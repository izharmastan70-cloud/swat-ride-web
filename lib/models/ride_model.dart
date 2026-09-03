import 'package:cloud_firestore/cloud_firestore.dart';

import 'location_model.dart';

class RideModel {
  // =========================================================
  // BASIC IDS
  // =========================================================

  final String rideId;
  final String userId;
  final String? driverId;
  final String serviceScope;
  final String bookingSource;

  // =========================================================
  // RIDER + DRIVER DISPLAY INFORMATION
  // =========================================================

  final String? riderName;
  final String? riderPhone;
  final String? driverName;
  final String? driverVehicleType;
  final String? driverVehicleNumber;
  final String? driverPrimaryImageUrl;

  // =========================================================
  // LOCATIONS
  // =========================================================

  final LocationModel pickupLocation;
  final LocationModel destinationLocation;
  final LocationModel? driverLocation;
  final double? driverLocationAccuracy;
  final double? driverSpeed;
  final double? driverHeading;

  // =========================================================
  // VEHICLE
  // =========================================================

  final String vehicleId;
  final String vehicleName;

  // =========================================================
  // RIDE CALCULATION
  // =========================================================

  final double distanceKm;
  final int estimatedMinutes;
  final double baseFare;
  final double estimatedFare;

  // =========================================================
  // PROMO + PAYMENT + COMMISSION
  // =========================================================

  final String? promoCode;
  final double promoDiscount;
  final String paymentMethod;
  final String paymentStatus;
  final double commissionAmount;

  // =========================================================
  // STATUS + MATCHING
  // =========================================================

  final String status;
  final List<String> rejectedDriverIds;
  final DateTime? requestExpiresAt;

  // =========================================================
  // RIDE START SECURITY PIN
  // =========================================================

  final String? rideStartPin;
  final bool rideStartPinVerified;
  final int rideStartPinFailedAttempts;

  // =========================================================
  // CANCELLATION
  // =========================================================

  final String? cancelledBy;
  final String? cancellationReason;

  // =========================================================
  // LIFECYCLE TIMES
  // =========================================================

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? driverArrivingAt;
  final DateTime? driverArrivedAt;
  final DateTime? rideStartedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? driverLocationUpdatedAt;
  final DateTime? rideStartPinVerifiedAt;

  const RideModel({
    required this.rideId,
    required this.userId,
    this.driverId,
    this.serviceScope = normalRideScope,
    this.bookingSource = riderAppBookingSource,
    this.riderName,
    this.riderPhone,
    this.driverName,
    this.driverVehicleType,
    this.driverVehicleNumber,
    this.driverPrimaryImageUrl,
    required this.pickupLocation,
    required this.destinationLocation,
    this.driverLocation,
    this.driverLocationAccuracy,
    this.driverSpeed,
    this.driverHeading,
    required this.vehicleId,
    required this.vehicleName,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.baseFare,
    required this.estimatedFare,
    this.promoCode,
    this.promoDiscount = 0,
    required this.paymentMethod,
    this.paymentStatus = paymentPending,
    this.commissionAmount = 0,
    required this.status,
    this.rejectedDriverIds = const <String>[],
    this.requestExpiresAt,
    this.rideStartPin,
    this.rideStartPinVerified = false,
    this.rideStartPinFailedAttempts = 0,
    this.cancelledBy,
    this.cancellationReason,
    required this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.driverArrivingAt,
    this.driverArrivedAt,
    this.rideStartedAt,
    this.completedAt,
    this.cancelledAt,
    this.driverLocationUpdatedAt,
    this.rideStartPinVerifiedAt,
  });

  // =========================================================
  // CONVENIENCE GETTERS
  // =========================================================

  bool get hasDriver => driverId?.trim().isNotEmpty == true;

  bool get isSearching => status == searching;

  bool get isActive => activeStatuses.contains(status);

  bool get isFinished => status == completed || status == cancelled;

  bool get hasRideStartPin =>
      rideStartPin != null && rideStartPin!.length == 4;

  bool get isRequestExpired {
    final DateTime? expiry = requestExpiresAt;
    return expiry != null && DateTime.now().isAfter(expiry);
  }

  double get netDriverEarning {
    final double earning = estimatedFare - commissionAmount;
    return earning < 0 ? 0 : earning;
  }

  // =========================================================
  // COPY WITH
  // =========================================================

  RideModel copyWith({
    String? rideId,
    String? userId,
    String? driverId,
    String? serviceScope,
    String? bookingSource,
    String? riderName,
    String? riderPhone,
    String? driverName,
    String? driverVehicleType,
    String? driverVehicleNumber,
    String? driverPrimaryImageUrl,
    LocationModel? pickupLocation,
    LocationModel? destinationLocation,
    LocationModel? driverLocation,
    double? driverLocationAccuracy,
    double? driverSpeed,
    double? driverHeading,
    String? vehicleId,
    String? vehicleName,
    double? distanceKm,
    int? estimatedMinutes,
    double? baseFare,
    double? estimatedFare,
    String? promoCode,
    double? promoDiscount,
    String? paymentMethod,
    String? paymentStatus,
    double? commissionAmount,
    String? status,
    List<String>? rejectedDriverIds,
    DateTime? requestExpiresAt,
    String? rideStartPin,
    bool? rideStartPinVerified,
    int? rideStartPinFailedAttempts,
    String? cancelledBy,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? driverArrivingAt,
    DateTime? driverArrivedAt,
    DateTime? rideStartedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? driverLocationUpdatedAt,
    DateTime? rideStartPinVerifiedAt,
  }) {
    return RideModel(
      rideId: rideId ?? this.rideId,
      userId: userId ?? this.userId,
      driverId: driverId ?? this.driverId,
      serviceScope: serviceScope ?? this.serviceScope,
      bookingSource: bookingSource ?? this.bookingSource,
      riderName: riderName ?? this.riderName,
      riderPhone: riderPhone ?? this.riderPhone,
      driverName: driverName ?? this.driverName,
      driverVehicleType: driverVehicleType ?? this.driverVehicleType,
      driverVehicleNumber:
          driverVehicleNumber ?? this.driverVehicleNumber,
        driverPrimaryImageUrl:
          driverPrimaryImageUrl ?? this.driverPrimaryImageUrl,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation:
          destinationLocation ?? this.destinationLocation,
      driverLocation: driverLocation ?? this.driverLocation,
      driverLocationAccuracy:
          driverLocationAccuracy ?? this.driverLocationAccuracy,
      driverSpeed: driverSpeed ?? this.driverSpeed,
      driverHeading: driverHeading ?? this.driverHeading,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      baseFare: baseFare ?? this.baseFare,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      promoCode: promoCode ?? this.promoCode,
      promoDiscount: promoDiscount ?? this.promoDiscount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      status: status ?? this.status,
      rejectedDriverIds: rejectedDriverIds ?? this.rejectedDriverIds,
      requestExpiresAt: requestExpiresAt ?? this.requestExpiresAt,
      rideStartPin: rideStartPin ?? this.rideStartPin,
      rideStartPinVerified:
          rideStartPinVerified ?? this.rideStartPinVerified,
      rideStartPinFailedAttempts:
          rideStartPinFailedAttempts ?? this.rideStartPinFailedAttempts,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      driverArrivingAt: driverArrivingAt ?? this.driverArrivingAt,
      driverArrivedAt: driverArrivedAt ?? this.driverArrivedAt,
      rideStartedAt: rideStartedAt ?? this.rideStartedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      driverLocationUpdatedAt:
          driverLocationUpdatedAt ?? this.driverLocationUpdatedAt,
      rideStartPinVerifiedAt:
          rideStartPinVerifiedAt ?? this.rideStartPinVerifiedAt,
    );
  }

  // =========================================================
  // FIRESTORE MAP
  // =========================================================

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'rideId': rideId,
      'userId': userId,
      'driverId': driverId,
      'serviceScope': serviceScope,
      'bookingSource': bookingSource,
      'riderName': riderName,
      'riderPhone': riderPhone,
      'driverName': driverName,
      'driverVehicleType': driverVehicleType,
      'driverVehicleNumber': driverVehicleNumber,
      'driverPrimaryImageUrl': driverPrimaryImageUrl,
      'pickupLocation': pickupLocation.toMap(),
      'destinationLocation': destinationLocation.toMap(),
      'driverLocation': driverLocation?.toMap(),
      'driverLocationAccuracy': driverLocationAccuracy,
      'driverSpeed': driverSpeed,
      'driverHeading': driverHeading,
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'distanceKm': distanceKm,
      'estimatedMinutes': estimatedMinutes,
      'baseFare': baseFare,
      'estimatedFare': estimatedFare,
      'promoCode': promoCode,
      'promoDiscount': promoDiscount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'commissionAmount': commissionAmount,
      'status': status,
      'rejectedDriverIds': rejectedDriverIds,
      'requestExpiresAt': _toTimestamp(requestExpiresAt),
      'rideStartPin': rideStartPin,
      'rideStartPinVerified': rideStartPinVerified,
      'rideStartPinFailedAttempts': rideStartPinFailedAttempts,
      'cancelledBy': cancelledBy,
      'cancellationReason': cancellationReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': _toTimestamp(updatedAt),
      'acceptedAt': _toTimestamp(acceptedAt),
      'driverArrivingAt': _toTimestamp(driverArrivingAt),
      'driverArrivedAt': _toTimestamp(driverArrivedAt),
      'rideStartedAt': _toTimestamp(rideStartedAt),
      'completedAt': _toTimestamp(completedAt),
      'cancelledAt': _toTimestamp(cancelledAt),
      'driverLocationUpdatedAt': _toTimestamp(driverLocationUpdatedAt),
      'rideStartPinVerifiedAt': _toTimestamp(rideStartPinVerifiedAt),
    };
  }

  // =========================================================
  // FROM FIRESTORE
  // =========================================================

  factory RideModel.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> driverLocationMap =
        _safeMap(map['driverLocation']);

    return RideModel(
      rideId: _string(map['rideId']),
      userId: _string(map['userId']),
      driverId: _nullableString(map['driverId']),
      serviceScope: _string(map['serviceScope'], fallback: normalRideScope),
      bookingSource: _string(
        map['bookingSource'],
        fallback: riderAppBookingSource,
      ),
      riderName: _nullableString(map['riderName']),
      riderPhone: _nullableString(map['riderPhone']),
      driverName: _nullableString(map['driverName']),
      driverVehicleType: _nullableString(map['driverVehicleType']),
      driverVehicleNumber: _nullableString(map['driverVehicleNumber']),
      driverPrimaryImageUrl: _nullableString(map['driverPrimaryImageUrl']),
      pickupLocation: _parseLocation(map['pickupLocation']),
      destinationLocation: _parseLocation(map['destinationLocation']),
      driverLocation: driverLocationMap.isEmpty
          ? null
          : LocationModel.fromMap(driverLocationMap),
      driverLocationAccuracy: _nullableDouble(
        map['driverLocationAccuracy'] ?? driverLocationMap['accuracy'],
      ),
      driverSpeed:
          _nullableDouble(map['driverSpeed'] ?? driverLocationMap['speed']),
      driverHeading: _nullableDouble(
        map['driverHeading'] ?? driverLocationMap['heading'],
      ),
      vehicleId: _string(map['vehicleId']),
      vehicleName: _string(map['vehicleName']),
      distanceKm: _double(map['distanceKm']),
      estimatedMinutes: _int(map['estimatedMinutes']),
      baseFare: _double(map['baseFare']),
      estimatedFare: _double(map['estimatedFare']),
      promoCode: _nullableString(map['promoCode']),
      promoDiscount: _double(map['promoDiscount']),
      paymentMethod: _string(map['paymentMethod'], fallback: cash),
      paymentStatus:
          _string(map['paymentStatus'], fallback: paymentPending),
      commissionAmount: _double(map['commissionAmount']),
      status: _string(map['status'], fallback: searching),
      rejectedDriverIds: _stringList(map['rejectedDriverIds']),
      requestExpiresAt: _parseNullableDateTime(map['requestExpiresAt']),
      rideStartPin: _nullableString(map['rideStartPin']),
      rideStartPinVerified: _bool(map['rideStartPinVerified']),
      rideStartPinFailedAttempts: _int(map['rideStartPinFailedAttempts']),
      cancelledBy: _nullableString(map['cancelledBy']),
      cancellationReason: _nullableString(map['cancellationReason']),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseNullableDateTime(map['updatedAt']),
      acceptedAt: _parseNullableDateTime(map['acceptedAt']),
      driverArrivingAt: _parseNullableDateTime(map['driverArrivingAt']),
      driverArrivedAt: _parseNullableDateTime(map['driverArrivedAt']),
      rideStartedAt: _parseNullableDateTime(map['rideStartedAt']),
      completedAt: _parseNullableDateTime(map['completedAt']),
      cancelledAt: _parseNullableDateTime(map['cancelledAt']),
      driverLocationUpdatedAt:
          _parseNullableDateTime(map['driverLocationUpdatedAt']),
      rideStartPinVerifiedAt:
          _parseNullableDateTime(map['rideStartPinVerifiedAt']),
    );
  }

  // =========================================================
  // SAFE PARSING
  // =========================================================

  static LocationModel _parseLocation(dynamic value) {
    final Map<String, dynamic> map = _safeMap(value);
    return LocationModel.fromMap(map);
  }

  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static String _string(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final String result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final String result = value.toString().trim();
    return result.isEmpty ? null : result;
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

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }

  static List<String> _stringList(dynamic value) {
    if (value is! Iterable) return const <String>[];

    return value
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static DateTime _parseDateTime(dynamic value) {
    return _parseNullableDateTime(value) ?? DateTime.now();
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Timestamp? _toTimestamp(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }

  // =========================================================
  // STATUS CONSTANTS
  // =========================================================

  static const String searching = 'searching';
  static const String normalRideScope = 'normal_ride';
  static const String riderAppBookingSource = 'rider_app';
  static const String phoneCallBookingSource = 'agent_phone_call';
  static const String driverAssigned = 'driver_assigned';
  static const String driverArriving = 'driver_arriving';
  static const String driverArrived = 'driver_arrived';
  static const String rideStarted = 'ride_started';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const Set<String> activeStatuses = <String>{
    searching,
    driverAssigned,
    driverArriving,
    driverArrived,
    rideStarted,
  };

  // =========================================================
  // PAYMENT CONSTANTS
  // =========================================================

  static const String cash = 'cash';
  static const String wallet = 'wallet';
  static const String jazzCash = 'jazzcash';
  static const String easypaisa = 'easypaisa';
  static const String card = 'card';

  static const String paymentPending = 'pending';
  static const String paymentPaid = 'paid';
  static const String paymentFailed = 'failed';
  static const String paymentRefunded = 'refunded';
}
