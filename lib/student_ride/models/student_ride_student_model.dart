enum StudentRideStudentStatus {
  draft,
  submitted,
  underReview,
  approved,
  rejected,
  suspended,
}

class StudentRideStudentModel {
  final String studentId;
  final String parentUserId;
  final StudentRideStudentStatus status;

  // Student
  final String fullName;
  final String profilePhotoUrl;
  final String dateOfBirth;
  final String gender;
  final String optionalPhoneNumber;

  // School
  final String schoolId;
  final String schoolName;
  final String campusName;
  final String className;
  final String sectionName;
  final String studentRegistrationNumber;
  final String schoolStartTime;
  final String schoolEndTime;

  // Home and pickup
  final String homeAddress;
  final double homeLatitude;
  final double homeLongitude;
  final String morningPickupAddress;
  final double morningPickupLatitude;
  final double morningPickupLongitude;
  final String afternoonDropAddress;
  final double afternoonDropLatitude;
  final double afternoonDropLongitude;

  // Parent and guardians
  final String primaryGuardianId;
  final List<String> authorizedGuardianIds;

  // Important medical information
  final String bloodGroup;
  final List<String> allergies;
  final List<String> medicalConditions;
  final List<String> medicines;
  final String medicalInstructions;
  final String doctorName;
  final String doctorPhone;

  // Package assignment
  final String activeSubscriptionId;
  final String assignedRouteId;
  final String assignedDriverId;
  final String assignedVehicleId;
  final bool morningServiceRequired;
  final bool afternoonServiceRequired;

  // Admin review
  final String rejectionReason;
  final String adminNotes;
  final String reviewedBy;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentRideStudentModel({
    required this.studentId,
    required this.parentUserId,
    required this.status,
    required this.fullName,
    required this.profilePhotoUrl,
    required this.dateOfBirth,
    required this.gender,
    required this.optionalPhoneNumber,
    required this.schoolId,
    required this.schoolName,
    required this.campusName,
    required this.className,
    required this.sectionName,
    required this.studentRegistrationNumber,
    required this.schoolStartTime,
    required this.schoolEndTime,
    required this.homeAddress,
    required this.homeLatitude,
    required this.homeLongitude,
    required this.morningPickupAddress,
    required this.morningPickupLatitude,
    required this.morningPickupLongitude,
    required this.afternoonDropAddress,
    required this.afternoonDropLatitude,
    required this.afternoonDropLongitude,
    required this.primaryGuardianId,
    required this.authorizedGuardianIds,
    required this.bloodGroup,
    required this.allergies,
    required this.medicalConditions,
    required this.medicines,
    required this.medicalInstructions,
    required this.doctorName,
    required this.doctorPhone,
    required this.activeSubscriptionId,
    required this.assignedRouteId,
    required this.assignedDriverId,
    required this.assignedVehicleId,
    required this.morningServiceRequired,
    required this.afternoonServiceRequired,
    required this.rejectionReason,
    required this.adminNotes,
    required this.reviewedBy,
    required this.submittedAt,
    required this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isApproved {
    return status == StudentRideStudentStatus.approved;
  }

  bool get hasActiveSubscription {
    return activeSubscriptionId.isNotEmpty;
  }

  bool get needsTransport {
    return morningServiceRequired || afternoonServiceRequired;
  }

  factory StudentRideStudentModel.fromMap(
    Map<String, dynamic> map, {
    String documentId = '',
  }) {
    return StudentRideStudentModel(
      studentId: documentId.isNotEmpty
          ? documentId
          : map['studentId']?.toString() ?? '',
      parentUserId: map['parentUserId']?.toString() ?? '',
      status: _statusFromString(map['status']?.toString()),
      fullName: map['fullName']?.toString() ?? '',
      profilePhotoUrl:
          map['profilePhotoUrl']?.toString() ?? '',
      dateOfBirth: map['dateOfBirth']?.toString() ?? '',
      gender: map['gender']?.toString() ?? '',
      optionalPhoneNumber:
          map['optionalPhoneNumber']?.toString() ?? '',
      schoolId: map['schoolId']?.toString() ?? '',
      schoolName: map['schoolName']?.toString() ?? '',
      campusName: map['campusName']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      sectionName: map['sectionName']?.toString() ?? '',
      studentRegistrationNumber:
          map['studentRegistrationNumber']?.toString() ?? '',
      schoolStartTime:
          map['schoolStartTime']?.toString() ?? '',
      schoolEndTime:
          map['schoolEndTime']?.toString() ?? '',
      homeAddress: map['homeAddress']?.toString() ?? '',
      homeLatitude: _readDouble(map['homeLatitude']),
      homeLongitude: _readDouble(map['homeLongitude']),
      morningPickupAddress:
          map['morningPickupAddress']?.toString() ?? '',
      morningPickupLatitude:
          _readDouble(map['morningPickupLatitude']),
      morningPickupLongitude:
          _readDouble(map['morningPickupLongitude']),
      afternoonDropAddress:
          map['afternoonDropAddress']?.toString() ?? '',
      afternoonDropLatitude:
          _readDouble(map['afternoonDropLatitude']),
      afternoonDropLongitude:
          _readDouble(map['afternoonDropLongitude']),
      primaryGuardianId:
          map['primaryGuardianId']?.toString() ?? '',
      authorizedGuardianIds:
          _readStringList(map['authorizedGuardianIds']),
      bloodGroup: map['bloodGroup']?.toString() ?? '',
      allergies: _readStringList(map['allergies']),
      medicalConditions:
          _readStringList(map['medicalConditions']),
      medicines: _readStringList(map['medicines']),
      medicalInstructions:
          map['medicalInstructions']?.toString() ?? '',
      doctorName: map['doctorName']?.toString() ?? '',
      doctorPhone: map['doctorPhone']?.toString() ?? '',
      activeSubscriptionId:
          map['activeSubscriptionId']?.toString() ?? '',
      assignedRouteId:
          map['assignedRouteId']?.toString() ?? '',
      assignedDriverId:
          map['assignedDriverId']?.toString() ?? '',
      assignedVehicleId:
          map['assignedVehicleId']?.toString() ?? '',
      morningServiceRequired:
          map['morningServiceRequired'] != false,
      afternoonServiceRequired:
          map['afternoonServiceRequired'] != false,
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
      'studentId': studentId,
      'parentUserId': parentUserId,
      'status': status.name,
      'fullName': fullName,
      'profilePhotoUrl': profilePhotoUrl,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'optionalPhoneNumber': optionalPhoneNumber,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'campusName': campusName,
      'className': className,
      'sectionName': sectionName,
      'studentRegistrationNumber':
          studentRegistrationNumber,
      'schoolStartTime': schoolStartTime,
      'schoolEndTime': schoolEndTime,
      'homeAddress': homeAddress,
      'homeLatitude': homeLatitude,
      'homeLongitude': homeLongitude,
      'morningPickupAddress': morningPickupAddress,
      'morningPickupLatitude': morningPickupLatitude,
      'morningPickupLongitude': morningPickupLongitude,
      'afternoonDropAddress': afternoonDropAddress,
      'afternoonDropLatitude': afternoonDropLatitude,
      'afternoonDropLongitude': afternoonDropLongitude,
      'primaryGuardianId': primaryGuardianId,
      'authorizedGuardianIds': authorizedGuardianIds,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'medicines': medicines,
      'medicalInstructions': medicalInstructions,
      'doctorName': doctorName,
      'doctorPhone': doctorPhone,
      'activeSubscriptionId': activeSubscriptionId,
      'assignedRouteId': assignedRouteId,
      'assignedDriverId': assignedDriverId,
      'assignedVehicleId': assignedVehicleId,
      'morningServiceRequired': morningServiceRequired,
      'afternoonServiceRequired': afternoonServiceRequired,
      'rejectionReason': rejectionReason,
      'adminNotes': adminNotes,
      'reviewedBy': reviewedBy,
      'submittedAt': submittedAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static StudentRideStudentStatus _statusFromString(
    String? value,
  ) {
    return StudentRideStudentStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => StudentRideStudentStatus.draft,
    );
  }

  static double _readDouble(dynamic value) {
    return value is num ? value.toDouble() : 0;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const [];

    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
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
