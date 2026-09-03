import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyFavoriteHotelsScreen extends StatelessWidget {
  const MyFavoriteHotelsScreen({
    super.key,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'My Favorite Hotels',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: user == null
          ? const _FavoriteMessage(
              icon: Icons.lock_outline,
              title: 'Login Required',
              message: 'Please log in to view your favorite hotels.',
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('hotel_favorites')
                  .where(
                    'userId',
                    isEqualTo: user.uid,
                  )
                  .snapshots(),
              builder: (
                context,
                AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: yellow,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _FavoriteMessage(
                    icon: Icons.error_outline,
                    title: 'Unable to Load Favorites',
                    message: snapshot.error.toString(),
                  );
                }

                final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                    snapshot.data?.docs ??
                        <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                docs.sort(
                  (
                    QueryDocumentSnapshot<Map<String, dynamic>> a,
                    QueryDocumentSnapshot<Map<String, dynamic>> b,
                  ) {
                    return _readDateTime(
                      b.data()['updatedAt'] ?? b.data()['createdAt'],
                    ).compareTo(
                      _readDateTime(
                        a.data()['updatedAt'] ?? a.data()['createdAt'],
                      ),
                    );
                  },
                );

                if (docs.isEmpty) {
                  return const _FavoriteMessage(
                    icon: Icons.favorite_border,
                    title: 'No Favorite Hotels',
                    message:
                        'Tap the heart icon on a hotel to add it to your favorites.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    28,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    final document = docs[index];
                    final data = document.data();

                    final String hotelId =
                        data['hotelId']?.toString() ?? '';
                    final String hotelName =
                        data['hotelName']?.toString() ?? 'Hotel';
                    final String hotelLocation =
                        data['hotelLocation']?.toString() ?? '';
                    final double rating =
                        _readDouble(data['averageRating']);
                    final int reviewCount =
                        _readInt(data['reviewCount']);
                    final double startingPrice =
                        _readDouble(data['startingPrice']);

                    return Container(
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: darkCard,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.06,
                          ),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop<Map<String, dynamic>>(
                            context,
                            <String, dynamic>{
                              'hotelId': hotelId,
                              'hotelName': hotelName,
                              'hotelLocation': hotelLocation,
                              'averageRating': rating,
                              'reviewCount': reviewCount,
                              'startingPrice': startingPrice,
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(17),
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: yellow.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.hotel,
                                color: yellow,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hotelName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  if (hotelLocation.isNotEmpty)
                                    Text(
                                      hotelLocation,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  const SizedBox(height: 5),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 4,
                                    children: [
                                      if (rating > 0)
                                        Text(
                                          '★ ${rating.toStringAsFixed(1)}'
                                          '${reviewCount > 0 ? ' ($reviewCount)' : ''}',
                                          style: const TextStyle(
                                            color: yellow,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      if (startingPrice > 0)
                                        Text(
                                          'Rs. ${_formatMoney(startingPrice)} / night',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove favorite',
                              onPressed: () async {
                                try {
                                  await document.reference.delete();

                                  if (!context.mounted) {
                                    return;
                                  }

                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Hotel removed from favorites.',
                                        ),
                                        backgroundColor: darkCard,
                                      ),
                                    );
                                } catch (error) {
                                  if (!context.mounted) {
                                    return;
                                  }

                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Unable to remove favorite: $error',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                }
                              },
                              icon: const Icon(
                                Icons.favorite,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _formatMoney(num amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        );
  }
}

class _FavoriteMessage extends StatelessWidget {
  const _FavoriteMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              color: MyFavoriteHotelsScreen.yellow,
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
