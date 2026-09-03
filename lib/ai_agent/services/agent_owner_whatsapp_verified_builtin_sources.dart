import '../models/agent_approval_request.dart';
import '../models/agent_crash_event.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_owner_whatsapp_verified_report.dart';
import '../models/agent_role.dart';
import 'agent_approval_service.dart';
import 'agent_crash_event_service.dart';
import 'agent_master_settings_service.dart';
import 'agent_owner_whatsapp_verified_report_source.dart';
import 'agent_role_service.dart';
import 'agent_security_agent_service.dart';

typedef AgentOwnerWhatsAppPendingApprovalLoader =
    Future<List<AgentApprovalRequest>> Function();

typedef AgentOwnerWhatsAppRoleLoader = Future<List<AgentRole>> Function();

typedef AgentOwnerWhatsAppSettingsLoader =
    Future<AgentMasterSettings> Function();

typedef AgentOwnerWhatsAppOpenCrashLoader =
    Future<List<AgentCrashEvent>> Function();

typedef AgentOwnerWhatsAppNowProvider = DateTime Function();

/// Current pending-approval snapshot.
///
/// This is intentionally NOT a historical approval activity report.
/// It exposes only privacy-minimized counts and never actionScope/requestedBy.
class AgentOwnerWhatsAppPendingApprovalsReportSource
    implements AgentOwnerWhatsAppVerifiedReportSource {
  AgentOwnerWhatsAppPendingApprovalsReportSource({
    required this._loader,
    AgentOwnerWhatsAppNowProvider? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  factory AgentOwnerWhatsAppPendingApprovalsReportSource.production() {
    final AgentApprovalService service = AgentApprovalService();

    return AgentOwnerWhatsAppPendingApprovalsReportSource(
      loader: () => service.watchPendingRequests().first,
    );
  }

  final AgentOwnerWhatsAppPendingApprovalLoader _loader;
  final AgentOwnerWhatsAppNowProvider _nowProvider;

  @override
  String get sourceId => 'owner_report.approvals.current_pending';

  @override
  Set<String> get supportedSectionIds => const <String>{
    AgentOwnerWhatsAppReportSectionId.approvals,
  };

  @override
  Future<AgentOwnerWhatsAppVerifiedReportSectionResult> fetchVerifiedSection({
    required String sectionId,
    required AgentOwnerWhatsAppVerifiedReportRequest request,
  }) async {
    if (sectionId != AgentOwnerWhatsAppReportSectionId.approvals) {
      throw const AgentOwnerWhatsAppVerifiedReportException(
        'Pending approval source received an unsupported section.',
      );
    }

    final List<AgentApprovalRequest> approvals = await _loader();
    final DateTime snapshotNow = _nowProvider().toUtc();

    final Map<String, int> byRisk = <String, int>{};
    final Map<String, int> byModule = <String, int>{};

    DateTime? oldestCreatedAt;

    for (final AgentApprovalRequest item in approvals) {
      item.validate();

      final bool expiredAtSnapshot = !item.expiresAt.toUtc().isAfter(
        snapshotNow,
      );

      if (!item.isPending || expiredAtSnapshot) {
        continue;
      }

      byRisk[item.risk] = (byRisk[item.risk] ?? 0) + 1;
      byModule[item.module] = (byModule[item.module] ?? 0) + 1;

      if (oldestCreatedAt == null || item.createdAt.isBefore(oldestCreatedAt)) {
        oldestCreatedAt = item.createdAt;
      }
    }

    final int pendingCount = byRisk.values.fold<int>(
      0,
      (int total, int value) => total + value,
    );

    return AgentOwnerWhatsAppVerifiedReportSectionResult.verified(
      sectionId: sectionId,
      sourceId: sourceId,
      data: <String, dynamic>{
        'coverageType': 'current_pending_snapshot',
        'requestedRangeApplied': false,
        'pendingApprovalCount': pendingCount,
        'pendingByRisk': byRisk,
        'pendingByModule': byModule,
        'oldestPendingCreatedAt': oldestCreatedAt?.toUtc().toIso8601String(),
        'containsActionScope': false,
        'containsRequesterIdentity': false,
      },
      generatedAt: _nowProvider().toUtc(),
    );
  }
}

/// Current AI control-plane/role status snapshot.
///
/// It is not a historical time-range metric.
class AgentOwnerWhatsAppAgentStatusReportSource
    implements AgentOwnerWhatsAppVerifiedReportSource {
  AgentOwnerWhatsAppAgentStatusReportSource({
    required this._roleLoader,
    required this._settingsLoader,
    AgentOwnerWhatsAppNowProvider? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  factory AgentOwnerWhatsAppAgentStatusReportSource.production() {
    final AgentRoleService roleService = AgentRoleService();
    final AgentMasterSettingsService settingsService =
        AgentMasterSettingsService();

    return AgentOwnerWhatsAppAgentStatusReportSource(
      roleLoader: roleService.getAllRoles,
      settingsLoader: settingsService.getSettings,
    );
  }

  final AgentOwnerWhatsAppRoleLoader _roleLoader;
  final AgentOwnerWhatsAppSettingsLoader _settingsLoader;
  final AgentOwnerWhatsAppNowProvider _nowProvider;

  @override
  String get sourceId => 'owner_report.agent_status.current';

  @override
  Set<String> get supportedSectionIds => const <String>{
    AgentOwnerWhatsAppReportSectionId.agentStatus,
  };

  @override
  Future<AgentOwnerWhatsAppVerifiedReportSectionResult> fetchVerifiedSection({
    required String sectionId,
    required AgentOwnerWhatsAppVerifiedReportRequest request,
  }) async {
    if (sectionId != AgentOwnerWhatsAppReportSectionId.agentStatus) {
      throw const AgentOwnerWhatsAppVerifiedReportException(
        'Agent status source received an unsupported section.',
      );
    }

    final List<AgentRole> roles = await _roleLoader();
    final AgentMasterSettings settings = await _settingsLoader();

    int operational = 0;
    int failClosed = 0;
    int disabledOrInactive = 0;
    bool ownerWhatsAppRolePresent = false;
    bool ownerWhatsAppRoleOperational = false;

    for (final AgentRole role in roles) {
      if (role.isOperational) {
        operational++;
      } else {
        disabledOrInactive++;
      }

      if (role.isFailClosed) {
        failClosed++;
      }

      if (role.roleId == 'owner_whatsapp_agent') {
        ownerWhatsAppRolePresent = true;
        ownerWhatsAppRoleOperational = role.isOperational;
      }
    }

    return AgentOwnerWhatsAppVerifiedReportSectionResult.verified(
      sectionId: sectionId,
      sourceId: sourceId,
      data: <String, dynamic>{
        'coverageType': 'current_control_plane_snapshot',
        'requestedRangeApplied': false,
        'roleCount': roles.length,
        'operationalRoleCount': operational,
        'disabledOrInactiveRoleCount': disabledOrInactive,
        'failClosedRoleCount': failClosed,
        'ownerWhatsAppRolePresent': ownerWhatsAppRolePresent,
        'ownerWhatsAppRoleOperational': ownerWhatsAppRoleOperational,
        'masterEnabled': settings.masterEnabled,
        'emergencyReadOnly': settings.emergencyReadOnly,
        'freeAiEnabled': settings.freeAiEnabled,
        'localAiEnabled': settings.localAiEnabled,
        'paidCodeAiEnabled': settings.paidCodeAiEnabled,
        'callAgentEnabled': settings.callAgentEnabled,
        'emailAgentEnabled': settings.emailAgentEnabled,
        'customerWhatsAppAgentEnabled': settings.customerWhatsAppAgentEnabled,
        'ownerWhatsAppAgentEnabled': settings.ownerWhatsAppAgentEnabled,
        'approvalEngineEnabled': settings.approvalEngineEnabled,
        'auditLoggingEnabled': settings.auditLoggingEnabled,
      },
      generatedAt: _nowProvider().toUtc(),
    );
  }
}

/// Current security configuration snapshot.
///
/// Uses the existing pure read/audit security service. No security mutation,
/// suspension, permission change or connector activation is performed.
class AgentOwnerWhatsAppSecurityReportSource
    implements AgentOwnerWhatsAppVerifiedReportSource {
  AgentOwnerWhatsAppSecurityReportSource({
    required this._roleLoader,
    required this._settingsLoader,
    this._securityService = const AgentSecurityAgentService(),
    AgentOwnerWhatsAppNowProvider? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  factory AgentOwnerWhatsAppSecurityReportSource.production() {
    final AgentRoleService roleService = AgentRoleService();
    final AgentMasterSettingsService settingsService =
        AgentMasterSettingsService();

    return AgentOwnerWhatsAppSecurityReportSource(
      roleLoader: roleService.getAllRoles,
      settingsLoader: settingsService.getSettings,
    );
  }

  final AgentOwnerWhatsAppRoleLoader _roleLoader;
  final AgentOwnerWhatsAppSettingsLoader _settingsLoader;
  final AgentSecurityAgentService _securityService;
  final AgentOwnerWhatsAppNowProvider _nowProvider;

  @override
  String get sourceId => 'owner_report.security.current_audit';

  @override
  Set<String> get supportedSectionIds => const <String>{
    AgentOwnerWhatsAppReportSectionId.security,
  };

  @override
  Future<AgentOwnerWhatsAppVerifiedReportSectionResult> fetchVerifiedSection({
    required String sectionId,
    required AgentOwnerWhatsAppVerifiedReportRequest request,
  }) async {
    if (sectionId != AgentOwnerWhatsAppReportSectionId.security) {
      throw const AgentOwnerWhatsAppVerifiedReportException(
        'Security source received an unsupported section.',
      );
    }

    final List<AgentRole> roles = await _roleLoader();
    final AgentMasterSettings settings = await _settingsLoader();

    final AgentSecurityAuditReport audit = _securityService.audit(
      roles: roles,
      configuration: <String, dynamic>{
        'masterEnabled': settings.masterEnabled,
        'emergencyReadOnly': settings.emergencyReadOnly,
        'freeAiEnabled': settings.freeAiEnabled,
        'localAiEnabled': settings.localAiEnabled,
        'paidCodeAiEnabled': settings.paidCodeAiEnabled,
        'callAgentEnabled': settings.callAgentEnabled,
        'emailAgentEnabled': settings.emailAgentEnabled,
        'customerWhatsAppAgentEnabled': settings.customerWhatsAppAgentEnabled,
        'ownerWhatsAppAgentEnabled': settings.ownerWhatsAppAgentEnabled,
        'approvalEngineEnabled': settings.approvalEngineEnabled,
        'auditLoggingEnabled': settings.auditLoggingEnabled,
      },
    );

    return AgentOwnerWhatsAppVerifiedReportSectionResult.verified(
      sectionId: sectionId,
      sourceId: sourceId,
      data: <String, dynamic>{
        'coverageType': 'current_configuration_audit',
        'requestedRangeApplied': false,
        'totalFindingCount': audit.total,
        'criticalFindingCount': audit.criticalCount,
        'highFindingCount': audit.highCount,
        'warningFindingCount': audit.warningCount,
        'infoFindingCount': audit.infoCount,
        'hasCritical': audit.hasCritical,
        'hasHighOrCritical': audit.hasHighOrCritical,
        'findingDetailsIncluded': false,
        'secretValuesIncluded': false,
      },
      generatedAt: _nowProvider().toUtc(),
    );
  }
}

/// Current OPEN/CLASSIFIED/HANDED-TO-CODE crash snapshot.
///
/// It deliberately does not claim to be a historical "crashes today" count
/// because the existing service exposes current-open state, not a date query.
class AgentOwnerWhatsAppOpenCrashReportSource
    implements AgentOwnerWhatsAppVerifiedReportSource {
  AgentOwnerWhatsAppOpenCrashReportSource({
    required this._loader,
    AgentOwnerWhatsAppNowProvider? nowProvider,
  }) : _nowProvider = nowProvider ?? DateTime.now;

  factory AgentOwnerWhatsAppOpenCrashReportSource.production() {
    final AgentCrashEventService service = AgentCrashEventService();

    return AgentOwnerWhatsAppOpenCrashReportSource(
      loader: () => service.watchOpen().first,
    );
  }

  final AgentOwnerWhatsAppOpenCrashLoader _loader;
  final AgentOwnerWhatsAppNowProvider _nowProvider;

  @override
  String get sourceId => 'owner_report.crashes.current_open';

  @override
  Set<String> get supportedSectionIds => const <String>{
    AgentOwnerWhatsAppReportSectionId.crashes,
  };

  @override
  Future<AgentOwnerWhatsAppVerifiedReportSectionResult> fetchVerifiedSection({
    required String sectionId,
    required AgentOwnerWhatsAppVerifiedReportRequest request,
  }) async {
    if (sectionId != AgentOwnerWhatsAppReportSectionId.crashes) {
      throw const AgentOwnerWhatsAppVerifiedReportException(
        'Open crash source received an unsupported section.',
      );
    }

    final List<AgentCrashEvent> crashes = await _loader();

    final Map<String, int> bySeverity = <String, int>{};
    final Map<String, int> byModule = <String, int>{};
    int totalOccurrences = 0;
    DateTime? latestSeenAt;

    for (final AgentCrashEvent event in crashes) {
      event.validate();

      bySeverity[event.severity] = (bySeverity[event.severity] ?? 0) + 1;
      byModule[event.module] = (byModule[event.module] ?? 0) + 1;
      totalOccurrences += event.occurrenceCount;

      if (latestSeenAt == null || event.lastSeenAt.isAfter(latestSeenAt)) {
        latestSeenAt = event.lastSeenAt;
      }
    }

    return AgentOwnerWhatsAppVerifiedReportSectionResult.verified(
      sectionId: sectionId,
      sourceId: sourceId,
      data: <String, dynamic>{
        'coverageType': 'current_open_crash_snapshot',
        'requestedRangeApplied': false,
        'openCrashFingerprintCount': crashes.length,
        'totalOpenCrashOccurrences': totalOccurrences,
        'openCrashBySeverity': bySeverity,
        'openCrashByModule': byModule,
        'latestOpenCrashSeenAt': latestSeenAt?.toUtc().toIso8601String(),
        'messageIncluded': false,
        'stackIncluded': false,
        'crashIdIncluded': false,
      },
      generatedAt: _nowProvider().toUtc(),
    );
  }
}

/// Production source registry for Phase 46 Step 8C.
///
/// Intentionally connected now:
/// - current pending approvals
/// - current AI Agent status
/// - current security audit summary
/// - current open crash summary
///
/// Intentionally NOT connected because the exact safe read contract is absent
/// or business data is not really attached:
/// - completed/failed task history
/// - Ride/Food/Hotel/Tour/Cargo/Student aggregate metrics
/// - real revenue/finance totals
/// - complaints/refunds/disputes
/// - development status
/// - agent activity history
/// - recommendations
class AgentOwnerWhatsAppVerifiedBuiltInSources {
  AgentOwnerWhatsAppVerifiedBuiltInSources._();

  static List<AgentOwnerWhatsAppVerifiedReportSource> production() {
    return <AgentOwnerWhatsAppVerifiedReportSource>[
      AgentOwnerWhatsAppPendingApprovalsReportSource.production(),
      AgentOwnerWhatsAppAgentStatusReportSource.production(),
      AgentOwnerWhatsAppSecurityReportSource.production(),
      AgentOwnerWhatsAppOpenCrashReportSource.production(),
    ];
  }

  static Set<String> get connectedSectionIds => const <String>{
    AgentOwnerWhatsAppReportSectionId.approvals,
    AgentOwnerWhatsAppReportSectionId.agentStatus,
    AgentOwnerWhatsAppReportSectionId.security,
    AgentOwnerWhatsAppReportSectionId.crashes,
  };
}
