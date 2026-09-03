import 'package:cloud_firestore/cloud_firestore.dart';

enum RideRefundStatus { pending, approved, rejected, refunded }

class RideRefundRequestModel {
  const RideRefundRequestModel({
    required this.id,
    required this.rideId,
    required this.paymentId,
    required this.userId,
    required this.originalAmount,
    required this.refundAmount,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.paymentMethod = '',
    this.providerTransactionId = '',
    this.adminNote = '',
    this.reviewedBy = '',
    this.reviewedByName = '',
    this.reviewedAt,
    this.refundedAt,
  });

  final String id;
  final String rideId;
  final String paymentId;
  final String userId;

  final double originalAmount;
  final double refundAmount;

  final String paymentMethod;
  final String providerTransactionId;
  final String reason;

  final RideRefundStatus status;

  final String adminNote;
  final String reviewedBy;
  final String reviewedByName;

  final DateTime createdAt;
  final DateTime? reviewedAt;
  final DateTime? refundedAt;

  bool get isPending => status == RideRefundStatus.pending;

  bool get isFinal =>
      status == RideRefundStatus.rejected ||
      status == RideRefundStatus.refunded;

  static RideRefundStatus statusFromValue(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';

    return RideRefundStatus.values.firstWhere(
      (item) => item.name == normalized,
      orElse: () => RideRefundStatus.pending,
    );
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }

  factory RideRefundRequestModel.fromMap(
    Map<String, dynamic> map, {
    required String documentId,
  }) {
    return RideRefundRequestModel(
      id: documentId,
      rideId: map['rideId']?.toString() ?? '',
      paymentId: map['paymentId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      originalAmount: (map['originalAmount'] as num?)?.toDouble() ?? 0,
      refundAmount: (map['refundAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['paymentMethod']?.toString() ?? '',
      providerTransactionId: map['providerTransactionId']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      status: statusFromValue(map['status']),
      adminNote: map['adminNote']?.toString() ?? '',
      reviewedBy: map['reviewedBy']?.toString() ?? '',
      reviewedByName: map['reviewedByName']?.toString() ?? '',
      createdAt: _date(map['createdAt']),
      reviewedAt: _nullableDate(map['reviewedAt']),
      refundedAt: _nullableDate(map['refundedAt']),
    );
  }
}
