import '../constants/agent_action_ids.dart';

class AgentCallStage3NextServiceGateStatus {
  AgentCallStage3NextServiceGateStatus._();

  static const String auditRequired = 'AUDIT_REQUIRED';
  static const String registryNotReady = 'REGISTRY_NOT_READY';
  static const String notConnected = 'NOT_CONNECTED';
}

class AgentCallFoodStatusStage3Readiness {
  const AgentCallFoodStatusStage3Readiness._();

  // Food STATUS / READ foundation completed in Steps 3B-3E.
  static const bool foodStatusFoundationReady = true;
  static const String dedicatedCallAction =
      AgentActionId.readCallFoodOrderStatus;
  static const bool dedicatedActionLowRisk = true;
  static const bool dedicatedActionReadOnly = true;
  static const bool permissionEngineReady = true;
  static const bool runtimeGateReady = true;
  static const bool trustedCallerContactOrderBindingReady = true;
  static const bool trustedBackendResolverContractReady = true;
  static const bool privacyMinimizedSnapshotReady = true;
  static const bool unauthorizedOrderExistenceHidingReady = true;
  static const bool safeEscalationRoutingReady = true;
  static const bool escalationRecommendationOnly = true;
  static const bool callAgentLeastPrivilegeThreeActions = true;

  // Truthful production status. Foundation-ready is NOT production-live.
  static const bool productionFoodStatusCallSupportLive = false;
  static const bool realTrustedBackendFoodResolverConnected = false;
  static const bool realCallerContactBindingSourceConnected = false;
  static const bool actualGenericFoodConnectorCallFlowConnected = false;
  static const bool actualHumanTransferConnected = false;
  static const bool actualManagerAdminTransferConnected = false;
  static const bool actualOwnerTransferConnected = false;
  static const bool productionTelephonyConnected = false;
  static const bool productionSttConnected = false;
  static const bool productionTtsConnected = false;
  static const bool productionSmsConnected = false;

  // Food status lane stays read-only.
  static const bool foodCreateAuthority = false;
  static const bool foodWriteAuthority = false;
  static const bool foodCancelAuthority = false;
  static const bool foodRefundAuthority = false;
  static const bool foodPaymentMutationAuthority = false;
  static const bool foodRiderAssignmentAuthority = false;
  static const bool directFirestoreAuthority = false;
  static const bool directFirebaseAuthAuthority = false;
  static const bool directFoodOrderServiceAuthority = false;
  static const bool providerAuthority = false;

  // Next-service gate. Step 3F deliberately selects NO new service.
  static const bool nextServiceSelectedNow = false;
  static const String nextStep =
      'PHASE 49 STAGE 3 STEP 3G - NEXT-SERVICE EXACT READINESS AUDIT / SELECTION';

  static const bool hotelConnectorImplementationExists = true;
  static const bool hotelCentralRegistryReady = false;
  static const String hotelGateStatus =
      AgentCallStage3NextServiceGateStatus.registryNotReady;

  static const bool tourConnectorImplementationExists = true;
  static const bool tourCentralRegistryReady = false;
  static const String tourGateStatus =
      AgentCallStage3NextServiceGateStatus.registryNotReady;

  static const bool cargoConnectorReady = false;
  static const String cargoGateStatus =
      AgentCallStage3NextServiceGateStatus.notConnected;

  static const bool studentConnectorReady = false;
  static const String studentGateStatus =
      AgentCallStage3NextServiceGateStatus.notConnected;

  static const bool parcelConnectorVerified = false;
  static const String parcelGateStatus =
      AgentCallStage3NextServiceGateStatus.auditRequired;

  static const bool hotelMayBeActivatedWithoutAudit = false;
  static const bool tourMayBeActivatedWithoutAudit = false;
  static const bool cargoMayBeActivatedWithoutAudit = false;
  static const bool studentMayBeActivatedWithoutAudit = false;
  static const bool parcelMayBeActivatedWithoutAudit = false;

  static const bool nextServiceGateLocked =
      !nextServiceSelectedNow &&
      !hotelCentralRegistryReady &&
      !tourCentralRegistryReady &&
      !cargoConnectorReady &&
      !studentConnectorReady &&
      !parcelConnectorVerified;

  static const bool step3FFoundationCloseoutReady =
      foodStatusFoundationReady &&
      dedicatedActionLowRisk &&
      dedicatedActionReadOnly &&
      permissionEngineReady &&
      runtimeGateReady &&
      trustedCallerContactOrderBindingReady &&
      trustedBackendResolverContractReady &&
      privacyMinimizedSnapshotReady &&
      unauthorizedOrderExistenceHidingReady &&
      safeEscalationRoutingReady &&
      escalationRecommendationOnly &&
      callAgentLeastPrivilegeThreeActions &&
      !productionFoodStatusCallSupportLive &&
      !foodWriteAuthority &&
      nextServiceGateLocked;

  static Map<String, dynamic> toSafeMap() {
    return <String, dynamic>{
      'foodStatusFoundationReady': foodStatusFoundationReady,
      'dedicatedCallAction': dedicatedCallAction,
      'dedicatedActionLowRisk': dedicatedActionLowRisk,
      'dedicatedActionReadOnly': dedicatedActionReadOnly,
      'permissionEngineReady': permissionEngineReady,
      'runtimeGateReady': runtimeGateReady,
      'trustedCallerContactOrderBindingReady':
          trustedCallerContactOrderBindingReady,
      'trustedBackendResolverContractReady':
          trustedBackendResolverContractReady,
      'privacyMinimizedSnapshotReady': privacyMinimizedSnapshotReady,
      'unauthorizedOrderExistenceHidingReady':
          unauthorizedOrderExistenceHidingReady,
      'safeEscalationRoutingReady': safeEscalationRoutingReady,
      'productionFoodStatusCallSupportLive':
          productionFoodStatusCallSupportLive,
      'realTrustedBackendFoodResolverConnected':
          realTrustedBackendFoodResolverConnected,
      'actualGenericFoodConnectorCallFlowConnected':
          actualGenericFoodConnectorCallFlowConnected,
      'productionTelephonyConnected': productionTelephonyConnected,
      'productionSttConnected': productionSttConnected,
      'productionTtsConnected': productionTtsConnected,
      'productionSmsConnected': productionSmsConnected,
      'foodWriteAuthority': foodWriteAuthority,
      'nextServiceSelectedNow': nextServiceSelectedNow,
      'hotelGateStatus': hotelGateStatus,
      'tourGateStatus': tourGateStatus,
      'cargoGateStatus': cargoGateStatus,
      'studentGateStatus': studentGateStatus,
      'parcelGateStatus': parcelGateStatus,
      'nextServiceGateLocked': nextServiceGateLocked,
      'step3FFoundationCloseoutReady': step3FFoundationCloseoutReady,
      'nextStep': nextStep,
    };
  }
}
