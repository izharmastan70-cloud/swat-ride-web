// lib/food/models/food_order_dispute_model.dart

// ============================================================
// FOOD ORDER DISPUTE MODEL
// ============================================================
// Safe foundation for customer / restaurant / rider disputes.
//
// Notes:
// - This model does NOT process payments or refunds directly.
// - Refund approval/execution remains an Admin/service responsibility.
// - Existing FoodOrderStatus lifecycle remains unchanged.
// ============================================================

enum FoodOrderDisputeStatus {
  open,
  underReview,
  awaitingCustomer,
  awaitingRestaurant,
  awaitingRider,
  resolved,
  rejected,
  cancelled,
}

enum FoodOrderDisputeRaisedBy { customer, restaurant, rider, admin, system }

enum FoodOrderDisputeReason {
  wrongOrder,
  missingItem,
  damagedItem,
  foodQualityIssue,
  deliveryIssue,
  paymentIssue,
  refundIssue,
  restaurantIssue,
  riderIssue,
  customerIssue,
  duplicateCharge,
  orderNotReceived,
  other,
}

extension FoodOrderDisputeStatusX on FoodOrderDisputeStatus {
  String get value => name;

  String get label {
    switch (this) {
      case FoodOrderDisputeStatus.open:
        return 'Open';
      case FoodOrderDisputeStatus.underReview:
        return 'Under Review';
      case FoodOrderDisputeStatus.awaitingCustomer:
        return 'Awaiting Customer';
      case FoodOrderDisputeStatus.awaitingRestaurant:
        return 'Awaiting Restaurant';
      case FoodOrderDisputeStatus.awaitingRider:
        return 'Awaiting Rider';
      case FoodOrderDisputeStatus.resolved:
        return 'Resolved';
      case FoodOrderDisputeStatus.rejected:
        return 'Rejected';
      case FoodOrderDisputeStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isClosed =>
      this == FoodOrderDisputeStatus.resolved ||
      this == FoodOrderDisputeStatus.rejected ||
      this == FoodOrderDisputeStatus.cancelled;

  static FoodOrderDisputeStatus fromValue(dynamic value) {
    final String normalized = value?.toString().trim().toLowerCase() ?? '';

    for (final FoodOrderDisputeStatus status in FoodOrderDisputeStatus.values) {
      if (status.name.toLowerCase() == normalized) {
        return status;
      }
    }

    return FoodOrderDisputeStatus.open;
  }
}

extension FoodOrderDisputeRaisedByX on FoodOrderDisputeRaisedBy {
  String get value => name;

  String get label {
    switch (this) {
      case FoodOrderDisputeRaisedBy.customer:
        return 'Customer';
      case FoodOrderDisputeRaisedBy.restaurant:
        return 'Restaurant';
      case FoodOrderDisputeRaisedBy.rider:
        return 'Delivery Rider';
      case FoodOrderDisputeRaisedBy.admin:
        return 'Admin';
      case FoodOrderDisputeRaisedBy.system:
        return 'System';
    }
  }

  static FoodOrderDisputeRaisedBy fromValue(dynamic value) {
    final String normalized = value?.toString().trim().toLowerCase() ?? '';

    for (final FoodOrderDisputeRaisedBy actor
        in FoodOrderDisputeRaisedBy.values) {
      if (actor.name.toLowerCase() == normalized) {
        return actor;
      }
    }

    return FoodOrderDisputeRaisedBy.system;
  }
}

extension FoodOrderDisputeReasonX on FoodOrderDisputeReason {
  String get value => name;

  String get label {
    switch (this) {
      case FoodOrderDisputeReason.wrongOrder:
        return 'Wrong order';
      case FoodOrderDisputeReason.missingItem:
        return 'Missing item';
      case FoodOrderDisputeReason.damagedItem:
        return 'Damaged item';
      case FoodOrderDisputeReason.foodQualityIssue:
        return 'Food quality issue';
      case FoodOrderDisputeReason.deliveryIssue:
        return 'Delivery issue';
      case FoodOrderDisputeReason.paymentIssue:
        return 'Payment issue';
      case FoodOrderDisputeReason.refundIssue:
        return 'Refund issue';
      case FoodOrderDisputeReason.restaurantIssue:
        return 'Restaurant issue';
      case FoodOrderDisputeReason.riderIssue:
        return 'Rider issue';
      case FoodOrderDisputeReason.customerIssue:
        return 'Customer issue';
      case FoodOrderDisputeReason.duplicateCharge:
        return 'Duplicate charge';
      case FoodOrderDisputeReason.orderNotReceived:
        return 'Order not received';
      case FoodOrderDisputeReason.other:
        return 'Other';
    }
  }

  static FoodOrderDisputeReason fromValue(dynamic value) {
    final String normalized = value?.toString().trim().toLowerCase() ?? '';

    for (final FoodOrderDisputeReason reason in FoodOrderDisputeReason.values) {
      if (reason.name.toLowerCase() == normalized) {
        return reason;
      }
    }

    return FoodOrderDisputeReason.other;
  }
}

class FoodOrderDisputeModel {
  final String disputeId;
  final String orderId;

  final String customerId;
  final String restaurantId;
  final String riderId;

  final FoodOrderDisputeRaisedBy raisedBy;
  final String raisedById;

  final FoodOrderDisputeReason reason;
  final String description;

  final FoodOrderDisputeStatus status;

  final bool refundRequested;
  final double requestedRefundAmount;

  final bool refundApproved;
  final double approvedRefundAmount;

  final String resolutionNote;
  final String resolvedBy;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  const FoodOrderDisputeModel({
    required this.disputeId,
    required this.orderId,
    required this.customerId,
    required this.restaurantId,
    required this.riderId,
    required this.raisedBy,
    required this.raisedById,
    required this.reason,
    required this.description,
    required this.status,
    required this.refundRequested,
    required this.requestedRefundAmount,
    required this.refundApproved,
    required this.approvedRefundAmount,
    required this.resolutionNote,
    required this.resolvedBy,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  bool get isOpen => !status.isClosed;

  bool get isResolved => status == FoodOrderDisputeStatus.resolved;

  bool get hasApprovedRefund => refundApproved && approvedRefundAmount > 0;

  FoodOrderDisputeModel copyWith({
    String? disputeId,
    String? orderId,
    String? customerId,
    String? restaurantId,
    String? riderId,
    FoodOrderDisputeRaisedBy? raisedBy,
    String? raisedById,
    FoodOrderDisputeReason? reason,
    String? description,
    FoodOrderDisputeStatus? status,
    bool? refundRequested,
    double? requestedRefundAmount,
    bool? refundApproved,
    double? approvedRefundAmount,
    String? resolutionNote,
    String? resolvedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    bool clearResolvedAt = false,
  }) {
    return FoodOrderDisputeModel(
      disputeId: disputeId ?? this.disputeId,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      restaurantId: restaurantId ?? this.restaurantId,
      riderId: riderId ?? this.riderId,
      raisedBy: raisedBy ?? this.raisedBy,
      raisedById: raisedById ?? this.raisedById,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      refundRequested: refundRequested ?? this.refundRequested,
      requestedRefundAmount:
          requestedRefundAmount ?? this.requestedRefundAmount,
      refundApproved: refundApproved ?? this.refundApproved,
      approvedRefundAmount: approvedRefundAmount ?? this.approvedRefundAmount,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: clearResolvedAt ? null : resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'disputeId': disputeId,
      'orderId': orderId,
      'customerId': customerId,
      'restaurantId': restaurantId,
      'riderId': riderId,
      'raisedBy': raisedBy.value,
      'raisedById': raisedById,
      'reason': reason.value,
      'description': description,
      'status': status.value,
      'refundRequested': refundRequested,
      'requestedRefundAmount': requestedRefundAmount,
      'refundApproved': refundApproved,
      'approvedRefundAmount': approvedRefundAmount,
      'resolutionNote': resolutionNote,
      'resolvedBy': resolvedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  factory FoodOrderDisputeModel.fromMap(Map<String, dynamic> map) {
    return FoodOrderDisputeModel(
      disputeId: _stringValue(map['disputeId']),
      orderId: _stringValue(map['orderId']),
      customerId: _stringValue(map['customerId']),
      restaurantId: _stringValue(map['restaurantId']),
      riderId: _stringValue(map['riderId']),
      raisedBy: FoodOrderDisputeRaisedByX.fromValue(map['raisedBy']),
      raisedById: _stringValue(map['raisedById']),
      reason: FoodOrderDisputeReasonX.fromValue(map['reason']),
      description: _stringValue(map['description']),
      status: FoodOrderDisputeStatusX.fromValue(map['status']),
      refundRequested: _boolValue(map['refundRequested']),
      requestedRefundAmount: _doubleValue(map['requestedRefundAmount']),
      refundApproved: _boolValue(map['refundApproved']),
      approvedRefundAmount: _doubleValue(map['approvedRefundAmount']),
      resolutionNote: _stringValue(map['resolutionNote']),
      resolvedBy: _stringValue(map['resolvedBy']),
      createdAt: _dateTimeValue(map['createdAt']) ?? DateTime.now(),
      updatedAt: _dateTimeValue(map['updatedAt']) ?? DateTime.now(),
      resolvedAt: _dateTimeValue(map['resolvedAt']),
    );
  }

  static String _stringValue(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static bool _boolValue(dynamic value) {
    if (value is bool) {
      return value;
    }

    return value?.toString().toLowerCase() == 'true';
  }

  static double _doubleValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _dateTimeValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    try {
      final dynamic converted = value.toDate();
      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Ignore unsupported timestamp values.
    }

    return null;
  }
}
