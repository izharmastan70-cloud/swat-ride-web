import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/student_ride_invoice_model.dart';
import '../models/student_ride_settings_model.dart';
import '../models/student_ride_subscription_model.dart';
import 'student_ride_commission_service.dart';

class StudentRideInvoiceService {
  StudentRideInvoiceService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    StudentRideCommissionService? commissionService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _commissionService = commissionService ??
            StudentRideCommissionService(
              firestore: firestore,
            );

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StudentRideCommissionService _commissionService;

  static const String invoicesCollectionName =
      'student_ride_invoices';
  static const String subscriptionsCollectionName =
      'student_ride_subscriptions';
  static const String studentsCollectionName =
      'student_ride_students';

  CollectionReference<Map<String, dynamic>>
      get _invoicesCollection =>
          _firestore.collection(invoicesCollectionName);

  CollectionReference<Map<String, dynamic>>
      get _subscriptionsCollection =>
          _firestore.collection(subscriptionsCollectionName);

  CollectionReference<Map<String, dynamic>>
      get _studentsCollection =>
          _firestore.collection(studentsCollectionName);

  DocumentReference<Map<String, dynamic>>
      get _settingsReference => _firestore
          .collection('student_ride_config')
          .doc('global_settings');

  String get _currentParentId {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Parent is not logged in.');
    }

    return user.uid;
  }

  Stream<List<StudentRideInvoiceModel>> watchMyInvoices() {
    final parentId = _currentParentId;

    return _invoicesCollection
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map(_mapAndSortInvoices);
  }

  Stream<List<StudentRideInvoiceModel>> watchAdminInvoices({
    StudentRideInvoiceStatus? status,
  }) {
    Query<Map<String, dynamic>> query =
        _invoicesCollection;

    if (status != null) {
      query = query.where(
        'status',
        isEqualTo: status.name,
      );
    }

    return query.snapshots().map(_mapAndSortInvoices);
  }

  Future<StudentRideInvoiceModel?> getInvoice(
    String invoiceId,
  ) async {
    final cleanInvoiceId = invoiceId.trim();

    if (cleanInvoiceId.isEmpty) {
      throw ArgumentError('Invoice ID is required.');
    }

    final snapshot =
        await _invoicesCollection.doc(cleanInvoiceId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return StudentRideInvoiceModel.fromMap(
      data,
      documentId: snapshot.id,
    );
  }

  Future<String> createMonthlyInvoice({
    required String subscriptionId,
    required int billingMonth,
    required int billingYear,
    required String adminId,
    double promoDiscount = 0,
    double adjustmentAmount = 0,
    String adminNote = '',
  }) async {
    final cleanSubscriptionId = subscriptionId.trim();
    final cleanAdminId = adminId.trim();

    if (cleanSubscriptionId.isEmpty) {
      throw ArgumentError('Subscription ID is required.');
    }

    if (cleanAdminId.isEmpty) {
      throw ArgumentError('Admin ID is required.');
    }

    if (billingMonth < 1 || billingMonth > 12) {
      throw ArgumentError(
        'Billing month must be between 1 and 12.',
      );
    }

    if (billingYear < 2020 || billingYear > 2200) {
      throw ArgumentError('Billing year is invalid.');
    }

    if (promoDiscount < 0) {
      throw ArgumentError(
        'Promo discount cannot be negative.',
      );
    }

    final monthPart =
        billingMonth.toString().padLeft(2, '0');
    final invoiceId =
        '${cleanSubscriptionId}_${billingYear}_$monthPart';

    final invoiceReference =
        _invoicesCollection.doc(invoiceId);
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

      final studentReference =
          _studentsCollection.doc(subscription.studentId);

      final studentSnapshot =
          await transaction.get(studentReference);
      final existingInvoiceSnapshot =
          await transaction.get(invoiceReference);

      if (existingInvoiceSnapshot.exists) {
        throw StateError(
          'An invoice already exists for this billing month.',
        );
      }

      if (!subscription.hasRouteAssignment) {
        throw StateError(
          'Complete route, driver and vehicle assignment first.',
        );
      }

      const allowedStatuses =
          <StudentRideSubscriptionStatus>{
        StudentRideSubscriptionStatus.paymentPending,
        StudentRideSubscriptionStatus.active,
        StudentRideSubscriptionStatus.paused,
      };

      if (!allowedStatuses.contains(subscription.status)) {
        throw StateError(
          'Invoice cannot be created in the '
          '${subscription.status.name} status.',
        );
      }

      final driverId =
          subscription.morningDriverId.isNotEmpty
              ? subscription.morningDriverId
              : subscription.afternoonDriverId.isNotEmpty
                  ? subscription.afternoonDriverId
                  : subscription.driverId;

      final routeId =
          subscription.morningRouteId.isNotEmpty
              ? subscription.morningRouteId
              : subscription.afternoonRouteId.isNotEmpty
                  ? subscription.afternoonRouteId
                  : subscription.routeId;

      if (driverId.isEmpty || routeId.isEmpty) {
        throw StateError(
          'Approved driver and route are required.',
        );
      }

      final studentData =
          studentSnapshot.data() ?? <String, dynamic>{};

      final studentName =
          studentData['studentName']?.toString().trim().isNotEmpty ==
                  true
              ? studentData['studentName'].toString().trim()
              : studentData['fullName']
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                      true
                  ? studentData['fullName'].toString().trim()
                  : studentData['name']
                              ?.toString()
                              .trim()
                              .isNotEmpty ==
                          true
                      ? studentData['name'].toString().trim()
                      : 'Student';

      final periodStart =
          DateTime(billingYear, billingMonth, 1);
      final periodEnd =
          DateTime(billingYear, billingMonth + 1, 0, 23, 59, 59);

      final registrationFee =
          subscription.currentPeriodStart == null
              ? subscription.registrationFee
              : 0.0;

      final baseBeforeSiblingDiscount =
          subscription.monthlyAmount +
              subscription.discountAmount;

      final subtotal =
          baseBeforeSiblingDiscount -
              subscription.discountAmount +
              registrationFee -
              promoDiscount +
              adjustmentAmount;

      final totalAmount =
          subtotal.clamp(0, double.infinity).toDouble();

      if (totalAmount <= 0) {
        throw StateError(
          'Calculated invoice total must be greater than zero.',
        );
      }

      final dueDate = DateTime(
        billingYear,
        billingMonth,
        5,
        23,
        59,
        59,
      );

      transaction.set(
        invoiceReference,
        <String, dynamic>{
          'invoiceId': invoiceId,
          'subscriptionId': subscription.subscriptionId,
          'packageId': subscription.packageId,
          'studentId': subscription.studentId,
          'studentName': studentName,
          'parentId': subscription.parentId,
          'driverId': driverId,
          'routeId': routeId,
          'billingMonth': billingMonth,
          'billingYear': billingYear,
          'periodStart': Timestamp.fromDate(periodStart),
          'periodEnd': Timestamp.fromDate(periodEnd),
          'dueDate': Timestamp.fromDate(dueDate),
          'baseAmount': baseBeforeSiblingDiscount,
          'distanceCharge': 0.0,
          'doorToDoorCharge': 0.0,
          'registrationFee': registrationFee,
          'siblingDiscount': subscription.discountAmount,
          'promoDiscount': promoDiscount,
          'adjustmentAmount': adjustmentAmount,
          'totalAmount': totalAmount,
          'currencyCode': subscription.currencyCode,
          'status': StudentRideInvoiceStatus.paymentPending.name,
          'paymentStatus': 'pending',
          'paymentMethod':
              StudentRideInvoicePaymentMethod.none.name,
          'amountPaid': 0.0,
          'paymentTransactionId': '',
          'commissionProcessed': false,
          'commissionSettlementId': '',
          'commissionAmount': 0.0,
          'driverNetEarning': 0.0,
          'commissionOutstanding': 0.0,
          'settlementStatus': 'pending',
          'issuedBy': cleanAdminId,
          'paymentConfirmedBy': '',
          'adminNote': adminNote.trim(),
          'issuedAt': FieldValue.serverTimestamp(),
          'paidAt': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      transaction.update(
        subscriptionReference,
        <String, dynamic>{
          'currentInvoiceId': invoiceId,
          'paymentStatus': 'pending',
          'status':
              StudentRideSubscriptionStatus.paymentPending.name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    });

    return invoiceId;
  }

  Future<void> confirmPaymentAndActivate({
    required String invoiceId,
    required StudentRideInvoicePaymentMethod paymentMethod,
    required String confirmedBy,
    String paymentTransactionId = '',
  }) async {
    final cleanInvoiceId = invoiceId.trim();
    final cleanConfirmedBy = confirmedBy.trim();
    final cleanTransactionId =
        paymentTransactionId.trim();

    if (cleanInvoiceId.isEmpty) {
      throw ArgumentError('Invoice ID is required.');
    }

    if (cleanConfirmedBy.isEmpty) {
      throw ArgumentError('Confirmer ID is required.');
    }

    if (paymentMethod ==
        StudentRideInvoicePaymentMethod.none) {
      throw ArgumentError('Payment method is required.');
    }

    if (paymentMethod !=
            StudentRideInvoicePaymentMethod.cash &&
        cleanTransactionId.isEmpty) {
      throw ArgumentError(
        'Digital payment transaction ID is required.',
      );
    }

    final settingsSnapshot =
        await _settingsReference.get();

    final settings = settingsSnapshot.exists
        ? StudentRideSettingsModel.fromMap(
            settingsSnapshot.data() ??
                <String, dynamic>{},
          )
        : StudentRideSettingsModel.defaults();

    _validatePaymentMethod(
      paymentMethod: paymentMethod,
      settings: settings,
    );

    await _commissionService.settleMonthlyInvoice(
      invoiceId: cleanInvoiceId,
      paymentMethod: paymentMethod.name,
      confirmedBy: cleanConfirmedBy,
    );

    final invoiceReference =
        _invoicesCollection.doc(cleanInvoiceId);

    await _firestore.runTransaction((transaction) async {
      final invoiceSnapshot =
          await transaction.get(invoiceReference);

      if (!invoiceSnapshot.exists) {
        throw StateError('Paid invoice was not found.');
      }

      final invoice =
          StudentRideInvoiceModel.fromMap(
        invoiceSnapshot.data() ?? <String, dynamic>{},
        documentId: invoiceSnapshot.id,
      );

      if (!invoice.commissionProcessed) {
        throw StateError(
          'Commission settlement was not completed.',
        );
      }

      final subscriptionReference =
          _subscriptionsCollection.doc(
        invoice.subscriptionId,
      );

      final subscriptionSnapshot =
          await transaction.get(subscriptionReference);

      if (!subscriptionSnapshot.exists) {
        throw StateError(
          'Invoice subscription was not found.',
        );
      }

      final nextBillingDate = DateTime(
        invoice.periodStart.year,
        invoice.periodStart.month + 1,
        1,
      );

      transaction.update(
        invoiceReference,
        <String, dynamic>{
          'status': StudentRideInvoiceStatus.paid.name,
          'paymentStatus': 'paid',
          'amountPaid': invoice.totalAmount,
          'paymentMethod': paymentMethod.name,
          'paymentTransactionId': cleanTransactionId,
          'paymentConfirmedBy': cleanConfirmedBy,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      transaction.update(
        subscriptionReference,
        <String, dynamic>{
          'status':
              StudentRideSubscriptionStatus.active.name,
          'paymentStatus': 'paid',
          'currentInvoiceId': cleanInvoiceId,
          'approvedStartDate':
              Timestamp.fromDate(invoice.periodStart),
          'currentPeriodStart':
              Timestamp.fromDate(invoice.periodStart),
          'currentPeriodEnd':
              Timestamp.fromDate(invoice.periodEnd),
          'nextBillingDate':
              Timestamp.fromDate(nextBillingDate),
          'reviewedBy': cleanConfirmedBy,
          'reviewedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  List<StudentRideInvoiceModel> _mapAndSortInvoices(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final invoices = snapshot.docs
        .map(
          (document) => StudentRideInvoiceModel.fromMap(
            document.data(),
            documentId: document.id,
          ),
        )
        .toList();

    invoices.sort((first, second) {
      final firstDate =
          first.issuedAt ?? first.createdAt ?? DateTime(2000);
      final secondDate =
          second.issuedAt ?? second.createdAt ?? DateTime(2000);

      return secondDate.compareTo(firstDate);
    });

    return invoices;
  }

  void _validatePaymentMethod({
    required StudentRideInvoicePaymentMethod paymentMethod,
    required StudentRideSettingsModel settings,
  }) {
    final enabled = switch (paymentMethod) {
      StudentRideInvoicePaymentMethod.cash =>
        settings.cashEnabled,
      StudentRideInvoicePaymentMethod.wallet =>
        settings.walletEnabled,
      StudentRideInvoicePaymentMethod.easypaisa =>
        settings.easypaisaEnabled,
      StudentRideInvoicePaymentMethod.jazzCash =>
        settings.jazzCashEnabled,
      StudentRideInvoicePaymentMethod.card =>
        settings.cardPaymentEnabled,
      StudentRideInvoicePaymentMethod.bank =>
        settings.cardPaymentEnabled,
      StudentRideInvoicePaymentMethod.none => false,
    };

    if (!enabled) {
      throw StateError(
        '${paymentMethod.name} payment is currently disabled.',
      );
    }
  }
}
