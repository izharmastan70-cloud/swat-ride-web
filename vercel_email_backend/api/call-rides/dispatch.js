import { cert, getApp, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { createPhoneBookedRide } from '../../src/services/phone_call_ride_booking_transaction_service.js';
import { dispatchTripNotification, formatTripConfirmationMessage } from '../../src/services/omnichannel_trip_notification_router_service.js';

const MAX_TEXT_LENGTH = 240;

function text(value, name, maxLength = MAX_TEXT_LENGTH) {
  const normalized = typeof value === 'string' ? value.trim() : '';
  if (!normalized || normalized.length > maxLength) {
    throw new Error(`INVALID_${name}`);
  }
  return normalized;
}

function number(value, name, minimum = 0, maximum = Number.MAX_VALUE) {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < minimum || value > maximum) {
    throw new Error(`INVALID_${name}`);
  }
  return value;
}

function phone(value) {
  const normalized = typeof value === 'string' ? value.replace(/\s/g, '') : '';
  if (!/^\+[1-9]\d{7,14}$/.test(normalized)) {
    throw new Error('INVALID_PASSENGER_PHONE');
  }
  return normalized;
}

function location(value, name) {
  if (!value || typeof value !== 'object') throw new Error(`INVALID_${name}`);
  return {
    latitude: number(value.latitude, `${name}_LATITUDE`, -90, 90),
    longitude: number(value.longitude, `${name}_LONGITUDE`, -180, 180),
    address: text(value.address, `${name}_ADDRESS`),
    placeName: text(value.placeName, `${name}_PLACE_NAME`),
  };
}

function initializeFirebase() {
  try {
    return getApp('swat-ride-call-dispatch');
  } catch (_) {
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    const projectId = process.env.SWAT_RIDE_FIREBASE_PROJECT_ID;
    if (!serviceAccountJson || !projectId) {
      throw new Error('FIREBASE_ADMIN_CONFIGURATION_MISSING');
    }
    return initializeApp({
      credential: cert(JSON.parse(serviceAccountJson)),
      projectId,
    }, 'swat-ride-call-dispatch');
  }
}

export default async function handler(request, response) {
  if (request.method !== 'POST') {
    return response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
  }

  try {
    const authorization = request.headers.authorization ?? '';
    const token = authorization.startsWith('Bearer ') ? authorization.substring(7) : '';
    const app = initializeFirebase();
    const auth = getAuth(app);
    const firestore = getFirestore(app);
    const identity = await auth.verifyIdToken(token, true);
    const admin = await firestore.collection('admins').doc(identity.uid).get();
    const adminData = admin.data() ?? {};
    const role = String(adminData.role ?? identity.role ?? '').toLowerCase();
    if (!admin.exists || adminData.isActive !== true || !['admin', 'super_admin'].includes(role)) {
      return response.status(403).json({ ok: false, code: 'DISPATCH_NOT_AUTHORIZED' });
    }

    const operationalControls = await firestore
      .collection('app_config')
      .doc('super_admin_operational_controls')
      .get();
    if (operationalControls.data()?.phoneCallBookingEnabled === false) {
      return response.status(503).json({
        ok: false,
        code: 'PHONE_CALL_BOOKING_PAUSED_BY_SUPER_ADMIN',
      });
    }

    const payload = request.body ?? {};
    const callSessionId = text(payload.callSessionId, 'CALL_SESSION_ID', 160);
    const idempotencyKey = text(payload.idempotencyKey, 'IDEMPOTENCY_KEY', 160);
    const passengerName = text(payload.passengerName, 'PASSENGER_NAME');
    const passengerPhone = phone(payload.passengerPhone);
    const driverId = text(payload.driverId, 'DRIVER_ID', 128);
    const pickupLocation = location(payload.pickupLocation, 'PICKUP');
    const destinationLocation = location(payload.destinationLocation, 'DESTINATION');
    const distanceKm = number(payload.distanceKm, 'DISTANCE_KM');
    const estimatedMinutes = Math.round(number(payload.estimatedMinutes, 'ESTIMATED_MINUTES'));
    const paymentMethod = text(payload.paymentMethod, 'PAYMENT_METHOD', 32).toLowerCase();

    const result = await createPhoneBookedRide({
      firestore,
      callSessionId,
      idempotencyKey,
      bookingSource: 'agent_phone_call',
      driverId,
      passengerName,
      passengerPhone,
      pickupLocation,
      destinationLocation,
      distanceKm,
      estimatedMinutes,
      paymentMethod,
      bookedByAdminId: identity.uid,
    });

    let sms = { status: 'ALREADY_SENT_OR_REUSED', providerMessageId: '' };
    if (!result.reused) {
      const driver = result.driver;
      sms = await dispatchTripNotification({
        channel: 'whatsapp',
        callSessionId,
        recipientPhone: passengerPhone,
        localRelayEnabled: operationalControls.data()?.localMessagingRelayEnabled !== false,
        messageBody: formatTripConfirmationMessage({
          driverName: driver.fullName ?? driver.name ?? 'Your driver',
          driverPhone: driver.phoneNumber ?? driver.phone ?? 'N/A',
          vehicleName: driver.vehicleType ?? result.vehicleId ?? 'N/A',
          vehicleNumber: driver.vehicleNumber ?? '',
          pickupAddress: pickupLocation.address,
          destinationAddress: destinationLocation.address,
          distanceKm,
          estimatedMinutes,
          estimatedFare: result.estimatedFare,
        }),
      });
      await firestore.collection('rides').doc(result.rideId).update({
        passengerNotificationStatus: sms.status,
        passengerNotificationMessageId: sms.providerMessageId,
        passengerNotificationSentAt: FieldValue.serverTimestamp(),
      });
    }
    return response.status(200).json({ ok: true, rideId: result.rideId, reused: result.reused, notificationStatus: sms.status });
  } catch (error) {
    const code = String(error?.message ?? 'DISPATCH_FAILED');
    const status = code.startsWith('INVALID_') ? 400
      : ['DRIVER_NOT_AVAILABLE', 'IDEMPOTENCY_KEY_ALREADY_IN_PROGRESS', 'IDEMPOTENCY_SESSION_MISMATCH'].includes(code) ? 409
      : 500;
    return response.status(status).json({ ok: false, code });
  }
}