import 'package:flutter/material.dart';

import '../services/agent_code_workspace.dart';
import '../services/agent_placeholder_code_workspace.dart';

// =========================================================
// AI AGENT — CODE CHANGE STATUS
// =========================================================
//
// Phase 16 visibility only.
// No Edit / Apply / Deploy button is exposed while the real workspace
// and test runner are disconnected.

class AgentCodeChangeStatusScreen extends StatelessWidget {
  const AgentCodeChangeStatusScreen({super.key});

  final AgentCodeWorkspace _workspace =
      const AgentPlaceholderCodeWorkspace();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('AI Code Change Safety'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: const Color(0xFF1A1A1A),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Phase 16 Safety Pipeline',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Workspace: ${_workspace.workspaceId}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Flow: Approval → Scope Lock → Hash Check → Backup → '
                  'Patch → Analyze/Test/Build → KEEP/ROLLBACK',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Real project editing and test execution are NOT connected '
                  'yet, so this package cannot modify SWAT RIDE source code.',
                  style: TextStyle(color: Colors.orangeAccent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
