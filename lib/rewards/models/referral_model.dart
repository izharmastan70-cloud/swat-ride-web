// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/models/referral_model.dart
//
// Tracks inviter and invited-user referrals, qualification,
// rewards, expiry and fraud-review status.
// =============================================================

import 'reward_point_model.dart';

enum ReferralStatus {
  pending,
  registered,
  qualified,
  rewarded,
  rejected,
  expired,
  cancelled,
}

enum ReferralRewardType {
  none,
  rewardPoints,
  walletCredit,
  coupon,
  voucher,
}

class ReferralModel {
  final String id;
  final String referralCode;

  final String inviterUserId;
  final String? invitedUserId;

  final ReferralStatus status;

  /// Module required for referral qualification.
  /// RewardModule.all means any supported customer module.
  final RewardModule qualifyingModule;

  /// Required number of completed bookings/orders.
  final int requiredCompletedBookings;

  /// Minimum value of each qualifying booking/order.
  final double minimumQualifyingAmount;

  /// Reward configuration saved as an audit snapshot.
  final ReferralRewardType inviterRewardType;
  final double inviterRewardValue;
  final String? inviterBenefitId;

  final ReferralRewardType invitedUserRewardType;
  final double invitedUserRewardValue;
  final String? invitedUserBenefitId;

  final bool inviterRewardIssued;
  final bool invitedUserRewardIssued;

  final String? inviterRewardTransactionId;
  final String? invitedUserRewardTransactionId;

  /// Number of completed qualifying transactions.
  final int completedQualifyingBookings;

  /// Referral verification and fraud protection.
  final bool phoneVerified;
  final bool identityVerified;
  final bool requiresManualReview;
  final bool isFraudSuspected;
  final String? reviewReason;
  final String? reviewedBy;

  /// Prevents duplicate reward issuance.
  final String idempotencyKey;

  final DateTime createdAt;
  final DateTime? registeredAt;
  final DateTime? qualifiedAt;
  final DateTime? rewardedAt;
  final DateTime? reviewedAt;
  final DateTime? expiryDate;
  final DateTime updatedAt;

  final Map<String, dynamic> metadata;

  const ReferralModel({
    required this.id,
    required this.referralCode,
    required this.inviterUserId,
    this.invitedUserId,
    this.status = ReferralStatus.pending,
    this.qualifyingModule = RewardModule.all,
    this.requiredCompletedBookings = 1,
    this.minimumQualifyingAmount = 0,
    this.inviterRewardType = ReferralRewardType.rewardPoints,
    this.inviterRewardValue = 0,
    this.inviterBenefitId,
    this.invitedUserRewardType = ReferralRewardType.rewardPoints,
    this.invitedUserRewardValue = 0,
    this.invitedUserBenefitId,
    this.inviterRewardIssued = false,
    this.invitedUserRewardIssued = false,
    this.inviterRewardTransactionId,
    this.invitedUserRewardTransactionId,
    this.completedQualifyingBookings = 0,
    this.phoneVerified = false,
    this.identityVerified = false,
    this.requiresManualReview = false,
    this.isFraudSuspected = false,
    this.reviewReason,
    this.reviewedBy,
    required this.idempotencyKey,
    required this.createdAt,
    this.registeredAt,
    this.qualifiedAt,
    this.rewardedAt,
    this.reviewedAt,
    this.expiryDate,
    required this.updatedAt,
    this.metadata = const {},
  });

  String get normalizedReferralCode {
    return referralCode.trim().toUpperCase();
  }

  bool get isExpired {
    if (status == ReferralStatus.expired) {
      return true;
    }

    if (expiryDate == null) {
      return false;
    }

    return DateTime.now().isAfter(expiryDate!);
  }

  bool get canBeQualified {
    if (isExpired || isFraudSuspected || requiresManualReview) {
      return false;
    }

    if (!phoneVerified) {
      return false;
    }

    if (invitedUserId == null || invitedUserId!.trim().isEmpty) {
      return false;
    }

    if (invitedUserId == inviterUserId) {
      return false;
    }

    return status == ReferralStatus.registered ||
        status == ReferralStatus.pending;
  }

  bool supportsQualifyingModule(RewardModule module) {
    return qualifyingModule == RewardModule.all ||
        qualifyingModule == module;
  }

  bool qualifiesAfterBooking({
    required RewardModule module,
    required double completedAmount,
    required int newCompletedBookingCount,
  }) {
    if (!canBeQualified) {
      return false;
    }

    if (!supportsQualifyingModule(module)) {
      return false;
    }

    if (completedAmount < minimumQualifyingAmount) {
      return false;
    }

    return newCompletedBookingCount >= requiredCompletedBookings;
  }

  bool get allEnabledRewardsIssued {
    final inviterDone =
        inviterRewardType == ReferralRewardType.none ||
            inviterRewardIssued;

    final invitedUserDone =
        invitedUserRewardType == ReferralRewardType.none ||
            invitedUserRewardIssued;

    return inviterDone && invitedUserDone;
  }

  ReferralModel copyWith({
    String? id,
    String? referralCode,
    String? inviterUserId,
    String? invitedUserId,
    bool removeInvitedUserId = false,
    ReferralStatus? status,
    RewardModule? qualifyingModule,
    int? requiredCompletedBookings,
    double? minimumQualifyingAmount,
    ReferralRewardType? inviterRewardType,
    double? inviterRewardValue,
    String? inviterBenefitId,
    bool removeInviterBenefitId = false,
    ReferralRewardType? invitedUserRewardType,
    double? invitedUserRewardValue,
    String? invitedUserBenefitId,
    bool removeInvitedUserBenefitId = false,
    bool? inviterRewardIssued,
    bool? invitedUserRewardIssued,
    String? inviterRewardTransactionId,
    bool removeInviterRewardTransactionId = false,
    String? invitedUserRewardTransactionId,
    bool removeInvitedUserRewardTransactionId = false,
    int? completedQualifyingBookings,
    bool? phoneVerified,
    bool? identityVerified,
    bool? requiresManualReview,
    bool? isFraudSuspected,
    String? reviewReason,
    bool removeReviewReason = false,
    String? reviewedBy,
    bool removeReviewedBy = false,
    String? idempotencyKey,
    DateTime? createdAt,
    DateTime? registeredAt,
    bool removeRegisteredAt = false,
    DateTime? qualifiedAt,
    bool removeQualifiedAt = false,
    DateTime? rewardedAt,
    bool removeRewardedAt = false,
    DateTime? reviewedAt,
    bool removeReviewedAt = false,
    DateTime? expiryDate,
    bool removeExpiryDate = false,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ReferralModel(
      id: id ?? this.id,
      referralCode: referralCode ?? this.referralCode,
      inviterUserId: inviterUserId ?? this.inviterUserId,
      invitedUserId: removeInvitedUserId
          ? null
          : invitedUserId ?? this.invitedUserId,
      status: status ?? this.status,
      qualifyingModule:
          qualifyingModule ?? this.qualifyingModule,
      requiredCompletedBookings:
          requiredCompletedBookings ??
              this.requiredCompletedBookings,
      minimumQualifyingAmount:
          minimumQualifyingAmount ??
              this.minimumQualifyingAmount,
      inviterRewardType:
          inviterRewardType ?? this.inviterRewardType,
      inviterRewardValue:
          inviterRewardValue ?? this.inviterRewardValue,
      inviterBenefitId: removeInviterBenefitId
          ? null
          : inviterBenefitId ?? this.inviterBenefitId,
      invitedUserRewardType:
          invitedUserRewardType ??
              this.invitedUserRewardType,
      invitedUserRewardValue:
          invitedUserRewardValue ??
              this.invitedUserRewardValue,
      invitedUserBenefitId: removeInvitedUserBenefitId
          ? null
          : invitedUserBenefitId ??
              this.invitedUserBenefitId,
      inviterRewardIssued:
          inviterRewardIssued ?? this.inviterRewardIssued,
      invitedUserRewardIssued:
          invitedUserRewardIssued ??
              this.invitedUserRewardIssued,
      inviterRewardTransactionId:
          removeInviterRewardTransactionId
              ? null
              : inviterRewardTransactionId ??
                  this.inviterRewardTransactionId,
      invitedUserRewardTransactionId:
          removeInvitedUserRewardTransactionId
              ? null
              : invitedUserRewardTransactionId ??
                  this.invitedUserRewardTransactionId,
      completedQualifyingBookings:
          completedQualifyingBookings ??
              this.completedQualifyingBookings,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      identityVerified:
          identityVerified ?? this.identityVerified,
      requiresManualReview:
          requiresManualReview ?? this.requiresManualReview,
      isFraudSuspected:
          isFraudSuspected ?? this.isFraudSuspected,
      reviewReason: removeReviewReason
          ? null
          : reviewReason ?? this.reviewReason,
      reviewedBy: removeReviewedBy
          ? null
          : reviewedBy ?? this.reviewedBy,
      idempotencyKey:
          idempotencyKey ?? this.idempotencyKey,
      createdAt: createdAt ?? this.createdAt,
      registeredAt: removeRegisteredAt
          ? null
          : registeredAt ?? this.registeredAt,
      qualifiedAt: removeQualifiedAt
          ? null
          : qualifiedAt ?? this.qualifiedAt,
      rewardedAt: removeRewardedAt
          ? null
          : rewardedAt ?? this.rewardedAt,
      reviewedAt: removeReviewedAt
          ? null
          : reviewedAt ?? this.reviewedAt,
      expiryDate: removeExpiryDate
          ? null
          : expiryDate ?? this.expiryDate,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referralCode': normalizedReferralCode,
      'inviterUserId': inviterUserId,
      'invitedUserId': invitedUserId,
      'status': status.name,
      'qualifyingModule': qualifyingModule.name,
      'requiredCompletedBookings': requiredCompletedBookings,
      'minimumQualifyingAmount': minimumQualifyingAmount,
      'inviterRewardType': inviterRewardType.name,
      'inviterRewardValue': inviterRewardValue,
      'inviterBenefitId': inviterBenefitId,
      'invitedUserRewardType': invitedUserRewardType.name,
      'invitedUserRewardValue': invitedUserRewardValue,
      'invitedUserBenefitId': invitedUserBenefitId,
      'inviterRewardIssued': inviterRewardIssued,
      'invitedUserRewardIssued': invitedUserRewardIssued,
      'inviterRewardTransactionId':
          inviterRewardTransactionId,
      'invitedUserRewardTransactionId':
          invitedUserRewardTransactionId,
      'completedQualifyingBookings':
          completedQualifyingBookings,
      'phoneVerified': phoneVerified,
      'identityVerified': identityVerified,
      'requiresManualReview': requiresManualReview,
      'isFraudSuspected': isFraudSuspected,
      'reviewReason': reviewReason,
      'reviewedBy': reviewedBy,
      'idempotencyKey': idempotencyKey,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'registeredAt': registeredAt?.millisecondsSinceEpoch,
      'qualifiedAt': qualifiedAt?.millisecondsSinceEpoch,
      'rewardedAt': rewardedAt?.millisecondsSinceEpoch,
      'reviewedAt': reviewedAt?.millisecondsSinceEpoch,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  factory ReferralModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();

    return ReferralModel(
      id: map['id']?.toString() ?? '',
      referralCode: map['referralCode']?.toString() ?? '',
      inviterUserId:
          map['inviterUserId']?.toString() ?? '',
      invitedUserId: map['invitedUserId']?.toString(),
      status: _statusFromString(map['status']?.toString()),
      qualifyingModule: _moduleFromString(
        map['qualifyingModule']?.toString(),
      ),
      requiredCompletedBookings:
          (map['requiredCompletedBookings'] as num?)
                  ?.toInt() ??
              1,
      minimumQualifyingAmount:
          (map['minimumQualifyingAmount'] as num?)
                  ?.toDouble() ??
              0,
      inviterRewardType: _rewardTypeFromString(
        map['inviterRewardType']?.toString(),
      ),
      inviterRewardValue:
          (map['inviterRewardValue'] as num?)
                  ?.toDouble() ??
              0,
      inviterBenefitId:
          map['inviterBenefitId']?.toString(),
      invitedUserRewardType: _rewardTypeFromString(
        map['invitedUserRewardType']?.toString(),
      ),
      invitedUserRewardValue:
          (map['invitedUserRewardValue'] as num?)
                  ?.toDouble() ??
              0,
      invitedUserBenefitId:
          map['invitedUserBenefitId']?.toString(),
      inviterRewardIssued:
          map['inviterRewardIssued'] as bool? ?? false,
      invitedUserRewardIssued:
          map['invitedUserRewardIssued'] as bool? ?? false,
      inviterRewardTransactionId:
          map['inviterRewardTransactionId']?.toString(),
      invitedUserRewardTransactionId:
          map['invitedUserRewardTransactionId']?.toString(),
      completedQualifyingBookings:
          (map['completedQualifyingBookings'] as num?)
                  ?.toInt() ??
              0,
      phoneVerified:
          map['phoneVerified'] as bool? ?? false,
      identityVerified:
          map['identityVerified'] as bool? ?? false,
      requiresManualReview:
          map['requiresManualReview'] as bool? ?? false,
      isFraudSuspected:
          map['isFraudSuspected'] as bool? ?? false,
      reviewReason: map['reviewReason']?.toString(),
      reviewedBy: map['reviewedBy']?.toString(),
      idempotencyKey:
          map['idempotencyKey']?.toString() ?? '',
      createdAt: _dateFromValue(map['createdAt']) ?? now,
      registeredAt: _dateFromValue(map['registeredAt']),
      qualifiedAt: _dateFromValue(map['qualifiedAt']),
      rewardedAt: _dateFromValue(map['rewardedAt']),
      reviewedAt: _dateFromValue(map['reviewedAt']),
      expiryDate: _dateFromValue(map['expiryDate']),
      updatedAt: _dateFromValue(map['updatedAt']) ?? now,
      metadata: Map<String, dynamic>.from(
        map['metadata'] as Map? ?? const {},
      ),
    );
  }

  static ReferralStatus _statusFromString(String? value) {
    return ReferralStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ReferralStatus.pending,
    );
  }

  static ReferralRewardType _rewardTypeFromString(
    String? value,
  ) {
    return ReferralRewardType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ReferralRewardType.none,
    );
  }

  static RewardModule _moduleFromString(String? value) {
    return RewardModule.values.firstWhere(
      (module) => module.name == value,
      orElse: () => RewardModule.all,
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