import '../models/agent_call_existing_ride_support_contract.dart';
import '../models/agent_call_existing_ride_trusted_resolution.dart';
import 'agent_call_existing_ride_read_support_service.dart';

/// Production implementation belongs on a trusted backend/server boundary.
///
/// There is intentionally no default Flutter/client implementation.
///
/// A production resolver must verify caller/contact/Ride access using trusted
/// server-side identity and Ride state. It must not trust raw phone,
/// transcript, voice text, the current FirebaseAuth user, or a Ride reference
/// alone as access authority.
abstract class AgentCallExistingRideTrustedBackendResolver {
  Future<AgentCallExistingRideTrustedResolutionReceipt> resolveAndRead({
    required AgentCallExistingRideTrustedResolutionRequest request,
    required DateTime now,
  });
}

/// Adapter from the trusted backend resolution contract into the Stage 2B
/// [AgentCallExistingRideReadGateway] contract.
///
/// This class itself does not access Firestore/RideService/network providers.
/// It only validates a server-issued receipt and converts it to the existing
/// privacy-minimized read evidence model.
class AgentCallExistingRideTrustedBackendReadGateway
    implements AgentCallExistingRideReadGateway {
  const AgentCallExistingRideTrustedBackendReadGateway({
    required this.resolver,
  });

  final AgentCallExistingRideTrustedBackendResolver resolver;

  @override
  Future<AgentCallExistingRideReadEvidence> readAuthorizedExistingRide({
    required AgentCallExistingRideSupportRequest request,
    required DateTime now,
  }) async {
    try {
      request.validate();
    } catch (_) {
      return _blockedEvidence(
        request: request,
        now: now,
        code: 'TRUSTED_BACKEND_RIDE_RESOLUTION_SCOPE_INVALID',
      );
    }

    final AgentCallExistingRideTrustedResolutionRequest resolutionRequest =
        AgentCallExistingRideTrustedResolutionRequest.fromSupportRequest(
          request,
        );

    try {
      resolutionRequest.validate();
    } catch (_) {
      return _blockedEvidence(
        request: request,
        now: now,
        code: 'TRUSTED_BACKEND_RIDE_RESOLUTION_SCOPE_INVALID',
      );
    }

    AgentCallExistingRideTrustedResolutionReceipt receipt;

    try {
      receipt = await resolver.resolveAndRead(
        request: resolutionRequest,
        now: now.toUtc(),
      );
    } catch (_) {
      return _blockedEvidence(
        request: request,
        now: now,
        code: 'TRUSTED_BACKEND_RIDE_RESOLVER_FAILED',
      );
    }

    try {
      receipt.validate();
    } catch (_) {
      return _blockedEvidence(
        request: request,
        now: now,
        code: 'TRUSTED_BACKEND_RIDE_RESOLUTION_INVALID',
      );
    }

    if (!receipt.exactlyMatchesRequest(resolutionRequest)) {
      return _blockedEvidence(
        request: request,
        now: now,
        code: 'TRUSTED_BACKEND_RIDE_RESOLUTION_BINDING_MISMATCH',
      );
    }

    if (!resolutionRequest.exactlyMatchesSupportRequest(request)) {
      return _blockedEvidence(
        request: request,
        now: now,
        code: 'TRUSTED_BACKEND_RIDE_SUPPORT_SCOPE_MISMATCH',
      );
    }

    if (!receipt.isFreshAt(now)) {
      return _blockedEvidence(
        request: request,
        now: now,
        code: 'TRUSTED_BACKEND_RIDE_RESOLUTION_EXPIRED',
      );
    }

    if (!receipt.isAuthorized) {
      // Deliberately collapse unavailable and denied states so the caller
      // cannot enumerate whether arbitrary Ride references exist.
      return _blockedEvidence(
        request: request,
        now: now,
        code: 'AUTHORIZED_EXISTING_RIDE_UNAVAILABLE',
      );
    }

    return AgentCallExistingRideReadEvidence(
      status: AgentCallExistingRideReadStatus.found,
      code: 'AUTHORIZED_EXISTING_RIDE_FOUND',
      verificationSource:
          AgentCallExistingRideReadEvidence.trustedVerificationSource,
      callSessionId: request.callSessionId,
      requestedBy: request.requestedBy,
      trustedCallerReferenceId: request.trustedCallerReferenceId,
      trustedContactReferenceId: request.trustedContactReferenceId,
      trustedRideReferenceId: receipt.resolvedRideReferenceId,
      verifiedAt: receipt.verifiedAt.toUtc(),
      expiresAt: receipt.expiresAt.toUtc(),
      snapshot: receipt.snapshot,
    );
  }

  AgentCallExistingRideReadEvidence _blockedEvidence({
    required AgentCallExistingRideSupportRequest request,
    required DateTime now,
    required String code,
  }) {
    final DateTime verifiedAt = now.toUtc();

    return AgentCallExistingRideReadEvidence(
      status: AgentCallExistingRideReadStatus.blocked,
      code: code,
      verificationSource: 'TRUSTED_BACKEND_RESOLUTION_BLOCKED',
      callSessionId: request.callSessionId.trim(),
      requestedBy: request.requestedBy.trim(),
      trustedCallerReferenceId: request.trustedCallerReferenceId.trim(),
      trustedContactReferenceId: request.trustedContactReferenceId.trim(),
      trustedRideReferenceId: request.trustedRideReferenceId.trim(),
      verifiedAt: verifiedAt,
      expiresAt: verifiedAt.add(const Duration(seconds: 30)),
    );
  }

  bool get hasDefaultProductionResolver => false;
  bool get requiresTrustedBackendResolver => true;
  bool get backendMustVerifyRideAccess => true;
  bool get backendMustUseTrustedServerState => true;
  bool get clientRideLookupAllowed => false;
  bool get arbitraryRideReferenceAllowed => false;

  bool get rawPhoneCanAuthorize => false;
  bool get transcriptCanAuthorize => false;
  bool get voiceCanAuthorize => false;
  bool get currentFirebaseUserCanAuthorize => false;
  bool get rideReferenceAloneCanAuthorize => false;

  bool get exposesRawPhone => false;
  bool get exposesFirebaseUid => false;
  bool get exposesLiveDriverGps => false;
  bool get exposesRideStartPin => false;

  bool get writesRide => false;
  bool get cancelsRide => false;
  bool get reassignsDriver => false;
  bool get changesPayment => false;
  bool get issuesRefund => false;
  bool get changesFare => false;

  bool get invokesFirestoreDirectly => false;
  bool get invokesFirebaseAuthDirectly => false;
  bool get invokesRideServiceDirectly => false;
  bool get invokesHttpDirectly => false;
  bool get invokesCloudFunctionsDirectly => false;
  bool get invokesTelephonyProvider => false;
}
