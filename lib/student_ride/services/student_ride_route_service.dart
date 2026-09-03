import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student_ride_route_model.dart';

class StudentRideRouteService {
  StudentRideRouteService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String routesCollectionName = 'student_ride_routes';

  CollectionReference<Map<String, dynamic>> get _routesCollection =>
      _firestore.collection(routesCollectionName);

  Stream<List<StudentRideRouteModel>> watchAllRoutesForAdmin({
    StudentRideRouteShift? shift,
    StudentRideRouteStatus? status,
  }) {
    Query<Map<String, dynamic>> query = _routesCollection;

    if (shift != null) {
      query = query.where('shift', isEqualTo: shift.name);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      final routes = snapshot.docs
          .map(
            (document) => StudentRideRouteModel.fromMap(
              document.data(),
              documentId: document.id,
            ),
          )
          .toList();

      routes.sort((first, second) {
        final schoolComparison =
            first.schoolName.toLowerCase().compareTo(
                  second.schoolName.toLowerCase(),
                );
        if (schoolComparison != 0) return schoolComparison;

        final shiftComparison = first.shift.index.compareTo(second.shift.index);
        if (shiftComparison != 0) return shiftComparison;

        return first.routeStartTime.compareTo(second.routeStartTime);
      });

      return routes;
    });
  }

  Stream<List<StudentRideRouteModel>> watchRoutesForSchool({
    required String schoolId,
    StudentRideRouteShift? shift,
  }) {
    final cleanSchoolId = schoolId.trim();
    if (cleanSchoolId.isEmpty) {
      throw ArgumentError('School ID is required.');
    }

    Query<Map<String, dynamic>> query = _routesCollection.where(
      'schoolId',
      isEqualTo: cleanSchoolId,
    );

    if (shift != null) {
      query = query.where('shift', isEqualTo: shift.name);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (document) => StudentRideRouteModel.fromMap(
                  document.data(),
                  documentId: document.id,
                ),
              )
              .toList(),
        );
  }

  Future<StudentRideRouteModel?> getRoute(String routeId) async {
    final cleanRouteId = routeId.trim();
    if (cleanRouteId.isEmpty) return null;

    final snapshot = await _routesCollection.doc(cleanRouteId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;

    return StudentRideRouteModel.fromMap(
      data,
      documentId: snapshot.id,
    );
  }

  Future<String> saveRoute({
    required StudentRideRouteModel route,
    required String adminId,
  }) async {
    final cleanAdminId = adminId.trim();
    if (cleanAdminId.isEmpty) {
      throw ArgumentError('Admin ID is required.');
    }

    _validateRoute(route);

    final reference = route.routeId.trim().isEmpty
        ? _routesCollection.doc()
        : _routesCollection.doc(route.routeId.trim());
    final existingSnapshot = await reference.get();

    if (existingSnapshot.exists) {
      final existing = StudentRideRouteModel.fromMap(
        existingSnapshot.data() ?? <String, dynamic>{},
        documentId: existingSnapshot.id,
      );

      if (route.vehicleCapacity < existing.assignedStudentCount) {
        throw StateError(
          'Vehicle capacity cannot be lower than assigned students.',
        );
      }

      if (route.assignedStudentCount != existing.assignedStudentCount) {
        throw StateError(
          'Assigned student count cannot be edited manually.',
        );
      }
    }

    final data = route.toMap()
      ..['routeId'] = reference.id
      ..['updatedBy'] = cleanAdminId
      ..['updatedAt'] = FieldValue.serverTimestamp();

    if (existingSnapshot.exists) {
      data
        ..remove('createdBy')
        ..remove('createdAt');
    } else {
      data
        ..['createdBy'] = cleanAdminId
        ..['createdAt'] = FieldValue.serverTimestamp()
        ..['assignedStudentCount'] = 0;
    }

    await reference.set(data, SetOptions(merge: true));
    return reference.id;
  }

  Future<void> updateRouteFields({
    required String routeId,
    required Map<String, dynamic> fields,
    required String adminId,
  }) async {
    final cleanRouteId = routeId.trim();
    final cleanAdminId = adminId.trim();

    if (cleanRouteId.isEmpty || cleanAdminId.isEmpty) {
      throw ArgumentError('Route ID and Admin ID are required.');
    }
    if (fields.isEmpty) return;

    const protectedFields = <String>{
      'routeId',
      'assignedStudentCount',
      'createdBy',
      'createdAt',
      'updatedBy',
      'updatedAt',
    };

    final safeFields = Map<String, dynamic>.from(fields)
      ..removeWhere((key, value) => protectedFields.contains(key))
      ..['updatedBy'] = cleanAdminId
      ..['updatedAt'] = FieldValue.serverTimestamp();

    if (safeFields.length == 2) return;

    await _routesCollection.doc(cleanRouteId).set(
          safeFields,
          SetOptions(merge: true),
        );
  }

  Future<void> setRouteStatus({
    required String routeId,
    required StudentRideRouteStatus status,
    required String adminId,
    String disabledMessage = '',
  }) async {
    final route = await getRoute(routeId);
    if (route == null) {
      throw StateError('Student Ride route was not found.');
    }

    if (status == StudentRideRouteStatus.active) {
      if (!route.hasCompleteAssignment) {
        throw StateError(
          'Assign an approved driver and vehicle before activating route.',
        );
      }
      if (route.vehicleCapacity <= route.assignedStudentCount) {
        throw StateError('This route has no available seats.');
      }
    }

    await updateRouteFields(
      routeId: routeId,
      adminId: adminId,
      fields: <String, dynamic>{
        'status': status.name,
        'disabledMessage':
            status == StudentRideRouteStatus.active ? '' : disabledMessage.trim(),
      },
    );
  }

  Future<void> updateRouteSchedule({
    required String routeId,
    required String routeStartTime,
    required String schoolArrivalTime,
    required List<int> operatingWeekdays,
    required String adminId,
  }) {
    final startTime = routeStartTime.trim();
    final arrivalTime = schoolArrivalTime.trim();
    final weekdays = operatingWeekdays
        .where((day) => day >= 1 && day <= 7)
        .toSet()
        .toList()
      ..sort();

    if (startTime.isEmpty || arrivalTime.isEmpty || weekdays.isEmpty) {
      throw ArgumentError('Route times and operating weekdays are required.');
    }

    return updateRouteFields(
      routeId: routeId,
      adminId: adminId,
      fields: <String, dynamic>{
        'routeStartTime': startTime,
        'schoolArrivalTime': arrivalTime,
        'operatingWeekdays': weekdays,
      },
    );
  }

  Future<void> updateRouteAssignment({
    required String routeId,
    required String driverId,
    required String driverName,
    required String vehicleId,
    required String vehicleRegistrationNumber,
    required int vehicleCapacity,
    required String adminId,
  }) async {
    if (vehicleCapacity < 1) {
      throw ArgumentError('Vehicle capacity must be at least 1.');
    }

    final route = await getRoute(routeId);
    if (route == null) {
      throw StateError('Student Ride route was not found.');
    }
    if (vehicleCapacity < route.assignedStudentCount) {
      throw StateError(
        'Vehicle capacity cannot be lower than assigned students.',
      );
    }

    await updateRouteFields(
      routeId: routeId,
      adminId: adminId,
      fields: <String, dynamic>{
        'driverId': driverId.trim(),
        'driverName': driverName.trim(),
        'vehicleId': vehicleId.trim(),
        'vehicleRegistrationNumber': vehicleRegistrationNumber.trim(),
        'vehicleCapacity': vehicleCapacity,
      },
    );
  }

  Future<void> replaceRouteStops({
    required String routeId,
    required List<StudentRideRouteStopModel> stops,
    required String adminId,
  }) {
    final orderedStops = List<StudentRideRouteStopModel>.from(stops)
      ..sort((first, second) => first.stopOrder.compareTo(second.stopOrder));

    final stopIds = orderedStops.map((stop) => stop.stopId.trim()).toList();
    if (stopIds.any((id) => id.isEmpty) || stopIds.toSet().length != stopIds.length) {
      throw ArgumentError('Every route stop needs a unique Stop ID.');
    }

    return updateRouteFields(
      routeId: routeId,
      adminId: adminId,
      fields: <String, dynamic>{
        'stops': orderedStops.map((stop) => stop.toMap()).toList(),
      },
    );
  }

  Future<void> deleteRoute({
    required String routeId,
    required String adminId,
  }) async {
    final cleanAdminId = adminId.trim();
    if (cleanAdminId.isEmpty) {
      throw ArgumentError('Admin ID is required.');
    }

    final route = await getRoute(routeId);
    if (route == null) return;

    if (route.assignedStudentCount > 0) {
      throw StateError(
        'Remove all student assignments before deleting this route.',
      );
    }

    await _routesCollection.doc(route.routeId).delete();
  }

  void _validateRoute(StudentRideRouteModel route) {
    if (route.routeName.trim().isEmpty ||
        route.schoolId.trim().isEmpty ||
        route.schoolName.trim().isEmpty ||
        route.routeStartTime.trim().isEmpty ||
        route.schoolArrivalTime.trim().isEmpty) {
      throw ArgumentError(
        'Route name, school and schedule information are required.',
      );
    }

    if (route.vehicleCapacity < 1 ||
        route.assignedStudentCount < 0 ||
        route.reservedSeatCount < 0 ||
        route.estimatedDistanceKm < 0 ||
        route.estimatedDurationMinutes < 0) {
      throw ArgumentError('Student Ride route values are invalid.');
    }

    if (route.operatingWeekdays.isEmpty ||
        route.operatingWeekdays.any((day) => day < 1 || day > 7)) {
      throw ArgumentError('Select valid operating weekdays.');
    }

    if (route.assignedStudentCount + route.reservedSeatCount >
        route.vehicleCapacity) {
      throw ArgumentError('Assigned and reserved seats exceed capacity.');
    }
  }
}
