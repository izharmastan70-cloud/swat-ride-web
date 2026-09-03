import 'agent_security_incident_role_inventory_migration_plan.dart';

class AgentSecurityIncidentRoleInventoryTransactionRequest {
  const AgentSecurityIncidentRoleInventoryTransactionRequest({
    required this.plan,
    required this.migrationIdSha256,
    required this.ownerApprovalId,
    required this.actorReferenceSha256,
    required this.expectedAuthorityManifestRevision,
    required this.proposedRolePayload,
  });

  final AgentSecurityIncidentRoleInventoryMigrationPlan plan;

  /// Idempotency/migration binding only. No raw token is stored here.
  final String migrationIdSha256;

  /// Reference to the separately approved Owner authorization.
  final String ownerApprovalId;

  /// Pseudonymous audit actor reference.
  final String actorReferenceSha256;

  /// Optimistic-concurrency revision for the role inventory authority manifest.
  final int expectedAuthorityManifestRevision;

  /// The exact proposed persisted role payload. The repository validates all
  /// security-sensitive fields again inside the Firestore transaction.
  final Map<String, dynamic> proposedRolePayload;

  void validate() {
    if (!_looksLikeSha256(migrationIdSha256) ||
        !_looksLikeSha256(actorReferenceSha256)) {
      throw const FormatException(
        'Migration id and actor reference must be SHA-256 values.',
      );
    }

    if (ownerApprovalId.trim().isEmpty) {
      throw const FormatException('Owner approval id is required.');
    }

    if (expectedAuthorityManifestRevision < 1) {
      throw const FormatException(
        'Existing role inventory authority manifest revision is required.',
      );
    }

    if (proposedRolePayload.isEmpty) {
      throw const FormatException('Proposed role payload is required.');
    }
  }

  bool _looksLikeSha256(String value) {
    final String normalized = value.trim().toLowerCase();
    return normalized.length == 64 &&
        RegExp(r'^[0-9a-f]{64}$').hasMatch(normalized);
  }

  bool get containsRawOwnerToken => false;
  bool get containsRawArmingToken => false;
  bool get containsRawFirebaseIdToken => false;
}
