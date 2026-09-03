class HotelBooking {
  final String id;
  final String userId;
  final String hotelId;
  final String roomId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final int rooms;
  final int nights;
  final double pricePerNight;
  final double totalAmount;
  final double advanceAmount;
  final double remainingAmount;
  final String paymentStatus;
  final String bookingStatus;
  final DateTime createdAt;

  const HotelBooking({
    required this.id,
    required this.userId,
    required this.hotelId,
    required this.roomId,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.rooms,
    required this.nights,
    required this.pricePerNight,
    required this.totalAmount,
    required this.advanceAmount,
    required this.remainingAmount,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.createdAt,
  });

  factory HotelBooking.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return HotelBooking(
      id:
          documentId,
      userId:
          map['userId'] ?? '',
      hotelId:
          map['hotelId'] ?? '',
      roomId:
          map['roomId'] ?? '',
      checkIn:
          DateTime.tryParse(
                map['checkIn'] ?? '',
              ) ??
              DateTime.now(),
      checkOut:
          DateTime.tryParse(
                map['checkOut'] ?? '',
              ) ??
              DateTime.now(),
      guests:
          (map['guests'] ?? 1)
              .toInt(),
      rooms:
          (map['rooms'] ?? 1)
              .toInt(),
      nights:
          (map['nights'] ?? 1)
              .toInt(),
      pricePerNight:
          (map['pricePerNight'] ?? 0)
              .toDouble(),
      totalAmount:
          (map['totalAmount'] ?? 0)
              .toDouble(),
      advanceAmount:
          (map['advanceAmount'] ?? 0)
              .toDouble(),
      remainingAmount:
          (map['remainingAmount'] ?? 0)
              .toDouble(),
      paymentStatus:
          map['paymentStatus'] ??
              'pending',
      bookingStatus:
          map['bookingStatus'] ??
              'pending',
      createdAt:
          DateTime.tryParse(
                map['createdAt'] ?? '',
              ) ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'hotelId': hotelId,
      'roomId': roomId,
      'checkIn':
          checkIn.toIso8601String(),
      'checkOut':
          checkOut.toIso8601String(),
      'guests': guests,
      'rooms': rooms,
      'nights': nights,
      'pricePerNight':
          pricePerNight,
      'totalAmount':
          totalAmount,
      'advanceAmount':
          advanceAmount,
      'remainingAmount':
          remainingAmount,
      'paymentStatus':
          paymentStatus,
      'bookingStatus':
          bookingStatus,
      'createdAt':
          createdAt.toIso8601String(),
    };
  }
}