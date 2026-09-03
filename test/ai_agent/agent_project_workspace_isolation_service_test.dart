import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_project_context.dart';
import 'package:swat_ride/ai_agent/services/agent_code_workspace.dart';
import 'package:swat_ride/ai_agent/services/agent_project_workspace_isolation_service.dart';

void main() {
  test('permits only relative paths in the matching project workspace', () async {
    final FakeWorkspace workspace = FakeWorkspace('swat_workspace');
    final AgentProjectWorkspaceIsolationService isolated =
        AgentProjectWorkspaceIsolationService(
          workspace: workspace,
          projectContext: validContext(workspaceId: 'swat_workspace'),
        );

    await isolated.writeFile(filePath: 'lib/main.dart', content: 'safe');

    expect(workspace.lastWrittenPath, 'lib/main.dart');
    expect(
      () => isolated.readFile('../client_project/secret.txt'),
      throwsFormatException,
    );
  });

  test('rejects a workspace belonging to another project', () {
    final AgentProjectWorkspaceIsolationService isolated =
        AgentProjectWorkspaceIsolationService(
          workspace: FakeWorkspace('client_workspace'),
          projectContext: validContext(workspaceId: 'swat_workspace'),
        );

    expect(() => isolated.workspaceId, throwsStateError);
  });
}

AgentProjectContext validContext({required String workspaceId}) {
  final DateTime now = DateTime.now().toUtc();
  return AgentProjectContext.create(
    tenantId: 'swat_ride',
    projectId: 'swat_ride_app',
    workspaceId: workspaceId,
    allowedModules: const <String>['core'],
    issuedAt: now.subtract(const Duration(minutes: 1)),
    expiresAt: now.add(const Duration(minutes: 5)),
  );
}

class FakeWorkspace implements AgentCodeWorkspace {
  FakeWorkspace(this.workspaceId);

  @override
  final String workspaceId;
  String? lastWrittenPath;

  @override
  Future<bool> fileExists(String filePath) async => true;

  @override
  Future<String> hashFile(String filePath) async => 'hash';

  @override
  Future<String> readFile(String filePath) async => 'content';

  @override
  Future<void> writeFile({
    required String filePath,
    required String content,
  }) async {
    lastWrittenPath = filePath;
  }
}