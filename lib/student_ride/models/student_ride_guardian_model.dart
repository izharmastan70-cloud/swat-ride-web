enum StudentRideGuardianRelation {
  father,
  mother,
  brother,
  sister,
  grandfather,
  grandmother,
  uncle,
  aunt,
  familyMember,
  other,
}

enum StudentRideGuardianVerificationStatus {
  pending,
  verified,
  rejected,
  suspended,
}

class StudentRideGuardianModel {
  final String guardianId;
  final String parentUserId;
  final String fullName;
  final String phoneNumber;
  final String cnicNumber;
  final StudentRideGuardianRelation relation;
  final StudentRideGuardianVerificationStatus verificationStatus;

  final String profilePhotoUrl;
  final String cnicFrontUrl;
  final String cnicBackUrl;

  final bool canReceiveStudent;
  final bool canApprovePickup;
  final bool canViewLiveTracking;
  final bool canReceiveNotifications;
  final bool isPrimaryGuardian;
  final bool isActive;

  final List<String> authorizedStudentIds;

  final String rejectionReason;
  final String verifiedBy;
  final DateTime? verifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentRideGuardianModel({
    required this.guardianId,
    required this.parentUserId,
    required this.fullName,
    required this.phoneNumber,
    required this.cnicNumber,
    required this.relation,
    required this.verificationStatus,
    required this.profilePhotoUrl,
    required this.cnicFrontUrl,
    required this.cnicBackUrl,
    required this.canReceiveStudent,
    required this.canApprovePickup,
    required this.canViewLiveTracking,
    required this.canReceiveNotifications,
    required this.isPrimaryGuardian,
    required this.isActive,
    required this.authorizedStudentIds,
    required this.rejectionReason,
    required this.verifiedBy,
    required this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isVerified {
    return verificationStatus ==
            StudentRideGuardianVerificationStatus.verified &&
        isActive;
  }

  bool canReceive(String studentId) {
    return isVerified &&
        canReceiveStudent &&
        authorizedStudentIds.contains(studentId);
  }

  factory StudentRideGuardianModel.fromMap(
    Map<String, dynamic> map, {
    String documentId = '',
  }) {
    return StudentRideGuardianModel(
      guardianId: documentId.isNotEmpty
          ? documentId
          : map['guardianId']?.toString() ?? '',
      parentUserId: map['parentUserId']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      cnicNumber: map['cnicNumber']?.toString() ?? '',
      relation: _relationFromString(
        map['relation']?.toString(),
      ),
      verificationStatus: _verificationFromString(
        map['verificationStatus']?.toString(),
      ),
      profilePhotoUrl:
          map['profilePhotoUrl']?.toString() ?? '',
      cnicFrontUrl: map['cnicFrontUrl']?.toString() ?? '',
      cnicBackUrl: map['cnicBackUrl']?.toString() ?? '',
      canReceiveStudent: map['canReceiveStudent'] == true,
      canApprovePickup: map['canApprovePickup'] == true,
      canViewLiveTracking:
          map['canViewLiveTracking'] == true,
      canReceiveNotifications:
          map['canReceiveNotifications'] != false,
      isPrimaryGuardian: map['isPrimaryGuardian'] == true,
      isActive: map['isActive'] != false,
      authorizedStudentIds:
          _readStringList(map['authorizedStudentIds']),
      rejectionReason:
          map['rejectionReason']?.toString() ?? '',
      verifiedBy: map['verifiedBy']?.toString() ?? '',
      verifiedAt: _readDateTime(map['verifiedAt']),
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'guardianId': guardianId,
      'parentUserId': parentUserId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'cnicNumber': cnicNumber,
      'relation': relation.name,
      'verificationStatus': verificationStatus.name,
      'profilePhotoUrl': profilePhotoUrl,
      'cnicFrontUrl': cnicFrontUrl,
      'cnicBackUrl': cnicBackUrl,
      'canReceiveStudent': canReceiveStudent,
      'canApprovePickup': canApprovePickup,
      'canViewLiveTracking': canViewLiveTracking,
      'canReceiveNotifications': canReceiveNotifications,
      'isPrimaryGuardian': isPrimaryGuardian,
      'isActive': isActive,
      'authorizedStudentIds': authorizedStudentIds,
      'rejectionReason': rejectionReason,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static StudentRideGuardianRelation _relationFromString(
    String? value,
  ) {
    return StudentRideGuardianRelation.values.firstWhere(
      (item) => item.name == value,
      orElse: () => StudentRideGuardianRelation.other,
    );
  }

  static StudentRideGuardianVerificationStatus
      _verificationFromString(String? value) {
    return StudentRideGuardianVerificationStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () =>
          StudentRideGuardianVerificationStatus.pending,
    );
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
