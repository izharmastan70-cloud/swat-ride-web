enum StudentRideSubscriptionStatus {
  draft,
  submitted,
  routeReview,
  waitlisted,
  paymentPending,
  active,
  paused,
  expired,
  cancelled,
  rejected,
}

class StudentRideSubscriptionModel {
  final String subscriptionId;
  final String parentId;
  final String studentId;
  final String packageId;
  final StudentRideSubscriptionStatus status;

  // Selected service snapshot
  final String packageName;
  final String tripType;
  final String priceMode;
  final bool doorToDoor;
  final bool autoRenew;

  // Assignment
  final String schoolId;
  // Legacy combined assignment fields remain for compatibility.
  final String routeId;
  final String driverId;
  final String vehicleId;
  final String seatNumber;

  // Shift-specific assignments support two-way subscriptions.
  final String morningRouteId;
  final String morningDriverId;
  final String morningVehicleId;
  final String afternoonRouteId;
  final String afternoonDriverId;
  final String afternoonVehicleId;

  // Schedule
  final String morningPickupTime;
  final String afternoonDropTime;
  final List<int> operatingWeekdays;

  // Subscription period
  final DateTime requestedStartDate;
  final DateTime? approvedStartDate;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? nextBillingDate;

  // Approved price snapshot
  final double monthlyAmount;
  final double registrationFee;
  final double discountAmount;
  final double approvedTotalAmount;
  final String currencyCode;

  // Current invoice
  final String currentInvoiceId;
  final String paymentStatus;

  // Pause and cancellation
  final DateTime? pausedAt;
  final DateTime? resumeDate;
  final String pauseReason;
  final DateTime? cancelledAt;
  final String cancellationReason;

  // Admin review
  final String rejectionReason;
  final String adminNotes;
  final String reviewedBy;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentRideSubscriptionModel({
    required this.subscriptionId,
    required this.parentId,
    required this.studentId,
    required this.packageId,
    required this.status,
    required this.packageName,
    required this.tripType,
    required this.priceMode,
    required this.doorToDoor,
    required this.autoRenew,
    required this.schoolId,
    required this.routeId,
    required this.driverId,
    required this.vehicleId,
    required this.seatNumber,
    required this.morningRouteId,
    required this.morningDriverId,
    required this.morningVehicleId,
    required this.afternoonRouteId,
    required this.afternoonDriverId,
    required this.afternoonVehicleId,
    required this.morningPickupTime,
    required this.afternoonDropTime,
    required this.operatingWeekdays,
    required this.requestedStartDate,
    required this.approvedStartDate,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.nextBillingDate,
    required this.monthlyAmount,
    required this.registrationFee,
    required this.discountAmount,
    required this.approvedTotalAmount,
    required this.currencyCode,
    required this.currentInvoiceId,
    required this.paymentStatus,
    required this.pausedAt,
    required this.resumeDate,
    required this.pauseReason,
    required this.cancelledAt,
    required this.cancellationReason,
    required this.rejectionReason,
    required this.adminNotes,
    required this.reviewedBy,
    required this.submittedAt,
    required this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive {
    return status == StudentRideSubscriptionStatus.active;
  }

  bool get needsPayment {
    return status ==
            StudentRideSubscriptionStatus.paymentPending ||
        paymentStatus != 'paid';
  }

  bool get hasMorningAssignment {
    return morningRouteId.isNotEmpty &&
        morningDriverId.isNotEmpty &&
        morningVehicleId.isNotEmpty;
  }

  bool get hasAfternoonAssignment {
    return afternoonRouteId.isNotEmpty &&
        afternoonDriverId.isNotEmpty &&
        afternoonVehicleId.isNotEmpty;
  }

  bool get hasRouteAssignment {
    if (tripType == 'morningOnly') {
      return hasMorningAssignment ||
          (routeId.isNotEmpty &&
              driverId.isNotEmpty &&
              vehicleId.isNotEmpty);
    }

    if (tripType == 'afternoonOnly') {
      return hasAfternoonAssignment ||
          (routeId.isNotEmpty &&
              driverId.isNotEmpty &&
              vehicleId.isNotEmpty);
    }

    return hasMorningAssignment && hasAfternoonAssignment;
  }

  factory StudentRideSubscriptionModel.fromMap(
    Map<String, dynamic> map, {
    String documentId = '',
  }) {
    final DateTime now = DateTime.now();

    return StudentRideSubscriptionModel(
      subscriptionId: documentId.isNotEmpty
          ? documentId
          : map['subscriptionId']?.toString() ?? '',
      parentId: map['parentId']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      packageId: map['packageId']?.toString() ?? '',
      status: _statusFromString(map['status']?.toString()),
      packageName: map['packageName']?.toString() ?? '',
      tripType: map['tripType']?.toString() ?? 'twoWay',
      priceMode:
          map['priceMode']?.toString() ?? 'fixedMonthly',
      doorToDoor: map['doorToDoor'] == true,
      autoRenew: map['autoRenew'] != false,
      schoolId: map['schoolId']?.toString() ?? '',
      routeId: map['routeId']?.toString() ?? '',
      driverId: map['driverId']?.toString() ?? '',
      vehicleId: map['vehicleId']?.toString() ?? '',
      seatNumber: map['seatNumber']?.toString() ?? '',
      morningRouteId:
          map['morningRouteId']?.toString() ?? '',
      morningDriverId:
          map['morningDriverId']?.toString() ?? '',
      morningVehicleId:
          map['morningVehicleId']?.toString() ?? '',
      afternoonRouteId:
          map['afternoonRouteId']?.toString() ?? '',
      afternoonDriverId:
          map['afternoonDriverId']?.toString() ?? '',
      afternoonVehicleId:
          map['afternoonVehicleId']?.toString() ?? '',
      morningPickupTime:
          map['morningPickupTime']?.toString() ?? '',
      afternoonDropTime:
          map['afternoonDropTime']?.toString() ?? '',
      operatingWeekdays:
          _readIntList(map['operatingWeekdays']),
      requestedStartDate:
          _readDateTime(map['requestedStartDate']) ?? now,
      approvedStartDate:
          _readDateTime(map['approvedStartDate']),
      currentPeriodStart:
          _readDateTime(map['currentPeriodStart']),
      currentPeriodEnd:
          _readDateTime(map['currentPeriodEnd']),
      nextBillingDate:
          _readDateTime(map['nextBillingDate']),
      monthlyAmount: _readDouble(map['monthlyAmount']),
      registrationFee:
          _readDouble(map['registrationFee']),
      discountAmount: _readDouble(map['discountAmount']),
      approvedTotalAmount:
          _readDouble(map['approvedTotalAmount']),
      currencyCode: map['currencyCode']?.toString() ?? 'PKR',
      currentInvoiceId:
          map['currentInvoiceId']?.toString() ?? '',
      paymentStatus:
          map['paymentStatus']?.toString() ?? 'pending',
      pausedAt: _readDateTime(map['pausedAt']),
      resumeDate: _readDateTime(map['resumeDate']),
      pauseReason: map['pauseReason']?.toString() ?? '',
      cancelledAt: _readDateTime(map['cancelledAt']),
      cancellationReason:
          map['cancellationReason']?.toString() ?? '',
      rejectionReason:
          map['rejectionReason']?.toString() ?? '',
      adminNotes: map['adminNotes']?.toString() ?? '',
      reviewedBy: map['reviewedBy']?.toString() ?? '',
      submittedAt: _readDateTime(map['submittedAt']),
      reviewedAt: _readDateTime(map['reviewedAt']),
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subscriptionId': subscriptionId,
      'parentId': parentId,
      'studentId': studentId,
      'packageId': packageId,
      'status': status.name,
      'packageName': packageName,
      'tripType': tripType,
      'priceMode': priceMode,
      'doorToDoor': doorToDoor,
      'autoRenew': autoRenew,
      'schoolId': schoolId,
      'routeId': routeId,
      'driverId': driverId,
      'vehicleId': vehicleId,
      'seatNumber': seatNumber,
      'morningRouteId': morningRouteId,
      'morningDriverId': morningDriverId,
      'morningVehicleId': morningVehicleId,
      'afternoonRouteId': afternoonRouteId,
      'afternoonDriverId': afternoonDriverId,
      'afternoonVehicleId': afternoonVehicleId,
      'morningPickupTime': morningPickupTime,
      'afternoonDropTime': afternoonDropTime,
      'operatingWeekdays': operatingWeekdays,
      'requestedStartDate':
          requestedStartDate.toIso8601String(),
      'approvedStartDate':
          approvedStartDate?.toIso8601String(),
      'currentPeriodStart':
          currentPeriodStart?.toIso8601String(),
      'currentPeriodEnd':
          currentPeriodEnd?.toIso8601String(),
      'nextBillingDate':
          nextBillingDate?.toIso8601String(),
      'monthlyAmount': monthlyAmount,
      'registrationFee': registrationFee,
      'discountAmount': discountAmount,
      'approvedTotalAmount': approvedTotalAmount,
      'currencyCode': currencyCode,
      'currentInvoiceId': currentInvoiceId,
      'paymentStatus': paymentStatus,
      'pausedAt': pausedAt?.toIso8601String(),
      'resumeDate': resumeDate?.toIso8601String(),
      'pauseReason': pauseReason,
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'rejectionReason': rejectionReason,
      'adminNotes': adminNotes,
      'reviewedBy': reviewedBy,
      'submittedAt': submittedAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static StudentRideSubscriptionStatus _statusFromString(
    String? value,
  ) {
    return StudentRideSubscriptionStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => StudentRideSubscriptionStatus.draft,
    );
  }

  static double _readDouble(dynamic value) {
    return value is num ? value.toDouble() : 0;
  }

  static List<int> _readIntList(dynamic value) {
    if (value is! List) {
      return const [1, 2, 3, 4, 5];
    }

    return value
        .whereType<num>()
        .map((item) => item.toInt())
        .where((item) => item >= 1 && item <= 7)
        .toSet()
        .toList()
      ..sort();
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    try {
      final dynamic converted = value.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Supports Firestore Timestamp without importing cloud_firestore.
    }

    return DateTime.tryParse(value.toString());
  }
}

