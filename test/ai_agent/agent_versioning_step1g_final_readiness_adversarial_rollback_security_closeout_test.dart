import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_versioning_closeout_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_versioning_final_readiness_input.dart';
import 'package:swat_ride/ai_agent/services/agent_versioning_final_readiness_service.dart';

void main() {
  const AgentVersioningFinalReadinessService service =
      AgentVersioningFinalReadinessService();

  AgentVersioningFinalReadinessInput input({
    bool versionContractReady = true,
    bool evaluationBindingReady = true,
    bool testEnvironmentReady = true,
    bool limitedRolloutReady = true,
    bool monitoringRollbackReady = true,
    bool fullRolloutEligibilityReady = true,
    bool knownGoodRollbackReady = true,
    bool phase42ImmutableEvidenceReady = true,
    bool permissionBoundaryReady = true,
    bool runtimeGateReady = true,
    bool securityBoundaryReady = true,
    bool coreAppIsolationReady = true,
    bool callAgentExactFourReady = true,
    bool productionActivationRequested = false,
    bool deploymentRequested = false,
    bool autoAuthorizationRequested = false,
  }) {
    return AgentVersioningFinalReadinessInput(
      versionContractReady: versionContractReady,
      evaluationBindingReady: evaluationBindingReady,
      testEnvironmentReady: testEnvironmentReady,
      limitedRolloutReady: limitedRolloutReady,
      monitoringRollbackReady: monitoringRollbackReady,
      fullRolloutEligibilityReady: fullRolloutEligibilityReady,
      knownGoodRollbackReady: knownGoodRollbackReady,
      phase42ImmutableEvidenceReady: phase42ImmutableEvidenceReady,
      permissionBoundaryReady: permissionBoundaryReady,
      runtimeGateReady: runtimeGateReady,
      securityBoundaryReady: securityBoundaryReady,
      coreAppIsolationReady: coreAppIsolationReady,
      callAgentExactFourReady: callAgentExactFourReady,
      productionActivationRequested: productionActivationRequested,
      deploymentRequested: deploymentRequested,
      autoAuthorizationRequested: autoAuthorizationRequested,
    );
  }

  test('clean Phase 62 foundation is ready but not production active', () {
    final report = service.evaluate(input());

    expect(
      report.status,
      AgentVersioningCloseoutContract.foundationReadyNotProductionActive,
    );
    expect(report.foundationReadyNotProductionActive, true);
    expect(report.phase66Required, true);
    expect(report.productionActive, false);
    expect(report.deploymentPerformed, false);
    expect(report.productionActivationPerformed, false);
    expect(report.autoModeAuthorized, false);
    expect(report.fullSafeAutoAuthorized, false);
  });

  test('missing foundation fails closed', () {
    final report = service.evaluate(input(fullRolloutEligibilityReady: false));

    expect(report.status, AgentVersioningCloseoutContract.blockedFoundation);
  });

  test('Permission boundary failure blocks closeout', () {
    final report = service.evaluate(input(permissionBoundaryReady: false));

    expect(report.status, AgentVersioningCloseoutContract.blockedSecurity);
  });

  test('Runtime Gate failure blocks closeout', () {
    final report = service.evaluate(input(runtimeGateReady: false));

    expect(report.status, AgentVersioningCloseoutContract.blockedSecurity);
  });

  test('core app isolation failure blocks closeout', () {
    final report = service.evaluate(input(coreAppIsolationReady: false));

    expect(report.status, AgentVersioningCloseoutContract.blockedSecurity);
  });

  test('production activation request is blocked until Phase 66', () {
    final report = service.evaluate(input(productionActivationRequested: true));

    expect(
      report.status,
      AgentVersioningCloseoutContract.blockedProductionActivation,
    );
  });

  test('deployment request is blocked until Phase 66', () {
    final report = service.evaluate(input(deploymentRequested: true));

    expect(
      report.status,
      AgentVersioningCloseoutContract.blockedProductionActivation,
    );
  });

  test('AUTO authorization request is blocked until Phase 66', () {
    final report = service.evaluate(input(autoAuthorizationRequested: true));

    expect(
      report.status,
      AgentVersioningCloseoutContract.blockedProductionActivation,
    );
  });

  test('final readiness service has zero execution authority', () {
    expect(service.phase66Required, true);
    expect(service.persistsReport, false);
    expect(service.callsProvider, false);
    expect(service.trainsModel, false);
    expect(service.mutatesPrompt, false);
    expect(service.deploysVersion, false);
    expect(service.activatesProduction, false);
    expect(service.authorizesAutoMode, false);
    expect(service.authorizesFullSafeAuto, false);
    expect(service.executesRollback, false);
    expect(service.restoresBackup, false);
    expect(service.consumesApproval, false);
    expect(service.grantsPermission, false);
    expect(service.overridesRuntimeGate, false);
    expect(service.overridesSecurity, false);
    expect(service.writesBusinessData, false);
  });

  test('ready report keeps core app continuity and no protected action', () {
    final report = service.evaluate(input());

    expect(report.coreAppCanContinue, true);
    expect(report.modelTrainingPerformed, false);
    expect(report.promptMutationPerformed, false);
    expect(report.rollbackExecutionPerformed, false);
    expect(report.exactBackupRestorePerformed, false);
    expect(report.approvalConsumed, false);
    expect(report.permissionGranted, false);
    expect(report.runtimeGateOverridden, false);
    expect(report.securityOverridden, false);
    expect(report.businessWritePerformed, false);
  });
}
