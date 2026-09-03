import 'package:cloud_firestore/cloud_firestore.dart';

class HotelAgent {
  const HotelAgent({
    required this.id,
    required this.hotelId,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.role,
    required this.permissions,
    required this.isActive,
    required this.isApprovedByAdmin,
    required this.createdAt,
    required this.updatedAt,
    this.activatedByAdminId = '',
    this.deactivatedByAdminId = '',
    this.deactivationReason = '',
  });

  final String id;
  final String hotelId;
  final String userId;

  final String fullName;
  final String phoneNumber;
  final String email;

  // owner, manager, receptionist, bookingAgent
  final String role;

  // Examples:
  // manageBookings
  // manageRooms
  // managePrices
  // chatWithGuests
  // callGuests
  // manageCheckInOut
  final List<String> permissions;

  // Admin can turn this agent ON/OFF without an app update.
  final bool isActive;

  // Agent cannot work until approved by SWAT RIDE admin.
  final bool isApprovedByAdmin;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String activatedByAdminId;
  final String deactivatedByAdminId;
  final String deactivationReason;

  bool get canAccessHotelPanel {
    return isActive && isApprovedByAdmin;
  }

  bool hasPermission(String permission) {
    return canAccessHotelPanel &&
        permissions.contains(permission);
  }

  factory HotelAgent.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return HotelAgent(
      id: documentId,
      hotelId: _readString(map['hotelId']),
      userId: _readString(map['userId']),
      fullName: _readString(map['fullName']),
      phoneNumber: _readString(map['phoneNumber']),
      email: _readString(map['email']),
      role: _readString(
        map['role'],
        fallback: 'bookingAgent',
      ),
      permissions: _readStringList(
        map['permissions'],
      ),
      isActive: map['isActive'] == true,
      isApprovedByAdmin:
          map['isApprovedByAdmin'] == true,
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
      activatedByAdminId: _readString(
        map['activatedByAdminId'],
      ),
      deactivatedByAdminId: _readString(
        map['deactivatedByAdminId'],
      ),
      deactivationReason: _readString(
        map['deactivationReason'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hotelId': hotelId,
      'userId': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role,
      'permissions': permissions,
      'isActive': isActive,
      'isApprovedByAdmin': isApprovedByAdmin,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
      'activatedByAdminId': activatedByAdminId,
      'deactivatedByAdminId':
          deactivatedByAdminId,
      'deactivationReason':
          deactivationReason,
    };
  }

  HotelAgent copyWith({
    String? id,
    String? hotelId,
    String? userId,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? role,
    List<String>? permissions,
    bool? isActive,
    bool? isApprovedByAdmin,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? activatedByAdminId,
    String? deactivatedByAdminId,
    String? deactivationReason,
  }) {
    return HotelAgent(
      id: id ?? this.id,
      hotelId: hotelId ?? this.hotelId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phoneNumber:
          phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      permissions:
          permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      isApprovedByAdmin:
          isApprovedByAdmin ??
              this.isApprovedByAdmin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activatedByAdminId:
          activatedByAdminId ??
              this.activatedByAdminId,
      deactivatedByAdminId:
          deactivatedByAdminId ??
              this.deactivatedByAdminId,
      deactivationReason:
          deactivationReason ??
              this.deactivationReason,
    );
  }

  static String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String text = value.toString().trim();

    return text.isEmpty ? fallback : text;
  }

  static List<String> _readStringList(
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

  static DateTime? _readDateTime(
    dynamic value,
  ) {
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
