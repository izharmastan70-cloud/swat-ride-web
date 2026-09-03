import 'package:cloud_firestore/cloud_firestore.dart';

class DriverAvailabilityService {
  DriverAvailabilityService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // =========================================================
  // COLLECTION
  // =========================================================

  CollectionReference<Map<String, dynamic>>
      get _driversCollection =>
          _firestore.collection('drivers');

  // =========================================================
  // WATCH SINGLE DRIVER STATUS
  // =========================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchDriverStatus(
    String driverId,
  ) {
    final String normalizedDriverId =
        driverId.trim();

    if (normalizedDriverId.isEmpty) {
      return const Stream<
          DocumentSnapshot<Map<String, dynamic>>>.empty();
    }

    return _driversCollection
        .doc(normalizedDriverId)
        .snapshots();
  }

  // =========================================================
  // GET DRIVER STATUS ONCE
  // =========================================================

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      getDriverStatus(
    String driverId,
  ) async {
    final String normalizedDriverId =
        driverId.trim();

    if (normalizedDriverId.isEmpty) {
      return null;
    }

    return _driversCollection
        .doc(normalizedDriverId)
        .get();
  }

  // =========================================================
  // GET ONLINE + AVAILABLE + APPROVED DRIVERS
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      getAvailableDrivers({
    String? vehicleType,
  }) {
    Query<Map<String, dynamic>> query =
        _driversCollection
            .where(
              'isOnline',
              isEqualTo: true,
            )
            .where(
              'isAvailable',
              isEqualTo: true,
            )
            .where(
              'status',
              isEqualTo: 'approved',
            );

    final String normalizedVehicleType =
        vehicleType?.trim() ?? '';

    if (normalizedVehicleType.isNotEmpty) {
      query = query.where(
        'vehicleType',
        isEqualTo: normalizedVehicleType,
      );
    }

    return query.snapshots();
  }

  // =========================================================
  // CHECK AVAILABLE DRIVER
  // =========================================================

  Future<bool> hasAvailableDriver({
    required String vehicleType,
  }) async {
    final String normalizedVehicleType =
        vehicleType.trim();

    if (normalizedVehicleType.isEmpty) {
      return false;
    }

    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _driversCollection
            .where(
              'isOnline',
              isEqualTo: true,
            )
            .where(
              'isAvailable',
              isEqualTo: true,
            )
            .where(
              'status',
              isEqualTo: 'approved',
            )
            .where(
              'vehicleType',
              isEqualTo: normalizedVehicleType,
            )
            .limit(1)
            .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> setOnlineStatus({
    required String driverId,
    required bool isOnline,
    String? driverName,
    String? vehicleType,
    String? vehicleNumber,
  }) async {
    final String normalizedDriverId =
        driverId.trim();

    if (normalizedDriverId.isEmpty) {
      throw Exception(
        'Driver ID is required.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        driverReference =
        _driversCollection.doc(
      normalizedDriverId,
    );

    await _firestore.runTransaction(
      (Transaction transaction) async {
        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(driverReference);

        final Map<String, dynamic> currentData =
            snapshot.data() ??
                <String, dynamic>{};

        final String currentStatus =
            currentData['status'] as String? ??
                'pending';
        final bool approvalComplete = _hasApprovedVehicleAndPhoto(currentData);

        final String activeRideId =
            currentData['activeRideId']
                    as String? ??
                '';

        // -----------------------------------------------------
        // GOING ONLINE
        // -----------------------------------------------------

        if (isOnline) {
          final bool isApproved =
              currentStatus == 'approved';

            if (!isApproved || !approvalComplete) {
            throw Exception(
              'Your vehicle, documents and primary photo must be approved before going online.',
            );
          }

          transaction.set(
            driverReference,
            <String, dynamic>{
              if ((driverName ?? '')
                  .trim()
                  .isNotEmpty)
                'fullName':
                    driverName!.trim(),

              if ((vehicleType ?? '')
                  .trim()
                  .isNotEmpty)
                'vehicleType':
                    vehicleType!.trim(),

              if ((vehicleNumber ?? '')
                  .trim()
                  .isNotEmpty)
                'vehicleNumber':
                    vehicleNumber!.trim(),

              'isOnline': true,

              // Driver is available only when there is
              // no active ride.
              'isAvailable':
                  activeRideId.isEmpty,

              'lastOnlineAt':
                  FieldValue.serverTimestamp(),

              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          return;
        }

        // -----------------------------------------------------
        // GOING OFFLINE
        // -----------------------------------------------------

        if (activeRideId.isNotEmpty) {
          throw Exception(
            'You cannot go offline during an active ride.',
          );
        }

        transaction.set(
          driverReference,
          <String, dynamic>{
            'isOnline': false,
            'isAvailable': false,
            'lastOfflineAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      },
    );
  }

  // =========================================================
  // OLD METHOD COMPATIBILITY
  // =========================================================
  //
  // Existing screens/services calling updateOnlineStatus()
  // will continue working.
  // =========================================================

  Future<void> updateOnlineStatus({
    required String driverId,
    required bool isOnline,
  }) async {
    await setOnlineStatus(
      driverId: driverId,
      isOnline: isOnline,
    );
  }

  // =========================================================
  // UPDATE AVAILABILITY SAFELY
  // =========================================================

  Future<void> updateAvailability({
    required String driverId,
    required bool isAvailable,
  }) async {
    final String normalizedDriverId =
        driverId.trim();

    if (normalizedDriverId.isEmpty) {
      throw Exception(
        'Driver ID is required.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        driverReference =
        _driversCollection.doc(
      normalizedDriverId,
    );

    await _firestore.runTransaction(
      (Transaction transaction) async {
        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(driverReference);

        if (!snapshot.exists) {
          throw Exception(
            'Driver profile does not exist.',
          );
        }

        final Map<String, dynamic> data =
            snapshot.data() ??
                <String, dynamic>{};

        final bool isOnline =
            data['isOnline'] as bool? ?? false;

        final String status =
            data['status'] as String? ??
                'pending';
        final bool approvalComplete = _hasApprovedVehicleAndPhoto(data);

        final String activeRideId =
            data['activeRideId']
                    as String? ??
                '';

        if (!isOnline && isAvailable) {
          throw Exception(
            'Please go online first.',
          );
        }

        if (status != 'approved' || !approvalComplete) {
          throw Exception(
            'Your vehicle, documents and primary photo are not approved.',
          );
        }

        if (activeRideId.isNotEmpty &&
            isAvailable) {
          throw Exception(
            'You cannot accept another ride during an active ride.',
          );
        }

        transaction.update(
          driverReference,
          <String, dynamic>{
            'isAvailable': isAvailable,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
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
  // MARK DRIVER BUSY
  // =========================================================

  Future<void> markDriverBusy({
    required String driverId,
    required String rideId,
  }) async {
    final String normalizedDriverId =
        driverId.trim();

    final String normalizedRideId =
        rideId.trim();

    if (normalizedDriverId.isEmpty ||
        normalizedRideId.isEmpty) {
      throw Exception(
        'Driver ID and Ride ID are required.',
      );
    }

    await _driversCollection
        .doc(normalizedDriverId)
        .set(
      <String, dynamic>{
        'isOnline': true,
        'isAvailable': false,
        'activeRideId': normalizedRideId,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // =========================================================
  // MARK DRIVER AVAILABLE AFTER RIDE
  // =========================================================

  Future<void> markDriverAvailable({
    required String driverId,
  }) async {
    final String normalizedDriverId =
        driverId.trim();

    if (normalizedDriverId.isEmpty) {
      return;
    }

    final DocumentReference<Map<String, dynamic>>
        driverReference =
        _driversCollection.doc(
      normalizedDriverId,
    );

    await _firestore.runTransaction(
      (Transaction transaction) async {
        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(driverReference);

        if (!snapshot.exists) {
          return;
        }

        final Map<String, dynamic> data =
            snapshot.data() ??
                <String, dynamic>{};

        final bool isOnline =
            data['isOnline'] as bool? ?? false;

        transaction.update(
          driverReference,
          <String, dynamic>{
            'activeRideId': null,
            'isAvailable': isOnline,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // =========================================================
  // UPDATE DRIVER LOCATION
  // =========================================================

  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  }) async {
    final String normalizedDriverId =
        driverId.trim();

    if (normalizedDriverId.isEmpty) {
      throw Exception(
        'Driver ID is required.',
      );
    }

    if (latitude < -90 || latitude > 90) {
      throw Exception(
        'Invalid latitude.',
      );
    }

    if (longitude < -180 || longitude > 180) {
      throw Exception(
        'Invalid longitude.',
      );
    }

    await _driversCollection
        .doc(normalizedDriverId)
        .set(
      <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'locationUpdatedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // =========================================================
  // SET DRIVER OFFLINE
  // =========================================================

  Future<void> setDriverOffline({
    required String driverId,
  }) async {
    await setOnlineStatus(
      driverId: driverId,
      isOnline: false,
    );
  }
}