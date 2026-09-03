import '../models/agent_call_tour_booking_status_contract.dart';
import '../models/agent_call_tour_booking_trusted_resolution.dart';

abstract class AgentCallTourBookingTrustedBackendResolver {
  const AgentCallTourBookingTrustedBackendResolver();

  Future<AgentCallTourBookingTrustedResolutionReceipt> resolveAndRead({
    required AgentCallTourBookingTrustedResolutionRequest request,
    required DateTime now,
  });
}

abstract class AgentCallTourBookingStatusReadGateway {
  const AgentCallTourBookingStatusReadGateway();

  Future<AgentCallTourBookingStatusReadEvidence>
  readAuthorizedTourBookingStatus({
    required AgentCallTourBookingStatusRequest request,
    required DateTime now,
  });
}

/// Phase 49 Stage 3 Step 3I.
///
/// Client-side boundary only. A trusted backend implementation must:
/// - verify the exact Call session + requestedBy binding,
/// - verify caller/contact identity binding,
/// - verify that the caller/contact may access the presented Tour booking,
/// - return only the privacy-minimized Tour status snapshot.
///
/// There is deliberately NO default Flutter/client resolver implementation.
/// Raw phone/transcript/voice/Firebase current user/booking reference alone
/// must never authorize access.
class AgentCallTourBookingTrustedBackendReadGateway
    implements AgentCallTourBookingStatusReadGateway {
  const AgentCallTourBookingTrustedBackendReadGateway({required this.resolver});

  final AgentCallTourBookingTrustedBackendResolver resolver;

  @override
  Future<AgentCallTourBookingStatusReadEvidence>
  readAuthorizedTourBookingStatus({
    required AgentCallTourBookingStatusRequest request,
    required DateTime now,
  }) async {
    final DateTime normalizedNow = now.toUtc();

    try {
      request.validate();

      final AgentCallTourBookingTrustedResolutionRequest resolutionRequest =
          AgentCallTourBookingTrustedResolutionRequest.fromCallRequest(request);

      final AgentCallTourBookingTrustedResolutionReceipt receipt =
          await resolver.resolveAndRead(
            request: resolutionRequest,
            now: normalizedNow,
          );

      receipt.validateFor(request: resolutionRequest, now: normalizedNow);

      if (!receipt.isAuthorized || receipt.snapshot == null) {
        return AgentCallTourBookingStatusReadEvidence.unavailable(
          observedAt: normalizedNow,
        );
      }

      return AgentCallTourBookingStatusReadEvidence.authorized(
        snapshot: receipt.snapshot!,
        observedAt: normalizedNow,
      );
    } catch (_) {
      // Fail closed. Unauthorized, not-found, blocked, stale, mismatched and
      // resolver failures intentionally collapse to the same generic result.
      return AgentCallTourBookingStatusReadEvidence.unavailable(
        observedAt: normalizedNow,
      );
    }
  }

  bool get requiresTrustedBackendResolver => true;
  bool get defaultFlutterProductionResolverConnected => false;
  bool get backendCallerContactAccessVerificationRequired => true;
  bool get exactSessionBindingRequired => true;
  bool get exactRequestedByBindingRequired => true;
  bool get exactCallerBindingRequired => true;
  bool get exactContactBindingRequired => true;
  bool get exactTourBookingBindingRequired => true;
  bool get hidesUnauthorizedTourBookingExistence => true;

  bool get rawPhoneIsAuthority => false;
  bool get transcriptIsAuthority => false;
  bool get voiceIsAuthority => false;
  bool get firebaseCurrentUserIsAuthority => false;
  bool get bookingReferenceAloneIsAuthority => false;

  bool get invokesGenericTourConnectorDirectly => false;
  bool get invokesTourBookingService => false;
  bool get invokesFirestore => false;
  bool get invokesFirebaseAuth => false;
  bool get invokesHttp => false;
  bool get invokesCloudFunctions => false;
  bool get invokesTelephonyProvider => false;

  bool get createsTourBooking => false;
  bool get writesTourBooking => false;
  bool get cancelsTourBooking => false;
  bool get changesTourPrice => false;
  bool get changesTourPayment => false;
  bool get changesTourAssignment => false;
}
