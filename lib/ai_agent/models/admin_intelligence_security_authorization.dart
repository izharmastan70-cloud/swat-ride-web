import 'agent_permission_decision.dart';

class AdminIntelligenceSecurityAuthorization {
  const AdminIntelligenceSecurityAuthorization({
    required this.permissionDecision,
    required this.runtimeDecision,
    required this.actionKnown,
    required this.handoffValid,
    required this.approvalRequired,
    required this.approvalSnapshotValid,
    required this.approvalConsumptionRequired,
    required this.authorizationReady,
    required this.reason,
    required this.approvalScope,
  });

  final AgentPermissionDecision permissionDecision;
  final AgentPermissionDecision runtimeDecision;

  final bool actionKnown;
  final bool handoffValid;

  /// Existing Permission Engine / action policy requirement.
  final bool approvalRequired;

  /// True only when a supplied APPROVED approval exactly matches
  /// role/action/module/scope and is not expired/consumed.
  final bool approvalSnapshotValid;

  /// Approval is verified but must still be atomically consumed at the
  /// execution boundary before a real provider call.
  final bool approvalConsumptionRequired;

  /// This is preparation readiness only. No provider has executed.
  final bool authorizationReady;

  final String reason;

  final Map<String, dynamic> approvalScope;

  bool get denied =>
      permissionDecision.isDenied ||
      runtimeDecision.isDenied ||
      !actionKnown ||
      !handoffValid;

  bool get waitingForApproval => approvalRequired && !approvalSnapshotValid;

  bool get readyForApprovalConsumption =>
      approvalRequired &&
      approvalSnapshotValid &&
      approvalConsumptionRequired &&
      !denied;

  bool get readyWithoutApprovalConsumption =>
      !approvalRequired && authorizationReady && !denied;
}
