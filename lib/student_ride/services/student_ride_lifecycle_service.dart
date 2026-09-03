import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/student_ride_invoice_model.dart';
import '../models/student_ride_package_model.dart';
import '../models/student_ride_subscription_model.dart';

class StudentRideLifecycleService {
  StudentRideLifecycleService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>>
      get _subscriptions =>
          _firestore.collection('student_ride_subscriptions');

  CollectionReference<Map<String, dynamic>> get _invoices =>
      _firestore.collection('student_ride_invoices');

  CollectionReference<Map<String, dynamic>> get _packages =>
      _firestore.collection('student_ride_packages');

  String get _currentParentId {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Parent is not logged in.');
    }

    return user.uid;
  }

  Future<void> requestPauseByParent({
    required String subscriptionId,
    required DateTime resumeDate,
    required String reason,
  }) async {
    final parentId = _currentParentId;

    await _pauseSubscription(
      subscriptionId: subscriptionId,
      resumeDate: resumeDate,
      reason: reason,
      actorId: parentId,
      expectedParentId: parentId,
    );
  }

  Future<void> pauseByAdmin({
    required String subscriptionId,
    required DateTime resumeDate,
    required String reason,
    required String adminId,
  }) {
    return _pauseSubscription(
      subscriptionId: subscriptionId,
      resumeDate: resumeDate,
      reason: reason,
      actorId: adminId.trim(),
    );
  }

  Future<void> _pauseSubscription({
    required String subscriptionId,
    required DateTime resumeDate,
    required String reason,
    required String actorId,
    String? expectedParentId,
  }) async {
    final cleanSubscriptionId = subscriptionId.trim();
    final cleanActorId = actorId.trim();

    if (cleanSubscriptionId.isEmpty) {
      throw ArgumentError('Subscription ID is required.');
    }

    if (cleanActorId.isEmpty) {
      throw ArgumentError('Actor ID is required.');
    }

    if (!resumeDate.isAfter(DateTime.now())) {
      throw ArgumentError(
        'Resume date must be in the future.',
      );
    }

    final subscriptionReference =
        _subscriptions.doc(cleanSubscriptionId);

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

      final packageReference =
          _packages.doc(subscription.packageId);
      final packageSnapshot =
          await transaction.get(packageReference);

      if (!packageSnapshot.exists) {
        throw StateError(
          'Subscription package was not found.',
        );
      }

      final package = StudentRidePackageModel.fromMap(
        packageSnapshot.data() ?? <String, dynamic>{},
        documentId: packageSnapshot.id,
      );

      if (expectedParentId != null &&
          subscription.parentId != expectedParentId) {
        throw StateError(
          'You cannot pause this subscription.',
        );
      }

      if (!package.pauseAllowed) {
        throw StateError(
          'Pause is disabled for this Student Ride package.',
        );
      }

      if (subscription.status !=
          StudentRideSubscriptionStatus.active) {
        throw StateError(
          'Only an active subscription can be paused.',
        );
      }

      if (subscription.paymentStatus != 'paid') {
        throw StateError(
          'Unpaid subscription cannot be paused.',
        );
      }

      transaction.update(
        subscriptionReference,
        <String, dynamic>{
          'status':
              StudentRideSubscriptionStatus.paused.name,
          'pausedAt': FieldValue.serverTimestamp(),
          'resumeDate': Timestamp.fromDate(resumeDate),
          'pauseReason': reason.trim(),
          'reviewedBy': cleanActorId,
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  Future<void> resumeSubscription({
    required String subscriptionId,
    required String actorId,
  }) async {
    final cleanSubscriptionId = subscriptionId.trim();
    final cleanActorId = actorId.trim();

    if (cleanSubscriptionId.isEmpty) {
      throw ArgumentError('Subscription ID is required.');
    }

    if (cleanActorId.isEmpty) {
      throw ArgumentError('Actor ID is required.');
    }

    final reference =
        _subscriptions.doc(cleanSubscriptionId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw StateError('Subscription was not found.');
      }

      final subscription =
          StudentRideSubscriptionModel.fromMap(
        snapshot.data() ?? <String, dynamic>{},
        documentId: snapshot.id,
      );

      if (subscription.status !=
          StudentRideSubscriptionStatus.paused) {
        throw StateError(
          'Only a paused subscription can be resumed.',
        );
      }

      if (subscription.paymentStatus != 'paid') {
        throw StateError(
          'Payment is required before resuming service.',
        );
      }

      if (!subscription.hasRouteAssignment) {
        throw StateError(
          'Complete route assignment before resuming.',
        );
      }

      transaction.update(reference, <String, dynamic>{
        'status': StudentRideSubscriptionStatus.active.name,
        'pausedAt': null,
        'resumeDate': null,
        'pauseReason': '',
        'reviewedBy': cleanActorId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<int> markOverdueInvoices() async {
    final now = DateTime.now();

    final snapshot = await _invoices
        .where(
          'status',
          isEqualTo:
              StudentRideInvoiceStatus.paymentPending.name,
        )
        .limit(400)
        .get();

    final overdueDocuments = snapshot.docs.where((document) {
      final invoice = StudentRideInvoiceModel.fromMap(
        document.data(),
        documentId: document.id,
      );

      return invoice.amountPaid < invoice.totalAmount &&
          now.isAfter(invoice.dueDate);
    }).toList();

    if (overdueDocuments.isEmpty) {
      return 0;
    }

    final batch = _firestore.batch();

    for (final document in overdueDocuments) {
      batch.update(document.reference, <String, dynamic>{
        'status': StudentRideInvoiceStatus.overdue.name,
        'paymentStatus': 'overdue',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final subscriptionId =
          document.data()['subscriptionId']
              ?.toString()
              .trim();

      if (subscriptionId != null &&
          subscriptionId.isNotEmpty) {
        batch.set(
          _subscriptions.doc(subscriptionId),
          <String, dynamic>{
            'paymentStatus': 'overdue',
            'status': StudentRideSubscriptionStatus
                .paymentPending.name,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
    return overdueDocuments.length;
  }

  Future<void> expireSubscription({
    required String subscriptionId,
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

    final reference =
        _subscriptions.doc(cleanSubscriptionId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw StateError('Subscription was not found.');
      }

      final subscription =
          StudentRideSubscriptionModel.fromMap(
        snapshot.data() ?? <String, dynamic>{},
        documentId: snapshot.id,
      );

      if (subscription.status ==
              StudentRideSubscriptionStatus.cancelled ||
          subscription.status ==
              StudentRideSubscriptionStatus.rejected) {
        throw StateError(
          'Closed subscription cannot be expired.',
        );
      }

      transaction.update(reference, <String, dynamic>{
        'status': StudentRideSubscriptionStatus.expired.name,
        'paymentStatus': 'expired',
        'adminNotes': reason.trim(),
        'reviewedBy': cleanAdminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<int> expireEndedSubscriptions() async {
    final now = DateTime.now();

    final snapshot = await _subscriptions
        .where(
          'status',
          whereIn: <String>[
            StudentRideSubscriptionStatus.active.name,
            StudentRideSubscriptionStatus.paused.name,
          ],
        )
        .limit(400)
        .get();

    final endedDocuments = snapshot.docs.where((document) {
      final subscription =
          StudentRideSubscriptionModel.fromMap(
        document.data(),
        documentId: document.id,
      );

      final periodEnd = subscription.currentPeriodEnd;

      return periodEnd != null &&
          now.isAfter(periodEnd) &&
          !subscription.autoRenew;
    }).toList();

    if (endedDocuments.isEmpty) {
      return 0;
    }

    final batch = _firestore.batch();

    for (final document in endedDocuments) {
      batch.update(document.reference, <String, dynamic>{
        'status': StudentRideSubscriptionStatus.expired.name,
        'paymentStatus': 'expired',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return endedDocuments.length;
  }
}
