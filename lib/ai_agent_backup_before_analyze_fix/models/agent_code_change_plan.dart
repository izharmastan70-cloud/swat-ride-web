import '../constants/agent_code_change_constants.dart';
import 'agent_code_patch.dart';

// =========================================================
// AI AGENT — CODE CHANGE PLAN
// =========================================================
//
// One plan = one approved technical change scope.
// Additional files require a new owner approval.

class AgentCodeChangePlan {
  final String changeId;
  final String approvalId;
  final String problemSummary;
  final List<String> approvedFilePaths;
  final List<AgentCodePatch> patches;
  final String status;
  final DateTime createdAt;

  const AgentCodeChangePlan({
    required this.changeId,
    required this.approvalId,
    required this.problemSummary,
    required this.approvedFilePaths,
    required this.patches,
    required this.status,
    required this.createdAt,
  });

  void validate() {
    if (changeId.trim().isEmpty ||
        approvalId.trim().isEmpty ||
        problemSummary.trim().isEmpty) {
      throw const AgentCodeChangePlanException(
        'Code change identity/problem fields cannot be empty.',
      );
    }

    if (!AgentCodeChangeStatus.values.contains(status)) {
      throw AgentCodeChangePlanException(
        'Invalid code change status "$status".',
      );
    }

    final Set<String> approved =
        approvedFilePaths.map((String e) => e.trim()).toSet();

    for (final AgentCodePatch patch in patches) {
      patch.validate();

      if (!approved.contains(patch.filePath.trim())) {
        throw AgentCodeChangePlanException(
          'Patch "${patch.filePath}" is outside approved file scope.',
        );
      }
    }
  }
}

class AgentCodeChangePlanException implements Exception {
  final String message;
  const AgentCodeChangePlanException(this.message);

  @override
  String toString() => 'AgentCodeChangePlanException: $message';
}
