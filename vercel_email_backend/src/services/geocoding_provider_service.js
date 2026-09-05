// Resolves free-text pickup/destination speech (e.g. "Blue Area, near the
// GPO") into coordinates. No specific geocoding vendor is bundled -- set
// GEOCODING_PROVIDER_URL / GEOCODING_PROVIDER_API_KEY to any provider that
// accepts a `query` parameter and returns { latitude, longitude }
// (a small adapter route on your own infrastructure is enough). When the
// generic adapter is unset, Mapbox Geocoding is used if MAPBOX_ACCESS_TOKEN
// is configured. The service fails closed when neither is available.
//
// Callers may also pass raw "lat,lng" text directly (e.g. supplied by a
// companion GPS-aware caller app) to skip geocoding entirely.

const COORDINATE_PATTERN = /^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$/;

function parseRawCoordinates(text) {
  const match = COORDINATE_PATTERN.exec(String(text ?? ''));
  if (!match) return null;
  const latitude = Number(match[1]);
  const longitude = Number(match[2]);
  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) return null;
  return { latitude, longitude };
}

/**
 * Resolves `addressText` to `{ latitude, longitude }`. Throws
 * `GEOCODING_NOT_CONFIGURED` when neither configured provider is available
 * and the text is not already raw coordinates, and `GEOCODING_FAILED` on
 * provider errors.
 */
export async function resolveAddressToCoordinates({ addressText, fetchFn = fetch }) {
  const rawCoordinates = parseRawCoordinates(addressText);
  if (rawCoordinates) return rawCoordinates;

  const providerUrl = process.env.GEOCODING_PROVIDER_URL;
  const providerApiKey = process.env.GEOCODING_PROVIDER_API_KEY;
  const mapboxToken = process.env.MAPBOX_ACCESS_TOKEN;
  if (!providerUrl && !mapboxToken) throw new Error('GEOCODING_NOT_CONFIGURED');

  if (!providerUrl) {
    const mapboxUrl = new URL(
      `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(addressText)}.json`,
    );
    mapboxUrl.searchParams.set('access_token', mapboxToken);
    mapboxUrl.searchParams.set('limit', '1');
    const response = await fetchFn(mapboxUrl.toString(), { method: 'GET' });
    if (!response.ok) throw new Error('GEOCODING_FAILED');
    const payload = await response.json().catch(() => ({}));
    const center = payload?.features?.[0]?.center;
    if (!Array.isArray(center) || !Number.isFinite(center[0]) || !Number.isFinite(center[1])) {
      throw new Error('GEOCODING_FAILED');
    }
    return { longitude: center[0], latitude: center[1] };
  }

  const url = new URL(providerUrl);
  url.searchParams.set('query', String(addressText ?? ''));
  if (providerApiKey) url.searchParams.set('key', providerApiKey);

  const response = await fetchFn(url.toString(), { method: 'GET' });
  if (!response.ok) throw new Error('GEOCODING_FAILED');
  const payload = await response.json().catch(() => ({}));
  const latitude = Number(payload.latitude);
  const longitude = Number(payload.longitude);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    throw new Error('GEOCODING_FAILED');
  }
  return { latitude, longitude };
}
