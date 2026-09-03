// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/services/global_promo_service.dart
//
// Global promo CRUD, validation, usage tracking and safe
// discount calculation with Firestore + testing bypass.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/reward_production_gate.dart';

import '../models/global_promo_code_model.dart';
import '../models/reward_point_model.dart';
import 'reward_service.dart';

class PromoValidationResult {
  final bool isValid;
  final String message;
  final double discountAmount;
  final GlobalPromoCodeModel? promo;

  const PromoValidationResult({
    required this.isValid,
    required this.message,
    this.discountAmount = 0,
    this.promo,
  });

  factory PromoValidationResult.valid({
    required GlobalPromoCodeModel promo,
    required double discountAmount,
  }) {
    return PromoValidationResult(
      isValid: true,
      message: 'Promo code is valid.',
      discountAmount: discountAmount,
      promo: promo,
    );
  }

  factory PromoValidationResult.invalid(String message) {
    return PromoValidationResult(
      isValid: false,
      message: message,
    );
  }
}

class GlobalPromoService {
  GlobalPromoService({
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

  static const String _promoCollection = 'global_promos';
  static const String _usageCollection = 'global_promo_usage';
  static const String _idempotencyCollection =
      'global_promo_idempotency';

  // -----------------------------------------------------------
  // TESTING BYPASS STORAGE
  // -----------------------------------------------------------

  static final Map<String, GlobalPromoCodeModel>
      _testingPromos = {};

  static final Map<String, int> _testingUserUsage = {};

  static final Set<String> _testingIdempotencyKeys = {};

  // -----------------------------------------------------------
  // ADMIN CRUD
  // -----------------------------------------------------------

  Future<void> savePromo(GlobalPromoCodeModel promo) async {
    if (promo.id.trim().isEmpty) {
      throw ArgumentError('Promo ID is required.');
    }

    if (promo.normalizedCode.isEmpty) {
      throw ArgumentError('Promo code is required.');
    }

    final duplicatePromo = await getPromoByCode(
      promo.normalizedCode,
    );

    if (duplicatePromo != null &&
        duplicatePromo.id != promo.id) {
      throw StateError('Promo code already exists.');
    }

    final updatedPromo = promo.copyWith(
      code: promo.normalizedCode,
      updatedAt: DateTime.now(),
    );

    if (useTestingBypass) {
      _testingPromos[promo.id] = updatedPromo;
      return;
    }

    await _firestore
        .collection(_promoCollection)
        .doc(promo.id)
        .set(
          updatedPromo.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<GlobalPromoCodeModel?> getPromoById(
    String promoId,
  ) async {
    if (promoId.trim().isEmpty) {
      return null;
    }

    if (useTestingBypass) {
      return _testingPromos[promoId];
    }

    final snapshot = await _firestore
        .collection(_promoCollection)
        .doc(promoId)
        .get();

    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return GlobalPromoCodeModel.fromMap({
      ...data,
      'id': snapshot.id,
    });
  }

  Future<GlobalPromoCodeModel?> getPromoByCode(
    String code,
  ) async {
    final normalizedCode = code.trim().toUpperCase();

    if (normalizedCode.isEmpty) {
      return null;
    }

    if (useTestingBypass) {
      for (final promo in _testingPromos.values) {
        if (promo.normalizedCode == normalizedCode) {
          return promo;
        }
      }

      return null;
    }

    final snapshot = await _firestore
        .collection(_promoCollection)
        .where('code', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final document = snapshot.docs.first;

    return GlobalPromoCodeModel.fromMap({
      ...document.data(),
      'id': document.id,
    });
  }

  Stream<List<GlobalPromoCodeModel>> watchPromos({
    bool activeOnly = false,
  }) {
    if (useTestingBypass) {
      var promos = _testingPromos.values.toList();

      if (activeOnly) {
        promos = promos
            .where((promo) => promo.isActive)
            .toList();
      }

      promos.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      return Stream.value(promos);
    }

    return _firestore
        .collection(_promoCollection)
        .snapshots()
        .map((snapshot) {
      var promos = snapshot.docs.map((document) {
        return GlobalPromoCodeModel.fromMap({
          ...document.data(),
          'id': document.id,
        });
      }).toList();

      if (activeOnly) {
        promos = promos
            .where((promo) => promo.isActive)
            .toList();
      }

      promos.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      return promos;
    });
  }

  Future<void> setPromoActive({
    required String promoId,
    required bool isActive,
  }) async {
    if (promoId.trim().isEmpty) {
      throw ArgumentError('Promo ID is required.');
    }

    if (useTestingBypass) {
      final promo = _testingPromos[promoId];

      if (promo == null) {
        throw StateError('Promo code was not found.');
      }

      _testingPromos[promoId] = promo.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      return;
    }

    await _firestore
        .collection(_promoCollection)
        .doc(promoId)
        .update({
      'isActive': isActive,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Permanent deletion should only be called from Admin panel.
  Future<void> deletePromo(String promoId) async {
    if (promoId.trim().isEmpty) {
      throw ArgumentError('Promo ID is required.');
    }

    if (useTestingBypass) {
      _testingPromos.remove(promoId);
      return;
    }

    await _firestore
        .collection(_promoCollection)
        .doc(promoId)
        .delete();
  }

  // -----------------------------------------------------------
  // USER USAGE
  // -----------------------------------------------------------

  Future<int> getUserUsageCount({
    required String promoId,
    required String userId,
  }) async {
    _validateUserId(userId);

    if (promoId.trim().isEmpty) {
      return 0;
    }

    final usageKey = _usageKey(
      promoId: promoId,
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
  // VALIDATION AND DISCOUNT CALCULATION
  // -----------------------------------------------------------

  Future<PromoValidationResult> validatePromo({
    required String code,
    required String userId,
    required RewardModule module,
    required double eligibleAmount,
    required String paymentMethod,
    required bool isFirstBooking,
    required bool isNewUser,
  }) async {
    _validateUserId(userId);

    if (code.trim().isEmpty) {
      return PromoValidationResult.invalid(
        'Enter a promo code.',
      );
    }

    if (eligibleAmount <= 0) {
      return PromoValidationResult.invalid(
        'Eligible amount must be greater than zero.',
      );
    }

    final settings = await _rewardService.getSettings();

    if (!settings.isPromoEnabledForModule(module)) {
      return PromoValidationResult.invalid(
        'Promo codes are currently disabled for ${module.name}.',
      );
    }

    final promo = await getPromoByCode(code);

    if (promo == null) {
      return PromoValidationResult.invalid(
        'Promo code was not found.',
      );
    }

    final userUsageCount = await getUserUsageCount(
      promoId: promo.id,
      userId: userId,
    );

    final canApply = promo.canUserApply(
      module: module,
      eligibleAmount: eligibleAmount,
      userUsageCount: userUsageCount,
      isFirstBooking: isFirstBooking,
      isNewUser: isNewUser,
      paymentMethod: paymentMethod,
    );

    if (!canApply) {
      return PromoValidationResult.invalid(
        _getInvalidReason(
          promo: promo,
          module: module,
          eligibleAmount: eligibleAmount,
          paymentMethod: paymentMethod,
          isFirstBooking: isFirstBooking,
          isNewUser: isNewUser,
          userUsageCount: userUsageCount,
        ),
      );
    }

    final discount = promo.calculateDiscount(
      eligibleAmount,
    );

    if (discount <= 0) {
      return PromoValidationResult.invalid(
        'This promo does not provide a valid discount.',
      );
    }

    return PromoValidationResult.valid(
      promo: promo,
      discountAmount: discount,
    );
  }

  String _getInvalidReason({
    required GlobalPromoCodeModel promo,
    required RewardModule module,
    required double eligibleAmount,
    required String paymentMethod,
    required bool isFirstBooking,
    required bool isNewUser,
    required int userUsageCount,
  }) {
    if (!promo.isActive) {
      return 'Promo code is disabled.';
    }

    if (!promo.isCurrentlyValid) {
      return 'Promo code is expired or unavailable.';
    }

    if (!promo.supportsModule(module)) {
      return 'Promo code is not valid for ${module.name}.';
    }

    if (!promo.supportsPaymentMethod(paymentMethod)) {
      return 'Promo code is not valid for this payment method.';
    }

    if (eligibleAmount < promo.minimumAmount) {
      return 'Minimum eligible amount is PKR '
          '${promo.minimumAmount.toStringAsFixed(0)}.';
    }

    if (promo.firstBookingOnly && !isFirstBooking) {
      return 'Promo code is valid only for the first booking.';
    }

    if (promo.newUsersOnly && !isNewUser) {
      return 'Promo code is valid only for new users.';
    }

    if (promo.singleUsePerUser && userUsageCount > 0) {
      return 'Promo code has already been used.';
    }

    if (promo.usageLimitPerUser != null &&
        userUsageCount >= promo.usageLimitPerUser!) {
      return 'Your promo usage limit has been reached.';
    }

    return 'Promo code cannot be applied.';
  }

  // -----------------------------------------------------------
  // RECORD USAGE AFTER SUCCESSFUL PAYMENT/BOOKING
  // -----------------------------------------------------------

  Future<void> recordPromoUsage({
    required String promoId,
    required String userId,
    required String sourceId,
    required String idempotencyKey,
    required double discountAmount,
    required RewardModule module,
  }) async {
    if (!RewardProductionGate.financialMutationsEnabled) {
      throw StateError(
        'Global promo usage mutations are disabled until the trusted backend is ready.',
      );
    }

    _validateUserId(userId);

    if (promoId.trim().isEmpty ||
        sourceId.trim().isEmpty ||
        idempotencyKey.trim().isEmpty) {
      throw ArgumentError(
        'Promo ID, source ID and idempotency key are required.',
      );
    }

    if (discountAmount < 0) {
      throw ArgumentError(
        'Discount amount cannot be negative.',
      );
    }

    if (useTestingBypass) {
      _recordTestingUsage(
        promoId: promoId,
        userId: userId,
        sourceId: sourceId,
        idempotencyKey: idempotencyKey,
        discountAmount: discountAmount,
        module: module,
      );

      return;
    }

    await _recordFirestoreUsage(
      promoId: promoId,
      userId: userId,
      sourceId: sourceId,
      idempotencyKey: idempotencyKey,
      discountAmount: discountAmount,
      module: module,
    );
  }

  void _recordTestingUsage({
    required String promoId,
    required String userId,
    required String sourceId,
    required String idempotencyKey,
    required double discountAmount,
    required RewardModule module,
  }) {
    if (_testingIdempotencyKeys.contains(idempotencyKey)) {
      throw StateError('Duplicate promo usage blocked.');
    }

    final promo = _testingPromos[promoId];

    if (promo == null) {
      throw StateError('Promo code was not found.');
    }

    if (promo.totalUsageLimit != null &&
        promo.usedCount >= promo.totalUsageLimit!) {
      throw StateError('Promo usage limit has been reached.');
    }

    final usageKey = _usageKey(
      promoId: promoId,
      userId: userId,
    );

    final userUsageCount =
        _testingUserUsage[usageKey] ?? 0;

    if (promo.usageLimitPerUser != null &&
        userUsageCount >= promo.usageLimitPerUser!) {
      throw StateError(
        'User promo usage limit has been reached.',
      );
    }

    _testingPromos[promoId] = promo.copyWith(
      usedCount: promo.usedCount + 1,
      updatedAt: DateTime.now(),
      metadata: {
        ...promo.metadata,
        'lastUsedBy': userId,
        'lastSourceId': sourceId,
        'lastDiscountAmount': discountAmount,
        'lastUsedModule': module.name,
      },
    );

    _testingUserUsage[usageKey] =
        userUsageCount + 1;

    _testingIdempotencyKeys.add(idempotencyKey);
  }

  Future<void> _recordFirestoreUsage({
    required String promoId,
    required String userId,
    required String sourceId,
    required String idempotencyKey,
    required double discountAmount,
    required RewardModule module,
  }) async {
    final promoReference = _firestore
        .collection(_promoCollection)
        .doc(promoId);

    final usageKey = _usageKey(
      promoId: promoId,
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
          throw StateError('Duplicate promo usage blocked.');
        }

        final promoSnapshot =
            await transaction.get(promoReference);

        final usageSnapshot =
            await transaction.get(usageReference);

        final promoData = promoSnapshot.data();

        if (!promoSnapshot.exists || promoData == null) {
          throw StateError('Promo code was not found.');
        }

        final promo = GlobalPromoCodeModel.fromMap({
          ...promoData,
          'id': promoSnapshot.id,
        });

        final usageData = usageSnapshot.data();

        final currentUserUsage =
            (usageData?['usageCount'] as num?)?.toInt() ?? 0;

        if (promo.totalUsageLimit != null &&
            promo.usedCount >= promo.totalUsageLimit!) {
          throw StateError(
            'Promo usage limit has been reached.',
          );
        }

        if (promo.usageLimitPerUser != null &&
            currentUserUsage >= promo.usageLimitPerUser!) {
          throw StateError(
            'User promo usage limit has been reached.',
          );
        }

        final now = DateTime.now();

        transaction.update(
          promoReference,
          {
            'usedCount': promo.usedCount + 1,
            'updatedAt': now.millisecondsSinceEpoch,
          },
        );

        transaction.set(
          usageReference,
          {
            'promoId': promoId,
            'userId': userId,
            'usageCount': currentUserUsage + 1,
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
            'promoId': promoId,
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

    _testingPromos.clear();
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
    required String promoId,
    required String userId,
  }) {
    return _safeDocumentId('${promoId}_$userId');
  }

  String _safeDocumentId(String value) {
    return value
        .trim()
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll(' ', '_');
  }
}
