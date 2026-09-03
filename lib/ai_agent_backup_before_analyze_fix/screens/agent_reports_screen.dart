import 'package:flutter/material.dart';

import '../constants/agent_report_constants.dart';
import '../models/agent_report.dart';
import '../models/agent_role.dart';
import '../services/agent_report_service.dart';
import '../services/agent_role_service.dart';

// =========================================================
// AI AGENT — REPORTS SCREEN
// =========================================================
//
// Standalone Phase 8 screen.
// No existing SWAT RIDE route/dashboard file is modified.
//
// It uses reports_agent only. If reports_agent does not exist or does not
// have explicit allowedActions, the report fails safely under default-deny.

class AgentReportsScreen extends StatefulWidget {
  final String currentAdminId;

  const AgentReportsScreen({
    super.key,
    required this.currentAdminId,
  });

  @override
  State<AgentReportsScreen> createState() =>
      _AgentReportsScreenState();
}

class _AgentReportsScreenState extends State<AgentReportsScreen> {
  final AgentReportService _reportService = AgentReportService();
  final AgentRoleService _roleService = AgentRoleService();

  AgentReport? _report;
  bool _busy = false;
  String? _error;

  Future<AgentRole> _loadReportsRole() async {
    final AgentRole? role =
        await _roleService.getRole('reports_agent');

    if (role == null) {
      throw StateError(
        'reports_agent is not seeded yet.',
      );
    }

    return role;
  }

  Future<void> _run({
    required bool daily,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final AgentRole role = await _loadReportsRole();

      final AgentReport report = daily
          ? await _reportService.buildDailyOwnerBrief(
              reportsRole: role,
              requestedBy: widget.currentAdminId,
            )
          : await _reportService.buildSystemHealthReport(
              reportsRole: role,
              requestedBy: widget.currentAdminId,
            );

      if (mounted) {
        setState(() => _report = report);
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('AI Reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : () => _run(daily: false),
                  child: const Text('SYSTEM HEALTH'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : () => _run(daily: true),
                  child: const Text('DAILY BRIEF'),
                ),
              ),
            ],
          ),
          if (_busy) ...<Widget>[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (_error != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
          if (_report != null) ...<Widget>[
            const SizedBox(height: 16),
            _ReportCard(report: _report!),
          ],
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final AgentReport report;

  const _ReportCard({
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
        report.status == AgentReportStatus.ready
            ? Colors.greenAccent
            : report.status == AgentReportStatus.partial
                ? Colors.orangeAccent
                : Colors.redAccent;

    return Card(
      color: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              report.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              report.status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              report.summary.toString(),
              style: const TextStyle(color: Colors.white70),
            ),
            if (report.warnings.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              const Text(
                'Warnings',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              for (final String warning in report.warnings)
                Text(
                  '• $warning',
                  style: const TextStyle(color: Colors.white60),
                ),
            ],
            if (report.unavailableSections.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              const Text(
                'Not connected yet',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              for (final String section in report.unavailableSections)
                Text(
                  '• $section',
                  style: const TextStyle(color: Colors.white38),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
