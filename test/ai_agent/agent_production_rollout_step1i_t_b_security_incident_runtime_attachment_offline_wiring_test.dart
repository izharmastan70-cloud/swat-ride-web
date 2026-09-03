import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_runtime_attachment_preflight_result.dart';

void main() {
  test('ready status remains only a separate approval-consumption boundary', () {
    const result = AgentSecurityIncidentRuntimeAttachmentPreflightResult(
      status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
          .readyForSeparateApprovalConsumption,
      reasonCode:
          'fresh_owner_permission_runtime_and_central_approval_snapshot_verified',
      freshOwnerVerified: true,
      permissionRequiresApproval: true,
      runtimeRequiresApproval: true,
      centralApprovalSnapshotVerified: true,
    );

    expect(result.readyForSeparateApprovalConsumption, isTrue);
    expect(result.consumesApproval, isFalse);
    expect(result.attachesRuntime, isFalse);
    expect(result.armsRepository, isFalse);
    expect(result.createsIncident, isFalse);
    expect(result.createsIdempotencyReceipt, isFalse);
  });

  test('safe result exposes no raw Firebase identity material', () {
    const result = AgentSecurityIncidentRuntimeAttachmentPreflightResult(
      status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
          .freshOwnerBlocked,
      reasonCode: 'blocked',
      freshOwnerVerified: false,
      permissionRequiresApproval: false,
      runtimeRequiresApproval: false,
      centralApprovalSnapshotVerified: false,
    );

    expect(result.containsRawIdToken, isFalse);
    expect(result.containsUid, isFalse);
    expect(result.containsEmail, isFalse);
    expect(result.containsPhone, isFalse);
    expect(result.containsRawClaims, isFalse);
  });

  test('preflight result cannot create or approve central approval', () {
    const result = AgentSecurityIncidentRuntimeAttachmentPreflightResult(
      status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus.notArmed,
      reasonCode: 'runtime_attachment_preflight_not_armed',
      freshOwnerVerified: false,
      permissionRequiresApproval: false,
      runtimeRequiresApproval: false,
      centralApprovalSnapshotVerified: false,
    );

    expect(result.createsApproval, isFalse);
    expect(result.approvesRequest, isFalse);
    expect(result.consumesApproval, isFalse);
  });

  test('preflight result cannot mutate production rollout authority', () {
    const result = AgentSecurityIncidentRuntimeAttachmentPreflightResult(
      status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
          .approvalMismatch,
      reasonCode: 'mismatch',
      freshOwnerVerified: true,
      permissionRequiresApproval: true,
      runtimeRequiresApproval: true,
      centralApprovalSnapshotVerified: false,
    );

    expect(result.changesRolloutStage, isFalse);
    expect(result.changesAgentMode, isFalse);
    expect(result.changesEmergencyStop, isFalse);
    expect(result.authorizesSuggestOnly, isFalse);
    expect(result.authorizesAuto, isFalse);
  });

  test('approval mismatch is never ready', () {
    const result = AgentSecurityIncidentRuntimeAttachmentPreflightResult(
      status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
          .approvalMismatch,
      reasonCode: 'central_approval_exact_scope_binding_mismatch',
      freshOwnerVerified: true,
      permissionRequiresApproval: true,
      runtimeRequiresApproval: true,
      centralApprovalSnapshotVerified: false,
    );

    expect(result.readyForSeparateApprovalConsumption, isFalse);
  });

  test('plain permission allow is represented as unsafe for this boundary', () {
    expect(
      AgentSecurityIncidentRuntimeAttachmentPreflightStatus
          .approvalRequiredDecisionMissing,
      isNotEmpty,
    );
  });

  test('central approval must remain available and exact-bound', () {
    expect(
      AgentSecurityIncidentRuntimeAttachmentPreflightStatus.approvalUnavailable,
      isNotEmpty,
    );
    expect(
      AgentSecurityIncidentRuntimeAttachmentPreflightStatus.approvalMismatch,
      isNotEmpty,
    );
    expect(
      AgentSecurityIncidentRuntimeAttachmentPreflightStatus.approvalInvalid,
      isNotEmpty,
    );
  });

  test('repository attachment and first incident write remain separate', () {
    const result = AgentSecurityIncidentRuntimeAttachmentPreflightResult(
      status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
          .readyForSeparateApprovalConsumption,
      reasonCode: 'ready',
      freshOwnerVerified: true,
      permissionRequiresApproval: true,
      runtimeRequiresApproval: true,
      centralApprovalSnapshotVerified: true,
    );

    expect(result.instantiatesRepository, isFalse);
    expect(result.attachesRuntime, isFalse);
    expect(result.armsRepository, isFalse);
    expect(result.createsIncident, isFalse);
    expect(result.updatesIncident, isFalse);
  });
}
