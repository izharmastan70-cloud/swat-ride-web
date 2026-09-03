import '../constants/agent_cross_agent_supervisor_attention_constants.dart';
import '../constants/agent_cross_agent_supervisor_coordination_constants.dart';
import '../models/agent_cross_agent_supervisor_attention_assessment.dart';
import '../models/agent_cross_agent_supervisor_attention_request.dart';

class AgentCrossAgentSupervisorAttentionPolicy {
  const AgentCrossAgentSupervisorAttentionPolicy();

  AgentCrossAgentSupervisorAttentionAssessment assess(
    AgentCrossAgentSupervisorAttentionRequest request,
  ) {
    request.validateStructure();

    final List<String> reasons = <String>[];

    final bool restrictedAuthorityMissing =
        request.securitySnapshot.restrictedAction &&
        !request.securitySnapshot.ownerAdminAuthorityPresent;

    if (restrictedAuthorityMissing) {
      reasons.add(
        AgentCrossAgentSupervisorAttentionReason.missingOwnerAdminAuthority,
      );
    }

    if (!request.conflictAssessment.clean ||
        request.conflictAssessment.recommendHold ||
        request.conflictAssessment.recommendStop) {
      reasons.add(AgentCrossAgentSupervisorAttentionReason.conflictOrWrongWork);
    }

    if (request.coordinationDecision.status ==
        AgentCrossAgentOwnershipStatus.holdAmbiguousOwner) {
      reasons.add(AgentCrossAgentSupervisorAttentionReason.ambiguousOwner);
    }

    if (request.coordinationDecision.status ==
        AgentCrossAgentOwnershipStatus.holdNoEligibleOwner) {
      reasons.add(AgentCrossAgentSupervisorAttentionReason.noEligibleOwner);
    }

    if (request.repeatedFailureCount >=
        AgentCrossAgentSupervisorAttentionLimits
            .repeatedFailureAttentionThreshold) {
      reasons.add(AgentCrossAgentSupervisorAttentionReason.repeatedFailure);
    }

    if (request.suspiciousActivityDetected) {
      reasons.add(AgentCrossAgentSupervisorAttentionReason.suspiciousActivity);
    }

    if (request.unsafeActionDetected) {
      reasons.add(AgentCrossAgentSupervisorAttentionReason.unsafeAction);
    }

    if (request.unclearAuthority) {
      reasons.add(AgentCrossAgentSupervisorAttentionReason.unclearAuthority);
    }

    if (request.mandatoryOwnerAdminReview && reasons.isEmpty) {
      reasons.add(AgentCrossAgentSupervisorAttentionReason.unclearAuthority);
    }

    final bool urgent =
        request.suspiciousActivityDetected ||
        request.unsafeActionDetected ||
        request.conflictAssessment.recommendStop;

    if (urgent) {
      return _result(
        level: AgentCrossAgentSupervisorAttentionLevel.urgentSecurity,
        hold: false,
        stop: true,
        attention: true,
        reasons: reasons.isEmpty
            ? const <String>[
                AgentCrossAgentSupervisorAttentionReason.unsafeAction,
              ]
            : reasons,
      );
    }

    final bool attentionNeeded =
        restrictedAuthorityMissing ||
        request.mandatoryOwnerAdminReview ||
        request.unclearAuthority ||
        request.repeatedFailureCount >=
            AgentCrossAgentSupervisorAttentionLimits
                .repeatedFailureAttentionThreshold ||
        !request.conflictAssessment.clean ||
        request.coordinationDecision.recommendHold ||
        request.coordinationDecision.escalationRecommended ||
        request.coordinationDecision.status ==
            AgentCrossAgentOwnershipStatus.holdAmbiguousOwner ||
        request.coordinationDecision.status ==
            AgentCrossAgentOwnershipStatus.holdNoEligibleOwner;

    if (attentionNeeded) {
      return _result(
        level: AgentCrossAgentSupervisorAttentionLevel.ownerAdminReview,
        hold: true,
        stop: false,
        attention: true,
        reasons: reasons.isEmpty
            ? const <String>[
                AgentCrossAgentSupervisorAttentionReason.unclearAuthority,
              ]
            : reasons,
      );
    }

    return _result(
      level: AgentCrossAgentSupervisorAttentionLevel.none,
      hold: false,
      stop: false,
      attention: false,
      reasons: const <String>['no_owner_admin_attention_required'],
    );
  }

  AgentCrossAgentSupervisorAttentionAssessment _result({
    required String level,
    required bool hold,
    required bool stop,
    required bool attention,
    required List<String> reasons,
  }) {
    final AgentCrossAgentSupervisorAttentionAssessment result =
        AgentCrossAgentSupervisorAttentionAssessment(
          level: level,
          recommendHold: hold,
          recommendStop: stop,
          ownerAdminAttentionRequired: attention,
          reasons: reasons,
        );

    result.validateStructure();
    return result;
  }

  bool get missingOwnerAdminAuthorityRequiresAttention => true;
  bool get conflictRequiresAttention => true;
  bool get ambiguousOwnerRequiresAttention => true;
  bool get noEligibleOwnerRequiresAttention => true;
  bool get repeatedFailureCanRequireAttention => true;
  bool get suspiciousActivityRequiresUrgentAttention => true;
  bool get unsafeActionRequiresUrgentAttention => true;
  bool get unclearAuthorityRequiresAttention => true;

  bool get supervisorCanManufactureOwnerAuthority => false;
  bool get supervisorCanCreateApproval => false;
  bool get supervisorCanGrantPermission => false;
  bool get supervisorCanExecuteBusinessAction => false;

  bool get retryLoopSuppressionImplementedHere => false;
  bool get notificationDeliveryImplementedHere => false;
  bool get persistenceImplementedHere => false;
}
