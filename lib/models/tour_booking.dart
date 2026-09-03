import 'package:cloud_firestore/cloud_firestore.dart';

class TourBooking {
  const TourBooking({
    required this.id,
    required this.userId,
    required this.packageId,
    required this.tourType,
    required this.startLocation,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.guests,
    required this.vehicleId,
    required this.hotelId,
    required this.totalAmount,
    required this.advanceAmount,
    required this.remainingAmount,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.driverId,
    required this.createdAt,
    this.guideId = '',
    this.hotelRoomId = '',
    this.adminId = '',
    this.partnerId = '',
    this.assignmentStatus = 'unassigned',
    this.rejectionReason = '',
    this.cancellationReason = '',
    this.specialRequest = '',
    this.pickupLatitude,
    this.pickupLongitude,
    this.isTestingMode = true,
    this.realPaymentProcessed = false,
    this.storageUploadUsed = false,
    this.updatedAt,
    this.confirmedAt,
    this.startedAt,
    this.arrivedAt,
    this.completedAt,
    this.cancelledAt,
    this.driverAssignedAt,
    this.guideAssignedAt,
    this.vehicleAssignedAt,
    this.hotelAssignedAt,
  });

  final String id;
  final String userId;
  final String packageId;
  final String tourType;
  final String startLocation;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int guests;

  final String vehicleId;
  final String hotelId;
  final String hotelRoomId;
  final String driverId;
  final String guideId;

  final String adminId;
  final String partnerId;
  final String assignmentStatus;

  final double totalAmount;
  final double advanceAmount;
  final double remainingAmount;

  final String paymentStatus;
  final String bookingStatus;

  final String rejectionReason;
  final String cancellationReason;
  final String specialRequest;

  final double? pickupLatitude;
  final double? pickupLongitude;

  final bool isTestingMode;
  final bool realPaymentProcessed;
  final bool storageUploadUsed;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? confirmedAt;
  final DateTime? startedAt;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? driverAssignedAt;
  final DateTime? guideAssignedAt;
  final DateTime? vehicleAssignedAt;
  final DateTime? hotelAssignedAt;

  bool get isPending =>
      bookingStatus == 'pending' ||
      bookingStatus == 'pending_admin_review';

  bool get isConfirmed => bookingStatus == 'confirmed';

  bool get isActive =>
      bookingStatus == 'started' ||
      bookingStatus == 'in_progress' ||
      bookingStatus == 'arrived';

  bool get isCompleted => bookingStatus == 'completed';

  bool get isCancelled =>
      bookingStatus == 'cancelled' ||
      bookingStatus == 'rejected';

  bool get hasAssignments =>
      driverId.isNotEmpty ||
      guideId.isNotEmpty ||
      vehicleId.isNotEmpty ||
      hotelId.isNotEmpty;

  factory TourBooking.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return TourBooking(
      id: documentId,
      userId: _string(map['userId']),
      packageId: _string(map['packageId']),
      tourType: _string(
        map['tourType'],
        fallback: 'private',
      ),
      startLocation: _string(
        map['startLocation'] ?? map['pickupLocation'],
      ),
      destination: _string(
        map['destination'] ?? map['destinationName'],
      ),
      startDate: _date(map['startDate']) ?? DateTime.now(),
      endDate: _date(map['endDate']) ??
          (_date(map['startDate']) ?? DateTime.now()),
      guests: _int(map['guests'], fallback: 1),
      vehicleId: _string(map['vehicleId']),
      hotelId: _string(map['hotelId']),
      hotelRoomId: _string(map['hotelRoomId']),
      driverId: _string(map['driverId']),
      guideId: _string(map['guideId']),
      adminId: _string(map['adminId']),
      partnerId: _string(map['partnerId']),
      assignmentStatus: _string(
        map['assignmentStatus'],
        fallback: 'unassigned',
      ),
      totalAmount: _double(map['totalAmount']),
      advanceAmount: _double(map['advanceAmount']),
      remainingAmount: _double(map['remainingAmount']),
      paymentStatus: _string(
        map['paymentStatus'],
        fallback: 'pending',
      ),
      bookingStatus: _string(
        map['bookingStatus'],
        fallback: 'pending',
      ),
      rejectionReason: _string(map['rejectionReason']),
      cancellationReason: _string(map['cancellationReason']),
      specialRequest: _string(map['specialRequest']),
      pickupLatitude: _nullableDouble(map['pickupLatitude']),
      pickupLongitude: _nullableDouble(map['pickupLongitude']),
      isTestingMode: map['isTestingMode'] != false,
      realPaymentProcessed:
          map['realPaymentProcessed'] == true,
      storageUploadUsed: map['storageUploadUsed'] == true,
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      updatedAt: _date(map['updatedAt']),
      confirmedAt: _date(map['confirmedAt']),
      startedAt: _date(map['startedAt']),
      arrivedAt: _date(map['arrivedAt']),
      completedAt: _date(map['completedAt']),
      cancelledAt: _date(map['cancelledAt']),
      driverAssignedAt: _date(map['driverAssignedAt']),
      guideAssignedAt: _date(map['guideAssignedAt']),
      vehicleAssignedAt: _date(map['vehicleAssignedAt']),
      hotelAssignedAt: _date(map['hotelAssignedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'packageId': packageId,
      'tourType': tourType,
      'startLocation': startLocation,
      'pickupLocation': startLocation,
      'destination': destination,
      'destinationName': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'guests': guests,
      'vehicleId': vehicleId,
      'hotelId': hotelId,
      'hotelRoomId': hotelRoomId,
      'driverId': driverId,
      'guideId': guideId,
      'adminId': adminId,
      'partnerId': partnerId,
      'assignmentStatus': assignmentStatus,
      'totalAmount': totalAmount,
      'advanceAmount': advanceAmount,
      'remainingAmount': remainingAmount,
      'paymentStatus': paymentStatus,
      'bookingStatus': bookingStatus,
      'rejectionReason': rejectionReason,
      'cancellationReason': cancellationReason,
      'specialRequest': specialRequest,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'isTestingMode': isTestingMode,
      'realPaymentProcessed': realPaymentProcessed,
      'storageUploadUsed': storageUploadUsed,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt!),
      'confirmedAt':
          confirmedAt == null ? null : Timestamp.fromDate(confirmedAt!),
      'startedAt':
          startedAt == null ? null : Timestamp.fromDate(startedAt!),
      'arrivedAt':
          arrivedAt == null ? null : Timestamp.fromDate(arrivedAt!),
      'completedAt':
          completedAt == null ? null : Timestamp.fromDate(completedAt!),
      'cancelledAt':
          cancelledAt == null ? null : Timestamp.fromDate(cancelledAt!),
      'driverAssignedAt': driverAssignedAt == null
          ? null
          : Timestamp.fromDate(driverAssignedAt!),
      'guideAssignedAt': guideAssignedAt == null
          ? null
          : Timestamp.fromDate(guideAssignedAt!),
      'vehicleAssignedAt': vehicleAssignedAt == null
          ? null
          : Timestamp.fromDate(vehicleAssignedAt!),
      'hotelAssignedAt': hotelAssignedAt == null
          ? null
          : Timestamp.fromDate(hotelAssignedAt!),
    };
  }

  TourBooking copyWith({
    String? id,
    String? userId,
    String? packageId,
    String? tourType,
    String? startLocation,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    int? guests,
    String? vehicleId,
    String? hotelId,
    String? hotelRoomId,
    String? driverId,
    String? guideId,
    String? adminId,
    String? partnerId,
    String? assignmentStatus,
    double? totalAmount,
    double? advanceAmount,
    double? remainingAmount,
    String? paymentStatus,
    String? bookingStatus,
    String? rejectionReason,
    String? cancellationReason,
    String? specialRequest,
    double? pickupLatitude,
    double? pickupLongitude,
    bool? isTestingMode,
    bool? realPaymentProcessed,
    bool? storageUploadUsed,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? confirmedAt,
    DateTime? startedAt,
    DateTime? arrivedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? driverAssignedAt,
    DateTime? guideAssignedAt,
    DateTime? vehicleAssignedAt,
    DateTime? hotelAssignedAt,
  }) {
    return TourBooking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      packageId: packageId ?? this.packageId,
      tourType: tourType ?? this.tourType,
      startLocation: startLocation ?? this.startLocation,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      guests: guests ?? this.guests,
      vehicleId: vehicleId ?? this.vehicleId,
      hotelId: hotelId ?? this.hotelId,
      hotelRoomId: hotelRoomId ?? this.hotelRoomId,
      driverId: driverId ?? this.driverId,
      guideId: guideId ?? this.guideId,
      adminId: adminId ?? this.adminId,
      partnerId: partnerId ?? this.partnerId,
      assignmentStatus:
          assignmentStatus ?? this.assignmentStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      cancellationReason:
          cancellationReason ?? this.cancellationReason,
      specialRequest: specialRequest ?? this.specialRequest,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      isTestingMode: isTestingMode ?? this.isTestingMode,
      realPaymentProcessed:
          realPaymentProcessed ?? this.realPaymentProcessed,
      storageUploadUsed:
          storageUploadUsed ?? this.storageUploadUsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      startedAt: startedAt ?? this.startedAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      driverAssignedAt:
          driverAssignedAt ?? this.driverAssignedAt,
      guideAssignedAt:
          guideAssignedAt ?? this.guideAssignedAt,
      vehicleAssignedAt:
          vehicleAssignedAt ?? this.vehicleAssignedAt,
      hotelAssignedAt:
          hotelAssignedAt ?? this.hotelAssignedAt,
    );
  }

  static String _string(
    dynamic value, {
    String fallback = '',
  }) {
    final String text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _int(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
