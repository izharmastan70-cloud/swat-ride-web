// Fare and ETA calculation engine shared by the human-agent phone dispatch
// endpoint and the AI voice dispatch (Tier 2) endpoint, so both booking
// paths apply identical admin per-KM pricing rules.

// Straight-line distance is multiplied to approximate normal road curves,
// matching the same fallback constants used by the Flutter
// RidePricingService when a real routing provider is unavailable.
export const ROAD_DISTANCE_MULTIPLIER = 1.25;
export const DEFAULT_AVERAGE_SPEED_KM_PER_HOUR = 25;
const EARTH_RADIUS_KM = 6371;

function toRadians(degrees) {
  return (degrees * Math.PI) / 180;
}

/** Great-circle distance between two coordinates, in kilometers. */
export function haversineDistanceKm({ fromLatitude, fromLongitude, toLatitude, toLongitude }) {
  const deltaLatitude = toRadians(toLatitude - fromLatitude);
  const deltaLongitude = toRadians(toLongitude - fromLongitude);
  const a =
    Math.sin(deltaLatitude / 2) ** 2 +
    Math.cos(toRadians(fromLatitude)) *
      Math.cos(toRadians(toLatitude)) *
      Math.sin(deltaLongitude / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_KM * c;
}

/** Approximate road distance (km) when no routing provider is available. */
export function estimateRoadDistanceKm({ fromLatitude, fromLongitude, toLatitude, toLongitude }) {
  const straightLineKm = haversineDistanceKm({
    fromLatitude,
    fromLongitude,
    toLatitude,
    toLongitude,
  });
  return Number((straightLineKm * ROAD_DISTANCE_MULTIPLIER).toFixed(3));
}

export function estimateEtaMinutes({
  distanceKm,
  averageSpeedKmPerHour = DEFAULT_AVERAGE_SPEED_KM_PER_HOUR,
}) {
  if (typeof distanceKm !== 'number' || !Number.isFinite(distanceKm) || distanceKm < 0) {
    throw new Error('INVALID_DISTANCE_KM');
  }
  if (
    typeof averageSpeedKmPerHour !== 'number' ||
    !Number.isFinite(averageSpeedKmPerHour) ||
    averageSpeedKmPerHour <= 0
  ) {
    throw new Error('INVALID_AVERAGE_SPEED');
  }
  return Math.max(1, Math.round((distanceKm / averageSpeedKmPerHour) * 60));
}

function nonNegativeNumber(value, name) {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 0) {
    throw new Error(`INVALID_${name}`);
  }
  return value;
}

function roundUp(value, unit) {
  return unit <= 0 ? value : Math.ceil(value / unit) * unit;
}

/**
 * Mirrors RidePricingService.calculateFare using the current document from
 * `normal_ride_pricing`; no fare or commission value is hardcoded here.
 */
export function calculateFare({
  baseFare,
  perKm,
  distanceKm,
  estimatedMinutes,
  perMinuteRate,
  minimumFare,
  bookingFee,
  surgeMultiplier,
  taxPercentage,
  roundingUnit,
  commissionRate,
}) {
  const safeBaseFare = nonNegativeNumber(baseFare, 'BASE_FARE');
  const safePerKm = nonNegativeNumber(perKm, 'PER_KM');
  const safeDistanceKm = nonNegativeNumber(distanceKm, 'DISTANCE_KM');
  const safeEstimatedMinutes = nonNegativeNumber(estimatedMinutes, 'ESTIMATED_MINUTES');
  const safePerMinuteRate = nonNegativeNumber(perMinuteRate, 'PER_MINUTE_RATE');
  const safeMinimumFare = nonNegativeNumber(minimumFare, 'MINIMUM_FARE');
  const safeBookingFee = nonNegativeNumber(bookingFee, 'BOOKING_FEE');
  const safeTaxPercentage = nonNegativeNumber(taxPercentage, 'TAX_PERCENTAGE');
  const safeRoundingUnit = nonNegativeNumber(roundingUnit, 'ROUNDING_UNIT');
  if (typeof surgeMultiplier !== 'number' || !Number.isFinite(surgeMultiplier) || surgeMultiplier < 1) {
    throw new Error('INVALID_SURGE_MULTIPLIER');
  }
  const safeCommissionRate = Math.min(100, nonNegativeNumber(commissionRate, 'COMMISSION_RATE'));
  const distanceFare = safeDistanceKm * safePerKm;
  const timeFare = safeEstimatedMinutes * safePerMinuteRate;
  const beforeSurge = safeBaseFare + distanceFare + timeFare + safeBookingFee;
  const afterSurge = beforeSurge * surgeMultiplier;
  const taxAmount = afterSurge * (safeTaxPercentage / 100);
  const estimatedFare = roundUp(Math.max(safeMinimumFare, afterSurge + taxAmount), safeRoundingUnit);
  const commissionAmount = estimatedFare * (safeCommissionRate / 100);
  return {
    estimatedFare: Number(estimatedFare.toFixed(2)),
    commissionAmount: Number(commissionAmount.toFixed(2)),
    distanceFare: Number(distanceFare.toFixed(2)),
    timeFare: Number(timeFare.toFixed(2)),
    surgeAmount: Number(Math.max(0, afterSurge - beforeSurge).toFixed(2)),
    taxAmount: Number(taxAmount.toFixed(2)),
  };
}
