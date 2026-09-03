import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/agent_security_incident_role_inventory_migration_approval_handoff.dart';
import '../models/agent_security_incident_role_inventory_migration_central_approval_request.dart';
import '../models/agent_security_incident_role_inventory_migration_owner_approval.dart';
import 'agent_security_incident_role_inventory_migration_owner_approval_policy.dart';

class AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequestPolicy {
  const AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequestPolicy({
    this.ownerApprovalPolicy =
        const AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalPolicy(),
  });

  final AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalPolicy
  ownerApprovalPolicy;

  AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest prepare({
    required AgentSecurityIncidentRoleInventoryMigrationOwnerApproval approval,
    required AgentSecurityIncidentRoleInventoryMigrationApprovalHandoff handoff,
    required DateTime nowUtc,
  }) {
    handoff.validate();

    final decision = ownerApprovalPolicy.evaluate(
      approval: approval,
      nowUtc: nowUtc,
    );

    if (!decision.valid) {
      throw FormatException(
        'Migration approval is not request-ready: ${decision.reasonCode}',
      );
    }

    if (handoff.bindingFingerprintSha256.toLowerCase() !=
            decision.bindingFingerprintSha256.toLowerCase() ||
        handoff.roleId != approval.targetRoleId ||
        handoff.actionId != approval.targetActionId ||
        handoff.module != approval.targetModule) {
      throw const FormatException(
        'T-AC handoff does not exactly bind the T-AB approval.',
      );
    }

    final String coordinatorDigest = sha256
        .convert(
          utf8.encode(
            'PHASE66_MIGRATION_COORDINATOR|'
            '${decision.bindingFingerprintSha256.toLowerCase()}',
          ),
        )
        .toString();

    final String requesterReference =
        'phase66_migration_coordinator_sha256:$coordinatorDigest';

    final Map<String, dynamic> exactScope =
        Map<String, dynamic>.from(handoff.actionScope)
          ..remove('freshOwnerVerifiedAtApproval')
          ..remove('explicitOwnerApproval')
          ..addAll(<String, dynamic>{
            'requestPrincipal': 'PHASE66_MIGRATION_COORDINATOR',
            'ownerApproverReferenceSha256': approval.ownerReferenceSha256
                .toLowerCase(),
            'selfApprovalAllowed': false,
          });

    final request =
        AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest(
          roleId: handoff.roleId,
          actionId: handoff.actionId,
          module: handoff.module,
          reason: handoff.reason,
          risk: handoff.risk,
          requestedBy: requesterReference,
          ownerApproverReferenceSha256: approval.ownerReferenceSha256
              .toLowerCase(),
          actionScope: exactScope,
          validity: handoff.validity,
          bindingFingerprintSha256: decision.bindingFingerprintSha256
              .toLowerCase(),
        );

    request.validate();
    return request;
  }

  bool get callsCentralApprovalService => false;
  bool get writesFirestore => false;
  bool get createsCentralApproval => false;
  bool get approvesCentralApproval => false;
  bool get consumesCentralApproval => false;
  bool get executesMigration => false;
  bool get createsRole => false;
  bool get mutatesGuard => false;
  bool get createsArmingToken => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
