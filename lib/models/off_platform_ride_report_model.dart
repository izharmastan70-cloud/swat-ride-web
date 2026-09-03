import 'package:cloud_firestore/cloud_firestore.dart';

/// A Rider-submitted report that a Driver requested cancellation so the same
/// trip could continue outside SWAT RIDE.
class OffPlatformRideReportModel {
  const OffPlatformRideReportModel({
    required this.reportId,
    required this.rideId,
    required this.riderId,
    required this.driverId,
    required this.reason,
    required this.status,
    required this.cancellationFeeWaived,
    required this.createdAt,
    this.riderNote,
    this.reviewedBy,
    this.reviewedAt,
    this.adminNote,
    this.adminAction,
  });

  final String reportId;
  final String rideId;
  final String riderId;
  final String driverId;
  final String reason;
  final String? riderNote;
  final String status;
  final bool cancellationFeeWaived;
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? adminNote;
  final String? adminAction;

  static const String driverAskedToCancel = 'driver_asked_to_cancel';

  static const String pending = 'pending';
  static const String underReview = 'under_review';
  static const String verified = 'verified';
  static const String rejected = 'rejected';

  static const String noAction = 'no_action';
  static const String warning = 'warning';
  static const String temporaryRestriction = 'temporary_restriction';
  static const String suspension = 'suspension';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'reportId': reportId,
      'rideId': rideId,
      'riderId': riderId,
      'driverId': driverId,
      'reason': reason,
      'riderNote': riderNote,
      'status': status,
      'cancellationFeeWaived': cancellationFeeWaived,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedBy': reviewedBy,
      'reviewedAt': _timestamp(reviewedAt),
      'adminNote': adminNote,
      'adminAction': adminAction,
    };
  }

  factory OffPlatformRideReportModel.fromMap(Map<String, dynamic> map) {
    return OffPlatformRideReportModel(
      reportId: _text(map['reportId']),
      rideId: _text(map['rideId']),
      riderId: _text(map['riderId']),
      driverId: _text(map['driverId']),
      reason: _text(map['reason'], driverAskedToCancel),
      riderNote: _nullableText(map['riderNote']),
      status: _text(map['status'], pending),
      cancellationFeeWaived: map['cancellationFeeWaived'] as bool? ?? true,
      createdAt: _date(map['createdAt']),
      reviewedBy: _nullableText(map['reviewedBy']),
      reviewedAt: _nullableDate(map['reviewedAt']),
      adminNote: _nullableText(map['adminNote']),
      adminAction: _nullableText(map['adminAction']),
    );
  }

  OffPlatformRideReportModel copyWith({
    String? reportId,
    String? rideId,
    String? riderId,
    String? driverId,
    String? reason,
    String? riderNote,
    String? status,
    bool? cancellationFeeWaived,
    DateTime? createdAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? adminNote,
    String? adminAction,
  }) {
    return OffPlatformRideReportModel(
      reportId: reportId ?? this.reportId,
      rideId: rideId ?? this.rideId,
      riderId: riderId ?? this.riderId,
      driverId: driverId ?? this.driverId,
      reason: reason ?? this.reason,
      riderNote: riderNote ?? this.riderNote,
      status: status ?? this.status,
      cancellationFeeWaived:
          cancellationFeeWaived ?? this.cancellationFeeWaived,
      createdAt: createdAt ?? this.createdAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      adminNote: adminNote ?? this.adminNote,
      adminAction: adminAction ?? this.adminAction,
    );
  }

  static Timestamp? _timestamp(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }

  static String _text(dynamic value, [String fallback = '']) {
    final String result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  static String? _nullableText(dynamic value) {
    final String result = value?.toString().trim() ?? '';
    return result.isEmpty ? null : result;
  }

  static DateTime _date(dynamic value) {
    return _nullableDate(value) ?? DateTime.now();
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
