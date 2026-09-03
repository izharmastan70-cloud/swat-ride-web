// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/services/reward_ai_service.dart
//
// Safe AI-style recommendation engine for all SWAT RIDE modules.
//
// Supports:
// - Best promo/coupon/voucher recommendation
// - Reward redemption comparison
// - Expiring-points recommendation
// - Loyalty upgrade prediction
// - Next milestone
// - Personalized offer ranking
// - Admin ON/OFF
// - Recommendation audit history
// - Real Firestore and testing bypass
//
// SECURITY:
// AI can only recommend.
// AI cannot apply discount, redeem points, credit/debit wallets,
// change prices, finalize bookings or complete payments.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/loyalty_level_model.dart';
import '../models/reward_point_model.dart';
import '../models/reward_settings_model.dart';
import '../models/reward_wallet_model.dart';

enum RewardAIRecommendationType {
  promo,
  coupon,
  voucher,
  rewardRedemption,
  cashback,
  expiringPoints,
  loyaltyUpgrade,
  nextMilestone,
  personalizedOffer,
  noBenefit,
}

enum RewardAIBenefitSource {
  promo,
  coupon,
  voucher,
  rewardPoints,
  cashback,
  loyalty,
  none,
}

enum RewardAIConfidence {
  low,
  medium,
  high,
}

class RewardBenefitCandidate {
  final String id;
  final String title;
  final String description;

  final RewardAIBenefitSource source;
  final RewardModule module;

  /// Estimated PKR saving.
  final double estimatedSaving;

  /// Reward points required when source is rewardPoints.
  final int requiredPoints;

  final double minimumBookingAmount;
  final DateTime? expiryDate;

  final bool isValid;
  final bool requiresConfirmation;

  final bool allowWithPromo;
  final bool allowWithCoupon;
  final bool allowWithVoucher;
  final bool allowWithRewards;
  final bool allowWithCashback;

  final Map<String, dynamic> metadata;

  const RewardBenefitCandidate({
    required this.id,
    required this.title,
    this.description = '',
    required this.source,
    this.module = RewardModule.all,
    required this.estimatedSaving,
    this.requiredPoints = 0,
    this.minimumBookingAmount = 0,
    this.expiryDate,
    this.isValid = true,
    this.requiresConfirmation = true,
    this.allowWithPromo = false,
    this.allowWithCoupon = false,
    this.allowWithVoucher = false,
    this.allowWithRewards = false,
    this.allowWithCashback = true,
    this.metadata = const {},
  });

  bool supportsModule(RewardModule selectedModule) {
    return module == RewardModule.all ||
        module == selectedModule;
  }

  bool get isExpired {
    return expiryDate != null &&
        DateTime.now().isAfter(expiryDate!);
  }

  bool isEligible({
    required RewardModule selectedModule,
    required double bookingAmount,
  }) {
    if (!isValid || isExpired) {
      return false;
    }

    if (!supportsModule(selectedModule)) {
      return false;
    }

    if (bookingAmount < minimumBookingAmount) {
      return false;
    }

    if (estimatedSaving <= 0) {
      return false;
    }

    return true;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'source': source.name,
      'module': module.name,
      'estimatedSaving': estimatedSaving,
      'requiredPoints': requiredPoints,
      'minimumBookingAmount': minimumBookingAmount,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'isValid': isValid,
      'requiresConfirmation': requiresConfirmation,
      'allowWithPromo': allowWithPromo,
      'allowWithCoupon': allowWithCoupon,
      'allowWithVoucher': allowWithVoucher,
      'allowWithRewards': allowWithRewards,
      'allowWithCashback': allowWithCashback,
      'metadata': metadata,
    };
  }
}

class RewardAIRecommendation {
  final String id;
  final String userId;

  final RewardAIRecommendationType type;
  final RewardAIConfidence confidence;

  final RewardModule module;

  final String title;
  final String explanation;

  final RewardBenefitCandidate? recommendedCandidate;
  final List<RewardBenefitCandidate> alternatives;

  final double estimatedSaving;
  final int recommendedRewardPoints;

  /// Always true before any financial/benefit action.
  final bool requiresUserConfirmation;

  /// Security value: this engine never auto-applies.
  final bool autoApplied;

  final DateTime createdAt;
  final DateTime? expiresAt;

  final Map<String, dynamic> metadata;

  const RewardAIRecommendation({
    required this.id,
    required this.userId,
    required this.type,
    required this.confidence,
    required this.module,
    required this.title,
    required this.explanation,
    this.recommendedCandidate,
    this.alternatives = const [],
    this.estimatedSaving = 0,
    this.recommendedRewardPoints = 0,
    this.requiresUserConfirmation = true,
    this.autoApplied = false,
    required this.createdAt,
    this.expiresAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'confidence': confidence.name,
      'module': module.name,
      'title': title,
      'explanation': explanation,
      'recommendedCandidate':
          recommendedCandidate?.toMap(),
      'alternatives':
          alternatives.map((item) => item.toMap()).toList(),
      'estimatedSaving': estimatedSaving,
      'recommendedRewardPoints':
          recommendedRewardPoints,
      'requiresUserConfirmation': true,

      /// Safety enforcement.
      'autoApplied': false,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }
}

class RewardAILoyaltyPrediction {
  final LoyaltyLevelModel? currentLevel;
  final LoyaltyLevelModel? predictedNextLevel;

  final int currentLifetimePoints;
  final int currentCompletedBookings;

  final int pointsNeeded;
  final int bookingsNeeded;

  final int? estimatedBookingsToUpgrade;
  final double progressPercentage;

  final String message;

  const RewardAILoyaltyPrediction({
    this.currentLevel,
    this.predictedNextLevel,
    required this.currentLifetimePoints,
    required this.currentCompletedBookings,
    required this.pointsNeeded,
    required this.bookingsNeeded,
    this.estimatedBookingsToUpgrade,
    required this.progressPercentage,
    required this.message,
  });
}

class RewardAIService {
  final FirebaseFirestore _firestore;

  /// Keep true during local/testing development.
  ///
  /// Change to false for real Firestore recommendation audit.
  final bool useTestingBypass;

  bool _testingAIEnabled = false;

  final Map<String, RewardAIRecommendation>
      _testingRecommendations = {};

  RewardAIService({
    FirebaseFirestore? firestore,
    this.useTestingBypass = false,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>
      get _recommendationsCollection {
    return _firestore
        .collection('reward_ai_recommendations');
  }

  DocumentReference<Map<String, dynamic>>
      get _settingsDocument {
    return _firestore
        .collection('reward_settings')
        .doc('global_rewards');
  }

  // =============================================================
  // ADMIN AI CONTROL
  // =============================================================

  Future<void> setAIRecommendationsEnabled({
    required bool enabled,
    required String updatedBy,
  }) async {
    if (useTestingBypass) {
      _testingAIEnabled = enabled;
      return;
    }

    await _settingsDocument.set({
      'aiRecommendationsEnabled': enabled,

      /// Security: Admin cannot enable automatic financial action.
      'aiAutoApplyEnabled': false,
      'updatedBy': updatedBy,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'version': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Future<bool> isAIRecommendationsEnabled() async {
    if (useTestingBypass) {
      return _testingAIEnabled;
    }

    final document = await _settingsDocument.get();

    if (!document.exists || document.data() == null) {
      return false;
    }

    final settings = RewardSettingsModel.fromMap(
      document.data()!,
    );

    return settings.aiRecommendationsEnabled;
  }

  /// Always false by design.
  bool get canAutoApplyBenefits => false;

  /// Always false by design.
  bool get canFinalizePayment => false;

  /// Always false by design.
  bool get canModifyWallet => false;

  // =============================================================
  // BEST BENEFIT RECOMMENDATION
  // =============================================================

  Future<RewardAIRecommendation> recommendBestBenefit({
    required String userId,
    required RewardModule module,
    required double bookingAmount,
    required List<RewardBenefitCandidate> candidates,
    RewardWalletModel? rewardWallet,
    RewardSettingsModel? settings,
  }) async {
    if (!await isAIRecommendationsEnabled()) {
      return _disabledRecommendation(
        userId: userId,
        module: module,
      );
    }

    if (bookingAmount <= 0) {
      return _noBenefitRecommendation(
        userId: userId,
        module: module,
        explanation:
            'A valid booking amount is required.',
      );
    }

    final eligible = candidates.where((candidate) {
      if (!candidate.isEligible(
        selectedModule: module,
        bookingAmount: bookingAmount,
      )) {
        return false;
      }

      if (candidate.source ==
              RewardAIBenefitSource.rewardPoints &&
          rewardWallet != null &&
          candidate.requiredPoints >
              rewardWallet.availablePoints) {
        return false;
      }

      if (candidate.source ==
              RewardAIBenefitSource.rewardPoints &&
          settings != null &&
          candidate.requiredPoints <
              settings.minimumRedeemPoints) {
        return false;
      }

      return true;
    }).toList();

    eligible.sort((first, second) {
      final savingComparison = second.estimatedSaving
          .compareTo(first.estimatedSaving);

      if (savingComparison != 0) {
        return savingComparison;
      }

      return _expiryPriority(first).compareTo(
        _expiryPriority(second),
      );
    });

    if (eligible.isEmpty) {
      final result = _noBenefitRecommendation(
        userId: userId,
        module: module,
        explanation:
            'No valid promo, coupon, voucher or reward '
            'redemption is currently available.',
      );

      await _saveRecommendation(result);
      return result;
    }

    final best = eligible.first;
    final alternatives = eligible.skip(1).take(3).toList();

    final recommendationType =
        _recommendationTypeForSource(best.source);

    final explanation = _buildBenefitExplanation(
      best: best,
      bookingAmount: bookingAmount,
      alternativeCount: alternatives.length,
    );

    final now = DateTime.now();

    final result = RewardAIRecommendation(
      id: _recommendationId(
        userId: userId,
        type: recommendationType,
        sourceId: best.id,
      ),
      userId: userId,
      type: recommendationType,
      confidence: eligible.length == 1
          ? RewardAIConfidence.medium
          : RewardAIConfidence.high,
      module: module,
      title: 'Best reward option',
      explanation: explanation,
      recommendedCandidate: best,
      alternatives: alternatives,
      estimatedSaving: best.estimatedSaving,
      recommendedRewardPoints:
          best.source == RewardAIBenefitSource.rewardPoints
              ? best.requiredPoints
              : 0,
      requiresUserConfirmation: true,
      autoApplied: false,
      createdAt: now,
      expiresAt: best.expiryDate,
      metadata: {
        'bookingAmount': bookingAmount,
        'candidateCount': candidates.length,
        'eligibleCandidateCount': eligible.length,
      },
    );

    await _saveRecommendation(result);

    return result;
  }

  int _expiryPriority(RewardBenefitCandidate candidate) {
    if (candidate.expiryDate == null) {
      return 999999999;
    }

    return candidate.expiryDate!
        .difference(DateTime.now())
        .inMinutes;
  }

  String _buildBenefitExplanation({
    required RewardBenefitCandidate best,
    required double bookingAmount,
    required int alternativeCount,
  }) {
    final saving =
        best.estimatedSaving.toStringAsFixed(2);

    final sourceName = _sourceDisplayName(best.source);

    var explanation =
        '$sourceName can save approximately PKR $saving '
        'on this booking.';

    if (best.expiryDate != null) {
      final days =
          best.expiryDate!.difference(DateTime.now()).inDays;

      if (days >= 0 && days <= 7) {
        explanation +=
            ' This benefit is also expiring soon.';
      }
    }

    if (alternativeCount > 0) {
      explanation +=
          ' Other eligible options are available for comparison.';
    }

    explanation +=
        ' Nothing will be applied without your confirmation.';

    return explanation;
  }

  // =============================================================
  // REWARD POINTS OR PROMO COMPARISON
  // =============================================================

  Future<RewardAIRecommendation>
      compareRewardPointsWithDiscount({
    required String userId,
    required RewardModule module,
    required double bookingAmount,
    required int availablePoints,
    required int proposedRedeemPoints,
    required double pkrValuePerPoint,
    required double bestPromoSaving,
    String? promoId,
  }) async {
    if (!await isAIRecommendationsEnabled()) {
      return _disabledRecommendation(
        userId: userId,
        module: module,
      );
    }

    var safePoints = proposedRedeemPoints;

    if (safePoints > availablePoints) {
      safePoints = availablePoints;
    }

    if (safePoints < 0) {
      safePoints = 0;
    }

    var rewardSaving = safePoints * pkrValuePerPoint;

    if (rewardSaving > bookingAmount) {
      rewardSaving = bookingAmount;
    }

    final rewardIsBetter =
        rewardSaving > bestPromoSaving;

    final equalValue =
        (rewardSaving - bestPromoSaving).abs() < 0.01;

    RewardBenefitCandidate? recommendedCandidate;
    RewardAIRecommendationType type;
    String explanation;

    if (equalValue && rewardSaving > 0) {
      type = RewardAIRecommendationType.rewardRedemption;

      recommendedCandidate = RewardBenefitCandidate(
        id: 'reward_points',
        title: 'Use reward points',
        source: RewardAIBenefitSource.rewardPoints,
        module: module,
        estimatedSaving: rewardSaving,
        requiredPoints: safePoints,
      );

      explanation =
          'Reward points and promo provide nearly the same '
          'saving. You may keep your points for a future booking. '
          'Your confirmation is required.';
    } else if (rewardIsBetter) {
      type = RewardAIRecommendationType.rewardRedemption;

      recommendedCandidate = RewardBenefitCandidate(
        id: 'reward_points',
        title: 'Use reward points',
        source: RewardAIBenefitSource.rewardPoints,
        module: module,
        estimatedSaving: rewardSaving,
        requiredPoints: safePoints,
      );

      explanation =
          'Using $safePoints reward points may save '
          'PKR ${rewardSaving.toStringAsFixed(2)}, which is '
          'better than the available promo. Confirmation is required.';
    } else if (bestPromoSaving > 0) {
      type = RewardAIRecommendationType.promo;

      recommendedCandidate = RewardBenefitCandidate(
        id: promoId ?? 'best_promo',
        title: 'Use available promo',
        source: RewardAIBenefitSource.promo,
        module: module,
        estimatedSaving: bestPromoSaving,
      );

      explanation =
          'The available promo may save '
          'PKR ${bestPromoSaving.toStringAsFixed(2)}, while '
          'preserving your reward points. Confirmation is required.';
    } else {
      final result = _noBenefitRecommendation(
        userId: userId,
        module: module,
        explanation:
            'No useful reward redemption or promo saving '
            'is currently available.',
      );

      await _saveRecommendation(result);
      return result;
    }

    final result = RewardAIRecommendation(
      id: _recommendationId(
        userId: userId,
        type: type,
        sourceId: recommendedCandidate.id,
      ),
      userId: userId,
      type: type,
      confidence: RewardAIConfidence.high,
      module: module,
      title: 'Reward saving comparison',
      explanation: explanation,
      recommendedCandidate: recommendedCandidate,
      estimatedSaving:
          recommendedCandidate.estimatedSaving,
      recommendedRewardPoints:
          recommendedCandidate.requiredPoints,
      requiresUserConfirmation: true,
      autoApplied: false,
      createdAt: DateTime.now(),
      metadata: {
        'bookingAmount': bookingAmount,
        'availablePoints': availablePoints,
        'rewardSaving': rewardSaving,
        'promoSaving': bestPromoSaving,
      },
    );

    await _saveRecommendation(result);

    return result;
  }

  // =============================================================
  // EXPIRING POINTS RECOMMENDATION
  // =============================================================

  Future<RewardAIRecommendation>
      recommendForExpiringPoints({
    required String userId,
    required RewardModule module,
    required int expiringPoints,
    required DateTime expiryDate,
    required double pkrValuePerPoint,
    double? expectedNextBookingAmount,
  }) async {
    if (!await isAIRecommendationsEnabled()) {
      return _disabledRecommendation(
        userId: userId,
        module: module,
      );
    }

    if (expiringPoints <= 0) {
      return _noBenefitRecommendation(
        userId: userId,
        module: module,
        explanation:
            'No reward points are currently expiring.',
      );
    }

    final daysRemaining =
        expiryDate.difference(DateTime.now()).inDays;

    final estimatedValue =
        expiringPoints * pkrValuePerPoint;

    var recommendedPoints = expiringPoints;

    if (expectedNextBookingAmount != null &&
        expectedNextBookingAmount > 0 &&
        estimatedValue > expectedNextBookingAmount) {
      recommendedPoints =
          (expectedNextBookingAmount / pkrValuePerPoint)
              .floor();

      if (recommendedPoints > expiringPoints) {
        recommendedPoints = expiringPoints;
      }
    }

    final candidate = RewardBenefitCandidate(
      id: 'expiring_reward_points',
      title: 'Use expiring reward points',
      source: RewardAIBenefitSource.rewardPoints,
      module: module,
      estimatedSaving:
          recommendedPoints * pkrValuePerPoint,
      requiredPoints: recommendedPoints,
      expiryDate: expiryDate,
    );

    final result = RewardAIRecommendation(
      id: _recommendationId(
        userId: userId,
        type:
            RewardAIRecommendationType.expiringPoints,
        sourceId:
            expiryDate.millisecondsSinceEpoch.toString(),
      ),
      userId: userId,
      type: RewardAIRecommendationType.expiringPoints,
      confidence: RewardAIConfidence.high,
      module: module,
      title: 'Points expiring soon',
      explanation:
          '$expiringPoints points will expire in '
          '${daysRemaining < 0 ? 0 : daysRemaining} days. '
          'Using up to $recommendedPoints points may prevent '
          'loss. Points will not be redeemed automatically.',
      recommendedCandidate: candidate,
      estimatedSaving: candidate.estimatedSaving,
      recommendedRewardPoints: recommendedPoints,
      requiresUserConfirmation: true,
      autoApplied: false,
      createdAt: DateTime.now(),
      expiresAt: expiryDate,
      metadata: {
        'expiringPoints': expiringPoints,
        'expiryDate': expiryDate.millisecondsSinceEpoch,
        'estimatedPointValue': estimatedValue,
      },
    );

    await _saveRecommendation(result);

    return result;
  }

  // =============================================================
  // LOYALTY UPGRADE PREDICTION
  // =============================================================

  RewardAILoyaltyPrediction predictLoyaltyUpgrade({
    required LoyaltyLevelModel? currentLevel,
    required List<LoyaltyLevelModel> activeLevels,
    required int lifetimePoints,
    required int completedBookings,
    double averagePointsPerBooking = 0,
  }) {
    final levels = activeLevels
        .where(
          (level) =>
              level.isActive &&
              level.hasValidConfiguration,
        )
        .toList()
      ..sort(
        (first, second) => first.displayOrder
            .compareTo(second.displayOrder),
      );

    LoyaltyLevelModel? nextLevel;

    for (final level in levels) {
      if (currentLevel == null ||
          level.displayOrder >
              currentLevel.displayOrder) {
        nextLevel = level;
        break;
      }
    }

    if (nextLevel == null) {
      return RewardAILoyaltyPrediction(
        currentLevel: currentLevel,
        currentLifetimePoints: lifetimePoints,
        currentCompletedBookings: completedBookings,
        pointsNeeded: 0,
        bookingsNeeded: 0,
        estimatedBookingsToUpgrade: 0,
        progressPercentage: 100,
        message:
            'You have reached the highest active loyalty level.',
      );
    }

    final rawPointsNeeded =
        nextLevel.minimumLifetimePoints -
            lifetimePoints;

    final rawBookingsNeeded =
        nextLevel.minimumCompletedBookings -
            completedBookings;

    final pointsNeeded =
        rawPointsNeeded < 0 ? 0 : rawPointsNeeded;

    final bookingsNeeded =
        rawBookingsNeeded < 0 ? 0 : rawBookingsNeeded;

    int? bookingsFromPoints;

    if (pointsNeeded == 0) {
      bookingsFromPoints = 0;
    } else if (averagePointsPerBooking > 0) {
      bookingsFromPoints =
          (pointsNeeded / averagePointsPerBooking).ceil();
    }

    int? estimatedBookings;

    if (bookingsFromPoints != null) {
      estimatedBookings =
          bookingsFromPoints > bookingsNeeded
              ? bookingsFromPoints
              : bookingsNeeded;
    } else if (bookingsNeeded > 0) {
      estimatedBookings = bookingsNeeded;
    }

    final pointsTarget =
        nextLevel.minimumLifetimePoints;

    final bookingTarget =
        nextLevel.minimumCompletedBookings;

    final pointsProgress = pointsTarget <= 0
        ? 1.0
        : lifetimePoints / pointsTarget;

    final bookingsProgress = bookingTarget <= 0
        ? 1.0
        : completedBookings / bookingTarget;

    final limitingProgress =
        pointsProgress < bookingsProgress
            ? pointsProgress
            : bookingsProgress;

    final percentage =
        (limitingProgress.clamp(0.0, 1.0) * 100)
            .toDouble();

    var message =
        'You need $pointsNeeded more points and '
        '$bookingsNeeded more completed bookings '
        'to reach ${nextLevel.name}.';

    if (estimatedBookings != null &&
        estimatedBookings > 0) {
      message +=
          ' Based on your current activity, this may take '
          'approximately $estimatedBookings bookings.';
    }

    return RewardAILoyaltyPrediction(
      currentLevel: currentLevel,
      predictedNextLevel: nextLevel,
      currentLifetimePoints: lifetimePoints,
      currentCompletedBookings: completedBookings,
      pointsNeeded: pointsNeeded,
      bookingsNeeded: bookingsNeeded,
      estimatedBookingsToUpgrade: estimatedBookings,
      progressPercentage: percentage,
      message: message,
    );
  }

  Future<RewardAIRecommendation>
      createLoyaltyMilestoneRecommendation({
    required String userId,
    required RewardModule module,
    required RewardAILoyaltyPrediction prediction,
  }) async {
    if (!await isAIRecommendationsEnabled()) {
      return _disabledRecommendation(
        userId: userId,
        module: module,
      );
    }

    final result = RewardAIRecommendation(
      id: _recommendationId(
        userId: userId,
        type:
            RewardAIRecommendationType.nextMilestone,
        sourceId:
            prediction.predictedNextLevel?.id ?? 'highest',
      ),
      userId: userId,
      type: RewardAIRecommendationType.nextMilestone,
      confidence:
          prediction.estimatedBookingsToUpgrade == null
              ? RewardAIConfidence.medium
              : RewardAIConfidence.high,
      module: module,
      title: prediction.predictedNextLevel == null
          ? 'Highest loyalty level reached'
          : 'Next loyalty milestone',
      explanation: prediction.message,
      requiresUserConfirmation: true,
      autoApplied: false,
      createdAt: DateTime.now(),
      metadata: {
        'currentLevelId':
            prediction.currentLevel?.id,
        'nextLevelId':
            prediction.predictedNextLevel?.id,
        'pointsNeeded': prediction.pointsNeeded,
        'bookingsNeeded': prediction.bookingsNeeded,
        'estimatedBookingsToUpgrade':
            prediction.estimatedBookingsToUpgrade,
        'progressPercentage':
            prediction.progressPercentage,
      },
    );

    await _saveRecommendation(result);

    return result;
  }

  // =============================================================
  // PERSONALIZED OFFER RANKING
  // =============================================================

  Future<RewardAIRecommendation>
      recommendPersonalizedOffer({
    required String userId,
    required RewardModule preferredModule,
    required double expectedBookingAmount,
    required List<RewardBenefitCandidate> offers,
    List<RewardModule> recentlyUsedModules = const [],
  }) async {
    if (!await isAIRecommendationsEnabled()) {
      return _disabledRecommendation(
        userId: userId,
        module: preferredModule,
      );
    }

    final scoredOffers =
        <MapEntry<RewardBenefitCandidate, double>>[];

    for (final offer in offers) {
      if (!offer.isEligible(
        selectedModule: preferredModule,
        bookingAmount: expectedBookingAmount,
      )) {
        continue;
      }

      var score = offer.estimatedSaving;

      if (offer.module == preferredModule ||
          offer.module == RewardModule.all) {
        score += 20;
      }

      if (recentlyUsedModules.contains(offer.module)) {
        score += 10;
      }

      if (offer.expiryDate != null) {
        final days =
            offer.expiryDate!
                .difference(DateTime.now())
                .inDays;

        if (days >= 0 && days <= 7) {
          score += 5;
        }
      }

      scoredOffers.add(MapEntry(offer, score));
    }

    scoredOffers.sort(
      (first, second) =>
          second.value.compareTo(first.value),
    );

    if (scoredOffers.isEmpty) {
      final result = _noBenefitRecommendation(
        userId: userId,
        module: preferredModule,
        explanation:
            'No personalized offer currently matches '
            'your booking.',
      );

      await _saveRecommendation(result);
      return result;
    }

    final best = scoredOffers.first.key;
    final alternatives = scoredOffers
        .skip(1)
        .take(3)
        .map((entry) => entry.key)
        .toList();

    final result = RewardAIRecommendation(
      id: _recommendationId(
        userId: userId,
        type: RewardAIRecommendationType
            .personalizedOffer,
        sourceId: best.id,
      ),
      userId: userId,
      type:
          RewardAIRecommendationType.personalizedOffer,
      confidence: RewardAIConfidence.medium,
      module: preferredModule,
      title: 'Recommended offer',
      explanation:
          '${best.title} matches your selected service and '
          'may save PKR '
          '${best.estimatedSaving.toStringAsFixed(2)}. '
          'Your confirmation is required.',
      recommendedCandidate: best,
      alternatives: alternatives,
      estimatedSaving: best.estimatedSaving,
      recommendedRewardPoints: best.requiredPoints,
      requiresUserConfirmation: true,
      autoApplied: false,
      createdAt: DateTime.now(),
      expiresAt: best.expiryDate,
      metadata: {
        'expectedBookingAmount': expectedBookingAmount,
        'preferredModule': preferredModule.name,
      },
    );

    await _saveRecommendation(result);

    return result;
  }

  // =============================================================
  // RECOMMENDATION HISTORY
  // =============================================================

  Future<List<RewardAIRecommendation>>
      getTestingRecommendations(String userId) async {
    final recommendations =
        _testingRecommendations.values
            .where(
              (item) => item.userId == userId,
            )
            .toList();

    recommendations.sort(
      (first, second) =>
          second.createdAt.compareTo(first.createdAt),
    );

    return recommendations;
  }

  Future<List<Map<String, dynamic>>>
      getRecommendationHistory(
    String userId,
  ) async {
    if (useTestingBypass) {
      final recommendations =
          await getTestingRecommendations(userId);

      return recommendations
          .map((item) => item.toMap())
          .toList();
    }

    final query = await _recommendationsCollection
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

  Future<void> recordUserDecision({
    required String recommendationId,
    required String userId,
    required bool accepted,
    String? selectedCandidateId,
  }) async {
    final now = DateTime.now();

    if (useTestingBypass) {
      return;
    }

    await _recommendationsCollection
        .doc(recommendationId)
        .set({
      'userDecision': accepted ? 'accepted' : 'rejected',
      'selectedCandidateId': selectedCandidateId,
      'decisionUserId': userId,
      'decisionAt': now.millisecondsSinceEpoch,

      /// Even accepted recommendation is not auto-applied.
      'autoApplied': false,
      'requiresExecutionConfirmation': true,
    }, SetOptions(merge: true));
  }

  // =============================================================
  // INTERNAL SAFETY HELPERS
  // =============================================================

  Future<void> _saveRecommendation(
    RewardAIRecommendation recommendation,
  ) async {
    final safeMap = recommendation.toMap();

    /// Enforce security regardless of supplied data.
    safeMap['autoApplied'] = false;
    safeMap['requiresUserConfirmation'] = true;

    if (useTestingBypass) {
      _testingRecommendations[recommendation.id] =
          recommendation;
      return;
    }

    await _recommendationsCollection
        .doc(recommendation.id)
        .set(safeMap);
  }

  RewardAIRecommendation _disabledRecommendation({
    required String userId,
    required RewardModule module,
  }) {
    return RewardAIRecommendation(
      id: _recommendationId(
        userId: userId,
        type: RewardAIRecommendationType.noBenefit,
        sourceId: 'disabled',
      ),
      userId: userId,
      type: RewardAIRecommendationType.noBenefit,
      confidence: RewardAIConfidence.high,
      module: module,
      title: 'AI recommendations disabled',
      explanation:
          'Reward recommendations are disabled by Admin.',
      requiresUserConfirmation: true,
      autoApplied: false,
      createdAt: DateTime.now(),
    );
  }

  RewardAIRecommendation _noBenefitRecommendation({
    required String userId,
    required RewardModule module,
    required String explanation,
  }) {
    return RewardAIRecommendation(
      id: _recommendationId(
        userId: userId,
        type: RewardAIRecommendationType.noBenefit,
        sourceId:
            DateTime.now().millisecondsSinceEpoch.toString(),
      ),
      userId: userId,
      type: RewardAIRecommendationType.noBenefit,
      confidence: RewardAIConfidence.high,
      module: module,
      title: 'No reward benefit available',
      explanation: explanation,
      requiresUserConfirmation: true,
      autoApplied: false,
      createdAt: DateTime.now(),
    );
  }

  RewardAIRecommendationType _recommendationTypeForSource(
    RewardAIBenefitSource source,
  ) {
    switch (source) {
      case RewardAIBenefitSource.promo:
        return RewardAIRecommendationType.promo;

      case RewardAIBenefitSource.coupon:
        return RewardAIRecommendationType.coupon;

      case RewardAIBenefitSource.voucher:
        return RewardAIRecommendationType.voucher;

      case RewardAIBenefitSource.rewardPoints:
        return RewardAIRecommendationType.rewardRedemption;

      case RewardAIBenefitSource.cashback:
        return RewardAIRecommendationType.cashback;

      case RewardAIBenefitSource.loyalty:
        return RewardAIRecommendationType.loyaltyUpgrade;

      case RewardAIBenefitSource.none:
        return RewardAIRecommendationType.noBenefit;
    }
  }

  String _sourceDisplayName(
    RewardAIBenefitSource source,
  ) {
    switch (source) {
      case RewardAIBenefitSource.promo:
        return 'Promo';

      case RewardAIBenefitSource.coupon:
        return 'Coupon';

      case RewardAIBenefitSource.voucher:
        return 'Voucher';

      case RewardAIBenefitSource.rewardPoints:
        return 'Reward points';

      case RewardAIBenefitSource.cashback:
        return 'Cashback';

      case RewardAIBenefitSource.loyalty:
        return 'Loyalty benefit';

      case RewardAIBenefitSource.none:
        return 'No benefit';
    }
  }

  String _recommendationId({
    required String userId,
    required RewardAIRecommendationType type,
    required String sourceId,
  }) {
    final value =
        '$userId:${type.name}:$sourceId';

    return 'reward_ai_${_stableHash(value)}';
  }

  int _stableHash(String value) {
    var hash = 2166136261;

    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }

    return hash;
  }

  // =============================================================
  // TESTING HELPERS
  // =============================================================

  void setTestingAIEnabled(bool enabled) {
    _testingAIEnabled = enabled;
  }

  void clearTestingData() {
    _testingRecommendations.clear();
    _testingAIEnabled = false;
  }
}