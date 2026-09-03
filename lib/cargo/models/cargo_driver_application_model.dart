import 'package:cloud_firestore/cloud_firestore.dart';

class CargoDriverApplicationModel {
  const CargoDriverApplicationModel({
    required this.applicationId,
    required this.userId,
    this.serviceScope = cargoScope,
    required this.fullName,
    required this.phone,
    required this.cnicNumber,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.address,
    required this.status,
    required this.createdAt,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    this.licenseFrontUrl,
    this.licenseBackUrl,
    this.vehicleRegistrationUrl,
    this.vehiclePhotoUrl,
    this.driverPhotoUrl,
    this.reviewedBy,
    this.reviewedAt,
    this.adminNote,
    this.commissionPercentage = 0,
    this.outstandingCommission = 0,
    this.totalCommissionPaid = 0,
  });

  final String applicationId;
  final String userId;
  final String serviceScope;

  final String fullName;
  final String phone;
  final String cnicNumber;

  final String vehicleType;
  final String vehicleNumber;
  final String address;

  final String status;

  final String? cnicFrontUrl;
  final String? cnicBackUrl;
  final String? licenseFrontUrl;
  final String? licenseBackUrl;
  final String? vehicleRegistrationUrl;
  final String? vehiclePhotoUrl;
  final String? driverPhotoUrl;

  final DateTime createdAt;

  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? adminNote;

  /// Driver-specific Cargo commission percentage.
  /// 0 means use the global Cargo commission setting.
  final double commissionPercentage;

  /// Cash-booking commission still owed by this driver.
  final double outstandingCommission;

  /// Total commission already settled/paid by this driver.
  final double totalCommissionPaid;

  static const String pending = 'pending';
  static const String cargoScope = 'cargo';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String suspended = 'suspended';

  static const String bike = 'bike';
  static const String rickshaw = 'rickshaw';
  static const String loaderRickshaw = 'loader_rickshaw';
  static const String qingqiLoader = 'qingqi_loader';
  static const String suzukiPickup = 'suzuki_pickup';
  static const String shehzore = 'shehzore';
  static const String miniTruck = 'mini_truck';
  static const String mediumTruck = 'medium_truck';
  static const String largeTruck = 'large_truck';
  static const String dumper = 'dumper';
  static const String tractorTrolley = 'tractor_trolley';

  static const List<String> supportedVehicleTypes = <String>[
    bike,
    rickshaw,
    loaderRickshaw,
    qingqiLoader,
    suzukiPickup,
    shehzore,
    miniTruck,
    mediumTruck,
    largeTruck,
    dumper,
    tractorTrolley,
  ];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'applicationId': applicationId,
      'userId': userId,
      'serviceScope': serviceScope,
      'fullName': fullName,
      'phone': phone,
      'cnicNumber': cnicNumber,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'address': address,
      'status': status,
      'documents': <String, dynamic>{
        'cnicFront': cnicFrontUrl,
        'cnicBack': cnicBackUrl,
        'licenseFront': licenseFrontUrl,
        'licenseBack': licenseBackUrl,
        'vehicleRegistration': vehicleRegistrationUrl,
        'vehiclePhoto': vehiclePhotoUrl,
        'driverPhoto': driverPhotoUrl,
      },
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedBy': reviewedBy,
      'reviewedAt': _timestamp(reviewedAt),
      'adminNote': adminNote,
      'commissionPercentage': commissionPercentage,
      'outstandingCommission': outstandingCommission,
      'totalCommissionPaid': totalCommissionPaid,
    };
  }

  factory CargoDriverApplicationModel.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> documents = map['documents'] is Map
        ? Map<String, dynamic>.from(map['documents'] as Map)
        : <String, dynamic>{};

    return CargoDriverApplicationModel(
      applicationId: _text(map['applicationId']),
      userId: _text(map['userId']),
      serviceScope: _text(map['serviceScope'], cargoScope),
      fullName: _text(map['fullName']),
      phone: _text(map['phone']),
      cnicNumber: _text(map['cnicNumber']),
      vehicleType: _text(map['vehicleType'], bike),
      vehicleNumber: _text(map['vehicleNumber']),
      address: _text(map['address']),
      status: _text(map['status'], pending),
      cnicFrontUrl: _nullableText(documents['cnicFront']),
      cnicBackUrl: _nullableText(documents['cnicBack']),
      licenseFrontUrl: _nullableText(documents['licenseFront']),
      licenseBackUrl: _nullableText(documents['licenseBack']),
      vehicleRegistrationUrl: _nullableText(documents['vehicleRegistration']),
      vehiclePhotoUrl: _nullableText(documents['vehiclePhoto']),
      driverPhotoUrl: _nullableText(documents['driverPhoto']),
      createdAt: _date(map['createdAt']),
      reviewedBy: _nullableText(map['reviewedBy']),
      reviewedAt: _nullableDate(map['reviewedAt']),
      adminNote: _nullableText(map['adminNote']),
      commissionPercentage: _number(map['commissionPercentage']),
      outstandingCommission: _number(map['outstandingCommission']),
      totalCommissionPaid: _number(map['totalCommissionPaid']),
    );
  }

  static Timestamp? _timestamp(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }

  static String _text(dynamic value, [String fallback = '']) {
    final String result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  static String? _nullableText(dynamic value) {
    final String result = value?.toString().trim() ?? '';
    return result.isEmpty ? null : result;
  }

  static double _number(dynamic value) {
    if (value is num) {
      final double number = value.toDouble();
      return number.isFinite && number >= 0 ? number : 0;
    }

    if (value is String) {
      final double? number = double.tryParse(value);

      if (number != null && number.isFinite && number >= 0) {
        return number;
      }
    }

    return 0;
  }

  static DateTime _date(dynamic value) {
    return _nullableDate(value) ?? DateTime.now();
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
