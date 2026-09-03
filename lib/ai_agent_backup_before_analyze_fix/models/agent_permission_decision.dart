import '../constants/agent_enums.dart';

// =========================================================
// AI AGENT — PERMISSION DECISION
// =========================================================

class AgentPermissionResult {
  AgentPermissionResult._();

  static const String allow = 'ALLOW';
  static const String requireApproval = 'REQUIRE_APPROVAL';
  static const String deny = 'DENY';
}

class AgentPermissionDecision {
  final String result;
  final String roleId;
  final String actionId;
  final String reason;
  final String effectiveMode;
  final bool shouldAudit;

  const AgentPermissionDecision({
    required this.result,
    required this.roleId,
    required this.actionId,
    required this.reason,
    required this.effectiveMode,
    this.shouldAudit = true,
  });

  bool get isAllowed => result == AgentPermissionResult.allow;

  bool get needsApproval =>
      result == AgentPermissionResult.requireApproval;

  bool get isDenied => result == AgentPermissionResult.deny;

  factory AgentPermissionDecision.deny({
    required String roleId,
    required String actionId,
    required String reason,
    String effectiveMode = AgentMode.off,
  }) {
    return AgentPermissionDecision(
      result: AgentPermissionResult.deny,
      roleId: roleId,
      actionId: actionId,
      reason: reason,
      effectiveMode: effectiveMode,
    );
  }

  factory AgentPermissionDecision.requireApproval({
    required String roleId,
    required String actionId,
    required String reason,
    required String effectiveMode,
  }) {
    return AgentPermissionDecision(
      result: AgentPermissionResult.requireApproval,
      roleId: roleId,
      actionId: actionId,
      reason: reason,
      effectiveMode: effectiveMode,
    );
  }

  factory AgentPermissionDecision.allow({
    required String roleId,
    required String actionId,
    required String reason,
    required String effectiveMode,
  }) {
    return AgentPermissionDecision(
      result: AgentPermissionResult.allow,
      roleId: roleId,
      actionId: actionId,
      reason: reason,
      effectiveMode: effectiveMode,
    );
  }
}
