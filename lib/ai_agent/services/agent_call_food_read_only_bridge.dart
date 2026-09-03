import '../models/agent_call_service_request_draft.dart';
import 'agent_food_order_read_only_connector.dart';

// =========================================================
// AI AGENT - CALL FOOD READ-ONLY BRIDGE
// =========================================================
//
// Phase 32 Step 3.
//
// Bridges Call Agent conversation/draft logic with the
// EXISTING Food read-only connector architecture.
//
// IMPORTANT:
// This step deliberately does NOT guess the existing
// AgentToolRequest / AgentReadOnlyExecutor constructor.
//
// The real connector remains authoritative for fetching an
// order. This bridge receives already-sanitized read-only
// Food data and converts it into a Call Agent status draft.
//
// NO Food order creation.
// NO cancellation.
// NO refund/payment.
// NO rider assignment.
// NO customer phone/address exposure.
// NO connector write authority.

class AgentCallFoodReadOnlyBridge {
  final AgentFoodOrderReadOnlyConnector foodConnector;

  AgentCallFoodReadOnlyBridge({
    AgentFoodOrderReadOnlyConnector? foodConnector,
  }) : foodConnector =
            foodConnector ??
            AgentFoodOrderReadOnlyConnector();

  String get expectedConnectorId =>
      'connector.food.order.read_only';

  String get module => 'food';

  AgentCallServiceRequestDraft
      buildOrderStatusDraft({
    required String customerName,
    required String contactPhoneMasked,
    required String orderId,
    required Map<String, dynamic>
        sanitizedOrderData,
  }) {
    final String cleanOrderId =
        orderId.trim();

    if (cleanOrderId.isEmpty) {
      throw const AgentCallFoodReadOnlyBridgeException(
        'orderId cannot be empty.',
      );
    }

    if (customerName.trim().isEmpty) {
      throw const AgentCallFoodReadOnlyBridgeException(
        'customerName cannot be empty.',
      );
    }

    if (contactPhoneMasked.trim().isEmpty) {
      throw const AgentCallFoodReadOnlyBridgeException(
        'contactPhoneMasked cannot be empty.',
      );
    }

    final String status =
        _text(
          sanitizedOrderData,
          'status',
          fallback: 'unknown',
        );

    final String paymentState =
        _text(
          sanitizedOrderData,
          'paymentState',
          fallback: 'unknown',
        );

    final String restaurantStatus =
        _text(
          sanitizedOrderData,
          'restaurantStatus',
        );

    final String riderStatus =
        _text(
          sanitizedOrderData,
          'riderStatus',
        );

    final List<String> parts =
        <String>[
      'Food order $cleanOrderId',
      'status: $status',
      'payment: $paymentState',
    ];

    if (restaurantStatus.isNotEmpty) {
      parts.add(
        'restaurant: $restaurantStatus',
      );
    }

    if (riderStatus.isNotEmpty) {
      parts.add(
        'delivery: $riderStatus',
      );
    }

    final AgentCallServiceRequestDraft draft =
        AgentCallServiceRequestDraft(
      serviceType:
          AgentCallServiceType.food,
      requestType:
          AgentCallServiceRequestType.status,
      customerName:
          customerName.trim(),
      contactPhoneMasked:
          contactPhoneMasked.trim(),
      referenceId:
          cleanOrderId,
      requestSummary:
          parts.join(', '),
      customerConfirmed:
          false,
    );

    draft.validate();

    return draft;
  }

  void verifySanitizedPayload(
    Map<String, dynamic> data,
  ) {
    const Set<String> forbiddenKeys =
        <String>{
      'customerPhone',
      'receiverPhone',
      'customerName',
      'receiverName',
      'deliveryAddress',
      'latitude',
      'longitude',
      'otp',
      'deliveryOtp',
      'cardNumber',
      'cvv',
      'cnic',
    };

    for (final String key
        in forbiddenKeys) {
      if (data.containsKey(key)) {
        throw AgentCallFoodReadOnlyBridgeException(
          'Sensitive Food field is not allowed in Call bridge: $key',
        );
      }
    }
  }

  String _text(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
  }) {
    final dynamic value = data[key];

    if (value == null) {
      return fallback;
    }

    final String result =
        value.toString().trim();

    return result.isEmpty
        ? fallback
        : result;
  }
}

class AgentCallFoodReadOnlyBridgeException
    implements Exception {
  final String message;

  const AgentCallFoodReadOnlyBridgeException(
    this.message,
  );

  @override
  String toString() =>
      'AgentCallFoodReadOnlyBridgeException: $message';
}