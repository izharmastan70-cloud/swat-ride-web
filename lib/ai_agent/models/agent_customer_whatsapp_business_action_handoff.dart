import '../constants/agent_action_ids.dart';
import '../services/agent_action_registry.dart';

class AgentCustomerWhatsAppBusinessOperation {
  AgentCustomerWhatsAppBusinessOperation._();

  static const String rideBookingRequest = 'RIDE_BOOKING_REQUEST';
  static const String foodOrderRequest = 'FOOD_ORDER_REQUEST';
  static const String hotelBookingRequest = 'HOTEL_BOOKING_REQUEST';
  static const String tourBookingRequest = 'TOUR_BOOKING_REQUEST';
  static const String cargoBookingRequest = 'CARGO_BOOKING_REQUEST';
  static const String supportEscalationRequest = 'SUPPORT_ESCALATION_REQUEST';

  static const Set<String> values = <String>{
    rideBookingRequest,
    foodOrderRequest,
    hotelBookingRequest,
    tourBookingRequest,
    cargoBookingRequest,
    supportEscalationRequest,
  };
}

/// Exact, customer-confirmed request handed toward the existing central
/// approval system.
///
/// This object is intentionally NOT executable. It does not call a Ride,
/// Food, Hotel, Tour, Cargo, payment, refund, or provider API.
class AgentCustomerWhatsAppBusinessActionHandoff {
  AgentCustomerWhatsAppBusinessActionHandoff({
    required this.handoffId,
    required this.sessionId,
    required this.conversationId,
    required this.senderRefHash,
    required this.customerIdAlias,
    required this.service,
    required this.operation,
    required this.customerConfirmed,
    required this.backendFactsVerified,
    required Map<String, dynamic> safeActionScope,
    required this.createdAt,
  }) : safeActionScope = Map<String, dynamic>.unmodifiable(safeActionScope);

  final String handoffId;
  final String sessionId;
  final String conversationId;
  final String senderRefHash;
  final String customerIdAlias;
  final String service;
  final String operation;
  final bool customerConfirmed;
  final bool backendFactsVerified;
  final Map<String, dynamic> safeActionScope;
  final DateTime createdAt;

  String get approvalActionId =>
      AgentActionId.requestCustomerWhatsAppBusinessAction;

  bool get requiresPermissionEngine => true;
  bool get requiresRuntimeGate => true;
  bool get requiresApprovalEngine => true;
  bool get requiresCustomerConfirmation => true;
  bool get mayExecuteBusinessWrite => false;
  bool get mayChargePayment => false;
  bool get maySendWhatsApp => false;

  bool get actionRegistryRequiresApproval {
    final action = AgentActionRegistry.get(approvalActionId);

    return action != null && !action.readOnly && action.alwaysRequiresApproval;
  }

  bool get readyForApprovalRequest =>
      customerConfirmed &&
      backendFactsVerified &&
      actionRegistryRequiresApproval;

  void validate() {
    if (handoffId.trim().isEmpty ||
        sessionId.trim().isEmpty ||
        conversationId.trim().isEmpty ||
        senderRefHash.trim().isEmpty ||
        customerIdAlias.trim().isEmpty ||
        service.trim().isEmpty) {
      throw const AgentCustomerWhatsAppBusinessActionException(
        'Business handoff binding fields cannot be empty.',
      );
    }

    if (!AgentCustomerWhatsAppBusinessOperation.values.contains(operation)) {
      throw const AgentCustomerWhatsAppBusinessActionException(
        'Unsupported Customer WhatsApp business operation.',
      );
    }

    if (!customerConfirmed) {
      throw const AgentCustomerWhatsAppBusinessActionException(
        'Explicit customer confirmation is required.',
      );
    }

    if (!backendFactsVerified) {
      throw const AgentCustomerWhatsAppBusinessActionException(
        'Business action facts must be verified before approval request.',
      );
    }

    if (!actionRegistryRequiresApproval) {
      throw const AgentCustomerWhatsAppBusinessActionException(
        'Customer WhatsApp business action must remain approval-required.',
      );
    }

    if (safeActionScope.isEmpty) {
      throw const AgentCustomerWhatsAppBusinessActionException(
        'Exact non-empty action scope is required.',
      );
    }

    _rejectSecretLikeScope(safeActionScope);
  }

  static void _rejectSecretLikeScope(Map<String, dynamic> scope) {
    const List<String> blocked = <String>[
      'password',
      'passwd',
      'otp',
      'secret',
      'token',
      'apikey',
      'api_key',
      'authorization',
      'credential',
      'cardnumber',
      'card_number',
      'cvv',
      'cvc',
      'pin',
      'serviceaccount',
      'service_account',
    ];

    for (final MapEntry<String, dynamic> entry in scope.entries) {
      final String key = entry.key.trim().toLowerCase();

      if (blocked.any(key.contains)) {
        throw const AgentCustomerWhatsAppBusinessActionException(
          'Secret/payment credential fields are forbidden in WhatsApp action scope.',
        );
      }

      final dynamic value = entry.value;

      if (value is Map) {
        _rejectSecretLikeScope(
          value.map(
            (dynamic key, dynamic item) =>
                MapEntry<String, dynamic>(key.toString(), item),
          ),
        );
      }
    }
  }
}

class AgentCustomerWhatsAppBusinessActionException implements Exception {
  const AgentCustomerWhatsAppBusinessActionException(this.message);

  final String message;

  @override
  String toString() => 'AgentCustomerWhatsAppBusinessActionException: $message';
}
