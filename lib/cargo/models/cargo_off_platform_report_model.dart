import 'package:cloud_firestore/cloud_firestore.dart';

/// A Cargo customer report that a Cargo Driver requested cancellation
/// so the same delivery, pickup, or Buy For Me job could continue
/// outside SWAT RIDE.
class CargoOffPlatformReportModel {
  const CargoOffPlatformReportModel({
    required this.reportId,
    required this.cargoBookingId,
    required this.customerId,
    required this.driverId,
    required this.reason,
    required this.status,
    required this.cancellationFeeWaived,
    required this.createdAt,
    this.bookingType,
    this.customerNote,
    this.reviewedBy,
    this.reviewedAt,
    this.adminNote,
    this.adminAction,
  });

  final String reportId;
  final String cargoBookingId;
  final String customerId;
  final String driverId;

  /// Examples:
  /// cargo_delivery, pickup_my_item, buy_for_me.
  final String? bookingType;

  final String reason;
  final String? customerNote;
  final String status;
  final bool cancellationFeeWaived;
  final DateTime createdAt;

  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? adminNote;
  final String? adminAction;

  /// Driver asked customer to cancel the SWAT RIDE Cargo booking and
  /// continue the same job privately/off-platform.
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
      'cargoBookingId': cargoBookingId,
      'customerId': customerId,
      'driverId': driverId,
      'bookingType': bookingType,
      'reason': reason,
      'customerNote': customerNote,
      'status': status,
      'cancellationFeeWaived': cancellationFeeWaived,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedBy': reviewedBy,
      'reviewedAt': _timestamp(reviewedAt),
      'adminNote': adminNote,
      'adminAction': adminAction,
    };
  }

  factory CargoOffPlatformReportModel.fromMap(Map<String, dynamic> map) {
    return CargoOffPlatformReportModel(
      reportId: _text(map['reportId']),
      cargoBookingId: _text(map['cargoBookingId']),
      customerId: _text(map['customerId']),
      driverId: _text(map['driverId']),
      bookingType: _nullableText(map['bookingType']),
      reason: _text(map['reason'], driverAskedToCancel),
      customerNote: _nullableText(map['customerNote']),
      status: _text(map['status'], pending),
      cancellationFeeWaived: map['cancellationFeeWaived'] as bool? ?? true,
      createdAt: _date(map['createdAt']),
      reviewedBy: _nullableText(map['reviewedBy']),
      reviewedAt: _nullableDate(map['reviewedAt']),
      adminNote: _nullableText(map['adminNote']),
      adminAction: _nullableText(map['adminAction']),
    );
  }

  CargoOffPlatformReportModel copyWith({
    String? reportId,
    String? cargoBookingId,
    String? customerId,
    String? driverId,
    String? bookingType,
    String? reason,
    String? customerNote,
    String? status,
    bool? cancellationFeeWaived,
    DateTime? createdAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? adminNote,
    String? adminAction,
  }) {
    return CargoOffPlatformReportModel(
      reportId: reportId ?? this.reportId,
      cargoBookingId: cargoBookingId ?? this.cargoBookingId,
      customerId: customerId ?? this.customerId,
      driverId: driverId ?? this.driverId,
      bookingType: bookingType ?? this.bookingType,
      reason: reason ?? this.reason,
      customerNote: customerNote ?? this.customerNote,
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
