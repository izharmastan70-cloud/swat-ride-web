class Hotel {
  final String id;
  final String name;
  final String location;
  final String category;
  final String description;
  final String imageUrl;
  final double rating;
  final double pricePerNight;
  final List<String> facilities;
  final bool isFeatured;
  final bool isActive;

  const Hotel({
    required this.id,
    required this.name,
    required this.location,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.pricePerNight,
    required this.facilities,
    required this.isFeatured,
    required this.isActive,
  });

  factory Hotel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return Hotel(
      id: documentId,
      name: map['name']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Standard',
      description: map['description']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      rating: _toDouble(map['rating']),
      pricePerNight: _toDouble(map['pricePerNight']),
      facilities: _toStringList(map['facilities']),
      isFeatured: map['isFeatured'] == true,
      isActive: map['isActive'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'pricePerNight': pricePerNight,
      'facilities': facilities,
      'isFeatured': isFeatured,
      'isActive': isActive,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .toList();
    }

    return <String>[];
  }
}