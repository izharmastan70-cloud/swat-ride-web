import '../constants/agent_report_constants.dart';

// =========================================================
// AI AGENT — REPORT MODEL
// =========================================================
//
// Phase 8 reports are deterministic/read-only summaries.
// No AI provider is required yet.
// Business-module metrics remain unavailable until real connectors exist.

class AgentReport {
  final String reportId;
  final String reportType;
  final String title;
  final String status;
  final Map<String, dynamic> summary;
  final List<String> warnings;
  final List<String> unavailableSections;
  final DateTime generatedAt;

  const AgentReport({
    required this.reportId,
    required this.reportType,
    required this.title,
    required this.status,
    required this.summary,
    required this.warnings,
    required this.unavailableSections,
    required this.generatedAt,
  });

  void validate() {
    if (reportId.trim().isEmpty) {
      throw const AgentReportValidationException(
        'reportId cannot be empty.',
      );
    }

    if (!AgentReportType.isValid(reportType)) {
      throw AgentReportValidationException(
        'Unknown reportType "$reportType".',
      );
    }

    if (!AgentReportStatus.isValid(status)) {
      throw AgentReportValidationException(
        'Unknown report status "$status".',
      );
    }
  }
}

class AgentReportValidationException implements Exception {
  final String message;

  const AgentReportValidationException(this.message);

  @override
  String toString() => 'AgentReportValidationException: $message';
}
