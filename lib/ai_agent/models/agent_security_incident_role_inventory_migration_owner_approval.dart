import 'agent_security_incident_role_inventory_revision_design.dart';

abstract final class AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalContract {
  static const String operation =
      'MIGRATE_SECURITY_INCIDENT_ROLE_INVENTORY_22_TO_23';

  static const String requiredRolloutStage = 'MONITOR_ONLY';

  static const Duration maxApprovalValidity = Duration(minutes: 15);

  static const bool proposedRoleEnabledAtMigration = false;

  static const bool oldGuardImmutable = true;
  static const bool oldArmingTokenImmutable = true;
  static const bool oldActivationReceiptImmutable = true;
  static const bool existingActivationTokenReuseAllowed = false;

  static const bool repositoryAttachAuthorized = false;
  static const bool repositoryArmAuthorized = false;
  static const bool firstIncidentWriteAuthorized = false;

  static const bool authorizesSuggestOnly = false;
  static const bool authorizesAuto = false;
}

class AgentSecurityIncidentRoleInventoryMigrationOwnerApproval {
  AgentSecurityIncidentRoleInventoryMigrationOwnerApproval({
    required this.approvalId,
    required this.ownerReferenceSha256,
    required this.currentInventoryFingerprintSha256,
    required this.proposedInventoryFingerprintSha256,
    required this.currentControlFingerprintSha256,
    required this.preconditionEvidenceFingerprintSha256,
    required this.currentGuardRevision,
    required this.proposedGuardRevision,
    required this.approvedAtUtc,
    required this.expiresAtUtc,
    required this.freshOwnerVerifiedAtApproval,
    required this.explicitOwnerApproval,
  }) {
    validate();
  }

  final String approvalId;

  /// Hashed/pseudonymous Owner reference only.
  /// Raw UID/email/phone/token/claims are never stored in this model.
  final String ownerReferenceSha256;

  final String currentInventoryFingerprintSha256;
  final String proposedInventoryFingerprintSha256;
  final String currentControlFingerprintSha256;

  /// Binds the approval to the exact fresh precondition-evidence envelope
  /// captured before approval. It is a SHA-256 only, never raw evidence.
  final String preconditionEvidenceFingerprintSha256;

  final int currentGuardRevision;
  final int proposedGuardRevision;

  final DateTime approvedAtUtc;
  final DateTime expiresAtUtc;

  final bool freshOwnerVerifiedAtApproval;
  final bool explicitOwnerApproval;

  String get operation =>
      AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalContract
          .operation;

  String get currentInventoryVersion =>
      AgentSecurityIncidentRoleInventoryRevisionDesign.currentInventoryVersion;

  String get proposedInventoryVersion =>
      AgentSecurityIncidentRoleInventoryRevisionDesign.proposedInventoryVersion;

  int get currentRoleCount =>
      AgentSecurityIncidentRoleInventoryRevisionDesign.currentRoleCount;

  int get proposedRoleCount =>
      AgentSecurityIncidentRoleInventoryRevisionDesign.proposedRoleCount;

  String get targetRoleId =>
      AgentSecurityIncidentRoleInventoryRevisionDesign.dedicatedRoleId;

  String get targetModule =>
      AgentSecurityIncidentRoleInventoryRevisionDesign.dedicatedModule;

  String get targetActionId =>
      AgentSecurityIncidentRoleInventoryRevisionDesign.attachRuntimeActionId;

  String get requestedRolloutStage =>
      AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalContract
          .requiredRolloutStage;

  bool get proposedRoleEnabled =>
      AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalContract
          .proposedRoleEnabledAtMigration;

  bool get oldGuardImmutable =>
      AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalContract
          .oldGuardImmutable;

  bool get oldArmingTokenImmutable =>
      AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalContract
          .oldArmingTokenImmutable;

  bool get oldActivationReceiptImmutable =>
      AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalContract
          .oldActivationReceiptImmutable;

  bool get existingActivationTokenReuseAllowed =>
      AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalContract
          .existingActivationTokenReuseAllowed;

  bool get repositoryAttachAuthorized =>
      AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalContract
          .repositoryAttachAuthorized;

  bool get repositoryArmAuthorized =>
      AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalContract
          .repositoryArmAuthorized;

  bool get firstIncidentWriteAuthorized =>
      AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalContract
          .firstIncidentWriteAuthorized;

  bool get authorizesSuggestOnly =>
      AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalContract
          .authorizesSuggestOnly;

  bool get authorizesAuto =>
      AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalContract
          .authorizesAuto;

  bool get metadataOnly => true;
  bool get containsRawOwnerIdentity => false;
  bool get containsRawAuthToken => false;
  bool get containsRawClaims => false;
  bool get writesFirestore => false;
  bool get createsCentralApproval => false;
  bool get consumesCentralApproval => false;
  bool get executesMigration => false;
  bool get createsRole => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;

  Map<String, Object> toExactBindingMap() {
    return <String, Object>{
      'operation': operation,
      'approvalId': approvalId.trim(),
      'ownerReferenceSha256': ownerReferenceSha256.toLowerCase(),
      'currentInventoryVersion': currentInventoryVersion,
      'proposedInventoryVersion': proposedInventoryVersion,
      'currentRoleCount': currentRoleCount,
      'proposedRoleCount': proposedRoleCount,
      'currentInventoryFingerprintSha256': currentInventoryFingerprintSha256
          .toLowerCase(),
      'proposedInventoryFingerprintSha256': proposedInventoryFingerprintSha256
          .toLowerCase(),
      'currentControlFingerprintSha256': currentControlFingerprintSha256
          .toLowerCase(),
      'preconditionEvidenceFingerprintSha256':
          preconditionEvidenceFingerprintSha256.toLowerCase(),
      'currentGuardRevision': currentGuardRevision,
      'proposedGuardRevision': proposedGuardRevision,
      'targetRoleId': targetRoleId,
      'targetModule': targetModule,
      'targetActionId': targetActionId,
      'requestedRolloutStage': requestedRolloutStage,
      'proposedRoleEnabled': proposedRoleEnabled,
      'freshOwnerVerifiedAtApproval': freshOwnerVerifiedAtApproval,
      'explicitOwnerApproval': explicitOwnerApproval,
      'approvedAtUtc': approvedAtUtc.toUtc().toIso8601String(),
      'expiresAtUtc': expiresAtUtc.toUtc().toIso8601String(),
      'oldGuardImmutable': oldGuardImmutable,
      'oldArmingTokenImmutable': oldArmingTokenImmutable,
      'oldActivationReceiptImmutable': oldActivationReceiptImmutable,
      'existingActivationTokenReuseAllowed':
          existingActivationTokenReuseAllowed,
      'repositoryAttachAuthorized': repositoryAttachAuthorized,
      'repositoryArmAuthorized': repositoryArmAuthorized,
      'firstIncidentWriteAuthorized': firstIncidentWriteAuthorized,
      'authorizesSuggestOnly': authorizesSuggestOnly,
      'authorizesAuto': authorizesAuto,
    };
  }

  void validate() {
    final RegExp sha256 = RegExp(r'^[A-Fa-f0-9]{64}$');

    if (approvalId.trim().isEmpty ||
        !sha256.hasMatch(ownerReferenceSha256) ||
        !sha256.hasMatch(currentInventoryFingerprintSha256) ||
        !sha256.hasMatch(proposedInventoryFingerprintSha256) ||
        !sha256.hasMatch(currentControlFingerprintSha256) ||
        !sha256.hasMatch(preconditionEvidenceFingerprintSha256)) {
      throw const FormatException(
        'Migration Owner approval contains invalid ID/SHA-256 binding.',
      );
    }

    if (currentInventoryFingerprintSha256.toLowerCase() ==
        proposedInventoryFingerprintSha256.toLowerCase()) {
      throw const FormatException(
        'Current and proposed inventory fingerprints must differ.',
      );
    }

    if (currentGuardRevision < 1 ||
        proposedGuardRevision != currentGuardRevision + 1) {
      throw const FormatException(
        'Migration Owner approval guard revision binding is invalid.',
      );
    }

    if (!approvedAtUtc.isUtc ||
        !expiresAtUtc.isUtc ||
        !expiresAtUtc.isAfter(approvedAtUtc) ||
        expiresAtUtc.difference(approvedAtUtc) >
            AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalContract
                .maxApprovalValidity) {
      throw const FormatException(
        'Migration Owner approval time window is invalid.',
      );
    }

    if (!freshOwnerVerifiedAtApproval || !explicitOwnerApproval) {
      throw const FormatException('Fresh explicit Owner approval is required.');
    }

    if (currentRoleCount != 22 ||
        proposedRoleCount != 23 ||
        proposedRoleCount != currentRoleCount + 1 ||
        requestedRolloutStage != 'MONITOR_ONLY' ||
        targetRoleId != 'security_incident_agent' ||
        targetModule != 'security_incident' ||
        targetActionId != 'security_incident.attach_runtime' ||
        proposedRoleEnabled ||
        !oldGuardImmutable ||
        !oldArmingTokenImmutable ||
        !oldActivationReceiptImmutable ||
        existingActivationTokenReuseAllowed ||
        repositoryAttachAuthorized ||
        repositoryArmAuthorized ||
        firstIncidentWriteAuthorized ||
        authorizesSuggestOnly ||
        authorizesAuto) {
      throw const FormatException(
        'Migration Owner approval violates Phase 66 fail-closed authority.',
      );
    }
  }
}
