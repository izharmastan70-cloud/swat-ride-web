import 'package:cloud_firestore/cloud_firestore.dart';

class DriverApplicationModel {
  final String applicationId;
  final String fullName;
  final String phoneNumber;
  final String cnicNumber;
  final String vehicleType;
  final String vehicleNumber;
  final String chassisNumber;
  final String vehicleOwnerId;
  final String authorizedDriverId;
  final String address;
  final String status;

  final Map<String, dynamic> documents;

  final Map<String, dynamic> adminReview;

  final Map<String, dynamic> driverAccount;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DriverApplicationModel({
    required this.applicationId,
    required this.fullName,
    required this.phoneNumber,
    required this.cnicNumber,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.chassisNumber,
    required this.vehicleOwnerId,
    required this.authorizedDriverId,
    required this.address,
    required this.status,
    required this.documents,
    required this.adminReview,
    required this.driverAccount,
    this.createdAt,
    this.updatedAt,
  });

  // =========================================================
  // FIRESTORE → MODEL
  // =========================================================

  factory DriverApplicationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return DriverApplicationModel(
      applicationId:
          data['applicationId'] ??
          snapshot.id,

      fullName:
          data['fullName'] ??
          '',

      phoneNumber:
          data['phoneNumber'] ??
          '',

      cnicNumber:
          data['cnicNumber'] ??
          '',

      vehicleType:
          data['vehicleType'] ??
          '',

      vehicleNumber:
          data['vehicleNumber'] ??
          '',

        chassisNumber:
          data['chassisNumber'] ??
          '',

        vehicleOwnerId:
          data['vehicleOwnerId'] ??
          data['userId'] ??
          '',

        authorizedDriverId:
          data['authorizedDriverId'] ??
          data['userId'] ??
          '',

      address:
          data['address'] ??
          '',

      status:
          data['status'] ??
          'pending',

      documents:
          Map<String, dynamic>.from(
        data['documents'] ?? {},
      ),

      adminReview:
          Map<String, dynamic>.from(
        data['adminReview'] ?? {},
      ),

      driverAccount:
          Map<String, dynamic>.from(
        data['driverAccount'] ?? {},
      ),

      createdAt:
          _parseTimestamp(
        data['createdAt'],
      ),

      updatedAt:
          _parseTimestamp(
        data['updatedAt'],
      ),
    );
  }

  // =========================================================
  // MODEL → FIRESTORE
  // =========================================================

  Map<String, dynamic> toFirestore() {
    return {
      'applicationId':
          applicationId,

      'applicationType':
          'driver_registration',

      'fullName':
          fullName,

      'phoneNumber':
          phoneNumber,

      'cnicNumber':
          cnicNumber,

      'vehicleType':
          vehicleType,

      'vehicleNumber':
          vehicleNumber,

        'chassisNumber':
          chassisNumber,

        'vehicleOwnerId':
          vehicleOwnerId,

        'authorizedDriverId':
          authorizedDriverId,

      'address':
          address,

      'status':
          status,

      'documents':
          documents,

      'adminReview':
          adminReview,

      'driverAccount':
          driverAccount,

      'createdAt':
          createdAt != null
              ? Timestamp.fromDate(
                  createdAt!,
                )
              : FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),
    };
  }

  // =========================================================
  // TIMESTAMP PARSER
  // =========================================================

  static DateTime? _parseTimestamp(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}