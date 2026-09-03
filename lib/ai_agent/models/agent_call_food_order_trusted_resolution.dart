import 'agent_call_food_order_status_contract.dart';

class AgentCallFoodOrderTrustedResolutionStatus {
  AgentCallFoodOrderTrustedResolutionStatus._();

  static const String authorizedFoodOrder = 'AUTHORIZED_FOOD_ORDER';
  static const String foodOrderUnavailable = 'FOOD_ORDER_UNAVAILABLE';
  static const String foodOrderResolutionBlocked =
      'FOOD_ORDER_RESOLUTION_BLOCKED';

  static const Set<String> values = <String>{
    authorizedFoodOrder,
    foodOrderUnavailable,
    foodOrderResolutionBlocked,
  };
}

class AgentCallFoodOrderStatusReadStatus {
  AgentCallFoodOrderStatusReadStatus._();

  static const String authorizedFoodOrderStatus =
      'AUTHORIZED_FOOD_ORDER_STATUS';
  static const String foodOrderStatusUnavailable =
      'FOOD_ORDER_STATUS_UNAVAILABLE';

  static const Set<String> values = <String>{
    authorizedFoodOrderStatus,
    foodOrderStatusUnavailable,
  };
}

/// Deliberately smaller than the existing generic Food connector payload.
///
/// CALL status support needs operational state only. It does not expose item
/// names/add-ons/menu IDs, order totals, payment credentials, customer
/// identity/address, delivery OTP, rider identity or GPS.
class AgentCallFoodOrderStatusSnapshot {
  const AgentCallFoodOrderStatusSnapshot({
    required this.trustedOrderReferenceId,
    required this.restaurantName,
    required this.orderStatus,
    required this.paymentState,
    required this.hasAssignedRider,
    required this.canTrackOrder,
    required this.itemCount,
    required this.orderUpdatedAt,
    required this.observedAt,
  });

  final String trustedOrderReferenceId;
  final String restaurantName;
  final String orderStatus;
  final String paymentState;
  final bool hasAssignedRider;
  final bool canTrackOrder;
  final int itemCount;
  final DateTime orderUpdatedAt;
  final DateTime observedAt;

  void validate() {
    if (trustedOrderReferenceId.trim().isEmpty ||
        restaurantName.trim().isEmpty ||
        orderStatus.trim().isEmpty ||
        paymentState.trim().isEmpty) {
      throw const AgentCallFoodOrderTrustedResolutionException(
        'Privacy-minimized Food status snapshot is incomplete.',
      );
    }

    if (trustedOrderReferenceId.trim().length > 200 ||
        restaurantName.trim().length > 200 ||
        orderStatus.trim().length > 100 ||
        paymentState.trim().length > 100) {
      throw const AgentCallFoodOrderTrustedResolutionException(
        'Food status snapshot text exceeds the allowed length.',
      );
    }

    if (itemCount < 0 || itemCount > 1000) {
      throw const AgentCallFoodOrderTrustedResolutionException(
        'Food status snapshot item count is invalid.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    return <String, dynamic>{
      'trustedOrderReferenceId': trustedOrderReferenceId.trim(),
      'restaurantName': restaurantName.trim(),
      'orderStatus': orderStatus.trim(),
      'paymentState': paymentState.trim(),
      'hasAssignedRider': hasAssignedRider,
      'canTrackOrder': canTrackOrder,
      'itemCount': itemCount,
      'orderUpdatedAt': orderUpdatedAt.toUtc().toIso8601String(),
      'observedAt': observedAt.toUtc().toIso8601String(),
    };
  }
}

class AgentCallFoodOrderTrustedResolutionRequest {
  const AgentCallFoodOrderTrustedResolutionRequest({
    required this.callSessionId,
    required this.requestedBy,
    required this.trustedCallerReferenceId,
    required this.trustedContactReferenceId,
    required this.presentedOrderReferenceId,
  });

  factory AgentCallFoodOrderTrustedResolutionRequest.fromStatusRequest(
    AgentCallFoodOrderStatusRequest request,
  ) {
    request.validate();

    return AgentCallFoodOrderTrustedResolutionRequest(
      callSessionId: request.callSessionId.trim(),
      requestedBy: request.requestedBy.trim(),
      trustedCallerReferenceId: request.trustedCallerReferenceId.trim(),
      trustedContactReferenceId: request.trustedContactReferenceId.trim(),
      presentedOrderReferenceId: request.trustedOrderReferenceId.trim(),
    );
  }

  final String callSessionId;
  final String requestedBy;
  final String trustedCallerReferenceId;
  final String trustedContactReferenceId;
  final String presentedOrderReferenceId;

  void validate() {
    if (callSessionId.trim().isEmpty ||
        requestedBy.trim().isEmpty ||
        trustedCallerReferenceId.trim().isEmpty ||
        trustedContactReferenceId.trim().isEmpty ||
        presentedOrderReferenceId.trim().isEmpty) {
      throw const AgentCallFoodOrderTrustedResolutionException(
        'Complete trusted Food resolver binding is required.',
      );
    }
  }
}

class AgentCallFoodOrderTrustedResolutionReceipt {
  const AgentCallFoodOrderTrustedResolutionReceipt({
    required this.status,
    required this.source,
    required this.callSessionId,
    required this.requestedBy,
    required this.trustedCallerReferenceId,
    required this.trustedContactReferenceId,
    required this.presentedOrderReferenceId,
    required this.backendAccessVerified,
    required this.resolvedAt,
    this.snapshot,
  });

  static const String trustedBackendSource =
      'TRUSTED_BACKEND_FOOD_ORDER_RESOLVER';
  static const Duration maxAge = Duration(minutes: 2);
  static const Duration maxFutureSkew = Duration(seconds: 15);

  final String status;
  final String source;
  final String callSessionId;
  final String requestedBy;
  final String trustedCallerReferenceId;
  final String trustedContactReferenceId;
  final String presentedOrderReferenceId;
  final bool backendAccessVerified;
  final DateTime resolvedAt;
  final AgentCallFoodOrderStatusSnapshot? snapshot;

  bool get isAuthorized =>
      status == AgentCallFoodOrderTrustedResolutionStatus.authorizedFoodOrder;

  void validateAgainst({
    required AgentCallFoodOrderTrustedResolutionRequest request,
    required DateTime now,
  }) {
    request.validate();

    if (!AgentCallFoodOrderTrustedResolutionStatus.values.contains(status)) {
      throw const AgentCallFoodOrderTrustedResolutionException(
        'Unknown Food order trusted resolution status.',
      );
    }

    if (source.trim() != trustedBackendSource) {
      throw const AgentCallFoodOrderTrustedResolutionException(
        'Food order resolution source is not trusted.',
      );
    }

    if (callSessionId.trim() != request.callSessionId.trim() ||
        requestedBy.trim() != request.requestedBy.trim() ||
        trustedCallerReferenceId.trim() !=
            request.trustedCallerReferenceId.trim() ||
        trustedContactReferenceId.trim() !=
            request.trustedContactReferenceId.trim() ||
        presentedOrderReferenceId.trim() !=
            request.presentedOrderReferenceId.trim()) {
      throw const AgentCallFoodOrderTrustedResolutionException(
        'Trusted Food order resolution binding mismatch.',
      );
    }

    final DateTime normalizedNow = now.toUtc();
    final DateTime normalizedResolvedAt = resolvedAt.toUtc();

    if (normalizedResolvedAt.isAfter(normalizedNow.add(maxFutureSkew))) {
      throw const AgentCallFoodOrderTrustedResolutionException(
        'Food order trusted resolution is from the future.',
      );
    }

    if (normalizedNow.difference(normalizedResolvedAt) > maxAge) {
      throw const AgentCallFoodOrderTrustedResolutionException(
        'Food order trusted resolution is stale.',
      );
    }

    if (isAuthorized) {
      if (!backendAccessVerified || snapshot == null) {
        throw const AgentCallFoodOrderTrustedResolutionException(
          'Authorized Food order resolution requires verified access and snapshot.',
        );
      }

      snapshot!.validate();

      if (snapshot!.trustedOrderReferenceId.trim() !=
          request.presentedOrderReferenceId.trim()) {
        throw const AgentCallFoodOrderTrustedResolutionException(
          'Resolved Food order snapshot reference mismatch.',
        );
      }

      if (snapshot!.observedAt.toUtc().isAfter(
        normalizedNow.add(maxFutureSkew),
      )) {
        throw const AgentCallFoodOrderTrustedResolutionException(
          'Food order snapshot observation time is invalid.',
        );
      }
    } else {
      if (backendAccessVerified || snapshot != null) {
        throw const AgentCallFoodOrderTrustedResolutionException(
          'Unavailable/blocked Food order resolution must expose no order snapshot.',
        );
      }
    }
  }
}

class AgentCallFoodOrderStatusReadEvidence {
  const AgentCallFoodOrderStatusReadEvidence._({
    required this.status,
    required this.observedAt,
    this.snapshot,
  });

  factory AgentCallFoodOrderStatusReadEvidence.authorized({
    required AgentCallFoodOrderStatusSnapshot snapshot,
    required DateTime observedAt,
  }) {
    return AgentCallFoodOrderStatusReadEvidence._(
      status: AgentCallFoodOrderStatusReadStatus.authorizedFoodOrderStatus,
      snapshot: snapshot,
      observedAt: observedAt,
    );
  }

  factory AgentCallFoodOrderStatusReadEvidence.unavailable({
    required DateTime observedAt,
  }) {
    return AgentCallFoodOrderStatusReadEvidence._(
      status: AgentCallFoodOrderStatusReadStatus.foodOrderStatusUnavailable,
      observedAt: observedAt,
    );
  }

  final String status;
  final AgentCallFoodOrderStatusSnapshot? snapshot;
  final DateTime observedAt;

  bool get isAuthorized =>
      status == AgentCallFoodOrderStatusReadStatus.authorizedFoodOrderStatus;

  void validate() {
    if (!AgentCallFoodOrderStatusReadStatus.values.contains(status)) {
      throw const AgentCallFoodOrderTrustedResolutionException(
        'Unknown Call Food status read evidence state.',
      );
    }

    if (isAuthorized) {
      if (snapshot == null) {
        throw const AgentCallFoodOrderTrustedResolutionException(
          'Authorized Call Food status evidence requires a snapshot.',
        );
      }

      snapshot!.validate();
    } else if (snapshot != null) {
      throw const AgentCallFoodOrderTrustedResolutionException(
        'Unavailable Call Food status evidence must expose no snapshot.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return <String, dynamic>{
      'status': status,
      'snapshot': snapshot?.toSafeMap(),
      'observedAt': observedAt.toUtc().toIso8601String(),
      'foodOrderExistenceDisclosedWhenUnavailable': false,
      'rawPhoneIncluded': false,
      'transcriptIncluded': false,
      'voiceIncluded': false,
      'firebaseUidIncluded': false,
      'customerIdentityIncluded': false,
      'deliveryAddressIncluded': false,
      'deliveryInstructionsIncluded': false,
      'deliveryOtpIncluded': false,
      'riderIdentityIncluded': false,
      'gpsIncluded': false,
      'itemDetailsIncluded': false,
      'orderTotalsIncluded': false,
      'paymentCredentialsIncluded': false,
      'foodWriteAuthority': false,
    };
  }
}

class AgentCallFoodOrderTrustedResolutionException implements Exception {
  const AgentCallFoodOrderTrustedResolutionException(this.message);

  final String message;

  @override
  String toString() => 'AgentCallFoodOrderTrustedResolutionException: $message';
}
