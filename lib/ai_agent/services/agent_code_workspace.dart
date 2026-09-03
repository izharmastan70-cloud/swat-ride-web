// =========================================================
// AI AGENT — CODE WORKSPACE CONTRACT
// =========================================================
//
// This is the ONLY interface future code editing may use.
//
// It deliberately exposes narrow file operations, not an unrestricted shell,
// process runner, filesystem handle, Git client, or deployment credential.
//
// Real SWAT RIDE workspace adapter is NOT included in Phase 16.

abstract class AgentCodeWorkspace {
  String get workspaceId;

  Future<bool> fileExists(String filePath);

  Future<String> readFile(String filePath);

  Future<void> writeFile({
    required String filePath,
    required String content,
  });

  Future<String> hashFile(String filePath);
}
