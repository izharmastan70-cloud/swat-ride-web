// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/models/reward_transaction_model.dart
//
// Stores reward earning, redemption, expiry, reversal,
// referral bonuses and Admin adjustments.
// =============================================================

import 'reward_point_model.dart';

enum RewardTransactionType {
  earned,
  redeemed,
  signupBonus,
  firstBookingBonus,
  referralBonus,
  campaignBonus,
  manualCredit,
  manualDebit,
  expired,
  reversed,
  refundAdjustment,
}

enum RewardTransactionStatus {
  pending,
  completed,
  cancelled,
  reversed,
  expired,
  failed,
}

class RewardTransactionModel {
  final String id;
  final String userId;

  /// Module or role that created this transaction.
  final RewardModule module;

  final RewardTransactionType type;
  final RewardTransactionStatus status;

  /// Positive points add balance.
  /// Negative points deduct balance.
  final int points;

  final int balanceBefore;
  final int balanceAfter;

  /// Booking, order, delivery, referral or campaign ID.
  final String? sourceId;

  /// Reward rule used to calculate these points.
  final String? rewardRuleId;

  final String title;
  final String description;

  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;

  /// Original transaction reversed by this transaction.
  final String? reversedTransactionId;

  /// Prevents duplicate reward credit for the same source.
  final String? idempotencyKey;

  final Map<String, dynamic> metadata;

  const RewardTransactionModel({
    required this.id,
    required this.userId,
    required this.module,
    required this.type,
    required this.status,
    required this.points,
    required this.balanceBefore,
    required this.balanceAfter,
    this.sourceId,
    this.rewardRuleId,
    required this.title,
    this.description = '',
    required this.createdAt,
    this.completedAt,
    this.expiresAt,
    this.reversedTransactionId,
    this.idempotencyKey,
    this.metadata = const {},
  });

  bool get isCredit => points > 0;

  bool get isDebit => points < 0;

  bool get isPending {
    return status == RewardTransactionStatus.pending;
  }

  bool get isCompleted {
    return status == RewardTransactionStatus.completed;
  }

  bool get isReversed {
    return status == RewardTransactionStatus.reversed;
  }

  bool get isExpired {
    if (status == RewardTransactionStatus.expired) {
      return true;
    }

    if (expiresAt == null) {
      return false;
    }

    return DateTime.now().isAfter(expiresAt!);
  }

  bool get affectsBalance {
    return status == RewardTransactionStatus.completed;
  }

  RewardTransactionModel copyWith({
    String? id,
    String? userId,
    RewardModule? module,
    RewardTransactionType? type,
    RewardTransactionStatus? status,
    int? points,
    int? balanceBefore,
    int? balanceAfter,
    String? sourceId,
    bool removeSourceId = false,
    String? rewardRuleId,
    bool removeRewardRuleId = false,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? completedAt,
    bool removeCompletedAt = false,
    DateTime? expiresAt,
    bool removeExpiresAt = false,
    String? reversedTransactionId,
    bool removeReversedTransactionId = false,
    String? idempotencyKey,
    bool removeIdempotencyKey = false,
    Map<String, dynamic>? metadata,
  }) {
    return RewardTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      module: module ?? this.module,
      type: type ?? this.type,
      status: status ?? this.status,
      points: points ?? this.points,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      sourceId: removeSourceId ? null : sourceId ?? this.sourceId,
      rewardRuleId: removeRewardRuleId
          ? null
          : rewardRuleId ?? this.rewardRuleId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      completedAt: removeCompletedAt
          ? null
          : completedAt ?? this.completedAt,
      expiresAt: removeExpiresAt
          ? null
          : expiresAt ?? this.expiresAt,
      reversedTransactionId: removeReversedTransactionId
          ? null
          : reversedTransactionId ?? this.reversedTransactionId,
      idempotencyKey: removeIdempotencyKey
          ? null
          : idempotencyKey ?? this.idempotencyKey,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'module': module.name,
      'type': type.name,
      'status': status.name,
      'points': points,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'sourceId': sourceId,
      'rewardRuleId': rewardRuleId,
      'title': title,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'reversedTransactionId': reversedTransactionId,
      'idempotencyKey': idempotencyKey,
      'metadata': metadata,
    };
  }

  factory RewardTransactionModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return RewardTransactionModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      module: _moduleFromString(map['module']?.toString()),
      type: _typeFromString(map['type']?.toString()),
      status: _statusFromString(map['status']?.toString()),
      points: (map['points'] as num?)?.toInt() ?? 0,
      balanceBefore:
          (map['balanceBefore'] as num?)?.toInt() ?? 0,
      balanceAfter:
          (map['balanceAfter'] as num?)?.toInt() ?? 0,
      sourceId: map['sourceId']?.toString(),
      rewardRuleId: map['rewardRuleId']?.toString(),
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      createdAt:
          _dateFromValue(map['createdAt']) ?? DateTime.now(),
      completedAt: _dateFromValue(map['completedAt']),
      expiresAt: _dateFromValue(map['expiresAt']),
      reversedTransactionId:
          map['reversedTransactionId']?.toString(),
      idempotencyKey: map['idempotencyKey']?.toString(),
      metadata: Map<String, dynamic>.from(
        map['metadata'] as Map? ?? const {},
      ),
    );
  }

  static RewardModule _moduleFromString(String? value) {
    return RewardModule.values.firstWhere(
      (module) => module.name == value,
      orElse: () => RewardModule.all,
    );
  }

  static RewardTransactionType _typeFromString(String? value) {
    return RewardTransactionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => RewardTransactionType.earned,
    );
  }

  static RewardTransactionStatus _statusFromString(
    String? value,
  ) {
    return RewardTransactionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => RewardTransactionStatus.pending,
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