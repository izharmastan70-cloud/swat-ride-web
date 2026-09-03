import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/map_location_model.dart';

class OpenMapLocationService {
  final FirebaseFirestore _firestore;
  
  static const String _locationsCollection = 'map_locations';
  static const Duration _locationTimeout = Duration(seconds: 30);
  static const Duration _locationCacheDuration = Duration(minutes: 5);

  DateTime? _lastLocationFetch;
  MapLocation? _cachedLocation;

  OpenMapLocationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get current device location with error handling
  Future<MapLocation?> getCurrentLocation({
    bool forceRefresh = false,
    bool useCache = true,
  }) async {
    try {
      // Check cache first
      if (useCache && !forceRefresh && _cachedLocation != null && _lastLocationFetch != null) {
        final timeSinceLastFetch = DateTime.now().difference(_lastLocationFetch!);
        if (timeSinceLastFetch < _locationCacheDuration) {
          return _cachedLocation;
        }
      }

      // Check permissions
      final permission = await _checkLocationPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _locationTimeout,
        ),
      );

      final location = MapLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        addressName: 'Current Location',
        selectionMethod: LocationSelectionMethod.currentLocation,
        selectedAt: DateTime.now(),
      );

      // Cache the location
      _cachedLocation = location;
      _lastLocationFetch = DateTime.now();

      return location;
    } catch (_) {
      return null;
    }
  }

  /// Check and request location permissions
  Future<LocationPermission> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      // Open app settings if permission is permanently denied
      await Geolocator.openLocationSettings();
      return LocationPermission.denied;
    }

    return permission;
  }

  /// Start location stream for real-time updates
  Stream<MapLocation> getLocationStream({
    int accuracyInMeters = 100,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: accuracyInMeters,
      ),
    ).map((position) {
      return MapLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        selectionMethod: LocationSelectionMethod.currentLocation,
        selectedAt: DateTime.now(),
      );
    });
  }

  /// Get approximate address from coordinates (reverse geocoding)
  /// Note: Uses OpenStreetMap Nominatim service (free, no API key needed)
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'zoom': '18',
        'addressdetails': '1',
      });
      final response = await http
          .get(uri, headers: {'User-Agent': 'SWAT-Ride/1.0'})
          .timeout(_locationTimeout);

      if (response.statusCode != 200) {
        return _formatCoordinateAddress(latitude, longitude);
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      return result['display_name'] as String? ??
          _formatCoordinateAddress(latitude, longitude);
    } catch (_) {
      return null;
    }
  }

  /// Format address from coordinates
  String _formatCoordinateAddress(double latitude, double longitude) {
    return '$latitude, $longitude';
  }

  /// Save location to Firestore
  Future<void> saveLocation(
    MapLocation location, {
    required String userId,
    String? locationType, // 'home', 'work', 'favorite', etc.
  }) async {
    try {
      await _firestore
          .collection(_locationsCollection)
          .add({
            'userId': userId,
            'latitude': location.latitude,
            'longitude': location.longitude,
            'addressName': location.addressName,
            'placeName': location.placeName,
            'locationType': locationType,
            'selectionMethod': location.selectionMethod.toString().split('.').last,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (_) {
      rethrow;
    }
  }

  /// Get saved locations for user
  Future<List<MapLocation>> getSavedLocations(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_locationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => MapLocation.fromJson(doc.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Validate location is within service area (Swat region)
  /// Swat boundaries: approximately 34.3° to 35.6° N, 72.4° to 73.3° E
  bool isLocationInSwat(MapLocation location) {
    const minLat = 34.0;
    const maxLat = 36.0;
    const minLon = 72.0;
    const maxLon = 74.0;

    return location.latitude >= minLat &&
        location.latitude <= maxLat &&
        location.longitude >= minLon &&
        location.longitude <= maxLon;
  }

  /// Get center point of Swat (default map center)
  static MapLocation getSwatCenter() {
    return MapLocation(
      latitude: 34.7682,
      longitude: 72.3345,
      addressName: 'Swat, Khyber Pakhtunkhwa, Pakistan',
      placeName: 'Swat Region',
      selectionMethod: LocationSelectionMethod.manual,
    );
  }

  /// Get Swat region bounds for map display
  static LatLngBounds getSwatBounds() {
    return LatLngBounds(
      LatLng(34.0, 72.0),  // Southwest corner
      LatLng(36.0, 74.0),  // Northeast corner
    );
  }

  /// Calculate distance between two locations
  double calculateDistance(MapLocation from, MapLocation to) {
    return from.distanceTo(to);
  }

  /// Clear cached location
  void clearCache() {
    _cachedLocation = null;
    _lastLocationFetch = null;
  }
}
