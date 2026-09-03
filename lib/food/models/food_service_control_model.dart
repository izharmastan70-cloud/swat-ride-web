import 'package:cloud_firestore/cloud_firestore.dart';

class FoodServiceControlModel {
  static const String settingsCollection = 'food_admin_settings';
  static const String settingsDocument = 'general_settings';

  static const String overrideNone = 'none';
  static const String overrideForceEnabled = 'force_enabled';
  static const String overrideForceDisabled = 'force_disabled';

  const FoodServiceControlModel({
    required this.foodServiceEnabled,
    required this.acceptNewOrders,
    required this.restaurantApplicationsEnabled,
    required this.riderApplicationsEnabled,
    required this.maintenanceMode,
    required this.maintenanceReason,
    required this.superAdminOverrideMode,
    required this.updatedBy,
    required this.updatedByRole,
    required this.updatedAt,
  });

  final bool foodServiceEnabled;
  final bool acceptNewOrders;
  final bool restaurantApplicationsEnabled;
  final bool riderApplicationsEnabled;
  final bool maintenanceMode;
  final String maintenanceReason;

  /// none | force_enabled | force_disabled
  final String superAdminOverrideMode;

  final String updatedBy;
  final String updatedByRole;
  final DateTime updatedAt;

  factory FoodServiceControlModel.defaults() {
    return FoodServiceControlModel(
      foodServiceEnabled: true,
      acceptNewOrders: true,
      restaurantApplicationsEnabled: true,
      riderApplicationsEnabled: true,
      maintenanceMode: false,
      maintenanceReason: '',
      superAdminOverrideMode: overrideNone,
      updatedBy: '',
      updatedByRole: '',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  bool get hasSuperAdminForceEnable =>
      superAdminOverrideMode == overrideForceEnabled;

  bool get hasSuperAdminForceDisable =>
      superAdminOverrideMode == overrideForceDisabled;

  bool get effectiveServiceEnabled {
    if (hasSuperAdminForceEnable) {
      return true;
    }

    if (hasSuperAdminForceDisable) {
      return false;
    }

    return foodServiceEnabled;
  }

  bool get canAcceptNewOrders =>
      effectiveServiceEnabled &&
      acceptNewOrders &&
      !maintenanceMode;

  bool get canAcceptRestaurantApplications =>
      effectiveServiceEnabled &&
      restaurantApplicationsEnabled &&
      !maintenanceMode;

  bool get canAcceptRiderApplications =>
      effectiveServiceEnabled &&
      riderApplicationsEnabled &&
      !maintenanceMode;

  String get unavailableMessage {
    final String reason = maintenanceReason.trim();

    if (reason.isNotEmpty) {
      return reason;
    }

    if (maintenanceMode) {
      return 'Food service is temporarily under maintenance.';
    }

    if (!effectiveServiceEnabled) {
      return 'Food service is temporarily unavailable.';
    }

    if (!acceptNewOrders) {
      return 'Food service is not accepting new orders right now.';
    }

    return '';
  }

  FoodServiceControlModel copyWith({
    bool? foodServiceEnabled,
    bool? acceptNewOrders,
    bool? restaurantApplicationsEnabled,
    bool? riderApplicationsEnabled,
    bool? maintenanceMode,
    String? maintenanceReason,
    String? superAdminOverrideMode,
    String? updatedBy,
    String? updatedByRole,
    DateTime? updatedAt,
  }) {
    return FoodServiceControlModel(
      foodServiceEnabled:
          foodServiceEnabled ?? this.foodServiceEnabled,
      acceptNewOrders:
          acceptNewOrders ?? this.acceptNewOrders,
      restaurantApplicationsEnabled:
          restaurantApplicationsEnabled ??
          this.restaurantApplicationsEnabled,
      riderApplicationsEnabled:
          riderApplicationsEnabled ??
          this.riderApplicationsEnabled,
      maintenanceMode:
          maintenanceMode ?? this.maintenanceMode,
      maintenanceReason:
          maintenanceReason ?? this.maintenanceReason,
      superAdminOverrideMode:
          superAdminOverrideMode ?? this.superAdminOverrideMode,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedByRole: updatedByRole ?? this.updatedByRole,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      // Legacy field retained for existing Food Admin settings.
      'foodModuleEnabled': foodServiceEnabled,

      'foodServiceEnabled': foodServiceEnabled,
      'acceptNewOrders': acceptNewOrders,
      'restaurantApplicationsEnabled':
          restaurantApplicationsEnabled,
      'riderApplicationsEnabled':
          riderApplicationsEnabled,
      'maintenanceMode': maintenanceMode,
      'maintenanceReason': maintenanceReason.trim(),
      'superAdminOverrideMode': superAdminOverrideMode,
      'updatedBy': updatedBy.trim(),
      'updatedByRole': updatedByRole.trim(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory FoodServiceControlModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final FoodServiceControlModel defaults =
        FoodServiceControlModel.defaults();

    final String overrideMode =
        _validOverrideMode(map['superAdminOverrideMode']);

    return FoodServiceControlModel(
      foodServiceEnabled: _boolValue(
        map['foodServiceEnabled'] ??
            map['foodModuleEnabled'],
        defaults.foodServiceEnabled,
      ),
      acceptNewOrders: _boolValue(
        map['acceptNewOrders'],
        defaults.acceptNewOrders,
      ),
      restaurantApplicationsEnabled: _boolValue(
        map['restaurantApplicationsEnabled'],
        defaults.restaurantApplicationsEnabled,
      ),
      riderApplicationsEnabled: _boolValue(
        map['riderApplicationsEnabled'],
        defaults.riderApplicationsEnabled,
      ),
      maintenanceMode: _boolValue(
        map['maintenanceMode'],
        defaults.maintenanceMode,
      ),
      maintenanceReason:
          map['maintenanceReason']?.toString().trim() ?? '',
      superAdminOverrideMode: overrideMode,
      updatedBy: map['updatedBy']?.toString().trim() ?? '',
      updatedByRole:
          map['updatedByRole']?.toString().trim() ?? '',
      updatedAt:
          _dateValue(map['updatedAt']) ?? defaults.updatedAt,
    );
  }

  static bool _boolValue(
    dynamic value,
    bool fallback,
  ) {
    return value is bool ? value : fallback;
  }

  static String _validOverrideMode(dynamic value) {
    final String mode =
        value?.toString().trim().toLowerCase() ?? '';

    if (mode == overrideForceEnabled ||
        mode == overrideForceDisabled) {
      return mode;
    }

    return overrideNone;
  }

  static DateTime? _dateValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return null;
  }
}
