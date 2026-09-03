import '../constants/agent_action_ids.dart';
import '../constants/agent_report_constants.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_report.dart';
import '../models/agent_role.dart';
import '../models/agent_tool_request.dart';
import '../models/agent_tool_result.dart';
import 'agent_master_settings_service.dart';
import 'agent_read_only_executor.dart';
import 'agent_role_service.dart';

// =========================================================
// AI AGENT — REPORT SERVICE
// =========================================================
//
// Phase 8 standalone Reports Agent foundation.
//
// The service:
// - uses the existing Permission Engine + Runtime Gate indirectly through
//   AgentReadOnlyExecutor
// - reads AI-owned data only
// - creates no SWAT RIDE business writes
// - never invents Ride/Food/Hotel/Tour/Cargo/Student metrics
//
// Business sections are explicitly marked unavailable until connectors
// are attached in later phases.

class AgentReportService {
  final AgentMasterSettingsService settingsService;
  final AgentRoleService roleService;
  final AgentReadOnlyExecutor readOnlyExecutor;

  AgentReportService({
    AgentMasterSettingsService? settingsService,
    AgentRoleService? roleService,
    AgentReadOnlyExecutor? readOnlyExecutor,
  })  : settingsService =
            settingsService ?? AgentMasterSettingsService(),
        roleService = roleService ?? AgentRoleService(),
        readOnlyExecutor = readOnlyExecutor ?? AgentReadOnlyExecutor();

  Future<AgentReport> buildSystemHealthReport({
    required AgentRole reportsRole,
    required String requestedBy,
  }) async {
    final AgentMasterSettings settings =
        await settingsService.getSettings();

    final AgentToolRequest request = AgentToolRequest(
      requestId: 'report_health_${DateTime.now().microsecondsSinceEpoch}',
      roleId: reportsRole.roleId,
      actionId: AgentActionId.readSystemHealth,
      toolId: 'tool.${AgentActionId.readSystemHealth}',
      requestedBy: requestedBy,
      actionScope: const <String, dynamic>{},
      createdAt: DateTime.now(),
    );

    final AgentToolResult result = await readOnlyExecutor.execute(
      settings: settings,
      role: reportsRole,
      request: request,
    );

    if (!result.isSuccess) {
      return _unavailableReport(
        reportType: AgentReportType.systemHealth,
        title: 'AI System Health',
        warning: result.message,
      );
    }

    final AgentReport report = AgentReport(
      reportId: request.requestId,
      reportType: AgentReportType.systemHealth,
      title: 'AI System Health',
      status: AgentReportStatus.ready,
      summary: Map<String, dynamic>.from(result.data),
      warnings: <String>[
        if (settings.emergencyReadOnly)
          'Emergency Read-Only mode is active.',
        if (!settings.freeAiEnabled)
          'Free AI provider class is currently OFF.',
        if (!settings.paidBudgetAvailable)
          'Paid Code AI budget is unavailable or exhausted.',
      ],
      unavailableSections: const <String>[],
      generatedAt: DateTime.now(),
    );

    report.validate();
    return report;
  }

  Future<AgentReport> buildDailyOwnerBrief({
    required AgentRole reportsRole,
    required String requestedBy,
  }) async {
    // Use the same controlled health read as the factual base.
    final AgentReport health = await buildSystemHealthReport(
      reportsRole: reportsRole,
      requestedBy: requestedBy,
    );

    if (health.status == AgentReportStatus.unavailable) {
      return _unavailableReport(
        reportType: AgentReportType.dailyOwnerBrief,
        title: 'Daily Owner Brief',
        warning: health.warnings.isEmpty
            ? 'System-health source unavailable.'
            : health.warnings.first,
      );
    }

    final List<AgentRole> roles = await roleService.getAllRoles();

    final List<String> disabledRoles = roles
        .where((AgentRole role) => !role.isOperational)
        .map((AgentRole role) => role.roleId)
        .toList(growable: false);

    final List<String> failClosedRoles = roles
        .where((AgentRole role) => role.isFailClosed)
        .map((AgentRole role) => role.roleId)
        .toList(growable: false);

    const List<String> businessSections = <String>[
      'Ride metrics',
      'Driver metrics',
      'Food metrics',
      'Hotel metrics',
      'Tour metrics',
      'Rewards metrics',
      'Cargo metrics',
      'Student Ride metrics',
      'Finance metrics',
    ];

    final Map<String, dynamic> summary = <String, dynamic>{
      ...health.summary,
      'disabledOrInactiveRoles': disabledRoles,
      'failClosedRoleIds': failClosedRoles,
      'businessMetricsConnected': false,
      'note':
          'Business metrics are intentionally unavailable until real module connectors are attached.',
    };

    final AgentReport report = AgentReport(
      reportId: 'daily_${DateTime.now().microsecondsSinceEpoch}',
      reportType: AgentReportType.dailyOwnerBrief,
      title: 'Daily Owner Brief',
      status: AgentReportStatus.partial,
      summary: summary,
      warnings: <String>[
        ...health.warnings,
        if (failClosedRoles.isNotEmpty)
          'One or more agent roles are fail-closed and require repair.',
      ],
      unavailableSections: businessSections,
      generatedAt: DateTime.now(),
    );

    report.validate();
    return report;
  }

  AgentReport _unavailableReport({
    required String reportType,
    required String title,
    required String warning,
  }) {
    final AgentReport report = AgentReport(
      reportId: 'unavailable_${DateTime.now().microsecondsSinceEpoch}',
      reportType: reportType,
      title: title,
      status: AgentReportStatus.unavailable,
      summary: const <String, dynamic>{},
      warnings: <String>[warning],
      unavailableSections: const <String>[],
      generatedAt: DateTime.now(),
    );

    report.validate();
    return report;
  }
}
