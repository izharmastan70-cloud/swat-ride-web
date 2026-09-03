// =========================================================
// AI AGENT — CODE BACKUP MANIFEST
// =========================================================
//
// Backup manifest records what must be restorable before any write.
// No real project backup is created by the placeholder workspace.

class AgentCodeBackupEntry {
  final String filePath;
  final String originalContent;
  final String originalHash;

  const AgentCodeBackupEntry({
    required this.filePath,
    required this.originalContent,
    required this.originalHash,
  });
}

class AgentCodeBackupManifest {
  final String backupId;
  final String changeId;
  final List<AgentCodeBackupEntry> entries;
  final DateTime createdAt;

  const AgentCodeBackupManifest({
    required this.backupId,
    required this.changeId,
    required this.entries,
    required this.createdAt,
  });

  bool get isComplete => entries.isNotEmpty;
}
