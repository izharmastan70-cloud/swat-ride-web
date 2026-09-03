import 'package:flutter/material.dart';

import '../constants/agent_action_ids.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_role.dart';
import '../models/agent_tool_request.dart';
import '../models/agent_tool_result.dart';
import '../services/agent_master_settings_service.dart';
import '../services/agent_read_only_executor.dart';
import '../services/agent_role_service.dart';

// =========================================================
// AI AGENT — READ-ONLY TEST SCREEN
// =========================================================
//
// Standalone developer/admin test surface for Phase 7.
// It reads only AI-owned collections through the controlled connector.
// It does not touch SWAT RIDE business modules.

class AgentReadOnlyTestScreen extends StatefulWidget {
  const AgentReadOnlyTestScreen({super.key});

  @override
  State<AgentReadOnlyTestScreen> createState() =>
      _AgentReadOnlyTestScreenState();
}

class _AgentReadOnlyTestScreenState
    extends State<AgentReadOnlyTestScreen> {
  final AgentMasterSettingsService _settingsService =
      AgentMasterSettingsService();
  final AgentRoleService _roleService = AgentRoleService();
  final AgentReadOnlyExecutor _executor = AgentReadOnlyExecutor();

  String _output = 'Not run yet.';
  bool _busy = false;

  Future<void> _runHealthRead() async {
    setState(() {
      _busy = true;
      _output = 'Running...';
    });

    try {
      final AgentMasterSettings settings =
          await _settingsService.getSettings();

      // Use any operational core-capable role only for development testing.
      // If none exists/allowed, the Permission Engine correctly denies.
      final List<AgentRole> roles = await _roleService.getAllRoles();

      AgentRole? selected;
      for (final AgentRole role in roles) {
        if (role.allowedActions.contains(
          AgentActionId.readSystemHealth,
        )) {
          selected = role;
          break;
        }
      }

      if (selected == null) {
        setState(() {
          _output =
              'No role currently has core.read_system_health in allowedActions. '
              'This is expected under Phase 2 default-deny until configured.';
        });
        return;
      }

      final AgentToolRequest request = AgentToolRequest(
        requestId:
            'phase7_${DateTime.now().microsecondsSinceEpoch}',
        roleId: selected.roleId,
        actionId: AgentActionId.readSystemHealth,
        toolId: 'tool.${AgentActionId.readSystemHealth}',
        requestedBy: 'phase7_test_screen',
        actionScope: const <String, dynamic>{},
        createdAt: DateTime.now(),
      );

      final AgentToolResult result = await _executor.execute(
        settings: settings,
        role: selected,
        request: request,
      );

      setState(() {
        _output =
            '${result.status}\n${result.message}\n${result.data}';
      });
    } catch (error) {
      setState(() {
        _output = 'Failed safely: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('AI Read-Only Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              onPressed: _busy ? null : _runHealthRead,
              child: const Text('READ AI SYSTEM HEALTH'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _output,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
