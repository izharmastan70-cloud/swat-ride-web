import 'package:cloud_firestore/cloud_firestore.dart';

class TourGuideApplication {
  const TourGuideApplication({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.cnic,
    required this.email,
    required this.experienceYears,
    required this.languages,
    required this.guideTypes,
    required this.destinations,
    required this.skills,
    required this.dailyRate,
    required this.hourlyRate,
    required this.hasFirstAidTraining,
    required this.availableForMultiDayTours,
    required this.availableForFamilyTours,
    required this.availableForGroupTours,
    required this.applicationStatus,
    required this.isCustomerAccessEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.licenseNumber = '',
    this.adminId = '',
    this.adminNote = '',
    this.rejectionReason = '',
    this.imageUrls = const <String>[],
    this.documentUrls = const <String>[],
  });

  final String id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String cnic;
  final String email;
  final String licenseNumber;
  final int experienceYears;

  final List<String> languages;
  final List<String> guideTypes;
  final List<String> destinations;
  final List<String> skills;

  final double dailyRate;
  final double hourlyRate;

  final bool hasFirstAidTraining;
  final bool availableForMultiDayTours;
  final bool availableForFamilyTours;
  final bool availableForGroupTours;

  final String applicationStatus;
  final bool isCustomerAccessEnabled;

  final String adminId;
  final String adminNote;
  final String rejectionReason;

  final List<String> imageUrls;
  final List<String> documentUrls;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isApproved =>
      applicationStatus == 'approved';

  factory TourGuideApplication.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return TourGuideApplication(
      id: documentId,
      userId: _string(map['userId']),
      fullName: _string(map['fullName']),
      phoneNumber: _string(map['phoneNumber']),
      cnic: _string(map['cnic']),
      email: _string(map['email']),
      licenseNumber: _string(map['licenseNumber']),
      experienceYears: _int(map['experienceYears']),
      languages: _stringList(map['languages']),
      guideTypes: _stringList(map['guideTypes']),
      destinations: _stringList(map['destinations']),
      skills: _stringList(map['skills']),
      dailyRate: _double(map['dailyRate']),
      hourlyRate: _double(map['hourlyRate']),
      hasFirstAidTraining:
          map['hasFirstAidTraining'] == true,
      availableForMultiDayTours:
          map['availableForMultiDayTours'] == true,
      availableForFamilyTours:
          map['availableForFamilyTours'] == true,
      availableForGroupTours:
          map['availableForGroupTours'] == true,
      applicationStatus: _string(
        map['applicationStatus'],
        fallback: 'draft',
      ),
      isCustomerAccessEnabled:
          map['isCustomerAccessEnabled'] != false,
      adminId: _string(map['adminId']),
      adminNote: _string(map['adminNote']),
      rejectionReason:
          _string(map['rejectionReason']),
      imageUrls: _stringList(map['imageUrls']),
      documentUrls:
          _stringList(map['documentUrls']),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'cnic': cnic,
      'email': email,
      'licenseNumber': licenseNumber,
      'experienceYears': experienceYears,
      'languages': languages,
      'guideTypes': guideTypes,
      'destinations': destinations,
      'skills': skills,
      'dailyRate': dailyRate,
      'hourlyRate': hourlyRate,
      'hasFirstAidTraining':
          hasFirstAidTraining,
      'availableForMultiDayTours':
          availableForMultiDayTours,
      'availableForFamilyTours':
          availableForFamilyTours,
      'availableForGroupTours':
          availableForGroupTours,
      'applicationStatus': applicationStatus,
      'isCustomerAccessEnabled':
          isCustomerAccessEnabled,
      'adminId': adminId,
      'adminNote': adminNote,
      'rejectionReason': rejectionReason,
      'imageUrls': imageUrls,
      'documentUrls': documentUrls,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }

  static String _string(
    dynamic value, {
    String fallback = '',
  }) {
    final String text =
        value?.toString().trim() ?? '';

    return text.isEmpty ? fallback : text;
  }

  static int _int(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static double _double(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static List<String> _stringList(
    dynamic value,
  ) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
