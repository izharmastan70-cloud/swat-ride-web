// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/models/reward_wallet_model.dart
//
// Stores the user's global reward points balance.
// This is separate from the user's cash/payment wallet.
// =============================================================

class RewardWalletModel {
  final String id;
  final String userId;

  /// Points available for redemption.
  final int availablePoints;

  /// Points waiting for booking/payment completion.
  final int pendingPoints;

  /// Points earned during the user's lifetime.
  final int lifetimeEarnedPoints;

  /// Points redeemed during the user's lifetime.
  final int lifetimeRedeemedPoints;

  /// Points that have expired.
  final int lifetimeExpiredPoints;

  /// Points reversed due to cancellation or refund.
  final int lifetimeReversedPoints;

  /// Current loyalty level ID, such as Bronze or Gold.
  final String loyaltyLevelId;

  /// Separate point totals for each module.
  /// Example: {'ride': 100, 'food': 50}
  final Map<String, int> modulePoints;

  final bool isActive;
  final bool isFrozen;

  /// Admin reason when the wallet is frozen.
  final String? freezeReason;

  /// Used to prevent conflicting wallet updates.
  final int version;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastEarnedAt;
  final DateTime? lastRedeemedAt;

  final Map<String, dynamic> metadata;

  const RewardWalletModel({
    required this.id,
    required this.userId,
    this.availablePoints = 0,
    this.pendingPoints = 0,
    this.lifetimeEarnedPoints = 0,
    this.lifetimeRedeemedPoints = 0,
    this.lifetimeExpiredPoints = 0,
    this.lifetimeReversedPoints = 0,
    this.loyaltyLevelId = 'bronze',
    this.modulePoints = const {},
    this.isActive = true,
    this.isFrozen = false,
    this.freezeReason,
    this.version = 0,
    required this.createdAt,
    required this.updatedAt,
    this.lastEarnedAt,
    this.lastRedeemedAt,
    this.metadata = const {},
  });

  int get totalTrackedPoints {
    return availablePoints + pendingPoints;
  }

  bool get canEarn {
    return isActive && !isFrozen;
  }

  bool canRedeem(int requestedPoints) {
    if (!isActive || isFrozen) {
      return false;
    }

    if (requestedPoints <= 0) {
      return false;
    }

    return availablePoints >= requestedPoints;
  }

  int pointsForModule(String moduleName) {
    return modulePoints[moduleName] ?? 0;
  }

  RewardWalletModel copyWith({
    String? id,
    String? userId,
    int? availablePoints,
    int? pendingPoints,
    int? lifetimeEarnedPoints,
    int? lifetimeRedeemedPoints,
    int? lifetimeExpiredPoints,
    int? lifetimeReversedPoints,
    String? loyaltyLevelId,
    Map<String, int>? modulePoints,
    bool? isActive,
    bool? isFrozen,
    String? freezeReason,
    bool removeFreezeReason = false,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastEarnedAt,
    bool removeLastEarnedAt = false,
    DateTime? lastRedeemedAt,
    bool removeLastRedeemedAt = false,
    Map<String, dynamic>? metadata,
  }) {
    return RewardWalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      availablePoints: availablePoints ?? this.availablePoints,
      pendingPoints: pendingPoints ?? this.pendingPoints,
      lifetimeEarnedPoints:
          lifetimeEarnedPoints ?? this.lifetimeEarnedPoints,
      lifetimeRedeemedPoints:
          lifetimeRedeemedPoints ?? this.lifetimeRedeemedPoints,
      lifetimeExpiredPoints:
          lifetimeExpiredPoints ?? this.lifetimeExpiredPoints,
      lifetimeReversedPoints:
          lifetimeReversedPoints ?? this.lifetimeReversedPoints,
      loyaltyLevelId: loyaltyLevelId ?? this.loyaltyLevelId,
      modulePoints: modulePoints ?? this.modulePoints,
      isActive: isActive ?? this.isActive,
      isFrozen: isFrozen ?? this.isFrozen,
      freezeReason: removeFreezeReason
          ? null
          : freezeReason ?? this.freezeReason,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastEarnedAt: removeLastEarnedAt
          ? null
          : lastEarnedAt ?? this.lastEarnedAt,
      lastRedeemedAt: removeLastRedeemedAt
          ? null
          : lastRedeemedAt ?? this.lastRedeemedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'availablePoints': availablePoints,
      'pendingPoints': pendingPoints,
      'lifetimeEarnedPoints': lifetimeEarnedPoints,
      'lifetimeRedeemedPoints': lifetimeRedeemedPoints,
      'lifetimeExpiredPoints': lifetimeExpiredPoints,
      'lifetimeReversedPoints': lifetimeReversedPoints,
      'loyaltyLevelId': loyaltyLevelId,
      'modulePoints': modulePoints,
      'isActive': isActive,
      'isFrozen': isFrozen,
      'freezeReason': freezeReason,
      'version': version,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'lastEarnedAt': lastEarnedAt?.millisecondsSinceEpoch,
      'lastRedeemedAt':
          lastRedeemedAt?.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  factory RewardWalletModel.fromMap(Map<String, dynamic> map) {
    return RewardWalletModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      availablePoints:
          (map['availablePoints'] as num?)?.toInt() ?? 0,
      pendingPoints:
          (map['pendingPoints'] as num?)?.toInt() ?? 0,
      lifetimeEarnedPoints:
          (map['lifetimeEarnedPoints'] as num?)?.toInt() ?? 0,
      lifetimeRedeemedPoints:
          (map['lifetimeRedeemedPoints'] as num?)?.toInt() ?? 0,
      lifetimeExpiredPoints:
          (map['lifetimeExpiredPoints'] as num?)?.toInt() ?? 0,
      lifetimeReversedPoints:
          (map['lifetimeReversedPoints'] as num?)?.toInt() ?? 0,
      loyaltyLevelId:
          map['loyaltyLevelId']?.toString() ?? 'bronze',
      modulePoints: _intMapFromValue(map['modulePoints']),
      isActive: map['isActive'] as bool? ?? true,
      isFrozen: map['isFrozen'] as bool? ?? false,
      freezeReason: map['freezeReason']?.toString(),
      version: (map['version'] as num?)?.toInt() ?? 0,
      createdAt:
          _dateFromValue(map['createdAt']) ?? DateTime.now(),
      updatedAt:
          _dateFromValue(map['updatedAt']) ?? DateTime.now(),
      lastEarnedAt: _dateFromValue(map['lastEarnedAt']),
      lastRedeemedAt: _dateFromValue(map['lastRedeemedAt']),
      metadata: Map<String, dynamic>.from(
        map['metadata'] as Map? ?? const {},
      ),
    );
  }

  static Map<String, int> _intMapFromValue(dynamic value) {
    if (value is! Map) {
      return {};
    }

    return value.map(
      (key, item) => MapEntry(
        key.toString(),
        item is num ? item.toInt() : 0,
      ),
    );
  }

  static DateTime? _dateFromValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
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
}