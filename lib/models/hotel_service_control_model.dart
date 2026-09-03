import 'package:cloud_firestore/cloud_firestore.dart';

enum HotelServiceOverride {
  none,
  forceEnabled,
  forceDisabled,
}

class HotelServiceControlModel {
  const HotelServiceControlModel({
    required this.serviceEnabled,
    required this.acceptNewBookings,
    required this.acceptPartnerApplications,
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.updatedBy,
    required this.updatedAt,
    this.superAdminOverride = HotelServiceOverride.none,
  });

  final bool serviceEnabled;
  final bool acceptNewBookings;
  final bool acceptPartnerApplications;
  final bool maintenanceMode;
  final String maintenanceMessage;
  final String updatedBy;
  final DateTime? updatedAt;
  final HotelServiceOverride superAdminOverride;

  bool get isServiceAvailable {
    switch (superAdminOverride) {
      case HotelServiceOverride.forceEnabled:
        return true;
      case HotelServiceOverride.forceDisabled:
        return false;
      case HotelServiceOverride.none:
        return serviceEnabled && !maintenanceMode;
    }
  }

  bool get canAcceptNewBookings {
    return isServiceAvailable && acceptNewBookings;
  }

  bool get canAcceptPartnerApplications {
    return isServiceAvailable && acceptPartnerApplications;
  }

  bool get isMaintenanceActive {
    return superAdminOverride == HotelServiceOverride.none &&
        maintenanceMode;
  }

  String get customerUnavailableMessage {
    final String message = maintenanceMessage.trim();

    if (message.isNotEmpty) {
      return message;
    }

    if (isMaintenanceActive) {
      return 'Hotel service is temporarily under maintenance.';
    }

    return 'Hotel service is temporarily unavailable.';
  }

  HotelServiceControlModel copyWith({
    bool? serviceEnabled,
    bool? acceptNewBookings,
    bool? acceptPartnerApplications,
    bool? maintenanceMode,
    String? maintenanceMessage,
    String? updatedBy,
    DateTime? updatedAt,
    HotelServiceOverride? superAdminOverride,
  }) {
    return HotelServiceControlModel(
      serviceEnabled: serviceEnabled ?? this.serviceEnabled,
      acceptNewBookings:
          acceptNewBookings ?? this.acceptNewBookings,
      acceptPartnerApplications:
          acceptPartnerApplications ??
          this.acceptPartnerApplications,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      maintenanceMessage:
          maintenanceMessage ?? this.maintenanceMessage,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      superAdminOverride:
          superAdminOverride ?? this.superAdminOverride,
    );
  }

  factory HotelServiceControlModel.defaults() {
    return const HotelServiceControlModel(
      serviceEnabled: true,
      acceptNewBookings: true,
      acceptPartnerApplications: true,
      maintenanceMode: false,
      maintenanceMessage: '',
      updatedBy: '',
      updatedAt: null,
      superAdminOverride: HotelServiceOverride.none,
    );
  }

  factory HotelServiceControlModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return HotelServiceControlModel(
      serviceEnabled: _readBool(
        map['serviceEnabled'],
        fallback: true,
      ),
      acceptNewBookings: _readBool(
        map['acceptNewBookings'],
        fallback: true,
      ),
      acceptPartnerApplications: _readBool(
        map['acceptPartnerApplications'],
        fallback: true,
      ),
      maintenanceMode: _readBool(
        map['maintenanceMode'],
        fallback: false,
      ),
      maintenanceMessage: _readString(
        map['maintenanceMessage'],
      ),
      updatedBy: _readString(map['updatedBy']),
      updatedAt: _readDateTime(map['updatedAt']),
      superAdminOverride: _readOverride(
        map['superAdminOverride'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'serviceEnabled': serviceEnabled,
      'acceptNewBookings': acceptNewBookings,
      'acceptPartnerApplications': acceptPartnerApplications,
      'maintenanceMode': maintenanceMode,
      'maintenanceMessage': maintenanceMessage.trim(),
      'updatedBy': updatedBy.trim(),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
      'superAdminOverride': superAdminOverride.name,
    };
  }

  static bool _readBool(
    dynamic value, {
    required bool fallback,
  }) {
    return value is bool ? value : fallback;
  }

  static String _readString(dynamic value) {
    return value is String ? value.trim() : '';
  }

  static DateTime? _readDateTime(dynamic value) {
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

  static HotelServiceOverride _readOverride(dynamic value) {
    final String normalized = _readString(value);

    for (final HotelServiceOverride override
        in HotelServiceOverride.values) {
      if (override.name == normalized) {
        return override;
      }
    }

    return HotelServiceOverride.none;
  }
}
