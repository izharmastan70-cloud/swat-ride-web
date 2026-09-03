// lib/food/models/food_cancellation_model.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Food Order Cancellation Model
//
// Customer policy:
// - Customer can cancel only within 5 minutes of order creation.
// - A cancellation reason is required.
// - Restaurant/Admin cancellation can follow separate permissions.
// =============================================================

enum FoodCancellationActor {
  customer,
  restaurant,
  rider,
  admin,
  system,
}

enum FoodCancellationReason {
  orderedByMistake,
  wrongDeliveryAddress,
  wrongItemsSelected,
  deliveryTimeTooLong,
  paymentIssue,
  restaurantRejected,
  itemUnavailable,
  riderUnavailable,
  duplicateOrder,
  other,
}

extension FoodCancellationReasonX
    on FoodCancellationReason {
  String get value {
    switch (this) {
      case FoodCancellationReason.orderedByMistake:
        return 'ordered_by_mistake';
      case FoodCancellationReason.wrongDeliveryAddress:
        return 'wrong_delivery_address';
      case FoodCancellationReason.wrongItemsSelected:
        return 'wrong_items_selected';
      case FoodCancellationReason.deliveryTimeTooLong:
        return 'delivery_time_too_long';
      case FoodCancellationReason.paymentIssue:
        return 'payment_issue';
      case FoodCancellationReason.restaurantRejected:
        return 'restaurant_rejected';
      case FoodCancellationReason.itemUnavailable:
        return 'item_unavailable';
      case FoodCancellationReason.riderUnavailable:
        return 'rider_unavailable';
      case FoodCancellationReason.duplicateOrder:
        return 'duplicate_order';
      case FoodCancellationReason.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case FoodCancellationReason.orderedByMistake:
        return 'Ordered by mistake';
      case FoodCancellationReason.wrongDeliveryAddress:
        return 'Wrong delivery address';
      case FoodCancellationReason.wrongItemsSelected:
        return 'Selected wrong items';
      case FoodCancellationReason.deliveryTimeTooLong:
        return 'Delivery time is too long';
      case FoodCancellationReason.paymentIssue:
        return 'Payment issue';
      case FoodCancellationReason.restaurantRejected:
        return 'Restaurant rejected the order';
      case FoodCancellationReason.itemUnavailable:
        return 'Item is unavailable';
      case FoodCancellationReason.riderUnavailable:
        return 'Delivery rider is unavailable';
      case FoodCancellationReason.duplicateOrder:
        return 'Duplicate order';
      case FoodCancellationReason.other:
        return 'Other reason';
    }
  }

  static FoodCancellationReason fromValue(
    dynamic value,
  ) {
    final String normalized =
        value?.toString().trim().toLowerCase() ?? '';

    for (final FoodCancellationReason reason
        in FoodCancellationReason.values) {
      if (reason.value == normalized ||
          reason.name.toLowerCase() == normalized) {
        return reason;
      }
    }

    return FoodCancellationReason.other;
  }
}

class FoodCancellationModel {
  static const Duration customerCancellationWindow =
      Duration(minutes: 5);

  final String id;
  final String orderId;
  final String userId;

  final FoodCancellationActor cancelledBy;
  final FoodCancellationReason reason;
  final String customReason;

  final DateTime orderCreatedAt;
  final DateTime cancellationDeadline;
  final DateTime cancelledAt;

  final bool wasWithinCustomerWindow;
  final bool refundRequired;
  final double refundAmount;

  final String status;
  final String adminNote;

  const FoodCancellationModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.cancelledBy,
    required this.reason,
    required this.customReason,
    required this.orderCreatedAt,
    required this.cancellationDeadline,
    required this.cancelledAt,
    required this.wasWithinCustomerWindow,
    required this.refundRequired,
    required this.refundAmount,
    required this.status,
    required this.adminNote,
  });

  factory FoodCancellationModel.customer({
    required String id,
    required String orderId,
    required String userId,
    required FoodCancellationReason reason,
    required DateTime orderCreatedAt,
    String customReason = '',
    bool refundRequired = false,
    double refundAmount = 0,
  }) {
    final DateTime cancelledAt = DateTime.now();
    final DateTime deadline = orderCreatedAt.add(
      customerCancellationWindow,
    );

    return FoodCancellationModel(
      id: id,
      orderId: orderId,
      userId: userId,
      cancelledBy: FoodCancellationActor.customer,
      reason: reason,
      customReason: customReason.trim(),
      orderCreatedAt: orderCreatedAt,
      cancellationDeadline: deadline,
      cancelledAt: cancelledAt,
      wasWithinCustomerWindow:
          !cancelledAt.isAfter(deadline),
      refundRequired: refundRequired,
      refundAmount: refundAmount < 0 ? 0 : refundAmount,
      status: 'completed',
      adminNote: '',
    );
  }

  bool get isOtherReason =>
      reason == FoodCancellationReason.other;

  bool get hasValidReason {
    if (!isOtherReason) {
      return true;
    }

    return customReason.trim().isNotEmpty;
  }

  String get reasonText {
    if (isOtherReason &&
        customReason.trim().isNotEmpty) {
      return customReason.trim();
    }

    return reason.displayName;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'cancelledBy': cancelledBy.name,
      'reason': reason.value,
      'customReason': customReason,
      'reasonText': reasonText,
      'orderCreatedAt':
          orderCreatedAt.toIso8601String(),
      'cancellationDeadline':
          cancellationDeadline.toIso8601String(),
      'cancelledAt': cancelledAt.toIso8601String(),
      'wasWithinCustomerWindow':
          wasWithinCustomerWindow,
      'refundRequired': refundRequired,
      'refundAmount': refundAmount,
      'status': status,
      'adminNote': adminNote,
    };
  }

  factory FoodCancellationModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final DateTime orderCreatedAt =
        _dateTimeValue(map['orderCreatedAt']) ??
            DateTime.now();

    return FoodCancellationModel(
      id: _stringValue(map['id']),
      orderId: _stringValue(map['orderId']),
      userId: _stringValue(map['userId']),
      cancelledBy:
          _actorFromValue(map['cancelledBy']),
      reason:
          FoodCancellationReasonX.fromValue(
        map['reason'],
      ),
      customReason:
          _stringValue(map['customReason']),
      orderCreatedAt: orderCreatedAt,
      cancellationDeadline:
          _dateTimeValue(
            map['cancellationDeadline'],
          ) ??
          orderCreatedAt.add(
            customerCancellationWindow,
          ),
      cancelledAt:
          _dateTimeValue(map['cancelledAt']) ??
              DateTime.now(),
      wasWithinCustomerWindow:
          _boolValue(
        map['wasWithinCustomerWindow'],
      ),
      refundRequired:
          _boolValue(map['refundRequired']),
      refundAmount:
          _doubleValue(map['refundAmount']),
      status: _stringValue(
        map['status'],
        fallback: 'completed',
      ),
      adminNote:
          _stringValue(map['adminNote']),
    );
  }

  static bool canCustomerCancel({
    required DateTime orderCreatedAt,
    DateTime? now,
  }) {
    final DateTime current = now ?? DateTime.now();

    return !current.isAfter(
      orderCreatedAt.add(
        customerCancellationWindow,
      ),
    );
  }

  static Duration remainingCustomerTime({
    required DateTime orderCreatedAt,
    DateTime? now,
  }) {
    final DateTime current = now ?? DateTime.now();
    final DateTime deadline = orderCreatedAt.add(
      customerCancellationWindow,
    );

    if (current.isAfter(deadline)) {
      return Duration.zero;
    }

    return deadline.difference(current);
  }

  static String customerNotificationText({
    required DateTime orderCreatedAt,
    DateTime? now,
  }) {
    final Duration remaining =
        remainingCustomerTime(
      orderCreatedAt: orderCreatedAt,
      now: now,
    );

    if (remaining == Duration.zero) {
      return 'The 5-minute customer cancellation window has ended.';
    }

    final int minutes =
        remaining.inMinutes;
    final int seconds =
        remaining.inSeconds % 60;

    return 'You can cancel this order within '
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.';
  }

  static FoodCancellationActor _actorFromValue(
    dynamic value,
  ) {
    final String normalized =
        value?.toString().trim().toLowerCase() ?? '';

    for (final FoodCancellationActor actor
        in FoodCancellationActor.values) {
      if (actor.name.toLowerCase() == normalized) {
        return actor;
      }
    }

    return FoodCancellationActor.system;
  }

  static String _stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    final String parsed =
        value?.toString().trim() ?? '';

    return parsed.isEmpty ? fallback : parsed;
  }

  static bool _boolValue(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String parsed =
        value?.toString().trim().toLowerCase() ?? '';

    return parsed == 'true' ||
        parsed == '1' ||
        parsed == 'yes';
  }

  static double _doubleValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static DateTime? _dateTimeValue(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    try {
      final dynamic converted = value.toDate();

      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Firestore Timestamp support without direct import.
    }

    return DateTime.tryParse(value.toString());
  }
}
