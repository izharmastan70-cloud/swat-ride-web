import 'package:flutter/material.dart';

import '../models/agent_approval_request.dart';
import '../services/agent_security_incident_post_migration_rebind_approval_decision_coordinator.dart';

class AgentSecurityIncidentPostMigrationRebindApprovalDecisionScreen
    extends StatefulWidget {
  const AgentSecurityIncidentPostMigrationRebindApprovalDecisionScreen({
    super.key,
    required this.currentAdminId,
  });

  final String currentAdminId;

  @override
  State<AgentSecurityIncidentPostMigrationRebindApprovalDecisionScreen>
  createState() =>
      _AgentSecurityIncidentPostMigrationRebindApprovalDecisionScreenState();
}

class _AgentSecurityIncidentPostMigrationRebindApprovalDecisionScreenState
    extends
        State<AgentSecurityIncidentPostMigrationRebindApprovalDecisionScreen> {
  static const String _approvePhrase = 'APPROVE REBIND';
  static const String _rejectPhrase = 'REJECT REBIND';

  final TextEditingController _confirmationController = TextEditingController();

  final AgentSecurityIncidentPostMigrationRebindApprovalDecisionCoordinator
  _readOnlyCoordinator =
      AgentSecurityIncidentPostMigrationRebindApprovalDecisionCoordinator.live();

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
          AgentSecurityIncidentPostMigrationRebindApprovalDecisionCoordinator.live(
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
            'Exact rebind approval marked APPROVED. Approval was NOT consumed '
            'and live rebind was NOT executed.';
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
          AgentSecurityIncidentPostMigrationRebindApprovalDecisionCoordinator.live(
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
            'Exact rebind approval marked REJECTED. No rebind/runtime action '
            'was executed.';
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
      appBar: AppBar(title: const Text('Post-Migration Rebind Owner Approval')),
      body: StreamBuilder<List<AgentApprovalRequest>>(
        stream: _readOnlyCoordinator.watchExactPending(),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<AgentApprovalRequest>> snapshot,
            ) {
              if (snapshot.hasError) {
                return _body(
                  child: Text(
                    'Exact rebind approval read blocked: ${snapshot.error}',
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
                    'No exact fresh PENDING post-migration rebind approval is '
                    'available. Expired approvals are never reused. Create a new '
                    'short-lived approval only after the exact live preflight.',
                  ),
                );
              }

              if (approvals.length != 1) {
                return _body(
                  child: Text(
                    'Safety stop: expected exactly one exact PENDING rebind '
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
                      'EXACT PENDING POST-MIGRATION REBIND APPROVAL FOUND',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Operation: '
                      'REBIND_SECURITY_INCIDENT_POST_MIGRATION_AUTHORITY_23_ROLE',
                    ),
                    const Text('Target role: security_incident_agent'),
                    const Text(
                      'Target action: security_incident.attach_runtime',
                    ),
                    const Text('Rollout stage: MONITOR_ONLY'),
                    const Text('Authority manifest: revision 2 → 3'),
                    const Text(
                      'Guard: revision 2 / roleCount 22 → revision 3 / 23',
                    ),
                    const Text('Role enable authorized: NO'),
                    const Text('Migration-hold release authorized: NO'),
                    const Text('Old token reuse: NO'),
                    const SizedBox(height: 12),
                    const Text(
                      'Decision only. Immediately before APPROVE/REJECT the app '
                      're-verifies the authenticated Firebase super_admin, UID '
                      'binding, fresh login/auth_time and historical consumed '
                      'Issue 11 Owner SHA. This screen does NOT consume the '
                      'approval, execute the six-write rebind, create a token or '
                      'receipt, enable the role, release the hold, attach/arm the '
                      'repository, or write an incident.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmationController,
                      enabled: !_working,
                      decoration: const InputDecoration(
                        labelText: 'Explicit Owner confirmation',
                        helperText: 'APPROVE REBIND  |  REJECT REBIND',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _working ? null : () => _approve(approval),
                      child: Text(
                        _working
                            ? 'WORKING...'
                            : 'APPROVE EXACT REBIND REQUEST',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _working ? null : () => _reject(approval),
                      child: const Text('REJECT EXACT REBIND REQUEST'),
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
