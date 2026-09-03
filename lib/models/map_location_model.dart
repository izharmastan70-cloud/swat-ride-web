// Represents a geographic location with coordinates, address, and metadata.
// Used for storing pickup and dropoff locations and manual pin selections.

import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Represents a geographic point with address information
class MapLocation {
  final double latitude;
  final double longitude;
  final String? addressName;
  final String? placeName;
  final DateTime? selectedAt;
  final LocationSelectionMethod selectionMethod;

  const MapLocation({
    required this.latitude,
    required this.longitude,
    this.addressName,
    this.placeName,
    this.selectedAt,
    this.selectionMethod = LocationSelectionMethod.manual,
  });

  /// Get LatLng object for flutter_map
  LatLng get latLng => LatLng(latitude, longitude);

  /// Create from LatLng object
  factory MapLocation.fromLatLng(
    LatLng point, {
    String? addressName,
    String? placeName,
    LocationSelectionMethod method = LocationSelectionMethod.manual,
  }) {
    return MapLocation(
      latitude: point.latitude,
      longitude: point.longitude,
      addressName: addressName,
      placeName: placeName,
      selectedAt: DateTime.now(),
      selectionMethod: method,
    );
  }

  /// Create from coordinates
  factory MapLocation.fromCoordinates(
    double lat,
    double lon, {
    String? addressName,
    String? placeName,
  }) {
    return MapLocation(
      latitude: lat,
      longitude: lon,
      addressName: addressName,
      placeName: placeName,
      selectedAt: DateTime.now(),
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'addressName': addressName,
      'placeName': placeName,
      'selectedAt': selectedAt?.toIso8601String(),
      'selectionMethod': selectionMethod.toString().split('.').last,
    };
  }

  /// Create from JSON
  factory MapLocation.fromJson(Map<String, dynamic> json) {
    return MapLocation(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      addressName: json['addressName'] as String?,
      placeName: json['placeName'] as String?,
      selectedAt: json['selectedAt'] != null
          ? DateTime.parse(json['selectedAt'] as String)
          : null,
      selectionMethod: _parseSelectionMethod(json['selectionMethod']),
    );
  }

  /// Copy with modifications
  MapLocation copyWith({
    double? latitude,
    double? longitude,
    String? addressName,
    String? placeName,
    DateTime? selectedAt,
    LocationSelectionMethod? selectionMethod,
  }) {
    return MapLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addressName: addressName ?? this.addressName,
      placeName: placeName ?? this.placeName,
      selectedAt: selectedAt ?? this.selectedAt,
      selectionMethod: selectionMethod ?? this.selectionMethod,
    );
  }

  /// Check if location is valid
  bool get isValid => latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;

  /// Get distance in meters from another location (Haversine formula)
  double distanceTo(MapLocation other) {
    const R = 6371000; // Earth's radius in meters
    final lat1Rad = latitude * math.pi / 180;
    final lat2Rad = other.latitude * math.pi / 180;
    final deltaLat = (other.latitude - latitude) * math.pi / 180;
    final deltaLon = (other.longitude - longitude) * math.pi / 180;

    final a = (math.sin(deltaLat / 2) * math.sin(deltaLat / 2)) +
        (math.cos(lat1Rad) * math.cos(lat2Rad) * math.sin(deltaLon / 2) * math.sin(deltaLon / 2));

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  @override
  String toString() => 'MapLocation(lat: $latitude, lon: $longitude, address: $addressName)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapLocation &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

/// Enum for how location was selected
enum LocationSelectionMethod {
  currentLocation,
  mapPin,
  manual,
  autocomplete,
  history,
}

/// Parse selection method from string
LocationSelectionMethod _parseSelectionMethod(dynamic value) {
  if (value is String) {
    return LocationSelectionMethod.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => LocationSelectionMethod.manual,
    );
  }
  return LocationSelectionMethod.manual;
}
