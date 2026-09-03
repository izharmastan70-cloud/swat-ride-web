import '../constants/agent_cross_agent_supervisor_attention_constants.dart';

class AgentCrossAgentSupervisorOwnerAdminEscalationHandoff {
  AgentCrossAgentSupervisorOwnerAdminEscalationHandoff({
    required this.handoffId,
    required this.taskId,
    required this.sourceAgentId,
    required this.attentionLevel,
    required this.securityDecisionReference,
    required this.conflictAssessmentReference,
    required this.coordinationDecisionReference,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String handoffId;
  final String taskId;
  final String sourceAgentId;
  final String attentionLevel;

  final String securityDecisionReference;
  final String conflictAssessmentReference;
  final String coordinationDecisionReference;

  final List<String> reasonCodes;

  bool get metadataOnly => true;
  bool get recipientAuthorityIsOwnerOrAdmin => true;
  bool get handoffIsNotApproval => true;
  bool get handoffIsNotPermission => true;
  bool get handoffDoesNotAuthorizeExecution => true;

  bool get containsRawPrompt => false;
  bool get containsRawConversation => false;
  bool get containsRawPrivatePayload => false;
  bool get containsRawApprovalToken => false;
  bool get containsRawPermissionToken => false;

  bool get notificationDeliveryImplementedHere => false;
  bool get persistenceImplementedHere => false;
  bool get businessExecutionImplementedHere => false;
  bool get securityMutationImplementedHere => false;

  void validateStructure() {
    final List<String> refs = <String>[
      handoffId,
      taskId,
      sourceAgentId,
      securityDecisionReference,
      conflictAssessmentReference,
      coordinationDecisionReference,
    ];

    final bool invalid = refs.any((String value) {
      final String trimmed = value.trim();

      return trimmed.isEmpty ||
          trimmed.length >
              AgentCrossAgentSupervisorAttentionLimits.opaqueIdMaxLength ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
    });

    if (invalid ||
        !AgentCrossAgentSupervisorAttentionLevel.values.contains(
          attentionLevel,
        ) ||
        attentionLevel == AgentCrossAgentSupervisorAttentionLevel.none ||
        reasonCodes.isEmpty ||
        reasonCodes.length >
            AgentCrossAgentSupervisorAttentionLimits.maxReasons) {
      throw const FormatException(
        'Invalid Cross-Agent Supervisor escalation handoff.',
      );
    }
  }
}
