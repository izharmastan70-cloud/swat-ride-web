/// Phase 49 Call Booking - Stage 1 readiness truth model.
///
/// "Stage 1 foundation complete" and "production booking live" are deliberately
/// separate states. The app must never infer production activation merely
/// because local contracts/tests are complete.
class AgentCallRideBookingStage1ReadinessManifest {
  const AgentCallRideBookingStage1ReadinessManifest({
    required this.centralPermissionRuntimeVerified,
    required this.trustedCallerContactBindingVerified,
    required this.preflightFareAndAvailabilityVerified,
    required this.trustedCustomerConfirmationVerified,
    required this.exactlyOnceContractVerified,
    required this.truthfulFinalReceiptVerified,
    required this.clientIdempotencyAccessExplicitlyDenied,
    required this.realTrustedBackendExecutorDeployed,
    required this.trustedServerIdempotencyDeployed,
    required this.callAgentRoleMigrationProven,
    required this.telephonyProviderConnected,
    required this.providerSecretsServerSide,
    required this.productionMonitoringReady,
  });

  final bool centralPermissionRuntimeVerified;
  final bool trustedCallerContactBindingVerified;
  final bool preflightFareAndAvailabilityVerified;
  final bool trustedCustomerConfirmationVerified;
  final bool exactlyOnceContractVerified;
  final bool truthfulFinalReceiptVerified;
  final bool clientIdempotencyAccessExplicitlyDenied;

  final bool realTrustedBackendExecutorDeployed;
  final bool trustedServerIdempotencyDeployed;
  final bool callAgentRoleMigrationProven;
  final bool telephonyProviderConnected;
  final bool providerSecretsServerSide;
  final bool productionMonitoringReady;

  factory AgentCallRideBookingStage1ReadinessManifest.foundationClosedProductionBlocked() {
    return const AgentCallRideBookingStage1ReadinessManifest(
      centralPermissionRuntimeVerified: true,
      trustedCallerContactBindingVerified: true,
      preflightFareAndAvailabilityVerified: true,
      trustedCustomerConfirmationVerified: true,
      exactlyOnceContractVerified: true,
      truthfulFinalReceiptVerified: true,
      clientIdempotencyAccessExplicitlyDenied: true,
      realTrustedBackendExecutorDeployed: false,
      trustedServerIdempotencyDeployed: false,
      callAgentRoleMigrationProven: false,
      telephonyProviderConnected: false,
      providerSecretsServerSide: false,
      productionMonitoringReady: false,
    );
  }

  bool get stage1SecurityFoundationComplete =>
      centralPermissionRuntimeVerified &&
      trustedCallerContactBindingVerified &&
      preflightFareAndAvailabilityVerified &&
      trustedCustomerConfirmationVerified &&
      exactlyOnceContractVerified &&
      truthfulFinalReceiptVerified &&
      clientIdempotencyAccessExplicitlyDenied;

  bool get productionBookingActivationAllowed =>
      stage1SecurityFoundationComplete &&
      realTrustedBackendExecutorDeployed &&
      trustedServerIdempotencyDeployed &&
      callAgentRoleMigrationProven &&
      telephonyProviderConnected &&
      providerSecretsServerSide &&
      productionMonitoringReady;

  bool get canTruthfullyClaimProductionLive =>
      productionBookingActivationAllowed;

  bool get canTruthfullyClaimStage1FoundationClosed =>
      stage1SecurityFoundationComplete;

  bool get clientFirestoreIdempotencyCanAuthorizeBooking => false;
  bool get preflightCanClaimBooked => false;
  bool get authorizationCanClaimBooked => false;
  bool get confirmationCanClaimBooked => false;
  bool get handoffCanClaimBooked => false;
  bool get localPlaceholderRideIdCanClaimBooked => false;

  List<String> missingProductionRequirements() {
    final List<String> missing = <String>[];

    if (!realTrustedBackendExecutorDeployed) {
      missing.add('TRUSTED_BACKEND_RIDE_EXECUTOR');
    }

    if (!trustedServerIdempotencyDeployed) {
      missing.add('TRUSTED_SERVER_IDEMPOTENCY');
    }

    if (!callAgentRoleMigrationProven) {
      missing.add('CALL_AGENT_ROLE_MIGRATION_PROOF');
    }

    if (!telephonyProviderConnected) {
      missing.add('TELEPHONY_PROVIDER');
    }

    if (!providerSecretsServerSide) {
      missing.add('SERVER_SIDE_PROVIDER_SECRETS');
    }

    if (!productionMonitoringReady) {
      missing.add('PRODUCTION_MONITORING_ROLLBACK');
    }

    return List<String>.unmodifiable(missing);
  }

  void validate() {
    if (productionBookingActivationAllowed &&
        !stage1SecurityFoundationComplete) {
      throw const AgentCallRideBookingStage1ReadinessException(
        'Production activation cannot bypass Stage 1 security foundation.',
      );
    }

    if (canTruthfullyClaimProductionLive &&
        missingProductionRequirements().isNotEmpty) {
      throw const AgentCallRideBookingStage1ReadinessException(
        'Production-live claim cannot have missing production requirements.',
      );
    }
  }
}

class AgentCallRideBookingStage1ReadinessException implements Exception {
  const AgentCallRideBookingStage1ReadinessException(this.message);

  final String message;

  @override
  String toString() => 'AgentCallRideBookingStage1ReadinessException: $message';
}
