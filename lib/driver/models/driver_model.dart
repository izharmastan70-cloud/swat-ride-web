import 'package:cloud_firestore/cloud_firestore.dart';

class DriverModel {
  final String driverId;
  final String fullName;
  final String phoneNumber;
  final String vehicleType;
  final String vehicleNumber;
  final bool isOnline;
  final bool isAvailable;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DriverModel({
    required this.driverId,
    required this.fullName,
    required this.phoneNumber,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.isOnline,
    required this.isAvailable,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory DriverModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return DriverModel(
      driverId: snapshot.id,
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      vehicleType: data['vehicleType'] ?? '',
      vehicleNumber: data['vehicleNumber'] ?? '',
      isOnline: data['isOnline'] ?? false,
      isAvailable: data['isAvailable'] ?? false,
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'isOnline': isOnline,
      'isAvailable': isAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}