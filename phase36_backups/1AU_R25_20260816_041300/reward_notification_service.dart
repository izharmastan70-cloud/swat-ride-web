// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/services/reward_notification_service.dart
//
// Notification model and service intentionally live in this ONE file.
// Real Firestore inbox + trusted backend push queue + testing bypass.
// =============================================================

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reward_point_model.dart';
import '../models/reward_settings_model.dart';

enum RewardNotificationType {
  pointsEarned,
  pointsRedeemed,
  pointsExpiring,
  pointsExpired,
  pointsReversed,
  cashbackEarned,
  cashbackAvailable,
  referralRegistered,
  referralQualified,
  referralRewarded,
  loyaltyUpgraded,
  loyaltyDowngraded,
  loyaltyMilestone,
  couponAvailable,
  voucherAvailable,
  promoAvailable,
  adminMessage,
}

enum RewardNotificationPriority { low, normal, high, urgent }

enum RewardNotificationDeliveryStatus {
  pending,
  queued,
  delivered,
  failed,
  cancelled,
}

class RewardNotificationModel {
  final String id;
  final String userId;
  final RewardNotificationType type;
  final RewardNotificationPriority priority;
  final RewardNotificationDeliveryStatus deliveryStatus;
  final RewardModule module;
  final String title;
  final String message;
  final String? sourceId;
  final String? actionLabel;
  final String? actionRoute;
  final bool inAppEnabled;
  final bool pushEnabled;
  final bool isRead;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? expiresAt;
  final String? idempotencyKey;
  final String? failureReason;
  final Map<String, dynamic> metadata;

  const RewardNotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    this.priority = RewardNotificationPriority.normal,
    this.deliveryStatus = RewardNotificationDeliveryStatus.pending,
    this.module = RewardModule.all,
    required this.title,
    required this.message,
    this.sourceId,
    this.actionLabel,
    this.actionRoute,
    this.inAppEnabled = true,
    this.pushEnabled = true,
    this.isRead = false,
    this.isArchived = false,
    required this.createdAt,
    this.scheduledAt,
    this.deliveredAt,
    this.readAt,
    this.expiresAt,
    this.idempotencyKey,
    this.failureReason,
    this.metadata = const {},
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  RewardNotificationModel copyWith({
    RewardNotificationDeliveryStatus? deliveryStatus,
    bool? isRead,
    bool? isArchived,
    DateTime? deliveredAt,
    DateTime? readAt,
    String? failureReason,
    bool removeFailureReason = false,
  }) {
    return RewardNotificationModel(
      id: id,
      userId: userId,
      type: type,
      priority: priority,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      module: module,
      title: title,
      message: message,
      sourceId: sourceId,
      actionLabel: actionLabel,
      actionRoute: actionRoute,
      inAppEnabled: inAppEnabled,
      pushEnabled: pushEnabled,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      scheduledAt: scheduledAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt,
      idempotencyKey: idempotencyKey,
      failureReason:
          removeFailureReason ? null : failureReason ?? this.failureReason,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type.name,
        'priority': priority.name,
        'deliveryStatus': deliveryStatus.name,
        'module': module.name,
        'title': title,
        'message': message,
        'sourceId': sourceId,
        'actionLabel': actionLabel,
        'actionRoute': actionRoute,
        'inAppEnabled': inAppEnabled,
        'pushEnabled': pushEnabled,
        'isRead': isRead,
        'isArchived': isArchived,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'scheduledAt': scheduledAt?.millisecondsSinceEpoch,
        'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
        'readAt': readAt?.millisecondsSinceEpoch,
        'expiresAt': expiresAt?.millisecondsSinceEpoch,
        'idempotencyKey': idempotencyKey,
        'failureReason': failureReason,
        'metadata': metadata,
      };

  factory RewardNotificationModel.fromMap(Map<String, dynamic> map) {
    return RewardNotificationModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      type: RewardNotificationType.values.firstWhere(
        (value) => value.name == map['type']?.toString(),
        orElse: () => RewardNotificationType.adminMessage,
      ),
      priority: RewardNotificationPriority.values.firstWhere(
        (value) => value.name == map['priority']?.toString(),
        orElse: () => RewardNotificationPriority.normal,
      ),
      deliveryStatus: RewardNotificationDeliveryStatus.values.firstWhere(
        (value) => value.name == map['deliveryStatus']?.toString(),
        orElse: () => RewardNotificationDeliveryStatus.pending,
      ),
      module: RewardModule.values.firstWhere(
        (value) => value.name == map['module']?.toString(),
        orElse: () => RewardModule.all,
      ),
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      sourceId: map['sourceId']?.toString(),
      actionLabel: map['actionLabel']?.toString(),
      actionRoute: map['actionRoute']?.toString(),
      inAppEnabled: map['inAppEnabled'] as bool? ?? true,
      pushEnabled: map['pushEnabled'] as bool? ?? true,
      isRead: map['isRead'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      scheduledAt: _date(map['scheduledAt']),
      deliveredAt: _date(map['deliveredAt']),
      readAt: _date(map['readAt']),
      expiresAt: _date(map['expiresAt']),
      idempotencyKey: map['idempotencyKey']?.toString(),
      failureReason: map['failureReason']?.toString(),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? const {}),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return DateTime.tryParse(value.toString());
  }
}

class RewardNotificationService {
  final FirebaseFirestore _firestore;
  final bool useTestingBypass;
  final Map<String, RewardNotificationModel> _testingNotifications = {};
  final Map<String, bool> _testingTypeSettings = {
    for (final type in RewardNotificationType.values) type.name: true,
  };

  RewardNotificationService({
    FirebaseFirestore? firestore,
    this.useTestingBypass = true,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('reward_notifications');

  CollectionReference<Map<String, dynamic>> get _deliveryQueue =>
      _firestore.collection('reward_notification_delivery_queue');

  DocumentReference<Map<String, dynamic>> get _typeSettings => _firestore
      .collection('reward_notification_settings')
      .doc('global');

  DocumentReference<Map<String, dynamic>> get _rewardSettings =>
      _firestore.collection('reward_settings').doc('global_rewards');

  Future<void> setNotificationTypeEnabled({
    required RewardNotificationType type,
    required bool enabled,
    required String updatedBy,
  }) async {
    if (useTestingBypass) {
      _testingTypeSettings[type.name] = enabled;
      return;
    }
    await _typeSettings.set({
      'enabledTypes.${type.name}': enabled,
      'updatedBy': updatedBy,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<bool> isNotificationTypeEnabled(
    RewardNotificationType type,
  ) async {
    if (useTestingBypass) return _testingTypeSettings[type.name] ?? true;
    final snapshot = await _typeSettings.get();
    final types = snapshot.data()?['enabledTypes'];
    return types is Map ? types[type.name] as bool? ?? true : true;
  }

  Future<bool> _allowedByGlobalSettings(
    RewardNotificationType type,
  ) async {
    if (useTestingBypass) return true;
    final snapshot = await _rewardSettings.get();
    if (!snapshot.exists || snapshot.data() == null) return true;
    final settings = RewardSettingsModel.fromMap(snapshot.data()!);
    switch (type) {
      case RewardNotificationType.pointsExpiring:
      case RewardNotificationType.pointsExpired:
        return settings.expiryNotificationsEnabled;
      case RewardNotificationType.loyaltyUpgraded:
      case RewardNotificationType.loyaltyDowngraded:
      case RewardNotificationType.loyaltyMilestone:
        return settings.loyaltyUpgradeNotificationsEnabled;
      default:
        return settings.rewardNotificationsEnabled;
    }
  }

  Future<RewardNotificationModel?> createNotification({
    required String userId,
    required RewardNotificationType type,
    required String title,
    required String message,
    RewardModule module = RewardModule.all,
    RewardNotificationPriority priority = RewardNotificationPriority.normal,
    String? sourceId,
    String? actionLabel,
    String? actionRoute,
    bool inAppEnabled = true,
    bool pushEnabled = true,
    DateTime? scheduledAt,
    DateTime? expiresAt,
    String? idempotencyKey,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (userId.trim().isEmpty || title.trim().isEmpty || message.trim().isEmpty) {
      throw ArgumentError('User, title and message are required.');
    }
    if (!await isNotificationTypeEnabled(type) ||
        !await _allowedByGlobalSettings(type)) {
      return null;
    }
    final now = DateTime.now();
    final key = idempotencyKey ??
        '$userId:${type.name}:${sourceId ?? now.microsecondsSinceEpoch}';
    final existing = await getByIdempotencyKey(key);
    if (existing != null) return existing;
    final id = 'reward_notification_${_stableHash(key)}';
    final model = RewardNotificationModel(
      id: id,
      userId: userId,
      type: type,
      priority: priority,
      deliveryStatus: pushEnabled
          ? RewardNotificationDeliveryStatus.queued
          : RewardNotificationDeliveryStatus.pending,
      module: module,
      title: title.trim(),
      message: message.trim(),
      sourceId: sourceId,
      actionLabel: actionLabel,
      actionRoute: actionRoute,
      inAppEnabled: inAppEnabled,
      pushEnabled: pushEnabled,
      createdAt: now,
      scheduledAt: scheduledAt,
      expiresAt: expiresAt,
      idempotencyKey: key,
      metadata: metadata,
    );
    if (useTestingBypass) {
      _testingNotifications[id] = model;
      return model;
    }
    final notificationRef = _notifications.doc(id);
    final queueRef = _deliveryQueue.doc(id);
    await _firestore.runTransaction((transaction) async {
      final old = await transaction.get(notificationRef);
      if (old.exists) return;
      transaction.set(notificationRef, model.toMap());
      if (pushEnabled) {
        transaction.set(queueRef, {
          'id': id,
          'notificationId': id,
          'userId': userId,
          'title': title.trim(),
          'message': message.trim(),
          'type': type.name,
          'module': module.name,
          'actionRoute': actionRoute,
          'priority': priority.name,
          'status': scheduledAt != null && scheduledAt.isAfter(now)
              ? 'scheduled'
              : 'queued',
          'scheduledAt': scheduledAt?.millisecondsSinceEpoch,
          'createdAt': now.millisecondsSinceEpoch,
          'attemptCount': 0,
          'metadata': metadata,
        });
      }
    });
    return model;
  }

  Future<RewardNotificationModel?> notifyPointsEarned({
    required String userId,
    required int points,
    required RewardModule module,
    required String sourceId,
  }) =>
      createNotification(
        userId: userId,
        type: RewardNotificationType.pointsEarned,
        title: 'Reward points earned',
        message: 'You earned $points reward points.',
        module: module,
        sourceId: sourceId,
        actionLabel: 'View rewards',
        actionRoute: '/rewards/wallet',
        idempotencyKey: 'points-earned:$userId:$sourceId',
        metadata: {'points': points},
      );

  Future<RewardNotificationModel?> notifyPointsRedeemed({
    required String userId,
    required int points,
    required RewardModule module,
    required String sourceId,
  }) =>
      createNotification(
        userId: userId,
        type: RewardNotificationType.pointsRedeemed,
        title: 'Reward points redeemed',
        message: '$points reward points were redeemed.',
        module: module,
        sourceId: sourceId,
        actionRoute: '/rewards/history',
        idempotencyKey: 'points-redeemed:$userId:$sourceId',
        metadata: {'points': points},
      );

  Future<RewardNotificationModel?> notifyPointsExpiring({
    required String userId,
    required int points,
    required DateTime expiryDate,
    required String sourceId,
  }) =>
      createNotification(
        userId: userId,
        type: RewardNotificationType.pointsExpiring,
        title: 'Reward points expiring soon',
        message: '$points reward points will expire soon.',
        priority: RewardNotificationPriority.high,
        sourceId: sourceId,
        actionRoute: '/rewards/redeem',
        expiresAt: expiryDate,
        idempotencyKey:
            'points-expiring:$userId:$sourceId:${expiryDate.millisecondsSinceEpoch}',
        metadata: {
          'points': points,
          'expiryDate': expiryDate.millisecondsSinceEpoch,
        },
      );

  Future<RewardNotificationModel?> notifyPointsExpired({
    required String userId,
    required int points,
    required String expiryTransactionId,
  }) =>
      createNotification(
        userId: userId,
        type: RewardNotificationType.pointsExpired,
        title: 'Reward points expired',
        message: '$points reward points have expired.',
        priority: RewardNotificationPriority.high,
        sourceId: expiryTransactionId,
        actionRoute: '/rewards/history',
        idempotencyKey: 'points-expired:$userId:$expiryTransactionId',
        metadata: {'points': points},
      );

  Future<RewardNotificationModel?> notifyCashbackEarned({
    required String userId,
    required double cashbackAmount,
    required RewardModule module,
    required String sourceId,
  }) =>
      createNotification(
        userId: userId,
        type: RewardNotificationType.cashbackEarned,
        title: 'Cashback earned',
        message:
            'You earned PKR ${cashbackAmount.toStringAsFixed(2)} cashback.',
        module: module,
        sourceId: sourceId,
        actionRoute: '/rewards/cashback',
        idempotencyKey: 'cashback-earned:$userId:$sourceId',
        metadata: {'cashbackAmount': cashbackAmount},
      );

  Future<RewardNotificationModel?> notifyReferralQualified({
    required String userId,
    required String referralId,
  }) =>
      createNotification(
        userId: userId,
        type: RewardNotificationType.referralQualified,
        title: 'Referral qualified',
        message: 'Your referral has qualified for a reward.',
        sourceId: referralId,
        actionRoute: '/rewards/referral',
        idempotencyKey: 'referral-qualified:$userId:$referralId',
      );

  Future<RewardNotificationModel?> notifyLoyaltyUpgrade({
    required String userId,
    required String previousLevelName,
    required String newLevelName,
  }) =>
      createNotification(
        userId: userId,
        type: RewardNotificationType.loyaltyUpgraded,
        title: 'Loyalty level upgraded',
        message:
            'Congratulations! You moved from $previousLevelName to $newLevelName.',
        priority: RewardNotificationPriority.high,
        actionRoute: '/rewards/levels',
        idempotencyKey: 'loyalty-upgrade:$userId:$newLevelName',
        metadata: {
          'previousLevelName': previousLevelName,
          'newLevelName': newLevelName,
        },
      );

  Future<RewardNotificationModel?> getByIdempotencyKey(String key) async {
    if (useTestingBypass) {
      for (final item in _testingNotifications.values) {
        if (item.idempotencyKey == key) return item;
      }
      return null;
    }
    final query = await _notifications
        .where('idempotencyKey', isEqualTo: key)
        .limit(1)
        .get();
    return query.docs.isEmpty
        ? null
        : RewardNotificationModel.fromMap(query.docs.first.data());
  }

  Future<List<RewardNotificationModel>> getUserNotifications({
    required String userId,
    bool unreadOnly = false,
    bool includeArchived = false,
    int? limit,
  }) async {
    List<RewardNotificationModel> items;
    if (useTestingBypass) {
      items = _testingNotifications.values
          .where((item) => item.userId == userId)
          .toList();
    } else {
      final query =
          await _notifications.where('userId', isEqualTo: userId).get();
      items = query.docs
          .map((doc) => RewardNotificationModel.fromMap(doc.data()))
          .toList();
    }
    items = items.where((item) {
      if (!item.inAppEnabled || item.isExpired) return false;
      if (!includeArchived && item.isArchived) return false;
      if (unreadOnly && item.isRead) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (limit != null && limit > 0 && items.length > limit) {
      return items.take(limit).toList();
    }
    return items;
  }

  Stream<List<RewardNotificationModel>> watchUserNotifications(
    String userId,
  ) {
    if (useTestingBypass) {
      return Stream.fromFuture(getUserNotifications(userId: userId));
    }
    return _notifications
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((query) {
      final items = query.docs
          .map((doc) => RewardNotificationModel.fromMap(doc.data()))
          .where((item) =>
              item.inAppEnabled && !item.isArchived && !item.isExpired)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  Future<int> getUnreadCount(String userId) async =>
      (await getUserNotifications(userId: userId, unreadOnly: true)).length;

  Future<void> markAsRead(String notificationId) async {
    final now = DateTime.now();
    if (useTestingBypass) {
      final old = _testingNotifications[notificationId];
      if (old != null && !old.isRead) {
        _testingNotifications[notificationId] =
            old.copyWith(isRead: true, readAt: now);
      }
      return;
    }
    await _notifications.doc(notificationId).update({
      'isRead': true,
      'readAt': now.millisecondsSinceEpoch,
    });
  }

  Future<void> markAllAsRead(String userId) async {
    if (useTestingBypass) {
      final now = DateTime.now();
      for (final entry in _testingNotifications.entries.toList()) {
        if (entry.value.userId == userId && !entry.value.isRead) {
          _testingNotifications[entry.key] =
              entry.value.copyWith(isRead: true, readAt: now);
        }
      }
      return;
    }
    final query = await _notifications
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final doc in query.docs) {
      batch.update(doc.reference, {'isRead': true, 'readAt': now});
    }
    await batch.commit();
  }

  Future<void> archiveNotification(String notificationId) async {
    if (useTestingBypass) {
      final old = _testingNotifications[notificationId];
      if (old != null) {
        _testingNotifications[notificationId] =
            old.copyWith(isArchived: true);
      }
      return;
    }
    await _notifications.doc(notificationId).update({
      'isArchived': true,
      'archivedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> markDelivered(String notificationId) async {
    final now = DateTime.now();
    if (useTestingBypass) {
      final old = _testingNotifications[notificationId];
      if (old != null) {
        _testingNotifications[notificationId] = old.copyWith(
          deliveryStatus: RewardNotificationDeliveryStatus.delivered,
          deliveredAt: now,
          removeFailureReason: true,
        );
      }
      return;
    }
    await _notifications.doc(notificationId).update({
      'deliveryStatus': RewardNotificationDeliveryStatus.delivered.name,
      'deliveredAt': now.millisecondsSinceEpoch,
      'failureReason': null,
    });
    await _deliveryQueue.doc(notificationId).set({
      'status': 'delivered',
      'deliveredAt': now.millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<void> markDeliveryFailed({
    required String notificationId,
    required String reason,
  }) async {
    if (useTestingBypass) {
      final old = _testingNotifications[notificationId];
      if (old != null) {
        _testingNotifications[notificationId] = old.copyWith(
          deliveryStatus: RewardNotificationDeliveryStatus.failed,
          failureReason: reason,
        );
      }
      return;
    }
    await _notifications.doc(notificationId).update({
      'deliveryStatus': RewardNotificationDeliveryStatus.failed.name,
      'failureReason': reason,
    });
    await _deliveryQueue.doc(notificationId).set({
      'status': 'failed',
      'failureReason': reason,
      'failedAt': DateTime.now().millisecondsSinceEpoch,
      'attemptCount': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  int _stableHash(String value) {
    var hash = 2166136261;
    for (final unit in utf8.encode(value)) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash;
  }

  void addTestingNotification(RewardNotificationModel notification) {
    _testingNotifications[notification.id] = notification;
  }

  void clearTestingData() {
    _testingNotifications.clear();
    _testingTypeSettings
      ..clear()
      ..addAll({
        for (final type in RewardNotificationType.values) type.name: true,
      });
  }
}
