import 'package:flutter/material.dart';

import '../constants/agent_feedback_constants.dart';
import '../models/agent_feedback_draft.dart';
import '../models/agent_feedback_item.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_role.dart';
import '../services/agent_feedback_agent.dart';
import '../services/agent_feedback_service.dart';
import '../services/agent_master_settings_service.dart';
import '../services/agent_role_service.dart';

// =========================================================
// AI AGENT — FEEDBACK INBOX
// =========================================================
//
// Standalone Phase 12 screen.
// Draft-only. No customer-facing send/delete action is available.

class AgentFeedbackInboxScreen extends StatefulWidget {
  const AgentFeedbackInboxScreen({super.key});

  @override
  State<AgentFeedbackInboxScreen> createState() =>
      _AgentFeedbackInboxScreenState();
}

class _AgentFeedbackInboxScreenState
    extends State<AgentFeedbackInboxScreen> {
  final AgentFeedbackService _feedbackService =
      AgentFeedbackService();
  final AgentFeedbackAgent _feedbackAgent =
      AgentFeedbackAgent();
  final AgentRoleService _roleService = AgentRoleService();
  final AgentMasterSettingsService _settingsService =
      AgentMasterSettingsService();

  final Map<String, AgentFeedbackDraft> _drafts =
      <String, AgentFeedbackDraft>{};

  Future<void> _draft(AgentFeedbackItem item) async {
    try {
      final AgentRole? role =
          await _roleService.getRole('feedback_agent');

      if (role == null) {
        throw StateError('feedback_agent is not seeded.');
      }

      final AgentMasterSettings settings =
          await _settingsService.getSettings();

      final AgentFeedbackDraft draft =
          await _feedbackAgent.draft(
        settings: settings,
        feedbackRole: role,
        feedback: item,
      );

      if (mounted) {
        setState(() {
          _drafts[item.feedbackId] = draft;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    }
  }

  Future<void> _markUnderReview(
    AgentFeedbackItem item,
  ) async {
    await _feedbackService.setStatus(
      feedbackId: item.feedbackId,
      status: AgentFeedbackStatus.underReview,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('AI Feedback Inbox'),
      ),
      body: StreamBuilder<List<AgentFeedbackItem>>(
        stream: _feedbackService.watchOpen(),
        builder: (
          BuildContext context,
          AsyncSnapshot<List<AgentFeedbackItem>> snapshot,
        ) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Feedback error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final List<AgentFeedbackItem> items =
              snapshot.data!;

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No open feedback.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
            itemBuilder: (
              BuildContext context,
              int index,
            ) {
              final AgentFeedbackItem item = items[index];
              final AgentFeedbackDraft? draft =
                  _drafts[item.feedbackId];

              return Card(
                color: const Color(0xFF1A1A1A),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${item.module} • ${item.type}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.rating != null)
                        Text(
                          'Rating: ${item.rating}/5',
                          style: const TextStyle(
                            color: Colors.amberAccent,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        item.message,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          OutlinedButton(
                            onPressed: () =>
                                _markUnderReview(item),
                            child: const Text('UNDER REVIEW'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _draft(item),
                            child: const Text('DRAFT REPLY'),
                          ),
                        ],
                      ),
                      if (draft != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          'Sentiment: ${draft.sentiment}',
                          style: const TextStyle(
                            color: Colors.white54,
                          ),
                        ),
                        Text(
                          'Escalation: ${draft.escalation}',
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          draft.replyText,
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          draft.note,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
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
