import 'package:cloud_firestore/cloud_firestore.dart';

class TourismDriverApplication {
  const TourismDriverApplication({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.cnic,
    required this.licenseNumber,
    required this.experienceYears,
    required this.languages,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleNumber,
    required this.seats,
    required this.luggageCapacity,
    required this.hasAirConditioning,
    required this.supportsMountainRoutes,
    required this.supportsMultiDayTours,
    required this.supportsGroupTours,
    required this.supportsFamilyTours,
    required this.supportsHotelPickup,
    required this.availableRoutes,
    required this.pricePerDay,
    required this.pricePerKm,
    required this.driverAllowancePerDay,
    required this.applicationStatus,
    required this.isCustomerAccessEnabled,
    required this.createdAt,
    required this.updatedAt,
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
  final String licenseNumber;
  final int experienceYears;
  final List<String> languages;

  final String vehicleType;
  final String vehicleModel;
  final String vehicleNumber;
  final int seats;
  final String luggageCapacity;
  final bool hasAirConditioning;

  final bool supportsMountainRoutes;
  final bool supportsMultiDayTours;
  final bool supportsGroupTours;
  final bool supportsFamilyTours;
  final bool supportsHotelPickup;

  final List<String> availableRoutes;

  final double pricePerDay;
  final double pricePerKm;
  final double driverAllowancePerDay;

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

  factory TourismDriverApplication.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return TourismDriverApplication(
      id: documentId,
      userId: _string(map['userId']),
      fullName: _string(map['fullName']),
      phoneNumber: _string(map['phoneNumber']),
      cnic: _string(map['cnic']),
      licenseNumber: _string(map['licenseNumber']),
      experienceYears: _int(map['experienceYears']),
      languages: _stringList(map['languages']),
      vehicleType: _string(map['vehicleType']),
      vehicleModel: _string(map['vehicleModel']),
      vehicleNumber: _string(map['vehicleNumber']),
      seats: _int(map['seats']),
      luggageCapacity: _string(map['luggageCapacity']),
      hasAirConditioning:
          map['hasAirConditioning'] == true,
      supportsMountainRoutes:
          map['supportsMountainRoutes'] == true,
      supportsMultiDayTours:
          map['supportsMultiDayTours'] == true,
      supportsGroupTours:
          map['supportsGroupTours'] == true,
      supportsFamilyTours:
          map['supportsFamilyTours'] == true,
      supportsHotelPickup:
          map['supportsHotelPickup'] == true,
      availableRoutes:
          _stringList(map['availableRoutes']),
      pricePerDay: _double(map['pricePerDay']),
      pricePerKm: _double(map['pricePerKm']),
      driverAllowancePerDay:
          _double(map['driverAllowancePerDay']),
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
      'licenseNumber': licenseNumber,
      'experienceYears': experienceYears,
      'languages': languages,
      'vehicleType': vehicleType,
      'vehicleModel': vehicleModel,
      'vehicleNumber': vehicleNumber,
      'seats': seats,
      'luggageCapacity': luggageCapacity,
      'hasAirConditioning': hasAirConditioning,
      'supportsMountainRoutes':
          supportsMountainRoutes,
      'supportsMultiDayTours':
          supportsMultiDayTours,
      'supportsGroupTours': supportsGroupTours,
      'supportsFamilyTours': supportsFamilyTours,
      'supportsHotelPickup': supportsHotelPickup,
      'availableRoutes': availableRoutes,
      'pricePerDay': pricePerDay,
      'pricePerKm': pricePerKm,
      'driverAllowancePerDay':
          driverAllowancePerDay,
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
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
