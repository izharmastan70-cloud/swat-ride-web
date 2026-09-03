class RouteCoordinate {
  const RouteCoordinate({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class OsrmRoute {
  const OsrmRoute({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.geometry,
  });

  final double distanceMeters;
  final double durationSeconds;
  final List<RouteCoordinate> geometry;

  double get distanceKm => distanceMeters / 1000;

  int get estimatedMinutes => (durationSeconds / 60).ceil();
}