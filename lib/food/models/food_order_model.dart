// lib/food/models/food_order_model.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Food Order Model
// =============================================================

import 'cart_item_model.dart';
import 'delivery_address_model.dart';

enum FoodOrderStatus {
  pending,
  accepted,
  preparing,
  readyForPickup,
  pickedUp,
  onTheWay,
  delivered,
  cancelled,
}

enum FoodPaymentMethod { cash, wallet, jazzCash, easypaisa, card }

class FoodOrderModel {
  final String orderId;
  final String customerId;
  final String restaurantId;
  final String restaurantName;
  final String riderId;

  final List<CartItemModel> items;
  final DeliveryAddressModel deliveryAddress;

  final FoodOrderStatus status;
  final bool ratingPromptDismissed;
  final FoodPaymentMethod paymentMethod;

  final double itemsTotal;
  final double deliveryFee;
  final double discount;
  final double serviceFee;

  final double riderLatitude;
  final double riderLongitude;

  final String customerOtp;

  final DateTime createdAt;
  final DateTime updatedAt;

  const FoodOrderModel({
    required this.orderId,
    required this.customerId,
    required this.restaurantId,
    required this.restaurantName,
    required this.riderId,
    required this.items,
    required this.deliveryAddress,
    required this.status,
    this.ratingPromptDismissed = false,
    required this.paymentMethod,
    required this.itemsTotal,
    required this.deliveryFee,
    required this.discount,
    required this.serviceFee,
    required this.riderLatitude,
    required this.riderLongitude,
    required this.customerOtp,
    required this.createdAt,
    required this.updatedAt,
  });

  double get grandTotal => itemsTotal + deliveryFee + serviceFee - discount;

  bool get canTrackOrder =>
      status == FoodOrderStatus.pickedUp || status == FoodOrderStatus.onTheWay;

  bool get shouldShowRatingPrompt =>
      status == FoodOrderStatus.delivered && !ratingPromptDismissed;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'orderId': orderId,
      'customerId': customerId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'riderId': riderId,
      'items': items.map((CartItemModel item) => item.toMap()).toList(),
      'deliveryAddress': deliveryAddress.toMap(),
      'status': status.name,
      'ratingPromptDismissed': ratingPromptDismissed,
      'paymentMethod': paymentMethod.name,
      'itemsTotal': itemsTotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'serviceFee': serviceFee,
      'grandTotal': grandTotal,
      'riderLatitude': riderLatitude,
      'riderLongitude': riderLongitude,
      'customerOtp': customerOtp,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FoodOrderModel.fromMap(Map<String, dynamic> map) {
    final List<CartItemModel> parsedItems = _mapList(
      map['items'],
    ).map((Map<String, dynamic> item) => CartItemModel.fromMap(item)).toList();

    return FoodOrderModel(
      orderId: _stringValue(map['orderId']),
      customerId: _stringValue(map['customerId']),
      restaurantId: _stringValue(map['restaurantId']),
      restaurantName: _stringValue(map['restaurantName']),
      riderId: _stringValue(map['riderId']),
      items: List<CartItemModel>.unmodifiable(parsedItems),
      deliveryAddress: DeliveryAddressModel.fromMap(
        _mapValue(map['deliveryAddress']),
      ),
      status: _statusFromValue(map['status']),
      ratingPromptDismissed: map['ratingPromptDismissed'] == true,
      paymentMethod: _paymentMethodFromValue(map['paymentMethod']),
      itemsTotal: _doubleValue(map['itemsTotal']),
      deliveryFee: _doubleValue(map['deliveryFee']),
      discount: _doubleValue(map['discount']),
      serviceFee: _doubleValue(map['serviceFee']),
      riderLatitude: _doubleValue(map['riderLatitude']),
      riderLongitude: _doubleValue(map['riderLongitude']),
      customerOtp: _stringValue(map['customerOtp']),
      createdAt: _dateTimeValue(map['createdAt']) ?? DateTime.now(),
      updatedAt: _dateTimeValue(map['updatedAt']) ?? DateTime.now(),
    );
  }

  static String _stringValue(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static double _doubleValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic> _mapValue(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((Map item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static DateTime? _dateTimeValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    try {
      final dynamic converted = value.toDate();

      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Supports normal strings when value is not
      // a Firestore Timestamp.
    }

    return DateTime.tryParse(value.toString());
  }

  static FoodOrderStatus _statusFromValue(dynamic value) {
    final String normalized = value?.toString().trim().toLowerCase() ?? '';

    for (final FoodOrderStatus status in FoodOrderStatus.values) {
      if (status.name.toLowerCase() == normalized) {
        return status;
      }
    }

    return FoodOrderStatus.pending;
  }

  static FoodPaymentMethod _paymentMethodFromValue(dynamic value) {
    final String normalized = value?.toString().trim().toLowerCase() ?? '';

    for (final FoodPaymentMethod method in FoodPaymentMethod.values) {
      if (method.name.toLowerCase() == normalized) {
        return method;
      }
    }

    return FoodPaymentMethod.cash;
  }
}
