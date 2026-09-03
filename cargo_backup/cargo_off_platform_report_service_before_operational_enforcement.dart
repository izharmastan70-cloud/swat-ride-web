import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cargo_off_platform_report_model.dart';

class CargoOffPlatformReportService {
  CargoOffPlatformReportService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'cargo_off_platform_reports';

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection(collectionName);

  Future<String> submitDriverAskedToCancelReport({
    required String cargoBookingId,
    required String customerId,
    required String driverId,
    String? bookingType,
    String? customerNote,
  }) async {
    final String bookingId = cargoBookingId.trim();
    final String userId = customerId.trim();
    final String cargoDriverId = driverId.trim();

    if (bookingId.isEmpty) {
      throw ArgumentError('cargoBookingId cannot be empty.');
    }

    if (userId.isEmpty) {
      throw ArgumentError('customerId cannot be empty.');
    }

    if (cargoDriverId.isEmpty) {
      throw ArgumentError('driverId cannot be empty.');
    }

    final DocumentReference<Map<String, dynamic>> reportReference = _reports
        .doc();

    final CargoOffPlatformReportModel report = CargoOffPlatformReportModel(
      reportId: reportReference.id,
      cargoBookingId: bookingId,
      customerId: userId,
      driverId: cargoDriverId,
      bookingType: _nullableText(bookingType),
      reason: CargoOffPlatformReportModel.driverAskedToCancel,
      customerNote: _nullableText(customerNote),
      status: CargoOffPlatformReportModel.pending,
      cancellationFeeWaived: true,
      createdAt: DateTime.now(),
      adminAction: CargoOffPlatformReportModel.noAction,
    );

    await reportReference.set(report.toMap());

    return reportReference.id;
  }

  Future<CargoOffPlatformReportModel?> getReport(String reportId) async {
    final String id = reportId.trim();

    if (id.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _reports
        .doc(id)
        .get();

    final Map<String, dynamic>? data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    data['reportId'] ??= snapshot.id;

    return CargoOffPlatformReportModel.fromMap(data);
  }

  Stream<CargoOffPlatformReportModel?> watchReport(String reportId) {
    final String id = reportId.trim();

    if (id.isEmpty) {
      return Stream<CargoOffPlatformReportModel?>.value(null);
    }

    return _reports.doc(id).snapshots().map((snapshot) {
      final Map<String, dynamic>? data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return null;
      }

      data['reportId'] ??= snapshot.id;

      return CargoOffPlatformReportModel.fromMap(data);
    });
  }

  Stream<List<CargoOffPlatformReportModel>> watchCustomerReports(
    String customerId,
  ) {
    final String id = customerId.trim();

    if (id.isEmpty) {
      return Stream<List<CargoOffPlatformReportModel>>.value(
        <CargoOffPlatformReportModel>[],
      );
    }

    return _reports.where('customerId', isEqualTo: id).snapshots().map((
      snapshot,
    ) {
      final List<CargoOffPlatformReportModel> reports = snapshot.docs.map((
        doc,
      ) {
        final Map<String, dynamic> data = doc.data();

        data['reportId'] ??= doc.id;

        return CargoOffPlatformReportModel.fromMap(data);
      }).toList();

      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return reports;
    });
  }

  Stream<List<CargoOffPlatformReportModel>> watchDriverReports(
    String driverId,
  ) {
    final String id = driverId.trim();

    if (id.isEmpty) {
      return Stream<List<CargoOffPlatformReportModel>>.value(
        <CargoOffPlatformReportModel>[],
      );
    }

    return _reports.where('driverId', isEqualTo: id).snapshots().map((
      snapshot,
    ) {
      final List<CargoOffPlatformReportModel> reports = snapshot.docs.map((
        doc,
      ) {
        final Map<String, dynamic> data = doc.data();

        data['reportId'] ??= doc.id;

        return CargoOffPlatformReportModel.fromMap(data);
      }).toList();

      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return reports;
    });
  }

  Stream<List<CargoOffPlatformReportModel>> watchPendingReports() {
    return _reports
        .where('status', isEqualTo: CargoOffPlatformReportModel.pending)
        .snapshots()
        .map((snapshot) {
          final List<CargoOffPlatformReportModel> reports = snapshot.docs.map((
            doc,
          ) {
            final Map<String, dynamic> data = doc.data();

            data['reportId'] ??= doc.id;

            return CargoOffPlatformReportModel.fromMap(data);
          }).toList();

          reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return reports;
        });
  }

  Stream<List<CargoOffPlatformReportModel>> watchAllReports() {
    return _reports.snapshots().map((snapshot) {
      final List<CargoOffPlatformReportModel> reports = snapshot.docs.map((
        doc,
      ) {
        final Map<String, dynamic> data = doc.data();

        data['reportId'] ??= doc.id;

        return CargoOffPlatformReportModel.fromMap(data);
      }).toList();

      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return reports;
    });
  }

  Future<void> markUnderReview({
    required String reportId,
    String? reviewedBy,
    String? adminNote,
  }) async {
    await _updateAdminReview(
      reportId: reportId,
      status: CargoOffPlatformReportModel.underReview,
      adminAction: CargoOffPlatformReportModel.noAction,
      reviewedBy: reviewedBy,
      adminNote: adminNote,
    );
  }

  Future<void> verifyReport({
    required String reportId,
    required String adminAction,
    String? reviewedBy,
    String? adminNote,
  }) async {
    if (!_validAdminActions.contains(adminAction)) {
      throw ArgumentError(
        'Unsupported Cargo report admin action: $adminAction',
      );
    }

    await _updateAdminReview(
      reportId: reportId,
      status: CargoOffPlatformReportModel.verified,
      adminAction: adminAction,
      reviewedBy: reviewedBy,
      adminNote: adminNote,
    );
  }

  Future<void> rejectReport({
    required String reportId,
    String? reviewedBy,
    String? adminNote,
  }) async {
    await _updateAdminReview(
      reportId: reportId,
      status: CargoOffPlatformReportModel.rejected,
      adminAction: CargoOffPlatformReportModel.noAction,
      reviewedBy: reviewedBy,
      adminNote: adminNote,
    );
  }

  Future<void> _updateAdminReview({
    required String reportId,
    required String status,
    required String adminAction,
    String? reviewedBy,
    String? adminNote,
  }) async {
    final String id = reportId.trim();

    if (id.isEmpty) {
      throw ArgumentError('reportId cannot be empty.');
    }

    await _reports.doc(id).update({
      'status': status,
      'adminAction': adminAction,
      'reviewedBy': _nullableText(reviewedBy),
      'reviewedAt': Timestamp.now(),
      'adminNote': _nullableText(adminNote),
    });
  }

  static const Set<String> _validAdminActions = {
    CargoOffPlatformReportModel.noAction,
    CargoOffPlatformReportModel.warning,
    CargoOffPlatformReportModel.temporaryRestriction,
    CargoOffPlatformReportModel.suspension,
  };
  static String? _nullableText(String? value) {
    final String result = value?.trim() ?? '';

    return result.isEmpty ? null : result;
  }
}
