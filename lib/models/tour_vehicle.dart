class TourVehicle {
  final String id;
  final String name;
  final String type;
  final String description;
  final int seats;
  final double pricePerDay;
  final double pricePerKm;
  final bool fuelIncluded;
  final bool driverIncluded;
  final bool isAvailable;
  final String imageUrl;

  const TourVehicle({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.seats,
    required this.pricePerDay,
    required this.pricePerKm,
    required this.fuelIncluded,
    required this.driverIncluded,
    required this.isAvailable,
    required this.imageUrl,
  });

  factory TourVehicle.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return TourVehicle(
      id: documentId,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      description:
          map['description'] ?? '',
      seats:
          (map['seats'] ?? 4).toInt(),
      pricePerDay:
          (map['pricePerDay'] ?? 0)
              .toDouble(),
      pricePerKm:
          (map['pricePerKm'] ?? 0)
              .toDouble(),
      fuelIncluded:
          map['fuelIncluded'] ?? true,
      driverIncluded:
          map['driverIncluded'] ?? true,
      isAvailable:
          map['isAvailable'] ?? true,
      imageUrl:
          map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'seats': seats,
      'pricePerDay': pricePerDay,
      'pricePerKm': pricePerKm,
      'fuelIncluded': fuelIncluded,
      'driverIncluded': driverIncluded,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
    };
  }
}