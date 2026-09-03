import 'package:flutter/material.dart';

import '../models/agent_master_settings.dart';
import '../models/agent_role.dart';
import '../models/agent_support_draft.dart';
import '../models/agent_support_request.dart';
import '../services/agent_master_settings_service.dart';
import '../services/agent_role_service.dart';
import '../services/agent_support_agent.dart';

// =========================================================
// AI AGENT — SUPPORT TEST SCREEN
// =========================================================
//
// Standalone Phase 11 test surface.
// Draft-only. Nothing is sent to a customer.

class AgentSupportTestScreen extends StatefulWidget {
  const AgentSupportTestScreen({super.key});

  @override
  State<AgentSupportTestScreen> createState() =>
      _AgentSupportTestScreenState();
}

class _AgentSupportTestScreenState
    extends State<AgentSupportTestScreen> {
  final TextEditingController _controller =
      TextEditingController();
  final AgentMasterSettingsService _settingsService =
      AgentMasterSettingsService();
  final AgentRoleService _roleService = AgentRoleService();
  final AgentSupportAgent _supportAgent = AgentSupportAgent();

  AgentSupportDraft? _draft;
  String? _error;
  bool _busy = false;

  Future<void> _draftReply() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final AgentRole? role =
          await _roleService.getRole('support_agent');

      if (role == null) {
        throw StateError('support_agent is not seeded.');
      }

      final AgentMasterSettings settings =
          await _settingsService.getSettings();

      final AgentSupportDraft draft =
          await _supportAgent.draft(
        settings: settings,
        supportRole: role,
        request: AgentSupportRequest(
          requestId:
              'support_test_${DateTime.now().microsecondsSinceEpoch}',
          userMessage: _controller.text.trim(),
          module: 'general',
          referenceId: '',
          userIdAlias: 'test_user',
          context: const <String, dynamic>{},
          createdAt: DateTime.now(),
        ),
      );

      if (mounted) {
        setState(() => _draft = draft);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Support Agent Test'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _controller,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter a support question...',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _busy ? null : _draftReply,
            child: const Text('DRAFT REPLY'),
          ),
          if (_busy) ...<Widget>[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
          if (_draft != null) ...<Widget>[
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFF1A1A1A),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${_draft!.status} • ${_draft!.intent}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _draft!.replyText,
                      style:
                          const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Escalation: ${_draft!.escalation}',
                      style:
                          const TextStyle(color: Colors.orangeAccent),
                    ),
                    Text(
                      _draft!.note,
                      style:
                          const TextStyle(color: Colors.white38),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
