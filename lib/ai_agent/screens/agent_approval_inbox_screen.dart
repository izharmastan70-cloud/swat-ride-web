import 'package:flutter/material.dart';

import '../models/agent_approval_request.dart';
import '../services/agent_approval_service.dart';

// =========================================================
// AI AGENT — APPROVAL INBOX SCREEN
// =========================================================
//
// Standalone Phase 3 screen.
// NOT wired into main.dart.
// Human owner/admin identity is passed by caller later.

class AgentApprovalInboxScreen extends StatefulWidget {
  final String currentAdminId;

  const AgentApprovalInboxScreen({
    super.key,
    required this.currentAdminId,
  });

  @override
  State<AgentApprovalInboxScreen> createState() =>
      _AgentApprovalInboxScreenState();
}

class _AgentApprovalInboxScreenState
    extends State<AgentApprovalInboxScreen> {
  final AgentApprovalService _service = AgentApprovalService();

  Future<void> _approve(AgentApprovalRequest request) async {
    try {
      await _service.approve(
        approvalId: request.approvalId,
        decidedBy: widget.currentAdminId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Approval granted for this action.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $error')),
        );
      }
    }
  }

  Future<void> _reject(AgentApprovalRequest request) async {
    try {
      await _service.reject(
        approvalId: request.approvalId,
        decidedBy: widget.currentAdminId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Approval rejected.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reject failed: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('AI Approval Inbox'),
      ),
      body: StreamBuilder<List<AgentApprovalRequest>>(
        stream: _service.watchPendingRequests(),
        builder: (
          BuildContext context,
          AsyncSnapshot<List<AgentApprovalRequest>> snapshot,
        ) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading approvals: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<AgentApprovalRequest> requests = snapshot.data!;

          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'No pending AI approvals.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (BuildContext _, int _) =>
                const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final AgentApprovalRequest request = requests[index];

              return Card(
                color: const Color(0xFF1A1A1A),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        request.actionId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Role: ${request.roleId}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Module: ${request.module}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Risk: ${request.risk}',
                        style: const TextStyle(color: Colors.orangeAccent),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.reason,
                        style: const TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scope: ${request.actionScope}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _reject(request),
                              child: const Text('REJECT'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _approve(request),
                              child: const Text('APPROVE'),
                            ),
                          ),
                        ],
                      ),
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
