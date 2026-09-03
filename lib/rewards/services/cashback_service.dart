// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/services/cashback_service.dart
//
// Global Admin-controlled cashback service for:
// Ride, Driver, Food, Hotel, Tourism, Cargo, Parcel,
// Student Ride, Wallet and future modules.
//
// Cashback is created only after successful booking/payment.
// Existing app modules will be connected after app completion.
// =============================================================

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/reward_production_gate.dart';

import '../models/cashback_model.dart';
import '../models/reward_point_model.dart';

class CashbackValidationResult {
  final bool isValid;
  final String message;
  final CashbackModel? rule;

  final double cashbackAmount;
  final int rewardPoints;

  final DateTime? availableAt;
  final DateTime? expiresAt;

  const CashbackValidationResult({
    required this.isValid,
    required this.message,
    this.rule,
    this.cashbackAmount = 0,
    this.rewardPoints = 0,
    this.availableAt,
    this.expiresAt,
  });

  factory CashbackValidationResult.invalid(String message) {
    return CashbackValidationResult(
      isValid: false,
      message: message,
    );
  }
}

class CashbackAwardResult {
  final bool success;
  final String message;

  final String? transactionId;
  final CashbackModel? rule;

  final double cashbackAmount;
  final int rewardPoints;

  final CashbackDestination? destination;

  final DateTime? availableAt;
  final DateTime? expiresAt;

  final bool duplicate;

  const CashbackAwardResult({
    required this.success,
    required this.message,
    this.transactionId,
    this.rule,
    this.cashbackAmount = 0,
    this.rewardPoints = 0,
    this.destination,
    this.availableAt,
    this.expiresAt,
    this.duplicate = false,
  });

  factory CashbackAwardResult.failed(String message) {
    return CashbackAwardResult(
      success: false,
      message: message,
    );
  }
}

class _CashbackUserStats {
  final int usageCount;

  final double dailyCashback;
  final double monthlyCashback;
  final double yearlyCashback;

  const _CashbackUserStats({
    this.usageCount = 0,
    this.dailyCashback = 0,
    this.monthlyCashback = 0,
    this.yearlyCashback = 0,
  });
}

class CashbackService {
  final FirebaseFirestore _firestore;

  /// Keep true during local/testing work.
  ///
  /// Set false when real Firebase connection is required.
  final bool useTestingBypass;

  bool _testingCashbackEnabled = true;

  final Map<String, CashbackModel> _testingRules = {};
  final Map<String, Map<String, dynamic>> _testingTransactions = {};

  CashbackService({
    FirebaseFirestore? firestore,
    this.useTestingBypass = false,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rulesCollection {
    return _firestore.collection('reward_cashback_rules');
  }

  CollectionReference<Map<String, dynamic>>
      get _transactionsCollection {
    return _firestore.collection('reward_cashback_transactions');
  }


  DocumentReference<Map<String, dynamic>> get _settingsDocument {
    return _firestore
        .collection('reward_engine_settings')
        .doc('cashback');
  }

  // =============================================================
  // GLOBAL ADMIN ON/OFF CONTROL
  // =============================================================

  Future<void> setCashbackEnabled({
    required bool enabled,
    required String updatedBy,
  }) async {
    if (useTestingBypass) {
      _testingCashbackEnabled = enabled;
      return;
    }

    await _settingsDocument.set({
      'isEnabled': enabled,
      'updatedBy': updatedBy,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<bool> isCashbackEnabled() async {
    if (useTestingBypass) {
      return _testingCashbackEnabled;
    }

    final document = await _settingsDocument.get();

    if (!document.exists || document.data() == null) {
      return true;
    }

    return document.data()!['isEnabled'] as bool? ?? true;
  }

  Stream<bool> watchCashbackEnabled() {
    if (useTestingBypass) {
      return Stream<bool>.value(_testingCashbackEnabled);
    }

    return _settingsDocument.snapshots().map((document) {
      if (!document.exists || document.data() == null) {
        return true;
      }

      return document.data()!['isEnabled'] as bool? ?? true;
    });
  }

  // =============================================================
  // ADMIN CASHBACK RULE MANAGEMENT
  // =============================================================

  Future<void> createCashbackRule(CashbackModel rule) async {
    _validateRuleConfiguration(rule);

    if (useTestingBypass) {
      if (_testingRules.containsKey(rule.id)) {
        throw StateError('Cashback rule already exists.');
      }

      _testingRules[rule.id] = rule;
      return;
    }

    final reference = _rulesCollection.doc(rule.id);
    final existing = await reference.get();

    if (existing.exists) {
      throw StateError('Cashback rule already exists.');
    }

    await reference.set(rule.toMap());
  }

  Future<void> updateCashbackRule(CashbackModel rule) async {
    _validateRuleConfiguration(rule);

    if (useTestingBypass) {
      if (!_testingRules.containsKey(rule.id)) {
        throw StateError('Cashback rule not found.');
      }

      _testingRules[rule.id] = rule.copyWith(
        updatedAt: DateTime.now(),
      );

      return;
    }

    final reference = _rulesCollection.doc(rule.id);
    final existing = await reference.get();

    if (!existing.exists) {
      throw StateError('Cashback rule not found.');
    }

    final updatedRule = rule.copyWith(
      updatedAt: DateTime.now(),
    );

    await reference.update(updatedRule.toMap());
  }

  Future<void> saveCashbackRule(CashbackModel rule) async {
    _validateRuleConfiguration(rule);

    if (useTestingBypass) {
      _testingRules[rule.id] = rule;
      return;
    }

    await _rulesCollection.doc(rule.id).set(
          rule.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> setRuleActive({
    required String ruleId,
    required bool isActive,
  }) async {
    final rule = await getCashbackRule(ruleId);

    if (rule == null) {
      throw StateError('Cashback rule not found.');
    }

    final updatedRule = rule.copyWith(
      isActive: isActive,
      updatedAt: DateTime.now(),
    );

    if (useTestingBypass) {
      _testingRules[ruleId] = updatedRule;
      return;
    }

    await _rulesCollection.doc(ruleId).update({
      'isActive': isActive,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteCashbackRule(String ruleId) async {
    if (ruleId.trim().isEmpty) {
      throw ArgumentError('Cashback rule ID cannot be empty.');
    }

    if (useTestingBypass) {
      _testingRules.remove(ruleId);
      return;
    }

    await _rulesCollection.doc(ruleId).delete();
  }

  void _validateRuleConfiguration(CashbackModel rule) {
    if (rule.id.trim().isEmpty) {
      throw ArgumentError('Cashback rule ID cannot be empty.');
    }

    if (rule.name.trim().isEmpty) {
      throw ArgumentError('Cashback rule name cannot be empty.');
    }

    if (rule.cashbackValue <= 0) {
      throw ArgumentError(
        'Cashback value must be greater than zero.',
      );
    }

    if (rule.type == CashbackType.percentage &&
        rule.cashbackValue > 100) {
      throw ArgumentError(
        'Percentage cashback cannot exceed 100%.',
      );
    }

    if (rule.minimumBookingAmount < 0) {
      throw ArgumentError(
        'Minimum booking amount cannot be negative.',
      );
    }

    if (rule.maximumCashbackPerBooking != null &&
        rule.maximumCashbackPerBooking! < 0) {
      throw ArgumentError(
        'Maximum cashback cannot be negative.',
      );
    }

    if (rule.destination == CashbackDestination.rewardWallet &&
        rule.rewardPointsPerPkr <= 0) {
      throw ArgumentError(
        'Reward points conversion must be greater than zero.',
      );
    }

    if (rule.pendingDays < 0) {
      throw ArgumentError('Pending days cannot be negative.');
    }

    if (rule.expiryDays != null && rule.expiryDays! < 0) {
      throw ArgumentError('Expiry days cannot be negative.');
    }

    if (rule.startDate != null &&
        rule.expiryDate != null &&
        rule.expiryDate!.isBefore(rule.startDate!)) {
      throw ArgumentError(
        'Expiry date cannot be before start date.',
      );
    }
  }

  // =============================================================
  // FETCH CASHBACK RULES
  // =============================================================

  Future<CashbackModel?> getCashbackRule(String ruleId) async {
    if (useTestingBypass) {
      return _testingRules[ruleId];
    }

    final document = await _rulesCollection.doc(ruleId).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return CashbackModel.fromMap(document.data()!);
  }

  Future<List<CashbackModel>> getAllCashbackRules() async {
    if (useTestingBypass) {
      final rules = _testingRules.values.toList();

      rules.sort(
        (first, second) =>
            second.createdAt.compareTo(first.createdAt),
      );

      return rules;
    }

    final query = await _rulesCollection.get();

    final rules = query.docs
        .map(
          (document) =>
              CashbackModel.fromMap(document.data()),
        )
        .toList();

    rules.sort(
      (first, second) =>
          second.createdAt.compareTo(first.createdAt),
    );

    return rules;
  }

  Future<List<CashbackModel>> getAvailableCashbackRules({
    required String userId,
    required RewardModule module,
    required String paymentMethod,
    required double eligibleAmount,
    bool promoUsed = false,
    bool couponUsed = false,
    bool voucherUsed = false,
    bool rewardRedemptionUsed = false,
  }) async {
    if (!await isCashbackEnabled()) {
      return [];
    }

    final allRules = await getAllCashbackRules();
    final availableRules = <CashbackModel>[];

    for (final rule in allRules) {
      final validation = await validateCashback(
        rule: rule,
        userId: userId,
        module: module,
        paymentMethod: paymentMethod,
        eligibleAmount: eligibleAmount,
        promoUsed: promoUsed,
        couponUsed: couponUsed,
        voucherUsed: voucherUsed,
        rewardRedemptionUsed: rewardRedemptionUsed,
      );

      if (validation.isValid) {
        availableRules.add(rule);
      }
    }

    return availableRules;
  }

  Future<CashbackModel?> findBestCashbackRule({
    required String userId,
    required RewardModule module,
    required String paymentMethod,
    required double eligibleAmount,
    bool promoUsed = false,
    bool couponUsed = false,
    bool voucherUsed = false,
    bool rewardRedemptionUsed = false,
  }) async {
    final rules = await getAvailableCashbackRules(
      userId: userId,
      module: module,
      paymentMethod: paymentMethod,
      eligibleAmount: eligibleAmount,
      promoUsed: promoUsed,
      couponUsed: couponUsed,
      voucherUsed: voucherUsed,
      rewardRedemptionUsed: rewardRedemptionUsed,
    );

    CashbackModel? bestRule;
    double bestAmount = 0;

    for (final rule in rules) {
      final amount = rule.calculateCashback(eligibleAmount);

      if (bestRule == null || amount > bestAmount) {
        bestRule = rule;
        bestAmount = amount;
      }
    }

    return bestRule;
  }

  // =============================================================
  // CASHBACK VALIDATION
  // =============================================================

  Future<CashbackValidationResult> validateCashback({
    required CashbackModel rule,
    required String userId,
    required RewardModule module,
    required String paymentMethod,
    required double eligibleAmount,
    bool promoUsed = false,
    bool couponUsed = false,
    bool voucherUsed = false,
    bool rewardRedemptionUsed = false,
    DateTime? completedAt,
  }) async {
    if (!await isCashbackEnabled()) {
      return CashbackValidationResult.invalid(
        'Cashback is disabled by Admin.',
      );
    }

    if (userId.trim().isEmpty) {
      return CashbackValidationResult.invalid(
        'User ID is required.',
      );
    }

    if (!rule.isCurrentlyValid) {
      return CashbackValidationResult.invalid(
        'Cashback rule is inactive, expired or invalid.',
      );
    }

    if (!rule.supportsModule(module)) {
      return CashbackValidationResult.invalid(
        'Cashback is not available for this module.',
      );
    }

    if (!rule.supportsPaymentMethod(paymentMethod)) {
      return CashbackValidationResult.invalid(
        'Cashback is not available for this payment method.',
      );
    }

    if (eligibleAmount <= 0) {
      return CashbackValidationResult.invalid(
        'Eligible amount must be greater than zero.',
      );
    }

    if (eligibleAmount < rule.minimumBookingAmount) {
      return CashbackValidationResult.invalid(
        'Minimum booking amount is '
        '${rule.minimumBookingAmount}.',
      );
    }

    if (promoUsed && !rule.allowWithPromo) {
      return CashbackValidationResult.invalid(
        'Cashback cannot be combined with a promo.',
      );
    }

    if (couponUsed && !rule.allowWithCoupon) {
      return CashbackValidationResult.invalid(
        'Cashback cannot be combined with a coupon.',
      );
    }

    if (voucherUsed && !rule.allowWithVoucher) {
      return CashbackValidationResult.invalid(
        'Cashback cannot be combined with a voucher.',
      );
    }

    if (rewardRedemptionUsed &&
        !rule.allowWithRewardRedemption) {
      return CashbackValidationResult.invalid(
        'Cashback cannot be combined with reward redemption.',
      );
    }

    final now = completedAt ?? DateTime.now();
    final stats = await _getUserStats(
      ruleId: rule.id,
      userId: userId,
      date: now,
    );

    if (!rule.canUserReceiveCashback(
      module: module,
      paymentMethod: paymentMethod,
      eligibleAmount: eligibleAmount,
      userUsageCount: stats.usageCount,
      userDailyCashback: stats.dailyCashback,
      userMonthlyCashback: stats.monthlyCashback,
      userYearlyCashback: stats.yearlyCashback,
    )) {
      return CashbackValidationResult.invalid(
        'User cashback usage or earning limit has been reached.',
      );
    }

    var cashbackAmount = rule.calculateCashback(
      eligibleAmount,
    );

    cashbackAmount = _applyRemainingLimits(
      rule: rule,
      calculatedAmount: cashbackAmount,
      stats: stats,
    );

    if (cashbackAmount <= 0) {
      return CashbackValidationResult.invalid(
        'Cashback limit has been reached.',
      );
    }

    final availableAt = rule.calculateAvailableAt(now);
    final expiresAt = rule.calculateCashbackExpiry(
      availableAt,
    );

    final rewardPoints = rule.calculateRewardPoints(
      cashbackAmount,
    );

    return CashbackValidationResult(
      isValid: true,
      message: 'Cashback is valid.',
      rule: rule,
      cashbackAmount: cashbackAmount,
      rewardPoints: rewardPoints,
      availableAt: availableAt,
      expiresAt: expiresAt,
    );
  }

  double _applyRemainingLimits({
    required CashbackModel rule,
    required double calculatedAmount,
    required _CashbackUserStats stats,
  }) {
    var allowedAmount = calculatedAmount;

    if (rule.dailyCashbackLimit != null) {
      final remaining =
          rule.dailyCashbackLimit! - stats.dailyCashback;

      if (remaining < allowedAmount) {
        allowedAmount = remaining;
      }
    }

    if (rule.monthlyCashbackLimit != null) {
      final remaining =
          rule.monthlyCashbackLimit! - stats.monthlyCashback;

      if (remaining < allowedAmount) {
        allowedAmount = remaining;
      }
    }

    if (rule.yearlyCashbackLimit != null) {
      final remaining =
          rule.yearlyCashbackLimit! - stats.yearlyCashback;

      if (remaining < allowedAmount) {
        allowedAmount = remaining;
      }
    }

    return allowedAmount < 0 ? 0 : allowedAmount;
  }

  // =============================================================
  // AWARD CASHBACK AFTER SUCCESSFUL BOOKING/PAYMENT
  // =============================================================

  Future<CashbackAwardResult> awardCashback({
    required String ruleId,
    required String userId,
    required String sourceId,
    required RewardModule module,
    required String paymentMethod,
    required double eligibleAmount,

    /// Must be true only after successful payment.
    required bool paymentCompleted,

    /// Must be true only after ride/order/booking is completed.
    required bool bookingCompleted,

    /// Unique value prevents duplicate cashback.
    required String idempotencyKey,

    bool promoUsed = false,
    bool couponUsed = false,
    bool voucherUsed = false,
    bool rewardRedemptionUsed = false,
    DateTime? completedAt,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (!RewardProductionGate.financialMutationsEnabled) {
      return CashbackAwardResult.failed(
        'Cashback financial mutations are disabled until the trusted backend is ready.',
      );
    }

    if (!paymentCompleted) {
      return CashbackAwardResult.failed(
        'Cashback requires successful payment.',
      );
    }

    if (!bookingCompleted) {
      return CashbackAwardResult.failed(
        'Cashback requires completed booking or order.',
      );
    }

    if (sourceId.trim().isEmpty) {
      return CashbackAwardResult.failed(
        'Booking or order source ID is required.',
      );
    }

    if (idempotencyKey.trim().isEmpty) {
      return CashbackAwardResult.failed(
        'Idempotency key is required.',
      );
    }

    final rule = await getCashbackRule(ruleId);

    if (rule == null) {
      return CashbackAwardResult.failed(
        'Cashback rule not found.',
      );
    }

    final completionDate = completedAt ?? DateTime.now();

    final validation = await validateCashback(
      rule: rule,
      userId: userId,
      module: module,
      paymentMethod: paymentMethod,
      eligibleAmount: eligibleAmount,
      promoUsed: promoUsed,
      couponUsed: couponUsed,
      voucherUsed: voucherUsed,
      rewardRedemptionUsed: rewardRedemptionUsed,
      completedAt: completionDate,
    );

    if (!validation.isValid) {
      return CashbackAwardResult.failed(
        validation.message,
      );
    }

    final transactionId = _safeDocumentId(
      idempotencyKey,
    );

    if (useTestingBypass) {
      final existing = _testingTransactions[transactionId];

      if (existing != null) {
        return CashbackAwardResult(
          success: true,
          message: 'Cashback was already processed.',
          transactionId: transactionId,
          rule: rule,
          cashbackAmount:
              (existing['cashbackAmount'] as num?)
                      ?.toDouble() ??
                  0,
          rewardPoints:
              (existing['rewardPoints'] as num?)?.toInt() ?? 0,
          destination: rule.destination,
          availableAt: _dateFromValue(
            existing['availableAt'],
          ),
          expiresAt: _dateFromValue(existing['expiresAt']),
          duplicate: true,
        );
      }

      final transactionData = _buildTransactionData(
        transactionId: transactionId,
        idempotencyKey: idempotencyKey,
        rule: rule,
        userId: userId,
        sourceId: sourceId,
        module: module,
        paymentMethod: paymentMethod,
        eligibleAmount: eligibleAmount,
        completionDate: completionDate,
        validation: validation,
        metadata: metadata,
      );

      _testingTransactions[transactionId] =
          transactionData;

      _testingRules[rule.id] = rule.copyWith(
        usedCount: rule.usedCount + 1,
        updatedAt: DateTime.now(),
      );

      return CashbackAwardResult(
        success: true,
        message: rule.pendingDays > 0
            ? 'Cashback created and is pending.'
            : 'Cashback awarded successfully.',
        transactionId: transactionId,
        rule: rule,
        cashbackAmount: validation.cashbackAmount,
        rewardPoints: validation.rewardPoints,
        destination: rule.destination,
        availableAt: validation.availableAt,
        expiresAt: validation.expiresAt,
      );
    }

    final transactionReference =
        _transactionsCollection.doc(transactionId);
    final ruleReference = _rulesCollection.doc(rule.id);

    try {
      final alreadyExists =
          await transactionReference.get();

      if (alreadyExists.exists &&
          alreadyExists.data() != null) {
        final data = alreadyExists.data()!;

        return CashbackAwardResult(
          success: true,
          message: 'Cashback was already processed.',
          transactionId: transactionId,
          rule: rule,
          cashbackAmount:
              (data['cashbackAmount'] as num?)?.toDouble() ?? 0,
          rewardPoints:
              (data['rewardPoints'] as num?)?.toInt() ?? 0,
          destination: rule.destination,
          availableAt: _dateFromValue(data['availableAt']),
          expiresAt: _dateFromValue(data['expiresAt']),
          duplicate: true,
        );
      }

      await _firestore.runTransaction((transaction) async {
        final existingTransaction =
            await transaction.get(transactionReference);

        if (existingTransaction.exists) {
          return;
        }

        final latestRuleDocument =
            await transaction.get(ruleReference);

        if (!latestRuleDocument.exists ||
            latestRuleDocument.data() == null) {
          throw StateError('Cashback rule not found.');
        }

        final latestRule = CashbackModel.fromMap(
          latestRuleDocument.data()!,
        );

        if (!latestRule.isCurrentlyValid) {
          throw StateError(
            'Cashback rule is no longer available.',
          );
        }

        if (latestRule.totalUsageLimit != null &&
            latestRule.usedCount >=
                latestRule.totalUsageLimit!) {
          throw StateError(
            'Cashback total usage limit has been reached.',
          );
        }

        final transactionData = _buildTransactionData(
          transactionId: transactionId,
          idempotencyKey: idempotencyKey,
          rule: latestRule,
          userId: userId,
          sourceId: sourceId,
          module: module,
          paymentMethod: paymentMethod,
          eligibleAmount: eligibleAmount,
          completionDate: completionDate,
          validation: validation,
          metadata: metadata,
        );

        transaction.set(
          transactionReference,
          transactionData,
        );

        transaction.update(ruleReference, {
          'usedCount': FieldValue.increment(1),
          'updatedAt':
              DateTime.now().millisecondsSinceEpoch,
        });
      });

      return CashbackAwardResult(
        success: true,
        message: rule.pendingDays > 0
            ? 'Cashback created and is pending.'
            : 'Cashback awarded successfully.',
        transactionId: transactionId,
        rule: rule,
        cashbackAmount: validation.cashbackAmount,
        rewardPoints: validation.rewardPoints,
        destination: rule.destination,
        availableAt: validation.availableAt,
        expiresAt: validation.expiresAt,
      );
    } catch (error) {
      return CashbackAwardResult.failed(
        error.toString().replaceFirst('Bad state: ', ''),
      );
    }
  }

  Map<String, dynamic> _buildTransactionData({
    required String transactionId,
    required String idempotencyKey,
    required CashbackModel rule,
    required String userId,
    required String sourceId,
    required RewardModule module,
    required String paymentMethod,
    required double eligibleAmount,
    required DateTime completionDate,
    required CashbackValidationResult validation,
    required Map<String, dynamic> metadata,
  }) {
    final isPending =
        validation.availableAt != null &&
        validation.availableAt!.isAfter(completionDate);

    return {
      'id': transactionId,
      'idempotencyKey': idempotencyKey,
      'ruleId': rule.id,
      'ruleName': rule.name,
      'userId': userId,
      'sourceId': sourceId,
      'module': module.name,
      'paymentMethod': paymentMethod,
      'eligibleAmount': eligibleAmount,
      'cashbackAmount': validation.cashbackAmount,
      'rewardPoints': validation.rewardPoints,
      'destination': rule.destination.name,
      'status': isPending ? 'pending' : 'available',
      'paymentCompleted': true,
      'bookingCompleted': true,
      'completedAt': completionDate.millisecondsSinceEpoch,
      'availableAt':
          validation.availableAt?.millisecondsSinceEpoch,
      'expiresAt':
          validation.expiresAt?.millisecondsSinceEpoch,
      'walletCredited': false,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  // =============================================================
  // USER CASHBACK HISTORY
  // =============================================================

  Future<List<Map<String, dynamic>>> getUserCashbackHistory(
    String userId,
  ) async {
    if (useTestingBypass) {
      final records = _testingTransactions.values
          .where(
            (record) => record['userId'] == userId,
          )
          .map(
            (record) => Map<String, dynamic>.from(record),
          )
          .toList();

      records.sort(
        (first, second) =>
            ((second['createdAt'] as num?)?.toInt() ?? 0)
                .compareTo(
          (first['createdAt'] as num?)?.toInt() ?? 0,
        ),
      );

      return records;
    }

    final query = await _transactionsCollection
        .where('userId', isEqualTo: userId)
        .get();

    final records = query.docs
        .map(
          (document) =>
              Map<String, dynamic>.from(document.data()),
        )
        .toList();

    records.sort(
      (first, second) =>
          ((second['createdAt'] as num?)?.toInt() ?? 0)
              .compareTo(
        (first['createdAt'] as num?)?.toInt() ?? 0,
      ),
    );

    return records;
  }

  // =============================================================
  // CASHBACK STATUS AND WALLET CREDIT
  // =============================================================

  Future<void> markCashbackAvailable(
    String transactionId,
  ) async {
    if (!RewardProductionGate.financialMutationsEnabled) {
      throw StateError(
        'Cashback financial mutations are disabled until the trusted backend is ready.',
      );
    }

    if (useTestingBypass) {
      final data = _testingTransactions[transactionId];

      if (data == null) {
        throw StateError('Cashback transaction not found.');
      }

      data['status'] = 'available';
      data['availableMarkedAt'] =
          DateTime.now().millisecondsSinceEpoch;

      return;
    }

    await _transactionsCollection.doc(transactionId).update({
      'status': 'available',
      'availableMarkedAt':
          DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// This only records wallet credit confirmation.
  ///
  /// Actual RewardWallet/PaymentWallet connection will be added
  /// when all app modules are connected.
  Future<void> confirmWalletCredit({
    required String transactionId,
    required String confirmedBy,
  }) async {
    if (!RewardProductionGate.financialMutationsEnabled) {
      throw StateError(
        'Cashback financial mutations are disabled until the trusted backend is ready.',
      );
    }

    if (useTestingBypass) {
      final data = _testingTransactions[transactionId];

      if (data == null) {
        throw StateError('Cashback transaction not found.');
      }

      if (data['walletCredited'] == true) {
        return;
      }

      data['walletCredited'] = true;
      data['walletCreditedBy'] = confirmedBy;
      data['walletCreditedAt'] =
          DateTime.now().millisecondsSinceEpoch;

      return;
    }

    final reference =
        _transactionsCollection.doc(transactionId);

    await _firestore.runTransaction((transaction) async {
      final document = await transaction.get(reference);

      if (!document.exists || document.data() == null) {
        throw StateError('Cashback transaction not found.');
      }

      final data = document.data()!;

      if (data['walletCredited'] == true) {
        return;
      }

      transaction.update(reference, {
        'walletCredited': true,
        'walletCreditedBy': confirmedBy,
        'walletCreditedAt':
            DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  Future<void> reverseCashback({
    required String transactionId,
    required String reason,
    required String reversedBy,
  }) async {
    if (!RewardProductionGate.financialMutationsEnabled) {
      throw StateError(
        'Cashback financial mutations are disabled until the trusted backend is ready.',
      );
    }

    if (useTestingBypass) {
      final data = _testingTransactions[transactionId];

      if (data == null) {
        throw StateError('Cashback transaction not found.');
      }

      data['status'] = 'reversed';
      data['reversalReason'] = reason;
      data['reversedBy'] = reversedBy;
      data['reversedAt'] =
          DateTime.now().millisecondsSinceEpoch;

      return;
    }

    await _transactionsCollection.doc(transactionId).update({
      'status': 'reversed',
      'reversalReason': reason,
      'reversedBy': reversedBy,
      'reversedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // =============================================================
  // USER LIMIT CALCULATION
  // =============================================================

  Future<_CashbackUserStats> _getUserStats({
    required String ruleId,
    required String userId,
    required DateTime date,
  }) async {
    final records = useTestingBypass
        ? _testingTransactions.values
            .where(
              (record) =>
                  record['ruleId'] == ruleId &&
                  record['userId'] == userId,
            )
            .toList()
        : (await _transactionsCollection
                .where('userId', isEqualTo: userId)
                .get())
            .docs
            .map((document) => document.data())
            .where(
              (record) => record['ruleId'] == ruleId,
            )
            .toList();

    var usageCount = 0;
    var dailyCashback = 0.0;
    var monthlyCashback = 0.0;
    var yearlyCashback = 0.0;

    for (final record in records) {
      final status = record['status']?.toString();

      if (status == 'reversed' ||
          status == 'cancelled' ||
          status == 'failed') {
        continue;
      }

      usageCount++;

      final completedAt = _dateFromValue(
        record['completedAt'],
      );

      if (completedAt == null) {
        continue;
      }

      final amount =
          (record['cashbackAmount'] as num?)?.toDouble() ?? 0;

      if (_isSameDay(completedAt, date)) {
        dailyCashback += amount;
      }

      if (_isSameMonth(completedAt, date)) {
        monthlyCashback += amount;
      }

      if (completedAt.year == date.year) {
        yearlyCashback += amount;
      }
    }

    return _CashbackUserStats(
      usageCount: usageCount,
      dailyCashback: dailyCashback,
      monthlyCashback: monthlyCashback,
      yearlyCashback: yearlyCashback,
    );
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _isSameMonth(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month;
  }

  String _safeDocumentId(String value) {
    return base64Url
        .encode(utf8.encode(value))
        .replaceAll('=', '');
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
      );
    }

    return DateTime.tryParse(value.toString());
  }

  // =============================================================
  // TESTING HELPERS
  // =============================================================

  void addTestingRule(CashbackModel rule) {
    _testingRules[rule.id] = rule;
  }

  void clearTestingData() {
    _testingRules.clear();
    _testingTransactions.clear();
    _testingCashbackEnabled = true;
  }
}
