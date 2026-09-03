import '../constants/agent_cross_agent_supervisor_attention_constants.dart';
import 'agent_cross_agent_supervisor_conflict_assessment.dart';
import 'agent_cross_agent_supervisor_coordination_decision.dart';
import 'agent_cross_agent_supervisor_security_snapshot.dart';

class AgentCrossAgentSupervisorAttentionRequest {
  const AgentCrossAgentSupervisorAttentionRequest({
    required this.requestId,
    required this.taskId,
    required this.sourceAgentId,
    required this.securitySnapshot,
    required this.conflictAssessment,
    required this.coordinationDecision,
    required this.repeatedFailureCount,
    required this.suspiciousActivityDetected,
    required this.unsafeActionDetected,
    required this.unclearAuthority,
    required this.mandatoryOwnerAdminReview,
  });

  final String requestId;
  final String taskId;
  final String sourceAgentId;

  final AgentCrossAgentSupervisorSecuritySnapshot securitySnapshot;
  final AgentCrossAgentSupervisorConflictAssessment conflictAssessment;
  final AgentCrossAgentSupervisorCoordinationDecision coordinationDecision;

  final int repeatedFailureCount;
  final bool suspiciousActivityDetected;
  final bool unsafeActionDetected;
  final bool unclearAuthority;
  final bool mandatoryOwnerAdminReview;

  bool get containsRawUserMessage => false;
  bool get containsRawConversation => false;
  bool get containsRawProviderResponse => false;
  bool get containsPrivatePayload => false;
  bool get containsRawApprovalToken => false;
  bool get containsRawPermissionToken => false;

  bool get asksSupervisorToGrantAuthority => false;
  bool get asksSupervisorToCreateApproval => false;
  bool get asksSupervisorToSendNotification => false;

  void validateStructure() {
    final List<String> values = <String>[requestId, taskId, sourceAgentId];

    final bool invalid = values.any((String value) {
      final String trimmed = value.trim();

      return trimmed.isEmpty ||
          trimmed.length >
              AgentCrossAgentSupervisorAttentionLimits.opaqueIdMaxLength ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
    });

    if (invalid || repeatedFailureCount < 0) {
      throw const FormatException(
        'Invalid Cross-Agent Supervisor attention request.',
      );
    }

    securitySnapshot.validateStructure();
    conflictAssessment.validateStructure();
    coordinationDecision.validateStructure();
  }
}
