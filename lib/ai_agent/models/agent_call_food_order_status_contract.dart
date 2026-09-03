class AgentCallFoodOrderStatusRequest {
  const AgentCallFoodOrderStatusRequest({
    required this.callSessionId,
    required this.requestedBy,
    required this.trustedCallerReferenceId,
    required this.trustedContactReferenceId,
    required this.trustedOrderReferenceId,
  });

  final String callSessionId;
  final String requestedBy;
  final String trustedCallerReferenceId;
  final String trustedContactReferenceId;
  final String trustedOrderReferenceId;

  bool get hasCompleteTrustedBinding =>
      callSessionId.trim().isNotEmpty &&
      requestedBy.trim().isNotEmpty &&
      trustedCallerReferenceId.trim().isNotEmpty &&
      trustedContactReferenceId.trim().isNotEmpty &&
      trustedOrderReferenceId.trim().isNotEmpty;

  void validate() {
    if (!hasCompleteTrustedBinding) {
      throw const AgentCallFoodOrderStatusContractException(
        'Complete trusted Call/caller/contact/Food-order binding is required.',
      );
    }

    if (callSessionId.trim().length > 200 ||
        requestedBy.trim().length > 200 ||
        trustedCallerReferenceId.trim().length > 200 ||
        trustedContactReferenceId.trim().length > 200 ||
        trustedOrderReferenceId.trim().length > 200) {
      throw const AgentCallFoodOrderStatusContractException(
        'Trusted Food-order binding reference exceeds the allowed length.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    return <String, dynamic>{
      'callSessionId': callSessionId.trim(),
      'requestedBy': requestedBy.trim(),
      'trustedCallerReferenceId': trustedCallerReferenceId.trim(),
      'trustedContactReferenceId': trustedContactReferenceId.trim(),
      'trustedOrderReferenceId': trustedOrderReferenceId.trim(),
      'hasCompleteTrustedBinding': hasCompleteTrustedBinding,
      'rawPhoneIncluded': false,
      'transcriptIncluded': false,
      'voiceIncluded': false,
      'firebaseUidIncluded': false,
      'deliveryAddressIncluded': false,
      'deliveryOtpIncluded': false,
      'paymentCredentialIncluded': false,
      'orderReadExecuted': false,
      'foodWriteAuthority': false,
    };
  }
}

class AgentCallFoodOrderStatusContractException implements Exception {
  const AgentCallFoodOrderStatusContractException(this.message);

  final String message;

  @override
  String toString() => 'AgentCallFoodOrderStatusContractException: $message';
}
