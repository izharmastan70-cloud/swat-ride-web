import 'package:flutter/material.dart';

import '../models/agent_production_rollout_monitor_observation_models.dart';
import '../services/agent_production_rollout_monitor_observation_reader.dart';

class AgentProductionRolloutMonitorObservationScreen extends StatefulWidget {
  const AgentProductionRolloutMonitorObservationScreen({
    super.key,
    required this.currentAdminId,
  });

  final String currentAdminId;

  @override
  State<AgentProductionRolloutMonitorObservationScreen> createState() =>
      _AgentProductionRolloutMonitorObservationScreenState();
}

class _AgentProductionRolloutMonitorObservationScreenState
    extends State<AgentProductionRolloutMonitorObservationScreen> {
  final AgentProductionRolloutMonitorObservationReader _reader =
      AgentProductionRolloutMonitorObservationReader();

  bool _working = false;
  String _message =
      'Run a read-only MONITOR_ONLY production stability observation.';
  AgentProductionRolloutMonitorObservation? _observation;

  Future<void> _runObservation() async {
    if (_working) return;

    setState(() {
      _working = true;
      _message = 'Reading live MONITOR_ONLY production safety state...';
      _observation = null;
    });

    try {
      final AgentProductionRolloutMonitorObservation observation = await _reader
          .read(currentAdminId: widget.currentAdminId);

      if (!mounted) return;

      setState(() {
        _observation = observation;
        _message = observation.stable
            ? 'MONITOR_ONLY CORE STABLE. This observation does not authorize '
                  'SUGGEST_ONLY or AUTO.'
            : 'MONITOR_ONLY CORE UNSTABLE. Do not advance rollout.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _message = 'Observation blocked safely: $error';
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
    final AgentProductionRolloutMonitorObservation? observation = _observation;

    return Scaffold(
      appBar: AppBar(title: const Text('MONITOR_ONLY Stability Observation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            color: const Color(0xFF1A1A1A),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'READ-ONLY OBSERVATION. This screen does not write Firestore, '
                'change Agent Modes, change rollout stage, enable providers, '
                'enable external channels, or authorize SUGGEST_ONLY/AUTO.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _working ? null : _runObservation,
            icon: const Icon(Icons.monitor_heart_outlined),
            label: const Text('RUN MONITOR_ONLY STABILITY OBSERVATION'),
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
          if (observation != null) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              color: observation.stable
                  ? const Color(0xFF123B1E)
                  : const Color(0xFF4A1010),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      observation.stable
                          ? 'MONITOR_ONLY_CORE_STABLE'
                          : 'MONITOR_ONLY_CORE_UNSTABLE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _row('Observed UTC', observation.observedAtUtc.toString()),
                    _row(
                      'Since activation',
                      _duration(observation.timeSinceActivation),
                    ),
                    _row('Stage', observation.stage),
                    _row('Activation', _short(observation.activationId)),
                    _row('Guard revision', '${observation.guardRevision}'),
                    _row('Role count', '${observation.roleCount}'),
                    _row(
                      'Enabled AUTO roles',
                      '${observation.enabledAutoRoleCount}',
                    ),
                    _row('AUTO traffic', '${observation.autoTrafficPercent}%'),
                    _row(
                      'Business writes',
                      '${observation.businessWriteTrafficPercent}%',
                    ),
                    _row(
                      'External channels',
                      observation.externalChannelsEnabled ? 'ON' : 'OFF',
                    ),
                    const Divider(),
                    _row('Master', observation.masterEnabled ? 'ON' : 'OFF'),
                    _row(
                      'Emergency read-only',
                      observation.emergencyReadOnly ? 'ACTIVE' : 'OFF',
                    ),
                    _row('Free AI', observation.freeAiEnabled ? 'ON' : 'OFF'),
                    _row('Local AI', observation.localAiEnabled ? 'ON' : 'OFF'),
                    _row(
                      'Paid Code AI',
                      observation.paidCodeAiEnabled ? 'ON' : 'OFF',
                    ),
                    _row(
                      'Paid Reasoning',
                      observation.paidReasoningEnabled ? 'ON' : 'OFF',
                    ),
                    _row(
                      'Call Agent',
                      observation.callAgentEnabled ? 'ON' : 'OFF',
                    ),
                    _row(
                      'Email Agent',
                      observation.emailAgentEnabled ? 'ON' : 'OFF',
                    ),
                    _row(
                      'Customer WhatsApp',
                      observation.customerWhatsAppAgentEnabled ? 'ON' : 'OFF',
                    ),
                    _row(
                      'Owner WhatsApp',
                      observation.ownerWhatsAppAgentEnabled ? 'ON' : 'OFF',
                    ),
                    _row(
                      'Emergency WhatsApp',
                      observation.emergencyWhatsAppAgentEnabled ? 'ON' : 'OFF',
                    ),
                    const Divider(),
                    _row(
                      'Runtime guard',
                      observation.runtimeGuardClean ? 'CLEAN' : 'FAIL',
                    ),
                    _row(
                      'Activation receipt',
                      observation.activationReceiptClean ? 'CLEAN' : 'FAIL',
                    ),
                    _row(
                      'Arming token',
                      observation.armingTokenClean ? 'CLEAN' : 'FAIL',
                    ),
                    _row(
                      'Revision binding',
                      observation.revisionBindingClean ? 'CLEAN' : 'FAIL',
                    ),
                    _row(
                      'Role-count binding',
                      observation.roleCountBindingClean ? 'CLEAN' : 'FAIL',
                    ),
                    _row(
                      'Control binding',
                      observation.controlBindingClean ? 'CLEAN' : 'FAIL',
                    ),
                    _row(
                      'Plan binding',
                      observation.planBindingClean ? 'CLEAN' : 'FAIL',
                    ),
                    _row(
                      'Actor binding',
                      observation.actorBindingClean ? 'CLEAN' : 'FAIL',
                    ),
                    _row(
                      'Approval binding',
                      observation.approvalBindingClean ? 'CLEAN' : 'FAIL',
                    ),
                    if (observation.failureCodes.isNotEmpty) ...<Widget>[
                      const Divider(),
                      const Text(
                        'Failure codes',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        observation.failureCodes.join('\n'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'STEP 1H-A LIMIT: Core stability only. Security incidents, '
                'runtime errors and Owner Attention alerts are audited in the '
                'next Step 1H observation substep before any SUGGEST_ONLY '
                'eligibility decision.',
              ),
            ),
          ),
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
            width: 170,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _short(String value) {
    final String clean = value.trim();

    if (clean.length <= 20) return clean;
    return '${clean.substring(0, 10)}...${clean.substring(clean.length - 8)}';
  }

  String _duration(Duration? duration) {
    if (duration == null) return 'UNKNOWN';

    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    return '${hours}h ${minutes}m ${seconds}s';
  }
}
