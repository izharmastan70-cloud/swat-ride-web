import 'package:flutter/material.dart';

import '../models/agent_tool_definition.dart';
import '../services/agent_controlled_tool_registry.dart';

// =========================================================
// AI AGENT — CONTROLLED TOOL REGISTRY SCREEN
// =========================================================
//
// Read-only development/admin visibility.
// No tool can be executed from this screen.

class AgentToolRegistryScreen extends StatelessWidget {
  const AgentToolRegistryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<AgentToolDefinition> tools =
        AgentControlledToolRegistry.all;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('AI Controlled Tools'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (
          BuildContext context,
          int index,
        ) {
          final AgentToolDefinition tool = tools[index];

          return Card(
            color: const Color(0xFF1A1A1A),
            child: ListTile(
              title: Text(
                tool.toolId,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                '${tool.module} • ${tool.risk}\n${tool.description}',
                style: const TextStyle(color: Colors.white60),
              ),
              isThreeLine: true,
              trailing: Chip(
                label: Text(
                  tool.connectorReady ? 'READY' : 'NOT CONNECTED',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
