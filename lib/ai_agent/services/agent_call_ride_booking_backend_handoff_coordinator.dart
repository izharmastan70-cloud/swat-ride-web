import '../models/agent_call_ride_booking_backend_handoff.dart';
import '../models/agent_call_ride_booking_customer_confirmation.dart';
import '../models/agent_call_ride_booking_execution_contract.dart';

/// Pure Step 1G coordinator.
///
/// It prepares a strict envelope only after Step 1F has produced a
/// verified-ready result carrying the exact verified confirmation scope.
///
/// It does NOT invoke a backend and does NOT create a Ride.
class AgentCallRideBookingBackendHandoffCoordinator {
  const AgentCallRideBookingBackendHandoffCoordinator();

  AgentCallRideBookingBackendHandoffResult prepare({
    required AgentCallRideBookingExecutionRequest request,
    required AgentCallRideBookingCustomerConfirmationBoundaryResult
    confirmationResult,
    required String envelopeId,
    required DateTime now,
  }) {
    request.validate();

    if (!confirmationResult.isReadyForStep1G) {
      return _blocked(code: 'STEP1F_VERIFIED_CONFIRMATION_REQUIRED', now: now);
    }

    if (!request.authorization.baseAuthorityAllowed) {
      return _blocked(code: 'CALL_BOOKING_AUTHORIZATION_BLOCKED', now: now);
    }

    if (!request.customerExplicitlyConfirmed) {
      return _blocked(code: 'CUSTOMER_CONFIRMATION_REQUIRED', now: now);
    }

    if (request.mode != AgentCallRideBookingExecutionMode.production) {
      return _blocked(code: 'PRODUCTION_HANDOFF_REQUIRED', now: now);
    }

    if (!request.fareVerification.isFreshAt(now)) {
      return _blocked(code: 'FARE_VERIFICATION_EXPIRED', now: now);
    }

    if (!request.fareVerification.rideServiceAvailable) {
      return _blocked(code: 'RIDE_SERVICE_UNAVAILABLE', now: now);
    }

    if (!request.fareVerification.driverAvailable) {
      return _blocked(code: 'NO_MATCHING_DRIVER_AVAILABLE', now: now);
    }

    if (request.fareVerification.usedTestingRouteBypass) {
      return _blocked(code: 'PRODUCTION_ROUTE_VERIFICATION_REQUIRED', now: now);
    }

    final AgentCallRideBookingCustomerConfirmationScope? scope =
        confirmationResult.verifiedScope;

    if (scope == null) {
      return _blocked(code: 'STEP1F_VERIFIED_SCOPE_REQUIRED', now: now);
    }

    if (confirmationResult.tokenReferenceId.trim().isEmpty) {
      return _blocked(code: 'CONFIRMATION_TOKEN_REFERENCE_REQUIRED', now: now);
    }

    final AgentCallRideBookingBackendHandoffEnvelope envelope =
        AgentCallRideBookingBackendHandoffEnvelope.fromVerifiedScope(
          envelopeId: envelopeId,
          scope: scope,
          confirmationTokenReferenceId: confirmationResult.tokenReferenceId,
          createdAt: now,
        );

    try {
      envelope.validate();
    } catch (_) {
      return _blocked(code: 'BACKEND_HANDOFF_ENVELOPE_INVALID', now: now);
    }

    if (!scope.exactlyMatches(
      AgentCallRideBookingCustomerConfirmationScope.fromExecutionRequest(
        request: request,
        callSessionId: scope.callSessionId,
        requestedBy: scope.requestedBy,
      ),
    )) {
      return _blocked(code: 'STEP1F_SCOPE_EXECUTION_MISMATCH', now: now);
    }

    if (!envelope.exactlyMatchesExecution(request)) {
      return _blocked(code: 'HANDOFF_EXECUTION_BINDING_MISMATCH', now: now);
    }

    if (!envelope.isFreshAt(now)) {
      return _blocked(code: 'HANDOFF_EXPIRED', now: now);
    }

    return AgentCallRideBookingBackendHandoffResult(
      status: AgentCallRideBookingBackendHandoffStatus.ready,
      code: 'READY_FOR_TRUSTED_BACKEND_EXECUTOR',
      createdAt: now.toUtc(),
      envelope: envelope,
    );
  }

  AgentCallRideBookingBackendHandoffResult _blocked({
    required String code,
    required DateTime now,
  }) {
    return AgentCallRideBookingBackendHandoffResult(
      status: AgentCallRideBookingBackendHandoffStatus.blocked,
      code: code,
      createdAt: now.toUtc(),
    );
  }

  bool get envelopeIsAuthority => false;
  bool get trustsClientEnvelopeWithoutBackendChecks => false;
  bool get invokesTrustedBackend => false;
  bool get writesRide => false;
  bool get writesFirestore => false;
  bool get usesCurrentFirebaseUserAsCaller => false;
  bool get includesRawPhone => false;
  bool get includesTranscript => false;
  bool get includesProviderSecret => false;
  bool get includesClientSigningSecret => false;
}
