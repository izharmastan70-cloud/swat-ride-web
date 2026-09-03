import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/location_model.dart';

class RideLocationService {
  RideLocationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Keep false until Google Places/Geocoding billing and key restrictions
  /// are configured through a secure backend.
  static const bool useGooglePlacesForProduction = false;

  CollectionReference<Map<String, dynamic>> get _placesCollection =>
      _firestore.collection('normal_ride_places');

  static const List<LocationModel> _builtInSwatPlaces = <LocationModel>[
    LocationModel(
      latitude: 34.7717,
      longitude: 72.3602,
      placeName: 'Mingora',
      address: 'Mingora, Swat, Khyber Pakhtunkhwa',
    ),
    LocationModel(
      latitude: 34.7758,
      longitude: 72.3625,
      placeName: 'Saidu Sharif',
      address: 'Saidu Sharif, Swat, Khyber Pakhtunkhwa',
    ),
    LocationModel(
      latitude: 34.8006,
      longitude: 72.3597,
      placeName: 'Fizagat',
      address: 'Fizagat, Mingora, Swat',
    ),
    LocationModel(
      latitude: 34.8126,
      longitude: 72.3547,
      placeName: 'Kanjo',
      address: 'Kanjo, Swat, Khyber Pakhtunkhwa',
    ),
    LocationModel(
      latitude: 34.7572,
      longitude: 72.3579,
      placeName: 'Saidu Teaching Hospital',
      address: 'Saidu Sharif, Swat',
    ),
    LocationModel(
      latitude: 34.7764,
      longitude: 72.3599,
      placeName: 'Swat Serena Hotel',
      address: 'Saidu Sharif, Swat',
    ),
    LocationModel(
      latitude: 34.8492,
      longitude: 72.4361,
      placeName: 'Malam Jabba Road',
      address: 'Malam Jabba Road, Swat',
    ),
    LocationModel(
      latitude: 34.9362,
      longitude: 72.4848,
      placeName: 'Madyan',
      address: 'Madyan, Swat, Khyber Pakhtunkhwa',
    ),
    LocationModel(
      latitude: 35.2074,
      longitude: 72.5444,
      placeName: 'Bahrain',
      address: 'Bahrain, Swat, Khyber Pakhtunkhwa',
    ),
    LocationModel(
      latitude: 35.4792,
      longitude: 72.5796,
      placeName: 'Kalam',
      address: 'Kalam, Swat, Khyber Pakhtunkhwa',
    ),
  ];

  Future<List<LocationModel>> getPopularPlaces() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _placesCollection
              .where('isEnabled', isEqualTo: true)
              .where('isPopular', isEqualTo: true)
              .limit(20)
              .get();

      final List<LocationModel> places = snapshot.docs
          .map(_locationFromDocument)
          .whereType<LocationModel>()
          .toList(growable: false);
      if (places.isNotEmpty) return places;
    } on FirebaseException {
      // Use built-in Swat places when offline, rules block the query, or the
      // Admin collection/index has not been created yet.
    }

    return _builtInSwatPlaces;
  }

  Future<List<LocationModel>> searchPlaces(String query) async {
    final String normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return getPopularPlaces();

    if (useGooglePlacesForProduction) {
      return _searchRealGooglePlaces(normalizedQuery);
    }

    final List<LocationModel> availablePlaces = await _allAdminOrSafePlaces();
    return availablePlaces.where((LocationModel place) {
      final String searchable =
          '${place.placeName} ${place.address}'.toLowerCase();
      return searchable.contains(normalizedQuery);
    }).toList(growable: false);
  }

  Future<List<LocationModel>> _allAdminOrSafePlaces() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _placesCollection
              .where('isEnabled', isEqualTo: true)
              .limit(100)
              .get();
      final List<LocationModel> places = snapshot.docs
          .map(_locationFromDocument)
          .whereType<LocationModel>()
          .toList(growable: false);
      if (places.isNotEmpty) return places;
    } on FirebaseException {
      // Safe fallback below.
    }
    return _builtInSwatPlaces;
  }

  LocationModel? _locationFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();
    final double? latitude = _nullableDouble(data['latitude']);
    final double? longitude = _nullableDouble(data['longitude']);
    final String placeName = data['placeName']?.toString().trim() ?? '';
    final String address = data['address']?.toString().trim() ?? '';

    if (latitude == null ||
        longitude == null ||
        placeName.isEmpty ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }

    return LocationModel(
      latitude: latitude,
      longitude: longitude,
      placeName: placeName,
      address: address.isEmpty ? placeName : address,
    );
  }

  /// Admin-only. Firestore Security Rules must enforce the Admin role.
  Future<void> saveAdminPlace({
    required String placeId,
    required LocationModel location,
    bool isEnabled = true,
    bool isPopular = false,
  }) async {
    final String id = placeId.trim();
    if (id.isEmpty) throw Exception('Place ID is required.');
    if (!_validCoordinates(location.latitude, location.longitude)) {
      throw Exception('Place coordinates are invalid.');
    }

    await _placesCollection.doc(id).set(<String, dynamic>{
      ...location.toMap(),
      'placeId': id,
      'isEnabled': isEnabled,
      'isPopular': isPopular,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<LocationModel>> _searchRealGooglePlaces(String query) async {
    // REAL GOOGLE PLACES / GEOCODING CONNECTION (BILLING PAUSED)
    //
    // Production flow:
    // 1. Flutter sends the search text and Swat region bounds to a backend.
    // 2. Backend calls Google Places Autocomplete with a restricted key.
    // 3. User selects a result; backend resolves Place Details coordinates.
    // 4. Flutter receives only place name, address, latitude and longitude.
    // 5. Never place an unrestricted server key inside the Flutter app.
    throw StateError(
      'Google Places billing is not enabled. '
      'Keep useGooglePlacesForProduction false during testing.',
    );
  }

  bool _validCoordinates(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  double? _nullableDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
