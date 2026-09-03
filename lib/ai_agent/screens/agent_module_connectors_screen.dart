import 'package:flutter/material.dart';

import '../models/agent_module_connector_descriptor.dart';
import '../services/agent_module_connector_registry.dart';

// =========================================================
// AI AGENT — MODULE CONNECTORS SCREEN
// =========================================================
//
// Read-only Phase 13 visibility screen.
// No real module connector can be enabled from this screen yet.

class AgentModuleConnectorsScreen extends StatelessWidget {
  const AgentModuleConnectorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<AgentModuleConnectorDescriptor> connectors =
        AgentModuleConnectorRegistry.all;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('AI Module Connectors'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: connectors.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (
          BuildContext context,
          int index,
        ) {
          final AgentModuleConnectorDescriptor item =
              connectors[index];

          return Card(
            color: const Color(0xFF1A1A1A),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.module.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(item.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.notes,
                    style: const TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Read-only first: ${item.readOnlyFirst}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Real module audit required: ${item.requiresRealModuleAudit}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
