class TourDestination {
  final String id;
  final String name;
  final String location;
  final String description;
  final String imageUrl;
  final String category;
  final double rating;
  final bool isFeatured;
  final bool isActive;
  final List<String> highlights;
  final List<String> bestFor;

  const TourDestination({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.isFeatured,
    required this.isActive,
    required this.highlights,
    required this.bestFor,
  });

  factory TourDestination.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return TourDestination(
      id: documentId,
      name: _readString(
        map['name'],
      ),
      location: _readString(
        map['location'],
      ),
      description: _readString(
        map['description'],
      ),
      imageUrl: _readString(
        map['imageUrl'],
      ),
      category: _readString(
        map['category'],
        fallback: 'Tourist Destination',
      ),
      rating: _readDouble(
        map['rating'],
      ),
      isFeatured:
          map['isFeatured'] == true,
      isActive:
          map['isActive'] != false,
      highlights: _readStringList(
        map['highlights'],
      ),
      bestFor: _readStringList(
        map['bestFor'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'rating': rating,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'highlights': highlights,
      'bestFor': bestFor,
    };
  }

  static String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String text =
        value.toString().trim();

    return text.isEmpty
        ? fallback
        : text;
  }

  static double _readDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  static List<String> _readStringList(
    dynamic value,
  ) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .map(
          (item) =>
              item.toString().trim(),
        )
        .where(
          (item) => item.isNotEmpty,
        )
        .toList();
  }
}