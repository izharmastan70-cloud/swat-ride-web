import '../models/agent_code_backup_manifest.dart';
import '../models/agent_code_change_plan.dart';
import '../models/agent_code_test_result.dart';
import 'agent_code_backup_service.dart';
import 'agent_code_test_runner.dart';
import 'agent_code_workspace.dart';
import 'agent_placeholder_code_workspace.dart';

// =========================================================
// AI AGENT — CODE CHANGE COORDINATOR
// =========================================================
//
// Phase 16 establishes the safe workflow:
//
// approved scope
//   -> verify original hashes
//   -> backup
//   -> apply only approved patches
//   -> test
//   -> KEEP or ROLLBACK
//
// Safe Phase 16 defaults keep the real workspace disconnected, so this
// coordinator cannot modify the user's actual project yet.

class AgentCodeChangeCoordinator {
  final AgentCodeWorkspace workspace;
  final AgentCodeBackupService backupService;
  final AgentCodeTestRunner testRunner;

  AgentCodeChangeCoordinator({
    AgentCodeWorkspace? workspace,
    AgentCodeBackupService? backupService,
    AgentCodeTestRunner? testRunner,
  })  : workspace =
            workspace ?? const AgentPlaceholderCodeWorkspace(),
        backupService = backupService ??
            AgentCodeBackupService(
              workspace: workspace ??
                  const AgentPlaceholderCodeWorkspace(),
            ),
        testRunner =
            testRunner ?? const AgentPlaceholderCodeTestRunner();

  Future<AgentCodeApplyResult> applyApprovedPlan(
    AgentCodeChangePlan plan,
  ) async {
    plan.validate();

    // 1) Detect stale source before backup/write.
    for (final patch in plan.patches) {
      final bool exists = await workspace.fileExists(patch.filePath);

      if (!exists) {
        return AgentCodeApplyResult.failed(
          'Approved file is unavailable: ${patch.filePath}',
        );
      }

      final String currentHash =
          await workspace.hashFile(patch.filePath);

      if (patch.originalHash.isNotEmpty &&
          currentHash != patch.originalHash) {
        return AgentCodeApplyResult.failed(
          'Source changed after proposal for ${patch.filePath}. '
          'New analysis/approval is required.',
        );
      }
    }

    // 2) Backup must complete before write.
    final AgentCodeBackupManifest backup =
        await backupService.createBackup(plan);

    if (!backup.isComplete) {
      return AgentCodeApplyResult.failed(
        'Backup was not complete. No code was changed.',
      );
    }

    // 3) Apply only files already validated as inside approved scope.
    try {
      for (final patch in plan.patches) {
        await workspace.writeFile(
          filePath: patch.filePath,
          content: patch.proposedContent,
        );
      }
    } catch (error) {
      // Best-effort immediate rollback after a partial write failure.
      try {
        await backupService.restore(backup);
      } catch (_) {}

      return AgentCodeApplyResult.failed(
        'Patch application failed and rollback was attempted: $error',
        backup: backup,
      );
    }

    // 4) Test.
    final AgentCodeTestResult tests = await testRunner.run();

    return AgentCodeApplyResult(
      success: true,
      message: tests.allPassed
          ? 'Patch applied and tests passed. Owner may KEEP.'
          : 'Patch applied but tests did not fully pass/are unavailable. '
              'Owner should review and may ROLLBACK.',
      backup: backup,
      tests: tests,
    );
  }

  Future<void> rollback(
    AgentCodeBackupManifest backup,
  ) {
    return backupService.restore(backup);
  }
}

class AgentCodeApplyResult {
  final bool success;
  final String message;
  final AgentCodeBackupManifest? backup;
  final AgentCodeTestResult? tests;

  const AgentCodeApplyResult({
    required this.success,
    required this.message,
    required this.backup,
    required this.tests,
  });

  factory AgentCodeApplyResult.failed(
    String message, {
    AgentCodeBackupManifest? backup,
  }) {
    return AgentCodeApplyResult(
      success: false,
      message: message,
      backup: backup,
      tests: null,
    );
  }
}
