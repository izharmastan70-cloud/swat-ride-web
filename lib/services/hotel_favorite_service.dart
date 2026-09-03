import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/hotel_favorite.dart';

class HotelFavoriteService {
  HotelFavoriteService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName =
      'hotel_favorites';

  CollectionReference<Map<String, dynamic>>
      get _favoritesCollection =>
          _firestore.collection(collectionName);

  String favoriteDocumentId({
    required String userId,
    required String hotelId,
  }) {
    return '${userId}_$hotelId';
  }

  Future<void> addFavorite({
    required HotelFavorite favorite,
  }) async {
    if (favorite.userId.trim().isEmpty) {
      throw Exception(
        'Customer user ID is required.',
      );
    }

    if (favorite.hotelId.trim().isEmpty) {
      throw Exception(
        'Hotel ID is required.',
      );
    }

    final String documentId =
        favoriteDocumentId(
      userId: favorite.userId,
      hotelId: favorite.hotelId,
    );

    await _favoritesCollection
        .doc(documentId)
        .set(
      <String, dynamic>{
        ...favorite.copyWith(
          id: documentId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          storageUploadUsed: false,
        ).toMap(),
        'favoriteId': documentId,
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeFavorite({
    required String userId,
    required String hotelId,
  }) async {
    if (userId.trim().isEmpty ||
        hotelId.trim().isEmpty) {
      throw Exception(
        'Customer and hotel ID are required.',
      );
    }

    final String documentId =
        favoriteDocumentId(
      userId: userId,
      hotelId: hotelId,
    );

    await _favoritesCollection
        .doc(documentId)
        .delete();
  }

  Future<bool> isFavorite({
    required String userId,
    required String hotelId,
  }) async {
    if (userId.trim().isEmpty ||
        hotelId.trim().isEmpty) {
      return false;
    }

    final String documentId =
        favoriteDocumentId(
      userId: userId,
      hotelId: hotelId,
    );

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _favoritesCollection
            .doc(documentId)
            .get();

    return snapshot.exists;
  }

  Stream<bool> favoriteStatusStream({
    required String userId,
    required String hotelId,
  }) {
    if (userId.trim().isEmpty ||
        hotelId.trim().isEmpty) {
      return Stream<bool>.value(false);
    }

    final String documentId =
        favoriteDocumentId(
      userId: userId,
      hotelId: hotelId,
    );

    return _favoritesCollection
        .doc(documentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.exists,
        );
  }

  Stream<List<HotelFavorite>>
      userFavoritesStream(
    String userId,
  ) {
    if (userId.trim().isEmpty) {
      return Stream<List<HotelFavorite>>.value(
        const <HotelFavorite>[],
      );
    }

    return _favoritesCollection
        .where(
          'userId',
          isEqualTo: userId,
        )
        .snapshots()
        .map(
      (snapshot) {
        final List<HotelFavorite> favorites =
            snapshot.docs
                .map(
                  (document) =>
                      HotelFavorite.fromMap(
                    document.data(),
                    document.id,
                  ),
                )
                .toList();

        favorites.sort(
          (a, b) =>
              b.createdAt.compareTo(a.createdAt),
        );

        return favorites;
      },
    );
  }

  Future<List<HotelFavorite>>
      getUserFavorites(
    String userId,
  ) async {
    if (userId.trim().isEmpty) {
      return const <HotelFavorite>[];
    }

    final QuerySnapshot<
            Map<String, dynamic>>
        snapshot =
        await _favoritesCollection
            .where(
              'userId',
              isEqualTo: userId,
            )
            .get();

    final List<HotelFavorite> favorites =
        snapshot.docs
            .map(
              (document) =>
                  HotelFavorite.fromMap(
                document.data(),
                document.id,
              ),
            )
            .toList();

    favorites.sort(
      (a, b) =>
          b.createdAt.compareTo(a.createdAt),
    );

    return favorites;
  }

  Future<bool> toggleFavorite({
    required HotelFavorite favorite,
  }) async {
    final bool exists = await isFavorite(
      userId: favorite.userId,
      hotelId: favorite.hotelId,
    );

    if (exists) {
      await removeFavorite(
        userId: favorite.userId,
        hotelId: favorite.hotelId,
      );

      return false;
    }

    await addFavorite(
      favorite: favorite,
    );

    return true;
  }

  Future<void> refreshFavoriteSnapshot({
    required String userId,
    required Map<String, dynamic> hotel,
  }) async {
    final String hotelId =
        hotel['id']?.toString() ??
            hotel['hotelId']?.toString() ??
            '';

    if (hotelId.isEmpty ||
        userId.trim().isEmpty) {
      return;
    }

    final bool exists = await isFavorite(
      userId: userId,
      hotelId: hotelId,
    );

    if (!exists) {
      return;
    }

    final String documentId =
        favoriteDocumentId(
      userId: userId,
      hotelId: hotelId,
    );

    await _favoritesCollection
        .doc(documentId)
        .set(
      <String, dynamic>{
        'hotelName':
            hotel['hotelName']?.toString() ??
                hotel['name']?.toString() ??
                'Hotel',
        'hotelLocation':
            hotel['location']?.toString() ??
                hotel['address']?.toString() ??
                '',
        'coverImageUrl':
            hotel['coverImageUrl']?.toString() ??
                hotel['imageUrl']?.toString() ??
                '',
        'averageRating':
            _readDouble(
          hotel['averageRating'],
        ),
        'reviewCount':
            _readInt(
          hotel['reviewCount'],
        ),
        'startingPrice':
            _readDouble(
          hotel['startingPrice'] ??
              hotel['pricePerNight'],
        ),
        'isActive':
            hotel['isActive'] != false,
        'storageUploadUsed': false,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<int> favoriteCountForHotel(
    String hotelId,
  ) async {
    if (hotelId.trim().isEmpty) {
      return 0;
    }

    final QuerySnapshot<
            Map<String, dynamic>>
        snapshot =
        await _favoritesCollection
            .where(
              'hotelId',
              isEqualTo: hotelId,
            )
            .get();

    return snapshot.docs.length;
  }

  int _readInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
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
}
