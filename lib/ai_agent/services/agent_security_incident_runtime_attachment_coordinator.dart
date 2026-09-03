import '../models/agent_approval_request.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import '../models/agent_security_incident_persisted_role_resolution_result.dart';
import '../models/agent_security_incident_runtime_attachment_preflight_result.dart';
import 'agent_approval_service.dart';
import 'agent_permission_engine.dart';
import 'agent_runtime_gate.dart';
import 'agent_security_incident_fresh_owner_claim_verification_service.dart';
import 'agent_security_incident_persisted_role_resolver.dart';

/// Phase 66 Step1I-T-B, hardened by Step1I-T-I.
///
/// Guarded authorization wiring for a future Security Incident runtime
/// attachment boundary.
///
/// IMPORTANT:
/// - default is NOT armed;
/// - caller-supplied AgentRole is NOT accepted;
/// - role authority is re-read from AgentRoleService through the dedicated
///   persisted-role resolver;
/// - this class never creates/approves/consumes an approval;
/// - this class never instantiates or arms AgentSecurityIncidentRepository;
/// - this class never writes an incident or idempotency receipt;
/// - the first incident write remains a separate later boundary;
/// - MONITOR_ONLY rollout is not changed by this class.
class AgentSecurityIncidentRuntimeAttachmentCoordinator {
  AgentSecurityIncidentRuntimeAttachmentCoordinator({
    required this.freshOwnerClaimService,
    required this.persistedRoleResolver,
    required this.approvalService,
    this.permissionEngine = const AgentPermissionEngine(),
    this.runtimeGate = const AgentRuntimeGate(),
    this.preflightExecutionArmed = false,
  });

  final AgentSecurityIncidentFreshOwnerClaimVerificationService
  freshOwnerClaimService;

  final AgentSecurityIncidentPersistedRoleResolver persistedRoleResolver;

  final AgentApprovalService approvalService;
  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;

  /// This is a preflight-read gate only.
  /// It is NOT repository executionArmed and grants no persistence authority.
  final bool preflightExecutionArmed;

  Future<AgentSecurityIncidentRuntimeAttachmentPreflightResult> evaluate({
    required String currentAdminId,
    required AgentMasterSettings settings,
    required String actionId,
    required String approvalId,
    required String expectedApprovalModule,
    required Map<String, dynamic> expectedApprovalScope,
  }) async {
    if (!preflightExecutionArmed) {
      return _blocked(
        status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus.notArmed,
        reasonCode: 'runtime_attachment_preflight_not_armed',
      );
    }

    final String normalizedActionId = actionId.trim();
    final String normalizedApprovalId = approvalId.trim();
    final String normalizedModule = expectedApprovalModule.trim();

    if (currentAdminId.trim().isEmpty ||
        normalizedActionId.isEmpty ||
        normalizedApprovalId.isEmpty ||
        normalizedModule.isEmpty) {
      return _blocked(
        status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
            .approvalMismatch,
        reasonCode: 'runtime_attachment_preflight_binding_invalid',
      );
    }

    // Actual execution must re-run the live five-minute Owner/Super Admin
    // custom-claim verification. A previous verification is not reused.
    final freshOwner = await freshOwnerClaimService.verify(
      currentAdminId: currentAdminId,
    );

    if (!freshOwner.verified ||
        !freshOwner.superAdminAccessVerified ||
        !freshOwner.roleClaimVerified ||
        !freshOwner.uidBindingVerified ||
        !freshOwner.customClaimSourceVerified ||
        !freshOwner.freshLoginVerified) {
      return AgentSecurityIncidentRuntimeAttachmentPreflightResult(
        status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
            .freshOwnerBlocked,
        reasonCode: freshOwner.reasonCode,
        freshOwnerVerified: false,
        permissionRequiresApproval: false,
        runtimeRequiresApproval: false,
        centralApprovalSnapshotVerified: false,
      );
    }

    // Step1I-T-I:
    // Never accept AgentRole from a caller. Re-read the exact persisted role
    // through AgentRoleService and validate the versioned least-privilege
    // contract before Permission Engine or Runtime Gate sees it.
    final AgentSecurityIncidentPersistedRoleResolutionResult roleResolution =
        await persistedRoleResolver.resolve();

    final AgentRole? role = roleResolution.role;

    if (!roleResolution.verified || role == null) {
      return AgentSecurityIncidentRuntimeAttachmentPreflightResult(
        status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
            .persistedRoleBlocked,
        reasonCode: roleResolution.reasonCode,
        freshOwnerVerified: true,
        permissionRequiresApproval: false,
        runtimeRequiresApproval: false,
        centralApprovalSnapshotVerified: false,
      );
    }

    // Permission is derived only from the freshly resolved persisted role.
    final AgentPermissionDecision permission = permissionEngine.evaluate(
      role: role,
      actionId: normalizedActionId,
    );

    if (permission.isDenied) {
      return AgentSecurityIncidentRuntimeAttachmentPreflightResult(
        status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
            .permissionBlocked,
        reasonCode: permission.reason,
        freshOwnerVerified: true,
        permissionRequiresApproval: false,
        runtimeRequiresApproval: false,
        centralApprovalSnapshotVerified: false,
      );
    }

    // This sensitive boundary MUST resolve to REQUIRE_APPROVAL.
    // A plain ALLOW is rejected rather than silently escalating authority.
    if (!permission.needsApproval) {
      return AgentSecurityIncidentRuntimeAttachmentPreflightResult(
        status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
            .approvalRequiredDecisionMissing,
        reasonCode:
            'security_incident_runtime_attachment_must_require_approval',
        freshOwnerVerified: true,
        permissionRequiresApproval: false,
        runtimeRequiresApproval: false,
        centralApprovalSnapshotVerified: false,
      );
    }

    // Pass the exact central Permission result and the SAME freshly resolved
    // persisted role through the existing Runtime Gate.
    final AgentPermissionDecision runtime = runtimeGate.apply(
      settings: settings,
      role: role,
      permissionDecision: permission,
    );

    if (runtime.isDenied) {
      return AgentSecurityIncidentRuntimeAttachmentPreflightResult(
        status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
            .runtimeBlocked,
        reasonCode: runtime.reason,
        freshOwnerVerified: true,
        permissionRequiresApproval: true,
        runtimeRequiresApproval: false,
        centralApprovalSnapshotVerified: false,
      );
    }

    if (!runtime.needsApproval || runtime.isAllowed) {
      return AgentSecurityIncidentRuntimeAttachmentPreflightResult(
        status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
            .approvalRequiredDecisionMissing,
        reasonCode: 'runtime_gate_must_preserve_sensitive_approval_requirement',
        freshOwnerVerified: true,
        permissionRequiresApproval: true,
        runtimeRequiresApproval: false,
        centralApprovalSnapshotVerified: false,
      );
    }

    // Read the current central Approval authority.
    // We intentionally do NOT consume it in Step1I-T-I.
    final AgentApprovalRequest? approval = await approvalService.getRequest(
      normalizedApprovalId,
    );

    if (approval == null) {
      return AgentSecurityIncidentRuntimeAttachmentPreflightResult(
        status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
            .approvalUnavailable,
        reasonCode: 'central_approval_not_found',
        freshOwnerVerified: true,
        permissionRequiresApproval: true,
        runtimeRequiresApproval: true,
        centralApprovalSnapshotVerified: false,
      );
    }

    try {
      approval.validate();
    } catch (_) {
      return AgentSecurityIncidentRuntimeAttachmentPreflightResult(
        status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
            .approvalInvalid,
        reasonCode: 'central_approval_validation_failed',
        freshOwnerVerified: true,
        permissionRequiresApproval: true,
        runtimeRequiresApproval: true,
        centralApprovalSnapshotVerified: false,
      );
    }

    if (!approval.canBeConsumed) {
      return AgentSecurityIncidentRuntimeAttachmentPreflightResult(
        status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
            .approvalUnavailable,
        reasonCode: 'central_approval_not_approved_unexpired_unconsumed',
        freshOwnerVerified: true,
        permissionRequiresApproval: true,
        runtimeRequiresApproval: true,
        centralApprovalSnapshotVerified: false,
      );
    }

    final bool exactApprovalBinding =
        approval.roleId == role.roleId &&
        approval.actionId == normalizedActionId &&
        approval.module == normalizedModule &&
        _deepEquals(approval.actionScope, expectedApprovalScope);

    if (!exactApprovalBinding) {
      return AgentSecurityIncidentRuntimeAttachmentPreflightResult(
        status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
            .approvalMismatch,
        reasonCode: 'central_approval_exact_scope_binding_mismatch',
        freshOwnerVerified: true,
        permissionRequiresApproval: true,
        runtimeRequiresApproval: true,
        centralApprovalSnapshotVerified: false,
      );
    }

    // READY means only:
    // a separate later execution boundary MAY attempt one-time central approval
    // consumption after ANOTHER exact-state, persisted-role, and fresh-Owner
    // check.
    //
    // It does NOT mean repository attachment, repository arming, persistence,
    // rollout advancement, SUGGEST_ONLY, or AUTO.
    return const AgentSecurityIncidentRuntimeAttachmentPreflightResult(
      status: AgentSecurityIncidentRuntimeAttachmentPreflightStatus
          .readyForSeparateApprovalConsumption,
      reasonCode:
          'fresh_owner_persisted_role_permission_runtime_and_central_approval_snapshot_verified',
      freshOwnerVerified: true,
      permissionRequiresApproval: true,
      runtimeRequiresApproval: true,
      centralApprovalSnapshotVerified: true,
    );
  }

  bool _deepEquals(Object? left, Object? right) {
    if (identical(left, right)) {
      return true;
    }

    if (left is Map && right is Map) {
      if (left.length != right.length) {
        return false;
      }

      for (final Object? key in left.keys) {
        if (!right.containsKey(key) || !_deepEquals(left[key], right[key])) {
          return false;
        }
      }

      return true;
    }

    if (left is List && right is List) {
      if (left.length != right.length) {
        return false;
      }

      for (int i = 0; i < left.length; i++) {
        if (!_deepEquals(left[i], right[i])) {
          return false;
        }
      }

      return true;
    }

    return left == right;
  }

  AgentSecurityIncidentRuntimeAttachmentPreflightResult _blocked({
    required String status,
    required String reasonCode,
  }) {
    return AgentSecurityIncidentRuntimeAttachmentPreflightResult(
      status: status,
      reasonCode: reasonCode,
      freshOwnerVerified: false,
      permissionRequiresApproval: false,
      runtimeRequiresApproval: false,
      centralApprovalSnapshotVerified: false,
    );
  }

  bool get defaultsFailClosed => true;

  // The coordinator can read Auth, persisted role, and central approval only
  // when a future caller explicitly opts into preflightExecutionArmed=true.
  // Step1I-T-I itself invokes none of those live reads.
  bool get livePreflightReadCapable => true;

  bool get callerSuppliedRoleAccepted => false;
  bool get syntheticRoleAuthorityAccepted => false;
  bool get persistedRoleResolutionRequired => true;

  bool get createsApproval => false;
  bool get approvesRequest => false;
  bool get consumesApproval => false;

  bool get instantiatesRepository => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;

  bool get createsIncident => false;
  bool get updatesIncident => false;
  bool get createsIdempotencyReceipt => false;

  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get changesEmergencyStop => false;

  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
