// Reads the admin-managed `normal_ride_pricing` collection to determine
// which vehicle categories (e.g. Motorcycle, Rickshaw, Car) are currently
// active/registered in the fleet. The AI voice agent must only offer and
// accept bookings for vehicles returned here.

function toVehicleInventoryItem(documentId, data) {
  return Object.freeze({
    vehicleId: String(data.vehicleId ?? documentId),
    name: String(data.vehicleName ?? data.name ?? documentId),
    baseFare: Number(data.baseFare ?? 0),
    perKm: Number(data.perKm ?? data.perKilometerRate ?? 0),
    commissionRate: Number(data.commissionRate ?? data.adminCommissionPercentage ?? 0),
  });
}

/**
 * Returns every vehicle category currently enabled by Admin pricing config.
 * `isEnabled === false` (or a missing document) means the vehicle is not
 * offered, matching the same rule enforced by the manual dispatch endpoint.
 */
export async function listActiveVehicleInventory({ firestore }) {
  if (!firestore || typeof firestore.collection !== 'function') {
    throw new Error('A Firestore instance is required.');
  }
  const snapshot = await firestore.collection('normal_ride_pricing').get();
  const inventory = [];
  for (const document of snapshot.docs) {
    const data = document.data() ?? {};
    if (data.isEnabled === false) continue;
    inventory.push(toVehicleInventoryItem(document.id, data));
  }
  return inventory;
}

/** True when `vehicleId` is currently active/registered in the fleet. */
export async function isVehicleActive({ firestore, vehicleId }) {
  if (!vehicleId || typeof vehicleId !== 'string') return false;
  const document = await firestore.collection('normal_ride_pricing').doc(vehicleId).get();
  if (!document.exists) return false;
  return document.data()?.isEnabled !== false;
}

/**
 * Matches free-form caller speech (e.g. "car", "a bike please") against the
 * active vehicle inventory by case-insensitive substring match on name/id.
 * Returns null when no active vehicle matches.
 */
export function matchVehiclePreference({ inventory, spokenText }) {
  const normalized = String(spokenText ?? '').trim().toLowerCase();
  if (!normalized) return null;
  for (const vehicle of inventory) {
    if (
      normalized.includes(vehicle.vehicleId.toLowerCase()) ||
      normalized.includes(vehicle.name.toLowerCase())
    ) {
      return vehicle;
    }
  }
  return null;
}
