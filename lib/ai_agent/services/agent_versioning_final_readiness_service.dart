import '../constants/agent_versioning_closeout_constants.dart';
import '../models/agent_versioning_final_readiness_input.dart';
import '../models/agent_versioning_final_readiness_report.dart';

class AgentVersioningFinalReadinessService {
  const AgentVersioningFinalReadinessService();

  AgentVersioningFinalReadinessReport evaluate(
    AgentVersioningFinalReadinessInput input,
  ) {
    if (input.forbiddenProductionActionRequested) {
      return _report(
        status: AgentVersioningCloseoutContract.blockedProductionActivation,
        reason: 'phase66_production_activation_required',
      );
    }

    if (!input.foundationReady) {
      return _report(
        status: AgentVersioningCloseoutContract.blockedFoundation,
        reason: 'phase62_foundation_incomplete',
      );
    }

    if (!input.securityReady) {
      return _report(
        status: AgentVersioningCloseoutContract.blockedSecurity,
        reason: 'security_or_failure_isolation_boundary_not_ready',
      );
    }

    return _report(
      status:
          AgentVersioningCloseoutContract.foundationReadyNotProductionActive,
      reason: 'phase62_foundation_ready_phase66_still_required',
    );
  }

  AgentVersioningFinalReadinessReport _report({
    required String status,
    required String reason,
  }) {
    return AgentVersioningFinalReadinessReport(
      contractVersion: AgentVersioningCloseoutContract.contractVersion,
      status: status,
      reasonCode: reason,
    );
  }

  bool get phase66Required => true;
  bool get persistsReport => false;
  bool get callsProvider => false;
  bool get trainsModel => false;
  bool get mutatesPrompt => false;
  bool get deploysVersion => false;
  bool get activatesProduction => false;
  bool get authorizesAutoMode => false;
  bool get authorizesFullSafeAuto => false;
  bool get executesRollback => false;
  bool get restoresBackup => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get overridesRuntimeGate => false;
  bool get overridesSecurity => false;
  bool get writesBusinessData => false;
}
