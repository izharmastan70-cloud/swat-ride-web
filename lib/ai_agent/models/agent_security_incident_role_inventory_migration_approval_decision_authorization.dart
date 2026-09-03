abstract final class AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction {
  static const String approve = 'APPROVE';
  static const String reject = 'REJECT';

  static const Set<String> values = <String>{approve, reject};
}

class AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAuthorization {
  const AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAuthorization({
    required this.allowed,
    required this.reasonCode,
    required this.decisionAction,
    required this.roleId,
    required this.actionId,
    required this.module,
    required this.bindingFingerprintSha256,
    required this.ownerApproverReferenceSha256,
    required this.ownerAuthAgeSeconds,
  });

  final bool allowed;
  final String reasonCode;
  final String decisionAction;

  final String roleId;
  final String actionId;
  final String module;

  final String bindingFingerprintSha256;
  final String ownerApproverReferenceSha256;

  /// Safe bounded projection only: 0..300.
  final int? ownerAuthAgeSeconds;

  bool get mayCallCentralApprove =>
      allowed &&
      decisionAction ==
          AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
              .approve;

  bool get mayCallCentralReject =>
      allowed &&
      decisionAction ==
          AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
              .reject;

  bool get approvalDecisionOnly => true;

  bool get createsCentralApproval => false;
  bool get approvesCentralApproval => false;
  bool get rejectsCentralApproval => false;
  bool get consumesCentralApproval => false;

  bool get writesFirestore => false;
  bool get executesMigration => false;
  bool get createsRole => false;
  bool get enablesRole => false;
  bool get mutatesGuard => false;
  bool get createsArmingToken => false;
  bool get reusesExistingActivationToken => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;

  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;

  bool get containsRawOwnerIdentity => false;
  bool get containsRawIdToken => false;
  bool get containsRawClaims => false;

  void validate() {
    final RegExp sha256 = RegExp(r'^[A-Fa-f0-9]{64}$');

    if (!AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
            .values
            .contains(decisionAction) ||
        roleId != 'security_incident_agent' ||
        actionId != 'security_incident.attach_runtime' ||
        module != 'security_incident' ||
        !sha256.hasMatch(bindingFingerprintSha256) ||
        !sha256.hasMatch(ownerApproverReferenceSha256)) {
      throw const FormatException(
        'Invalid migration approval decision authorization.',
      );
    }

    if (allowed) {
      if (ownerAuthAgeSeconds == null ||
          ownerAuthAgeSeconds! < 0 ||
          ownerAuthAgeSeconds! > 300) {
        throw const FormatException(
          'Allowed migration approval decision requires fresh bounded Owner auth age.',
        );
      }
    }

    if (!allowed && (mayCallCentralApprove || mayCallCentralReject)) {
      throw const FormatException(
        'Blocked decision cannot authorize central approval mutation.',
      );
    }
  }
}
