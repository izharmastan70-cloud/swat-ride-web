abstract final class AgentSecurityIncidentPostRebindEnableApprovalDecisionAction {
  static const String approve = 'APPROVE';
  static const String reject = 'REJECT';

  static const Set<String> values = <String>{approve, reject};
}

class AgentSecurityIncidentPostRebindEnableApprovalDecisionAuthorization {
  const AgentSecurityIncidentPostRebindEnableApprovalDecisionAuthorization({
    required this.allowed,
    required this.reasonCode,
    required this.decisionAction,
    required this.ownerApproverReferenceSha256,
    required this.ownerAuthAgeSeconds,
  });

  final bool allowed;
  final String reasonCode;
  final String decisionAction;
  final String ownerApproverReferenceSha256;
  final int? ownerAuthAgeSeconds;

  bool get mayCallCentralApprove =>
      allowed &&
      decisionAction ==
          AgentSecurityIncidentPostRebindEnableApprovalDecisionAction.approve;

  bool get mayCallCentralReject =>
      allowed &&
      decisionAction ==
          AgentSecurityIncidentPostRebindEnableApprovalDecisionAction.reject;

  bool get approvalDecisionOnly => true;
  bool get createsCentralApproval => false;
  bool get consumesCentralApproval => false;
  bool get issuesReplacementToken => false;
  bool get consumesReplacementToken => false;
  bool get enablesRole => false;
  bool get releasesMigrationHold => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
