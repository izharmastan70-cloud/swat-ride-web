import 'agent_code_workspace.dart';

// =========================================================
// AI AGENT — PLACEHOLDER CODE WORKSPACE
// =========================================================
//
// Safe default for Phase 16.
// All real project file access is unavailable.
// Therefore no accidental SWAT RIDE source file can be edited.

class AgentPlaceholderCodeWorkspace implements AgentCodeWorkspace {
  const AgentPlaceholderCodeWorkspace();

  @override
  String get workspaceId => 'unconnected_swat_ride_workspace';

  @override
  Future<bool> fileExists(String filePath) async => false;

  @override
  Future<String> readFile(String filePath) {
    throw StateError(
      'Real SWAT RIDE code workspace is not connected yet.',
    );
  }

  @override
  Future<void> writeFile({
    required String filePath,
    required String content,
  }) {
    throw StateError(
      'Real SWAT RIDE code workspace is not connected yet.',
    );
  }

  @override
  Future<String> hashFile(String filePath) {
    throw StateError(
      'Real SWAT RIDE code workspace is not connected yet.',
    );
  }
}
