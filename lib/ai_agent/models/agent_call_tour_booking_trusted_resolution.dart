import 'agent_call_tour_booking_status_contract.dart';

class AgentCallTourBookingTrustedResolutionStatus {
  AgentCallTourBookingTrustedResolutionStatus._();

  static const String authorizedTourBooking = 'AUTHORIZED_TOUR_BOOKING';
  static const String tourBookingUnavailable = 'TOUR_BOOKING_UNAVAILABLE';
  static const String tourBookingResolutionBlocked =
      'TOUR_BOOKING_RESOLUTION_BLOCKED';

  static const Set<String> values = <String>{
    authorizedTourBooking,
    tourBookingUnavailable,
    tourBookingResolutionBlocked,
  };
}

class AgentCallTourBookingStatusReadStatus {
  AgentCallTourBookingStatusReadStatus._();

  static const String authorizedTourBookingStatus =
      'AUTHORIZED_TOUR_BOOKING_STATUS';
  static const String tourBookingStatusUnavailable =
      'TOUR_BOOKING_STATUS_UNAVAILABLE';
}

class AgentCallTourBookingStatusSnapshot {
  const AgentCallTourBookingStatusSnapshot({
    required this.trustedTourBookingReferenceId,
    required this.tourType,
    required this.bookingStatus,
    required this.paymentStatus,
    required this.assignmentStatus,
    required this.startDate,
    required this.endDate,
    required this.hasDriver,
    required this.hasGuide,
    required this.hasVehicle,
    required this.hasHotel,
    required this.observedAt,
  });

  final String trustedTourBookingReferenceId;
  final String tourType;
  final String bookingStatus;
  final String paymentStatus;
  final String assignmentStatus;
  final DateTime startDate;
  final DateTime endDate;
  final bool hasDriver;
  final bool hasGuide;
  final bool hasVehicle;
  final bool hasHotel;
  final DateTime observedAt;

  void validate() {
    if (trustedTourBookingReferenceId.trim().isEmpty ||
        trustedTourBookingReferenceId.trim().length > 200) {
      throw const AgentCallTourBookingTrustedResolutionException(
        'Trusted Tour booking reference is invalid.',
      );
    }

    for (final String value in <String>[
      tourType,
      bookingStatus,
      paymentStatus,
      assignmentStatus,
    ]) {
      if (value.trim().isEmpty || value.trim().length > 200) {
        throw const AgentCallTourBookingTrustedResolutionException(
          'Tour status snapshot contains invalid operational text.',
        );
      }
    }

    if (endDate.toUtc().isBefore(startDate.toUtc())) {
      throw const AgentCallTourBookingTrustedResolutionException(
        'Tour status snapshot date range is invalid.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return <String, dynamic>{
      'trustedTourBookingReferenceId': trustedTourBookingReferenceId.trim(),
      'tourType': tourType.trim(),
      'bookingStatus': bookingStatus.trim(),
      'paymentStatus': paymentStatus.trim(),
      'assignmentStatus': assignmentStatus.trim(),
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
      'hasDriver': hasDriver,
      'hasGuide': hasGuide,
      'hasVehicle': hasVehicle,
      'hasHotel': hasHotel,
      'observedAt': observedAt.toUtc().toIso8601String(),
    };
  }
}

class AgentCallTourBookingTrustedResolutionRequest {
  const AgentCallTourBookingTrustedResolutionRequest({
    required this.callSessionId,
    required this.requestedBy,
    required this.trustedCallerReferenceId,
    required this.trustedContactReferenceId,
    required this.presentedTourBookingReferenceId,
  });

  factory AgentCallTourBookingTrustedResolutionRequest.fromCallRequest(
    AgentCallTourBookingStatusRequest request,
  ) {
    request.validate();

    return AgentCallTourBookingTrustedResolutionRequest(
      callSessionId: request.callSessionId.trim(),
      requestedBy: request.requestedBy.trim(),
      trustedCallerReferenceId: request.trustedCallerReferenceId.trim(),
      trustedContactReferenceId: request.trustedContactReferenceId.trim(),
      presentedTourBookingReferenceId: request.trustedTourBookingReferenceId
          .trim(),
    );
  }

  final String callSessionId;
  final String requestedBy;
  final String trustedCallerReferenceId;
  final String trustedContactReferenceId;
  final String presentedTourBookingReferenceId;

  void validate() {
    if (callSessionId.trim().isEmpty ||
        requestedBy.trim().isEmpty ||
        trustedCallerReferenceId.trim().isEmpty ||
        trustedContactReferenceId.trim().isEmpty ||
        presentedTourBookingReferenceId.trim().isEmpty) {
      throw const AgentCallTourBookingTrustedResolutionException(
        'Complete trusted Tour resolution binding is required.',
      );
    }
  }
}

class AgentCallTourBookingTrustedResolutionReceipt {
  const AgentCallTourBookingTrustedResolutionReceipt({
    required this.status,
    required this.source,
    required this.callSessionId,
    required this.requestedBy,
    required this.trustedCallerReferenceId,
    required this.trustedContactReferenceId,
    required this.presentedTourBookingReferenceId,
    required this.backendAccessVerified,
    required this.resolvedAt,
    this.snapshot,
  });

  static const String trustedBackendSource =
      'TRUSTED_BACKEND_TOUR_BOOKING_RESOLVER';

  static const Duration maxAge = Duration(minutes: 2);
  static const Duration maxFutureSkew = Duration(seconds: 15);

  final String status;
  final String source;
  final String callSessionId;
  final String requestedBy;
  final String trustedCallerReferenceId;
  final String trustedContactReferenceId;
  final String presentedTourBookingReferenceId;
  final bool backendAccessVerified;
  final DateTime resolvedAt;
  final AgentCallTourBookingStatusSnapshot? snapshot;

  bool get isAuthorized =>
      status ==
      AgentCallTourBookingTrustedResolutionStatus.authorizedTourBooking;

  void validateFor({
    required AgentCallTourBookingTrustedResolutionRequest request,
    required DateTime now,
  }) {
    request.validate();

    if (!AgentCallTourBookingTrustedResolutionStatus.values.contains(status)) {
      throw const AgentCallTourBookingTrustedResolutionException(
        'Unknown trusted Tour resolution status.',
      );
    }

    if (source != trustedBackendSource) {
      throw const AgentCallTourBookingTrustedResolutionException(
        'Untrusted Tour resolver source.',
      );
    }

    if (callSessionId.trim() != request.callSessionId.trim() ||
        requestedBy.trim() != request.requestedBy.trim() ||
        trustedCallerReferenceId.trim() !=
            request.trustedCallerReferenceId.trim() ||
        trustedContactReferenceId.trim() !=
            request.trustedContactReferenceId.trim() ||
        presentedTourBookingReferenceId.trim() !=
            request.presentedTourBookingReferenceId.trim()) {
      throw const AgentCallTourBookingTrustedResolutionException(
        'Trusted Tour resolver binding mismatch.',
      );
    }

    final DateTime utcNow = now.toUtc();
    final DateTime utcResolvedAt = resolvedAt.toUtc();

    if (utcResolvedAt.isAfter(utcNow.add(maxFutureSkew))) {
      throw const AgentCallTourBookingTrustedResolutionException(
        'Trusted Tour resolution is too far in the future.',
      );
    }

    if (utcNow.difference(utcResolvedAt) > maxAge) {
      throw const AgentCallTourBookingTrustedResolutionException(
        'Trusted Tour resolution is stale.',
      );
    }

    if (isAuthorized) {
      if (!backendAccessVerified || snapshot == null) {
        throw const AgentCallTourBookingTrustedResolutionException(
          'Authorized Tour resolution requires verified access and snapshot.',
        );
      }

      snapshot!.validate();

      if (snapshot!.trustedTourBookingReferenceId.trim() !=
          request.presentedTourBookingReferenceId.trim()) {
        throw const AgentCallTourBookingTrustedResolutionException(
          'Tour snapshot/reference binding mismatch.',
        );
      }

      return;
    }

    if (backendAccessVerified || snapshot != null) {
      throw const AgentCallTourBookingTrustedResolutionException(
        'Unavailable/blocked Tour resolution must expose no verified snapshot.',
      );
    }
  }
}

class AgentCallTourBookingStatusReadEvidence {
  const AgentCallTourBookingStatusReadEvidence._({
    required this.status,
    required this.observedAt,
    this.snapshot,
  });

  factory AgentCallTourBookingStatusReadEvidence.authorized({
    required AgentCallTourBookingStatusSnapshot snapshot,
    required DateTime observedAt,
  }) {
    snapshot.validate();

    return AgentCallTourBookingStatusReadEvidence._(
      status: AgentCallTourBookingStatusReadStatus.authorizedTourBookingStatus,
      observedAt: observedAt.toUtc(),
      snapshot: snapshot,
    );
  }

  factory AgentCallTourBookingStatusReadEvidence.unavailable({
    required DateTime observedAt,
  }) {
    return AgentCallTourBookingStatusReadEvidence._(
      status: AgentCallTourBookingStatusReadStatus.tourBookingStatusUnavailable,
      observedAt: observedAt.toUtc(),
    );
  }

  final String status;
  final DateTime observedAt;
  final AgentCallTourBookingStatusSnapshot? snapshot;

  bool get isAuthorized =>
      status ==
      AgentCallTourBookingStatusReadStatus.authorizedTourBookingStatus;

  Map<String, dynamic> toSafeMap() {
    return <String, dynamic>{
      'status': status,
      'observedAt': observedAt.toUtc().toIso8601String(),
      'snapshot': snapshot?.toSafeMap(),
      'tourBookingExistenceDisclosedWhenUnavailable': false,
      'userIdIncluded': false,
      'phoneIncluded': false,
      'emailIncluded': false,
      'cnicIncluded': false,
      'pickupCoordinatesIncluded': false,
      'specialRequestIncluded': false,
      'financialAmountsIncluded': false,
      'privateAssignmentIdsIncluded': false,
      'writeAuthority': false,
      'cancelAuthority': false,
      'paymentMutationAuthority': false,
      'assignmentMutationAuthority': false,
    };
  }
}

class AgentCallTourBookingTrustedResolutionException implements Exception {
  const AgentCallTourBookingTrustedResolutionException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentCallTourBookingTrustedResolutionException: $message';
}
