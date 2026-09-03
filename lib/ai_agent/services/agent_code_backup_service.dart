import '../models/agent_code_backup_manifest.dart';
import '../models/agent_code_change_plan.dart';
import 'agent_code_workspace.dart';
import 'agent_placeholder_code_workspace.dart';

// =========================================================
// AI AGENT — CODE BACKUP SERVICE
// =========================================================
//
// Backup MUST succeed before any future code write.

class AgentCodeBackupService {
  final AgentCodeWorkspace workspace;

  AgentCodeBackupService({
    AgentCodeWorkspace? workspace,
  }) : workspace =
            workspace ?? const AgentPlaceholderCodeWorkspace();

  Future<AgentCodeBackupManifest> createBackup(
    AgentCodeChangePlan plan,
  ) async {
    plan.validate();

    final List<AgentCodeBackupEntry> entries =
        <AgentCodeBackupEntry>[];

    for (final String path in plan.approvedFilePaths) {
      final bool exists = await workspace.fileExists(path);

      if (!exists) {
        throw StateError(
          'Backup blocked: approved file does not exist in connected workspace: $path',
        );
      }

      final String content = await workspace.readFile(path);
      final String hash = await workspace.hashFile(path);

      entries.add(
        AgentCodeBackupEntry(
          filePath: path,
          originalContent: content,
          originalHash: hash,
        ),
      );
    }

    if (entries.length != plan.approvedFilePaths.length) {
      throw StateError(
        'Backup incomplete. Code write must not proceed.',
      );
    }

    return AgentCodeBackupManifest(
      backupId: 'backup_${DateTime.now().microsecondsSinceEpoch}',
      changeId: plan.changeId,
      entries: entries,
      createdAt: DateTime.now(),
    );
  }

  Future<void> restore(
    AgentCodeBackupManifest backup,
  ) async {
    if (!backup.isComplete) {
      throw StateError('Rollback blocked: backup is incomplete.');
    }

    for (final AgentCodeBackupEntry entry in backup.entries) {
      await workspace.writeFile(
        filePath: entry.filePath,
        content: entry.originalContent,
      );
    }
  }
}
