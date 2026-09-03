import 'package:flutter/material.dart';

import '../models/agent_production_rollout_monitor_recovery_models.dart';
import '../services/agent_production_rollout_monitor_recovery_coordinator.dart';

class AgentProductionRolloutMonitorRecoveryScreen extends StatefulWidget {
  const AgentProductionRolloutMonitorRecoveryScreen({
    super.key,
    required this.currentAdminId,
  });

  final String currentAdminId;

  @override
  State<AgentProductionRolloutMonitorRecoveryScreen> createState() =>
      _AgentProductionRolloutMonitorRecoveryScreenState();
}

class _AgentProductionRolloutMonitorRecoveryScreenState
    extends State<AgentProductionRolloutMonitorRecoveryScreen> {
  final AgentProductionRolloutMonitorRecoveryCoordinator _coordinator =
      AgentProductionRolloutMonitorRecoveryCoordinator();

  AgentProductionRolloutMonitorRecoveryPrepared? _prepared;
  AgentProductionRolloutMonitorRecoveryOutcome? _outcome;

  bool _working = false;
  String _message =
      'Emergency Stop must remain active until recovery precheck is clean.';

  Future<void> _prepareRecovery() async {
    if (_working) return;

    setState(() {
      _working = true;
      _prepared = null;
      _outcome = null;
      _message =
          'Running fresh Super Admin + immutable MONITOR_ONLY recovery precheck...';
    });

    try {
      final AgentProductionRolloutMonitorRecoveryPrepared prepared =
          await _coordinator.prepare(currentAdminId: widget.currentAdminId);

      if (!mounted) return;

      setState(() {
        _prepared = prepared;
        _message =
            'RECOVERY PRECHECK CLEAN. Emergency Stop is still ACTIVE. '
            'Review the bindings before explicit release.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _message = 'RECOVERY PRECHECK BLOCKED: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _confirmRelease() async {
    final AgentProductionRolloutMonitorRecoveryPrepared? prepared = _prepared;

    if (_working || prepared == null) return;

    final TextEditingController controller = TextEditingController();

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text(
                'Release Emergency Stop for MONITOR_ONLY recovery?',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'This is a real production control-plane write. '
                    'It only releases the existing Emergency Stop after a '
                    'fresh exact precheck. AUTO and business-write traffic '
                    'must remain 0%; Local/Paid/Call/Email/WhatsApp remain OFF.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No automatic rollback or automatic Emergency Stop '
                    'reactivation will occur. If immediate post-release '
                    'verification fails, manually reactivate Emergency Stop.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Type RELEASE MONITOR_ONLY to continue:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'RELEASE MONITOR_ONLY',
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('CANCEL'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(controller.text.trim() == 'RELEASE MONITOR_ONLY');
                  },
                  child: const Text('RELEASE & REVERIFY'),
                ),
              ],
            );
          },
        ) ??
        false;

    controller.dispose();

    if (!confirmed || !mounted) return;

    setState(() {
      _working = true;
      _message =
          'Fresh precheck running again before controlled Emergency Stop release...';
    });

    try {
      final AgentProductionRolloutMonitorRecoveryOutcome outcome =
          await _coordinator.releaseAndReverify(
            currentAdminId: widget.currentAdminId,
            typedConfirmation: 'RELEASE MONITOR_ONLY',
            prepared: prepared,
          );

      if (!mounted) return;

      setState(() {
        _outcome = outcome;
        _prepared = null;
        _message = outcome.postReleaseVerified
            ? 'MONITOR_ONLY RECOVERY VERIFIED ACTIVE. '
                  'AUTO=0%, business writes=0%, external channels remain OFF.'
            : outcome.released
            ? 'CRITICAL: Emergency Stop was released but immediate '
                  'reverification failed. MANUALLY REACTIVATE EMERGENCY STOP.'
            : 'Recovery release was blocked before any Emergency Stop change.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _prepared = null;
        _message =
            'RECOVERY ACTION BLOCKED/FAILED: $error. Check Emergency Stop state '
            'before doing anything else.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AgentProductionRolloutMonitorRecoveryPrepared? prepared = _prepared;
    final AgentProductionRolloutMonitorRecoveryOutcome? outcome = _outcome;

    return Scaffold(
      appBar: AppBar(title: const Text('Controlled MONITOR_ONLY Recovery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            color: const Color(0xFF4A1010),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'DO NOT USE THE GENERIC RELEASE EMERGENCY STOP BUTTON. '
                'This recovery surface first verifies the existing APPLIED '
                'MONITOR_ONLY activation, consumed token, runtime guard, '
                'bindings, current Owner identity and zero AUTO/business-write '
                'authority.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _working ? null : _prepareRecovery,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('PRECHECK CONTROLLED RECOVERY'),
          ),
          if (_working) ...<Widget>[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_message),
            ),
          ),
          if (prepared != null) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Clean recovery binding',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _row('Activation', _short(prepared.activationId)),
                    _row('Token SHA', _short(prepared.armingTokenIdSha256)),
                    _row('Guard revision', '${prepared.guardRevision}'),
                    _row('Role count', '${prepared.roleCount}'),
                    _row(
                      'Role projection SHA',
                      _short(prepared.roleProjectionSha256),
                    ),
                    _row('Control SHA', _short(prepared.controlStateSha256)),
                    _row('Plan SHA', _short(prepared.planSha256)),
                    _row('Actor SHA', _short(prepared.actorSha256)),
                    _row('Owner approval', _short(prepared.ownerApprovalId)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _working ? null : _confirmRelease,
              icon: const Icon(Icons.lock_open_outlined),
              label: const Text(
                'RELEASE EMERGENCY STOP & IMMEDIATELY REVERIFY',
              ),
            ),
          ],
          if (outcome != null) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              color: outcome.postReleaseVerified
                  ? const Color(0xFF123B1E)
                  : const Color(0xFF4A1010),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      outcome.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      outcome.reasonCode,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Activation: ${_short(outcome.activationId)} | '
                      'Guard revision: ${outcome.guardRevision}',
                      style: const TextStyle(color: Colors.white70),
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _short(String value) {
    final String clean = value.trim();

    if (clean.length <= 20) return clean;
    return '${clean.substring(0, 10)}...${clean.substring(clean.length - 8)}';
  }
}
