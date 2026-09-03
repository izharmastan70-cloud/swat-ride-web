import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student_ride_route_model.dart';
import '../models/student_ride_subscription_model.dart';

class StudentRideRouteAssignmentService {
  StudentRideRouteAssignmentService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String routesCollectionName =
      'student_ride_routes';
  static const String subscriptionsCollectionName =
      'student_ride_subscriptions';

  CollectionReference<Map<String, dynamic>>
      get _routesCollection =>
          _firestore.collection(routesCollectionName);

  CollectionReference<Map<String, dynamic>>
      get _subscriptionsCollection =>
          _firestore.collection(subscriptionsCollectionName);

  Stream<List<StudentRideRouteModel>> watchAvailableRoutes({
    required String schoolId,
    required StudentRideRouteShift shift,
  }) {
    return _routesCollection
        .where('schoolId', isEqualTo: schoolId.trim())
        .where('shift', isEqualTo: shift.name)
        .snapshots()
        .map((snapshot) {
      final routes = snapshot.docs
          .map(
            (document) => StudentRideRouteModel.fromMap(
              document.data(),
              documentId: document.id,
            ),
          )
          .where((route) {
        return route.status == StudentRideRouteStatus.active &&
            route.hasCompleteAssignment &&
            route.availableSeats > 0;
      }).toList();

      routes.sort(
        (first, second) =>
            first.routeName.compareTo(second.routeName),
      );

      return routes;
    });
  }

  Future<void> assignRoute({
    required String subscriptionId,
    required String routeId,
    required StudentRideRouteShift shift,
    required String seatNumber,
    required String adminId,
    String adminNotes = '',
  }) async {
    final cleanSubscriptionId = subscriptionId.trim();
    final cleanRouteId = routeId.trim();
    final cleanSeatNumber = seatNumber.trim();
    final cleanAdminId = adminId.trim();

    if (cleanSubscriptionId.isEmpty) {
      throw ArgumentError('Subscription ID is required.');
    }

    if (cleanRouteId.isEmpty) {
      throw ArgumentError('Route ID is required.');
    }

    if (cleanAdminId.isEmpty) {
      throw ArgumentError('Admin ID is required.');
    }

    final subscriptionReference =
        _subscriptionsCollection.doc(cleanSubscriptionId);
    final routeReference =
        _routesCollection.doc(cleanRouteId);

    await _firestore.runTransaction((transaction) async {
      final subscriptionSnapshot =
          await transaction.get(subscriptionReference);
      final routeSnapshot =
          await transaction.get(routeReference);

      if (!subscriptionSnapshot.exists) {
        throw StateError('Subscription was not found.');
      }

      if (!routeSnapshot.exists) {
        throw StateError('Student Ride route was not found.');
      }

      final subscriptionData =
          subscriptionSnapshot.data() ?? <String, dynamic>{};
      final routeData =
          routeSnapshot.data() ?? <String, dynamic>{};

      final subscription =
          StudentRideSubscriptionModel.fromMap(
        subscriptionData,
        documentId: subscriptionSnapshot.id,
      );

      final route = StudentRideRouteModel.fromMap(
        routeData,
        documentId: routeSnapshot.id,
      );

      _validateSubscriptionStatus(subscription.status);
      _validateTripShift(
        tripType: subscription.tripType,
        shift: shift,
      );

      if (route.shift != shift) {
        throw StateError(
          'Selected route does not match the requested shift.',
        );
      }

      if (route.status != StudentRideRouteStatus.active) {
        throw StateError(
          route.disabledMessage.trim().isEmpty
              ? 'Selected route is not active.'
              : route.disabledMessage,
        );
      }

      if (!route.hasCompleteAssignment) {
        throw StateError(
          'Route must have an approved driver and vehicle.',
        );
      }

      if (route.schoolId != subscription.schoolId) {
        throw StateError(
          'Route and subscription schools do not match.',
        );
      }

      final existingRouteId =
          shift == StudentRideRouteShift.morning
              ? subscription.morningRouteId
              : subscription.afternoonRouteId;

      if (existingRouteId.isNotEmpty) {
        if (existingRouteId == cleanRouteId) {
          throw StateError(
            'This route is already assigned for the selected shift.',
          );
        }

        throw StateError(
          'Remove the existing shift assignment before assigning another route.',
        );
      }

      if (!route.hasAvailableSeat) {
        if (route.waitlistEnabled) {
          transaction.update(
            subscriptionReference,
            <String, dynamic>{
              'status':
                  StudentRideSubscriptionStatus.waitlisted.name,
              'adminNotes': adminNotes.trim().isEmpty
                  ? 'Selected route is currently full.'
                  : adminNotes.trim(),
              'reviewedBy': cleanAdminId,
              'reviewedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );

          return;
        }

        throw StateError(
          'Selected route has no available seat.',
        );
      }

      final bool assigningMorning =
          shift == StudentRideRouteShift.morning;

      final String morningRouteId = assigningMorning
          ? route.routeId
          : subscription.morningRouteId;
      final String morningDriverId = assigningMorning
          ? route.driverId
          : subscription.morningDriverId;
      final String morningVehicleId = assigningMorning
          ? route.vehicleId
          : subscription.morningVehicleId;

      final String afternoonRouteId = assigningMorning
          ? subscription.afternoonRouteId
          : route.routeId;
      final String afternoonDriverId = assigningMorning
          ? subscription.afternoonDriverId
          : route.driverId;
      final String afternoonVehicleId = assigningMorning
          ? subscription.afternoonVehicleId
          : route.vehicleId;

      if (subscription.tripType == 'twoWay' &&
          morningDriverId.isNotEmpty &&
          afternoonDriverId.isNotEmpty &&
          morningDriverId != afternoonDriverId) {
        throw StateError(
          'Two-way monthly service must use the same approved '
          'Student Ride Driver for both shifts.',
        );
      }

      final bool morningComplete =
          morningRouteId.isNotEmpty &&
              morningDriverId.isNotEmpty &&
              morningVehicleId.isNotEmpty;

      final bool afternoonComplete =
          afternoonRouteId.isNotEmpty &&
              afternoonDriverId.isNotEmpty &&
              afternoonVehicleId.isNotEmpty;

      final bool assignmentComplete;
      if (subscription.tripType == 'morningOnly') {
        assignmentComplete = morningComplete;
      } else if (subscription.tripType == 'afternoonOnly') {
        assignmentComplete = afternoonComplete;
      } else {
        assignmentComplete =
            morningComplete && afternoonComplete;
      }

      final int assignedAfter =
          route.assignedStudentCount + 1;
      final int usedSeatsAfter =
          assignedAfter + route.reservedSeatCount;

      transaction.update(
        routeReference,
        <String, dynamic>{
          'assignedStudentCount': assignedAfter,
          if (usedSeatsAfter >= route.vehicleCapacity)
            'status': StudentRideRouteStatus.full.name,
          'updatedBy': cleanAdminId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      final Map<String, dynamic> subscriptionUpdates =
          <String, dynamic>{
        if (assigningMorning) ...<String, dynamic>{
          'morningRouteId': route.routeId,
          'morningDriverId': route.driverId,
          'morningVehicleId': route.vehicleId,
          'morningPickupTime': route.routeStartTime,
        } else ...<String, dynamic>{
          'afternoonRouteId': route.routeId,
          'afternoonDriverId': route.driverId,
          'afternoonVehicleId': route.vehicleId,
          'afternoonDropTime': route.routeStartTime,
        },
        'seatNumber': cleanSeatNumber,
        'status': assignmentComplete
            ? StudentRideSubscriptionStatus
                .paymentPending.name
            : StudentRideSubscriptionStatus.routeReview.name,
        'adminNotes': adminNotes.trim(),
        'reviewedBy': cleanAdminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Keep legacy assignment fields populated for old UI code.
      if (subscription.routeId.isEmpty ||
          subscription.tripType != 'twoWay') {
        subscriptionUpdates.addAll(<String, dynamic>{
          'routeId': route.routeId,
          'driverId': route.driverId,
          'vehicleId': route.vehicleId,
        });
      }

      transaction.update(
        subscriptionReference,
        subscriptionUpdates,
      );
    });
  }

  Future<void> removeRouteAssignment({
    required String subscriptionId,
    required StudentRideRouteShift shift,
    required String adminId,
    String reason = '',
  }) async {
    final cleanSubscriptionId = subscriptionId.trim();
    final cleanAdminId = adminId.trim();

    if (cleanSubscriptionId.isEmpty) {
      throw ArgumentError('Subscription ID is required.');
    }

    if (cleanAdminId.isEmpty) {
      throw ArgumentError('Admin ID is required.');
    }

    final subscriptionReference =
        _subscriptionsCollection.doc(cleanSubscriptionId);

    await _firestore.runTransaction((transaction) async {
      final subscriptionSnapshot =
          await transaction.get(subscriptionReference);

      if (!subscriptionSnapshot.exists) {
        throw StateError('Subscription was not found.');
      }

      final subscription =
          StudentRideSubscriptionModel.fromMap(
        subscriptionSnapshot.data() ?? <String, dynamic>{},
        documentId: subscriptionSnapshot.id,
      );

      final bool removingMorning =
          shift == StudentRideRouteShift.morning;

      final String assignedRouteId = removingMorning
          ? subscription.morningRouteId
          : subscription.afternoonRouteId;

      if (assignedRouteId.isEmpty) {
        throw StateError(
          'No route is assigned for the selected shift.',
        );
      }

      final routeReference =
          _routesCollection.doc(assignedRouteId);
      final routeSnapshot =
          await transaction.get(routeReference);

      if (!routeSnapshot.exists) {
        throw StateError(
          'Assigned Student Ride route was not found.',
        );
      }

      final route = StudentRideRouteModel.fromMap(
        routeSnapshot.data() ?? <String, dynamic>{},
        documentId: routeSnapshot.id,
      );

      final int assignedAfter =
          route.assignedStudentCount > 0
              ? route.assignedStudentCount - 1
              : 0;

      final Map<String, dynamic> routeUpdates =
          <String, dynamic>{
        'assignedStudentCount': assignedAfter,
        'updatedBy': cleanAdminId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (route.status == StudentRideRouteStatus.full) {
        routeUpdates['status'] =
            StudentRideRouteStatus.active.name;
      }

      transaction.update(routeReference, routeUpdates);

      final String remainingRouteId = removingMorning
          ? subscription.afternoonRouteId
          : subscription.morningRouteId;
      final String remainingDriverId = removingMorning
          ? subscription.afternoonDriverId
          : subscription.morningDriverId;
      final String remainingVehicleId = removingMorning
          ? subscription.afternoonVehicleId
          : subscription.morningVehicleId;

      final Map<String, dynamic> subscriptionUpdates =
          <String, dynamic>{
        if (removingMorning) ...<String, dynamic>{
          'morningRouteId': '',
          'morningDriverId': '',
          'morningVehicleId': '',
          'morningPickupTime': '',
        } else ...<String, dynamic>{
          'afternoonRouteId': '',
          'afternoonDriverId': '',
          'afternoonVehicleId': '',
          'afternoonDropTime': '',
        },
        'status':
            StudentRideSubscriptionStatus.routeReview.name,
        'paymentStatus': 'pending',
        'currentInvoiceId': '',
        'adminNotes': reason.trim(),
        'reviewedBy': cleanAdminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (subscription.routeId == assignedRouteId) {
        subscriptionUpdates.addAll(<String, dynamic>{
          'routeId': remainingRouteId,
          'driverId': remainingDriverId,
          'vehicleId': remainingVehicleId,
          if (remainingRouteId.isEmpty) 'seatNumber': '',
        });
      }

      transaction.update(
        subscriptionReference,
        subscriptionUpdates,
      );
    });
  }
  Future<void> sendToWaitlist({
    required String subscriptionId,
    required String adminId,
    required String reason,
  }) async {
    final cleanSubscriptionId = subscriptionId.trim();
    final cleanAdminId = adminId.trim();

    if (cleanSubscriptionId.isEmpty) {
      throw ArgumentError('Subscription ID is required.');
    }

    if (cleanAdminId.isEmpty) {
      throw ArgumentError('Admin ID is required.');
    }

    await _subscriptionsCollection
        .doc(cleanSubscriptionId)
        .update(<String, dynamic>{
      'status': StudentRideSubscriptionStatus.waitlisted.name,
      'adminNotes': reason.trim(),
      'reviewedBy': cleanAdminId,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _validateSubscriptionStatus(
    StudentRideSubscriptionStatus status,
  ) {
    const allowedStatuses =
        <StudentRideSubscriptionStatus>{
      StudentRideSubscriptionStatus.submitted,
      StudentRideSubscriptionStatus.routeReview,
      StudentRideSubscriptionStatus.waitlisted,
    };

    if (!allowedStatuses.contains(status)) {
      throw StateError(
        'Routes cannot be assigned in the ${status.name} status.',
      );
    }
  }

  void _validateTripShift({
    required String tripType,
    required StudentRideRouteShift shift,
  }) {
    if (tripType == 'morningOnly' &&
        shift != StudentRideRouteShift.morning) {
      throw StateError(
        'Morning-only package cannot use an afternoon route.',
      );
    }

    if (tripType == 'afternoonOnly' &&
        shift != StudentRideRouteShift.afternoon) {
      throw StateError(
        'Afternoon-only package cannot use a morning route.',
      );
    }
  }
}


