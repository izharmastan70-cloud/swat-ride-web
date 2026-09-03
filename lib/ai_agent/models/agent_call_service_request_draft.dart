// =========================================================
// AI AGENT - CALL SERVICE REQUEST DRAFT
// =========================================================
//
// Phase 32 combined roadmap.
//
// Safe draft foundation for:
// - Food
// - Hotel
// - Tour
//
// This model DOES NOT:
// - create a real order
// - create a real hotel booking
// - create a real tour booking
// - cancel anything
// - charge/refund money
// - invoke a telephony provider
//
// Existing Permission/Approval architecture remains
// authoritative for future controlled writes.

class AgentCallServiceType {
  AgentCallServiceType._();

  static const String food = 'FOOD';
  static const String hotel = 'HOTEL';
  static const String tour = 'TOUR';

  static const Set<String> values = <String>{
    food,
    hotel,
    tour,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentCallServiceRequestType {
  AgentCallServiceRequestType._();

  static const String booking = 'BOOKING';
  static const String status = 'STATUS';
  static const String information = 'INFORMATION';

  static const Set<String> values = <String>{
    booking,
    status,
    information,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentCallServiceRequestDraft {
  final String serviceType;
  final String requestType;

  final String customerName;
  final String contactPhoneMasked;

  final String referenceId;
  final String requestSummary;

  final bool customerConfirmed;

  const AgentCallServiceRequestDraft({
    required this.serviceType,
    required this.requestType,
    required this.customerName,
    required this.contactPhoneMasked,
    this.referenceId = '',
    required this.requestSummary,
    this.customerConfirmed = false,
  });

  bool get isBookingRequest =>
      requestType ==
      AgentCallServiceRequestType.booking;

  bool get isStatusRequest =>
      requestType ==
      AgentCallServiceRequestType.status;

  bool get requiresConfirmation =>
      isBookingRequest;

  bool get canProceedAsDraft =>
      isComplete &&
      (!requiresConfirmation ||
          customerConfirmed);

  bool get isComplete =>
      AgentCallServiceType.isValid(serviceType) &&
      AgentCallServiceRequestType.isValid(
        requestType,
      ) &&
      customerName.trim().isNotEmpty &&
      contactPhoneMasked.trim().isNotEmpty &&
      requestSummary.trim().isNotEmpty &&
      (!isStatusRequest ||
          referenceId.trim().isNotEmpty);

  void validate() {
    if (!AgentCallServiceType.isValid(
      serviceType,
    )) {
      throw AgentCallServiceRequestDraftException(
        'Invalid Call service type "$serviceType".',
      );
    }

    if (!AgentCallServiceRequestType.isValid(
      requestType,
    )) {
      throw AgentCallServiceRequestDraftException(
        'Invalid Call request type "$requestType".',
      );
    }

    if (customerName.trim().isEmpty) {
      throw const AgentCallServiceRequestDraftException(
        'customerName cannot be empty.',
      );
    }

    if (contactPhoneMasked.trim().isEmpty) {
      throw const AgentCallServiceRequestDraftException(
        'contactPhoneMasked cannot be empty.',
      );
    }

    if (requestSummary.trim().isEmpty) {
      throw const AgentCallServiceRequestDraftException(
        'requestSummary cannot be empty.',
      );
    }

    if (isStatusRequest &&
        referenceId.trim().isEmpty) {
      throw const AgentCallServiceRequestDraftException(
        'Status request requires referenceId.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'serviceType': serviceType,
      'requestType': requestType,
      'customerName': customerName,
      'contactPhoneMasked': contactPhoneMasked,
      'referenceId': referenceId,
      'requestSummary': requestSummary,
      'customerConfirmed': customerConfirmed,
      'requiresConfirmation':
          requiresConfirmation,
      'canProceedAsDraft':
          canProceedAsDraft,
    };
  }
}

class AgentCallServiceRequestDraftException
    implements Exception {
  final String message;

  const AgentCallServiceRequestDraftException(
    this.message,
  );

  @override
  String toString() =>
      'AgentCallServiceRequestDraftException: $message';
}