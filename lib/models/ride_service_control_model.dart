import 'package:cloud_firestore/cloud_firestore.dart';

class RideServiceControlModel {
  const RideServiceControlModel({
    required this.serviceEnabled,
    required this.maintenanceMode,
    required this.reason,
    required this.updatedBy,
    required this.updatedAt,
    this.superAdminOverride,
    this.superAdminOverrideReason = '',
    this.superAdminOverrideBy = '',
    this.superAdminOverrideAt,
  });

  final bool serviceEnabled;
  final bool maintenanceMode;
  final String reason;

  final String updatedBy;
  final DateTime? updatedAt;

  /// Reserved for Super Admin.
  ///
  /// null  = no override
  /// true  = force Normal Ride ON
  /// false = force Normal Ride OFF
  final bool? superAdminOverride;

  final String superAdminOverrideReason;
  final String superAdminOverrideBy;
  final DateTime? superAdminOverrideAt;

  bool get effectiveServiceEnabled {
    final bool? override = superAdminOverride;

    if (override != null) {
      return override;
    }

    return serviceEnabled && !maintenanceMode;
  }

  bool get isUnavailable => !effectiveServiceEnabled;

  bool get isMaintenanceActive => superAdminOverride == null && maintenanceMode;

  String get effectiveReason {
    if (superAdminOverride != null &&
        superAdminOverrideReason.trim().isNotEmpty) {
      return superAdminOverrideReason.trim();
    }

    if (reason.trim().isNotEmpty) {
      return reason.trim();
    }

    if (maintenanceMode) {
      return 'Normal Ride is temporarily under maintenance. Please try again later.';
    }

    if (!serviceEnabled) {
      return 'Normal Ride is temporarily unavailable. Please try again later.';
    }

    return '';
  }

  RideServiceControlModel copyWith({
    bool? serviceEnabled,
    bool? maintenanceMode,
    String? reason,
    String? updatedBy,
    DateTime? updatedAt,
    bool? superAdminOverride,
    bool clearSuperAdminOverride = false,
    String? superAdminOverrideReason,
    String? superAdminOverrideBy,
    DateTime? superAdminOverrideAt,
  }) {
    return RideServiceControlModel(
      serviceEnabled: serviceEnabled ?? this.serviceEnabled,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      reason: reason ?? this.reason,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      superAdminOverride: clearSuperAdminOverride
          ? null
          : superAdminOverride ?? this.superAdminOverride,
      superAdminOverrideReason:
          superAdminOverrideReason ?? this.superAdminOverrideReason,
      superAdminOverrideBy: superAdminOverrideBy ?? this.superAdminOverrideBy,
      superAdminOverrideAt: superAdminOverrideAt ?? this.superAdminOverrideAt,
    );
  }

  factory RideServiceControlModel.defaults() {
    return const RideServiceControlModel(
      serviceEnabled: true,
      maintenanceMode: false,
      reason: '',
      updatedBy: '',
      updatedAt: null,
    );
  }

  factory RideServiceControlModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return RideServiceControlModel.defaults();
    }

    return RideServiceControlModel(
      serviceEnabled: _readBool(map['serviceEnabled'], fallback: true),
      maintenanceMode: _readBool(map['maintenanceMode'], fallback: false),
      reason: _readText(map['reason']),
      updatedBy: _readText(map['updatedBy']),
      updatedAt: _readDateTime(map['updatedAt']),
      superAdminOverride: map['superAdminOverride'] is bool
          ? map['superAdminOverride'] as bool
          : null,
      superAdminOverrideReason: _readText(map['superAdminOverrideReason']),
      superAdminOverrideBy: _readText(map['superAdminOverrideBy']),
      superAdminOverrideAt: _readDateTime(map['superAdminOverrideAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'serviceEnabled': serviceEnabled,
      'maintenanceMode': maintenanceMode,
      'reason': reason.trim(),
      'updatedBy': updatedBy.trim(),
      'updatedAt': updatedAt,
      'superAdminOverride': superAdminOverride,
      'superAdminOverrideReason': superAdminOverrideReason.trim(),
      'superAdminOverrideBy': superAdminOverrideBy.trim(),
      'superAdminOverrideAt': superAdminOverrideAt,
    };
  }

  static bool _readBool(dynamic value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String normalized = value?.toString().trim().toLowerCase() ?? '';

    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }

    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }

    return fallback;
  }

  static String _readText(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }

    return null;
  }
}
