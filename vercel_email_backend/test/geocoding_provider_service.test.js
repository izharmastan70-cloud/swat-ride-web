import assert from 'node:assert/strict';
import test from 'node:test';
import { resolveAddressToCoordinates } from '../src/services/geocoding_provider_service.js';

test('uses Mapbox Geocoding when no custom provider is configured', async () => {
  const previousProviderUrl = process.env.GEOCODING_PROVIDER_URL;
  const previousMapboxToken = process.env.MAPBOX_ACCESS_TOKEN;
  delete process.env.GEOCODING_PROVIDER_URL;
  process.env.MAPBOX_ACCESS_TOKEN = 'test-mapbox-token';
  let requestedUrl = '';
  try {
    const result = await resolveAddressToCoordinates({
      addressText: 'Mingora, Swat',
      fetchFn: async (url) => {
        requestedUrl = url;
        return {
          ok: true,
          json: async () => ({ features: [{ center: [72.3629, 34.7795] }] }),
        };
      },
    });
    assert.deepEqual(result, { longitude: 72.3629, latitude: 34.7795 });
    assert.match(requestedUrl, /api\.mapbox\.com\/geocoding\/v5/);
    assert.match(requestedUrl, /access_token=test-mapbox-token/);
  } finally {
    if (previousProviderUrl === undefined) delete process.env.GEOCODING_PROVIDER_URL;
    else process.env.GEOCODING_PROVIDER_URL = previousProviderUrl;
    if (previousMapboxToken === undefined) delete process.env.MAPBOX_ACCESS_TOKEN;
    else process.env.MAPBOX_ACCESS_TOKEN = previousMapboxToken;
  }
});