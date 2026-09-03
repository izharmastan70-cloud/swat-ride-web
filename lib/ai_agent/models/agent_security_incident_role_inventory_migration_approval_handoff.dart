class AgentSecurityIncidentRoleInventoryMigrationApprovalHandoff {
  const AgentSecurityIncidentRoleInventoryMigrationApprovalHandoff({
    required this.roleId,
    required this.actionId,
    required this.module,
    required this.reason,
    required this.risk,
    required this.requestedBy,
    required this.actionScope,
    required this.validity,
    required this.bindingFingerprintSha256,
  });

  final String roleId;
  final String actionId;
  final String module;
  final String reason;
  final String risk;

  /// Pseudonymous requester reference only. Never raw UID/email/phone/token.
  final String requestedBy;

  final Map<String, dynamic> actionScope;
  final Duration validity;

  /// SHA-256 of the exact T-AB migration Owner approval binding.
  final String bindingFingerprintSha256;

  bool get readyForSeparateCentralApprovalCreate => true;

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
        requestedBy.trim().isEmpty ||
        !requestedBy.startsWith('phase66_owner_sha256:') ||
        validity <= Duration.zero ||
        validity > const Duration(minutes: 15) ||
        !sha256.hasMatch(bindingFingerprintSha256)) {
      throw const FormatException(
        'Invalid Phase 66 migration central-approval handoff.',
      );
    }

    const Set<String> requiredScopeKeys = <String>{
      'operation',
      'bindingFingerprintSha256',
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
      'freshOwnerVerifiedAtApproval',
      'explicitOwnerApproval',
      'oldGuardImmutable',
      'oldArmingTokenImmutable',
      'oldActivationReceiptImmutable',
      'existingActivationTokenReuseAllowed',
      'repositoryAttachAuthorized',
      'repositoryArmAuthorized',
      'firstIncidentWriteAuthorized',
      'authorizesSuggestOnly',
      'authorizesAuto',
    };

    if (!actionScope.keys.toSet().containsAll(requiredScopeKeys)) {
      throw const FormatException(
        'Migration central-approval actionScope is incomplete.',
      );
    }

    if (actionScope['operation'] !=
            'MIGRATE_SECURITY_INCIDENT_ROLE_INVENTORY_22_TO_23' ||
        actionScope['bindingFingerprintSha256'] !=
            bindingFingerprintSha256.toLowerCase() ||
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
        actionScope['freshOwnerVerifiedAtApproval'] != true ||
        actionScope['explicitOwnerApproval'] != true ||
        actionScope['oldGuardImmutable'] != true ||
        actionScope['oldArmingTokenImmutable'] != true ||
        actionScope['oldActivationReceiptImmutable'] != true ||
        actionScope['existingActivationTokenReuseAllowed'] != false ||
        actionScope['repositoryAttachAuthorized'] != false ||
        actionScope['repositoryArmAuthorized'] != false ||
        actionScope['firstIncidentWriteAuthorized'] != false ||
        actionScope['authorizesSuggestOnly'] != false ||
        actionScope['authorizesAuto'] != false) {
      throw const FormatException(
        'Migration central-approval actionScope authority mismatch.',
      );
    }

    for (final String key in <String>[
      'currentInventoryFingerprintSha256',
      'proposedInventoryFingerprintSha256',
      'currentControlFingerprintSha256',
      'preconditionEvidenceFingerprintSha256',
    ]) {
      final String value = (actionScope[key] ?? '').toString();

      if (!sha256.hasMatch(value)) {
        throw FormatException(
          'Migration central-approval actionScope SHA-256 invalid: $key',
        );
      }
    }

    if (actionScope['currentGuardRevision'] is! int ||
        actionScope['proposedGuardRevision'] is! int ||
        actionScope['proposedGuardRevision'] !=
            (actionScope['currentGuardRevision'] as int) + 1) {
      throw const FormatException(
        'Migration central-approval guard revision mismatch.',
      );
    }
  }
}
