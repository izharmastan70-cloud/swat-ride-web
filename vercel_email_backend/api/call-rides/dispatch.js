import { cert, getApp, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore, Timestamp } from 'firebase-admin/firestore';

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

async function sendPassengerNotification({ to, body, callSessionId }) {
  const relayUrl = process.env.PASSENGER_WHATSAPP_RELAY_URL;
  const relayToken = process.env.PASSENGER_WHATSAPP_RELAY_TOKEN;
  if (!relayUrl || !relayToken) {
    return { status: 'NOT_CONFIGURED', providerMessageId: '' };
  }
  const response = await fetch(relayUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Relay-Secret': relayToken,
    },
    body: JSON.stringify({
      callSessionId,
      recipientPhone: to,
      messageBody: body,
      channel: 'whatsapp',
    }),
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok || payload.ok === false) {
    throw new Error('PASSENGER_MESSAGE_RELAY_REJECTED');
  }
  return { status: 'ACCEPTED', providerMessageId: String(payload.messageId ?? '') };
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

    const result = await firestore.runTransaction(async (transaction) => {
      const reservationReference = firestore.collection('agent_call_ride_booking_idempotency').doc(idempotencyKey);
      const reservation = await transaction.get(reservationReference);
      if (reservation.exists) {
        if (reservation.data()?.callSessionId !== callSessionId) {
          throw new Error('IDEMPOTENCY_SESSION_MISMATCH');
        }
        const existingRideId = String(reservation.data()?.rideId ?? '');
        if (existingRideId) return { rideId: existingRideId, reused: true, driver: null, estimatedFare: 0 };
        throw new Error('IDEMPOTENCY_KEY_ALREADY_IN_PROGRESS');
      }

      const driverReference = firestore.collection('drivers').doc(driverId);
      const driver = await transaction.get(driverReference);
      const driverData = driver.data() ?? {};
      const vehicleApproved = driverData.vehicleApproval?.status === 'approved';
      const documentsApproved = driverData.documentApproval?.status === 'approved';
      const photoApproved = driverData.primaryImageApproval?.status === 'approved';
      if (!driver.exists || driverData.status !== 'approved' || driverData.isSuspended === true ||
          driverData.isAvailable !== true || driverData.activeRideId || !vehicleApproved ||
          !documentsApproved || !photoApproved) {
        throw new Error('DRIVER_NOT_AVAILABLE');
      }

      const vehicleId = text(String(driverData.pricingVehicleId ?? driverData.vehicleType ?? ''), 'VEHICLE_ID', 64);
      const pricing = await transaction.get(firestore.collection('normal_ride_pricing').doc(vehicleId));
      const pricingData = pricing.data() ?? {};
      if (!pricing.exists || pricingData.isEnabled === false) throw new Error('VEHICLE_PRICING_UNAVAILABLE');
      const baseFare = number(pricingData.baseFare, 'SERVER_BASE_FARE');
      const perKm = number(pricingData.perKm, 'SERVER_PER_KM');
      const estimatedFare = Number((baseFare + (perKm * distanceKm)).toFixed(2));
      const commissionRate = typeof pricingData.commissionRate === 'number' ? pricingData.commissionRate : 0;
      const commissionAmount = Number((estimatedFare * commissionRate / 100).toFixed(2));
      const rideReference = firestore.collection('rides').doc();
      const now = Timestamp.now();

      transaction.create(rideReference, {
        rideId: rideReference.id,
        userId: `phone:${idempotencyKey}`,
        bookingSource: 'agent_phone_call',
        callSessionId,
        bookedByAdminId: identity.uid,
        driverId,
        driverName: String(driverData.fullName ?? driverData.name ?? 'SWAT RIDE Driver'),
        driverVehicleType: String(driverData.vehicleType ?? vehicleId),
        driverVehicleNumber: String(driverData.vehicleNumber ?? ''),
        driverPrimaryImageUrl: String(driverData.primaryImageApproval?.approvedUrl ?? ''),
        riderName: passengerName,
        riderPhone: passengerPhone,
        serviceScope: 'normal_ride',
        pickupLocation,
        destinationLocation,
        vehicleId,
        vehicleName: String(pricingData.name ?? driverData.vehicleType ?? vehicleId),
        distanceKm,
        estimatedMinutes,
        baseFare,
        estimatedFare,
        promoCode: null,
        promoDiscount: 0,
        paymentMethod,
        paymentStatus: 'pending',
        commissionAmount,
        status: 'driver_assigned',
        rejectedDriverIds: [],
        requestExpiresAt: null,
        rideStartPin: null,
        rideStartPinVerified: false,
        rideStartPinFailedAttempts: 0,
        createdAt: now,
        updatedAt: now,
        acceptedAt: now,
      });
      transaction.set(driverReference, {
        isAvailable: false,
        activeRideId: rideReference.id,
        lastRideAcceptedAt: now,
        updatedAt: now,
      }, { merge: true });
      transaction.create(reservationReference, {
        idempotencyKey,
        callSessionId,
        rideId: rideReference.id,
        createdBy: identity.uid,
        createdAt: now,
      });
      return {
        rideId: rideReference.id,
        reused: false,
        driver: driverData,
        estimatedFare,
      };
    });

    let sms = { status: 'ALREADY_SENT_OR_REUSED', providerMessageId: '' };
    if (!result.reused) {
      const driver = result.driver;
      try {
        sms = await sendPassengerNotification({
          to: passengerPhone,
          callSessionId,
          body: `SWAT RIDE: ${driver.fullName ?? driver.name ?? 'Your driver'} is assigned. Car: ${driver.vehicleNumber ?? 'N/A'} (${driver.vehicleType ?? 'N/A'}). Phone: ${driver.phoneNumber ?? driver.phone ?? 'N/A'}. ETA: ${estimatedMinutes} min. Fare: Rs. ${result.estimatedFare.toFixed(0)}`,
        });
      } catch (_) {
        sms = { status: 'FAILED', providerMessageId: '' };
      }
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