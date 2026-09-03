import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/ride_model.dart';
import '../../services/ride_service_control_service.dart';

class DriverRideService {
  DriverRideService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // =========================================================
  // COLLECTIONS
  // =========================================================

  CollectionReference<Map<String, dynamic>> get _ridesCollection =>
      _firestore.collection('rides');

  CollectionReference<Map<String, dynamic>> get _driversCollection =>
      _firestore.collection('drivers');

  // =========================================================
  // NORMALIZE VALUE
  // =========================================================

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  }

  // =========================================================
  // VEHICLE MATCHING
  // =========================================================
  //
  // Rider ki selected vehicle aur Driver ki registered
  // vehicle category ko match karta hai.
  //
  // Examples:
  // Car / car / Mini Car / mini_car
  // =========================================================

  bool _vehicleMatches({
    required Map<String, dynamic> rideData,
    required String driverVehicleType,
  }) {
    final String driverVehicle = _normalize(driverVehicleType);

    final String rideVehicleId = _normalize(
      rideData['vehicleId'] as String? ?? '',
    );

    final String rideVehicleName = _normalize(
      rideData['vehicleName'] as String? ?? '',
    );

    if (driverVehicle.isEmpty) {
      return false;
    }

    if (driverVehicle == rideVehicleId || driverVehicle == rideVehicleName) {
      return true;
    }

    // Temporary compatibility for existing vehicle names.
    // Later Admin Vehicle Configuration will provide one
    // permanent category ID for Rider and Driver.
    const Map<String, List<String>> vehicleGroups = {
      'bike': ['bike', 'motorbike', 'motorcycle'],
      'rickshaw': ['rickshaw', 'auto_rickshaw'],
      'car': ['car', 'mini_car', 'alto', 'wagon_r', 'sedan', 'corolla'],
      'premium': [
        'premium',
        'premium_car',
        'suv',
        'vitara',
        'fielder',
        'corolla_fielder',
      ],
    };

    for (final MapEntry<String, List<String>> entry in vehicleGroups.entries) {
      final bool driverInGroup = entry.value.contains(driverVehicle);

      final bool rideInGroup =
          entry.value.contains(rideVehicleId) ||
          entry.value.contains(rideVehicleName);

      if (driverInGroup && rideInGroup) {
        return true;
      }
    }

    return false;
  }

  // =========================================================
  // CHECK DRIVER REJECTION
  // =========================================================

  bool _wasRejectedByDriver({
    required Map<String, dynamic> rideData,
    required String driverId,
  }) {
    final List<dynamic> rejectedDriverIds =
        rideData['rejectedDriverIds'] as List<dynamic>? ?? <dynamic>[];

    return rejectedDriverIds.contains(driverId);
  }

  // =========================================================
  // AVAILABLE RIDE REQUESTS STREAM
  // =========================================================
  //
  // This is real Firestore code.
  //
  // Only rides with status "searching" are loaded.
  // Vehicle matching and rejected-driver filtering are
  // applied safely on the Driver device.
  //
  // Nearby GPS sorting will be added after Driver GPS
  // connection phase.
  // =========================================================

  Stream<List<RideModel>> watchAvailableRides({
    required String driverId,
    required String vehicleType,
  }) {
    final String normalizedDriverId = driverId.trim();

    if (normalizedDriverId.isEmpty) {
      return Stream.value(<RideModel>[]);
    }

    return _ridesCollection
        .where('status', isEqualTo: RideModel.searching)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<RideModel> matchingRides = <RideModel>[];

          for (final QueryDocumentSnapshot<Map<String, dynamic>> document
              in snapshot.docs) {
            final Map<String, dynamic> data = document.data();

            final String? assignedDriverId = data['driverId'] as String?;

            // Skip if already assigned.
            if (assignedDriverId != null &&
                assignedDriverId.trim().isNotEmpty) {
              continue;
            }

            // Skip if this Driver rejected it earlier.
            if (_wasRejectedByDriver(
              rideData: data,
              driverId: normalizedDriverId,
            )) {
              continue;
            }

            // Skip non-matching vehicle requests.
            if (!_vehicleMatches(
              rideData: data,
              driverVehicleType: vehicleType,
            )) {
              continue;
            }

            try {
              final Map<String, dynamic> safeData = {
                ...data,
                'rideId': data['rideId'] ?? document.id,
              };

              matchingRides.add(RideModel.fromMap(safeData));
            } catch (_) {
              // One damaged ride document must not crash
              // the complete Driver Ride Requests screen.
              continue;
            }
          }

          // Newest requests appear first.
          matchingRides.sort(
            (RideModel first, RideModel second) =>
                second.createdAt.compareTo(first.createdAt),
          );

          return matchingRides;
        });
  }

  // =========================================================
  // ACCEPT RIDE SAFELY
  // =========================================================
  //
  // Firestore Transaction:
  //
  // 1. Reads latest ride status.
  // 2. Confirms ride is still searching.
  // 3. Confirms another Driver has not accepted it.
  // 4. Assigns this Driver.
  // 5. Marks Driver busy/unavailable.
  //
  // This prevents two Drivers from accepting one ride.
  // =========================================================

  Future<void> acceptRide({
    required String rideId,
    required String driverId,
    required String driverName,
    required String vehicleType,
    required String vehicleNumber,
  }) async {
    final String normalizedRideId = rideId.trim();

    final String normalizedDriverId = driverId.trim();

    if (normalizedRideId.isEmpty) {
      throw Exception('Ride ID is required.');
    }

    if (normalizedDriverId.isEmpty) {
      throw Exception('Driver ID is required.');
    }

    // Global Normal Ride service control.
    // Blocks only NEW Driver acceptance. Existing active rides continue.
    await RideServiceControlService(
      firestore: _firestore,
    ).ensureNewRideAvailable();

    final DocumentReference<Map<String, dynamic>> rideReference =
        _ridesCollection.doc(normalizedRideId);

    final DocumentReference<Map<String, dynamic>> driverReference =
        _driversCollection.doc(normalizedDriverId);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> driverSnapshot =
          await transaction.get(driverReference);
      final Map<String, dynamic> driverData =
          driverSnapshot.data() ?? <String, dynamic>{};
      if (!driverSnapshot.exists ||
          driverData['status'] != 'approved' ||
          !_hasApprovedVehicleAndPhoto(driverData)) {
        throw Exception(
          'Your vehicle, documents and primary photo must be approved before accepting rides.',
        );
      }
      final DocumentSnapshot<Map<String, dynamic>> rideSnapshot =
          await transaction.get(rideReference);

      if (!rideSnapshot.exists) {
        throw Exception('This ride request no longer exists.');
      }

      final Map<String, dynamic> rideData =
          rideSnapshot.data() ?? <String, dynamic>{};

      final String currentStatus = rideData['status'] as String? ?? '';

      final String? currentDriverId = rideData['driverId'] as String?;

      if (currentStatus != RideModel.searching) {
        throw Exception('This ride is no longer available.');
      }

      if (currentDriverId != null && currentDriverId.trim().isNotEmpty) {
        throw Exception('Another Driver has already accepted this ride.');
      }

      if (_wasRejectedByDriver(
        rideData: rideData,
        driverId: normalizedDriverId,
      )) {
        throw Exception('You already declined this request.');
      }

      if (!_vehicleMatches(
        rideData: rideData,
        driverVehicleType: vehicleType,
      )) {
        throw Exception('This ride does not match your vehicle.');
      }

      transaction.update(rideReference, <String, dynamic>{
        'driverId': normalizedDriverId,
        'driverName': driverName.trim(),
        'driverVehicleType': vehicleType.trim(),
        'driverVehicleNumber': vehicleNumber.trim(),
        'driverPrimaryImageUrl': _approvedPrimaryImageUrl(driverData),
        'status': RideModel.driverAssigned,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(driverReference, <String, dynamic>{
        'isOnline': true,
        'isAvailable': false,
        'activeRideId': normalizedRideId,
        'lastRideAcceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  String? _approvedPrimaryImageUrl(Map<String, dynamic> data) {
    final Map<dynamic, dynamic> photo =
        data['primaryImageApproval'] as Map<dynamic, dynamic>? ?? const {};
    if (photo['status'] != 'approved') return null;
    final String url = photo['approvedUrl']?.toString().trim() ?? '';
    return url.isEmpty ? null : url;
  }

    bool _hasApprovedVehicleAndPhoto(Map<String, dynamic> data) {
    final Map<dynamic, dynamic> vehicle =
      data['vehicleApproval'] as Map<dynamic, dynamic>? ?? const {};
    final Map<dynamic, dynamic> documents =
      data['documentApproval'] as Map<dynamic, dynamic>? ?? const {};
    final Map<dynamic, dynamic> photo =
      data['primaryImageApproval'] as Map<dynamic, dynamic>? ?? const {};
    return vehicle['status'] == 'approved' &&
      documents['status'] == 'approved' &&
      photo['status'] == 'approved' &&
      (photo['approvedUrl']?.toString().trim().isNotEmpty ?? false);
    }

  // =========================================================
  // REJECT RIDE
  // =========================================================
  //
  // Reject karne se Rider ki booking cancel nahi hoti.
  // Sirf is Driver ko woh request dobara show nahi hoti.
  // =========================================================

  Future<void> rejectRide({
    required String rideId,
    required String driverId,
    String reason = 'driver_declined',
  }) async {
    final String normalizedRideId = rideId.trim();

    final String normalizedDriverId = driverId.trim();

    if (normalizedRideId.isEmpty) {
      throw Exception('Ride ID is required.');
    }

    if (normalizedDriverId.isEmpty) {
      throw Exception('Driver ID is required.');
    }

    final DocumentReference<Map<String, dynamic>> rideReference =
        _ridesCollection.doc(normalizedRideId);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
          .get(rideReference);

      if (!snapshot.exists) {
        return;
      }

      final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};

      if (data['status'] != RideModel.searching) {
        return;
      }

      transaction.update(rideReference, <String, dynamic>{
        'rejectedDriverIds': FieldValue.arrayUnion(<String>[
          normalizedDriverId,
        ]),
        'lastRejectionReason': reason.trim(),
        'lastRejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // =========================================================
  // ACTIVE DRIVER RIDE STREAM
  // =========================================================

  Stream<RideModel?> watchActiveDriverRide(String driverId) {
    final String normalizedDriverId = driverId.trim();

    if (normalizedDriverId.isEmpty) {
      return Stream.value(null);
    }

    return _ridesCollection
        .where('driverId', isEqualTo: normalizedDriverId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<RideModel> activeRides = <RideModel>[];

          for (final QueryDocumentSnapshot<Map<String, dynamic>> document
              in snapshot.docs) {
            final Map<String, dynamic> data = document.data();

            final String status = data['status'] as String? ?? '';

            final bool isActive =
                status == RideModel.driverAssigned ||
                status == RideModel.driverArriving ||
                status == RideModel.driverArrived ||
                status == RideModel.rideStarted;

            if (!isActive) {
              continue;
            }

            try {
              activeRides.add(
                RideModel.fromMap({
                  ...data,
                  'rideId': data['rideId'] ?? document.id,
                }),
              );
            } catch (_) {
              continue;
            }
          }

          if (activeRides.isEmpty) {
            return null;
          }

          activeRides.sort(
            (RideModel first, RideModel second) =>
                second.createdAt.compareTo(first.createdAt),
          );

          return activeRides.first;
        });
  }

  // =========================================================
  // GET ACTIVE DRIVER RIDE ONCE
  // =========================================================

  Future<RideModel?> getActiveDriverRide(String driverId) async {
    final String normalizedDriverId = driverId.trim();

    if (normalizedDriverId.isEmpty) {
      return null;
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _ridesCollection
        .where('driverId', isEqualTo: normalizedDriverId)
        .get();

    final List<RideModel> activeRides = <RideModel>[];

    for (final QueryDocumentSnapshot<Map<String, dynamic>> document
        in snapshot.docs) {
      final Map<String, dynamic> data = document.data();

      final String status = data['status'] as String? ?? '';

      final bool isActive =
          status == RideModel.driverAssigned ||
          status == RideModel.driverArriving ||
          status == RideModel.driverArrived ||
          status == RideModel.rideStarted;

      if (!isActive) {
        continue;
      }

      try {
        activeRides.add(
          RideModel.fromMap({...data, 'rideId': data['rideId'] ?? document.id}),
        );
      } catch (_) {
        continue;
      }
    }

    if (activeRides.isEmpty) {
      return null;
    }

    activeRides.sort(
      (RideModel first, RideModel second) =>
          second.createdAt.compareTo(first.createdAt),
    );

    return activeRides.first;
  }

  // =========================================================
  // UPDATE DRIVER RIDE STATUS
  // =========================================================

  Future<void> updateRideStatus({
    required String rideId,
    required String driverId,
    required String newStatus,
  }) async {
    final String normalizedRideId = rideId.trim();

    final String normalizedDriverId = driverId.trim();

    final String normalizedStatus = newStatus.trim();

    if (normalizedRideId.isEmpty ||
        normalizedDriverId.isEmpty ||
        normalizedStatus.isEmpty) {
      throw Exception('Ride, Driver and status are required.');
    }

    const Set<String> allowedStatuses = {
      RideModel.driverArriving,
      RideModel.driverArrived,
      RideModel.rideStarted,
      RideModel.completed,
      RideModel.cancelled,
    };

    if (!allowedStatuses.contains(normalizedStatus)) {
      throw Exception('Invalid ride status.');
    }

    final DocumentReference<Map<String, dynamic>> rideReference =
        _ridesCollection.doc(normalizedRideId);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
          .get(rideReference);

      if (!snapshot.exists) {
        throw Exception('Ride not found.');
      }

      final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};

      if (data['driverId'] != normalizedDriverId) {
        throw Exception('This ride is not assigned to this Driver.');
      }

      final Map<String, dynamic> updateData = {
        'status': normalizedStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (normalizedStatus == RideModel.driverArriving) {
        updateData['driverArrivingAt'] = FieldValue.serverTimestamp();
      }

      if (normalizedStatus == RideModel.driverArrived) {
        updateData['driverArrivedAt'] = FieldValue.serverTimestamp();
      }

      if (normalizedStatus == RideModel.rideStarted) {
        updateData['rideStartedAt'] = FieldValue.serverTimestamp();
      }

      if (normalizedStatus == RideModel.completed) {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      if (normalizedStatus == RideModel.cancelled) {
        updateData['cancelledAt'] = FieldValue.serverTimestamp();
      }

      transaction.update(rideReference, updateData);
    });

    if (normalizedStatus == RideModel.completed ||
        normalizedStatus == RideModel.cancelled) {
      await _driversCollection.doc(normalizedDriverId).set(<String, dynamic>{
        'isAvailable': true,
        'activeRideId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // =========================================================
  // DRIVER GOES OFFLINE
  // =========================================================

  Future<void> setDriverOffline({required String driverId}) async {
    final String normalizedDriverId = driverId.trim();

    if (normalizedDriverId.isEmpty) {
      return;
    }

    final RideModel? activeRide = await getActiveDriverRide(normalizedDriverId);

    if (activeRide != null) {
      throw Exception('You cannot go offline during an active ride.');
    }

    await _driversCollection.doc(normalizedDriverId).set(<String, dynamic>{
      'isOnline': false,
      'isAvailable': false,
      'activeRideId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
