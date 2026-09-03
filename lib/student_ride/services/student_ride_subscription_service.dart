import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/student_ride_package_model.dart';
import '../models/student_ride_subscription_model.dart';

class StudentRideSubscriptionService {
  StudentRideSubscriptionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String subscriptionsCollectionName =
      'student_ride_subscriptions';
  static const String studentsCollectionName =
      'student_ride_students';
  static const String packagesCollectionName =
      'student_ride_packages';

  CollectionReference<Map<String, dynamic>>
      get _subscriptionsCollection =>
          _firestore.collection(subscriptionsCollectionName);

  CollectionReference<Map<String, dynamic>>
      get _studentsCollection =>
          _firestore.collection(studentsCollectionName);

  CollectionReference<Map<String, dynamic>>
      get _packagesCollection =>
          _firestore.collection(packagesCollectionName);

  String get _currentParentId {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Parent is not logged in.');
    }

    return user.uid;
  }

  Stream<List<StudentRideSubscriptionModel>>
      watchMySubscriptions() {
    final parentId = _currentParentId;

    return _subscriptionsCollection
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) {
      final subscriptions = snapshot.docs
          .map(
            (document) =>
                StudentRideSubscriptionModel.fromMap(
              document.data(),
              documentId: document.id,
            ),
          )
          .toList();

      subscriptions.sort((first, second) {
        final firstDate =
            first.updatedAt ?? first.createdAt ?? DateTime(2000);
        final secondDate =
            second.updatedAt ?? second.createdAt ?? DateTime(2000);

        return secondDate.compareTo(firstDate);
      });

      return subscriptions;
    });
  }

  Stream<List<StudentRideSubscriptionModel>>
      watchSubscriptionsForAdmin({
    StudentRideSubscriptionStatus? status,
  }) {
    Query<Map<String, dynamic>> query =
        _subscriptionsCollection;

    if (status != null) {
      query = query.where(
        'status',
        isEqualTo: status.name,
      );
    }

    return query.snapshots().map((snapshot) {
      final subscriptions = snapshot.docs
          .map(
            (document) =>
                StudentRideSubscriptionModel.fromMap(
              document.data(),
              documentId: document.id,
            ),
          )
          .toList();

      subscriptions.sort((first, second) {
        final firstDate =
            first.submittedAt ?? first.createdAt ?? DateTime(2000);
        final secondDate =
            second.submittedAt ?? second.createdAt ?? DateTime(2000);

        return secondDate.compareTo(firstDate);
      });

      return subscriptions;
    });
  }

  Future<StudentRideSubscriptionModel?> getSubscription(
    String subscriptionId,
  ) async {
    final id = subscriptionId.trim();

    if (id.isEmpty) {
      throw ArgumentError('Subscription ID is required.');
    }

    final snapshot =
        await _subscriptionsCollection.doc(id).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return StudentRideSubscriptionModel.fromMap(
      data,
      documentId: snapshot.id,
    );
  }

  Future<String> submitSubscription({
    required String studentId,
    required String packageId,
    required DateTime requestedStartDate,
    required String schoolId,
    required bool doorToDoor,
    required bool autoRenew,
    required int requestedServiceDays,
    double estimatedDistanceKm = 0,
    bool applySiblingDiscount = false,
    String morningPickupTime = '',
    String afternoonDropTime = '',
  }) async {
    final parentId = _currentParentId;
    final cleanStudentId = studentId.trim();
    final cleanPackageId = packageId.trim();
    final cleanSchoolId = schoolId.trim();

    if (cleanStudentId.isEmpty) {
      throw ArgumentError('Student ID is required.');
    }

    if (cleanPackageId.isEmpty) {
      throw ArgumentError('Package ID is required.');
    }

    if (cleanSchoolId.isEmpty) {
      throw ArgumentError('School ID is required.');
    }

    if (requestedServiceDays < 1) {
      throw ArgumentError(
        'Requested service days must be at least 1.',
      );
    }

    if (estimatedDistanceKm < 0) {
      throw ArgumentError(
        'Estimated distance cannot be negative.',
      );
    }

    final existingSnapshot = await _subscriptionsCollection
        .where('parentId', isEqualTo: parentId)
        .where('studentId', isEqualTo: cleanStudentId)
        .get();

    final hasOpenSubscription =
        existingSnapshot.docs.any((document) {
      final value = document.data()['status']?.toString();

      return value !=
              StudentRideSubscriptionStatus.cancelled.name &&
          value !=
              StudentRideSubscriptionStatus.expired.name &&
          value !=
              StudentRideSubscriptionStatus.rejected.name;
    });

    if (hasOpenSubscription) {
      throw StateError(
        'This student already has an open Student Ride subscription.',
      );
    }

    final studentReference =
        _studentsCollection.doc(cleanStudentId);
    final packageReference =
        _packagesCollection.doc(cleanPackageId);
    final subscriptionReference =
        _subscriptionsCollection.doc();

    await _firestore.runTransaction((transaction) async {
      final studentSnapshot =
          await transaction.get(studentReference);
      final packageSnapshot =
          await transaction.get(packageReference);

      if (!studentSnapshot.exists) {
        throw StateError('Student profile was not found.');
      }

      if (!packageSnapshot.exists) {
        throw StateError('Student Ride package was not found.');
      }

      final studentData =
          studentSnapshot.data() ?? <String, dynamic>{};
      final packageData =
          packageSnapshot.data() ?? <String, dynamic>{};

      if (studentData['parentId']?.toString() != parentId) {
        throw StateError(
          'You can only request a ride for your own student.',
        );
      }

      final package = StudentRidePackageModel.fromMap(
        packageData,
        documentId: packageSnapshot.id,
      );

      if (!package.isEnabled) {
        throw StateError(
          package.disabledMessage.trim().isEmpty
              ? 'This Student Ride package is unavailable.'
              : package.disabledMessage,
        );
      }

      if (!package.supportsSchool(cleanSchoolId)) {
        throw StateError(
          'This package is not available for the selected school.',
        );
      }

      if (requestedServiceDays < package.minimumDays) {
        throw StateError(
          'This package requires at least '
          '${package.minimumDays} service days.',
        );
      }

      final price = _calculatePrice(
        package: package,
        requestedServiceDays: requestedServiceDays,
        estimatedDistanceKm: estimatedDistanceKm,
        doorToDoor: doorToDoor,
        applySiblingDiscount: applySiblingDiscount,
      );

      transaction.set(
        subscriptionReference,
        <String, dynamic>{
          'subscriptionId': subscriptionReference.id,
          'parentId': parentId,
          'studentId': cleanStudentId,
          'packageId': package.packageId,
          'status':
              StudentRideSubscriptionStatus.routeReview.name,
          'packageName': package.name,
          'tripType': package.tripType.name,
          'priceMode': package.priceMode.name,
          'doorToDoor': doorToDoor && package.doorToDoor,
          'autoRenew':
              autoRenew && package.autoRenewAllowed,
          'schoolId': cleanSchoolId,
          'routeId': '',
          'driverId': '',
          'vehicleId': '',
          'seatNumber': '',
          'morningRouteId': '',
          'morningDriverId': '',
          'morningVehicleId': '',
          'afternoonRouteId': '',
          'afternoonDriverId': '',
          'afternoonVehicleId': '',
          'morningPickupTime': morningPickupTime.trim(),
          'afternoonDropTime': afternoonDropTime.trim(),
          'operatingWeekdays': package.operatingWeekdays,
          'requestedStartDate':
              Timestamp.fromDate(requestedStartDate),
          'approvedStartDate': null,
          'currentPeriodStart': null,
          'currentPeriodEnd': null,
          'nextBillingDate': null,
          'monthlyAmount': price.monthlyAmount,
          'registrationFee': package.registrationFee,
          'discountAmount': price.discountAmount,
          'approvedTotalAmount': price.totalAmount,
          'currencyCode': package.currencyCode,
          'currentInvoiceId': '',
          'paymentStatus': 'pending',
          'pausedAt': null,
          'resumeDate': null,
          'pauseReason': '',
          'cancelledAt': null,
          'cancellationReason': '',
          'rejectionReason': '',
          'adminNotes': '',
          'reviewedBy': '',
          'requestedServiceDays': requestedServiceDays,
          'estimatedDistanceKm': estimatedDistanceKm,
          'siblingDiscountApplied':
              applySiblingDiscount &&
                  package.siblingDiscountAllowed,
          'submittedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    });

    return subscriptionReference.id;
  }

  Future<void> placeOnWaitlist({
    required String subscriptionId,
    required String adminId,
    String adminNotes = '',
  }) {
    return _updateAdminStatus(
      subscriptionId: subscriptionId,
      status: StudentRideSubscriptionStatus.waitlisted,
      adminId: adminId,
      adminNotes: adminNotes,
    );
  }

  Future<void> returnToRouteReview({
    required String subscriptionId,
    required String adminId,
    String adminNotes = '',
  }) {
    return _updateAdminStatus(
      subscriptionId: subscriptionId,
      status: StudentRideSubscriptionStatus.routeReview,
      adminId: adminId,
      adminNotes: adminNotes,
    );
  }

  Future<void> rejectSubscription({
    required String subscriptionId,
    required String adminId,
    required String rejectionReason,
  }) async {
    if (rejectionReason.trim().isEmpty) {
      throw ArgumentError('Rejection reason is required.');
    }

    await _subscriptionsCollection
        .doc(subscriptionId.trim())
        .update(<String, dynamic>{
      'status': StudentRideSubscriptionStatus.rejected.name,
      'rejectionReason': rejectionReason.trim(),
      'reviewedBy': adminId.trim(),
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelByParent({
    required String subscriptionId,
    required String reason,
  }) async {
    final parentId = _currentParentId;
    final reference =
        _subscriptionsCollection.doc(subscriptionId.trim());

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw StateError('Subscription was not found.');
      }

      final data = snapshot.data() ?? <String, dynamic>{};

      if (data['parentId']?.toString() != parentId) {
        throw StateError(
          'You cannot cancel this subscription.',
        );
      }

      final status = data['status']?.toString();

      if (status ==
              StudentRideSubscriptionStatus.cancelled.name ||
          status == StudentRideSubscriptionStatus.expired.name ||
          status == StudentRideSubscriptionStatus.rejected.name) {
        throw StateError(
          'This subscription is already closed.',
        );
      }

      transaction.update(reference, <String, dynamic>{
        'status':
            StudentRideSubscriptionStatus.cancelled.name,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _updateAdminStatus({
    required String subscriptionId,
    required StudentRideSubscriptionStatus status,
    required String adminId,
    required String adminNotes,
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
      'status': status.name,
      'adminNotes': adminNotes.trim(),
      'reviewedBy': cleanAdminId,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  _StudentRidePriceResult _calculatePrice({
    required StudentRidePackageModel package,
    required int requestedServiceDays,
    required double estimatedDistanceKm,
    required bool doorToDoor,
    required bool applySiblingDiscount,
  }) {
    double amount;

    switch (package.priceMode) {
      case StudentRidePackagePriceMode.fixedMonthly:
        amount = package.basePrice;
        break;

      case StudentRidePackagePriceMode.daily:
        amount = package.perDayPrice * requestedServiceDays;
        break;

      case StudentRidePackagePriceMode.routeBased:
        amount = package.basePrice;
        break;

      case StudentRidePackagePriceMode.distanceBased:
        amount = package.basePrice +
            (package.perKmPrice * estimatedDistanceKm);
        break;
    }

    if (doorToDoor && package.doorToDoor) {
      amount += package.doorToDoorCharge;
    }

    double discountAmount = 0;

    if (applySiblingDiscount &&
        package.siblingDiscountAllowed) {
      discountAmount =
          amount * (package.siblingDiscountPercent / 100);

      if (package.maximumDiscountAmount > 0 &&
          discountAmount > package.maximumDiscountAmount) {
        discountAmount = package.maximumDiscountAmount;
      }
    }

    final monthlyAmount =
        (amount - discountAmount).clamp(0, double.infinity);

    return _StudentRidePriceResult(
      monthlyAmount: monthlyAmount.toDouble(),
      discountAmount: discountAmount,
      totalAmount:
          monthlyAmount.toDouble() + package.registrationFee,
    );
  }
}

class _StudentRidePriceResult {
  const _StudentRidePriceResult({
    required this.monthlyAmount,
    required this.discountAmount,
    required this.totalAmount,
  });

  final double monthlyAmount;
  final double discountAmount;
  final double totalAmount;
}

