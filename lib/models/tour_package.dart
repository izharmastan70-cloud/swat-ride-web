class TourPackage {
  final String id;
  final String name;
  final String description;
  final String startLocation;
  final String duration;
  final int days;
  final int nights;
  final double pricePerPerson;
  final String vehicleType;
  final String hotelCategory;
  final List<String> destinations;
  final List<String> included;
  final List<String> excluded;
  final String imageUrl;
  final bool isFeatured;
  final bool isActive;

  const TourPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.startLocation,
    required this.duration,
    required this.days,
    required this.nights,
    required this.pricePerPerson,
    required this.vehicleType,
    required this.hotelCategory,
    required this.destinations,
    required this.included,
    required this.excluded,
    required this.imageUrl,
    required this.isFeatured,
    required this.isActive,
  });

  factory TourPackage.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return TourPackage(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      startLocation:
          map['startLocation'] ?? '',
      duration:
          map['duration'] ?? '',
      days:
          (map['days'] ?? 1).toInt(),
      nights:
          (map['nights'] ?? 0).toInt(),
      pricePerPerson:
          (map['pricePerPerson'] ?? 0)
              .toDouble(),
      vehicleType:
          map['vehicleType'] ?? '',
      hotelCategory:
          map['hotelCategory'] ?? '',
      destinations:
          List<String>.from(
        map['destinations'] ?? [],
      ),
      included:
          List<String>.from(
        map['included'] ?? [],
      ),
      excluded:
          List<String>.from(
        map['excluded'] ?? [],
      ),
      imageUrl:
          map['imageUrl'] ?? '',
      isFeatured:
          map['isFeatured'] ?? false,
      isActive:
          map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'startLocation': startLocation,
      'duration': duration,
      'days': days,
      'nights': nights,
      'pricePerPerson': pricePerPerson,
      'vehicleType': vehicleType,
      'hotelCategory': hotelCategory,
      'destinations': destinations,
      'included': included,
      'excluded': excluded,
      'imageUrl': imageUrl,
      'isFeatured': isFeatured,
      'isActive': isActive,
    };
  }
}