class LocationModel {
  final double latitude;
  final double longitude;
  final String address;
  final String placeName;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.placeName,
  });

  // =========================================================
  // COPY WITH
  // =========================================================

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? placeName,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      placeName: placeName ?? this.placeName,
    );
  }

  // =========================================================
  // FIRESTORE MAP
  // =========================================================

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'placeName': placeName,
    };
  }

  // =========================================================
  // FROM FIRESTORE
  // =========================================================

  factory LocationModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return LocationModel(
      latitude:
          (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude:
          (map['longitude'] as num?)?.toDouble() ?? 0.0,
      address:
          map['address'] as String? ?? '',
      placeName:
          map['placeName'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'LocationModel('
        'latitude: $latitude, '
        'longitude: $longitude, '
        'address: $address, '
        'placeName: $placeName'
        ')';
  }
}