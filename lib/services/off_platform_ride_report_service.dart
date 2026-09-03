import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/off_platform_ride_report_model.dart';

class OffPlatformRideReportService {
  OffPlatformRideReportService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _rides =>
      _firestore.collection('rides');

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('off_platform_ride_reports');

  /// Reports that the assigned Driver requested an app cancellation and
  /// safely cancels the ride without charging a Rider cancellation fee.
  ///
  /// No automatic warning, strike, restriction, or suspension is issued here.
  /// Admin must review the report before any Driver action is applied.
  Future<String> reportDriverAskedToCancel({
    required String rideId,
    String? riderNote,
  }) async {
    final String normalizedRideId = rideId.trim();
    if (normalizedRideId.isEmpty) {
      throw Exception('Ride ID is required.');
    }

    final String? riderId = _auth.currentUser?.uid;
    if (riderId == null || riderId.isEmpty) {
      throw Exception('Please sign in before reporting this issue.');
    }

    final DocumentReference<Map<String, dynamic>> rideReference =
        _rides.doc(normalizedRideId);
    final DocumentReference<Map<String, dynamic>> reportReference =
        _reports.doc(normalizedRideId);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> rideSnapshot =
          await transaction.get(rideReference);
      if (!rideSnapshot.exists) throw Exception('Ride not found.');

      final Map<String, dynamic> ride =
          rideSnapshot.data() ?? <String, dynamic>{};
      final String storedRiderId = _text(ride['userId']);
      final String driverId = _text(ride['driverId']);
      final String status = _text(ride['status'], 'searching');

      if (storedRiderId != riderId) {
        throw Exception('You are not allowed to report this ride.');
      }
      if (driverId.isEmpty) {
        throw Exception('No Driver is assigned to this ride.');
      }
      if (status == 'ride_started') {
        throw Exception(
          'A started ride cannot be cancelled here. Use Safety or Support.',
        );
      }
      if (status == 'completed') {
        throw Exception('A completed ride cannot be cancelled.');
      }

      final DocumentSnapshot<Map<String, dynamic>> existingReport =
          await transaction.get(reportReference);
      if (existingReport.exists) {
        throw Exception('This issue has already been reported.');
      }

      transaction.set(reportReference, <String, dynamic>{
        'reportId': normalizedRideId,
        'rideId': normalizedRideId,
        'riderId': riderId,
        'driverId': driverId,
        'reason': OffPlatformRideReportModel.driverAskedToCancel,
        'riderNote': _nullableText(riderNote),
        'status': OffPlatformRideReportModel.pending,
        'cancellationFeeWaived': true,
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedBy': null,
        'reviewedAt': null,
        'adminNote': null,
        'adminAction': null,
      });

      transaction.update(rideReference, <String, dynamic>{
        'status': 'cancelled',
        'cancelledBy': 'rider',
        'cancellationReason':
            OffPlatformRideReportModel.driverAskedToCancel,
        'cancellationFee': 0,
        'cancellationFeeWaived': true,
        'offPlatformReportId': normalizedRideId,
        'offPlatformReported': true,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Driver strikes/counters are intentionally not written by the Rider.
      // A trusted Admin review applies verified actions later. This prevents
      // one unverified report from automatically penalizing a Driver.
    });

    return reportReference.id;
  }

  Stream<List<OffPlatformRideReportModel>> watchReports({
    String status = OffPlatformRideReportModel.pending,
  }) {
    Query<Map<String, dynamic>> query = _reports;
    final String normalizedStatus = status.trim().toLowerCase();
    if (normalizedStatus.isNotEmpty && normalizedStatus != 'all') {
      query = query.where('status', isEqualTo: normalizedStatus);
    }

    return query.snapshots().map((snapshot) {
      final List<OffPlatformRideReportModel> reports = snapshot.docs.map((doc) {
        final Map<String, dynamic> data = doc.data();
        data['reportId'] ??= doc.id;
        return OffPlatformRideReportModel.fromMap(data);
      }).toList();
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    });
  }

  Stream<OffPlatformRideReportModel?> watchReport(String reportId) {
    final String id = reportId.trim();
    if (id.isEmpty) return Stream.value(null);

    return _reports.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final Map<String, dynamic> data = snapshot.data()!;
      data['reportId'] ??= snapshot.id;
      return OffPlatformRideReportModel.fromMap(data);
    });
  }

  static String _text(dynamic value, [String fallback = '']) {
    final String result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  static String? _nullableText(String? value) {
    final String result = value?.trim() ?? '';
    return result.isEmpty ? null : result;
  }
}
