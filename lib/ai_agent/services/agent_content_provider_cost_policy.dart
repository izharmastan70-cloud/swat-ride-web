import '../constants/agent_content_provider_privacy_safety_constants.dart';
import '../models/agent_content_paid_ai_budget.dart';
import '../models/agent_content_privacy_safe_generation_context.dart';
import '../models/agent_content_provider_route_decision.dart';

class AgentContentProviderCostPolicy {
  const AgentContentProviderCostPolicy();

  AgentContentProviderRouteDecision chooseRoute({
    required AgentContentPrivacySafeGenerationContext context,
    required AgentContentPaidAiBudget budget,
    required bool templateCanHandle,
    required bool freeOnlineAvailable,
    required bool freeOnlineSuitable,
    required bool localAiEnabled,
    required bool localAiAvailable,
    required bool localAiSuitable,
    required bool paidAiNeeded,
  }) {
    try {
      context.validateStructure();
    } catch (_) {
      return _decision(
        status: AgentContentProviderRouteStatus.privacyBlocked,
        requestId: _safeId(context.requestId),
        providerClass: AgentContentProviderClass.templateOrCode,
        paidApprovalRequired: false,
        costLoggingRequired: false,
        reasons: const <String>[
          'invalid_privacy_projection',
          'fail_closed',
          'draft_only',
        ],
      );
    }

    if (!context.privacySafe) {
      return _decision(
        status: AgentContentProviderRouteStatus.privacyBlocked,
        requestId: context.requestId,
        providerClass: AgentContentProviderClass.templateOrCode,
        paidApprovalRequired: false,
        costLoggingRequired: false,
        reasons: const <String>[
          'forbidden_private_data_detected',
          'provider_projection_blocked',
          'fail_closed',
          'draft_only',
        ],
      );
    }

    if (templateCanHandle) {
      return _decision(
        status: AgentContentProviderRouteStatus.useTemplateOrCode,
        requestId: context.requestId,
        providerClass: AgentContentProviderClass.templateOrCode,
        paidApprovalRequired: false,
        costLoggingRequired: false,
        reasons: const <String>[
          'template_or_code_first',
          'no_ai_cost_required',
          'human_review_required',
          'draft_only',
        ],
      );
    }

    if (freeOnlineAvailable && freeOnlineSuitable) {
      return _decision(
        status: AgentContentProviderRouteStatus.useFreeOnline,
        requestId: context.requestId,
        providerClass: AgentContentProviderClass.freeOnline,
        paidApprovalRequired: false,
        costLoggingRequired: false,
        reasons: const <String>[
          'free_ai_first',
          'privacy_safe_projection_only',
          'human_review_required',
          'draft_only',
        ],
      );
    }

    if (localAiEnabled && localAiAvailable && localAiSuitable) {
      return _decision(
        status: AgentContentProviderRouteStatus.useLocalOptional,
        requestId: context.requestId,
        providerClass: AgentContentProviderClass.localOptional,
        paidApprovalRequired: false,
        costLoggingRequired: false,
        reasons: const <String>[
          'local_ai_optional',
          'free_ai_unsuitable_or_unavailable',
          'human_review_required',
          'draft_only',
        ],
      );
    }

    if (!paidAiNeeded) {
      return _decision(
        status: AgentContentProviderRouteStatus.providerUnavailableDraftOnly,
        requestId: context.requestId,
        providerClass: AgentContentProviderClass.templateOrCode,
        paidApprovalRequired: false,
        costLoggingRequired: false,
        reasons: const <String>[
          'no_suitable_provider',
          'system_continues_without_paid_ai',
          'human_review_required',
          'draft_only',
        ],
      );
    }

    if (!budget.valid || !budget.paidAiEnabled) {
      return _decision(
        status: AgentContentProviderRouteStatus.paidDisabled,
        requestId: context.requestId,
        providerClass: AgentContentProviderClass.paid,
        paidApprovalRequired: budget.askBeforePaid,
        costLoggingRequired: true,
        reasons: const <String>[
          'paid_ai_disabled_or_invalid_budget',
          'paid_ai_stops_system_continues',
          'human_review_required',
          'draft_only',
        ],
      );
    }

    if (!budget.budgetAllowsPaid) {
      return _decision(
        status: AgentContentProviderRouteStatus.paidBudgetBlocked,
        requestId: context.requestId,
        providerClass: AgentContentProviderClass.paid,
        paidApprovalRequired: budget.askBeforePaid,
        costLoggingRequired: true,
        reasons: const <String>[
          'paid_budget_limit_reached',
          'paid_ai_stops_system_continues',
          'owner_limits_preserved',
          'human_review_required',
          'draft_only',
        ],
      );
    }

    if (!budget.approvalAllowsPaid) {
      return _decision(
        status: AgentContentProviderRouteStatus.paidApprovalRequired,
        requestId: context.requestId,
        providerClass: AgentContentProviderClass.paid,
        paidApprovalRequired: true,
        costLoggingRequired: true,
        reasons: const <String>[
          'ask_before_paid_required',
          'owner_task_approval_required',
          'human_review_required',
          'draft_only',
        ],
      );
    }

    return _decision(
      status: AgentContentProviderRouteStatus.usePaid,
      requestId: context.requestId,
      providerClass: AgentContentProviderClass.paid,
      paidApprovalRequired: budget.askBeforePaid,
      costLoggingRequired: true,
      reasons: const <String>[
        'paid_ai_last_escalation',
        'paid_ai_enabled',
        'paid_budget_within_limits',
        'paid_approval_satisfied',
        'privacy_safe_projection_only',
        'human_review_required',
        'draft_only',
      ],
    );
  }

  AgentContentProviderRouteDecision _decision({
    required String status,
    required String requestId,
    required String providerClass,
    required bool paidApprovalRequired,
    required bool costLoggingRequired,
    required List<String> reasons,
  }) {
    final AgentContentProviderRouteDecision decision =
        AgentContentProviderRouteDecision(
          status: status,
          requestId: requestId,
          providerClass: providerClass,
          humanReviewRequired: true,
          paidApprovalRequired: paidApprovalRequired,
          costLoggingRequired: costLoggingRequired,
          reasonCodes: reasons,
        );

    decision.validateStructure();
    return decision;
  }

  String _safeId(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'invalid_content_request';
    }

    if (trimmed.length <= AgentContentCostLimits.maxRequestIdLength) {
      return trimmed;
    }

    return trimmed.substring(0, AgentContentCostLimits.maxRequestIdLength);
  }

  bool get routeOrderIsTemplateFreeLocalPaid => true;
  bool get templatesFirst => true;
  bool get freeAiFirst => true;
  bool get localAiOptional => true;
  bool get paidAiLast => true;
  bool get paidAiMasterToggleRequired => true;
  bool get askBeforePaidSupported => true;
  bool get perTaskLimitRequired => true;
  bool get dailyLimitRequired => true;
  bool get monthlyLimitRequired => true;
  bool get costLoggingRequired => true;
  bool get ownerCanChangeLimits => true;
  bool get budgetExhaustionStopsPaidOnly => true;
  bool get budgetExhaustionStopsSystem => false;
  bool get minimumContextProjectionRequired => true;
  bool get privacySafeProjectionRequired => true;
  bool get providerFailureDoesNotBreakCoreApp => true;
  bool get providerCannotPublish => true;
  bool get providerCannotApprove => true;
  bool get providerCannotExecuteBusinessActions => true;
  bool get providerCannotChangeSecurityRules => true;
  bool get providerCannotChangeCostLimits => true;
  bool get providerCannotSelfDeploy => true;
  bool get humanReviewAlwaysRequired => true;
  bool get invokesProvider => false;
  bool get performsBilling => false;
  bool get writesBusinessData => false;
  bool get persistsProviderDecision => false;
  bool get implementsPhase57KnowledgeLibrary => false;
  bool get implementsPhase62SelfDeployment => false;
  bool get implementsPhase63PrivacyUi => false;
}
