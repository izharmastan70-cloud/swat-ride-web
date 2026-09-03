import '../constants/agent_action_ids.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_role.dart';
import '../models/agent_voice_super_admin_authorization.dart';
import '../models/agent_voice_super_admin_execution_result.dart';
import '../models/agent_voice_super_admin_orchestrated_report.dart';
import '../models/agent_voice_super_admin_query_plan.dart';
import '../models/agent_voice_super_admin_report_orchestration_request.dart';
import 'agent_voice_super_admin_query_planner.dart';
import 'agent_voice_super_admin_report_orchestrator.dart';

abstract class AgentVoiceSuperAdminQueryPlanningGateway {
  AgentVoiceSuperAdminQueryPlan plan({
    required AgentVoiceSuperAdminQueryPlanningRequest request,
    required DateTime now,
  });
}

class AgentVoiceSuperAdminStep2FQueryPlanningGateway
    implements AgentVoiceSuperAdminQueryPlanningGateway {
  const AgentVoiceSuperAdminStep2FQueryPlanningGateway({
    this.planner = const AgentVoiceSuperAdminQueryPlanner(),
  });

  final AgentVoiceSuperAdminQueryPlanner planner;

  @override
  AgentVoiceSuperAdminQueryPlan plan({
    required AgentVoiceSuperAdminQueryPlanningRequest request,
    required DateTime now,
  }) {
    return planner.plan(request: request, now: now);
  }
}

abstract class AgentVoiceSuperAdminReportExecutionGateway {
  Future<AgentVoiceSuperAdminOrchestratedReport> build({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentVoiceSuperAdminSessionBinding session,
    required AgentVoiceSuperAdminAuthorizationRequest authorizationRequest,
    required AgentVoiceSuperAdminReportOrchestrationRequest request,
    required DateTime now,
  });
}

class AgentVoiceSuperAdminStep2EReportExecutionGateway
    implements AgentVoiceSuperAdminReportExecutionGateway {
  const AgentVoiceSuperAdminStep2EReportExecutionGateway({
    required this.orchestrator,
  });

  final AgentVoiceSuperAdminReportOrchestrator orchestrator;

  @override
  Future<AgentVoiceSuperAdminOrchestratedReport> build({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentVoiceSuperAdminSessionBinding session,
    required AgentVoiceSuperAdminAuthorizationRequest authorizationRequest,
    required AgentVoiceSuperAdminReportOrchestrationRequest request,
    required DateTime now,
  }) {
    return orchestrator.build(
      settings: settings,
      role: role,
      session: session,
      authorizationRequest: authorizationRequest,
      request: request,
      now: now,
    );
  }
}

/// Phase 48 Step 2G end-to-end read/report coordinator.
///
/// The coordinator deliberately separates untrusted query intent from trusted
/// authorization/session inputs:
///
/// query text / future STT transcript
///   -> Step 2F deterministic plan
///   -> explicit report request
///   -> Step 2E orchestration
///   -> Step 2D per-source authorization + registered read-only acquisition
///
/// The query can never create, replace or widen the Owner session,
/// authorization action, principal identity or permission.
class AgentVoiceSuperAdminExecutionCoordinator {
  const AgentVoiceSuperAdminExecutionCoordinator({
    required this.queryPlanningGateway,
    required this.reportExecutionGateway,
  });

  final AgentVoiceSuperAdminQueryPlanningGateway queryPlanningGateway;
  final AgentVoiceSuperAdminReportExecutionGateway reportExecutionGateway;

  Future<AgentVoiceSuperAdminExecutionResult> execute({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentVoiceSuperAdminSessionBinding session,
    required AgentVoiceSuperAdminAuthorizationRequest authorizationRequest,
    required AgentVoiceSuperAdminQueryPlanningRequest queryRequest,
    required DateTime now,
  }) async {
    final AgentVoiceSuperAdminQueryPlan plan = queryPlanningGateway.plan(
      request: queryRequest,
      now: now,
    );

    plan.validate();

    if (!plan.isPlanned) {
      return _unsupported(plan: plan, code: plan.code, now: now);
    }

    // Fail closed before orchestration if the surrounding trusted flow did not
    // supply the dedicated Voice Super Admin read/report authorization action.
    // Query text cannot select this action.
    if (authorizationRequest.actionId !=
        AgentActionId.readVoiceSuperAdminVerifiedReport) {
      return _unsupported(
        plan: plan,
        code: 'VOICE_SUPER_ADMIN_REPORT_AUTHORIZATION_ACTION_REQUIRED',
        now: now,
      );
    }

    final AgentVoiceSuperAdminReportOrchestrationRequest reportRequest =
        plan.reportRequest!;

    reportRequest.validate();

    final AgentVoiceSuperAdminOrchestratedReport report =
        await reportExecutionGateway.build(
          settings: settings,
          role: role,
          session: session,
          authorizationRequest: authorizationRequest,
          request: reportRequest,
          now: now,
        );

    report.validate();

    final AgentVoiceSuperAdminExecutionResult result =
        AgentVoiceSuperAdminExecutionResult(
          status: AgentVoiceSuperAdminExecutionStatus.executed,
          code: 'VERIFIED_REPORT_EXECUTED',
          queryPlan: plan,
          report: report,
          createdAt: now,
        );

    result.validate();
    return result;
  }

  AgentVoiceSuperAdminExecutionResult _unsupported({
    required AgentVoiceSuperAdminQueryPlan plan,
    required String code,
    required DateTime now,
  }) {
    final AgentVoiceSuperAdminExecutionResult result =
        AgentVoiceSuperAdminExecutionResult(
          status: AgentVoiceSuperAdminExecutionStatus.unsupported,
          code: code,
          queryPlan: plan,
          createdAt: now,
        );

    result.validate();
    return result;
  }

  bool get queryCreatesAuthorization => false;
  bool get queryCreatesSession => false;
  bool get queryChangesPrincipalIdentity => false;
  bool get querySelectsPermissionAction => false;
  bool get usesStep2FPlanner => true;
  bool get usesStep2EOrchestrator => true;
  bool get sourceAuthorizationRemainsInStep2D => true;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get writesBusinessData => false;
  bool get mutatesSafety => false;
  bool get callsProvider => false;
  bool get usesSpeechToTextProvider => false;
  bool get usesTextToSpeechProvider => false;
  bool get storesRawAudio => false;
  bool get deploys => false;
}
