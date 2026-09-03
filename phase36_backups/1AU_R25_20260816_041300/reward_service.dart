// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/services/reward_service.dart
//
// Central reward service with:
// - Real Firestore support
// - Safe in-memory testing bypass
// - Duplicate reward protection
// - Atomic wallet updates
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/reward_production_gate.dart';
import '../models/reward_point_model.dart';
import '../models/reward_settings_model.dart';
import '../models/reward_transaction_model.dart';
import '../models/reward_wallet_model.dart';

class RewardService {
  RewardService({
    FirebaseFirestore? firestore,
    this.useTestingBypass = true,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Keep true during standalone testing.
  /// Set false after final Firebase integration.
  final bool useTestingBypass;

  static const String _settingsCollection = 'reward_settings';
  static const String _rulesCollection = 'reward_point_rules';
  static const String _walletsCollection = 'reward_wallets';
  static const String _transactionsCollection =
      'reward_transactions';
  static const String _idempotencyCollection =
      'reward_idempotency';

  static const String globalSettingsId = 'global_rewards';

  // -----------------------------------------------------------
  // TESTING BYPASS STORAGE
  // -----------------------------------------------------------

  static RewardSettingsModel? _testingSettings;

  static final Map<String, RewardPointModel> _testingRules = {};

  static final Map<String, RewardWalletModel> _testingWallets = {};

  static final Map<String, RewardTransactionModel>
      _testingTransactions = {};

  static final Set<String> _testingIdempotencyKeys = {};

  // -----------------------------------------------------------
  // SETTINGS
  // -----------------------------------------------------------

  Future<RewardSettingsModel> getSettings() async {
    if (useTestingBypass) {
      return _testingSettings ?? _defaultDisabledSettings();
    }

    final snapshot = await _firestore
        .collection(_settingsCollection)
        .doc(globalSettingsId)
        .get();

    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return _defaultDisabledSettings();
    }

    return RewardSettingsModel.fromMap({
      ...data,
      'id': snapshot.id,
    });
  }

  Stream<RewardSettingsModel> watchSettings() {
    if (useTestingBypass) {
      return Stream.value(
        _testingSettings ?? _defaultDisabledSettings(),
      );
    }

    return _firestore
        .collection(_settingsCollection)
        .doc(globalSettingsId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return _defaultDisabledSettings();
      }

      return RewardSettingsModel.fromMap({
        ...data,
        'id': snapshot.id,
      });
    });
  }

  Future<void> saveSettings(
    RewardSettingsModel settings,
  ) async {
    final updatedSettings = RewardSettingsModel.fromMap({
      ...settings.toMap(),
      'id': globalSettingsId,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'version': settings.version + 1,
    });

    if (useTestingBypass) {
      _testingSettings = updatedSettings;
      return;
    }

    await _firestore
        .collection(_settingsCollection)
        .doc(globalSettingsId)
        .set(
          updatedSettings.toMap(),
          SetOptions(merge: true),
        );
  }

  // -----------------------------------------------------------
  // REWARD POINT RULES
  // -----------------------------------------------------------

  Future<void> saveRewardRule(
    RewardPointModel rule,
  ) async {
    if (rule.id.trim().isEmpty) {
      throw ArgumentError('Reward rule ID is required.');
    }

    if (useTestingBypass) {
      _testingRules[rule.id] = rule;
      return;
    }

    await _firestore
        .collection(_rulesCollection)
        .doc(rule.id)
        .set(
          rule.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<RewardPointModel?> getRewardRule(
    String ruleId,
  ) async {
    if (ruleId.trim().isEmpty) {
      return null;
    }

    if (useTestingBypass) {
      return _testingRules[ruleId];
    }

    final snapshot = await _firestore
        .collection(_rulesCollection)
        .doc(ruleId)
        .get();

    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return RewardPointModel.fromMap({
      ...data,
      'id': snapshot.id,
    });
  }

  Stream<List<RewardPointModel>> watchRewardRules() {
    if (useTestingBypass) {
      final rules = _testingRules.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      return Stream.value(rules);
    }

    return _firestore
        .collection(_rulesCollection)
        .snapshots()
        .map((snapshot) {
      final rules = snapshot.docs.map((document) {
        return RewardPointModel.fromMap({
          ...document.data(),
          'id': document.id,
        });
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      return rules;
    });
  }

  Future<void> setRewardRuleActive({
    required String ruleId,
    required bool isActive,
  }) async {
    if (useTestingBypass) {
      final current = _testingRules[ruleId];

      if (current == null) {
        return;
      }

      _testingRules[ruleId] = current.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );
      return;
    }

    await _firestore
        .collection(_rulesCollection)
        .doc(ruleId)
        .update({
      'isActive': isActive,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // -----------------------------------------------------------
  // REWARD WALLET
  // -----------------------------------------------------------

  Future<RewardWalletModel> getWallet(
    String userId,
  ) async {
    _validateUserId(userId);

    if (useTestingBypass) {
      return _testingWallets[userId] ??
          _emptyWallet(userId);
    }

    final snapshot = await _firestore
        .collection(_walletsCollection)
        .doc(userId)
        .get();

    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return _emptyWallet(userId);
    }

    return RewardWalletModel.fromMap({
      ...data,
      'id': snapshot.id,
      'userId': userId,
    });
  }

  Stream<RewardWalletModel> watchWallet(
    String userId,
  ) {
    _validateUserId(userId);

    if (useTestingBypass) {
      return Stream.value(
        _testingWallets[userId] ?? _emptyWallet(userId),
      );
    }

    return _firestore
        .collection(_walletsCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return _emptyWallet(userId);
      }

      return RewardWalletModel.fromMap({
        ...data,
        'id': snapshot.id,
        'userId': userId,
      });
    });
  }

  // -----------------------------------------------------------
  // CALCULATE POINTS
  // -----------------------------------------------------------

  Future<int> calculateEarnablePoints({
    required RewardPointModel rule,
    required RewardModule module,
    required double eligibleAmount,
    int earnedToday = 0,
    int earnedThisMonth = 0,
    int earnedThisYear = 0,
  }) async {
    final settings = await getSettings();

    if (!settings.hasValidConfiguration) {
      return 0;
    }

    if (!settings.isRewardEnabledForModule(module)) {
      return 0;
    }

    final calculatedPoints = rule.calculatePoints(
      eligibleAmount: eligibleAmount,
      selectedModule: module,
    );

    return settings.applyEarnLimits(
      calculatedPoints: calculatedPoints,
      earnedToday: earnedToday,
      earnedThisMonth: earnedThisMonth,
      earnedThisYear: earnedThisYear,
    );
  }

  // -----------------------------------------------------------
  // EARN POINTS
  // -----------------------------------------------------------

  Future<RewardTransactionModel> earnPoints({
    required String userId,
    required RewardPointModel rule,
    required RewardModule module,
    required double eligibleAmount,
    required String sourceId,
    required String idempotencyKey,
    String title = 'Reward points earned',
    String description = '',
    int earnedToday = 0,
    int earnedThisMonth = 0,
    int earnedThisYear = 0,
  }) async {
    if (!RewardProductionGate.financialMutationsEnabled) {
      throw StateError(
        'Reward-point earning is temporarily disabled in production. '
        'A trusted backend is required before reward balances can be changed.',
      );
    }
    _validateUserId(userId);
    _validateSourceAndIdempotency(
      sourceId: sourceId,
      idempotencyKey: idempotencyKey,
    );

    final settings = await getSettings();

    if (!settings.isRewardEnabledForModule(module)) {
      throw StateError(
        'Rewards are disabled for ${module.name}.',
      );
    }

    final points = await calculateEarnablePoints(
      rule: rule,
      module: module,
      eligibleAmount: eligibleAmount,
      earnedToday: earnedToday,
      earnedThisMonth: earnedThisMonth,
      earnedThisYear: earnedThisYear,
    );

    if (points <= 0) {
      throw StateError(
        'No reward points are available for this transaction.',
      );
    }

    final expiresAt =
        settings.calculateRewardExpiry(DateTime.now());

    if (useTestingBypass) {
      return _earnPointsTesting(
        userId: userId,
        rule: rule,
        module: module,
        points: points,
        sourceId: sourceId,
        idempotencyKey: idempotencyKey,
        title: title,
        description: description,
        expiresAt: expiresAt,
      );
    }

    return _earnPointsFirestore(
      userId: userId,
      rule: rule,
      module: module,
      points: points,
      sourceId: sourceId,
      idempotencyKey: idempotencyKey,
      title: title,
      description: description,
      expiresAt: expiresAt,
    );
  }

  RewardTransactionModel _earnPointsTesting({
    required String userId,
    required RewardPointModel rule,
    required RewardModule module,
    required int points,
    required String sourceId,
    required String idempotencyKey,
    required String title,
    required String description,
    required DateTime? expiresAt,
  }) {
    if (_testingIdempotencyKeys.contains(idempotencyKey)) {
      throw StateError('Duplicate reward transaction blocked.');
    }

    final now = DateTime.now();
    final wallet =
        _testingWallets[userId] ?? _emptyWallet(userId);

    if (!wallet.canEarn) {
      throw StateError('Reward wallet is inactive or frozen.');
    }

    final modulePoints = Map<String, int>.from(
      wallet.modulePoints,
    );

    modulePoints[module.name] =
        (modulePoints[module.name] ?? 0) + points;

    final updatedWallet = wallet.copyWith(
      availablePoints: wallet.availablePoints + points,
      lifetimeEarnedPoints:
          wallet.lifetimeEarnedPoints + points,
      modulePoints: modulePoints,
      version: wallet.version + 1,
      updatedAt: now,
      lastEarnedAt: now,
    );

    final transactionId =
        'test_reward_${now.microsecondsSinceEpoch}';

    final rewardTransaction = RewardTransactionModel(
      id: transactionId,
      userId: userId,
      module: module,
      type: RewardTransactionType.earned,
      status: RewardTransactionStatus.completed,
      points: points,
      balanceBefore: wallet.availablePoints,
      balanceAfter: updatedWallet.availablePoints,
      sourceId: sourceId,
      rewardRuleId: rule.id,
      title: title,
      description: description,
      createdAt: now,
      completedAt: now,
      expiresAt: expiresAt,
      idempotencyKey: idempotencyKey,
    );

    _testingWallets[userId] = updatedWallet;
    _testingTransactions[transactionId] =
        rewardTransaction;
    _testingIdempotencyKeys.add(idempotencyKey);

    return rewardTransaction;
  }

  Future<RewardTransactionModel> _earnPointsFirestore({
    required String userId,
    required RewardPointModel rule,
    required RewardModule module,
    required int points,
    required String sourceId,
    required String idempotencyKey,
    required String title,
    required String description,
    required DateTime? expiresAt,
  }) async {
    final walletReference = _firestore
        .collection(_walletsCollection)
        .doc(userId);

    final transactionReference = _firestore
        .collection(_transactionsCollection)
        .doc();

    final idempotencyReference = _firestore
        .collection(_idempotencyCollection)
        .doc(_safeDocumentId(idempotencyKey));

    return _firestore.runTransaction(
      (firestoreTransaction) async {
        final idempotencySnapshot =
            await firestoreTransaction.get(
          idempotencyReference,
        );

        if (idempotencySnapshot.exists) {
          throw StateError(
            'Duplicate reward transaction blocked.',
          );
        }

        final walletSnapshot =
            await firestoreTransaction.get(
          walletReference,
        );

        final walletData = walletSnapshot.data();

        final wallet =
            walletSnapshot.exists && walletData != null
                ? RewardWalletModel.fromMap({
                    ...walletData,
                    'id': walletSnapshot.id,
                    'userId': userId,
                  })
                : _emptyWallet(userId);

        if (!wallet.canEarn) {
          throw StateError(
            'Reward wallet is inactive or frozen.',
          );
        }

        final now = DateTime.now();

        final modulePoints = Map<String, int>.from(
          wallet.modulePoints,
        );

        modulePoints[module.name] =
            (modulePoints[module.name] ?? 0) + points;

        final updatedWallet = wallet.copyWith(
          availablePoints: wallet.availablePoints + points,
          lifetimeEarnedPoints:
              wallet.lifetimeEarnedPoints + points,
          modulePoints: modulePoints,
          version: wallet.version + 1,
          updatedAt: now,
          lastEarnedAt: now,
        );

        final rewardTransaction = RewardTransactionModel(
          id: transactionReference.id,
          userId: userId,
          module: module,
          type: RewardTransactionType.earned,
          status: RewardTransactionStatus.completed,
          points: points,
          balanceBefore: wallet.availablePoints,
          balanceAfter: updatedWallet.availablePoints,
          sourceId: sourceId,
          rewardRuleId: rule.id,
          title: title,
          description: description,
          createdAt: now,
          completedAt: now,
          expiresAt: expiresAt,
          idempotencyKey: idempotencyKey,
        );

        firestoreTransaction.set(
          walletReference,
          updatedWallet.toMap(),
        );

        firestoreTransaction.set(
          transactionReference,
          rewardTransaction.toMap(),
        );

        firestoreTransaction.set(
          idempotencyReference,
          {
            'idempotencyKey': idempotencyKey,
            'transactionId': transactionReference.id,
            'userId': userId,
            'sourceId': sourceId,
            'createdAt': now.millisecondsSinceEpoch,
          },
        );

        return rewardTransaction;
      },
    );
  }

  // -----------------------------------------------------------
  // REDEEM POINTS
  // -----------------------------------------------------------

  Future<RewardTransactionModel> redeemPoints({
    required String userId,
    required RewardModule module,
    required int points,
    required String sourceId,
    required String idempotencyKey,
    String title = 'Reward points redeemed',
    String description = '',
    int redeemedToday = 0,
    int redeemedThisMonth = 0,
    int redeemedThisYear = 0,
  }) async {
    if (!RewardProductionGate.financialMutationsEnabled) {
      throw StateError(
        'Reward-point redemption is temporarily disabled in production. '
        'A trusted backend is required before reward balances can be changed.',
      );
    }
    _validateUserId(userId);
    _validateSourceAndIdempotency(
      sourceId: sourceId,
      idempotencyKey: idempotencyKey,
    );

    final settings = await getSettings();
    final wallet = await getWallet(userId);

    final canRedeem = settings.canRedeemPoints(
      module: module,
      requestedPoints: points,
      availablePoints: wallet.availablePoints,
      redeemedToday: redeemedToday,
      redeemedThisMonth: redeemedThisMonth,
      redeemedThisYear: redeemedThisYear,
    );

    if (!canRedeem) {
      throw StateError(
        'Reward points cannot be redeemed.',
      );
    }

    if (useTestingBypass) {
      return _redeemPointsTesting(
        userId: userId,
        module: module,
        points: points,
        sourceId: sourceId,
        idempotencyKey: idempotencyKey,
        title: title,
        description: description,
      );
    }

    return _redeemPointsFirestore(
      userId: userId,
      module: module,
      points: points,
      sourceId: sourceId,
      idempotencyKey: idempotencyKey,
      title: title,
      description: description,
    );
  }

  RewardTransactionModel _redeemPointsTesting({
    required String userId,
    required RewardModule module,
    required int points,
    required String sourceId,
    required String idempotencyKey,
    required String title,
    required String description,
  }) {
    if (_testingIdempotencyKeys.contains(idempotencyKey)) {
      throw StateError('Duplicate redemption blocked.');
    }

    final wallet =
        _testingWallets[userId] ?? _emptyWallet(userId);

    if (!wallet.canRedeem(points)) {
      throw StateError('Insufficient reward points.');
    }

    final now = DateTime.now();

    final updatedWallet = wallet.copyWith(
      availablePoints: wallet.availablePoints - points,
      lifetimeRedeemedPoints:
          wallet.lifetimeRedeemedPoints + points,
      version: wallet.version + 1,
      updatedAt: now,
      lastRedeemedAt: now,
    );

    final transactionId =
        'test_redeem_${now.microsecondsSinceEpoch}';

    final rewardTransaction = RewardTransactionModel(
      id: transactionId,
      userId: userId,
      module: module,
      type: RewardTransactionType.redeemed,
      status: RewardTransactionStatus.completed,
      points: -points,
      balanceBefore: wallet.availablePoints,
      balanceAfter: updatedWallet.availablePoints,
      sourceId: sourceId,
      title: title,
      description: description,
      createdAt: now,
      completedAt: now,
      idempotencyKey: idempotencyKey,
    );

    _testingWallets[userId] = updatedWallet;
    _testingTransactions[transactionId] =
        rewardTransaction;
    _testingIdempotencyKeys.add(idempotencyKey);

    return rewardTransaction;
  }

  Future<RewardTransactionModel> _redeemPointsFirestore({
    required String userId,
    required RewardModule module,
    required int points,
    required String sourceId,
    required String idempotencyKey,
    required String title,
    required String description,
  }) async {
    final walletReference = _firestore
        .collection(_walletsCollection)
        .doc(userId);

    final transactionReference = _firestore
        .collection(_transactionsCollection)
        .doc();

    final idempotencyReference = _firestore
        .collection(_idempotencyCollection)
        .doc(_safeDocumentId(idempotencyKey));

    return _firestore.runTransaction(
      (firestoreTransaction) async {
        final idempotencySnapshot =
            await firestoreTransaction.get(
          idempotencyReference,
        );

        if (idempotencySnapshot.exists) {
          throw StateError('Duplicate redemption blocked.');
        }

        final walletSnapshot =
            await firestoreTransaction.get(
          walletReference,
        );

        final walletData = walletSnapshot.data();

        if (!walletSnapshot.exists || walletData == null) {
          throw StateError('Reward wallet does not exist.');
        }

        final wallet = RewardWalletModel.fromMap({
          ...walletData,
          'id': walletSnapshot.id,
          'userId': userId,
        });

        if (!wallet.canRedeem(points)) {
          throw StateError('Insufficient reward points.');
        }

        final now = DateTime.now();

        final updatedWallet = wallet.copyWith(
          availablePoints:
              wallet.availablePoints - points,
          lifetimeRedeemedPoints:
              wallet.lifetimeRedeemedPoints + points,
          version: wallet.version + 1,
          updatedAt: now,
          lastRedeemedAt: now,
        );

        final rewardTransaction = RewardTransactionModel(
          id: transactionReference.id,
          userId: userId,
          module: module,
          type: RewardTransactionType.redeemed,
          status: RewardTransactionStatus.completed,
          points: -points,
          balanceBefore: wallet.availablePoints,
          balanceAfter: updatedWallet.availablePoints,
          sourceId: sourceId,
          title: title,
          description: description,
          createdAt: now,
          completedAt: now,
          idempotencyKey: idempotencyKey,
        );

        firestoreTransaction.set(
          walletReference,
          updatedWallet.toMap(),
        );

        firestoreTransaction.set(
          transactionReference,
          rewardTransaction.toMap(),
        );

        firestoreTransaction.set(
          idempotencyReference,
          {
            'idempotencyKey': idempotencyKey,
            'transactionId': transactionReference.id,
            'userId': userId,
            'sourceId': sourceId,
            'createdAt': now.millisecondsSinceEpoch,
          },
        );

        return rewardTransaction;
      },
    );
  }

  // -----------------------------------------------------------
  // TRANSACTION HISTORY
  // -----------------------------------------------------------

  Stream<List<RewardTransactionModel>> watchUserTransactions(
    String userId,
  ) {
    _validateUserId(userId);

    if (useTestingBypass) {
      final transactions = _testingTransactions.values
          .where((item) => item.userId == userId)
          .toList()
        ..sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );

      return Stream.value(transactions);
    }

    return _firestore
        .collection(_transactionsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final transactions = snapshot.docs.map((document) {
        return RewardTransactionModel.fromMap({
          ...document.data(),
          'id': document.id,
        });
      }).toList()
        ..sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );

      return transactions;
    });
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

    _testingSettings = null;
    _testingRules.clear();
    _testingWallets.clear();
    _testingTransactions.clear();
    _testingIdempotencyKeys.clear();
  }

  // -----------------------------------------------------------
  // PRIVATE HELPERS
  // -----------------------------------------------------------

  RewardSettingsModel _defaultDisabledSettings() {
    final now = DateTime.now();

    return RewardSettingsModel(
      id: globalSettingsId,
      updatedBy: 'system_default',
      createdAt: now,
      updatedAt: now,
    );
  }

  RewardWalletModel _emptyWallet(String userId) {
    final now = DateTime.now();

    return RewardWalletModel(
      id: userId,
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );
  }

  void _validateUserId(String userId) {
    if (userId.trim().isEmpty) {
      throw ArgumentError('User ID is required.');
    }
  }

  void _validateSourceAndIdempotency({
    required String sourceId,
    required String idempotencyKey,
  }) {
    if (sourceId.trim().isEmpty) {
      throw ArgumentError('Source ID is required.');
    }

    if (idempotencyKey.trim().isEmpty) {
      throw ArgumentError('Idempotency key is required.');
    }
  }

  String _safeDocumentId(String value) {
    return value
        .trim()
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll(' ', '_');
  }
}