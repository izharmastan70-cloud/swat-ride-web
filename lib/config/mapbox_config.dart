class MapboxConfig {
  const MapboxConfig._();

  // Mapbox public access tokens are designed for client-side map rendering.
  static const String accessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '',
  );

  static const String rasterTilesUrl =
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/512/{z}/{x}/{y}@2x?access_token=$accessToken';
}