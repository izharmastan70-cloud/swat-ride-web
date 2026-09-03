import 'package:flutter/material.dart';

import '../models/agent_master_settings.dart';
import '../models/agent_role.dart';
import '../services/agent_master_settings_service.dart';
import '../services/agent_paid_code_router.dart';
import '../services/agent_role_service.dart';

// =========================================================
// AI AGENT — PAID CODE AI STATUS
// =========================================================
//
// Phase 15 visibility only.
// No provider key editor, no code write button, no deploy button.

class AgentPaidCodeStatusScreen extends StatefulWidget {
  const AgentPaidCodeStatusScreen({super.key});

  @override
  State<AgentPaidCodeStatusScreen> createState() =>
      _AgentPaidCodeStatusScreenState();
}

class _AgentPaidCodeStatusScreenState
    extends State<AgentPaidCodeStatusScreen> {
  final AgentMasterSettingsService _settingsService =
      AgentMasterSettingsService();

  final AgentRoleService _roleService =
      AgentRoleService();

  final AgentPaidCodeRouter _router =
      AgentPaidCodeRouter();

  String _providerStatus = 'Not checked';

  Future<void> _check() async {
    try {
      final AgentMasterSettings settings =
          await _settingsService.getSettings();

      final AgentRole? codeRole =
          await _roleService.getRole(AgentRole.codeAgentRoleId);

      if (codeRole == null) {
        setState(() {
          _providerStatus = 'code_agent is not seeded.';
        });
        return;
      }

      final bool providerAvailable =
          await _router.provider.isAvailable();

      if (mounted) {
        setState(() {
          _providerStatus =
              'Master: ${settings.masterEnabled}\n'
              'Paid Code AI enabled: ${settings.paidCodeAiEnabled}\n'
              'Budget available: ${settings.paidBudgetAvailable}\n'
              'Code Agent operational: ${codeRole.isOperational}\n'
              'Provider available: $providerAvailable\n'
              'Provider ID: ${_router.provider.providerId}';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _providerStatus = 'Check failed safely: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Paid Code AI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              onPressed: _check,
              child: const Text('CHECK STATUS'),
            ),
            const SizedBox(height: 16),
            SelectableText(
              _providerStatus,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'Phase 15 is analysis/proposal only. No source-code write or '
              'production deployment is available here.',
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ],
        ),
      ),
    );
  }
}
