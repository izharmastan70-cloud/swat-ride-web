import 'package:flutter/material.dart';

import '../models/agent_approval_request.dart';
import '../services/agent_security_incident_post_rebind_enable_approval_decision_coordinator.dart';

class AgentSecurityIncidentPostRebindEnableApprovalDecisionScreen
    extends StatefulWidget {
  const AgentSecurityIncidentPostRebindEnableApprovalDecisionScreen({
    super.key,
    required this.currentAdminId,
  });

  final String currentAdminId;

  @override
  State<AgentSecurityIncidentPostRebindEnableApprovalDecisionScreen>
  createState() =>
      _AgentSecurityIncidentPostRebindEnableApprovalDecisionScreenState();
}

class _AgentSecurityIncidentPostRebindEnableApprovalDecisionScreenState
    extends State<AgentSecurityIncidentPostRebindEnableApprovalDecisionScreen> {
  static const String _approvePhrase = 'APPROVE ENABLE';
  static const String _rejectPhrase = 'REJECT ENABLE';

  final TextEditingController _confirmationController = TextEditingController();

  final AgentSecurityIncidentPostRebindEnableApprovalDecisionCoordinator
  _readOnlyCoordinator =
      AgentSecurityIncidentPostRebindEnableApprovalDecisionCoordinator.live();

  bool _working = false;
  String _message = '';

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _approve(AgentApprovalRequest observed) async {
    if (_working) {
      return;
    }

    if (_confirmationController.text.trim() != _approvePhrase) {
      setState(() {
        _message = 'Type exactly "$_approvePhrase" before approval.';
      });
      return;
    }

    setState(() {
      _working = true;
      _message = '';
    });

    try {
      final coordinator =
          AgentSecurityIncidentPostRebindEnableApprovalDecisionCoordinator.live(
            executionArmed: true,
          );

      await coordinator.approveObserved(
        observed: observed,
        currentAdminId: widget.currentAdminId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _message =
            'Exact post-rebind enable approval marked APPROVED. The approval '
            'was NOT consumed, no replacement token was issued, the role was '
            'NOT enabled and the migration hold was NOT released.';
        _confirmationController.clear();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Approval blocked: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  Future<void> _reject(AgentApprovalRequest observed) async {
    if (_working) {
      return;
    }

    if (_confirmationController.text.trim() != _rejectPhrase) {
      setState(() {
        _message = 'Type exactly "$_rejectPhrase" before rejection.';
      });
      return;
    }

    setState(() {
      _working = true;
      _message = '';
    });

    try {
      final coordinator =
          AgentSecurityIncidentPostRebindEnableApprovalDecisionCoordinator.live(
            executionArmed: true,
          );

      await coordinator.rejectObserved(
        observed: observed,
        currentAdminId: widget.currentAdminId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _message =
            'Exact post-rebind enable approval marked REJECTED. No token, role '
            'enable, hold release or runtime action was executed.';
        _confirmationController.clear();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Rejection blocked: $error';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post-Rebind Role Enable Owner Approval'),
      ),
      body: StreamBuilder<List<AgentApprovalRequest>>(
        stream: _readOnlyCoordinator.watchExactPending(),
        builder: (BuildContext context, AsyncSnapshot<List<AgentApprovalRequest>> snapshot) {
          if (snapshot.hasError) {
            return _body(
              child: Text(
                'Exact enable approval read blocked: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData) {
            return _body(
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final List<AgentApprovalRequest> approvals = snapshot.data!;

          if (approvals.isEmpty) {
            return _body(
              child: const Text(
                'No exact fresh PENDING post-rebind role-enable approval is '
                'available. Expired approvals and prior migration/rebind '
                'approvals are never reused.',
              ),
            );
          }

          if (approvals.length != 1) {
            return _body(
              child: Text(
                'Safety stop: expected exactly one exact PENDING enable '
                'approval, found ${approvals.length}.',
              ),
            );
          }

          final AgentApprovalRequest approval = approvals.single;

          return _body(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'EXACT PENDING POST-REBIND ROLE ENABLE APPROVAL FOUND',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Operation: '
                  'ENABLE_SECURITY_INCIDENT_ROLE_AND_RELEASE_MIGRATION_HOLD_23_ROLE',
                ),
                const Text('Target role: security_incident_agent'),
                const Text('Target action: security_incident.attach_runtime'),
                const Text('Rollout remains: MONITOR_ONLY'),
                const Text('Authority manifest: revision 3 / roleCount 23'),
                const Text('Guard: revision 3 / roleCount 23'),
                const Text('Future atomic transaction: 5 writes'),
                const Text('Replacement token consume: REQUIRED'),
                const Text('Role mode after enable: ASK_FIRST'),
                const Text('Repository attach/arm authorized: NO'),
                const Text('Incident write authorized: NO'),
                const Text('SUGGEST_ONLY/AUTO authorized: NO'),
                const SizedBox(height: 12),
                const Text(
                  'Decision only. Immediately before APPROVE/REJECT the app '
                  're-verifies the authenticated Firebase super_admin, UID '
                  'binding, fresh login/auth_time and historical Owner SHA. '
                  'This screen does NOT create or consume the approval, issue '
                  'or consume a replacement token, enable the role, release '
                  'the migration hold, attach/arm the repository or write an '
                  'incident.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmationController,
                  enabled: !_working,
                  decoration: const InputDecoration(
                    labelText: 'Explicit Owner confirmation',
                    helperText: 'APPROVE ENABLE  |  REJECT ENABLE',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _working ? null : () => _approve(approval),
                  child: Text(
                    _working
                        ? 'WORKING...'
                        : 'APPROVE EXACT ROLE ENABLE REQUEST',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _working ? null : () => _reject(approval),
                  child: const Text('REJECT EXACT ROLE ENABLE REQUEST'),
                ),
                if (_message.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(_message),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _body({required Widget child}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ],
    );
  }
}
