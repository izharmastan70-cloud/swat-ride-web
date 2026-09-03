class VehicleModel {
  final String id;
  final String name;
  final String image;
  final String category;
  final double baseFare;
  final double perKm;
  final String capacity;
  final String description;

  const VehicleModel({
    required this.id,
    required this.name,
    required this.image,
    required this.category,
    required this.baseFare,
    required this.perKm,
    required this.capacity,
    required this.description,
  });
}