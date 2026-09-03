import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/hotel_recommendation.dart';

class HotelRecommendationService {
  HotelRecommendationService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String engineVersion =
      'hotel_recommendation_v1';

  Future<HotelRecommendationResponse>
      recommendHotels({
    required HotelRecommendationRequest request,
    int limit = 10,
  }) async {
    _validateRequest(request);

    final List<Map<String, dynamic>> hotels =
        await _loadHotels();

    final Set<String> favoriteHotelIds =
        await _loadFavoriteHotelIds(
      request.userId,
    );

    final List<HotelRecommendationResult> results =
        <HotelRecommendationResult>[];

    for (final Map<String, dynamic> hotel
        in hotels) {
      final HotelRecommendationResult? result =
          await _scoreHotel(
        hotel: hotel,
        request: request,
        favoriteHotelIds:
            favoriteHotelIds,
      );

      if (result != null) {
        results.add(result);
      }
    }

    results.sort(
      (
        HotelRecommendationResult a,
        HotelRecommendationResult b,
      ) {
        final int scoreCompare =
            b.matchPercentage.compareTo(
          a.matchPercentage,
        );

        if (scoreCompare != 0) {
          return scoreCompare;
        }

        final int availabilityCompare =
            b.availableRooms.compareTo(
          a.availableRooms,
        );

        if (availabilityCompare != 0) {
          return availabilityCompare;
        }

        return b.rating.compareTo(
          a.rating,
        );
      },
    );

    final List<HotelRecommendationResult>
        ranked = <HotelRecommendationResult>[];

    for (int index = 0;
        index < results.length &&
            index < limit;
        index++) {
      ranked.add(
        results[index].copyWith(
          rank: index + 1,
        ),
      );
    }

    return HotelRecommendationResponse(
      request: request,
      results: ranked,
      generatedAt: DateTime.now(),
      engineVersion: engineVersion,
      aiSummary: '',
      aiAgentUsed: false,
      testingMode: true,
    );
  }

  Future<List<Map<String, dynamic>>>
      _loadHotels() async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection('hotels')
            .get();

    return snapshot.docs
        .map(
          (
            QueryDocumentSnapshot<
                    Map<String, dynamic>>
                document,
          ) =>
              <String, dynamic>{
            ...document.data(),
            'id': document.id,
          },
        )
        .where(
          (Map<String, dynamic> hotel) =>
              hotel['isActive'] != false &&
              hotel['isDeleted'] != true,
        )
        .toList();
  }

  Future<Set<String>>
      _loadFavoriteHotelIds(
    String userId,
  ) async {
    if (userId.trim().isEmpty) {
      return <String>{};
    }

    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection('hotel_favorites')
            .where(
              'userId',
              isEqualTo: userId,
            )
            .get();

    return snapshot.docs
        .map(
          (
            QueryDocumentSnapshot<
                    Map<String, dynamic>>
                document,
          ) =>
              document.data()['hotelId']
                  ?.toString(),
        )
        .whereType<String>()
        .where(
          (String value) =>
              value.trim().isNotEmpty,
        )
        .toSet();
  }

  Future<HotelRecommendationResult?>
      _scoreHotel({
    required Map<String, dynamic> hotel,
    required HotelRecommendationRequest
        request,
    required Set<String>
        favoriteHotelIds,
  }) async {
    final String hotelId =
        hotel['id']?.toString() ??
            hotel['hotelId']?.toString() ??
            '';

    if (hotelId.isEmpty ||
        request.excludeHotelIds.contains(
          hotelId,
        )) {
      return null;
    }

    final String hotelName =
        hotel['hotelName']?.toString() ??
            hotel['name']?.toString() ??
            'Hotel';

    final String location =
        hotel['location']?.toString() ??
            hotel['address']?.toString() ??
            '';

    final String category =
        hotel['category']?.toString() ??
            'Standard';

    final double pricePerNight =
        _readDouble(
      hotel['startingPrice'] ??
          hotel['pricePerNight'] ??
          hotel['price'],
    );

    final double rating =
        _readDouble(
      hotel['averageRating'] ??
          hotel['rating'],
    );

    final int reviewCount =
        _readInt(
      hotel['reviewCount'],
    );

    final List<String> amenities =
        _readStringList(
      hotel['amenities'],
    );

    final bool isFavorite =
        favoriteHotelIds.contains(
          hotelId,
        ) ||
        request.preferredHotelIds.contains(
          hotelId,
        );

    final bool isAdminEnabled =
        hotel['isActive'] != false &&
        hotel['isDeleted'] != true;

    final int availableRooms =
        await _calculateAvailableRooms(
      hotelId: hotelId,
      request: request,
    );

    final bool isAvailable =
        availableRooms >= request.rooms;

    double score = 0;
    final List<String> matchedReasons =
        <String>[];
    final List<String> missingRequirements =
        <String>[];

    // Budget: 30 points.
    if (pricePerNight > 0 &&
        request.maxBudgetPerNight > 0) {
      if (pricePerNight <=
          request.maxBudgetPerNight) {
        score += 30;
        matchedReasons.add(
          'Within budget',
        );
      } else {
        final double ratio =
            request.maxBudgetPerNight /
                pricePerNight;

        final double partial =
            (30 * ratio).clamp(
          0,
          20,
        );

        score += partial;
        missingRequirements.add(
          'Above nightly budget by PKR ${_money(pricePerNight - request.maxBudgetPerNight)}',
        );
      }
    }

    // Location: 20 points.
    final String destination =
        request.destination
            .trim()
            .toLowerCase();

    if (destination.isEmpty) {
      score += 10;
    } else {
      final String normalizedLocation =
          location.toLowerCase();

      if (normalizedLocation.contains(
            destination,
          ) ||
          destination.contains(
            normalizedLocation,
          )) {
        score += 20;
        matchedReasons.add(
          'Matches destination',
        );
      } else {
        final List<String> hotelWords =
            normalizedLocation
                .split(
                  RegExp(r'[\s,]+'),
                )
                .where(
                  (String value) =>
                      value.length > 2,
                )
                .toList();

        final bool partialLocation =
            hotelWords.any(
          (String word) =>
              destination.contains(word),
        );

        if (partialLocation) {
          score += 10;
          matchedReasons.add(
            'Near preferred area',
          );
        } else {
          missingRequirements.add(
            'Different location',
          );
        }
      }
    }

    // Availability: 20 points.
    if (isAvailable) {
      score += 20;
      matchedReasons.add(
        '$availableRooms room(s) available',
      );
    } else if (availableRooms > 0) {
      score += 8;
      missingRequirements.add(
        'Only $availableRooms room(s) available',
      );
    } else {
      missingRequirements.add(
        'No room available for selected dates',
      );
    }

    // Amenities: 15 points.
    final List<String> requiredAmenities =
        _buildRequiredAmenities(
      request,
    );

    if (requiredAmenities.isEmpty) {
      score += 7.5;
    } else {
      int matchedAmenityCount = 0;

      for (final String required
          in requiredAmenities) {
        final bool matched =
            amenities.any(
          (String amenity) =>
              amenity
                  .toLowerCase()
                  .contains(
                    required.toLowerCase(),
                  ),
        );

        if (matched) {
          matchedAmenityCount++;
          matchedReasons.add(
            'Has $required',
          );
        } else {
          missingRequirements.add(
            'Missing $required',
          );
        }
      }

      score +=
          15 *
          (matchedAmenityCount /
              requiredAmenities.length);
    }

    // Rating: 10 points.
    if (rating > 0) {
      final double ratingScore =
          (rating / 5).clamp(
        0,
        1,
      ) *
              8;

      score += ratingScore;

      if (rating >= 4) {
        matchedReasons.add(
          'Strong guest rating',
        );
      }
    }

    if (reviewCount > 0) {
      final double reviewBonus =
          (reviewCount / 100)
              .clamp(
                0,
                1,
              ) *
              2;

      score += reviewBonus;
    }

    // Favorite/history: 5 points.
    if (isFavorite) {
      score += 5;
      matchedReasons.add(
        'Previously favored hotel',
      );
    }

    // Category preference bonus.
    if (request.preferredCategories
        .map(
          (String value) =>
              value.toLowerCase(),
        )
        .contains(
          category.toLowerCase(),
        )) {
      score += 3;
      matchedReasons.add(
        'Matches preferred category',
      );
    }

    // Trip-type adjustment.
    score += _tripTypeScore(
      request: request,
      category: category,
      amenities: amenities,
      matchedReasons:
          matchedReasons,
    );

    // Capacity safety check.
    final int roomCapacity =
        await _calculateTotalCapacity(
      hotelId,
    );

    if (roomCapacity > 0 &&
        roomCapacity <
            request.totalGuests) {
      missingRequirements.add(
        'Guest capacity may be insufficient',
      );
      score -= 8;
    }

    if (!isAdminEnabled) {
      score = 0;
      missingRequirements.add(
        'Hotel disabled by admin',
      );
    }

    if (!isAvailable) {
      score -= 10;
    }

    final double matchPercentage =
        score.clamp(
      0,
      100,
    );

    final double totalStayPrice =
        pricePerNight *
            request.totalNights *
            request.rooms;

    final String summary =
        _buildSummary(
      hotelName: hotelName,
      matchPercentage:
          matchPercentage,
      matchedReasons:
          matchedReasons,
      missingRequirements:
          missingRequirements,
      totalStayPrice:
          totalStayPrice,
      isAvailable: isAvailable,
    );

    return HotelRecommendationResult(
      hotelId: hotelId,
      hotelName: hotelName,
      location: location,
      category: category,
      score: score,
      matchPercentage:
          matchPercentage,
      pricePerNight:
          pricePerNight,
      totalStayPrice:
          totalStayPrice,
      availableRooms:
          availableRooms,
      rating: rating,
      reviewCount: reviewCount,
      matchedReasons:
          matchedReasons,
      missingRequirements:
          missingRequirements,
      amenities: amenities,
      isFavorite: isFavorite,
      isAvailable: isAvailable,
      isAdminEnabled:
          isAdminEnabled,
      rank: 0,
      summary: summary,
      imageUrl:
          hotel['coverImageUrl']
                  ?.toString() ??
              hotel['imageUrl']
                  ?.toString() ??
              '',
      localImagePath:
          hotel['localCoverImagePath']
                  ?.toString() ??
              '',
      aiGenerated: false,
    );
  }

  Future<int> _calculateAvailableRooms({
    required String hotelId,
    required HotelRecommendationRequest
        request,
  }) async {
    final QuerySnapshot<Map<String, dynamic>>
        roomSnapshot = await _firestore
            .collection('hotel_rooms')
            .where(
              'hotelId',
              isEqualTo: hotelId,
            )
            .get();

    int totalAvailableQuantity = 0;

    final List<String> usableRoomIds =
        <String>[];

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        room in roomSnapshot.docs) {
      final Map<String, dynamic> data =
          room.data();

      if (data['isActive'] == false ||
          data['isDeleted'] == true) {
        continue;
      }

      final String manualStatus =
          data['manualStatus']
                  ?.toString() ??
              data['status']
                  ?.toString() ??
              'available';

      if (<String>{
        'maintenance',
        'housekeeping',
        'blocked',
      }.contains(manualStatus)) {
        continue;
      }

      final int quantity =
          _readInt(
        data['availableQuantity'] ??
            data['quantity'],
        fallback: 1,
      );

      totalAvailableQuantity += quantity;

      usableRoomIds.add(
        data['roomId']?.toString() ??
            room.id,
      );
    }

    if (usableRoomIds.isEmpty) {
      return 0;
    }

    final QuerySnapshot<Map<String, dynamic>>
        bookingSnapshot = await _firestore
            .collection('hotel_bookings')
            .where(
              'hotelId',
              isEqualTo: hotelId,
            )
            .get();

    int reservedRooms = 0;

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        booking in bookingSnapshot.docs) {
      final Map<String, dynamic> data =
          booking.data();

      final String status =
          data['bookingStatus']
                  ?.toString() ??
              '';

      if (<String>{
        'cancelled',
        'rejected',
        'checked_out',
        'completed',
      }.contains(status)) {
        continue;
      }

      final String roomId =
          data['roomId']?.toString() ??
              '';

      if (roomId.isNotEmpty &&
          !usableRoomIds.contains(
            roomId,
          )) {
        continue;
      }

      final DateTime? checkIn =
          _readDate(
        data['checkIn'],
      );

      final DateTime? checkOut =
          _readDate(
        data['checkOut'],
      );

      if (checkIn == null ||
          checkOut == null) {
        continue;
      }

      final bool overlaps =
          request.checkInDate
                  .isBefore(checkOut) &&
              request.checkOutDate
                  .isAfter(checkIn);

      if (!overlaps) {
        continue;
      }

      reservedRooms += _readInt(
        data['rooms'],
        fallback: 1,
      );
    }

    final int available =
        totalAvailableQuantity -
            reservedRooms;

    return available > 0
        ? available
        : 0;
  }

  Future<int> _calculateTotalCapacity(
    String hotelId,
  ) async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection('hotel_rooms')
            .where(
              'hotelId',
              isEqualTo: hotelId,
            )
            .get();

    int capacity = 0;

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        document in snapshot.docs) {
      final Map<String, dynamic> data =
          document.data();

      if (data['isActive'] == false ||
          data['isDeleted'] == true) {
        continue;
      }

      final int roomCapacity =
          _readInt(
        data['capacity'],
        fallback:
            _readInt(data['adults']) +
                _readInt(
                  data['children'],
                ),
      );

      final int quantity =
          _readInt(
        data['availableQuantity'] ??
            data['quantity'],
        fallback: 1,
      );

      capacity +=
          roomCapacity * quantity;
    }

    return capacity;
  }

  List<String> _buildRequiredAmenities(
    HotelRecommendationRequest request,
  ) {
    final Set<String> values =
        request.requiredAmenities
            .map(
              (String value) =>
                  value.trim(),
            )
            .where(
              (String value) =>
                  value.isNotEmpty,
            )
            .toSet();

    if (request.needsParking) {
      values.add('Parking');
    }

    if (request.needsHotWater) {
      values.add('Hot Water');
    }

    if (request.needsFamilyRoom) {
      values.add('Family Room');
    }

    if (request.needsWiFi) {
      values.add('Wi-Fi');
    }

    if (request.needsRestaurant) {
      values.add('Restaurant');
    }

    if (request.needsMountainView) {
      values.add('Mountain View');
    }

    if (request.needsRiverView) {
      values.add('River View');
    }

    return values.toList();
  }

  double _tripTypeScore({
    required HotelRecommendationRequest
        request,
    required String category,
    required List<String> amenities,
    required List<String> matchedReasons,
  }) {
    final String tripType =
        request.tripType
            .trim()
            .toLowerCase();

    final List<String> normalizedAmenities =
        amenities
            .map(
              (String value) =>
                  value.toLowerCase(),
            )
            .toList();

    double score = 0;

    if (tripType == 'family') {
      final bool familyFriendly =
          normalizedAmenities.any(
            (String value) =>
                value.contains('family'),
          ) ||
          category.toLowerCase() ==
              'family';

      if (familyFriendly) {
        score += 3;
        matchedReasons.add(
          'Family-friendly stay',
        );
      }
    }

    if (tripType == 'couple') {
      final bool scenic =
          normalizedAmenities.any(
        (String value) =>
            value.contains('view') ||
            value.contains('garden'),
      );

      if (scenic) {
        score += 2;
        matchedReasons.add(
          'Suitable for couple stay',
        );
      }
    }

    if (tripType == 'business') {
      final bool businessReady =
          normalizedAmenities.any(
            (String value) =>
                value.contains('wi-fi') ||
                value.contains('wifi'),
          );

      if (businessReady) {
        score += 2;
        matchedReasons.add(
          'Business-ready facilities',
        );
      }
    }

    if (tripType == 'solo') {
      if (category.toLowerCase() ==
              'budget' ||
          category.toLowerCase() ==
              'standard') {
        score += 2;
        matchedReasons.add(
          'Good value for solo traveller',
        );
      }
    }

    return score;
  }

  String _buildSummary({
    required String hotelName,
    required double matchPercentage,
    required List<String>
        matchedReasons,
    required List<String>
        missingRequirements,
    required double totalStayPrice,
    required bool isAvailable,
  }) {
    final StringBuffer buffer =
        StringBuffer();

    buffer.write(
      '$hotelName is a ${matchPercentage.toStringAsFixed(0)}% match.',
    );

    if (matchedReasons.isNotEmpty) {
      buffer.write(
        ' Best points: ${matchedReasons.take(3).join(', ')}.',
      );
    }

    if (!isAvailable) {
      buffer.write(
        ' Rooms are not fully available for the selected dates.',
      );
    }

    if (missingRequirements.isNotEmpty) {
      buffer.write(
        ' Warning: ${missingRequirements.take(2).join(', ')}.',
      );
    }

    if (totalStayPrice > 0) {
      buffer.write(
        ' Estimated stay total: PKR ${_money(totalStayPrice)}.',
      );
    }

    return buffer.toString();
  }

  void _validateRequest(
    HotelRecommendationRequest request,
  ) {
    if (!request.hasValidDates) {
      throw Exception(
        'Check-out date must be after check-in date.',
      );
    }

    if (request.rooms <= 0) {
      throw Exception(
        'At least one room is required.',
      );
    }

    if (request.adults <= 0) {
      throw Exception(
        'At least one adult is required.',
      );
    }

    if (request.maxBudgetPerNight < 0) {
      throw Exception(
        'Budget cannot be negative.',
      );
    }
  }

  List<String> _readStringList(
    dynamic value,
  ) {
    if (value is List) {
      return value
          .map(
            (dynamic item) =>
                item.toString().trim(),
          )
          .where(
            (String item) =>
                item.isNotEmpty,
          )
          .toList();
    }

    if (value is String &&
        value.trim().isNotEmpty) {
      return value
          .split(',')
          .map(
            (String item) =>
                item.trim(),
          )
          .where(
            (String item) =>
                item.isNotEmpty,
          )
          .toList();
    }

    return <String>[];
  }

  int _readInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  double _readDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  DateTime? _readDate(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(
        value,
      );
    }

    return null;
  }

  String _money(
    num amount,
  ) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(
            r'\B(?=(\d{3})+(?!\d))',
          ),
          (Match match) => ',',
        );
  }
}
