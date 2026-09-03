import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/location_model.dart';
import '../models/osrm_route_model.dart';

class OsrmRoutingException implements Exception {
  const OsrmRoutingException(this.message);

  final String message;

  @override
  String toString() => 'OsrmRoutingException: $message';
}

class OsrmRoutingService {
  OsrmRoutingService({http.Client? client}) : _client = client ?? http.Client();

  static const String _host = 'router.project-osrm.org';
  static const Duration _requestTimeout = Duration(seconds: 15);

  final http.Client _client;

  Future<OsrmRoute> getDrivingRoute({
    required LocationModel pickup,
    required LocationModel destination,
  }) async {
    _validateLocation(pickup, 'pickup');
    _validateLocation(destination, 'destination');

    final Uri uri = Uri.https(
      _host,
      '/route/v1/driving/${pickup.longitude},${pickup.latitude};'
          '${destination.longitude},${destination.latitude}',
      const <String, String>{
        'overview': 'full',
        'geometries': 'geojson',
        'steps': 'false',
      },
    );

    try {
      final http.Response response = await _client
          .get(uri, headers: const <String, String>{'User-Agent': 'SWAT-Ride/1.0'})
          .timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw OsrmRoutingException('OSRM returned HTTP ${response.statusCode}.');
      }
      return _parseRoute(jsonDecode(response.body));
    } on OsrmRoutingException {
      rethrow;
    } catch (_) {
      throw const OsrmRoutingException(
        'Unable to calculate the driving route. Please try again.',
      );
    }
  }

  OsrmRoute _parseRoute(Object? body) {
    if (body is! Map<String, dynamic> || body['code'] != 'Ok') {
      throw const OsrmRoutingException('No driving route is available.');
    }
    final Object? routesValue = body['routes'];
    if (routesValue is! List || routesValue.isEmpty || routesValue.first is! Map) {
      throw const OsrmRoutingException('No driving route is available.');
    }
    final Map<dynamic, dynamic> route = routesValue.first as Map<dynamic, dynamic>;
    final double? distance = (route['distance'] as num?)?.toDouble();
    final double? duration = (route['duration'] as num?)?.toDouble();
    final Map<dynamic, dynamic>? geometry = route['geometry'] as Map<dynamic, dynamic>?;
    final Object? coordinatesValue = geometry?['coordinates'];
    if (distance == null || distance <= 0 || duration == null || duration < 0 ||
        coordinatesValue is! List) {
      throw const OsrmRoutingException('OSRM returned an invalid route.');
    }

    final List<RouteCoordinate> coordinates = coordinatesValue
        .whereType<List>()
        .where((List<dynamic> point) => point.length >= 2 && point[0] is num && point[1] is num)
        .map((List<dynamic> point) => RouteCoordinate(
              longitude: (point[0] as num).toDouble(),
              latitude: (point[1] as num).toDouble(),
            ))
        .toList(growable: false);
    if (coordinates.length < 2) {
      throw const OsrmRoutingException('OSRM returned an invalid route geometry.');
    }
    return OsrmRoute(
      distanceMeters: distance,
      durationSeconds: duration,
      geometry: coordinates,
    );
  }

  void _validateLocation(LocationModel location, String label) {
    if (location.latitude < -90 || location.latitude > 90 ||
        location.longitude < -180 || location.longitude > 180) {
      throw OsrmRoutingException('The $label coordinates are invalid.');
    }
  }
}