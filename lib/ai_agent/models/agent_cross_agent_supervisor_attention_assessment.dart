import '../constants/agent_cross_agent_supervisor_attention_constants.dart';

class AgentCrossAgentSupervisorAttentionAssessment {
  AgentCrossAgentSupervisorAttentionAssessment({
    required this.level,
    required this.recommendHold,
    required this.recommendStop,
    required this.ownerAdminAttentionRequired,
    required List<String> reasons,
  }) : reasons = List<String>.unmodifiable(reasons);

  final String level;
  final bool recommendHold;
  final bool recommendStop;
  final bool ownerAdminAttentionRequired;
  final List<String> reasons;

  bool get noAttention => level == AgentCrossAgentSupervisorAttentionLevel.none;

  bool get recommendationOnly => true;
  bool get securityAuthorityAlwaysAboveSupervisor => true;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get manufacturesOwnerAuthority => false;
  bool get expandsScope => false;
  bool get authorizesExecution => false;
  bool get executesBusinessAction => false;

  bool get sendsNotification => false;
  bool get persistsAssessment => false;
  bool get mutatesTask => false;
  bool get mutatesRouting => false;
  bool get modifiesSecurityEngine => false;

  void validateStructure() {
    if (!AgentCrossAgentSupervisorAttentionLevel.values.contains(level) ||
        reasons.isEmpty ||
        reasons.length > AgentCrossAgentSupervisorAttentionLimits.maxReasons) {
      throw const FormatException(
        'Invalid Cross-Agent Supervisor attention assessment.',
      );
    }

    if (noAttention &&
        (recommendHold || recommendStop || ownerAdminAttentionRequired)) {
      throw const FormatException(
        'No-attention assessment cannot recommend action.',
      );
    }

    if (recommendStop && !ownerAdminAttentionRequired) {
      throw const FormatException(
        'STOP recommendation requires attention handoff.',
      );
    }
  }
}
