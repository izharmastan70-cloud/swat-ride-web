import { FieldValue } from 'firebase-admin/firestore';
import { estimateEtaMinutes, estimateRoadDistanceKm } from '../../src/services/fare_eta_engine_service.js';
import { resolveAddressToCoordinates } from '../../src/services/geocoding_provider_service.js';
import { findNearestAvailableDrivers } from '../../src/services/nearest_available_driver_locator_service.js';
import { dispatchTripNotification, formatTripConfirmationMessage } from '../../src/services/omnichannel_trip_notification_router_service.js';
import { createPhoneBookedRide } from '../../src/services/phone_call_ride_booking_transaction_service.js';
import { isVehicleActive } from '../../src/services/vehicle_inventory_query_service.js';
import { errorResponse, firestore, isLocalMessagingRelayEnabled, requirePbxWebhook, requireVoiceBookingEnabled, text } from './_shared.js';

export default async function handler(request, response) {
  if (request.method !== 'POST') return response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
  try {
    requirePbxWebhook(request);
    const firestoreInstance = firestore();
    await requireVoiceBookingEnabled(firestoreInstance);
    const payload = request.body ?? {};
    const callSessionId = text(payload.callSessionId, 'CALL_SESSION_ID', 160);
    const idempotencyKey = text(payload.idempotencyKey, 'IDEMPOTENCY_KEY', 160);
    const sessionReference = firestoreInstance.collection('ai_voice_call_sessions').doc(callSessionId);
    const session = await sessionReference.get();
    const sessionData = session.data() ?? {};
    const slots = sessionData.filledSlots ?? {};
    if (!session.exists || !['ready_for_dispatch', 'dispatched'].includes(sessionData.status)) {
      throw new Error('VOICE_CALL_SESSION_NOT_READY_FOR_DISPATCH');
    }
    if (sessionData.status === 'dispatched') {
      if (sessionData.dispatchIdempotencyKey !== idempotencyKey) {
        throw new Error('IDEMPOTENCY_SESSION_MISMATCH');
      }
      return response.status(200).json({
        ok: true,
        rideId: sessionData.rideId,
        reused: true,
        notificationStatus: sessionData.notificationStatus ?? 'ALREADY_SENT_OR_REUSED',
        driverEtaMinutes: sessionData.driverEtaMinutes ?? 0,
      });
    }
    if (!await isVehicleActive({ firestore: firestoreInstance, vehicleId: slots.vehiclePreference })) {
      throw new Error('VEHICLE_NOT_AVAILABLE');
    }

    const [pickupCoordinates, destinationCoordinates] = await Promise.all([
      resolveAddressToCoordinates({ addressText: slots.pickupAddress }),
      resolveAddressToCoordinates({ addressText: slots.destinationAddress }),
    ]);
    const distanceKm = estimateRoadDistanceKm({
      fromLatitude: pickupCoordinates.latitude,
      fromLongitude: pickupCoordinates.longitude,
      toLatitude: destinationCoordinates.latitude,
      toLongitude: destinationCoordinates.longitude,
    });
    const tripEstimatedMinutes = estimateEtaMinutes({ distanceKm });
    const candidates = await findNearestAvailableDrivers({
      firestore: firestoreInstance,
      vehicleId: slots.vehiclePreference,
      pickupLatitude: pickupCoordinates.latitude,
      pickupLongitude: pickupCoordinates.longitude,
    });
    if (!candidates.length) throw new Error('NO_AVAILABLE_DRIVER');

    let result;
    let driverEtaMinutes = 0;
    for (const candidate of candidates) {
      driverEtaMinutes = estimateEtaMinutes({ distanceKm: candidate.distanceToPickupKm });
      try {
        result = await createPhoneBookedRide({
          firestore: firestoreInstance,
          callSessionId,
          idempotencyKey,
          bookingSource: 'ai_voice_call',
          driverId: candidate.driverId,
          passengerName: slots.callerName,
          passengerPhone: sessionData.callerPhone,
          pickupLocation: { ...pickupCoordinates, address: slots.pickupAddress, placeName: slots.pickupAddress },
          destinationLocation: { ...destinationCoordinates, address: slots.destinationAddress, placeName: slots.destinationAddress },
          distanceKm,
          estimatedMinutes: tripEstimatedMinutes,
          paymentMethod: 'cash',
        });
        break;
      } catch (error) {
        if (String(error?.message) !== 'DRIVER_NOT_AVAILABLE') throw error;
      }
    }
    if (!result) throw new Error('NO_AVAILABLE_DRIVER');

    let notification = { status: 'ALREADY_SENT_OR_REUSED', providerMessageId: '' };
    if (!result.reused) {
      const driver = result.driver;
      notification = await dispatchTripNotification({
        channel: 'sms',
        callSessionId,
        recipientPhone: sessionData.callerPhone,
        localRelayEnabled: await isLocalMessagingRelayEnabled(firestoreInstance),
        messageBody: formatTripConfirmationMessage({
          driverName: driver.fullName ?? driver.name ?? 'Your driver',
          driverPhone: driver.phoneNumber ?? driver.phone ?? 'N/A',
          vehicleName: driver.vehicleType ?? result.vehicleId,
          vehicleNumber: driver.vehicleNumber ?? '',
          pickupAddress: slots.pickupAddress,
          destinationAddress: slots.destinationAddress,
          distanceKm,
          estimatedMinutes: driverEtaMinutes,
          estimatedFare: result.estimatedFare,
        }),
      });
      await firestoreInstance.collection('rides').doc(result.rideId).update({
        passengerCount: slots.passengerCount,
        passengerNotificationStatus: notification.status,
        passengerNotificationMessageId: notification.providerMessageId,
        passengerNotificationSentAt: FieldValue.serverTimestamp(),
      });
    }
    await sessionReference.update({
      status: 'dispatched',
      rideId: result.rideId,
      dispatchIdempotencyKey: idempotencyKey,
      notificationStatus: notification.status,
      driverEtaMinutes,
      updatedAt: FieldValue.serverTimestamp(),
    });
    return response.status(200).json({
      ok: true,
      rideId: result.rideId,
      reused: result.reused,
      notificationStatus: notification.status,
      driverEtaMinutes,
    });
  } catch (error) {
    return errorResponse(response, error);
  }
}