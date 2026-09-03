import 'package:cloud_firestore/cloud_firestore.dart';

class CargoBookingModel {
  const CargoBookingModel({
    required this.bookingId,
    required this.customerId,
    required this.serviceType,
    required this.status,
    required this.createdAt,
    this.driverId,
    this.vehicleType,
    this.pickupAddress,
    this.dropAddress,
    this.shopName,
    this.shopAddress,
    this.receiverName,
    this.receiverPhone,
    this.itemNote,
    this.itemImageUrl,
    this.expectedItemAmount = 0,
    this.advancePercentage = 0,
    this.advanceAmount = 0,
    this.advancePaid = false,
    this.paymentMethod,
    this.totalFare = 0,
    this.adminCommissionPercentage = 0,
    this.commissionAmount = 0,
    this.driverNetEarning = 0,
    this.cancellationReason,
    this.cancellationFee = 0,
    this.cancellationFeeWaived = false,
    this.offPlatformReported = false,
    this.offPlatformReportId,
    this.cancelledAt,
    this.completedAt,
  });

  final String bookingId;
  final String customerId;
  final String? driverId;

  /// parcel, goods, shifting, pickup_my_item, buy_for_me
  final String serviceType;

  /// searching, driver_assigned, driver_arriving, picked_up,
  /// shopping, on_the_way, delivered, cancelled
  final String status;

  final String? vehicleType;

  final String? pickupAddress;
  final String? dropAddress;

  /// Used mainly for Pickup My Item / Buy For Me.
  final String? shopName;
  final String? shopAddress;

  final String? receiverName;
  final String? receiverPhone;

  /// User can type item list / quantity / instructions here.
  final String? itemNote;

  /// Optional item/sample image. Storage can be connected later.
  final String? itemImageUrl;

  /// Estimated purchase cost for Buy For Me.
  final double expectedItemAmount;

  /// Admin-controlled policy can later decide 50% or 100%.
  final double advancePercentage;
  final double advanceAmount;
  final bool advancePaid;

  final String? paymentMethod;

  /// Fare / commission snapshot at booking time.
  final double totalFare;
  final double adminCommissionPercentage;
  final double commissionAmount;
  final double driverNetEarning;

  final String? cancellationReason;
  final double cancellationFee;
  final bool cancellationFeeWaived;

  final bool offPlatformReported;
  final String? offPlatformReportId;

  final DateTime createdAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;

  static const String parcel = 'parcel';
  static const String goods = 'goods';
  static const String shifting = 'shifting';
  static const String pickupMyItem = 'pickup_my_item';
  static const String buyForMe = 'buy_for_me';

  static const String searching = 'searching';
  static const String driverAssigned = 'driver_assigned';
  static const String driverArriving = 'driver_arriving';
  static const String pickedUp = 'picked_up';
  static const String shopping = 'shopping';
  static const String onTheWay = 'on_the_way';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'bookingId': bookingId,
      'customerId': customerId,
      'driverId': driverId,
      'serviceType': serviceType,
      'status': status,
      'vehicleType': vehicleType,
      'pickupAddress': pickupAddress,
      'dropAddress': dropAddress,
      'shopName': shopName,
      'shopAddress': shopAddress,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'itemNote': itemNote,
      'itemImageUrl': itemImageUrl,
      'expectedItemAmount': expectedItemAmount,
      'advancePercentage': advancePercentage,
      'advanceAmount': advanceAmount,
      'advancePaid': advancePaid,
      'paymentMethod': paymentMethod,
      'totalFare': totalFare,
      'adminCommissionPercentage': adminCommissionPercentage,
      'commissionAmount': commissionAmount,
      'driverNetEarning': driverNetEarning,
      'cancellationReason': cancellationReason,
      'cancellationFee': cancellationFee,
      'cancellationFeeWaived': cancellationFeeWaived,
      'offPlatformReported': offPlatformReported,
      'offPlatformReportId': offPlatformReportId,
      'createdAt': Timestamp.fromDate(createdAt),
      'cancelledAt': _timestamp(cancelledAt),
      'completedAt': _timestamp(completedAt),
    };
  }

  factory CargoBookingModel.fromMap(Map<String, dynamic> map) {
    return CargoBookingModel(
      bookingId: _text(map['bookingId']),
      customerId: _text(map['customerId']),
      driverId: _nullableText(map['driverId']),
      serviceType: _text(map['serviceType'], parcel),
      status: _text(map['status'], searching),
      vehicleType: _nullableText(map['vehicleType']),
      pickupAddress: _nullableText(map['pickupAddress']),
      dropAddress: _nullableText(map['dropAddress']),
      shopName: _nullableText(map['shopName']),
      shopAddress: _nullableText(map['shopAddress']),
      receiverName: _nullableText(map['receiverName']),
      receiverPhone: _nullableText(map['receiverPhone']),
      itemNote: _nullableText(map['itemNote']),
      itemImageUrl: _nullableText(map['itemImageUrl']),
      expectedItemAmount: _number(map['expectedItemAmount']),
      advancePercentage: _number(map['advancePercentage']),
      advanceAmount: _number(map['advanceAmount']),
      advancePaid: map['advancePaid'] == true,
      paymentMethod: _nullableText(map['paymentMethod']),
      totalFare: _number(map['totalFare']),
      adminCommissionPercentage: _number(map['adminCommissionPercentage']),
      commissionAmount: _number(map['commissionAmount']),
      driverNetEarning: _number(map['driverNetEarning']),
      cancellationReason: _nullableText(map['cancellationReason']),
      cancellationFee: _number(map['cancellationFee']),
      cancellationFeeWaived: map['cancellationFeeWaived'] == true,
      offPlatformReported: map['offPlatformReported'] == true,
      offPlatformReportId: _nullableText(map['offPlatformReportId']),
      createdAt: _date(map['createdAt']),
      cancelledAt: _nullableDate(map['cancelledAt']),
      completedAt: _nullableDate(map['completedAt']),
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

  static double _number(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
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
