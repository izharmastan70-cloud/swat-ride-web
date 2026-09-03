// SWAT RIDE - UNIVERSAL TRUSTED CONTACT MODEL
//
// Shared trusted/emergency contact model for the complete app.
//
// Used by:
// - Ride customer / driver
// - Student Ride parent / guardian / driver
// - Food customer / delivery rider / restaurant partner
// - Cargo / Parcel customer / driver
// - Hotel guest / owner / staff
// - Tour customer / tourism driver / tour guide
//
// IMPORTANT:
// A trusted contact belongs to a USER, not to one service.
// Therefore the same contact can be used across all SWAT RIDE modules.

import 'package:cloud_firestore/cloud_firestore.dart';

class TrustedContactModel {
  const TrustedContactModel({
    required this.contactId,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.isPrimary = false,
    this.isEnabled = true,
    this.receiveSosAlerts = true,
    this.receiveLiveLocation = true,
    this.receiveServiceDetails = true,
    this.receiveSafetyUpdates = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Firestore document ID.
  final String contactId;

  /// SWAT RIDE user who owns this trusted contact.
  final String userId;

  final String name;
  final String phoneNumber;

  /// Example:
  /// Father, Mother, Brother, Sister, Friend, Guardian, Spouse.
  final String relationship;

  /// Main emergency contact.
  final bool isPrimary;

  /// Allows user to temporarily disable this contact
  /// without deleting it.
  final bool isEnabled;

  /// Contact may receive emergency SOS alerts.
  final bool receiveSosAlerts;

  /// Contact may receive/share emergency live location.
  final bool receiveLiveLocation;

  /// Contact may receive relevant ride/order/tour/hotel details.
  final bool receiveServiceDetails;

  /// Contact may receive later safety-status updates.
  final bool receiveSafetyUpdates;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get canReceiveEmergencyAlert {
    return isEnabled && receiveSosAlerts;
  }

  bool get canReceiveLocation {
    return isEnabled && receiveLiveLocation;
  }

  TrustedContactModel copyWith({
    String? contactId,
    String? userId,
    String? name,
    String? phoneNumber,
    String? relationship,
    bool? isPrimary,
    bool? isEnabled,
    bool? receiveSosAlerts,
    bool? receiveLiveLocation,
    bool? receiveServiceDetails,
    bool? receiveSafetyUpdates,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrustedContactModel(
      contactId: contactId ?? this.contactId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      isEnabled: isEnabled ?? this.isEnabled,
      receiveSosAlerts:
          receiveSosAlerts ?? this.receiveSosAlerts,
      receiveLiveLocation:
          receiveLiveLocation ?? this.receiveLiveLocation,
      receiveServiceDetails:
          receiveServiceDetails ?? this.receiveServiceDetails,
      receiveSafetyUpdates:
          receiveSafetyUpdates ?? this.receiveSafetyUpdates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'contactId': contactId,
      'userId': userId,
      'name': name.trim(),
      'phoneNumber': phoneNumber.trim(),
      'relationship': relationship.trim(),
      'isPrimary': isPrimary,
      'isEnabled': isEnabled,
      'receiveSosAlerts': receiveSosAlerts,
      'receiveLiveLocation': receiveLiveLocation,
      'receiveServiceDetails': receiveServiceDetails,
      'receiveSafetyUpdates': receiveSafetyUpdates,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory TrustedContactModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return TrustedContactModel(
      contactId:
          documentId ?? map['contactId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      relationship: map['relationship']?.toString() ?? '',
      isPrimary: _readBool(
        map['isPrimary'],
        fallback: false,
      ),
      isEnabled: _readBool(
        map['isEnabled'],
        fallback: true,
      ),
      receiveSosAlerts: _readBool(
        map['receiveSosAlerts'],
        fallback: true,
      ),
      receiveLiveLocation: _readBool(
        map['receiveLiveLocation'],
        fallback: true,
      ),
      receiveServiceDetails: _readBool(
        map['receiveServiceDetails'],
        fallback: true,
      ),
      receiveSafetyUpdates: _readBool(
        map['receiveSafetyUpdates'],
        fallback: true,
      ),
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  factory TrustedContactModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    return TrustedContactModel.fromMap(
      data,
      documentId: document.id,
    );
  }

  static bool _readBool(
    dynamic value, {
    required bool fallback,
  }) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final String normalized =
          value.trim().toLowerCase();

      if (normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes') {
        return true;
      }

      if (normalized == 'false' ||
          normalized == '0' ||
          normalized == 'no') {
        return false;
      }
    }

    return fallback;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

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