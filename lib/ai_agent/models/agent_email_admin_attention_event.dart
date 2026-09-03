class AgentEmailAdminAttentionStatus {
  AgentEmailAdminAttentionStatus._();

  static const String pendingReview = 'PENDING_REVIEW';
}

class AgentEmailAdminAttentionEvent {
  const AgentEmailAdminAttentionEvent({
    required this.attentionId,
    required this.draftId,
    required this.sourceAddressMasked,
    required this.subjectSafe,
    required this.safeSummary,
    required this.reasonCodes,
    required this.createdAt,
  });

  final String attentionId;
  final String draftId;
  final String sourceAddressMasked;
  final String subjectSafe;
  final String safeSummary;
  final List<String> reasonCodes;
  final DateTime createdAt;

  String get status => AgentEmailAdminAttentionStatus.pendingReview;

  bool get requiresHumanReview => true;
  bool get mayAutoSend => false;
  bool get bodyIncluded => false;
  bool get sensitiveValueIncluded => false;
  bool get phase64OwnerAttentionCompatible => true;

  List<String> get reviewActions => const <String>[
    'REVIEW',
    'APPROVE',
    'REJECT',
  ];

  void validate() {
    if (attentionId.trim().isEmpty ||
        draftId.trim().isEmpty ||
        sourceAddressMasked.trim().isEmpty ||
        subjectSafe.trim().isEmpty ||
        safeSummary.trim().isEmpty) {
      throw const AgentEmailAdminAttentionException(
        'Email Admin Attention identity/summary fields cannot be empty.',
      );
    }

    if (reasonCodes.isEmpty) {
      throw const AgentEmailAdminAttentionException(
        'Email Admin Attention requires at least one reason code.',
      );
    }
  }

  Map<String, dynamic> toSafeMetadata() {
    validate();

    return <String, dynamic>{
      'attentionType': 'EMAIL_UNUSUAL_REVIEW',
      'attentionId': attentionId.trim(),
      'draftId': draftId.trim(),
      'sourceAddressMasked': sourceAddressMasked.trim(),
      'subjectSafe': subjectSafe.trim(),
      'safeSummary': safeSummary.trim(),
      'reasonCodes': List<String>.unmodifiable(reasonCodes),
      'status': status,
      'requiresHumanReview': true,
      'reviewActions': reviewActions,
      'mayAutoSend': false,
      'bodyIncluded': false,
      'sensitiveValueIncluded': false,
      'phase64OwnerAttentionCompatible': true,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }
}

class AgentEmailAdminAttentionException implements Exception {
  const AgentEmailAdminAttentionException(this.message);

  final String message;

  @override
  String toString() => 'AgentEmailAdminAttentionException: $message';
}
