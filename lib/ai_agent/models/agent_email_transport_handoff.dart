class AgentEmailTransportHandoff {
  const AgentEmailTransportHandoff({
    required this.handoffId,
    required this.authorizationRequestId,
    required this.approvalId,
    required this.draftId,
    required this.bindingAlgorithm,
    required this.bindingFingerprint,
    required this.senderIdentityId,
    required this.providerId,
    required this.fromAddress,
    required this.to,
    required this.cc,
    required this.bcc,
    required this.subject,
    required this.bodyText,
    required this.attachmentIds,
    required this.createdAt,
  });

  final String handoffId;
  final String authorizationRequestId;
  final String approvalId;
  final String draftId;
  final String bindingAlgorithm;
  final String bindingFingerprint;
  final String senderIdentityId;
  final String providerId;
  final String fromAddress;
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final String subject;
  final String bodyText;
  final List<String> attachmentIds;
  final DateTime createdAt;

  bool get approvalAlreadyConsumed => true;

  bool get maySend => false;
  bool get mayCallProvider => false;
  bool get mayOpenNetworkConnection => false;
  bool get mayWriteMailbox => false;
  bool get mayDeploy => false;

  void validate() {
    if (handoffId.trim().isEmpty ||
        authorizationRequestId.trim().isEmpty ||
        approvalId.trim().isEmpty ||
        draftId.trim().isEmpty ||
        bindingAlgorithm.trim().isEmpty ||
        bindingFingerprint.trim().isEmpty ||
        senderIdentityId.trim().isEmpty ||
        providerId.trim().isEmpty ||
        fromAddress.trim().isEmpty) {
      throw const AgentEmailTransportHandoffException(
        'Email transport handoff identity fields cannot be empty.',
      );
    }

    if (to.isEmpty) {
      throw const AgentEmailTransportHandoffException(
        'Email transport handoff requires at least one TO recipient.',
      );
    }

    if (subject.trim().isEmpty || bodyText.trim().isEmpty) {
      throw const AgentEmailTransportHandoffException(
        'Email transport handoff requires subject and bodyText.',
      );
    }
  }
}

class AgentEmailTransportHandoffException implements Exception {
  const AgentEmailTransportHandoffException(this.message);

  final String message;

  @override
  String toString() => 'AgentEmailTransportHandoffException: $message';
}
