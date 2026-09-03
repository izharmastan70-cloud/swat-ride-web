import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/hotel_favorite.dart';
import '../services/hotel_favorite_service.dart';
import 'hotel_room_selection_screen.dart';

class HotelDetailScreen extends StatefulWidget {
  const HotelDetailScreen({
    super.key,
    required this.hotel,
  });

  final Map<String, dynamic> hotel;

  @override
  State<HotelDetailScreen> createState() =>
      _HotelDetailScreenState();
}

class _HotelDetailScreenState
    extends State<HotelDetailScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final HotelFavoriteService _favoriteService =
      HotelFavoriteService();

  bool _isFavoriteWorking = false;

  Map<String, dynamic> get hotel => widget.hotel;

  @override
  Widget build(BuildContext context) {
    final String hotelId =
        hotel['id']?.toString() ??
            hotel['hotelId']?.toString() ??
            '';

    final String hotelName =
        hotel['name']?.toString().trim().isNotEmpty == true
            ? hotel['name'].toString()
            : hotel['hotelName']
                        ?.toString()
                        .trim()
                        .isNotEmpty ==
                    true
                ? hotel['hotelName'].toString()
                : 'Swat Hotel';

    final String location =
        hotel['location']?.toString().trim().isNotEmpty == true
            ? hotel['location'].toString()
            : hotel['address']
                        ?.toString()
                        .trim()
                        .isNotEmpty ==
                    true
                ? hotel['address'].toString()
                : 'Swat, Khyber Pakhtunkhwa';

    final String category =
        hotel['category']?.toString().trim().isNotEmpty == true
            ? hotel['category'].toString()
            : 'Standard';

    final String description =
        hotel['description']?.toString().trim().isNotEmpty == true
            ? hotel['description'].toString()
            : 'Comfortable accommodation for your Swat trip.';

    final String imageUrl =
        hotel['imageUrl']?.toString() ??
            hotel['coverImageUrl']?.toString() ??
            '';

    final double rating =
        _readDouble(hotel['averageRating'] ?? hotel['rating']);
    final int reviewCount =
        _readInt(hotel['reviewCount']);
    final int price =
        _readInt(hotel['startingPrice'] ?? hotel['price']);
    final int rooms =
        _readInt(hotel['availableRooms'] ?? hotel['rooms']);
    final List<String> amenities =
        _readAmenities(hotel['amenities']);

    final User? user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Hotel Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          if (user == null)
            IconButton(
              tooltip: 'Add to favorites',
              onPressed: _showLoginRequired,
              icon: const Icon(
                Icons.favorite_border,
                color: Colors.white,
              ),
            )
          else
            StreamBuilder<bool>(
              stream: _favoriteService.favoriteStatusStream(
                userId: user.uid,
                hotelId: hotelId,
              ),
              builder: (context, snapshot) {
                final bool isFavorite =
                    snapshot.data == true;

                return IconButton(
                  tooltip: isFavorite
                      ? 'Remove Favorite'
                      : 'Add Favorite',
                  onPressed: _isFavoriteWorking
                      ? null
                      : () => _toggleFavorite(
                            userId: user.uid,
                            hotelId: hotelId,
                            hotelName: hotelName,
                            location: location,
                            rating: rating,
                            reviewCount: reviewCount,
                            price: price,
                            imageUrl: imageUrl,
                          ),
                  icon: _isFavoriteWorking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: yellow,
                          ),
                        )
                      : Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFavorite
                              ? Colors.redAccent
                              : Colors.white,
                        ),
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: darkCard,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Starting from',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price > 0
                          ? 'PKR ${_formatPrice(price)} / night'
                          : 'Price on request',
                      style: const TextStyle(
                        color: yellow,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: hotelId.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) {
                              return HotelRoomSelectionScreen(
                                hotel: hotel,
                              );
                            },
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: yellow,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor:
                      Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Select Room',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 240,
                color: const Color(0xFF252525),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return const Center(
                            child: Icon(
                              Icons.hotel,
                              color: yellow,
                              size: 80,
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(
                          Icons.hotel,
                          color: yellow,
                          size: 80,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotelName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: yellow,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: yellow.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: yellow,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.star,
                          color: yellow,
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (reviewCount > 0) ...[
                          const SizedBox(width: 5),
                          Text(
                            '($reviewCount review(s))',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'About This Hotel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: darkCard,
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.05,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          _infoRow(
                            icon: Icons.hotel,
                            title: 'Hotel Category',
                            value: category,
                          ),
                          const Divider(
                            color: Colors.white12,
                            height: 24,
                          ),
                          _infoRow(
                            icon: Icons.meeting_room,
                            title: 'Available Rooms',
                            value: rooms > 0
                                ? '$rooms Rooms'
                                : 'Confirm Availability',
                          ),
                          const Divider(
                            color: Colors.white12,
                            height: 24,
                          ),
                          _infoRow(
                            icon: Icons.location_city,
                            title: 'Location',
                            value: location,
                          ),
                          const Divider(
                            color: Colors.white12,
                            height: 24,
                          ),
                          _infoRow(
                            icon: Icons.payments,
                            title: 'Starting Price',
                            value: price > 0
                                ? 'PKR ${_formatPrice(price)}'
                                : 'On Request',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Hotel Facilities',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: amenities.map(
                        (amenity) {
                          return _facilityChip(
                            icon: _facilityIcon(amenity),
                            title: amenity,
                          );
                        },
                      ).toList(),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: darkCard,
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color: yellow.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: yellow,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Testing mode is active. Favorites use real Firestore. Live hotel images remain bypassed until Firebase Storage billing is enabled.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite({
    required String userId,
    required String hotelId,
    required String hotelName,
    required String location,
    required double rating,
    required int reviewCount,
    required int price,
    required String imageUrl,
  }) async {
    if (hotelId.trim().isEmpty) {
      _showMessage(
        'Hotel ID is missing.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isFavoriteWorking = true;
    });

    try {
      final HotelFavorite favorite =
          HotelFavorite(
        id: '',
        userId: userId,
        hotelId: hotelId,
        hotelName: hotelName,
        hotelLocation: location,
        coverImageUrl: imageUrl,
        localCoverImagePath: '',
        averageRating: rating,
        reviewCount: reviewCount,
        startingPrice: price.toDouble(),
        isActive: hotel['isActive'] != false,
        storageUploadUsed: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bool isNowFavorite =
          await _favoriteService.toggleFavorite(
        favorite: favorite,
      );

      _showMessage(
        isNowFavorite
            ? 'Hotel added to favorites.'
            : 'Hotel removed from favorites.',
      );
    } catch (error) {
      _showMessage(
        'Unable to update favorite: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFavoriteWorking = false;
        });
      }
    }
  }

  void _showLoginRequired() {
    _showMessage(
      'Please log in to use hotel favorites.',
      isError: true,
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: yellow,
          size: 23,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _facilityChip({
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: yellow,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _readAmenities(dynamic value) {
    if (value is List) {
      final List<String> result = value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();

      if (result.isNotEmpty) {
        return result;
      }
    }

    return const <String>[
      'Wi-Fi',
      'Parking',
      'Restaurant',
      'Hot Water',
      'Room Service',
      'Family Rooms',
    ];
  }

  IconData _facilityIcon(String amenity) {
    final String value = amenity.toLowerCase();

    if (value.contains('wi-fi') ||
        value.contains('wifi')) {
      return Icons.wifi;
    }
    if (value.contains('parking')) {
      return Icons.local_parking;
    }
    if (value.contains('restaurant') ||
        value.contains('food')) {
      return Icons.restaurant;
    }
    if (value.contains('hot water')) {
      return Icons.hot_tub;
    }
    if (value.contains('room service')) {
      return Icons.room_service;
    }
    if (value.contains('family')) {
      return Icons.family_restroom;
    }
    if (value.contains('river')) {
      return Icons.water;
    }
    if (value.contains('mountain')) {
      return Icons.terrain;
    }
    if (value.contains('garden')) {
      return Icons.park;
    }
    if (value.contains('kitchen')) {
      return Icons.kitchen;
    }

    return Icons.check_circle_outline;
  }

  int _readInt(dynamic value) {
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

  double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static String _formatPrice(int price) {
    final String value = price.toString();

    return value.replaceAllMapped(
      RegExp(r'\\B(?=(\\d{3})+(?!\\d))'),
      (match) => ',',
    );
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : darkCard,
        ),
      );
  }
}
