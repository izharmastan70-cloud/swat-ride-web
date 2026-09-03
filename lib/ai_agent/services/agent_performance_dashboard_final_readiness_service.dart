import '../constants/agent_performance_dashboard_closeout_constants.dart';
import '../models/agent_performance_dashboard_readiness_input.dart';
import '../models/agent_performance_dashboard_readiness_report.dart';
import 'agent_performance_dashboard_adversarial_gate.dart';

class AgentPerformanceDashboardFinalReadinessService {
  const AgentPerformanceDashboardFinalReadinessService({
    this.adversarialGate = const AgentPerformanceDashboardAdversarialGate(),
  });

  final AgentPerformanceDashboardAdversarialGate adversarialGate;

  AgentPerformanceDashboardReadinessReport evaluate(
    AgentPerformanceDashboardReadinessInput input,
  ) {
    try {
      input.validateStructure();
    } catch (_) {
      return _report(
        status: AgentPerformanceDashboardCloseoutStatus.blockedInvalidMetadata,
        closeoutId: _safeCloseoutId(input.closeoutId),
        foundationReady: false,
        adversarialReady: false,
        coreFailureIsolationReady: true,
        failedScenarioIds: const <String>[],
        reasonCodes: const <String>[
          'invalid_dashboard_closeout_metadata',
          'fail_closed',
          'production_not_active',
        ],
      );
    }

    if (input.productionActivationRequested) {
      return _report(
        status:
            AgentPerformanceDashboardCloseoutStatus.blockedProductionActivation,
        closeoutId: input.closeoutId,
        foundationReady: false,
        adversarialReady: false,
        coreFailureIsolationReady: input.coreFailureIsolationReady,
        failedScenarioIds: const <String>[],
        reasonCodes: const <String>[
          'production_activation_not_allowed_in_phase61_closeout',
          'fail_closed',
          'production_not_active',
        ],
      );
    }

    if (!input.allFoundationLocksReady) {
      return _report(
        status: AgentPerformanceDashboardCloseoutStatus.blockedFoundation,
        closeoutId: input.closeoutId,
        foundationReady: false,
        adversarialReady: false,
        coreFailureIsolationReady: input.coreFailureIsolationReady,
        failedScenarioIds: const <String>[],
        reasonCodes: const <String>[
          'phase61_foundation_lock_missing',
          'fail_closed',
          'production_not_active',
        ],
      );
    }

    final Set<String> presentScenarioIds = input.scenarios
        .map((scenario) => scenario.scenarioId)
        .toSet();

    final Set<String> missingScenarioIds =
        AgentPerformanceDashboardCloseoutScenarioId.required.difference(
          presentScenarioIds,
        );

    if (missingScenarioIds.isNotEmpty) {
      final List<String> missing = missingScenarioIds.toList()..sort();

      return _report(
        status: AgentPerformanceDashboardCloseoutStatus.blockedAdversarial,
        closeoutId: input.closeoutId,
        foundationReady: true,
        adversarialReady: false,
        coreFailureIsolationReady: input.coreFailureIsolationReady,
        failedScenarioIds: missing,
        reasonCodes: const <String>[
          'required_dashboard_adversarial_evidence_missing',
          'fail_closed',
          'production_not_active',
        ],
      );
    }

    final List<String> failed = adversarialGate.failedScenarioIds(
      input.scenarios,
    );

    if (failed.isNotEmpty) {
      return _report(
        status: AgentPerformanceDashboardCloseoutStatus.blockedAdversarial,
        closeoutId: input.closeoutId,
        foundationReady: true,
        adversarialReady: false,
        coreFailureIsolationReady: input.coreFailureIsolationReady,
        failedScenarioIds: failed,
        reasonCodes: const <String>[
          'dashboard_adversarial_safety_failure',
          'fail_closed',
          'production_not_active',
        ],
      );
    }

    return _report(
      status: AgentPerformanceDashboardCloseoutStatus.foundationReady,
      closeoutId: input.closeoutId,
      foundationReady: true,
      adversarialReady: true,
      coreFailureIsolationReady: true,
      failedScenarioIds: const <String>[],
      reasonCodes: const <String>[
        'phase61_dashboard_foundation_ready',
        'read_only_visibility_only',
        'security_authority_above_dashboard',
        'production_not_active',
      ],
    );
  }

  AgentPerformanceDashboardReadinessReport _report({
    required String status,
    required String closeoutId,
    required bool foundationReady,
    required bool adversarialReady,
    required bool coreFailureIsolationReady,
    required List<String> failedScenarioIds,
    required List<String> reasonCodes,
  }) {
    final AgentPerformanceDashboardReadinessReport report =
        AgentPerformanceDashboardReadinessReport(
          status: status,
          closeoutId: closeoutId,
          foundationReady: foundationReady,
          adversarialReady: adversarialReady,
          coreFailureIsolationReady: coreFailureIsolationReady,
          failedScenarioIds: failedScenarioIds,
          reasonCodes: reasonCodes,
        );

    report.validateStructure();
    return report;
  }

  String _safeCloseoutId(String value) {
    final String trimmed = value.trim();
    final RegExp opaqueIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');

    if (trimmed.isEmpty ||
        trimmed != value ||
        trimmed.length >
            AgentPerformanceDashboardCloseoutContract.maxOpaqueIdLength ||
        !opaqueIdPattern.hasMatch(trimmed)) {
      return 'redacted:phase61_closeout';
    }

    return trimmed;
  }
}
