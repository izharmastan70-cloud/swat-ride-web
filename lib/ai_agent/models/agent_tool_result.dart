// =========================================================
// AI AGENT — CONTROLLED TOOL RESULT
// =========================================================

class AgentToolResultStatus {
  AgentToolResultStatus._();

  static const String success = 'SUCCESS';
  static const String denied = 'DENIED';
  static const String approvalRequired = 'APPROVAL_REQUIRED';
  static const String unavailable = 'UNAVAILABLE';
  static const String failed = 'FAILED';
}

class AgentToolResult {
  final String status;
  final String requestId;
  final String roleId;
  final String actionId;
  final String toolId;
  final String message;
  final Map<String, dynamic> data;

  const AgentToolResult({
    required this.status,
    required this.requestId,
    required this.roleId,
    required this.actionId,
    required this.toolId,
    required this.message,
    this.data = const <String, dynamic>{},
  });

  bool get isSuccess => status == AgentToolResultStatus.success;
}
