import '../models/agent_call_ride_booking_customer_confirmation.dart';
import '../models/agent_call_ride_booking_execution_contract.dart';

/// Production implementation must be a trusted backend/server boundary.
///
/// It must verify an opaque token reference against a server-side customer
/// confirmation record and atomically consume it exactly once.
///
/// There is intentionally NO default Flutter/client implementation.
abstract class AgentCallRideBookingCustomerConfirmationGateway {
  Future<AgentCallRideBookingCustomerConfirmationVerification>
  verifyAndConsume({
    required String tokenReferenceId,
    required AgentCallRideBookingCustomerConfirmationScope expectedScope,
    required DateTime now,
  });
}

/// Phase 49 Step 1F customer confirmation boundary.
///
/// Existing `draft.customerConfirmed` is necessary but no longer sufficient
/// for future real Ride execution. A trusted backend confirmation token must
/// additionally verify and consume against the exact booking scope.
///
/// This boundary does not create a Ride.
class AgentCallRideBookingCustomerConfirmationBoundary {
  const AgentCallRideBookingCustomerConfirmationBoundary({
    required this.confirmationGateway,
  });

  final AgentCallRideBookingCustomerConfirmationGateway confirmationGateway;

  Future<AgentCallRideBookingCustomerConfirmationBoundaryResult>
  verifyForTrustedBackend({
    required AgentCallRideBookingExecutionRequest request,
    required String callSessionId,
    required String requestedBy,
    required String tokenReferenceId,
    required DateTime now,
  }) async {
    request.validate();

    if (!request.draft.customerConfirmed) {
      return _blocked(
        code: 'CUSTOMER_CONFIRMATION_REQUIRED',
        tokenReferenceId: tokenReferenceId,
        now: now,
      );
    }

    final String session = callSessionId.trim();
    final String actor = requestedBy.trim();
    final String tokenRef = tokenReferenceId.trim();

    if (session.isEmpty || actor.isEmpty) {
      return _blocked(
        code: 'TRUSTED_CALL_SESSION_BINDING_REQUIRED',
        tokenReferenceId: tokenRef,
        now: now,
      );
    }

    if (tokenRef.isEmpty) {
      return _blocked(
        code: 'CUSTOMER_CONFIRMATION_TOKEN_REQUIRED',
        tokenReferenceId: '',
        now: now,
      );
    }

    if (!request.fareVerification.isFreshAt(now)) {
      return _blocked(
        code: 'CUSTOMER_CONFIRMATION_FARE_EXPIRED',
        tokenReferenceId: tokenRef,
        now: now,
      );
    }

    final AgentCallRideBookingCustomerConfirmationScope scope =
        AgentCallRideBookingCustomerConfirmationScope.fromExecutionRequest(
          request: request,
          callSessionId: session,
          requestedBy: actor,
        );

    scope.validate();

    AgentCallRideBookingCustomerConfirmationVerification verification;

    try {
      verification = await confirmationGateway.verifyAndConsume(
        tokenReferenceId: tokenRef,
        expectedScope: scope,
        now: now,
      );
    } catch (_) {
      return _blocked(
        code: 'CUSTOMER_CONFIRMATION_GATEWAY_FAILED',
        tokenReferenceId: tokenRef,
        now: now,
      );
    }

    try {
      verification.validate();
    } catch (_) {
      return _blocked(
        code: 'CUSTOMER_CONFIRMATION_VERIFICATION_INVALID',
        tokenReferenceId: tokenRef,
        now: now,
      );
    }

    if (!verification.isTrustedFor(
      expectedScope: scope,
      expectedTokenReferenceId: tokenRef,
      now: now,
    )) {
      return _blocked(
        code: 'CUSTOMER_CONFIRMATION_TOKEN_MISMATCH',
        tokenReferenceId: tokenRef,
        now: now,
      );
    }

    return AgentCallRideBookingCustomerConfirmationBoundaryResult(
      status: AgentCallRideBookingCustomerConfirmationBoundaryResult.ready,
      code: 'CUSTOMER_CONFIRMATION_VERIFIED',
      tokenReferenceId: tokenRef,
      createdAt: now.toUtc(),
      verifiedScope: scope,
    );
  }

  AgentCallRideBookingCustomerConfirmationBoundaryResult _blocked({
    required String code,
    required String tokenReferenceId,
    required DateTime now,
  }) {
    return AgentCallRideBookingCustomerConfirmationBoundaryResult(
      status: AgentCallRideBookingCustomerConfirmationBoundaryResult.blocked,
      code: code,
      tokenReferenceId: tokenReferenceId.trim(),
      createdAt: now.toUtc(),
    );
  }

  bool get customerBooleanIsSufficientAuthority => false;
  bool get tokenIsAuthenticationByItself => false;
  bool get transcriptCanMintToken => false;
  bool get voiceCanMintToken => false;
  bool get aiCanMintToken => false;
  bool get clientCanSignProductionToken => false;
  bool get storesRawPhoneSecret => false;
  bool get storesTranscriptConfirmationText => false;

  bool get requiresTrustedBackendIssuer => true;
  bool get requiresAtomicOneTimeConsumption => true;
  bool get requiresExactCallerBinding => true;
  bool get requiresExactContactBinding => true;
  bool get requiresCallSessionBinding => true;
  bool get requiresIdempotencyBinding => true;
  bool get requiresExactVerifiedFareScope => true;
  bool get requiresShortLivedConfirmation => true;

  bool get writesRide => false;
  bool get changesPayment => false;
  bool get changesDriverState => false;
  bool get sendsSms => false;
  bool get invokesTelephonyProvider => false;
  bool get invokesSpeechToTextProvider => false;
  bool get invokesTextToSpeechProvider => false;
}
