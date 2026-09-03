enum StudentRideDriverApplicationStatus {
  draft,
  submitted,
  underReview,
  approved,
  rejected,
  suspended,
}

class StudentRideDriverApplicationModel {
  // Application and account
  final String id;
  final String userId;
  final String existingNormalDriverId;
  final StudentRideDriverApplicationStatus status;

  // Personal information
  final String fullName;
  final String phoneNumber;
  final String cnicNumber;
  final String dateOfBirth;
  final String address;
  final String city;
  final String emergencyContactName;
  final String emergencyContactPhone;

  // Driver documents
  final String profilePhotoUrl;
  final String cnicFrontUrl;
  final String cnicBackUrl;
  final String drivingLicenseNumber;
  final String drivingLicenseFrontUrl;
  final String drivingLicenseBackUrl;
  final String policeVerificationUrl;

  // Vehicle information
  final String vehicleType;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleColor;
  final String vehicleRegistrationNumber;
  final int vehicleModelYear;
  final int seatingCapacity;
  final String vehicleFrontPhotoUrl;
  final String vehicleBackPhotoUrl;
  final String vehicleRegistrationDocumentUrl;
  final String vehicleFitnessCertificateUrl;
  final String vehicleInsuranceDocumentUrl;

  // Student transport checks
  final int schoolTransportExperienceYears;
  final bool hasSchoolTransportExperience;
  final bool hasFirstAidTraining;
  final bool childSafetyDeclarationAccepted;
  final bool backgroundCheckConsentAccepted;
  final bool hasAttendant;
  final String attendantName;
  final String attendantPhone;
  final String attendantCnicNumber;

  // Availability
  final bool morningAvailable;
  final bool afternoonAvailable;
  final List<String> preferredSchoolIds;
  final List<String> preferredRouteIds;

  // Payment settlement
  final String settlementMethod;
  final String accountTitle;
  final String accountNumber;
  final String bankName;

  // Admin review
  final String rejectionReason;
  final String adminNotes;
  final String reviewedBy;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentRideDriverApplicationModel({
    required this.id,
    required this.userId,
    required this.existingNormalDriverId,
    required this.status,
    required this.fullName,
    required this.phoneNumber,
    required this.cnicNumber,
    required this.dateOfBirth,
    required this.address,
    required this.city,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.profilePhotoUrl,
    required this.cnicFrontUrl,
    required this.cnicBackUrl,
    required this.drivingLicenseNumber,
    required this.drivingLicenseFrontUrl,
    required this.drivingLicenseBackUrl,
    required this.policeVerificationUrl,
    required this.vehicleType,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehicleRegistrationNumber,
    required this.vehicleModelYear,
    required this.seatingCapacity,
    required this.vehicleFrontPhotoUrl,
    required this.vehicleBackPhotoUrl,
    required this.vehicleRegistrationDocumentUrl,
    required this.vehicleFitnessCertificateUrl,
    required this.vehicleInsuranceDocumentUrl,
    required this.schoolTransportExperienceYears,
    required this.hasSchoolTransportExperience,
    required this.hasFirstAidTraining,
    required this.childSafetyDeclarationAccepted,
    required this.backgroundCheckConsentAccepted,
    required this.hasAttendant,
    required this.attendantName,
    required this.attendantPhone,
    required this.attendantCnicNumber,
    required this.morningAvailable,
    required this.afternoonAvailable,
    required this.preferredSchoolIds,
    required this.preferredRouteIds,
    required this.settlementMethod,
    required this.accountTitle,
    required this.accountNumber,
    required this.bankName,
    required this.rejectionReason,
    required this.adminNotes,
    required this.reviewedBy,
    required this.submittedAt,
    required this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isApproved {
    return status == StudentRideDriverApplicationStatus.approved;
  }

  bool get isPending {
    return status == StudentRideDriverApplicationStatus.submitted ||
        status == StudentRideDriverApplicationStatus.underReview;
  }

  bool get hasRequiredConsent {
    return childSafetyDeclarationAccepted &&
        backgroundCheckConsentAccepted;
  }

  bool get hasValidAvailability {
    return morningAvailable || afternoonAvailable;
  }

  factory StudentRideDriverApplicationModel.fromMap(
    Map<String, dynamic> map, {
    String documentId = '',
  }) {
    return StudentRideDriverApplicationModel(
      id: documentId.isNotEmpty
          ? documentId
          : map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      existingNormalDriverId:
          map['existingNormalDriverId']?.toString() ?? '',
      status: _statusFromString(map['status']?.toString()),
      fullName: map['fullName']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      cnicNumber: map['cnicNumber']?.toString() ?? '',
      dateOfBirth: map['dateOfBirth']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      emergencyContactName:
          map['emergencyContactName']?.toString() ?? '',
      emergencyContactPhone:
          map['emergencyContactPhone']?.toString() ?? '',
      profilePhotoUrl: map['profilePhotoUrl']?.toString() ?? '',
      cnicFrontUrl: map['cnicFrontUrl']?.toString() ?? '',
      cnicBackUrl: map['cnicBackUrl']?.toString() ?? '',
      drivingLicenseNumber:
          map['drivingLicenseNumber']?.toString() ?? '',
      drivingLicenseFrontUrl:
          map['drivingLicenseFrontUrl']?.toString() ?? '',
      drivingLicenseBackUrl:
          map['drivingLicenseBackUrl']?.toString() ?? '',
      policeVerificationUrl:
          map['policeVerificationUrl']?.toString() ?? '',
      vehicleType: map['vehicleType']?.toString() ?? '',
      vehicleMake: map['vehicleMake']?.toString() ?? '',
      vehicleModel: map['vehicleModel']?.toString() ?? '',
      vehicleColor: map['vehicleColor']?.toString() ?? '',
      vehicleRegistrationNumber:
          map['vehicleRegistrationNumber']?.toString() ?? '',
      vehicleModelYear: _readInt(map['vehicleModelYear']),
      seatingCapacity: _readInt(map['seatingCapacity'], fallback: 1),
      vehicleFrontPhotoUrl:
          map['vehicleFrontPhotoUrl']?.toString() ?? '',
      vehicleBackPhotoUrl:
          map['vehicleBackPhotoUrl']?.toString() ?? '',
      vehicleRegistrationDocumentUrl:
          map['vehicleRegistrationDocumentUrl']?.toString() ?? '',
      vehicleFitnessCertificateUrl:
          map['vehicleFitnessCertificateUrl']?.toString() ?? '',
      vehicleInsuranceDocumentUrl:
          map['vehicleInsuranceDocumentUrl']?.toString() ?? '',
      schoolTransportExperienceYears:
          _readInt(map['schoolTransportExperienceYears']),
      hasSchoolTransportExperience:
          map['hasSchoolTransportExperience'] == true,
      hasFirstAidTraining: map['hasFirstAidTraining'] == true,
      childSafetyDeclarationAccepted:
          map['childSafetyDeclarationAccepted'] == true,
      backgroundCheckConsentAccepted:
          map['backgroundCheckConsentAccepted'] == true,
      hasAttendant: map['hasAttendant'] == true,
      attendantName: map['attendantName']?.toString() ?? '',
      attendantPhone: map['attendantPhone']?.toString() ?? '',
      attendantCnicNumber:
          map['attendantCnicNumber']?.toString() ?? '',
      morningAvailable: map['morningAvailable'] == true,
      afternoonAvailable: map['afternoonAvailable'] == true,
      preferredSchoolIds: _readStringList(map['preferredSchoolIds']),
      preferredRouteIds: _readStringList(map['preferredRouteIds']),
      settlementMethod: map['settlementMethod']?.toString() ?? '',
      accountTitle: map['accountTitle']?.toString() ?? '',
      accountNumber: map['accountNumber']?.toString() ?? '',
      bankName: map['bankName']?.toString() ?? '',
      rejectionReason: map['rejectionReason']?.toString() ?? '',
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
      'id': id,
      'userId': userId,
      'existingNormalDriverId': existingNormalDriverId,
      'status': status.name,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'cnicNumber': cnicNumber,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'city': city,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'profilePhotoUrl': profilePhotoUrl,
      'cnicFrontUrl': cnicFrontUrl,
      'cnicBackUrl': cnicBackUrl,
      'drivingLicenseNumber': drivingLicenseNumber,
      'drivingLicenseFrontUrl': drivingLicenseFrontUrl,
      'drivingLicenseBackUrl': drivingLicenseBackUrl,
      'policeVerificationUrl': policeVerificationUrl,
      'vehicleType': vehicleType,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'vehicleRegistrationNumber': vehicleRegistrationNumber,
      'vehicleModelYear': vehicleModelYear,
      'seatingCapacity': seatingCapacity,
      'vehicleFrontPhotoUrl': vehicleFrontPhotoUrl,
      'vehicleBackPhotoUrl': vehicleBackPhotoUrl,
      'vehicleRegistrationDocumentUrl':
          vehicleRegistrationDocumentUrl,
      'vehicleFitnessCertificateUrl': vehicleFitnessCertificateUrl,
      'vehicleInsuranceDocumentUrl': vehicleInsuranceDocumentUrl,
      'schoolTransportExperienceYears':
          schoolTransportExperienceYears,
      'hasSchoolTransportExperience': hasSchoolTransportExperience,
      'hasFirstAidTraining': hasFirstAidTraining,
      'childSafetyDeclarationAccepted':
          childSafetyDeclarationAccepted,
      'backgroundCheckConsentAccepted':
          backgroundCheckConsentAccepted,
      'hasAttendant': hasAttendant,
      'attendantName': attendantName,
      'attendantPhone': attendantPhone,
      'attendantCnicNumber': attendantCnicNumber,
      'morningAvailable': morningAvailable,
      'afternoonAvailable': afternoonAvailable,
      'preferredSchoolIds': preferredSchoolIds,
      'preferredRouteIds': preferredRouteIds,
      'settlementMethod': settlementMethod,
      'accountTitle': accountTitle,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'rejectionReason': rejectionReason,
      'adminNotes': adminNotes,
      'reviewedBy': reviewedBy,
      'submittedAt': submittedAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static StudentRideDriverApplicationStatus _statusFromString(
    String? value,
  ) {
    return StudentRideDriverApplicationStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => StudentRideDriverApplicationStatus.draft,
    );
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    return value is num ? value.toInt() : fallback;
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
