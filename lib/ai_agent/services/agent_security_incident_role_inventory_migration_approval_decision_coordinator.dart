import 'dart:convert';

import '../models/agent_approval_request.dart';
import '../models/agent_security_incident_fresh_owner_claim_verification_result.dart';
import '../models/agent_security_incident_role_inventory_migration_approval_decision_authorization.dart';
import '../models/agent_security_incident_role_inventory_migration_central_approval_request.dart';
import 'agent_approval_service.dart';
import 'agent_security_incident_fresh_owner_claim_verification_service.dart';
import 'agent_security_incident_role_inventory_migration_approval_decision_policy.dart';
import 'agent_security_incident_role_inventory_migration_central_approval_gateway.dart';

typedef AgentSecurityIncidentMigrationFreshOwnerVerifier =
    Future<AgentSecurityIncidentFreshOwnerClaimVerificationResult> Function(
      String currentAdminId,
    );

class AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionCoordinator {
  AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionCoordinator({
    required this.gateway,
    required this.freshOwnerVerifier,
    this.decisionPolicy =
        const AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionPolicy(),
    this.executionArmed = false,
  });

  factory AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionCoordinator.live({
    bool executionArmed = false,
  }) {
    final AgentApprovalService approvalService = AgentApprovalService();

    final AgentSecurityIncidentFreshOwnerClaimVerificationService
    freshOwnerService =
        AgentSecurityIncidentFreshOwnerClaimVerificationService();

    return AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionCoordinator(
      gateway:
          AgentSecurityIncidentRoleInventoryMigrationCentralApprovalGatewayAdapter(
            approvalService: approvalService,
          ),
      freshOwnerVerifier: (String currentAdminId) {
        return freshOwnerService.verify(currentAdminId: currentAdminId);
      },
      executionArmed: executionArmed,
    );
  }

  final AgentSecurityIncidentRoleInventoryMigrationCentralApprovalGateway
  gateway;

  final AgentSecurityIncidentMigrationFreshOwnerVerifier freshOwnerVerifier;

  final AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionPolicy
  decisionPolicy;

  /// Fail-closed default. A future dedicated UI/runtime boundary must
  /// explicitly arm this coordinator before APPROVE/REJECT mutation.
  final bool executionArmed;

  Stream<List<AgentApprovalRequest>> watchExactPending({
    required AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest
    expected,
  }) {
    expected.validate();

    return gateway.watchPendingRequests().map(
      (List<AgentApprovalRequest> items) => items
          .where(
            (AgentApprovalRequest item) =>
                _matchesExpected(observed: item, expected: expected),
          )
          .toList(growable: false),
    );
  }

  Future<
    AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAuthorization
  >
  approveObserved({
    required AgentApprovalRequest observed,
    required AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest
    expected,
    required String currentAdminId,
  }) async {
    return _decideObserved(
      observed: observed,
      expected: expected,
      currentAdminId: currentAdminId,
      decisionAction:
          AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
              .approve,
    );
  }

  Future<
    AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAuthorization
  >
  rejectObserved({
    required AgentApprovalRequest observed,
    required AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest
    expected,
    required String currentAdminId,
  }) async {
    return _decideObserved(
      observed: observed,
      expected: expected,
      currentAdminId: currentAdminId,
      decisionAction:
          AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAction
              .reject,
    );
  }

  Future<
    AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAuthorization
  >
  _decideObserved({
    required AgentApprovalRequest observed,
    required AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest
    expected,
    required String currentAdminId,
    required String decisionAction,
  }) async {
    if (!executionArmed) {
      throw StateError(
        'Migration approval decision coordinator is not execution-armed.',
      );
    }

    expected.validate();
    observed.validate();

    if (!_matchesExpected(observed: observed, expected: expected)) {
      throw const FormatException(
        'Observed central approval does not exactly match migration request.',
      );
    }

    if (!observed.isPending ||
        observed.isExpiredNow ||
        observed.consumedAt != null) {
      throw StateError(
        'Observed migration central approval is not fresh PENDING/unconsumed.',
      );
    }

    final AgentSecurityIncidentFreshOwnerClaimVerificationResult
    freshOwnerVerification = await freshOwnerVerifier(currentAdminId);

    final AgentSecurityIncidentRoleInventoryMigrationApprovalDecisionAuthorization
    authorization = decisionPolicy.evaluate(
      request: expected,
      freshOwnerVerification: freshOwnerVerification,
      currentAdminId: currentAdminId,
      decisionAction: decisionAction,
    );

    if (!authorization.allowed) {
      throw StateError(
        'Fresh Owner migration approval decision blocked: '
        '${authorization.reasonCode}',
      );
    }

    final String decidedBy =
        'phase66_owner_sha256:${authorization.ownerApproverReferenceSha256}';

    if (authorization.mayCallCentralApprove) {
      await gateway.approve(
        approvalId: observed.approvalId,
        decidedBy: decidedBy,
      );
    } else if (authorization.mayCallCentralReject) {
      await gateway.reject(
        approvalId: observed.approvalId,
        decidedBy: decidedBy,
      );
    } else {
      throw StateError(
        'Authorized migration decision exposes no APPROVE/REJECT call.',
      );
    }

    return authorization;
  }

  bool _matchesExpected({
    required AgentApprovalRequest observed,
    required AgentSecurityIncidentRoleInventoryMigrationCentralApprovalRequest
    expected,
  }) {
    if (observed.roleId != expected.roleId ||
        observed.actionId != expected.actionId ||
        observed.module != expected.module ||
        observed.reason != expected.reason ||
        observed.risk != expected.risk ||
        observed.requestedBy != expected.requestedBy) {
      return false;
    }

    if (_canonicalJson(observed.actionScope) !=
        _canonicalJson(expected.actionScope)) {
      return false;
    }

    final Duration validity = observed.expiresAt.difference(observed.createdAt);

    return validity > Duration.zero &&
        validity <= expected.validity &&
        observed.decidedAt == null &&
        observed.decidedBy == null &&
        observed.decisionNote == null;
  }

  String _canonicalJson(Map<String, dynamic> source) {
    return jsonEncode(_canonicalize(source));
  }

  Object? _canonicalize(Object? value) {
    if (value is Map) {
      final List<String> keys =
          value.keys.map((Object? key) => key.toString()).toList()..sort();

      return <String, Object?>{
        for (final String key in keys) key: _canonicalize(value[key]),
      };
    }

    if (value is List) {
      return value.map<Object?>(_canonicalize).toList(growable: false);
    }

    return value;
  }

  bool get defaultFailClosed => !executionArmed;
  bool get createsCentralApproval => false;
  bool get consumesCentralApproval => false;
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
}
