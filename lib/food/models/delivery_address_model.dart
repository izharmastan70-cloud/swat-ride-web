// lib/food/models/delivery_address_model.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Delivery Address Model (Foundation)
// =============================================================

enum AddressType {
  home,
  office,
  other,
}

class DeliveryAddressModel {
  final String id;
  final String userId;

  final AddressType addressType;

  final String receiverName;
  final String receiverPhone;

  final String houseNo;
  final String street;
  final String area;
  final String city;
  final String landmark;

  final double latitude;
  final double longitude;

  final bool isDefault;

  final String deliveryInstructions;

  final DateTime createdAt;
  final DateTime updatedAt;

  const DeliveryAddressModel({
    required this.id,
    required this.userId,
    required this.addressType,
    required this.receiverName,
    required this.receiverPhone,
    required this.houseNo,
    required this.street,
    required this.area,
    required this.city,
    required this.landmark,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.deliveryInstructions,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullAddress =>
      "$houseNo, $street, $area, $city";

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "addressType": addressType.name,
      "receiverName": receiverName,
      "receiverPhone": receiverPhone,
      "houseNo": houseNo,
      "street": street,
      "area": area,
      "city": city,
      "landmark": landmark,
      "latitude": latitude,
      "longitude": longitude,
      "isDefault": isDefault,
      "deliveryInstructions": deliveryInstructions,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
    };
  }

  factory DeliveryAddressModel.fromMap(
      Map<String, dynamic> map) {
    return DeliveryAddressModel(
      id: map["id"] ?? "",
      userId: map["userId"] ?? "",
      addressType: AddressType.values.firstWhere(
        (e) => e.name == map["addressType"],
        orElse: () => AddressType.home,
      ),
      receiverName: map["receiverName"] ?? "",
      receiverPhone: map["receiverPhone"] ?? "",
      houseNo: map["houseNo"] ?? "",
      street: map["street"] ?? "",
      area: map["area"] ?? "",
      city: map["city"] ?? "",
      landmark: map["landmark"] ?? "",
      latitude: (map["latitude"] ?? 0).toDouble(),
      longitude: (map["longitude"] ?? 0).toDouble(),
      isDefault: map["isDefault"] ?? false,
      deliveryInstructions:
          map["deliveryInstructions"] ?? "",
      createdAt: DateTime.tryParse(
              map["createdAt"] ?? "") ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
              map["updatedAt"] ?? "") ??
          DateTime.now(),
    );
  }
}
