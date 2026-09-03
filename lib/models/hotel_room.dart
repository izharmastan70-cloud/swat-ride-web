class HotelRoom {
  final String id;
  final String hotelId;
  final String name;
  final String description;
  final String roomType;
  final int maxGuests;
  final int beds;
  final double pricePerNight;
  final List<String> facilities;
  final String imageUrl;
  final bool isAvailable;

  const HotelRoom({
    required this.id,
    required this.hotelId,
    required this.name,
    required this.description,
    required this.roomType,
    required this.maxGuests,
    required this.beds,
    required this.pricePerNight,
    required this.facilities,
    required this.imageUrl,
    required this.isAvailable,
  });

  factory HotelRoom.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    int readInt(
      dynamic value, {
      int fallback = 0,
    }) {
      if (value is num) {
        return value.toInt();
      }

      return int.tryParse(
            value?.toString() ?? '',
          ) ??
          fallback;
    }

    double readDouble(
      dynamic value, {
      double fallback = 0,
    }) {
      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(
            value?.toString() ?? '',
          ) ??
          fallback;
    }

    final int adults = readInt(
      map['adults'],
      fallback: 0,
    );

    final int children = readInt(
      map['children'],
      fallback: 0,
    );

    final int capacity = readInt(
      map['capacity'],
      fallback: adults + children,
    );

    final int maxGuests = readInt(
      map['maxGuests'],
      fallback: capacity > 0
          ? capacity
          : (adults + children > 0
              ? adults + children
              : 2),
    );

    final int availableQuantity = readInt(
      map['availableQuantity'] ?? map['quantity'],
      fallback: 1,
    );

    final String manualStatus =
        map['manualStatus']?.toString().trim().toLowerCase() ?? '';

    final bool operationallyBlocked =
        manualStatus == 'blocked' ||
            manualStatus == 'maintenance' ||
            manualStatus == 'housekeeping';

    final bool active =
        map['isActive'] != false &&
            map['isDeleted'] != true;

    final bool compatibilityAvailable =
        active &&
            !operationallyBlocked &&
            availableQuantity > 0;

    final bool isAvailable =
        map['isAvailable'] is bool
            ? map['isAvailable'] == true &&
                compatibilityAvailable
            : compatibilityAvailable;

    final String resolvedName =
        map['name']?.toString().trim().isNotEmpty == true
            ? map['name'].toString().trim()
            : map['roomName']?.toString().trim().isNotEmpty == true
                ? map['roomName'].toString().trim()
                : map['roomType']?.toString().trim().isNotEmpty == true
                    ? map['roomType'].toString().trim()
                    : 'Room';

    final String resolvedRoomType =
        map['roomType']?.toString().trim().isNotEmpty == true
            ? map['roomType'].toString().trim()
            : map['roomName']?.toString().trim().isNotEmpty == true
                ? map['roomName'].toString().trim()
                : resolvedName;

    final List<String> facilities =
        ((map['facilities'] ?? map['amenities']) is List)
            ? List<String>.from(
                (map['facilities'] ?? map['amenities'])
                    .map((dynamic value) => value.toString()),
              )
            : <String>[];

    return HotelRoom(
      id: id,
      hotelId: map['hotelId']?.toString() ?? '',
      name: resolvedName,
      description:
          map['description']?.toString() ?? '',
      roomType: resolvedRoomType,
      maxGuests: maxGuests,
      beds: readInt(
        map['beds'],
        fallback: 1,
      ),
      pricePerNight: readDouble(
        map['pricePerNight'] ??
            map['roomPrice'] ??
            map['price'],
      ),
      facilities: facilities,
      imageUrl:
          map['imageUrl']?.toString() ??
              (((map['images'] is List) &&
                      (map['images'] as List).isNotEmpty)
                  ? (map['images'] as List)
                      .first
                      .toString()
                  : ''),
      isAvailable: isAvailable,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'hotelId': hotelId,
      'name': name,
      'description': description,
      'roomType': roomType,
      'maxGuests': maxGuests,
      'beds': beds,
      'pricePerNight': pricePerNight,
      'facilities': facilities,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }
}