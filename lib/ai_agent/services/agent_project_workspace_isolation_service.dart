import '../models/agent_project_context.dart';
import 'agent_code_workspace.dart';

/// Project-scoped wrapper for the existing narrow workspace contract.
/// It never supplies filesystem, shell, Git, or deployment authority.
class AgentProjectWorkspaceIsolationService implements AgentCodeWorkspace {
  AgentProjectWorkspaceIsolationService({
    required this.workspace,
    required this.projectContext,
  });

  final AgentCodeWorkspace workspace;
  final AgentProjectContext projectContext;

  @override
  String get workspaceId {
    _validateWorkspace();
    return workspace.workspaceId;
  }

  @override
  Future<bool> fileExists(String filePath) async {
    _validateFilePath(filePath);
    return workspace.fileExists(filePath);
  }

  @override
  Future<String> readFile(String filePath) async {
    _validateFilePath(filePath);
    return workspace.readFile(filePath);
  }

  @override
  Future<void> writeFile({
    required String filePath,
    required String content,
  }) async {
    _validateFilePath(filePath);
    await workspace.writeFile(filePath: filePath, content: content);
  }

  @override
  Future<String> hashFile(String filePath) async {
    _validateFilePath(filePath);
    return workspace.hashFile(filePath);
  }

  void _validateFilePath(String filePath) {
    _validateWorkspace();
    final String normalized = filePath.replaceAll('\\', '/').trim();
    if (normalized.isEmpty ||
        normalized.startsWith('/') ||
        RegExp(r'^[A-Za-z]:').hasMatch(normalized) ||
        normalized.split('/').contains('..')) {
      throw const FormatException('Workspace path escapes project scope.');
    }
  }

  void _validateWorkspace() {
    projectContext.validate(now: DateTime.now().toUtc());
    if (workspace.workspaceId.trim() != projectContext.workspaceId) {
      throw StateError('Workspace does not match the project context.');
    }
  }
}