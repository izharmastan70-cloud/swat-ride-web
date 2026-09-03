// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/services/voucher_service.dart
//
// Global voucher service for Ride, Food, Hotel, Tourism,
// Cargo, Parcel, Wallet and future SWAT RIDE modules.
//
// Admin controls voucher creation, editing, cancellation,
// availability, stacking rules and supported modules.
//
// IMPORTANT:
// Reward-points vouchers are never credited automatically.
// User/Admin confirmation is required before reward credit.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/reward_production_gate.dart';

import '../models/reward_point_model.dart';
import '../models/voucher_model.dart';

class VoucherValidationResult {
  final bool isValid;
  final String message;
  final VoucherModel? voucher;
  final double benefitAmount;
  final int rewardPoints;
  final bool requiresRewardConfirmation;

  const VoucherValidationResult({
    required this.isValid,
    required this.message,
    this.voucher,
    this.benefitAmount = 0,
    this.rewardPoints = 0,
    this.requiresRewardConfirmation = false,
  });

  factory VoucherValidationResult.invalid(String message) {
    return VoucherValidationResult(
      isValid: false,
      message: message,
    );
  }
}

class VoucherRedemptionResult {
  final bool success;
  final String message;
  final VoucherModel? voucher;
  final double benefitAmount;
  final int rewardPoints;
  final bool rewardCreditPendingConfirmation;
  final String? redemptionId;

  const VoucherRedemptionResult({
    required this.success,
    required this.message,
    this.voucher,
    this.benefitAmount = 0,
    this.rewardPoints = 0,
    this.rewardCreditPendingConfirmation = false,
    this.redemptionId,
  });

  factory VoucherRedemptionResult.failed(String message) {
    return VoucherRedemptionResult(
      success: false,
      message: message,
    );
  }
}

class VoucherService {
  final FirebaseFirestore _firestore;

  /// Keep true while testing without Firebase connection.
  ///
  /// Change to false when real Firebase integration starts.
  final bool useTestingBypass;

  final Map<String, VoucherModel> _testingVouchers = {};
  final Set<String> _testingRedemptions = {};

  VoucherService({
    FirebaseFirestore? firestore,
    this.useTestingBypass = false,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _voucherCollection {
    return _firestore.collection('reward_vouchers');
  }

  CollectionReference<Map<String, dynamic>> get _redemptionCollection {
    return _firestore.collection('reward_voucher_redemptions');
  }

  // =============================================================
  // ADMIN METHODS
  // =============================================================

  Future<void> createVoucher(VoucherModel voucher) async {
    if (voucher.id.trim().isEmpty) {
      throw ArgumentError('Voucher ID cannot be empty.');
    }

    if (voucher.code.trim().isEmpty) {
      throw ArgumentError('Voucher code cannot be empty.');
    }

    if (voucher.benefitValue < 0) {
      throw ArgumentError('Voucher benefit cannot be negative.');
    }

    if (voucher.minimumAmount < 0) {
      throw ArgumentError('Minimum amount cannot be negative.');
    }

    if (voucher.maximumDiscount != null &&
        voucher.maximumDiscount! < 0) {
      throw ArgumentError('Maximum discount cannot be negative.');
    }

    if (voucher.expiryDate.isBefore(voucher.validFrom)) {
      throw ArgumentError(
        'Voucher expiry date cannot be before its start date.',
      );
    }

    if (useTestingBypass) {
      final duplicate = _testingVouchers.values.any(
        (existing) =>
            existing.code.trim().toUpperCase() ==
                voucher.code.trim().toUpperCase() &&
            existing.id != voucher.id,
      );

      if (duplicate) {
        throw StateError('A voucher with this code already exists.');
      }

      _testingVouchers[voucher.id] = voucher;
      return;
    }

    final duplicateQuery = await _voucherCollection
        .where(
          'code',
          isEqualTo: voucher.code.trim().toUpperCase(),
        )
        .limit(1)
        .get();

    if (duplicateQuery.docs.isNotEmpty &&
        duplicateQuery.docs.first.id != voucher.id) {
      throw StateError('A voucher with this code already exists.');
    }

    final data = voucher.toMap();
    data['code'] = voucher.code.trim().toUpperCase();

    await _voucherCollection.doc(voucher.id).set(data);
  }

  Future<void> updateVoucher(VoucherModel voucher) async {
    if (voucher.id.trim().isEmpty) {
      throw ArgumentError('Voucher ID cannot be empty.');
    }

    if (useTestingBypass) {
      if (!_testingVouchers.containsKey(voucher.id)) {
        throw StateError('Voucher not found.');
      }

      _testingVouchers[voucher.id] = voucher;
      return;
    }

    final document = await _voucherCollection.doc(voucher.id).get();

    if (!document.exists) {
      throw StateError('Voucher not found.');
    }

    final data = voucher.toMap();
    data['code'] = voucher.code.trim().toUpperCase();
    data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

    await _voucherCollection.doc(voucher.id).update(data);
  }

  Future<void> saveVoucher(VoucherModel voucher) async {
    if (useTestingBypass) {
      _testingVouchers[voucher.id] = voucher;
      return;
    }

    final data = voucher.toMap();
    data['code'] = voucher.code.trim().toUpperCase();

    await _voucherCollection.doc(voucher.id).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<void> cancelVoucher(String voucherId) async {
    if (voucherId.trim().isEmpty) {
      throw ArgumentError('Voucher ID cannot be empty.');
    }

    if (useTestingBypass) {
      final voucher = _testingVouchers[voucherId];

      if (voucher == null) {
        throw StateError('Voucher not found.');
      }

      final updatedMap = voucher.toMap();
      updatedMap['isActive'] = false;
      updatedMap['status'] = VoucherStatus.cancelled.name;
      updatedMap['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      _testingVouchers[voucherId] =
          VoucherModel.fromMap(updatedMap);

      return;
    }

    await _voucherCollection.doc(voucherId).update({
      'isActive': false,
      'status': VoucherStatus.cancelled.name,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteVoucher(String voucherId) async {
    if (voucherId.trim().isEmpty) {
      throw ArgumentError('Voucher ID cannot be empty.');
    }

    if (useTestingBypass) {
      _testingVouchers.remove(voucherId);
      return;
    }

    await _voucherCollection.doc(voucherId).delete();
  }

  // =============================================================
  // VOUCHER FETCHING
  // =============================================================

  Future<VoucherModel?> getVoucherById(String voucherId) async {
    if (useTestingBypass) {
      return _testingVouchers[voucherId];
    }

    final document = await _voucherCollection.doc(voucherId).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return VoucherModel.fromMap(document.data()!);
  }

  Future<VoucherModel?> getVoucherByCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      return null;
    }

    if (useTestingBypass) {
      for (final voucher in _testingVouchers.values) {
        if (voucher.code.trim().toUpperCase() == normalizedCode) {
          return voucher;
        }
      }

      return null;
    }

    final query = await _voucherCollection
        .where('code', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return VoucherModel.fromMap(query.docs.first.data());
  }

  Future<List<VoucherModel>> getAllVouchers() async {
    if (useTestingBypass) {
      final vouchers = _testingVouchers.values.toList();

      vouchers.sort(
        (first, second) =>
            second.createdAt.compareTo(first.createdAt),
      );

      return vouchers;
    }

    final query = await _voucherCollection.get();

    final vouchers = query.docs
        .map((document) => VoucherModel.fromMap(document.data()))
        .toList();

    vouchers.sort(
      (first, second) =>
          second.createdAt.compareTo(first.createdAt),
    );

    return vouchers;
  }

  Future<List<VoucherModel>> getAvailableVouchers({
    required String userId,
    required RewardModule module,
    double bookingAmount = 0,
  }) async {
    final vouchers = await getAllVouchers();
    final available = <VoucherModel>[];

    for (final voucher in vouchers) {
      final validation = await validateVoucher(
        voucher: voucher,
        userId: userId,
        module: module,
        bookingAmount: bookingAmount,
      );

      if (validation.isValid) {
        available.add(voucher);
      }
    }

    return available;
  }

  // =============================================================
  // VALIDATION
  // =============================================================

  Future<VoucherValidationResult> validateVoucherCode({
    required String code,
    required String userId,
    required RewardModule module,
    required double bookingAmount,
    bool rewardRedemptionUsed = false,
    bool promoUsed = false,
    bool couponUsed = false,
    bool cashbackRequested = false,
  }) async {
    final voucher = await getVoucherByCode(code);

    if (voucher == null) {
      return VoucherValidationResult.invalid(
        'Voucher code not found.',
      );
    }

    return validateVoucher(
      voucher: voucher,
      userId: userId,
      module: module,
      bookingAmount: bookingAmount,
      rewardRedemptionUsed: rewardRedemptionUsed,
      promoUsed: promoUsed,
      couponUsed: couponUsed,
      cashbackRequested: cashbackRequested,
    );
  }

  Future<VoucherValidationResult> validateVoucher({
    required VoucherModel voucher,
    required String userId,
    required RewardModule module,
    required double bookingAmount,
    bool rewardRedemptionUsed = false,
    bool promoUsed = false,
    bool couponUsed = false,
    bool cashbackRequested = false,
  }) async {
    final now = DateTime.now();

    if (!voucher.isActive) {
      return VoucherValidationResult.invalid(
        'This voucher is inactive.',
      );
    }

    if (voucher.status != VoucherStatus.active) {
      return VoucherValidationResult.invalid(
        'This voucher is not available.',
      );
    }

    if (now.isBefore(voucher.validFrom)) {
      return VoucherValidationResult.invalid(
        'This voucher is not active yet.',
      );
    }

    if (now.isAfter(voucher.expiryDate)) {
      return VoucherValidationResult.invalid(
        'This voucher has expired.',
      );
    }

    if (voucher.assignedUserId != null &&
        voucher.assignedUserId!.isNotEmpty &&
        voucher.assignedUserId != userId) {
      return VoucherValidationResult.invalid(
        'This voucher is assigned to another user.',
      );
    }

    final supportsAllModules =
        voucher.supportedModules.contains(RewardModule.all);

    if (!supportsAllModules &&
        !voucher.supportedModules.contains(module)) {
      return VoucherValidationResult.invalid(
        'This voucher is not valid for the selected module.',
      );
    }

    if (bookingAmount < 0) {
      return VoucherValidationResult.invalid(
        'Booking amount cannot be negative.',
      );
    }

    if (bookingAmount < voucher.minimumAmount) {
      return VoucherValidationResult.invalid(
        'Minimum booking amount is ${voucher.minimumAmount}.',
      );
    }

    if (voucher.singleUse && voucher.redeemedAt != null) {
      return VoucherValidationResult.invalid(
        'This voucher has already been redeemed.',
      );
    }

    if (rewardRedemptionUsed && !voucher.allowRewardRedemption) {
      return VoucherValidationResult.invalid(
        'Reward points cannot be combined with this voucher.',
      );
    }

    if (promoUsed && !voucher.allowPromoStacking) {
      return VoucherValidationResult.invalid(
        'Promo code cannot be combined with this voucher.',
      );
    }

    if (couponUsed && !voucher.allowCouponStacking) {
      return VoucherValidationResult.invalid(
        'Coupon cannot be combined with this voucher.',
      );
    }

    if (cashbackRequested && !voucher.allowCashback) {
      return VoucherValidationResult.invalid(
        'Cashback is not allowed with this voucher.',
      );
    }

    if (voucher.benefitValue < 0) {
      return VoucherValidationResult.invalid(
        'Voucher benefit configuration is invalid.',
      );
    }

    final benefitAmount = _calculateBenefitAmount(
      voucher: voucher,
      bookingAmount: bookingAmount,
    );

    final rewardPoints =
        voucher.benefitType == VoucherBenefitType.rewardPoints
            ? voucher.benefitValue.floor()
            : 0;

    return VoucherValidationResult(
      isValid: true,
      message: 'Voucher is valid.',
      voucher: voucher,
      benefitAmount: benefitAmount,
      rewardPoints: rewardPoints,
      requiresRewardConfirmation:
          voucher.benefitType == VoucherBenefitType.rewardPoints,
    );
  }

  double _calculateBenefitAmount({
    required VoucherModel voucher,
    required double bookingAmount,
  }) {
    double amount;

    switch (voucher.benefitType) {
      case VoucherBenefitType.percentageDiscount:
        amount = bookingAmount * (voucher.benefitValue / 100);
        break;

      case VoucherBenefitType.fixedDiscount:
        amount = voucher.benefitValue;
        break;

      case VoucherBenefitType.freeDelivery:
        amount = voucher.benefitValue;
        break;

      case VoucherBenefitType.rewardPoints:
        return 0;
    }

    if (voucher.maximumDiscount != null &&
        amount > voucher.maximumDiscount!) {
      amount = voucher.maximumDiscount!;
    }

    if (amount > bookingAmount) {
      amount = bookingAmount;
    }

    if (amount < 0) {
      return 0;
    }

    return amount;
  }

  // =============================================================
  // REDEMPTION
  // =============================================================

  Future<VoucherRedemptionResult> redeemVoucher({
    required String voucherId,
    required String userId,
    required String sourceId,
    required RewardModule module,
    required double bookingAmount,

    /// Must be true only after successful payment/booking confirmation.
    required bool paymentCompleted,

    /// Unique key prevents duplicate voucher redemption.
    required String idempotencyKey,

    bool rewardRedemptionUsed = false,
    bool promoUsed = false,
    bool couponUsed = false,
    bool cashbackRequested = false,
  }) async {
    if (!RewardProductionGate.financialMutationsEnabled) {
      return VoucherRedemptionResult.failed(
        'Voucher financial mutations are disabled until the trusted backend is ready.',
      );
    }

    if (!paymentCompleted) {
      return VoucherRedemptionResult.failed(
        'Voucher redemption requires successful payment.',
      );
    }

    if (idempotencyKey.trim().isEmpty) {
      return VoucherRedemptionResult.failed(
        'Idempotency key is required.',
      );
    }

    final voucher = await getVoucherById(voucherId);

    if (voucher == null) {
      return VoucherRedemptionResult.failed(
        'Voucher not found.',
      );
    }

    final validation = await validateVoucher(
      voucher: voucher,
      userId: userId,
      module: module,
      bookingAmount: bookingAmount,
      rewardRedemptionUsed: rewardRedemptionUsed,
      promoUsed: promoUsed,
      couponUsed: couponUsed,
      cashbackRequested: cashbackRequested,
    );

    if (!validation.isValid) {
      return VoucherRedemptionResult.failed(
        validation.message,
      );
    }

    if (useTestingBypass) {
      if (_testingRedemptions.contains(idempotencyKey)) {
        return VoucherRedemptionResult.failed(
          'This voucher redemption was already processed.',
        );
      }

      _testingRedemptions.add(idempotencyKey);

      final updatedMap = voucher.toMap();

      if (voucher.singleUse) {
        updatedMap['status'] = VoucherStatus.redeemed.name;
        updatedMap['isActive'] = false;
        updatedMap['redeemedAt'] =
            DateTime.now().millisecondsSinceEpoch;
        updatedMap['redeemedSourceId'] = sourceId;
        updatedMap['redeemedModule'] = module.name;

        _testingVouchers[voucher.id] =
            VoucherModel.fromMap(updatedMap);
      }

      return VoucherRedemptionResult(
        success: true,
        message: validation.requiresRewardConfirmation
            ? 'Voucher redeemed. Reward points require confirmation.'
            : 'Voucher redeemed successfully.',
        voucher: voucher,
        benefitAmount: validation.benefitAmount,
        rewardPoints: validation.rewardPoints,
        rewardCreditPendingConfirmation:
            validation.requiresRewardConfirmation,
        redemptionId: idempotencyKey,
      );
    }

    final redemptionReference =
        _redemptionCollection.doc(idempotencyKey);
    final voucherReference = _voucherCollection.doc(voucherId);

    try {
      await _firestore.runTransaction((transaction) async {
        final existingRedemption =
            await transaction.get(redemptionReference);

        if (existingRedemption.exists) {
          throw StateError(
            'This voucher redemption was already processed.',
          );
        }

        final voucherSnapshot =
            await transaction.get(voucherReference);

        if (!voucherSnapshot.exists ||
            voucherSnapshot.data() == null) {
          throw StateError('Voucher not found.');
        }

        final latestVoucher =
            VoucherModel.fromMap(voucherSnapshot.data()!);

        final latestValidation = await validateVoucher(
          voucher: latestVoucher,
          userId: userId,
          module: module,
          bookingAmount: bookingAmount,
          rewardRedemptionUsed: rewardRedemptionUsed,
          promoUsed: promoUsed,
          couponUsed: couponUsed,
          cashbackRequested: cashbackRequested,
        );

        if (!latestValidation.isValid) {
          throw StateError(latestValidation.message);
        }

        final redeemedAt = DateTime.now();

        transaction.set(redemptionReference, {
          'id': idempotencyKey,
          'voucherId': latestVoucher.id,
          'voucherCode': latestVoucher.code,
          'userId': userId,
          'sourceId': sourceId,
          'module': module.name,
          'bookingAmount': bookingAmount,
          'benefitType': latestVoucher.benefitType.name,
          'benefitAmount': latestValidation.benefitAmount,
          'rewardPoints': latestValidation.rewardPoints,
          'rewardCreditConfirmed': false,
          'paymentCompleted': true,
          'createdAt': redeemedAt.millisecondsSinceEpoch,
          'metadata': <String, dynamic>{},
        });

        if (latestVoucher.singleUse) {
          transaction.update(voucherReference, {
            'status': VoucherStatus.redeemed.name,
            'isActive': false,
            'redeemedAt': redeemedAt.millisecondsSinceEpoch,
            'redeemedSourceId': sourceId,
            'redeemedModule': module.name,
            'updatedAt': redeemedAt.millisecondsSinceEpoch,
          });
        }
      });

      return VoucherRedemptionResult(
        success: true,
        message: validation.requiresRewardConfirmation
            ? 'Voucher redeemed. Reward points require confirmation.'
            : 'Voucher redeemed successfully.',
        voucher: voucher,
        benefitAmount: validation.benefitAmount,
        rewardPoints: validation.rewardPoints,
        rewardCreditPendingConfirmation:
            validation.requiresRewardConfirmation,
        redemptionId: idempotencyKey,
      );
    } catch (error) {
      return VoucherRedemptionResult.failed(
        error.toString().replaceFirst('Bad state: ', ''),
      );
    }
  }

  // =============================================================
  // REWARD POINT CONFIRMATION
  // =============================================================

  /// Call this only after User/Admin confirms reward-points credit.
  ///
  /// This method only records confirmation. Actual point credit will
  /// later be connected through RewardService.
  Future<void> confirmRewardPointVoucher({
    required String redemptionId,
    required String confirmedBy,
  }) async {
    if (!RewardProductionGate.financialMutationsEnabled) {
      throw StateError(
        'Voucher financial mutations are disabled until the trusted backend is ready.',
      );
    }

    if (redemptionId.trim().isEmpty) {
      throw ArgumentError('Redemption ID cannot be empty.');
    }

    if (useTestingBypass) {
      if (!_testingRedemptions.contains(redemptionId)) {
        throw StateError('Voucher redemption not found.');
      }

      return;
    }

    final reference = _redemptionCollection.doc(redemptionId);
    final document = await reference.get();

    if (!document.exists || document.data() == null) {
      throw StateError('Voucher redemption not found.');
    }

    final data = document.data()!;
    final benefitType = data['benefitType']?.toString();

    if (benefitType != VoucherBenefitType.rewardPoints.name) {
      throw StateError(
        'This voucher does not provide reward points.',
      );
    }

    if (data['rewardCreditConfirmed'] == true) {
      return;
    }

    await reference.update({
      'rewardCreditConfirmed': true,
      'rewardCreditConfirmedBy': confirmedBy,
      'rewardCreditConfirmedAt':
          DateTime.now().millisecondsSinceEpoch,
    });
  }

  // =============================================================
  // TESTING HELPERS
  // =============================================================

  void addTestingVoucher(VoucherModel voucher) {
    _testingVouchers[voucher.id] = voucher;
  }

  void clearTestingData() {
    _testingVouchers.clear();
    _testingRedemptions.clear();
  }
}
