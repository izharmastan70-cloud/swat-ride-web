import '../models/agent_call_existing_ride_support_contract.dart';

/// Production implementation must be a trusted server/controlled read boundary.
///
/// The gateway must resolve [trustedRideReferenceId] only after verifying the
/// exact trusted caller/contact/session binding. It must not trust raw phone,
/// transcript text, voice content or the current FirebaseAuth user as ownership
/// authority.
abstract class AgentCallExistingRideReadGateway {
  Future<AgentCallExistingRideReadEvidence> readAuthorizedExistingRide({
    required AgentCallExistingRideSupportRequest request,
    required DateTime now,
  });
}

/// Stage 2 read/status/explain boundary for one existing Ride.
///
/// This service intentionally has no Firestore, FirebaseAuth or RideService
/// dependency. It accepts only evidence from [AgentCallExistingRideReadGateway].
class AgentCallExistingRideReadSupportService {
  const AgentCallExistingRideReadSupportService({required this.gateway});

  final AgentCallExistingRideReadGateway gateway;

  Future<AgentCallExistingRideSupportResult> read({
    required AgentCallExistingRideSupportRequest request,
    required DateTime now,
  }) async {
    try {
      request.validate();
    } catch (_) {
      return _unavailable(
        code: 'TRUSTED_EXISTING_RIDE_BINDING_REQUIRED',
        now: now,
      );
    }

    AgentCallExistingRideReadEvidence evidence;

    try {
      evidence = await gateway.readAuthorizedExistingRide(
        request: request,
        now: now.toUtc(),
      );
    } catch (_) {
      return _unavailable(code: 'EXISTING_RIDE_READ_GATEWAY_FAILED', now: now);
    }

    try {
      evidence.validate();
    } catch (_) {
      return _unavailable(
        code: 'EXISTING_RIDE_READ_EVIDENCE_INVALID',
        now: now,
      );
    }

    if (!evidence.exactlyMatchesRequest(request)) {
      return _unavailable(
        code: 'EXISTING_RIDE_READ_BINDING_MISMATCH',
        now: now,
      );
    }

    if (!evidence.isFreshAt(now)) {
      return _unavailable(
        code: 'EXISTING_RIDE_READ_EVIDENCE_EXPIRED',
        now: now,
      );
    }

    if (!evidence.isFound) {
      // Do not reveal whether an arbitrary Ride reference exists or merely
      // failed ownership/authorization checks.
      return _unavailable(code: 'EXISTING_RIDE_SUPPORT_UNAVAILABLE', now: now);
    }

    final AgentCallExistingRideSupportSnapshot snapshot = evidence.snapshot!;

    if (snapshot.trustedRideReferenceId.trim() !=
        request.trustedRideReferenceId.trim()) {
      return _unavailable(
        code: 'EXISTING_RIDE_SNAPSHOT_BINDING_MISMATCH',
        now: now,
      );
    }

    return AgentCallExistingRideSupportResult(
      status: AgentCallExistingRideSupportResult.ready,
      code: request.intent == AgentCallExistingRideSupportIntent.status
          ? 'EXISTING_RIDE_STATUS_READY'
          : 'EXISTING_RIDE_DETAILS_READY',
      createdAt: now.toUtc(),
      snapshot: snapshot,
    );
  }

  AgentCallExistingRideSupportResult _unavailable({
    required String code,
    required DateTime now,
  }) {
    return AgentCallExistingRideSupportResult(
      status: AgentCallExistingRideSupportResult.unavailable,
      code: code,
      createdAt: now.toUtc(),
    );
  }

  bool get readOnly => true;
  bool get writesRide => false;
  bool get cancelsRide => false;
  bool get reassignsDriver => false;
  bool get changesPayment => false;
  bool get issuesRefund => false;
  bool get changesFare => false;
  bool get changesCommission => false;
  bool get sendsSms => false;
  bool get invokesTelephonyProvider => false;
  bool get invokesSpeechToTextProvider => false;
  bool get invokesTextToSpeechProvider => false;

  bool get rawPhoneCanAuthorizeRideRead => false;
  bool get transcriptCanAuthorizeRideRead => false;
  bool get voiceCanAuthorizeRideRead => false;
  bool get currentFirebaseUserCanImpersonateCaller => false;
  bool get rideReferenceAloneIsAuthority => false;

  bool get requiresTrustedCallerBinding => true;
  bool get requiresTrustedContactBinding => true;
  bool get requiresCallSessionBinding => true;
  bool get requiresExactRideReferenceBinding => true;
  bool get requiresTrustedReadGateway => true;
  bool get hidesUnauthorizedRideExistence => true;
}
