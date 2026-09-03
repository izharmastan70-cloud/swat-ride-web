import 'package:cloud_firestore/cloud_firestore.dart';

class CargoOperationalSettingsModel {
  const CargoOperationalSettingsModel({
    required this.cargoEnabled,
    required this.acceptingNewBookings,
    required this.driverApplicationsEnabled,
    required this.offPlatformReportingEnabled,
    required this.updatedAt,
    this.updatedBy,
  });

  /// Master Cargo ON/OFF switch.
  final bool cargoEnabled;

  /// Allow customers to create new Cargo bookings.
  final bool acceptingNewBookings;

  /// Allow new Cargo Driver applications.
  final bool driverApplicationsEnabled;

  /// Allow Cargo off-platform safety reporting.
  final bool offPlatformReportingEnabled;

  final DateTime updatedAt;
  final String? updatedBy;

  factory CargoOperationalSettingsModel.defaults() {
    return CargoOperationalSettingsModel(
      cargoEnabled: true,
      acceptingNewBookings: true,
      driverApplicationsEnabled: true,
      offPlatformReportingEnabled: true,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'cargoEnabled': cargoEnabled,
      'acceptingNewBookings': acceptingNewBookings,
      'driverApplicationsEnabled': driverApplicationsEnabled,
      'offPlatformReportingEnabled': offPlatformReportingEnabled,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }

  factory CargoOperationalSettingsModel.fromMap(Map<String, dynamic> map) {
    return CargoOperationalSettingsModel(
      cargoEnabled: map['cargoEnabled'] != false,
      acceptingNewBookings: map['acceptingNewBookings'] != false,
      driverApplicationsEnabled: map['driverApplicationsEnabled'] != false,
      offPlatformReportingEnabled: map['offPlatformReportingEnabled'] != false,
      updatedAt: _date(map['updatedAt']),
      updatedBy: _nullableText(map['updatedBy']),
    );
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }

  static String? _nullableText(dynamic value) {
    final String result = value?.toString().trim() ?? '';

    return result.isEmpty ? null : result;
  }
}
