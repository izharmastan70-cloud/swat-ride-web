class AgentUnifiedContextReadinessStatus {
  AgentUnifiedContextReadinessStatus._();

  static const String foundationReadyNotProductionActive =
      'FOUNDATION_READY_NOT_PRODUCTION_ACTIVE';

  static const String blocked = 'BLOCKED';
}

class AgentUnifiedContextReadinessReport {
  AgentUnifiedContextReadinessReport({
    required this.status,
    required this.step1BDataContractReady,
    required this.step1CIdentityScopedAssemblyReady,
    required this.step1DFreshnessConflictResolutionReady,
    required this.step1EMinimumDisclosureProjectionReady,
    required this.step1FContinuityFailureIsolationReady,
    required this.phase51ContinuityBoundaryPreserved,
    required this.callAgentExactFourActionsPreserved,
    required this.permissionApprovalRuntimeAuthorityPreserved,
    required this.productionContextPersistenceActive,
    required this.fullConversationHistoryStoreActive,
    required this.crossSubjectContextLoadingActive,
    required this.providerExecutionActive,
    required this.targetAgentInvocationActive,
    required this.runtimeBusinessActionActive,
    required this.businessWriteActive,
    required this.phase63PrivacyRetentionControlCenterImplemented,
    required this.productionUnifiedContextActive,
  });

  final String status;

  final bool step1BDataContractReady;
  final bool step1CIdentityScopedAssemblyReady;
  final bool step1DFreshnessConflictResolutionReady;
  final bool step1EMinimumDisclosureProjectionReady;
  final bool step1FContinuityFailureIsolationReady;

  final bool phase51ContinuityBoundaryPreserved;
  final bool callAgentExactFourActionsPreserved;
  final bool permissionApprovalRuntimeAuthorityPreserved;

  /// These are intentionally false at Phase 52 foundation closeout.
  final bool productionContextPersistenceActive;
  final bool fullConversationHistoryStoreActive;
  final bool crossSubjectContextLoadingActive;
  final bool providerExecutionActive;
  final bool targetAgentInvocationActive;
  final bool runtimeBusinessActionActive;
  final bool businessWriteActive;
  final bool phase63PrivacyRetentionControlCenterImplemented;
  final bool productionUnifiedContextActive;

  bool get allFoundationChecksPassed =>
      step1BDataContractReady &&
      step1CIdentityScopedAssemblyReady &&
      step1DFreshnessConflictResolutionReady &&
      step1EMinimumDisclosureProjectionReady &&
      step1FContinuityFailureIsolationReady &&
      phase51ContinuityBoundaryPreserved &&
      callAgentExactFourActionsPreserved &&
      permissionApprovalRuntimeAuthorityPreserved;

  bool get productionSafetyBoundaryPreserved =>
      !productionContextPersistenceActive &&
      !fullConversationHistoryStoreActive &&
      !crossSubjectContextLoadingActive &&
      !providerExecutionActive &&
      !targetAgentInvocationActive &&
      !runtimeBusinessActionActive &&
      !businessWriteActive &&
      !phase63PrivacyRetentionControlCenterImplemented &&
      !productionUnifiedContextActive;

  bool get foundationReady =>
      status ==
          AgentUnifiedContextReadinessStatus
              .foundationReadyNotProductionActive &&
      allFoundationChecksPassed &&
      productionSafetyBoundaryPreserved;

  bool get productionReady => false;
  bool get productionActive => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get invokesRuntimeGate => false;
  bool get writesBusinessData => false;
  bool get persistsReport => false;

  Map<String, dynamic> toSafeMap() {
    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'step1BDataContractReady': step1BDataContractReady,
      'step1CIdentityScopedAssemblyReady': step1CIdentityScopedAssemblyReady,
      'step1DFreshnessConflictResolutionReady':
          step1DFreshnessConflictResolutionReady,
      'step1EMinimumDisclosureProjectionReady':
          step1EMinimumDisclosureProjectionReady,
      'step1FContinuityFailureIsolationReady':
          step1FContinuityFailureIsolationReady,
      'phase51ContinuityBoundaryPreserved': phase51ContinuityBoundaryPreserved,
      'callAgentExactFourActionsPreserved': callAgentExactFourActionsPreserved,
      'permissionApprovalRuntimeAuthorityPreserved':
          permissionApprovalRuntimeAuthorityPreserved,
      'productionContextPersistenceActive': productionContextPersistenceActive,
      'fullConversationHistoryStoreActive': fullConversationHistoryStoreActive,
      'crossSubjectContextLoadingActive': crossSubjectContextLoadingActive,
      'providerExecutionActive': providerExecutionActive,
      'targetAgentInvocationActive': targetAgentInvocationActive,
      'runtimeBusinessActionActive': runtimeBusinessActionActive,
      'businessWriteActive': businessWriteActive,
      'phase63PrivacyRetentionControlCenterImplemented':
          phase63PrivacyRetentionControlCenterImplemented,
      'productionUnifiedContextActive': productionUnifiedContextActive,
      'allFoundationChecksPassed': allFoundationChecksPassed,
      'productionSafetyBoundaryPreserved': productionSafetyBoundaryPreserved,
      'foundationReady': foundationReady,
      'productionReady': false,
      'productionActive': false,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'invokesProvider': false,
      'invokesTargetAgent': false,
      'invokesRuntimeGate': false,
      'writesBusinessData': false,
      'persistsReport': false,
    });
  }
}
