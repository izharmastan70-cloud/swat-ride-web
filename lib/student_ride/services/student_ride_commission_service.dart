import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student_ride_settings_model.dart';

class StudentRideCommissionService {
  StudentRideCommissionService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _invoices =>
      _firestore.collection('student_ride_invoices');

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');

  CollectionReference<Map<String, dynamic>> get _driverEarnings =>
      _firestore.collection('driver_earnings');

  CollectionReference<Map<String, dynamic>> get _commissionLedger =>
      _firestore.collection('ride_commission_settlements');

  DocumentReference<Map<String, dynamic>> get _adminWallet =>
      _firestore
          .collection('ride_admin_settings')
          .doc('admin_wallet');

  DocumentReference<Map<String, dynamic>> get _settings =>
      _firestore
          .collection('student_ride_config')
          .doc('global_settings');

  Future<void> settleMonthlyInvoice({
    required String invoiceId,
    required String paymentMethod,
    required String confirmedBy,
  }) async {
    final String normalizedInvoiceId = invoiceId.trim();
    final String normalizedPayment =
        paymentMethod.trim().toLowerCase();
    final String normalizedConfirmedBy = confirmedBy.trim();

    if (normalizedInvoiceId.isEmpty) {
      throw Exception('Student Ride invoice ID is required.');
    }

    if (normalizedPayment.isEmpty) {
      throw Exception('Payment method is required.');
    }

    if (normalizedConfirmedBy.isEmpty) {
      throw Exception('Payment confirmer ID is required.');
    }

    final String financeDocumentId =
        'student_ride_$normalizedInvoiceId';

    final DocumentReference<Map<String, dynamic>> invoiceReference =
        _invoices.doc(normalizedInvoiceId);
    final DocumentReference<Map<String, dynamic>> earningReference =
        _driverEarnings.doc(financeDocumentId);
    final DocumentReference<Map<String, dynamic>> ledgerReference =
        _commissionLedger.doc(financeDocumentId);

    await _firestore.runTransaction((transaction) async {
      final invoiceSnapshot =
          await transaction.get(invoiceReference);
      final settingsSnapshot =
          await transaction.get(_settings);
      final earningSnapshot =
          await transaction.get(earningReference);
      final adminWalletSnapshot =
          await transaction.get(_adminWallet);

      if (!invoiceSnapshot.exists) {
        throw Exception('Student Ride monthly invoice was not found.');
      }

      final Map<String, dynamic> invoiceData =
          invoiceSnapshot.data()!;

      final String driverId =
          invoiceData['driverId']?.toString().trim() ?? '';

      if (driverId.isEmpty) {
        throw Exception(
          'No Student Ride Driver is assigned to this invoice.',
        );
      }

      final DocumentReference<Map<String, dynamic>> driverReference =
          _drivers.doc(driverId);

      final driverSnapshot =
          await transaction.get(driverReference);

      if (!driverSnapshot.exists) {
        throw Exception('Assigned Driver account was not found.');
      }

      // The earning document ID is unique for this monthly invoice.
      // If it already exists, commission was previously processed.
      if (earningSnapshot.exists) {
        return;
      }

      final double grossAmount =
          _number(invoiceData['totalAmount']);

      if (grossAmount <= 0) {
        throw Exception('Student Ride invoice amount is invalid.');
      }

      final StudentRideSettingsModel settings =
          settingsSnapshot.exists
              ? StudentRideSettingsModel.fromMap(
                  settingsSnapshot.data()!,
                )
              : StudentRideSettingsModel.defaults();

      final double commission = _calculateCommission(
        grossAmount: grossAmount,
        type: settings.commissionType,
        value: settings.commissionValue,
      );

      final double netDriverEarning =
          grossAmount - commission;

      final bool isCashPayment =
          normalizedPayment == 'cash';

      final Map<String, dynamic> driverData =
          driverSnapshot.data() ?? <String, dynamic>{};

      final Map<String, dynamic> adminData =
          adminWalletSnapshot.data() ?? <String, dynamic>{};

      final double driverWalletBefore =
          _number(driverData['walletBalance']);

      final double outstandingBefore =
          _number(driverData['outstandingCommission']);

      final double totalCommissionPaidBefore =
          _number(driverData['totalCommissionPaid']);

      final double adminBalanceBefore =
          _number(adminData['walletBalance']);

      final double adminCommissionReceivedBefore =
          _number(adminData['totalCommissionReceived']);

      final double adminOutstandingBefore =
          _number(adminData['totalOutstandingReceivable']);

      double driverWalletAfter = driverWalletBefore;
      double autoDeductedCommission = 0;
      double remainingOutstanding = 0;
      double adminCreditNow = 0;

      if (isCashPayment) {
        // Parent pays the complete monthly amount directly
        // to the Student Ride Driver/operator.
        autoDeductedCommission =
            driverWalletBefore >= commission
                ? commission
                : driverWalletBefore;

        remainingOutstanding =
            commission - autoDeductedCommission;

        driverWalletAfter =
            driverWalletBefore - autoDeductedCommission;

        adminCreditNow = autoDeductedCommission;
      } else {
        // Digital payment is collected by SWAT RIDE.
        // Admin commission is withheld and only net earning
        // is credited into the global Driver wallet.
        autoDeductedCommission = commission;
        remainingOutstanding = 0;
        driverWalletAfter =
            driverWalletBefore + netDriverEarning;
        adminCreditNow = commission;
      }

      final String settlementStatus =
          remainingOutstanding > 0
              ? 'partially_settled'
              : 'settled';

      transaction.set(
        invoiceReference,
        <String, dynamic>{
          'paymentMethod': normalizedPayment,
          'paymentStatus': 'paid',
          'status': 'paid',
          'amountPaid': grossAmount,
          'commissionType': settings.commissionType.name,
          'commissionValue': settings.commissionValue,
          'commissionAmount': commission,
          'driverNetEarning': netDriverEarning,
          'commissionAutoDeducted':
              autoDeductedCommission,
          'commissionOutstanding':
              remainingOutstanding,
          'commissionProcessed': true,
          'commissionSettlementId': financeDocumentId,
          'settlementStatus': settlementStatus,
          'paymentConfirmedBy': normalizedConfirmedBy,
          'paidAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        earningReference,
        <String, dynamic>{
          'earningId': financeDocumentId,
          'serviceType': 'student_ride',
          'invoiceId': normalizedInvoiceId,
          'packageId': invoiceData['packageId'],
          'subscriptionId': invoiceData['subscriptionId'],
          'studentId': invoiceData['studentId'],
          'parentId': invoiceData['parentId'],
          'driverId': driverId,
          'grossFare': grossAmount,
          'commissionAmount': commission,
          'netDriverEarning': netDriverEarning,
          'paymentMethod': normalizedPayment,
          'paymentStatus': 'paid',
          'settlementStatus': settlementStatus,
          'commissionAutoDeducted':
              autoDeductedCommission,
          'cashCommissionOutstanding':
              remainingOutstanding,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      transaction.set(
        driverReference,
        <String, dynamic>{
          'lifetimeGrossFare':
              FieldValue.increment(grossAmount),
          'lifetimeCommission':
              FieldValue.increment(commission),
          'lifetimeNetEarnings':
              FieldValue.increment(netDriverEarning),
          'walletBalance': driverWalletAfter,
          'outstandingCommission':
              outstandingBefore + remainingOutstanding,
          'totalCommissionPaid':
              totalCommissionPaidBefore + adminCreditNow,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        _adminWallet,
        <String, dynamic>{
          'walletBalance':
              adminBalanceBefore + adminCreditNow,
          'totalCommissionReceived':
              adminCommissionReceivedBefore + adminCreditNow,
          'totalOutstandingReceivable':
              adminOutstandingBefore + remainingOutstanding,
          'lastTransactionAt':
              FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        ledgerReference,
        <String, dynamic>{
          'settlementId': financeDocumentId,
          'serviceType': 'student_ride',
          'sourceType': 'driver',
          'sourceId': driverId,
          'invoiceId': normalizedInvoiceId,
          'subscriptionId': invoiceData['subscriptionId'],
          'paymentMode':
              isCashPayment ? 'cash' : 'digital',
          'grossAmount': grossAmount,
          'commissionType': settings.commissionType.name,
          'commissionValue': settings.commissionValue,
          'commissionAmount': commission,
          'autoDeductedAmount': adminCreditNow,
          'outstandingAmount': remainingOutstanding,
          'netEarning': netDriverEarning,
          'status': settlementStatus,
          'confirmedBy': normalizedConfirmedBy,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    });

    // Production note:
    // Digital payments must be confirmed by a secure backend
    // after JazzCash/Easypaisa/Card/Bank webhook verification.
    // Secret payment keys must never be stored in Flutter.
  }

  double previewCommission({
    required double grossAmount,
    required StudentRideCommissionType type,
    required double value,
  }) {
    return _calculateCommission(
      grossAmount: grossAmount,
      type: type,
      value: value,
    );
  }

  double _calculateCommission({
    required double grossAmount,
    required StudentRideCommissionType type,
    required double value,
  }) {
    if (grossAmount < 0 || value < 0) {
      throw ArgumentError(
        'Amount and commission value cannot be negative.',
      );
    }

    final double rawCommission =
        type == StudentRideCommissionType.percentage
            ? grossAmount * value / 100
            : value;

    final double safeCommission =
        rawCommission.clamp(0, grossAmount).toDouble();

    return _roundMoney(safeCommission);
  }

  double _number(dynamic value) {
    return value is num ? value.toDouble() : 0;
  }

  double _roundMoney(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}

