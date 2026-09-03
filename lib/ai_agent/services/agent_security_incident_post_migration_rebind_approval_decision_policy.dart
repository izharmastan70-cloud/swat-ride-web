import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/agent_approval_request.dart';
import '../models/agent_security_incident_fresh_owner_claim_verification_result.dart';
import '../models/agent_security_incident_post_migration_rebind_approval_decision_authorization.dart';
import '../models/agent_security_incident_post_migration_rebind_owner_approval.dart';

class AgentSecurityIncidentPostMigrationRebindApprovalDecisionPolicy {
  const AgentSecurityIncidentPostMigrationRebindApprovalDecisionPolicy();

  static const String historicalMigrationApprovalId =
      'phase66-migration-9e2c7bb01a054a61eb81b850b4015825';

  static const String historicalMigrationOperation =
      'MIGRATE_SECURITY_INCIDENT_ROLE_INVENTORY_22_TO_23';

  static const String exactReason =
      'Owner approval required for exact 23-role post-migration Security '
      'Incident authority rebind only; role enable and migration-hold release '
      'remain unauthorized.';

  static const Set<String> _exactScopeKeys = <String>{
    'operation',
    'postMigrationSnapshotSha256',
    'roleInventoryFingerprintSha256',
    'postMigrationControlStateFingerprintSha256',
    'rebindPlanFingerprintSha256',
    'roleCount',
    'currentAuthorityManifestRevision',
    'targetAuthorityManifestRevision',
    'currentGuardRevision',
    'targetGuardRevision',
    'targetRoleId',
    'targetModule',
    'targetActionId',
    'requestedRolloutStage',
    'migrationApprovalId',
    'freshOwnerVerifiedAtApproval',
    'explicitOwnerApproval',
    'selfApprovalAllowed',
    'migrationApprovalReuseAllowed',
    'oldArmingTokenReuseAllowed',
    'roleEnableAuthorized',
    'migrationHoldReleaseAuthorized',
    'repositoryAttachAuthorized',
    'repositoryArmAuthorized',
    'firstIncidentWriteAuthorized',
    'authorizesSuggestOnly',
    'authorizesAuto',
  };

  bool matchesExactPendingRequest(AgentApprovalRequest request) {
    if (!request.isPending ||
        request.isExpiredNow ||
        request.consumedAt != null ||
        request.decidedAt != null ||
        request.decidedBy != null ||
        request.decisionNote != null) {
      return false;
    }

    if (request.roleId !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .targetRoleId ||
        request.actionId !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .targetActionId ||
        request.module !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .targetModule ||
        request.reason != exactReason ||
        request.risk != 'CRITICAL') {
      return false;
    }

    final RegExp requester = RegExp(
      r'^phase66_rebind_coordinator_sha256:([a-f0-9]{64})$',
    );

    if (!requester.hasMatch(request.requestedBy)) {
      return false;
    }

    final Duration validity = request.expiresAt.difference(request.createdAt);

    if (validity !=
        AgentSecurityIncidentPostMigrationRebindApprovalContract
            .maxApprovalValidity) {
      return false;
    }

    final Map<String, dynamic> scope = request.actionScope;

    if (scope.keys.toSet().length != _exactScopeKeys.length ||
        !scope.keys.toSet().containsAll(_exactScopeKeys) ||
        !_exactScopeKeys.containsAll(scope.keys.toSet())) {
      return false;
    }

    if (scope['operation'] !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .operation ||
        scope['postMigrationSnapshotSha256']?.toString().toLowerCase() !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .lockedPostMigrationSnapshotSha256 ||
        scope['roleInventoryFingerprintSha256']?.toString().toLowerCase() !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .lockedRoleInventoryFingerprintSha256 ||
        !_isSha256(scope['postMigrationControlStateFingerprintSha256']) ||
        !_isSha256(scope['rebindPlanFingerprintSha256']) ||
        _asInt(scope['roleCount']) !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .roleCount ||
        _asInt(scope['currentAuthorityManifestRevision']) !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .currentAuthorityManifestRevision ||
        _asInt(scope['targetAuthorityManifestRevision']) !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .targetAuthorityManifestRevision ||
        _asInt(scope['currentGuardRevision']) !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .currentGuardRevision ||
        _asInt(scope['targetGuardRevision']) !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .targetGuardRevision ||
        scope['targetRoleId'] !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .targetRoleId ||
        scope['targetModule'] !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .targetModule ||
        scope['targetActionId'] !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .targetActionId ||
        scope['requestedRolloutStage'] !=
            AgentSecurityIncidentPostMigrationRebindApprovalContract
                .targetRolloutStage ||
        scope['migrationApprovalId'] != historicalMigrationApprovalId ||
        scope['freshOwnerVerifiedAtApproval'] != true ||
        scope['explicitOwnerApproval'] != true ||
        scope['selfApprovalAllowed'] != false ||
        scope['migrationApprovalReuseAllowed'] != false ||
        scope['oldArmingTokenReuseAllowed'] != false ||
        scope['roleEnableAuthorized'] != false ||
        scope['migrationHoldReleaseAuthorized'] != false ||
        scope['repositoryAttachAuthorized'] != false ||
        scope['repositoryArmAuthorized'] != false ||
        scope['firstIncidentWriteAuthorized'] != false ||
        scope['authorizesSuggestOnly'] != false ||
        scope['authorizesAuto'] != false) {
      return false;
    }

    return true;
  }

  AgentSecurityIncidentPostMigrationRebindApprovalDecisionAuthorization
  evaluate({
    required AgentApprovalRequest request,
    required AgentApprovalRequest historicalMigrationApproval,
    required AgentSecurityIncidentFreshOwnerClaimVerificationResult
    freshOwnerVerification,
    required String currentAdminId,
    required String decisionAction,
  }) {
    if (currentAdminId.trim().isEmpty) {
      return _deny('current_admin_id_required', decisionAction);
    }

    if (!AgentSecurityIncidentPostMigrationRebindApprovalDecisionAction.values
        .contains(decisionAction)) {
      return _deny('invalid_rebind_approval_decision_action', decisionAction);
    }

    if (!matchesExactPendingRequest(request)) {
      return _deny(
        'pending_rebind_approval_exact_scope_mismatch',
        decisionAction,
      );
    }

    final String? historicalOwnerSha = _historicalOwnerSha(
      historicalMigrationApproval,
    );

    if (historicalOwnerSha == null) {
      return _deny(
        'historical_consumed_migration_owner_evidence_invalid',
        decisionAction,
      );
    }

    if (!freshOwnerVerification.verified ||
        !freshOwnerVerification.superAdminAccessVerified ||
        !freshOwnerVerification.roleClaimVerified ||
        !freshOwnerVerification.uidBindingVerified ||
        !freshOwnerVerification.customClaimSourceVerified ||
        !freshOwnerVerification.freshLoginVerified ||
        freshOwnerVerification.boundedAuthAgeSeconds == null ||
        freshOwnerVerification.boundedAuthAgeSeconds! < 0 ||
        freshOwnerVerification.boundedAuthAgeSeconds! > 300) {
      return _deny('fresh_owner_verification_required', decisionAction);
    }

    final String currentOwnerSha = sha256
        .convert(utf8.encode(currentAdminId.trim()))
        .toString();

    if (currentOwnerSha != historicalOwnerSha) {
      return _deny('fresh_owner_reference_mismatch', decisionAction);
    }

    final RegExp requester = RegExp(
      r'^phase66_rebind_coordinator_sha256:([a-f0-9]{64})$',
    );

    final Match? requesterMatch = requester.firstMatch(request.requestedBy);

    if (requesterMatch == null ||
        requesterMatch.group(1) == historicalOwnerSha) {
      return _deny(
        'rebind_requester_owner_separation_violation',
        decisionAction,
      );
    }

    return AgentSecurityIncidentPostMigrationRebindApprovalDecisionAuthorization(
      allowed: true,
      reasonCode: 'fresh_exact_owner_rebind_decision_authorized',
      decisionAction: decisionAction,
      ownerApproverReferenceSha256: historicalOwnerSha,
      ownerAuthAgeSeconds: freshOwnerVerification.boundedAuthAgeSeconds,
    );
  }

  String? _historicalOwnerSha(AgentApprovalRequest approval) {
    if (approval.approvalId != historicalMigrationApprovalId ||
        !approval.isConsumed ||
        approval.consumedAt == null ||
        approval.decidedAt == null ||
        approval.decidedBy == null) {
      return null;
    }

    final Map<String, dynamic> scope = approval.actionScope;

    if (scope['operation'] != historicalMigrationOperation) {
      return null;
    }

    final String ownerSha =
        scope['ownerApproverReferenceSha256']?.toString().toLowerCase() ?? '';

    if (!_isSha256(ownerSha)) {
      return null;
    }

    if (approval.decidedBy != 'phase66_owner_sha256:$ownerSha') {
      return null;
    }

    return ownerSha;
  }

  bool _isSha256(Object? value) {
    return RegExp(
      r'^[a-fA-F0-9]{64}$',
    ).hasMatch(value?.toString().trim() ?? '');
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  AgentSecurityIncidentPostMigrationRebindApprovalDecisionAuthorization _deny(
    String reasonCode,
    String decisionAction,
  ) {
    return AgentSecurityIncidentPostMigrationRebindApprovalDecisionAuthorization(
      allowed: false,
      reasonCode: reasonCode,
      decisionAction: decisionAction,
      ownerApproverReferenceSha256: '',
      ownerAuthAgeSeconds: null,
    );
  }

  bool get pureDecisionPolicy => true;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get executesRebind => false;
  bool get createsFreshToken => false;
  bool get createsRebindReceipt => false;
  bool get enablesRole => false;
  bool get releasesMigrationHold => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
