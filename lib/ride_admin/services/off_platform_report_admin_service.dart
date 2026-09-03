import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/off_platform_ride_report_model.dart';

class OffPlatformReportAdminService {
  OffPlatformReportAdminService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('off_platform_ride_reports');

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');

  Stream<List<OffPlatformRideReportModel>> watchReports({
    String status = OffPlatformRideReportModel.pending,
  }) {
    Query<Map<String, dynamic>> query = _reports;
    final String normalizedStatus = status.trim().toLowerCase();
    if (normalizedStatus.isNotEmpty && normalizedStatus != 'all') {
      query = query.where('status', isEqualTo: normalizedStatus);
    }

    return query.snapshots().map((snapshot) {
      final reports = snapshot.docs.map((document) {
        final data = document.data();
        data['reportId'] ??= document.id;
        return OffPlatformRideReportModel.fromMap(data);
      }).toList();
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  Future<void> markUnderReview({
    required String reportId,
    required String adminId,
  }) async {
    final String id = _required(reportId, 'Report ID');
    final String reviewerId = _required(adminId, 'Admin ID');
    await _reports.doc(id).update(<String, dynamic>{
      'status': OffPlatformRideReportModel.underReview,
      'reviewedBy': reviewerId,
      'reviewStartedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Rejects an unverified Rider allegation without penalizing the Driver.
  Future<void> rejectReport({
    required String reportId,
    required String adminId,
    required String adminNote,
  }) async {
    final String id = _required(reportId, 'Report ID');
    final String reviewerId = _required(adminId, 'Admin ID');
    final String note = _clearNote(adminNote);

    await _reports.doc(id).update(<String, dynamic>{
      'status': OffPlatformRideReportModel.rejected,
      'reviewedBy': reviewerId,
      'reviewedAt': FieldValue.serverTimestamp(),
      'adminNote': note,
      'adminAction': OffPlatformRideReportModel.noAction,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Verifies the report and applies only the action explicitly selected by
  /// the Admin. No client-side automatic suspension is performed.
  Future<void> verifyReport({
    required String reportId,
    required String adminId,
    required String adminNote,
    required String action,
    Duration restrictionDuration = const Duration(hours: 24),
  }) async {
    final String id = _required(reportId, 'Report ID');
    final String reviewerId = _required(adminId, 'Admin ID');
    final String note = _clearNote(adminNote);
    final String normalizedAction = action.trim().toLowerCase();

    const Set<String> allowedActions = <String>{
      OffPlatformRideReportModel.warning,
      OffPlatformRideReportModel.temporaryRestriction,
      OffPlatformRideReportModel.suspension,
    };
    if (!allowedActions.contains(normalizedAction)) {
      throw Exception('Please select a valid Driver action.');
    }
    if (restrictionDuration <= Duration.zero) {
      throw Exception('Restriction duration must be greater than zero.');
    }

    final DocumentReference<Map<String, dynamic>> reportReference =
        _reports.doc(id);

    await _firestore.runTransaction((transaction) async {
      final reportSnapshot = await transaction.get(reportReference);
      if (!reportSnapshot.exists) throw Exception('Report not found.');

      final Map<String, dynamic> report =
          reportSnapshot.data() ?? <String, dynamic>{};
      final String currentStatus = _text(report['status']);
      if (currentStatus == OffPlatformRideReportModel.verified ||
          currentStatus == OffPlatformRideReportModel.rejected) {
        throw Exception('This report has already been reviewed.');
      }

      final String driverId = _required(
        _text(report['driverId']),
        'Driver ID',
      );
      final DocumentReference<Map<String, dynamic>> driverReference =
          _drivers.doc(driverId);
      final driverSnapshot = await transaction.get(driverReference);
      if (!driverSnapshot.exists) throw Exception('Driver not found.');

      transaction.update(reportReference, <String, dynamic>{
        'status': OffPlatformRideReportModel.verified,
        'reviewedBy': reviewerId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'adminNote': note,
        'adminAction': normalizedAction,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final Map<String, dynamic> driverUpdate = <String, dynamic>{
        'verifiedOffPlatformReportCount': FieldValue.increment(1),
        'lastOffPlatformAction': normalizedAction,
        'lastOffPlatformActionBy': reviewerId,
        'lastOffPlatformActionAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (normalizedAction == OffPlatformRideReportModel.warning) {
        driverUpdate['offPlatformWarningCount'] = FieldValue.increment(1);
      }

      if (normalizedAction ==
          OffPlatformRideReportModel.temporaryRestriction) {
        driverUpdate.addAll(<String, dynamic>{
          'isAvailable': false,
          'rideRequestRestricted': true,
          'rideRequestRestrictedUntil': Timestamp.fromDate(
            DateTime.now().add(restrictionDuration),
          ),
          'rideRequestRestrictionReason':
              'Verified off-platform ride cancellation request',
        });
      }

      if (normalizedAction == OffPlatformRideReportModel.suspension) {
        driverUpdate.addAll(<String, dynamic>{
          'status': 'suspended',
          'isSuspended': true,
          'isOnline': false,
          'isAvailable': false,
          'suspensionReason':
              'Verified off-platform ride cancellation request',
          'statusUpdatedBy': reviewerId,
          'statusUpdatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(driverReference, driverUpdate);
    });
  }

  static String _required(String value, String label) {
    final String result = value.trim();
    if (result.isEmpty) throw Exception('$label is required.');
    return result;
  }

  static String _clearNote(String value) {
    final String result = value.trim();
    if (result.length < 5) {
      throw Exception('Please enter a clear review note.');
    }
    if (result.length > 500) {
      throw Exception('Review note cannot exceed 500 characters.');
    }
    return result;
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';
}
