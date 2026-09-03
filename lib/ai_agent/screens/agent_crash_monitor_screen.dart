import 'package:flutter/material.dart';

import '../models/agent_crash_assessment.dart';
import '../models/agent_crash_event.dart';
import '../services/agent_crash_event_service.dart';
import '../services/agent_crash_monitor_agent.dart';

// =========================================================
// AI AGENT — CRASH MONITOR SCREEN
// =========================================================
//
// Standalone Phase 14 screen.
// No real FlutterError hook / production crash SDK connection yet.

class AgentCrashMonitorScreen extends StatefulWidget {
  const AgentCrashMonitorScreen({super.key});

  @override
  State<AgentCrashMonitorScreen> createState() =>
      _AgentCrashMonitorScreenState();
}

class _AgentCrashMonitorScreenState
    extends State<AgentCrashMonitorScreen> {
  final AgentCrashEventService _service =
      AgentCrashEventService();

  final AgentCrashMonitorAgent _agent =
      AgentCrashMonitorAgent();

  final Map<String, AgentCrashAssessment> _assessments =
      <String, AgentCrashAssessment>{};

  Future<void> _classify(AgentCrashEvent event) async {
    final AgentCrashAssessment assessment =
        await _agent.classify(event);

    if (mounted) {
      setState(() {
        _assessments[event.crashId] = assessment;
      });
    }
  }

  Future<void> _prepareHandoff(
    AgentCrashEvent event,
  ) async {
    await _agent.markHandoffPrepared(event);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Code Agent handoff prepared. No paid AI request has been made.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('AI Crash Monitor'),
      ),
      body: StreamBuilder<List<AgentCrashEvent>>(
        stream: _service.watchOpen(),
        builder: (
          BuildContext context,
          AsyncSnapshot<List<AgentCrashEvent>> snapshot,
        ) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Crash monitor error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final List<AgentCrashEvent> events =
              snapshot.data!;

          if (events.isEmpty) {
            return const Center(
              child: Text(
                'No open crash events.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: 12),
            itemBuilder: (
              BuildContext context,
              int index,
            ) {
              final AgentCrashEvent event = events[index];
              final AgentCrashAssessment? assessment =
                  _assessments[event.crashId];

              return Card(
                color: const Color(0xFF1A1A1A),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${event.module} • ${event.errorType}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.message,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Occurrences: ${event.occurrenceCount}',
                        style: const TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          OutlinedButton(
                            onPressed: () => _classify(event),
                            child: const Text('CLASSIFY'),
                          ),
                          const SizedBox(width: 8),
                          if (assessment
                                  ?.shouldHandoffToCodeAgent ??
                              false)
                            ElevatedButton(
                              onPressed: () =>
                                  _prepareHandoff(event),
                              child: const Text(
                                'PREPARE CODE HANDOFF',
                              ),
                            ),
                        ],
                      ),
                      if (assessment != null) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          '${assessment.severity} • ${assessment.category}',
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                          ),
                        ),
                        Text(
                          assessment.reason,
                          style: const TextStyle(
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
