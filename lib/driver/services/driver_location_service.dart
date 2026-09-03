import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Controls the normal SWAT RIDE driver's GPS and Firestore location updates.
///
/// Google Maps is intentionally not required here. GPS coordinates work
/// without Maps billing and can later be displayed on a real map.
class DriverLocationService {
  DriverLocationService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  StreamSubscription<Position>? _positionSubscription;
  Position? _lastUploadedPosition;
  DateTime? _lastUploadedAt;
  bool _uploadInProgress = false;
  bool _isTracking = false;

  bool get isTracking => _isTracking;
  Position? get lastUploadedPosition => _lastUploadedPosition;

  CollectionReference<Map<String, dynamic>> get _driversCollection =>
      _firestore.collection('drivers');

  // =========================================================
  // GPS PERMISSION + SERVICE CHECK
  // =========================================================

  Future<LocationAccessResult> checkLocationAccess({
    bool requestPermission = true,
  }) async {
    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return const LocationAccessResult(
        status: LocationAccessStatus.serviceDisabled,
        message: 'Please turn on phone location/GPS.',
      );
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationAccessResult(
        status: LocationAccessStatus.permissionDenied,
        message: 'Location permission was denied.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationAccessResult(
        status: LocationAccessStatus.permissionDeniedForever,
        message:
            'Location permission is blocked. Enable it from app settings.',
      );
    }

    return const LocationAccessResult(
      status: LocationAccessStatus.ready,
      message: 'Location is ready.',
    );
  }

  Future<void> ensureLocationReady() async {
    final LocationAccessResult result =
        await checkLocationAccess(requestPermission: true);

    if (!result.isReady) {
      throw DriverLocationException(result.message, result.status);
    }
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  // =========================================================
  // CURRENT PHONE GPS
  // =========================================================

  Future<Position> getCurrentPosition() async {
    await ensureLocationReady();

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  Future<Position?> getLastKnownPosition() async {
    await ensureLocationReady();
    return Geolocator.getLastKnownPosition();
  }

  // =========================================================
  // START CONTROLLED REAL-TIME TRACKING
  // =========================================================
  //
  // Battery protection:
  // - Android/iOS GPS stream uses distanceFilter.
  // - Firestore writes are also throttled by time and distance.
  // - Duplicate tracking subscriptions are prevented.
  //
  // Background/foreground-service platform configuration will be enabled
  // in the production Maps/background phase. This service already exposes
  // the reusable tracking logic.
  // =========================================================

  Future<void> startLocationTracking({
    required String driverId,
    String? activeRideId,
    Duration minimumUploadInterval = const Duration(seconds: 10),
    double minimumUploadDistanceMeters = 15,
    void Function(Position position)? onPosition,
    void Function(Object error)? onError,
  }) async {
    final String normalizedDriverId = driverId.trim();

    if (normalizedDriverId.isEmpty) {
      throw const DriverLocationException(
        'Driver ID is required.',
        LocationAccessStatus.invalidDriver,
      );
    }

    if (minimumUploadDistanceMeters < 0) {
      throw const DriverLocationException(
        'Minimum GPS distance cannot be negative.',
        LocationAccessStatus.invalidSettings,
      );
    }

    await ensureLocationReady();
    await stopLocationTracking();

    _isTracking = true;

    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (Position position) async {
        onPosition?.call(position);

        if (!_shouldUpload(
          position: position,
          minimumInterval: minimumUploadInterval,
          minimumDistanceMeters: minimumUploadDistanceMeters,
        )) {
          return;
        }

        if (_uploadInProgress) return;
        _uploadInProgress = true;

        try {
          await updatePosition(
            driverId: normalizedDriverId,
            position: position,
            activeRideId: activeRideId,
          );

          _lastUploadedPosition = position;
          _lastUploadedAt = DateTime.now();
        } catch (error) {
          onError?.call(error);
        } finally {
          _uploadInProgress = false;
        }
      },
      onError: (Object error) {
        onError?.call(error);
      },
      cancelOnError: false,
    );
  }

  bool _shouldUpload({
    required Position position,
    required Duration minimumInterval,
    required double minimumDistanceMeters,
  }) {
    final Position? previousPosition = _lastUploadedPosition;
    final DateTime? previousTime = _lastUploadedAt;

    if (previousPosition == null || previousTime == null) {
      return true;
    }

    final Duration elapsed = DateTime.now().difference(previousTime);
    final double distance = Geolocator.distanceBetween(
      previousPosition.latitude,
      previousPosition.longitude,
      position.latitude,
      position.longitude,
    );

    return elapsed >= minimumInterval ||
        distance >= minimumDistanceMeters;
  }

  Future<void> stopLocationTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    _uploadInProgress = false;
  }

  // =========================================================
  // SAVE COMPLETE GPS POSITION
  // =========================================================

  Future<void> updatePosition({
    required String driverId,
    required Position position,
    String? activeRideId,
  }) async {
    await _saveLocation(
      driverId: driverId,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      heading: position.heading,
      speed: position.speed,
      activeRideId: activeRideId,
    );
  }

  // =========================================================
  // EXISTING METHOD COMPATIBILITY
  // =========================================================

  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  }) async {
    await _saveLocation(
      driverId: driverId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<void> _saveLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? heading,
    double? speed,
    String? activeRideId,
  }) async {
    final String normalizedDriverId = driverId.trim();

    if (normalizedDriverId.isEmpty) {
      throw const DriverLocationException(
        'Driver ID is required.',
        LocationAccessStatus.invalidDriver,
      );
    }

    if (latitude < -90 || latitude > 90) {
      throw const DriverLocationException(
        'Invalid latitude.',
        LocationAccessStatus.invalidCoordinates,
      );
    }

    if (longitude < -180 || longitude > 180) {
      throw const DriverLocationException(
        'Invalid longitude.',
        LocationAccessStatus.invalidCoordinates,
      );
    }

    final Map<String, dynamic> location = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'geoPoint': GeoPoint(latitude, longitude),
      'accuracy': ?accuracy,
      'altitude': ?altitude,
      'heading': ?heading,
      if (speed != null) 'speed': speed < 0 ? 0 : speed,
      'recordedAt': FieldValue.serverTimestamp(),
    };

    await _driversCollection.doc(normalizedDriverId).set(
      <String, dynamic>{
        // Flat values preserve compatibility with existing screens.
        'latitude': latitude,
        'longitude': longitude,
        'location': location,
        if (activeRideId != null && activeRideId.trim().isNotEmpty)
          'activeRideId': activeRideId.trim(),
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (activeRideId != null && activeRideId.trim().isNotEmpty) {
      await _firestore.collection('rides').doc(activeRideId.trim()).set(
        <String, dynamic>{
          'driverLocation': location,
          'driverLocationUpdatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }

  // =========================================================
  // DRIVER LOCATION FIRESTORE STREAM
  // =========================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>> getDriverLocation(
    String driverId,
  ) {
    final String normalizedDriverId = driverId.trim();

    if (normalizedDriverId.isEmpty) {
      return const Stream<
          DocumentSnapshot<Map<String, dynamic>>>.empty();
    }

    return _driversCollection.doc(normalizedDriverId).snapshots();
  }

  // =========================================================
  // UPDATE LOCATION + ONLINE STATUS
  // =========================================================

  Future<void> updateDriverLocationAndStatus({
    required String driverId,
    required double latitude,
    required double longitude,
    required bool isOnline,
    required bool isAvailable,
  }) async {
    await _saveLocation(
      driverId: driverId,
      latitude: latitude,
      longitude: longitude,
    );

    await _driversCollection.doc(driverId.trim()).set(
      <String, dynamic>{
        'isOnline': isOnline,
        'isAvailable': isOnline && isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // =========================================================
  // SET DRIVER OFFLINE + STOP GPS
  // =========================================================

  Future<void> setDriverOffline({
    required String driverId,
  }) async {
    final String normalizedDriverId = driverId.trim();

    if (normalizedDriverId.isEmpty) return;

    await stopLocationTracking();

    await _driversCollection.doc(normalizedDriverId).set(
      <String, dynamic>{
        'isOnline': false,
        'isAvailable': false,
        'lastOfflineAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> dispose() {
    return stopLocationTracking();
  }
}

enum LocationAccessStatus {
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  invalidDriver,
  invalidCoordinates,
  invalidSettings,
}

class LocationAccessResult {
  final LocationAccessStatus status;
  final String message;

  const LocationAccessResult({
    required this.status,
    required this.message,
  });

  bool get isReady => status == LocationAccessStatus.ready;
}

class DriverLocationException implements Exception {
  final String message;
  final LocationAccessStatus status;

  const DriverLocationException(this.message, this.status);

  @override
  String toString() => message;
}

