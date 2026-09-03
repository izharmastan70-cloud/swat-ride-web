class AgentCallExistingRideSupportIntent {
  AgentCallExistingRideSupportIntent._();

  static const String status = 'STATUS';
  static const String details = 'DETAILS';

  static const Set<String> values = <String>{status, details};
}

class AgentCallExistingRideReadStatus {
  AgentCallExistingRideReadStatus._();

  static const String found = 'AUTHORIZED_RIDE_FOUND';
  static const String notFound = 'AUTHORIZED_RIDE_NOT_FOUND';
  static const String blocked = 'EXISTING_RIDE_READ_BLOCKED';

  static const Set<String> values = <String>{found, notFound, blocked};
}

/// Call Agent Stage 2 request for one already-existing Ride.
///
/// The request deliberately carries only opaque trusted references.
/// Raw phone number, transcript text, voice/audio and FirebaseAuth user identity
/// are not ownership proof and are therefore not part of this contract.
class AgentCallExistingRideSupportRequest {
  const AgentCallExistingRideSupportRequest({
    required this.callSessionId,
    required this.requestedBy,
    required this.trustedCallerReferenceId,
    required this.trustedContactReferenceId,
    required this.trustedRideReferenceId,
    required this.intent,
  });

  final String callSessionId;
  final String requestedBy;
  final String trustedCallerReferenceId;
  final String trustedContactReferenceId;
  final String trustedRideReferenceId;
  final String intent;

  void validate() {
    if (callSessionId.trim().isEmpty ||
        requestedBy.trim().isEmpty ||
        trustedCallerReferenceId.trim().isEmpty ||
        trustedContactReferenceId.trim().isEmpty ||
        trustedRideReferenceId.trim().isEmpty) {
      throw const AgentCallExistingRideSupportException(
        'Complete trusted existing-Ride support binding is required.',
      );
    }

    if (!AgentCallExistingRideSupportIntent.values.contains(intent)) {
      throw const AgentCallExistingRideSupportException(
        'Unsupported existing-Ride support intent.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    return <String, dynamic>{
      'callSessionId': callSessionId.trim(),
      'requestedBy': requestedBy.trim(),
      'trustedCallerReferenceId': trustedCallerReferenceId.trim(),
      'trustedContactReferenceId': trustedContactReferenceId.trim(),
      'trustedRideReferenceId': trustedRideReferenceId.trim(),
      'intent': intent,
      'rawPhoneStored': false,
      'transcriptStored': false,
      'voiceStored': false,
      'firebaseUserUsedAsCaller': false,
    };
  }
}

/// Privacy-minimized view of one existing Ride.
///
/// Intentionally excluded:
/// - rider name/phone/userId;
/// - driver phone/userId;
/// - live driver GPS/location/heading/speed;
/// - Ride start PIN / OTP / security secrets;
/// - exact raw pickup/destination coordinates;
/// - payment credentials;
/// - internal rejected-driver lists.
class AgentCallExistingRideSupportSnapshot {
  const AgentCallExistingRideSupportSnapshot({
    required this.trustedRideReferenceId,
    required this.rideStatus,
    required this.vehicleName,
    required this.driverAssigned,
    required this.estimatedFare,
    required this.paymentStatus,
    required this.observedAt,
    this.driverDisplayName,
    this.driverVehicleType,
    this.driverVehicleNumber,
  });

  final String trustedRideReferenceId;
  final String rideStatus;
  final String vehicleName;
  final bool driverAssigned;
  final String? driverDisplayName;
  final String? driverVehicleType;
  final String? driverVehicleNumber;
  final double estimatedFare;
  final String paymentStatus;
  final DateTime observedAt;

  void validate() {
    if (trustedRideReferenceId.trim().isEmpty ||
        rideStatus.trim().isEmpty ||
        vehicleName.trim().isEmpty ||
        paymentStatus.trim().isEmpty) {
      throw const AgentCallExistingRideSupportException(
        'Existing-Ride support snapshot is incomplete.',
      );
    }

    if (estimatedFare < 0) {
      throw const AgentCallExistingRideSupportException(
        'Existing-Ride support fare cannot be negative.',
      );
    }

    if (!driverAssigned &&
        ((driverDisplayName?.trim().isNotEmpty ?? false) ||
            (driverVehicleType?.trim().isNotEmpty ?? false) ||
            (driverVehicleNumber?.trim().isNotEmpty ?? false))) {
      throw const AgentCallExistingRideSupportException(
        'Unassigned Ride cannot expose driver display details.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    return <String, dynamic>{
      'trustedRideReferenceId': trustedRideReferenceId.trim(),
      'rideStatus': rideStatus.trim(),
      'vehicleName': vehicleName.trim(),
      'driverAssigned': driverAssigned,
      'driverDisplayName': _nullable(driverDisplayName),
      'driverVehicleType': _nullable(driverVehicleType),
      'driverVehicleNumber': _nullable(driverVehicleNumber),
      'estimatedFare': estimatedFare,
      'paymentStatus': paymentStatus.trim(),
      'observedAt': observedAt.toUtc().toIso8601String(),
      'riderPhoneIncluded': false,
      'driverPhoneIncluded': false,
      'liveDriverLocationIncluded': false,
      'rideStartPinIncluded': false,
      'rawCoordinatesIncluded': false,
      'paymentCredentialIncluded': false,
    };
  }

  static String? _nullable(String? value) {
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }
}

/// Evidence returned only by a trusted existing-Ride read gateway.
///
/// This evidence proves only that the requested caller/contact/session binding
/// was allowed to read the exact Ride reference. It is never write authority.
class AgentCallExistingRideReadEvidence {
  const AgentCallExistingRideReadEvidence({
    required this.status,
    required this.code,
    required this.verificationSource,
    required this.callSessionId,
    required this.requestedBy,
    required this.trustedCallerReferenceId,
    required this.trustedContactReferenceId,
    required this.trustedRideReferenceId,
    required this.verifiedAt,
    required this.expiresAt,
    this.snapshot,
  });

  static const String trustedVerificationSource =
      'TRUSTED_EXISTING_RIDE_READ_GATEWAY';

  final String status;
  final String code;
  final String verificationSource;
  final String callSessionId;
  final String requestedBy;
  final String trustedCallerReferenceId;
  final String trustedContactReferenceId;
  final String trustedRideReferenceId;
  final DateTime verifiedAt;
  final DateTime expiresAt;
  final AgentCallExistingRideSupportSnapshot? snapshot;

  bool get isFound =>
      status == AgentCallExistingRideReadStatus.found && snapshot != null;

  bool get isNotFound =>
      status == AgentCallExistingRideReadStatus.notFound && snapshot == null;

  bool get isBlocked =>
      status == AgentCallExistingRideReadStatus.blocked && snapshot == null;

  void validate() {
    if (!AgentCallExistingRideReadStatus.values.contains(status) ||
        code.trim().isEmpty ||
        callSessionId.trim().isEmpty ||
        requestedBy.trim().isEmpty ||
        trustedCallerReferenceId.trim().isEmpty ||
        trustedContactReferenceId.trim().isEmpty ||
        trustedRideReferenceId.trim().isEmpty) {
      throw const AgentCallExistingRideSupportException(
        'Existing-Ride read evidence is incomplete.',
      );
    }

    if (!expiresAt.toUtc().isAfter(verifiedAt.toUtc())) {
      throw const AgentCallExistingRideSupportException(
        'Existing-Ride read evidence expiry is invalid.',
      );
    }

    if (expiresAt.toUtc().difference(verifiedAt.toUtc()) >
        const Duration(minutes: 2)) {
      throw const AgentCallExistingRideSupportException(
        'Existing-Ride read evidence lifetime is too long.',
      );
    }

    if (isFound) {
      if (verificationSource != trustedVerificationSource) {
        throw const AgentCallExistingRideSupportException(
          'Found Ride evidence requires trusted verification source.',
        );
      }

      snapshot!.validate();

      if (snapshot!.trustedRideReferenceId.trim() !=
          trustedRideReferenceId.trim()) {
        throw const AgentCallExistingRideSupportException(
          'Ride snapshot reference does not match trusted Ride binding.',
        );
      }
    } else if (snapshot != null) {
      throw const AgentCallExistingRideSupportException(
        'Non-found Ride evidence must not expose a Ride snapshot.',
      );
    }
  }

  bool exactlyMatchesRequest(AgentCallExistingRideSupportRequest request) {
    return callSessionId.trim() == request.callSessionId.trim() &&
        requestedBy.trim() == request.requestedBy.trim() &&
        trustedCallerReferenceId.trim() ==
            request.trustedCallerReferenceId.trim() &&
        trustedContactReferenceId.trim() ==
            request.trustedContactReferenceId.trim() &&
        trustedRideReferenceId.trim() == request.trustedRideReferenceId.trim();
  }

  bool isFreshAt(DateTime now) {
    final DateTime utcNow = now.toUtc();

    return !verifiedAt.toUtc().isAfter(utcNow) &&
        expiresAt.toUtc().isAfter(utcNow);
  }
}

class AgentCallExistingRideSupportResult {
  const AgentCallExistingRideSupportResult({
    required this.status,
    required this.code,
    required this.createdAt,
    this.snapshot,
  });

  static const String ready = 'EXISTING_RIDE_SUPPORT_READY';
  static const String unavailable = 'EXISTING_RIDE_SUPPORT_UNAVAILABLE';

  final String status;
  final String code;
  final DateTime createdAt;
  final AgentCallExistingRideSupportSnapshot? snapshot;

  bool get isReady => status == ready && snapshot != null;
  bool get isUnavailable => status == unavailable && snapshot == null;

  Map<String, dynamic> toSafeMap() {
    return <String, dynamic>{
      'status': status,
      'code': code,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'snapshot': snapshot?.toSafeMap(),
      'rideWritePerformed': false,
      'cancellationPerformed': false,
      'driverReassignmentPerformed': false,
      'paymentMutationPerformed': false,
      'refundPerformed': false,
      'fareMutationPerformed': false,
    };
  }
}

class AgentCallExistingRideSupportException implements Exception {
  const AgentCallExistingRideSupportException(this.message);

  final String message;

  @override
  String toString() => 'AgentCallExistingRideSupportException: $message';
}
