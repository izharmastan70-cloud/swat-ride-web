class AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest {
  const AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest({
    required this.roleId,
    required this.actionId,
    required this.module,
    required this.reason,
    required this.risk,
    required this.requestedBy,
    required this.ownerApproverReferenceSha256,
    required this.actionScope,
    required this.validity,
    required this.bindingFingerprintSha256,
  });

  final String roleId;
  final String actionId;
  final String module;
  final String reason;
  final String risk;

  /// System migration-coordinator pseudonym only.
  /// This MUST NOT be the Owner approver identity/pseudonym.
  final String requestedBy;

  /// Expected fresh Owner/Super Admin approver reference, SHA-256 only.
  final String ownerApproverReferenceSha256;

  final Map<String, dynamic> actionScope;
  final Duration validity;
  final String bindingFingerprintSha256;

  bool get requesterIsSystemMigrationCoordinator => true;
  bool get approverMustBeFreshOwner => true;
  bool get requesterAndApproverMustDiffer => true;
  bool get selfApprovalAllowed => false;

  bool get readyForSeparateLiveCentralApprovalCreate => true;

  bool get createsCentralApproval => false;
  bool get approvesCentralApproval => false;
  bool get consumesCentralApproval => false;
  bool get writesFirestore => false;
  bool get executesMigration => false;
  bool get createsRole => false;
  bool get mutatesGuard => false;
  bool get createsArmingToken => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;

  bool get containsRawOwnerIdentity => false;
  bool get containsRawAuthToken => false;
  bool get containsRawClaims => false;

  void validate() {
    final RegExp sha256 = RegExp(r'^[A-Fa-f0-9]{64}$');

    if (roleId != 'security_incident_agent' ||
        actionId != 'security_incident.attach_runtime' ||
        module != 'security_incident' ||
        risk != 'CRITICAL' ||
        reason.trim().isEmpty ||
        !requestedBy.startsWith('phase66_migration_coordinator_sha256:') ||
        !sha256.hasMatch(ownerApproverReferenceSha256) ||
        validity <= Duration.zero ||
        validity > const Duration(minutes: 15) ||
        !sha256.hasMatch(bindingFingerprintSha256)) {
      throw const FormatException(
        'Invalid separated migration central approval request.',
      );
    }

    final String requesterDigest = requestedBy.substring(
      'phase66_migration_coordinator_sha256:'.length,
    );

    if (!sha256.hasMatch(requesterDigest) ||
        requesterDigest.toLowerCase() ==
            ownerApproverReferenceSha256.toLowerCase()) {
      throw const FormatException(
        'Migration requester and Owner approver must be distinct.',
      );
    }

    const Set<String> requiredScopeKeys = <String>{
      'operation',
      'bindingFingerprintSha256',
      'requestPrincipal',
      'ownerApproverReferenceSha256',
      'currentInventoryVersion',
      'proposedInventoryVersion',
      'currentRoleCount',
      'proposedRoleCount',
      'currentInventoryFingerprintSha256',
      'proposedInventoryFingerprintSha256',
      'currentControlFingerprintSha256',
      'preconditionEvidenceFingerprintSha256',
      'currentGuardRevision',
      'proposedGuardRevision',
      'targetRoleId',
      'targetModule',
      'targetActionId',
      'requestedRolloutStage',
      'proposedRoleEnabled',
      'oldGuardImmutable',
      'oldArmingTokenImmutable',
      'oldActivationReceiptImmutable',
      'existingActivationTokenReuseAllowed',
      'repositoryAttachAuthorized',
      'repositoryArmAuthorized',
      'firstIncidentWriteAuthorized',
      'authorizesSuggestOnly',
      'authorizesAuto',
      'selfApprovalAllowed',
    };

    if (!actionScope.keys.toSet().containsAll(requiredScopeKeys)) {
      throw const FormatException(
        'Separated migration central approval scope is incomplete.',
      );
    }

    if (actionScope['operation'] !=
            'MIGRATE_SECURITY_INCIDENT_ROLE_INVENTORY_22_TO_23' ||
        actionScope['bindingFingerprintSha256'] !=
            bindingFingerprintSha256.toLowerCase() ||
        actionScope['requestPrincipal'] != 'PHASE66_MIGRATION_COORDINATOR' ||
        actionScope['ownerApproverReferenceSha256'] !=
            ownerApproverReferenceSha256.toLowerCase() ||
        actionScope['currentInventoryVersion'] != 'phase66_roles_v1_22' ||
        actionScope['proposedInventoryVersion'] !=
            'phase66_roles_v2_23_security_incident' ||
        actionScope['currentRoleCount'] != 22 ||
        actionScope['proposedRoleCount'] != 23 ||
        actionScope['targetRoleId'] != roleId ||
        actionScope['targetModule'] != module ||
        actionScope['targetActionId'] != actionId ||
        actionScope['requestedRolloutStage'] != 'MONITOR_ONLY' ||
        actionScope['proposedRoleEnabled'] != false ||
        actionScope['oldGuardImmutable'] != true ||
        actionScope['oldArmingTokenImmutable'] != true ||
        actionScope['oldActivationReceiptImmutable'] != true ||
        actionScope['existingActivationTokenReuseAllowed'] != false ||
        actionScope['repositoryAttachAuthorized'] != false ||
        actionScope['repositoryArmAuthorized'] != false ||
        actionScope['firstIncidentWriteAuthorized'] != false ||
        actionScope['authorizesSuggestOnly'] != false ||
        actionScope['authorizesAuto'] != false ||
        actionScope['selfApprovalAllowed'] != false) {
      throw const FormatException(
        'Separated migration central approval scope authority mismatch.',
      );
    }
  }
}
