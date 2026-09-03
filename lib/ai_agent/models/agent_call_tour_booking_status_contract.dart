class AgentCallTourBookingStatusRequest {
  const AgentCallTourBookingStatusRequest({
    required this.callSessionId,
    required this.requestedBy,
    required this.trustedCallerReferenceId,
    required this.trustedContactReferenceId,
    required this.trustedTourBookingReferenceId,
  });

  final String callSessionId;
  final String requestedBy;
  final String trustedCallerReferenceId;
  final String trustedContactReferenceId;
  final String trustedTourBookingReferenceId;

  bool get hasCompleteTrustedBinding =>
      callSessionId.trim().isNotEmpty &&
      requestedBy.trim().isNotEmpty &&
      trustedCallerReferenceId.trim().isNotEmpty &&
      trustedContactReferenceId.trim().isNotEmpty &&
      trustedTourBookingReferenceId.trim().isNotEmpty;

  void validate() {
    if (!hasCompleteTrustedBinding) {
      throw const AgentCallTourBookingStatusContractException(
        'Complete trusted Call/caller/contact/Tour-booking binding is required.',
      );
    }

    if (callSessionId.trim().length > 200 ||
        requestedBy.trim().length > 200 ||
        trustedCallerReferenceId.trim().length > 200 ||
        trustedContactReferenceId.trim().length > 200 ||
        trustedTourBookingReferenceId.trim().length > 200) {
      throw const AgentCallTourBookingStatusContractException(
        'Trusted Tour-booking binding reference exceeds the allowed length.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    return <String, dynamic>{
      'callSessionId': callSessionId.trim(),
      'requestedBy': requestedBy.trim(),
      'trustedCallerReferenceId': trustedCallerReferenceId.trim(),
      'trustedContactReferenceId': trustedContactReferenceId.trim(),
      'trustedTourBookingReferenceId': trustedTourBookingReferenceId.trim(),
      'hasCompleteTrustedBinding': hasCompleteTrustedBinding,
      'rawPhoneIncluded': false,
      'transcriptIncluded': false,
      'voiceIncluded': false,
      'firebaseUidIncluded': false,
      'pickupCoordinatesIncluded': false,
      'specialRequestIncluded': false,
      'financialAmountsIncluded': false,
      'privateAssignmentIdsIncluded': false,
      'tourReadExecuted': false,
      'tourWriteAuthority': false,
    };
  }
}

class AgentCallTourBookingStatusContractException implements Exception {
  const AgentCallTourBookingStatusContractException(this.message);

  final String message;

  @override
  String toString() => 'AgentCallTourBookingStatusContractException: $message';
}
