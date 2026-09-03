import 'agent_call_existing_ride_support_contract.dart';

class AgentCallExistingRideTrustedResolutionStatus {
  AgentCallExistingRideTrustedResolutionStatus._();

  static const String authorized = 'AUTHORIZED_EXISTING_RIDE';
  static const String unavailable = 'EXISTING_RIDE_UNAVAILABLE';
  static const String blocked = 'EXISTING_RIDE_RESOLUTION_BLOCKED';

  static const Set<String> values = <String>{authorized, unavailable, blocked};
}

/// Exact opaque scope sent to a trusted backend resolver.
///
/// The client is allowed to carry opaque reference IDs, but those references
/// are never authority by themselves. The trusted backend must resolve and
/// verify their relationship using server-side trusted state.
class AgentCallExistingRideTrustedResolutionRequest {
  const AgentCallExistingRideTrustedResolutionRequest({
    required this.callSessionId,
    required this.requestedBy,
    required this.trustedCallerReferenceId,
    required this.trustedContactReferenceId,
    required this.presentedRideReferenceId,
    required this.intent,
  });

  factory AgentCallExistingRideTrustedResolutionRequest.fromSupportRequest(
    AgentCallExistingRideSupportRequest request,
  ) {
    return AgentCallExistingRideTrustedResolutionRequest(
      callSessionId: request.callSessionId,
      requestedBy: request.requestedBy,
      trustedCallerReferenceId: request.trustedCallerReferenceId,
      trustedContactReferenceId: request.trustedContactReferenceId,
      presentedRideReferenceId: request.trustedRideReferenceId,
      intent: request.intent,
    );
  }

  final String callSessionId;
  final String requestedBy;
  final String trustedCallerReferenceId;
  final String trustedContactReferenceId;
  final String presentedRideReferenceId;
  final String intent;

  void validate() {
    if (callSessionId.trim().isEmpty ||
        requestedBy.trim().isEmpty ||
        trustedCallerReferenceId.trim().isEmpty ||
        trustedContactReferenceId.trim().isEmpty ||
        presentedRideReferenceId.trim().isEmpty) {
      throw const AgentCallExistingRideSupportException(
        'Complete trusted backend Ride-resolution scope is required.',
      );
    }

    if (!AgentCallExistingRideSupportIntent.values.contains(intent)) {
      throw const AgentCallExistingRideSupportException(
        'Unsupported trusted backend existing-Ride intent.',
      );
    }
  }

  bool exactlyMatchesSupportRequest(
    AgentCallExistingRideSupportRequest request,
  ) {
    return callSessionId.trim() == request.callSessionId.trim() &&
        requestedBy.trim() == request.requestedBy.trim() &&
        trustedCallerReferenceId.trim() ==
            request.trustedCallerReferenceId.trim() &&
        trustedContactReferenceId.trim() ==
            request.trustedContactReferenceId.trim() &&
        presentedRideReferenceId.trim() ==
            request.trustedRideReferenceId.trim() &&
        intent == request.intent;
  }

  Map<String, dynamic> toSafeMap() {
    return <String, dynamic>{
      'callSessionId': callSessionId.trim(),
      'requestedBy': requestedBy.trim(),
      'trustedCallerReferenceId': trustedCallerReferenceId.trim(),
      'trustedContactReferenceId': trustedContactReferenceId.trim(),
      'presentedRideReferenceId': presentedRideReferenceId.trim(),
      'intent': intent,
      'rawPhoneIncluded': false,
      'transcriptIncluded': false,
      'voiceIncluded': false,
      'firebaseUidIncluded': false,
    };
  }
}

/// Server-issued result from the existing-Ride resolver.
///
/// AUTHORIZED may be issued only after the trusted backend verifies:
/// - exact Call session;
/// - exact requestedBy actor;
/// - trusted caller reference;
/// - trusted contact reference;
/// - presented Ride reference;
/// - caller/contact access to the real Ride record;
/// - privacy-minimized safe Ride snapshot.
///
/// The receipt is read evidence only. It is not authentication for any other
/// action and never authorizes Ride mutation.
class AgentCallExistingRideTrustedResolutionReceipt {
  const AgentCallExistingRideTrustedResolutionReceipt({
    required this.status,
    required this.code,
    required this.source,
    required this.callSessionId,
    required this.requestedBy,
    required this.trustedCallerReferenceId,
    required this.trustedContactReferenceId,
    required this.presentedRideReferenceId,
    required this.resolvedRideReferenceId,
    required this.ownershipOrAccessVerified,
    required this.verifiedAt,
    required this.expiresAt,
    this.snapshot,
  });

  static const String trustedSource = 'TRUSTED_BACKEND_EXISTING_RIDE_RESOLVER';

  final String status;
  final String code;
  final String source;
  final String callSessionId;
  final String requestedBy;
  final String trustedCallerReferenceId;
  final String trustedContactReferenceId;
  final String presentedRideReferenceId;
  final String resolvedRideReferenceId;
  final bool ownershipOrAccessVerified;
  final DateTime verifiedAt;
  final DateTime expiresAt;
  final AgentCallExistingRideSupportSnapshot? snapshot;

  bool get isAuthorized =>
      status == AgentCallExistingRideTrustedResolutionStatus.authorized;

  void validate() {
    if (!AgentCallExistingRideTrustedResolutionStatus.values.contains(status) ||
        code.trim().isEmpty ||
        callSessionId.trim().isEmpty ||
        requestedBy.trim().isEmpty ||
        trustedCallerReferenceId.trim().isEmpty ||
        trustedContactReferenceId.trim().isEmpty ||
        presentedRideReferenceId.trim().isEmpty) {
      throw const AgentCallExistingRideSupportException(
        'Trusted backend Ride-resolution receipt is incomplete.',
      );
    }

    if (!expiresAt.toUtc().isAfter(verifiedAt.toUtc())) {
      throw const AgentCallExistingRideSupportException(
        'Trusted backend Ride-resolution expiry is invalid.',
      );
    }

    if (expiresAt.toUtc().difference(verifiedAt.toUtc()) >
        const Duration(minutes: 2)) {
      throw const AgentCallExistingRideSupportException(
        'Trusted backend Ride-resolution lifetime is too long.',
      );
    }

    if (isAuthorized) {
      if (source != trustedSource) {
        throw const AgentCallExistingRideSupportException(
          'Authorized Ride resolution requires the exact trusted backend source.',
        );
      }

      if (!ownershipOrAccessVerified) {
        throw const AgentCallExistingRideSupportException(
          'Authorized Ride resolution requires verified ownership/access.',
        );
      }

      if (resolvedRideReferenceId.trim().isEmpty || snapshot == null) {
        throw const AgentCallExistingRideSupportException(
          'Authorized Ride resolution requires resolved Ride evidence.',
        );
      }

      snapshot!.validate();

      if (snapshot!.trustedRideReferenceId.trim() !=
          resolvedRideReferenceId.trim()) {
        throw const AgentCallExistingRideSupportException(
          'Resolved Ride reference does not match safe Ride snapshot.',
        );
      }
    } else {
      if (snapshot != null || resolvedRideReferenceId.trim().isNotEmpty) {
        throw const AgentCallExistingRideSupportException(
          'Unavailable/blocked Ride resolution must not expose Ride evidence.',
        );
      }

      if (ownershipOrAccessVerified) {
        throw const AgentCallExistingRideSupportException(
          'Unavailable/blocked Ride resolution cannot claim verified access.',
        );
      }
    }
  }

  bool exactlyMatchesRequest(
    AgentCallExistingRideTrustedResolutionRequest request,
  ) {
    return callSessionId.trim() == request.callSessionId.trim() &&
        requestedBy.trim() == request.requestedBy.trim() &&
        trustedCallerReferenceId.trim() ==
            request.trustedCallerReferenceId.trim() &&
        trustedContactReferenceId.trim() ==
            request.trustedContactReferenceId.trim() &&
        presentedRideReferenceId.trim() ==
            request.presentedRideReferenceId.trim();
  }

  bool isFreshAt(DateTime now) {
    final DateTime utcNow = now.toUtc();

    return !verifiedAt.toUtc().isAfter(utcNow) &&
        expiresAt.toUtc().isAfter(utcNow);
  }

  Map<String, dynamic> toSafeMap() {
    return <String, dynamic>{
      'status': status,
      'code': code,
      'source': source,
      'callSessionId': callSessionId.trim(),
      'requestedBy': requestedBy.trim(),
      'trustedCallerReferenceId': trustedCallerReferenceId.trim(),
      'trustedContactReferenceId': trustedContactReferenceId.trim(),
      'presentedRideReferenceId': presentedRideReferenceId.trim(),
      'resolvedRideReferenceId': isAuthorized
          ? resolvedRideReferenceId.trim()
          : null,
      'ownershipOrAccessVerified': isAuthorized
          ? ownershipOrAccessVerified
          : false,
      'verifiedAt': verifiedAt.toUtc().toIso8601String(),
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'snapshot': isAuthorized ? snapshot?.toSafeMap() : null,
      'rawPhoneIncluded': false,
      'transcriptIncluded': false,
      'voiceIncluded': false,
      'firebaseUidIncluded': false,
      'rideWriteAuthority': false,
    };
  }
}
