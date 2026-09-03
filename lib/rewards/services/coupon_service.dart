// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/services/coupon_service.dart
//
// Admin coupon management, validation and usage tracking
// with real Firestore and safe testing bypass.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/reward_production_gate.dart';

import '../models/coupon_model.dart';
import '../models/reward_point_model.dart';
import 'reward_service.dart';

class CouponValidationResult {
  final bool isValid;
  final String message;
  final double discountAmount;
  final CouponModel? coupon;

  const CouponValidationResult({
    required this.isValid,
    required this.message,
    this.discountAmount = 0,
    this.coupon,
  });

  factory CouponValidationResult.valid({
    required CouponModel coupon,
    required double discountAmount,
  }) {
    return CouponValidationResult(
      isValid: true,
      message: 'Coupon is valid.',
      discountAmount: discountAmount,
      coupon: coupon,
    );
  }

  factory CouponValidationResult.invalid(String message) {
    return CouponValidationResult(
      isValid: false,
      message: message,
    );
  }
}

class CouponService {
  CouponService({
    FirebaseFirestore? firestore,
    RewardService? rewardService,
    this.useTestingBypass = false,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _rewardService = rewardService ??
            RewardService(
              firestore: firestore,
              useTestingBypass: useTestingBypass,
            );

  final FirebaseFirestore _firestore;
  final RewardService _rewardService;
  final bool useTestingBypass;

  static const String _couponCollection = 'reward_coupons';
  static const String _usageCollection = 'reward_coupon_usage';
  static const String _idempotencyCollection =
      'reward_coupon_idempotency';

  static final Map<String, CouponModel> _testingCoupons = {};
  static final Map<String, int> _testingUserUsage = {};
  static final Set<String> _testingIdempotencyKeys = {};

  // -----------------------------------------------------------
  // ADMIN CRUD
  // -----------------------------------------------------------

  Future<void> saveCoupon(CouponModel coupon) async {
    if (coupon.id.trim().isEmpty) {
      throw ArgumentError('Coupon ID is required.');
    }

    if (coupon.normalizedCode.isEmpty) {
      throw ArgumentError('Coupon code is required.');
    }

    final duplicate = await getCouponByCode(
      coupon.normalizedCode,
    );

    if (duplicate != null && duplicate.id != coupon.id) {
      throw StateError('Coupon code already exists.');
    }

    final data = coupon.toMap();
    data['code'] = coupon.normalizedCode;
    data['updatedAt'] =
        DateTime.now().millisecondsSinceEpoch;

    final updatedCoupon = CouponModel.fromMap(data);

    if (useTestingBypass) {
      _testingCoupons[coupon.id] = updatedCoupon;
      return;
    }

    await _firestore
        .collection(_couponCollection)
        .doc(coupon.id)
        .set(
          updatedCoupon.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<CouponModel?> getCouponById(String couponId) async {
    if (couponId.trim().isEmpty) {
      return null;
    }

    if (useTestingBypass) {
      return _testingCoupons[couponId];
    }

    final snapshot = await _firestore
        .collection(_couponCollection)
        .doc(couponId)
        .get();

    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return CouponModel.fromMap({
      ...data,
      'id': snapshot.id,
    });
  }

  Future<CouponModel?> getCouponByCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      return null;
    }

    if (useTestingBypass) {
      for (final coupon in _testingCoupons.values) {
        if (coupon.normalizedCode == normalizedCode) {
          return coupon;
        }
      }

      return null;
    }

    final snapshot = await _firestore
        .collection(_couponCollection)
        .where('code', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final document = snapshot.docs.first;

    return CouponModel.fromMap({
      ...document.data(),
      'id': document.id,
    });
  }

  Stream<List<CouponModel>> watchCoupons({
    bool activeOnly = false,
  }) {
    if (useTestingBypass) {
      var coupons = _testingCoupons.values.toList();

      if (activeOnly) {
        coupons = coupons
            .where((coupon) => coupon.isActive)
            .toList();
      }

      coupons.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      return Stream.value(coupons);
    }

    return _firestore
        .collection(_couponCollection)
        .snapshots()
        .map((snapshot) {
      var coupons = snapshot.docs.map((document) {
        return CouponModel.fromMap({
          ...document.data(),
          'id': document.id,
        });
      }).toList();

      if (activeOnly) {
        coupons = coupons
            .where((coupon) => coupon.isActive)
            .toList();
      }

      coupons.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      return coupons;
    });
  }

  Future<void> setCouponActive({
    required String couponId,
    required bool isActive,
  }) async {
    if (couponId.trim().isEmpty) {
      throw ArgumentError('Coupon ID is required.');
    }

    if (useTestingBypass) {
      final coupon = _testingCoupons[couponId];

      if (coupon == null) {
        throw StateError('Coupon was not found.');
      }

      final data = coupon.toMap();
      data['isActive'] = isActive;
      data['updatedAt'] =
          DateTime.now().millisecondsSinceEpoch;

      _testingCoupons[couponId] =
          CouponModel.fromMap(data);

      return;
    }

    await _firestore
        .collection(_couponCollection)
        .doc(couponId)
        .update({
      'isActive': isActive,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Permanent deletion must only be exposed to Admin.
  Future<void> deleteCoupon(String couponId) async {
    if (couponId.trim().isEmpty) {
      throw ArgumentError('Coupon ID is required.');
    }

    if (useTestingBypass) {
      _testingCoupons.remove(couponId);
      return;
    }

    await _firestore
        .collection(_couponCollection)
        .doc(couponId)
        .delete();
  }

  // -----------------------------------------------------------
  // USER COUPONS
  // -----------------------------------------------------------

  Future<List<CouponModel>> getAvailableCoupons({
    required String userId,
    required String loyaltyLevelId,
    required RewardModule module,
    required bool isFirstBooking,
  }) async {
    _validateUserId(userId);

    List<CouponModel> coupons;

    if (useTestingBypass) {
      coupons = _testingCoupons.values.toList();
    } else {
      final snapshot = await _firestore
          .collection(_couponCollection)
          .get();

      coupons = snapshot.docs.map((document) {
        return CouponModel.fromMap({
          ...document.data(),
          'id': document.id,
        });
      }).toList();
    }

    final available = <CouponModel>[];

    for (final coupon in coupons) {
      if (!coupon.isCurrentlyValid) {
        continue;
      }

      if (!coupon.supportsModule(module)) {
        continue;
      }

      if (!coupon.isAvailableForUser(
        userId: userId,
        loyaltyLevelId: loyaltyLevelId,
        isFirstBooking: isFirstBooking,
      )) {
        continue;
      }

      final usageCount = await getUserUsageCount(
        couponId: coupon.id,
        userId: userId,
      );

      if (coupon.singleUsePerUser && usageCount > 0) {
        continue;
      }

      if (coupon.usageLimitPerUser != null &&
          usageCount >= coupon.usageLimitPerUser!) {
        continue;
      }

      available.add(coupon);
    }

    available.sort(
      (a, b) => a.expiryDate == null
          ? 1
          : b.expiryDate == null
              ? -1
              : a.expiryDate!.compareTo(b.expiryDate!),
    );

    return available;
  }

  Future<int> getUserUsageCount({
    required String couponId,
    required String userId,
  }) async {
    _validateUserId(userId);

    final usageKey = _usageKey(
      couponId: couponId,
      userId: userId,
    );

    if (useTestingBypass) {
      return _testingUserUsage[usageKey] ?? 0;
    }

    final snapshot = await _firestore
        .collection(_usageCollection)
        .doc(usageKey)
        .get();

    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return 0;
    }

    return (data['usageCount'] as num?)?.toInt() ?? 0;
  }

  // -----------------------------------------------------------
  // VALIDATION
  // -----------------------------------------------------------

  Future<CouponValidationResult> validateCoupon({
    required String code,
    required String userId,
    required String loyaltyLevelId,
    required RewardModule module,
    required double eligibleAmount,
    required bool isFirstBooking,
  }) async {
    _validateUserId(userId);

    if (code.trim().isEmpty) {
      return CouponValidationResult.invalid(
        'Enter a coupon code.',
      );
    }

    if (eligibleAmount <= 0) {
      return CouponValidationResult.invalid(
        'Eligible amount must be greater than zero.',
      );
    }

    final settings = await _rewardService.getSettings();

    if (!settings.isCouponEnabledForModule(module)) {
      return CouponValidationResult.invalid(
        'Coupons are currently disabled for ${module.name}.',
      );
    }

    final coupon = await getCouponByCode(code);

    if (coupon == null) {
      return CouponValidationResult.invalid(
        'Coupon was not found.',
      );
    }

    final usageCount = await getUserUsageCount(
      couponId: coupon.id,
      userId: userId,
    );

    final canApply = coupon.canUserApply(
      userId: userId,
      loyaltyLevelId: loyaltyLevelId,
      module: module,
      eligibleAmount: eligibleAmount,
      userUsageCount: usageCount,
      isFirstBooking: isFirstBooking,
    );

    if (!canApply) {
      return CouponValidationResult.invalid(
        _invalidReason(
          coupon: coupon,
          userId: userId,
          loyaltyLevelId: loyaltyLevelId,
          module: module,
          eligibleAmount: eligibleAmount,
          usageCount: usageCount,
          isFirstBooking: isFirstBooking,
        ),
      );
    }

    final discount = coupon.calculateDiscount(
      eligibleAmount,
    );

    if (discount <= 0) {
      return CouponValidationResult.invalid(
        'Coupon does not provide a valid discount.',
      );
    }

    return CouponValidationResult.valid(
      coupon: coupon,
      discountAmount: discount,
    );
  }

  String _invalidReason({
    required CouponModel coupon,
    required String userId,
    required String loyaltyLevelId,
    required RewardModule module,
    required double eligibleAmount,
    required int usageCount,
    required bool isFirstBooking,
  }) {
    if (!coupon.isActive) {
      return 'Coupon is disabled.';
    }

    if (!coupon.isCurrentlyValid) {
      return 'Coupon is expired or unavailable.';
    }

    if (!coupon.supportsModule(module)) {
      return 'Coupon is not valid for ${module.name}.';
    }

    if (eligibleAmount < coupon.minimumAmount) {
      return 'Minimum eligible amount is PKR '
          '${coupon.minimumAmount.toStringAsFixed(0)}.';
    }

    if (!coupon.isAvailableForUser(
      userId: userId,
      loyaltyLevelId: loyaltyLevelId,
      isFirstBooking: isFirstBooking,
    )) {
      return 'This coupon is not available for this user.';
    }

    if (coupon.singleUsePerUser && usageCount > 0) {
      return 'Coupon has already been used.';
    }

    if (coupon.usageLimitPerUser != null &&
        usageCount >= coupon.usageLimitPerUser!) {
      return 'Coupon usage limit has been reached.';
    }

    return 'Coupon cannot be applied.';
  }

  // -----------------------------------------------------------
  // RECORD USAGE AFTER SUCCESSFUL BOOKING/PAYMENT
  // -----------------------------------------------------------

  Future<void> recordCouponUsage({
    required String couponId,
    required String userId,
    required String sourceId,
    required String idempotencyKey,
    required double discountAmount,
    required RewardModule module,
  }) async {
    if (!RewardProductionGate.financialMutationsEnabled) {
      throw StateError(
        'Coupon usage mutations are disabled until the trusted backend is ready.',
      );
    }

    _validateUserId(userId);

    if (couponId.trim().isEmpty ||
        sourceId.trim().isEmpty ||
        idempotencyKey.trim().isEmpty) {
      throw ArgumentError(
        'Coupon ID, source ID and idempotency key are required.',
      );
    }

    if (discountAmount < 0) {
      throw ArgumentError(
        'Discount amount cannot be negative.',
      );
    }

    if (useTestingBypass) {
      _recordTestingUsage(
        couponId: couponId,
        userId: userId,
        sourceId: sourceId,
        idempotencyKey: idempotencyKey,
        discountAmount: discountAmount,
        module: module,
      );

      return;
    }

    await _recordFirestoreUsage(
      couponId: couponId,
      userId: userId,
      sourceId: sourceId,
      idempotencyKey: idempotencyKey,
      discountAmount: discountAmount,
      module: module,
    );
  }

  void _recordTestingUsage({
    required String couponId,
    required String userId,
    required String sourceId,
    required String idempotencyKey,
    required double discountAmount,
    required RewardModule module,
  }) {
    if (_testingIdempotencyKeys.contains(idempotencyKey)) {
      throw StateError('Duplicate coupon usage blocked.');
    }

    final coupon = _testingCoupons[couponId];

    if (coupon == null) {
      throw StateError('Coupon was not found.');
    }

    final usageKey = _usageKey(
      couponId: couponId,
      userId: userId,
    );

    final usageCount =
        _testingUserUsage[usageKey] ?? 0;

    if (coupon.totalUsageLimit != null &&
        coupon.usedCount >= coupon.totalUsageLimit!) {
      throw StateError(
        'Coupon total usage limit has been reached.',
      );
    }

    if (coupon.usageLimitPerUser != null &&
        usageCount >= coupon.usageLimitPerUser!) {
      throw StateError(
        'User coupon usage limit has been reached.',
      );
    }

    final couponData = coupon.toMap();
    couponData['usedCount'] = coupon.usedCount + 1;
    couponData['updatedAt'] =
        DateTime.now().millisecondsSinceEpoch;
    couponData['metadata'] = {
      ...coupon.metadata,
      'lastUsedBy': userId,
      'lastSourceId': sourceId,
      'lastDiscountAmount': discountAmount,
      'lastUsedModule': module.name,
    };

    _testingCoupons[couponId] =
        CouponModel.fromMap(couponData);

    _testingUserUsage[usageKey] = usageCount + 1;
    _testingIdempotencyKeys.add(idempotencyKey);
  }

  Future<void> _recordFirestoreUsage({
    required String couponId,
    required String userId,
    required String sourceId,
    required String idempotencyKey,
    required double discountAmount,
    required RewardModule module,
  }) async {
    final couponReference = _firestore
        .collection(_couponCollection)
        .doc(couponId);

    final usageKey = _usageKey(
      couponId: couponId,
      userId: userId,
    );

    final usageReference = _firestore
        .collection(_usageCollection)
        .doc(usageKey);

    final idempotencyReference = _firestore
        .collection(_idempotencyCollection)
        .doc(_safeDocumentId(idempotencyKey));

    await _firestore.runTransaction(
      (transaction) async {
        final idempotencySnapshot =
            await transaction.get(idempotencyReference);

        if (idempotencySnapshot.exists) {
          throw StateError('Duplicate coupon usage blocked.');
        }

        final couponSnapshot =
            await transaction.get(couponReference);

        final usageSnapshot =
            await transaction.get(usageReference);

        final couponData = couponSnapshot.data();

        if (!couponSnapshot.exists || couponData == null) {
          throw StateError('Coupon was not found.');
        }

        final coupon = CouponModel.fromMap({
          ...couponData,
          'id': couponSnapshot.id,
        });

        final usageData = usageSnapshot.data();

        final currentUsage =
            (usageData?['usageCount'] as num?)?.toInt() ?? 0;

        if (coupon.totalUsageLimit != null &&
            coupon.usedCount >= coupon.totalUsageLimit!) {
          throw StateError(
            'Coupon total usage limit has been reached.',
          );
        }

        if (coupon.usageLimitPerUser != null &&
            currentUsage >= coupon.usageLimitPerUser!) {
          throw StateError(
            'User coupon usage limit has been reached.',
          );
        }

        final now = DateTime.now();

        transaction.update(
          couponReference,
          {
            'usedCount': coupon.usedCount + 1,
            'updatedAt': now.millisecondsSinceEpoch,
          },
        );

        transaction.set(
          usageReference,
          {
            'couponId': couponId,
            'userId': userId,
            'usageCount': currentUsage + 1,
            'lastSourceId': sourceId,
            'lastDiscountAmount': discountAmount,
            'lastUsedModule': module.name,
            'updatedAt': now.millisecondsSinceEpoch,
          },
          SetOptions(merge: true),
        );

        transaction.set(
          idempotencyReference,
          {
            'idempotencyKey': idempotencyKey,
            'couponId': couponId,
            'userId': userId,
            'sourceId': sourceId,
            'discountAmount': discountAmount,
            'module': module.name,
            'createdAt': now.millisecondsSinceEpoch,
          },
        );
      },
    );
  }

  // -----------------------------------------------------------
  // TESTING HELPERS
  // -----------------------------------------------------------

  void clearTestingData() {
    if (!useTestingBypass) {
      throw StateError(
        'Testing data can only be cleared in bypass mode.',
      );
    }

    _testingCoupons.clear();
    _testingUserUsage.clear();
    _testingIdempotencyKeys.clear();
  }

  // -----------------------------------------------------------
  // PRIVATE HELPERS
  // -----------------------------------------------------------

  void _validateUserId(String userId) {
    if (userId.trim().isEmpty) {
      throw ArgumentError('User ID is required.');
    }
  }

  String _usageKey({
    required String couponId,
    required String userId,
  }) {
    return _safeDocumentId('${couponId}_$userId');
  }

  String _safeDocumentId(String value) {
    return value
        .trim()
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll(' ', '_');
  }
}
