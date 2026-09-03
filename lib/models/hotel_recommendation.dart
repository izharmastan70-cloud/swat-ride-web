class HotelRecommendationRequest {
  const HotelRecommendationRequest({
    required this.userId,
    required this.destination,
    required this.checkInDate,
    required this.checkOutDate,
    required this.adults,
    required this.children,
    required this.rooms,
    required this.maxBudgetPerNight,
    required this.tripType,
    this.requiredAmenities = const <String>[],
    this.preferredCategories = const <String>[],
    this.preferredHotelIds = const <String>[],
    this.excludeHotelIds = const <String>[],
    this.needsParking = false,
    this.needsHotWater = false,
    this.needsFamilyRoom = false,
    this.needsWiFi = false,
    this.needsRestaurant = false,
    this.needsMountainView = false,
    this.needsRiverView = false,
  });

  final String userId;
  final String destination;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int adults;
  final int children;
  final int rooms;
  final double maxBudgetPerNight;
  final String tripType;
  final List<String> requiredAmenities;
  final List<String> preferredCategories;
  final List<String> preferredHotelIds;
  final List<String> excludeHotelIds;
  final bool needsParking;
  final bool needsHotWater;
  final bool needsFamilyRoom;
  final bool needsWiFi;
  final bool needsRestaurant;
  final bool needsMountainView;
  final bool needsRiverView;

  int get totalGuests => adults + children;

  int get totalNights {
    final int nights =
        checkOutDate.difference(checkInDate).inDays;

    return nights > 0 ? nights : 0;
  }

  double get maximumStayBudget =>
      maxBudgetPerNight * totalNights * rooms;

  bool get hasValidDates =>
      checkOutDate.isAfter(checkInDate);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'destination': destination,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
      'adults': adults,
      'children': children,
      'rooms': rooms,
      'maxBudgetPerNight': maxBudgetPerNight,
      'tripType': tripType,
      'requiredAmenities': requiredAmenities,
      'preferredCategories': preferredCategories,
      'preferredHotelIds': preferredHotelIds,
      'excludeHotelIds': excludeHotelIds,
      'needsParking': needsParking,
      'needsHotWater': needsHotWater,
      'needsFamilyRoom': needsFamilyRoom,
      'needsWiFi': needsWiFi,
      'needsRestaurant': needsRestaurant,
      'needsMountainView': needsMountainView,
      'needsRiverView': needsRiverView,
      'totalGuests': totalGuests,
      'totalNights': totalNights,
      'maximumStayBudget': maximumStayBudget,
    };
  }
}

class HotelRecommendationResult {
  const HotelRecommendationResult({
    required this.hotelId,
    required this.hotelName,
    required this.location,
    required this.category,
    required this.score,
    required this.matchPercentage,
    required this.pricePerNight,
    required this.totalStayPrice,
    required this.availableRooms,
    required this.rating,
    required this.reviewCount,
    required this.matchedReasons,
    required this.missingRequirements,
    required this.amenities,
    required this.isFavorite,
    required this.isAvailable,
    required this.isAdminEnabled,
    required this.rank,
    this.summary = '',
    this.imageUrl = '',
    this.localImagePath = '',
    this.aiGenerated = false,
  });

  final String hotelId;
  final String hotelName;
  final String location;
  final String category;
  final double score;
  final double matchPercentage;
  final double pricePerNight;
  final double totalStayPrice;
  final int availableRooms;
  final double rating;
  final int reviewCount;
  final List<String> matchedReasons;
  final List<String> missingRequirements;
  final List<String> amenities;
  final bool isFavorite;
  final bool isAvailable;
  final bool isAdminEnabled;
  final int rank;
  final String summary;
  final String imageUrl;
  final String localImagePath;
  final bool aiGenerated;

  bool get isRecommended =>
      isAvailable &&
      isAdminEnabled &&
      matchPercentage >= 50;

  bool get hasWarnings =>
      missingRequirements.isNotEmpty;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'hotelId': hotelId,
      'hotelName': hotelName,
      'location': location,
      'category': category,
      'score': score,
      'matchPercentage': matchPercentage,
      'pricePerNight': pricePerNight,
      'totalStayPrice': totalStayPrice,
      'availableRooms': availableRooms,
      'rating': rating,
      'reviewCount': reviewCount,
      'matchedReasons': matchedReasons,
      'missingRequirements': missingRequirements,
      'amenities': amenities,
      'isFavorite': isFavorite,
      'isAvailable': isAvailable,
      'isAdminEnabled': isAdminEnabled,
      'rank': rank,
      'summary': summary,
      'imageUrl': imageUrl,
      'localImagePath': localImagePath,
      'aiGenerated': aiGenerated,
    };
  }

  HotelRecommendationResult copyWith({
    String? hotelId,
    String? hotelName,
    String? location,
    String? category,
    double? score,
    double? matchPercentage,
    double? pricePerNight,
    double? totalStayPrice,
    int? availableRooms,
    double? rating,
    int? reviewCount,
    List<String>? matchedReasons,
    List<String>? missingRequirements,
    List<String>? amenities,
    bool? isFavorite,
    bool? isAvailable,
    bool? isAdminEnabled,
    int? rank,
    String? summary,
    String? imageUrl,
    String? localImagePath,
    bool? aiGenerated,
  }) {
    return HotelRecommendationResult(
      hotelId: hotelId ?? this.hotelId,
      hotelName: hotelName ?? this.hotelName,
      location: location ?? this.location,
      category: category ?? this.category,
      score: score ?? this.score,
      matchPercentage:
          matchPercentage ?? this.matchPercentage,
      pricePerNight:
          pricePerNight ?? this.pricePerNight,
      totalStayPrice:
          totalStayPrice ?? this.totalStayPrice,
      availableRooms:
          availableRooms ?? this.availableRooms,
      rating: rating ?? this.rating,
      reviewCount:
          reviewCount ?? this.reviewCount,
      matchedReasons:
          matchedReasons ?? this.matchedReasons,
      missingRequirements:
          missingRequirements ??
              this.missingRequirements,
      amenities: amenities ?? this.amenities,
      isFavorite:
          isFavorite ?? this.isFavorite,
      isAvailable:
          isAvailable ?? this.isAvailable,
      isAdminEnabled:
          isAdminEnabled ?? this.isAdminEnabled,
      rank: rank ?? this.rank,
      summary: summary ?? this.summary,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath:
          localImagePath ?? this.localImagePath,
      aiGenerated:
          aiGenerated ?? this.aiGenerated,
    );
  }
}

class HotelRecommendationResponse {
  const HotelRecommendationResponse({
    required this.request,
    required this.results,
    required this.generatedAt,
    required this.engineVersion,
    this.aiSummary = '',
    this.aiAgentUsed = false,
    this.testingMode = true,
  });

  final HotelRecommendationRequest request;
  final List<HotelRecommendationResult> results;
  final DateTime generatedAt;
  final String engineVersion;
  final String aiSummary;
  final bool aiAgentUsed;
  final bool testingMode;

  HotelRecommendationResult? get bestMatch =>
      results.isEmpty ? null : results.first;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'request': request.toMap(),
      'results': results
          .map(
            (HotelRecommendationResult result) =>
                result.toMap(),
          )
          .toList(),
      'generatedAt': generatedAt.toIso8601String(),
      'engineVersion': engineVersion,
      'aiSummary': aiSummary,
      'aiAgentUsed': aiAgentUsed,
      'testingMode': testingMode,
    };
  }
}
