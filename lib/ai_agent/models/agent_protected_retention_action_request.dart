enum AgentProtectedRetentionActionType {
  deleteProtectedRecords,
  overrideProtectedRetention,
}

enum AgentProtectedRetentionDataClass { audit, security, finance }

class AgentProtectedRetentionActionRequest {
  final String requestId;
  final AgentProtectedRetentionActionType actionType;
  final AgentProtectedRetentionDataClass dataClass;

  final String collectionPath;
  final List<String> recordIds;

  final String requestedBy;
  final String requestedByRole;

  final String reason;
  final String confirmationPhrase;

  final String approvalId;

  final DateTime createdAt;

  const AgentProtectedRetentionActionRequest({
    required this.requestId,
    required this.actionType,
    required this.dataClass,
    required this.collectionPath,
    required this.recordIds,
    required this.requestedBy,
    required this.requestedByRole,
    required this.reason,
    required this.confirmationPhrase,
    required this.approvalId,
    required this.createdAt,
  });

  bool get hasExplicitReason => reason.trim().length >= 10;

  bool get hasExplicitConfirmation =>
      confirmationPhrase.trim() == 'CONFIRM PROTECTED DATA ACTION';

  bool get isSuperAdminRequest => requestedByRole.trim() == 'super_admin';

  bool get hasApproval => approvalId.trim().isNotEmpty;

  Map<String, dynamic> toAuditMetadata() {
    return <String, dynamic>{
      'requestId': requestId.trim(),
      'actionType': actionType.name,
      'dataClass': dataClass.name,
      'collectionPath': collectionPath.trim(),
      'recordIds': List<String>.unmodifiable(recordIds),
      'requestedBy': requestedBy.trim(),
      'requestedByRole': requestedByRole.trim(),
      'reason': reason.trim(),
      'approvalId': approvalId.trim(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
