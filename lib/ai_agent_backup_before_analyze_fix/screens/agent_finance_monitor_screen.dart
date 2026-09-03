import 'package:flutter/material.dart';

import '../models/agent_finance_summary.dart';
import '../services/agent_finance_agent.dart';

// =========================================================
// AI AGENT — FINANCE MONITOR SCREEN
// =========================================================
//
// Standalone Phase 18 screen.
// Monitoring only. No money-action execution button exists.

class AgentFinanceMonitorScreen extends StatefulWidget {
  const AgentFinanceMonitorScreen({super.key});

  @override
  State<AgentFinanceMonitorScreen> createState() =>
      _AgentFinanceMonitorScreenState();
}

class _AgentFinanceMonitorScreenState
    extends State<AgentFinanceMonitorScreen> {
  final AgentFinanceAgent _agent = AgentFinanceAgent();

  AgentFinanceSummary? _summary;
  String? _error;
  bool _busy = false;

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final AgentFinanceSummary summary = await _agent.summary();

      if (mounted) {
        setState(() => _summary = summary);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AgentFinanceSummary? summary = _summary;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('AI Finance Monitor'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ElevatedButton(
            onPressed: _busy ? null : _load,
            child: const Text('LOAD FINANCE SUMMARY'),
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
          if (summary != null) ...<Widget>[
            const SizedBox(height: 16),
            _Metric(label: 'Gross', value: summary.grossRs),
            _Metric(label: 'Commission', value: summary.commissionRs),
            _Metric(label: 'Net', value: summary.netRs),
            _Metric(label: 'Pending', value: summary.pendingRs),
            const SizedBox(height: 10),
            Text(
              'Prepared settlements: ${summary.preparedSettlements}\n'
              'Prepared refunds: ${summary.refundsPrepared}\n'
              'Prepared withdrawals: ${summary.withdrawalsPrepared}',
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 12),
            const Text(
              'Real Wallet/Payment/Commission connectors are NOT attached yet. '
              'This screen cannot move money.',
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final int value;

  const _Metric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A1A),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: Text(
          'Rs $value',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
