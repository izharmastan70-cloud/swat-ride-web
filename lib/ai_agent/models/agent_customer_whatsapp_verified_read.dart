import '../constants/agent_customer_whatsapp_constants.dart';

class AgentCustomerWhatsAppReadKind {
  AgentCustomerWhatsAppReadKind._();

  static const String serviceInfo = 'SERVICE_INFO';
  static const String bookingStatus = 'BOOKING_STATUS';
  static const String driverStatus = 'DRIVER_STATUS';
  static const String fare = 'FARE';
  static const String paymentStatus = 'PAYMENT_STATUS';
  static const String availability = 'AVAILABILITY';

  static const Set<String> values = <String>{
    serviceInfo,
    bookingStatus,
    driverStatus,
    fare,
    paymentStatus,
    availability,
  };

  static bool isSensitive(String kind) {
    return kind == bookingStatus ||
        kind == driverStatus ||
        kind == paymentStatus;
  }
}

class AgentCustomerWhatsAppVerifiedReadRequest {
  const AgentCustomerWhatsAppVerifiedReadRequest({
    required this.service,
    required this.kind,
    this.customerId = '',
    this.referenceId = '',
    this.customerVerified = false,
  });

  final String service;
  final String kind;
  final String customerId;
  final String referenceId;
  final bool customerVerified;

  bool get sensitive => AgentCustomerWhatsAppReadKind.isSensitive(kind);

  void validate() {
    if (!AgentCustomerWhatsAppService.values.contains(service)) {
      throw const AgentCustomerWhatsAppVerifiedReadException(
        'Unsupported Customer WhatsApp service.',
      );
    }

    if (!AgentCustomerWhatsAppReadKind.values.contains(kind)) {
      throw const AgentCustomerWhatsAppVerifiedReadException(
        'Unsupported Customer WhatsApp read kind.',
      );
    }

    if (customerId.contains('\n') ||
        customerId.contains('\r') ||
        referenceId.contains('\n') ||
        referenceId.contains('\r')) {
      throw const AgentCustomerWhatsAppVerifiedReadException(
        'Customer/reference identifiers cannot contain line breaks.',
      );
    }
  }
}

class AgentCustomerWhatsAppVerifiedReadResult {
  AgentCustomerWhatsAppVerifiedReadResult({
    required this.ok,
    required this.backendVerified,
    required this.code,
    Map<String, dynamic> safeData = const <String, dynamic>{},
    this.requiresCustomerVerification = false,
    this.requiresHumanEscalation = false,
  }) : safeData = Map<String, dynamic>.unmodifiable(safeData);

  final bool ok;
  final bool backendVerified;
  final String code;
  final Map<String, dynamic> safeData;
  final bool requiresCustomerVerification;
  final bool requiresHumanEscalation;

  bool get mayUseInCustomerReply =>
      ok &&
      backendVerified &&
      !requiresCustomerVerification &&
      !requiresHumanEscalation;

  factory AgentCustomerWhatsAppVerifiedReadResult.denied(
    String code, {
    bool requiresCustomerVerification = false,
    bool requiresHumanEscalation = false,
  }) {
    return AgentCustomerWhatsAppVerifiedReadResult(
      ok: false,
      backendVerified: false,
      code: code,
      requiresCustomerVerification: requiresCustomerVerification,
      requiresHumanEscalation: requiresHumanEscalation,
    );
  }
}

abstract class AgentCustomerWhatsAppVerifiedReadSource {
  Future<AgentCustomerWhatsAppVerifiedReadResult> readVerified(
    AgentCustomerWhatsAppVerifiedReadRequest request,
  );
}

class AgentCustomerWhatsAppVerifiedReadException implements Exception {
  const AgentCustomerWhatsAppVerifiedReadException(this.message);

  final String message;

  @override
  String toString() => 'AgentCustomerWhatsAppVerifiedReadException: $message';
}
