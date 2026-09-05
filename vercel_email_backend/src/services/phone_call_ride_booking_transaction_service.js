// Shared, transaction-based ride-creation logic for phone/voice bookings.
// Used by BOTH the human-agent manual dispatch endpoint
// (/api/call-rides/dispatch, explicit driverId) and the AI voice dispatch
// (Tier 2) endpoint (/api/calls/dispatch, auto-selected nearest driver), so
// every phone/voice booking path enforces identical driver-eligibility,
// pricing, and idempotency rules.
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { calculateFare } from './fare_eta_engine_service.js';

/**
 * Creates (or safely reuses, via idempotency key) a ride booked through a
 * phone call or AI voice agent. Returns `{ rideId, reused, driver,
 * estimatedFare, vehicleId }`.
 */
export async function createPhoneBookedRide({
  firestore,
  callSessionId,
  idempotencyKey,
  bookingSource,
  driverId,
  passengerName,
  passengerPhone,
  pickupLocation,
  destinationLocation,
  distanceKm,
  estimatedMinutes,
  paymentMethod,
  bookedByAdminId = null,
  riderUserId = null,
}) {
  if (!firestore || typeof firestore.runTransaction !== 'function') {
    throw new Error('A Firestore instance is required.');
  }
  if (!bookingSource || typeof bookingSource !== 'string') {
    throw new Error('INVALID_BOOKING_SOURCE');
  }
  if (!driverId || typeof driverId !== 'string') {
    throw new Error('INVALID_DRIVER_ID');
  }

  return firestore.runTransaction(async (transaction) => {
    const reservationReference = firestore
      .collection('agent_call_ride_booking_idempotency')
      .doc(idempotencyKey);
    const reservation = await transaction.get(reservationReference);
    if (reservation.exists) {
      if (reservation.data()?.callSessionId !== callSessionId) {
        throw new Error('IDEMPOTENCY_SESSION_MISMATCH');
      }
      const existingRideId = String(reservation.data()?.rideId ?? '');
      if (existingRideId) {
        return { rideId: existingRideId, reused: true, driver: null, estimatedFare: 0, vehicleId: '' };
      }
      throw new Error('IDEMPOTENCY_KEY_ALREADY_IN_PROGRESS');
    }

    const driverReference = firestore.collection('drivers').doc(driverId);
    const driver = await transaction.get(driverReference);
    const driverData = driver.data() ?? {};
    const vehicleApproved = driverData.vehicleApproval?.status === 'approved';
    const documentsApproved = driverData.documentApproval?.status === 'approved';
    const photoApproved = driverData.primaryImageApproval?.status === 'approved';
    if (
      !driver.exists ||
      driverData.status !== 'approved' ||
      driverData.isSuspended === true ||
      driverData.isAvailable !== true ||
      driverData.activeRideId ||
      !vehicleApproved ||
      !documentsApproved ||
      !photoApproved
    ) {
      throw new Error('DRIVER_NOT_AVAILABLE');
    }

    const vehicleId = String(driverData.pricingVehicleId ?? driverData.vehicleType ?? '');
    if (!vehicleId) throw new Error('INVALID_VEHICLE_ID');
    const pricing = await transaction.get(firestore.collection('normal_ride_pricing').doc(vehicleId));
    const pricingData = pricing.data() ?? {};
    if (!pricing.exists || pricingData.isEnabled === false) throw new Error('VEHICLE_PRICING_UNAVAILABLE');

    const pricingSnapshot = {
      baseFare: Number(pricingData.baseFare ?? 0),
      perKm: Number(pricingData.perKm ?? pricingData.perKilometerRate ?? 0),
      perMinuteRate: Number(pricingData.perMinuteRate ?? 0),
      minimumFare: Number(pricingData.minimumFare ?? pricingData.minFare ?? 0),
      bookingFee: Number(pricingData.bookingFee ?? 0),
      surgeMultiplier: Number(pricingData.surgeMultiplier ?? 1),
      taxPercentage: Number(pricingData.taxPercentage ?? 0),
      roundingUnit: Number(pricingData.roundingUnit ?? 1),
      commissionRate: Number(pricingData.commissionRate ?? pricingData.adminCommissionPercentage ?? 0),
    };
    const fare = calculateFare({ ...pricingSnapshot, distanceKm, estimatedMinutes });
    const { estimatedFare, commissionAmount } = fare;

    const rideReference = firestore.collection('rides').doc();
    const now = Timestamp.now();
    const userId = riderUserId && riderUserId.trim() ? riderUserId.trim() : `phone:${idempotencyKey}`;

    transaction.create(rideReference, {
      rideId: rideReference.id,
      userId,
      bookingSource,
      callSessionId,
      bookedByAdminId,
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
      vehicleName: String(pricingData.name ?? pricingData.vehicleName ?? driverData.vehicleType ?? vehicleId),
      distanceKm,
      estimatedMinutes,
      baseFare: pricingSnapshot.baseFare,
      perKilometerRate: pricingSnapshot.perKm,
      perMinuteRate: pricingSnapshot.perMinuteRate,
      minimumFare: pricingSnapshot.minimumFare,
      bookingFee: pricingSnapshot.bookingFee,
      surgeMultiplier: pricingSnapshot.surgeMultiplier,
      taxPercentage: pricingSnapshot.taxPercentage,
      roundingUnit: pricingSnapshot.roundingUnit,
      adminCommissionPercentage: pricingSnapshot.commissionRate,
      distanceFare: fare.distanceFare,
      timeFare: fare.timeFare,
      surgeAmount: fare.surgeAmount,
      taxAmount: fare.taxAmount,
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
    transaction.set(
      driverReference,
      {
        isAvailable: false,
        activeRideId: rideReference.id,
        lastRideAcceptedAt: now,
        updatedAt: now,
      },
      { merge: true },
    );
    transaction.create(reservationReference, {
      idempotencyKey,
      callSessionId,
      rideId: rideReference.id,
      createdBy: bookedByAdminId,
      bookingSource,
      createdAt: now,
    });

    return { rideId: rideReference.id, reused: false, driver: driverData, estimatedFare, vehicleId };
  });
}

// Re-exported so downstream callers writing side-effect updates outside the
// transaction (e.g. passenger-notification status) share one FieldValue.
export { FieldValue };
