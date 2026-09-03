import 'package:flutter/material.dart';

import '../models/agent_orchestrator_config.dart';
import '../services/agent_orchestrator_config_service.dart';

// =========================================================
// AI AGENT — OPENCLAW STATUS SCREEN
// =========================================================
//
// Standalone Phase 10 visibility/control screen.
// It only toggles the orchestrator foundation.
// No network endpoint/secret editor exists yet.

class AgentOpenClawStatusScreen extends StatelessWidget {
  AgentOpenClawStatusScreen({super.key});

  final AgentOrchestratorConfigService _service =
      AgentOrchestratorConfigService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('OpenClaw Orchestrator'),
      ),
      body: StreamBuilder<AgentOrchestratorConfig>(
        stream: _service.watchConfig(),
        builder: (
          BuildContext context,
          AsyncSnapshot<AgentOrchestratorConfig> snapshot,
        ) {
          final AgentOrchestratorConfig config =
              snapshot.data ??
                  AgentOrchestratorConfig.safeDefaults();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                color: const Color(0xFF1A1A1A),
                child: SwitchListTile(
                  value: config.enabled,
                  onChanged: (bool value) async {
                    await _service.setEnabled(value);
                  },
                  title: const Text(
                    'OpenClaw Foundation',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${config.status}\n'
                    'Read-only only: ${config.readOnlyOnly}',
                    style:
                        const TextStyle(color: Colors.white60),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No real network transport/API credentials are configured in Phase 10.',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          );
        },
      ),
    );
  }
}
