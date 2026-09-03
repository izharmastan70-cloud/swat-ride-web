import 'package:flutter/material.dart';

import '../models/admin_intelligence_report.dart';
import '../models/admin_intelligence_signal.dart';

/// Read-only presentation surface for a verified Admin Intelligence report.
///
/// This screen never scans source code, never calls an AI provider, never
/// writes Firestore, and never executes an admin/business action.
///
/// A caller may provide the latest authorized report snapshot. When no report
/// is supplied, the screen shows a safe empty state rather than fabricating
/// findings.
class AdminIntelligenceReportScreen extends StatelessWidget {
  const AdminIntelligenceReportScreen({super.key, this.report});

  final AdminIntelligenceReport? report;

  @override
  Widget build(BuildContext context) {
    final AdminIntelligenceReport? current = report;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(title: const Text('Admin Intelligence')),
      body: current == null
          ? const _EmptyReportState()
          : _ReportBody(report: current),
    );
  }
}

class _EmptyReportState extends StatelessWidget {
  const _EmptyReportState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const <Widget>[
        Card(
          color: Color(0xFF1A1A1A),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'No authorized report snapshot loaded',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Admin Intelligence is monitor/report-first. '
                  'This screen only displays an authorized report snapshot '
                  'provided by the existing read-only report pipeline. '
                  'It does not run provider calls or admin actions.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final AdminIntelligenceReport report;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _SummaryCard(report: report),
        const SizedBox(height: 12),
        if (report.findings.isEmpty)
          const Card(
            color: Color(0xFF1A1A1A),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No verified findings in this report.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        else
          ...report.findings.map(
            (AdminIntelligenceSignal finding) => _FindingCard(finding: finding),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});

  final AdminIntelligenceReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Verified operational report',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Report: ${report.reportId}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              'Verified findings: ${report.findings.length}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              'Read-only: ${report.readOnly ? 'YES' : 'NO'}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              'Automatic action allowed: '
              '${report.automaticActionAllowed ? 'YES' : 'NO'}',
              style: TextStyle(
                color: report.automaticActionAllowed
                    ? Colors.orangeAccent
                    : Colors.greenAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FindingCard extends StatelessWidget {
  const _FindingCard({required this.finding});

  final AdminIntelligenceSignal finding;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              finding.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Area: ${finding.adminArea}',
              style: const TextStyle(color: Colors.white54),
            ),
            Text(
              'Type: ${finding.findingType}',
              style: const TextStyle(color: Colors.white54),
            ),
            Text(
              'Severity: ${finding.severity}',
              style: const TextStyle(color: Colors.white54),
            ),
            Text(
              'Verification: ${finding.verificationStatus}',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
