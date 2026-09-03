abstract final class AgentSecurityIncidentPostMigrationRebindApprovalDecisionAction {
  static const String approve = 'APPROVE';
  static const String reject = 'REJECT';

  static const Set<String> values = <String>{approve, reject};
}

class AgentSecurityIncidentPostMigrationRebindApprovalDecisionAuthorization {
  const AgentSecurityIncidentPostMigrationRebindApprovalDecisionAuthorization({
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

  /// Safe bounded projection only: 0..300 when verified.
  final int? ownerAuthAgeSeconds;

  bool get mayCallCentralApprove =>
      allowed &&
      decisionAction ==
          AgentSecurityIncidentPostMigrationRebindApprovalDecisionAction
              .approve;

  bool get mayCallCentralReject =>
      allowed &&
      decisionAction ==
          AgentSecurityIncidentPostMigrationRebindApprovalDecisionAction.reject;

  bool get approvalDecisionOnly => true;

  bool get createsCentralApproval => false;
  bool get consumesCentralApproval => false;
  bool get executesRebind => false;
  bool get createsFreshToken => false;
  bool get createsRebindReceipt => false;
  bool get mutatesAuthorityManifest => false;
  bool get mutatesGuard => false;
  bool get enablesRole => false;
  bool get releasesMigrationHold => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
