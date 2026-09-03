import '../constants/agent_paid_code_constants.dart';

// =========================================================
// AI AGENT — PAID CODE REQUEST
// =========================================================
//
// Technical-only request.
// No business/customer-support work is permitted through this model.
//
// sourceContext must already be sanitized and scoped to the approved
// technical problem. Secrets/credentials must never be included.

class AgentPaidCodeRequest {
  final String requestId;
  final String roleId;
  final String requestType;
  final String problemSummary;
  final String errorLog;
  final Map<String, dynamic> sourceContext;
  final List<String> approvedFilePaths;
  final String approvalId;
  final DateTime createdAt;

  const AgentPaidCodeRequest({
    required this.requestId,
    required this.roleId,
    required this.requestType,
    required this.problemSummary,
    required this.errorLog,
    required this.sourceContext,
    required this.approvedFilePaths,
    required this.approvalId,
    required this.createdAt,
  });

  void validate() {
    if (requestId.trim().isEmpty ||
        roleId.trim().isEmpty ||
        problemSummary.trim().isEmpty) {
      throw const AgentPaidCodeRequestException(
        'Paid Code request identity/problem fields cannot be empty.',
      );
    }

    if (!AgentPaidCodeRequestType.isValid(requestType)) {
      throw AgentPaidCodeRequestException(
        'Invalid Paid Code requestType "$requestType".',
      );
    }

    if (approvalId.trim().isEmpty) {
      throw const AgentPaidCodeRequestException(
        'Paid Code AI requires an explicit one-action approvalId.',
      );
    }

    if (approvedFilePaths.any((String path) => path.trim().isEmpty)) {
      throw const AgentPaidCodeRequestException(
        'approvedFilePaths cannot contain empty paths.',
      );
    }
  }
}

class AgentPaidCodeRequestException implements Exception {
  final String message;
  const AgentPaidCodeRequestException(this.message);

  @override
  String toString() => 'AgentPaidCodeRequestException: $message';
}
