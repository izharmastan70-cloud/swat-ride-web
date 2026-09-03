import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_authorization.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_foundation.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_orchestrated_report.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_query_plan.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_report_orchestration_request.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_response.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_source_acquisition_request.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_verified_report.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_verified_section.dart';
import 'package:swat_ride/ai_agent/services/agent_voice_super_admin_execution_coordinator.dart';
import 'package:swat_ride/ai_agent/services/agent_voice_super_admin_query_planner.dart';

class _FakePlanningGateway implements AgentVoiceSuperAdminQueryPlanningGateway {
  _FakePlanningGateway(this.result);

  final AgentVoiceSuperAdminQueryPlan result;
  int calls = 0;

  @override
  AgentVoiceSuperAdminQueryPlan plan({
    required AgentVoiceSuperAdminQueryPlanningRequest request,
    required DateTime now,
  }) {
    calls += 1;
    return result;
  }
}

class _FakeReportGateway implements AgentVoiceSuperAdminReportExecutionGateway {
  _FakeReportGateway(this.result);

  final AgentVoiceSuperAdminOrchestratedReport result;

  int calls = 0;
  AgentVoiceSuperAdminAuthorizationRequest? lastAuthorizationRequest;
  AgentVoiceSuperAdminSessionBinding? lastSession;
  AgentVoiceSuperAdminReportOrchestrationRequest? lastReportRequest;

  @override
  Future<AgentVoiceSuperAdminOrchestratedReport> build({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentVoiceSuperAdminSessionBinding session,
    required AgentVoiceSuperAdminAuthorizationRequest authorizationRequest,
    required AgentVoiceSuperAdminReportOrchestrationRequest request,
    required DateTime now,
  }) async {
    calls += 1;
    lastAuthorizationRequest = authorizationRequest;
    lastSession = session;
    lastReportRequest = request;
    return result;
  }
}

AgentRole _voiceRole() => buildInitialAgentRoles().firstWhere(
  (AgentRole role) => role.roleId == AgentVoiceSuperAdminFoundation.roleId,
);

AgentMasterSettings _settings() => AgentMasterSettings.safeDefaults().copyWith(
  masterEnabled: true,
  freeAiEnabled: true,
  voiceSuperAdminAgentEnabled: true,
);

AgentVoiceSuperAdminSessionBinding _session() =>
    AgentVoiceSuperAdminSessionBinding(
      principalType: AgentVoiceSuperAdminPrincipalType.superAdmin,
      principalUid: 'owner-1',
      deviceBindingId: 'device-1',
      sessionId: 'session-1',
      verificationLevel: AgentVoiceSuperAdminVerificationLevel.linkedAccount,
      verifiedAt: DateTime.utc(2026, 8, 18, 5),
      expiresAt: DateTime.utc(2026, 8, 18, 8),
    );

AgentVoiceSuperAdminAuthorizationRequest _authorization({
  String actionId = AgentActionId.readVoiceSuperAdminVerifiedReport,
}) => AgentVoiceSuperAdminAuthorizationRequest(
  actionId: actionId,
  actorId: 'owner-1',
  expectedDeviceBindingId: 'device-1',
  expectedSessionId: 'session-1',
);

AgentVoiceSuperAdminQueryPlan _planned() {
  return AgentVoiceSuperAdminQueryPlan(
    status: AgentVoiceSuperAdminQueryPlanStatus.planned,
    code: 'EXPLICIT_VERIFIED_REPORT_REQUEST_PLANNED',
    intent: 'SYSTEM_HEALTH',
    normalizedQuery: 'system health',
    createdAt: DateTime.utc(2026, 8, 18, 6),
    reportRequest: const AgentVoiceSuperAdminReportOrchestrationRequest(
      reportId: 'report-1',
      sourceRequests: <AgentVoiceSuperAdminSourceAcquisitionRequest>[
        AgentVoiceSuperAdminSourceAcquisitionRequest(
          moduleId: 'SYSTEM_HEALTH',
          readKind: AgentVoiceSuperAdminSourceReadKind.status,
        ),
      ],
    ),
  );
}

AgentVoiceSuperAdminQueryPlan _unsupportedPlan() {
  return AgentVoiceSuperAdminQueryPlan(
    status: AgentVoiceSuperAdminQueryPlanStatus.unsupported,
    code: 'QUERY_INTENT_NOT_CONNECTED',
    intent: 'UNSUPPORTED_READ_ONLY_QUERY',
    normalizedQuery: 'random query',
    createdAt: DateTime.utc(2026, 8, 18, 6),
  );
}

AgentVoiceSuperAdminOrchestratedReport _report() {
  final AgentVoiceSuperAdminVerifiedSection section =
      AgentVoiceSuperAdminVerifiedSection.verified(
        moduleId: 'SYSTEM_HEALTH',
        sourceId: 'connector.ai_core.read_only',
        summaryText: 'VERIFIED - aiMasterEnabled: true',
        facts: const <String, Object?>{'aiMasterEnabled': true},
        verifiedAt: DateTime.utc(2026, 8, 18, 6),
      );

  final AgentVoiceSuperAdminVerifiedReport verifiedReport =
      AgentVoiceSuperAdminVerifiedReport(
        reportId: 'report-1',
        status: AgentVoiceSuperAdminReportStatus.ready,
        sections: <AgentVoiceSuperAdminVerifiedSection>[section],
        readableText: 'SYSTEM_HEALTH: VERIFIED - aiMasterEnabled: true',
        createdAt: DateTime.utc(2026, 8, 18, 6),
      );

  final AgentVoiceSuperAdminResponse response = AgentVoiceSuperAdminResponse(
    textOutput: verifiedReport.readableText,
    voicePlaybackEnabled: false,
    voicePlaybackText: null,
    verifiedSourceIds: const <String>['connector.ai_core.read_only'],
    unavailableModuleIds: const <String>[],
    createdAt: DateTime.utc(2026, 8, 18, 6),
  );

  final AgentVoiceSuperAdminOrchestratedReport report =
      AgentVoiceSuperAdminOrchestratedReport(
        verifiedReport: verifiedReport,
        response: response,
      );

  report.validate();
  return report;
}

void main() {
  group('Phase 48 Step 2G execution coordinator', () {
    test('unsupported plan stops before report orchestrator', () async {
      final planning = _FakePlanningGateway(_unsupportedPlan());
      final reportGateway = _FakeReportGateway(_report());

      final coordinator = AgentVoiceSuperAdminExecutionCoordinator(
        queryPlanningGateway: planning,
        reportExecutionGateway: reportGateway,
      );

      final result = await coordinator.execute(
        settings: _settings(),
        role: _voiceRole(),
        session: _session(),
        authorizationRequest: _authorization(),
        queryRequest: const AgentVoiceSuperAdminQueryPlanningRequest(
          queryText: 'random query',
        ),
        now: DateTime.utc(2026, 8, 18, 6),
      );

      expect(planning.calls, 1);
      expect(reportGateway.calls, 0);
      expect(result.isUnsupported, isTrue);
      expect(result.report, isNull);
      expect(result.textOutput, isNull);
    });

    test(
      'planned query passes trusted auth/session unchanged to Step 2E gateway',
      () async {
        final planning = _FakePlanningGateway(_planned());
        final reportGateway = _FakeReportGateway(_report());

        final coordinator = AgentVoiceSuperAdminExecutionCoordinator(
          queryPlanningGateway: planning,
          reportExecutionGateway: reportGateway,
        );

        final AgentVoiceSuperAdminSessionBinding session = _session();
        final AgentVoiceSuperAdminAuthorizationRequest authorization =
            _authorization();

        final result = await coordinator.execute(
          settings: _settings(),
          role: _voiceRole(),
          session: session,
          authorizationRequest: authorization,
          queryRequest: const AgentVoiceSuperAdminQueryPlanningRequest(
            queryText: 'system health',
          ),
          now: DateTime.utc(2026, 8, 18, 6),
        );

        expect(result.isExecuted, isTrue);
        expect(reportGateway.calls, 1);
        expect(reportGateway.lastAuthorizationRequest, same(authorization));
        expect(reportGateway.lastSession, same(session));
        expect(
          reportGateway.lastReportRequest?.sourceRequests.single.moduleId,
          'SYSTEM_HEALTH',
        );
        expect(
          result.textOutput,
          'SYSTEM_HEALTH: VERIFIED - aiMasterEnabled: true',
        );
      },
    );

    test(
      'wrong trusted authorization action stops before orchestrator',
      () async {
        final planning = _FakePlanningGateway(_planned());
        final reportGateway = _FakeReportGateway(_report());

        final result =
            await AgentVoiceSuperAdminExecutionCoordinator(
              queryPlanningGateway: planning,
              reportExecutionGateway: reportGateway,
            ).execute(
              settings: _settings(),
              role: _voiceRole(),
              session: _session(),
              authorizationRequest: _authorization(
                actionId: AgentActionId.readSystemHealth,
              ),
              queryRequest: const AgentVoiceSuperAdminQueryPlanningRequest(
                queryText: 'system health',
              ),
              now: DateTime.utc(2026, 8, 18, 6),
            );

        expect(result.isUnsupported, isTrue);
        expect(
          result.code,
          'VOICE_SUPER_ADMIN_REPORT_AUTHORIZATION_ACTION_REQUIRED',
        );
        expect(reportGateway.calls, 0);
      },
    );

    test(
      'real Step 2F whole-app planner feeds explicit list to execution gateway',
      () async {
        final reportGateway = _FakeReportGateway(_report());

        final coordinator = AgentVoiceSuperAdminExecutionCoordinator(
          queryPlanningGateway:
              const AgentVoiceSuperAdminStep2FQueryPlanningGateway(),
          reportExecutionGateway: reportGateway,
        );

        final result = await coordinator.execute(
          settings: _settings(),
          role: _voiceRole(),
          session: _session(),
          authorizationRequest: _authorization(),
          queryRequest: const AgentVoiceSuperAdminQueryPlanningRequest(
            queryText: 'Mujhe poore SWAT RIDE ka aaj ka haal batao',
          ),
          now: DateTime.utc(2026, 8, 18, 6),
        );

        expect(result.isExecuted, isTrue);
        expect(reportGateway.calls, 1);

        final List<String> modules = reportGateway
            .lastReportRequest!
            .sourceRequests
            .map(
              (AgentVoiceSuperAdminSourceAcquisitionRequest item) =>
                  item.moduleId,
            )
            .toList(growable: false);

        expect(modules, contains('SYSTEM_HEALTH'));
        expect(modules, contains('NORMAL_RIDE'));
        expect(modules, contains('DRIVER'));
        expect(modules, contains('HOTEL'));
        expect(modules, contains('CARGO'));
        expect(modules, contains('AI_USAGE_COST_OWNER_READ'));
        expect(modules.toSet().length, modules.length);
      },
    );

    test(
      'consequential real Step 2F query never reaches execution gateway',
      () async {
        final reportGateway = _FakeReportGateway(_report());

        final result =
            await AgentVoiceSuperAdminExecutionCoordinator(
              queryPlanningGateway:
                  const AgentVoiceSuperAdminStep2FQueryPlanningGateway(),
              reportExecutionGateway: reportGateway,
            ).execute(
              settings: _settings(),
              role: _voiceRole(),
              session: _session(),
              authorizationRequest: _authorization(),
              queryRequest: const AgentVoiceSuperAdminQueryPlanningRequest(
                queryText: 'suspend driver and refund payment',
              ),
              now: DateTime.utc(2026, 8, 18, 6),
            );

        expect(result.isUnsupported, isTrue);
        expect(reportGateway.calls, 0);
      },
    );

    test(
      'coordinator exposes no authority/write/provider/speech capability',
      () {
        final coordinator = AgentVoiceSuperAdminExecutionCoordinator(
          queryPlanningGateway: _FakePlanningGateway(_planned()),
          reportExecutionGateway: _FakeReportGateway(_report()),
        );

        expect(coordinator.queryCreatesAuthorization, isFalse);
        expect(coordinator.queryCreatesSession, isFalse);
        expect(coordinator.queryChangesPrincipalIdentity, isFalse);
        expect(coordinator.querySelectsPermissionAction, isFalse);
        expect(coordinator.usesStep2FPlanner, isTrue);
        expect(coordinator.usesStep2EOrchestrator, isTrue);
        expect(coordinator.sourceAuthorizationRemainsInStep2D, isTrue);

        expect(coordinator.grantsPermission, isFalse);
        expect(coordinator.createsApproval, isFalse);
        expect(coordinator.consumesApproval, isFalse);
        expect(coordinator.writesBusinessData, isFalse);
        expect(coordinator.mutatesSafety, isFalse);
        expect(coordinator.callsProvider, isFalse);
        expect(coordinator.usesSpeechToTextProvider, isFalse);
        expect(coordinator.usesTextToSpeechProvider, isFalse);
        expect(coordinator.storesRawAudio, isFalse);
        expect(coordinator.deploys, isFalse);
      },
    );
  });
}
