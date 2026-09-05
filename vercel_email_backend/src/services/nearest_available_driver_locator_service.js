// Finds the nearest available, fully-approved driver for a given vehicle
// category and pickup point. Used by the AI voice dispatch (Tier 2) engine
// to auto-select a driver, mirroring the same eligibility rules already
// enforced inside the manual /api/call-rides/dispatch transaction.
import { haversineDistanceKm } from './fare_eta_engine_service.js';

function isDriverEligible(driverData, vehicleId) {
  const vehicleApproved = driverData.vehicleApproval?.status === 'approved';
  const documentsApproved = driverData.documentApproval?.status === 'approved';
  const photoApproved = driverData.primaryImageApproval?.status === 'approved';
  const driverVehicleId = String(driverData.pricingVehicleId ?? driverData.vehicleType ?? '');
  return (
    driverData.status === 'approved' &&
    driverData.isSuspended !== true &&
    driverData.isAvailable === true &&
    !driverData.activeRideId &&
    vehicleApproved &&
    documentsApproved &&
    photoApproved &&
    driverVehicleId === vehicleId &&
    typeof driverData.latitude === 'number' &&
    typeof driverData.longitude === 'number'
  );
}

/**
 * Returns up to `limit` eligible drivers for `vehicleId`, nearest first, so
 * the caller can retry the next candidate if the closest one is claimed by
 * another booking before the atomic ride-creation transaction completes.
 */
export async function findNearestAvailableDrivers({
  firestore,
  vehicleId,
  pickupLatitude,
  pickupLongitude,
  limit = 5,
}) {
  if (!firestore || typeof firestore.collection !== 'function') {
    throw new Error('A Firestore instance is required.');
  }
  if (!vehicleId || typeof vehicleId !== 'string') {
    throw new Error('INVALID_VEHICLE_ID');
  }
  if (typeof pickupLatitude !== 'number' || typeof pickupLongitude !== 'number') {
    throw new Error('INVALID_PICKUP_COORDINATES');
  }

  const snapshot = await firestore.collection('drivers').where('status', '==', 'approved').get();
  const candidates = [];
  for (const document of snapshot.docs) {
    const data = document.data() ?? {};
    if (!isDriverEligible(data, vehicleId)) continue;
    const distanceToPickupKm = haversineDistanceKm({
      fromLatitude: data.latitude,
      fromLongitude: data.longitude,
      toLatitude: pickupLatitude,
      toLongitude: pickupLongitude,
    });
    candidates.push({ driverId: document.id, driverData: data, distanceToPickupKm });
  }

  candidates.sort((a, b) => a.distanceToPickupKm - b.distanceToPickupKm);
  return candidates.slice(0, Math.max(1, limit));
}
