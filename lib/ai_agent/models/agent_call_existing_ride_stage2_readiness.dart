import '../constants/agent_action_ids.dart';

/// Phase 49 Stage 2 truthful readiness manifest.
///
/// Stage 2 closes the EXISTING RIDE SUPPORT FOUNDATION only:
/// - trusted read/status/details contract;
/// - dedicated least-privilege Call action;
/// - Permission Engine + Runtime Gate authorization;
/// - safe escalation recommendation;
/// - trusted backend Ride-reference resolver/read-gateway boundary.
///
/// This manifest deliberately does NOT claim production existing-Ride Call
/// support is live. The real trusted backend resolver, real caller/contact
/// binding source and external call/provider transports remain deployment work.
class AgentCallExistingRideStage2Readiness {
  const AgentCallExistingRideStage2Readiness._();

  static const String scope = 'EXISTING_RIDE_READ_STATUS_EXPLAIN';
  static const String dedicatedActionId = AgentActionId.readCallExistingRide;

  // Stage 2 foundation evidence.
  static const bool trustedReadContractReady = true;
  static const bool privacyMinimizedSnapshotReady = true;
  static const bool dedicatedReadActionReady = true;
  static const bool permissionEngineAuthorizationReady = true;
  static const bool runtimeGateAuthorizationReady = true;
  static const bool trustedBindingContractReady = true;
  static const bool safeEscalationRoutingReady = true;
  static const bool trustedResolverBoundaryReady = true;
  static const bool unauthorizedRideExistenceHidden = true;

  // Locked least-privilege/security properties.
  static const bool exactSessionBindingRequired = true;
  static const bool exactRequestedByBindingRequired = true;
  static const bool exactCallerBindingRequired = true;
  static const bool exactContactBindingRequired = true;
  static const bool exactRideReferenceBindingRequired = true;
  static const bool backendRideAccessVerificationRequired = true;
  static const bool trustedServerStateRequired = true;
  static const bool rawPhoneCanAuthorize = false;
  static const bool transcriptCanAuthorize = false;
  static const bool voiceCanAuthorize = false;
  static const bool currentFirebaseUserCanAuthorize = false;
  static const bool rideReferenceAloneCanAuthorize = false;

  // No Stage 2 business mutation authority.
  static const bool rideWriteAllowed = false;
  static const bool rideCancelAllowed = false;
  static const bool driverReassignmentAllowed = false;
  static const bool paymentChangeAllowed = false;
  static const bool refundAllowed = false;
  static const bool fareChangeAllowed = false;
  static const bool transferExecutionIncluded = false;

  // Truthful production blockers.
  static const bool trustedBackendResolverImplementationConnected = false;
  static const bool trustedCallerContactBindingSourceConnected = false;
  static const bool actualHumanTransferExecutionConnected = false;
  static const bool productionTelephonyConnected = false;
  static const bool productionSttConnected = false;
  static const bool productionTtsConnected = false;
  static const bool productionSmsConnected = false;

  static const bool stage2FoundationReady =
      trustedReadContractReady &&
      privacyMinimizedSnapshotReady &&
      dedicatedReadActionReady &&
      permissionEngineAuthorizationReady &&
      runtimeGateAuthorizationReady &&
      trustedBindingContractReady &&
      safeEscalationRoutingReady &&
      trustedResolverBoundaryReady &&
      unauthorizedRideExistenceHidden;

  static const bool productionExistingRideCallSupportLive =
      stage2FoundationReady &&
      trustedBackendResolverImplementationConnected &&
      trustedCallerContactBindingSourceConnected &&
      productionTelephonyConnected;

  static const bool mayClaimStage2FoundationComplete =
      stage2FoundationReady && !productionExistingRideCallSupportLive;

  static Map<String, dynamic> toSafeMap() {
    return <String, dynamic>{
      'scope': scope,
      'dedicatedActionId': dedicatedActionId,
      'stage2FoundationReady': stage2FoundationReady,
      'productionExistingRideCallSupportLive':
          productionExistingRideCallSupportLive,
      'trustedBackendResolverImplementationConnected':
          trustedBackendResolverImplementationConnected,
      'trustedCallerContactBindingSourceConnected':
          trustedCallerContactBindingSourceConnected,
      'actualHumanTransferExecutionConnected':
          actualHumanTransferExecutionConnected,
      'productionTelephonyConnected': productionTelephonyConnected,
      'productionSttConnected': productionSttConnected,
      'productionTtsConnected': productionTtsConnected,
      'productionSmsConnected': productionSmsConnected,
      'rideWriteAllowed': rideWriteAllowed,
      'rideCancelAllowed': rideCancelAllowed,
      'driverReassignmentAllowed': driverReassignmentAllowed,
      'paymentChangeAllowed': paymentChangeAllowed,
      'refundAllowed': refundAllowed,
      'fareChangeAllowed': fareChangeAllowed,
      'rawPhoneCanAuthorize': rawPhoneCanAuthorize,
      'transcriptCanAuthorize': transcriptCanAuthorize,
      'voiceCanAuthorize': voiceCanAuthorize,
      'currentFirebaseUserCanAuthorize': currentFirebaseUserCanAuthorize,
      'rideReferenceAloneCanAuthorize': rideReferenceAloneCanAuthorize,
    };
  }
}
