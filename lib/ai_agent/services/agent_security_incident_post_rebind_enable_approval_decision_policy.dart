import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/agent_approval_request.dart';
import '../models/agent_security_incident_fresh_owner_claim_verification_result.dart';
import '../models/agent_security_incident_post_rebind_enable_approval_decision_authorization.dart';
import '../models/agent_security_incident_post_rebind_enable_execution_contract.dart';
import 'agent_security_incident_post_migration_rebind_approval_decision_policy.dart';

class AgentSecurityIncidentPostRebindEnableApprovalDecisionPolicy {
  const AgentSecurityIncidentPostRebindEnableApprovalDecisionPolicy();

  static const Duration maxApprovalValidity = Duration(minutes: 15);

  static const String exactReason =
      'Owner approval required for exact post-rebind security_incident_agent '
      'enable plus migration-hold release under MONITOR_ONLY; replacement token '
      'must be consumed atomically and repository attach/arm remain unauthorized.';

  static const Set<String> _exactScopeKeys = <String>{
    'operation',
    'roleId',
    'module',
    'actionId',
    'rolloutStage',
    'roleCount',
    'authorityManifestRevision',
    'guardRevision',
    'rebindReceiptIdSha256',
    'replacementTokenIdSha256',
    'freshOwnerVerifiedAtApproval',
    'explicitOwnerApproval',
    'selfApprovalAllowed',
    'migrationApprovalReuseAllowed',
    'rebindApprovalReuseAllowed',
    'oldArmingTokenReuseAllowed',
    'replacementTokenConsumeAuthorized',
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
            AgentSecurityIncidentPostRebindEnableExecutionContract.roleId ||
        request.actionId !=
            AgentSecurityIncidentPostRebindEnableExecutionContract
                .targetActionId ||
        request.module !=
            AgentSecurityIncidentPostRebindEnableExecutionContract.module ||
        request.reason != exactReason ||
        request.risk != 'HIGH') {
      return false;
    }

    final RegExp requester = RegExp(
      r'^phase66_enable_coordinator_sha256:([a-f0-9]{64})$',
    );

    if (!requester.hasMatch(request.requestedBy)) {
      return false;
    }

    if (request.expiresAt.difference(request.createdAt) !=
        maxApprovalValidity) {
      return false;
    }

    final Map<String, dynamic> scope = request.actionScope;
    final Set<String> keys = scope.keys.toSet();

    if (keys.length != _exactScopeKeys.length ||
        !keys.containsAll(_exactScopeKeys) ||
        !_exactScopeKeys.containsAll(keys)) {
      return false;
    }

    if (scope['operation'] !=
            AgentSecurityIncidentPostRebindEnableExecutionContract
                .enableOperation ||
        scope['roleId'] !=
            AgentSecurityIncidentPostRebindEnableExecutionContract.roleId ||
        scope['module'] !=
            AgentSecurityIncidentPostRebindEnableExecutionContract.module ||
        scope['actionId'] !=
            AgentSecurityIncidentPostRebindEnableExecutionContract
                .targetActionId ||
        scope['rolloutStage'] !=
            AgentSecurityIncidentPostRebindEnableExecutionContract
                .rolloutStage ||
        _asInt(scope['roleCount']) !=
            AgentSecurityIncidentPostRebindEnableExecutionContract.roleCount ||
        _asInt(scope['authorityManifestRevision']) !=
            AgentSecurityIncidentPostRebindEnableExecutionContract
                .authorityManifestRevision ||
        _asInt(scope['guardRevision']) !=
            AgentSecurityIncidentPostRebindEnableExecutionContract
                .guardRevision ||
        !_isSha256(scope['rebindReceiptIdSha256']) ||
        !_isSha256(scope['replacementTokenIdSha256']) ||
        scope['freshOwnerVerifiedAtApproval'] != true ||
        scope['explicitOwnerApproval'] != true ||
        scope['selfApprovalAllowed'] != false ||
        scope['migrationApprovalReuseAllowed'] != false ||
        scope['rebindApprovalReuseAllowed'] != false ||
        scope['oldArmingTokenReuseAllowed'] != false ||
        scope['replacementTokenConsumeAuthorized'] != true ||
        scope['roleEnableAuthorized'] != true ||
        scope['migrationHoldReleaseAuthorized'] != true ||
        scope['repositoryAttachAuthorized'] != false ||
        scope['repositoryArmAuthorized'] != false ||
        scope['firstIncidentWriteAuthorized'] != false ||
        scope['authorizesSuggestOnly'] != false ||
        scope['authorizesAuto'] != false) {
      return false;
    }

    return true;
  }

  AgentSecurityIncidentPostRebindEnableApprovalDecisionAuthorization evaluate({
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

    if (!AgentSecurityIncidentPostRebindEnableApprovalDecisionAction.values
        .contains(decisionAction)) {
      return _deny('invalid_enable_approval_decision_action', decisionAction);
    }

    if (!matchesExactPendingRequest(request)) {
      return _deny(
        'pending_enable_approval_exact_scope_mismatch',
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

    final Match? requesterMatch = RegExp(
      r'^phase66_enable_coordinator_sha256:([a-f0-9]{64})$',
    ).firstMatch(request.requestedBy);

    if (requesterMatch == null ||
        requesterMatch.group(1) == historicalOwnerSha) {
      return _deny(
        'enable_requester_owner_separation_violation',
        decisionAction,
      );
    }

    return AgentSecurityIncidentPostRebindEnableApprovalDecisionAuthorization(
      allowed: true,
      reasonCode: 'fresh_exact_owner_enable_decision_authorized',
      decisionAction: decisionAction,
      ownerApproverReferenceSha256: historicalOwnerSha,
      ownerAuthAgeSeconds: freshOwnerVerification.boundedAuthAgeSeconds,
    );
  }

  String? _historicalOwnerSha(AgentApprovalRequest approval) {
    if (approval.approvalId !=
            AgentSecurityIncidentPostMigrationRebindApprovalDecisionPolicy
                .historicalMigrationApprovalId ||
        !approval.isConsumed ||
        approval.consumedAt == null ||
        approval.decidedAt == null ||
        approval.decidedBy == null) {
      return null;
    }

    final Map<String, dynamic> scope = approval.actionScope;

    if (scope['operation'] !=
        AgentSecurityIncidentPostMigrationRebindApprovalDecisionPolicy
            .historicalMigrationOperation) {
      return null;
    }

    final String ownerSha =
        scope['ownerApproverReferenceSha256']?.toString().toLowerCase() ?? '';

    if (!_isSha256(ownerSha) ||
        approval.decidedBy != 'phase66_owner_sha256:$ownerSha') {
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

  AgentSecurityIncidentPostRebindEnableApprovalDecisionAuthorization _deny(
    String reasonCode,
    String decisionAction,
  ) {
    return AgentSecurityIncidentPostRebindEnableApprovalDecisionAuthorization(
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
