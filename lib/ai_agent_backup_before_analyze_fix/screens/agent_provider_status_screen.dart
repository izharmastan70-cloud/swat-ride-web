import 'package:flutter/material.dart';

import '../models/agent_provider_health.dart';
import '../services/agent_provider_health_service.dart';

// =========================================================
// AI AGENT — PROVIDER STATUS SCREEN
// =========================================================
//
// Read-only Phase 9 provider-health view.
// No API keys or provider credentials are displayed.

class AgentProviderStatusScreen extends StatelessWidget {
  AgentProviderStatusScreen({super.key});

  final AgentProviderHealthService _service =
      AgentProviderHealthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('AI Provider Status'),
      ),
      body: StreamBuilder<List<AgentProviderHealth>>(
        stream: _service.watchAll(),
        builder: (
          BuildContext context,
          AsyncSnapshot<List<AgentProviderHealth>> snapshot,
        ) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Provider status error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<AgentProviderHealth> items = snapshot.data!;

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No provider-health records yet.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (
              BuildContext context,
              int index,
            ) {
              final AgentProviderHealth item = items[index];

              return Card(
                color: const Color(0xFF1A1A1A),
                child: ListTile(
                  title: Text(
                    item.providerId,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${item.providerType}\n'
                    'Failures: ${item.consecutiveFailures} • '
                    'Requests: ${item.requestsToday}',
                    style: const TextStyle(color: Colors.white60),
                  ),
                  trailing: Text(
                    item.status,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
