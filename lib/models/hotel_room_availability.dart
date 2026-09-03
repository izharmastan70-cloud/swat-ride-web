import 'package:cloud_firestore/cloud_firestore.dart';

class HotelRoomAvailability {
  const HotelRoomAvailability({
    required this.id,
    required this.hotelId,
    required this.roomId,
    required this.startDate,
    required this.endDate,
    required this.isBlocked,
    required this.reason,
    required this.priceOverride,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String hotelId;
  final String roomId;

  // Inclusive start date.
  final DateTime startDate;

  // Exclusive checkout/end date.
  final DateTime endDate;

  // true = unavailable for new bookings
  final bool isBlocked;

  // maintenance, renovation, owner_block, holiday, seasonal
  final String reason;

  // Null means use normal room price.
  final double? priceOverride;

  final String createdByUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool overlaps({
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    return checkIn.isBefore(endDate) &&
        checkOut.isAfter(startDate);
  }

  factory HotelRoomAvailability.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return HotelRoomAvailability(
      id: documentId,
      hotelId: _readString(map['hotelId']),
      roomId: _readString(map['roomId']),
      startDate: _readDateTime(
        map['startDate'],
      ),
      endDate: _readDateTime(
        map['endDate'],
      ),
      isBlocked: map['isBlocked'] == true,
      reason: _readString(
        map['reason'],
        fallback: 'owner_block',
      ),
      priceOverride:
          _readNullableDouble(
        map['priceOverride'],
      ),
      createdByUserId:
          _readString(
        map['createdByUserId'],
      ),
      createdAt:
          _readNullableDateTime(
        map['createdAt'],
      ),
      updatedAt:
          _readNullableDateTime(
        map['updatedAt'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hotelId': hotelId,
      'roomId': roomId,
      'startDate':
          Timestamp.fromDate(startDate),
      'endDate':
          Timestamp.fromDate(endDate),
      'isBlocked': isBlocked,
      'reason': reason,
      'priceOverride': priceOverride,
      'createdByUserId':
          createdByUserId,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
    };
  }

  static String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    final String text =
        value?.toString().trim() ?? '';

    return text.isEmpty
        ? fallback
        : text;
  }

  static double? _readNullableDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  static DateTime _readDateTime(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.now();
    }

    return DateTime.now();
  }

  static DateTime? _readNullableDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return _readDateTime(value);
  }
}
