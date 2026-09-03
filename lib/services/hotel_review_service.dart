import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/hotel_review.dart';

class HotelReviewService {
  HotelReviewService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName =
      'hotel_reviews';

  CollectionReference<Map<String, dynamic>>
      get _reviewsCollection =>
          _firestore.collection(collectionName);

  Future<String> submitReview({
    required HotelReview review,
  }) async {
    if (!review.ratingIsValid) {
      throw Exception(
        'Rating must be between 1 and 5.',
      );
    }

    if (review.hotelId.trim().isEmpty ||
        review.bookingId.trim().isEmpty ||
        review.userId.trim().isEmpty) {
      throw Exception(
        'Hotel, booking and customer ID are required.',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>>
        bookingSnapshot = await _firestore
            .collection('hotel_bookings')
            .doc(review.bookingId)
            .get();

    if (!bookingSnapshot.exists ||
        bookingSnapshot.data() == null) {
      throw Exception(
        'Hotel booking was not found.',
      );
    }

    final Map<String, dynamic> booking =
        bookingSnapshot.data()!;

    final String bookingUserId =
        booking['userId']?.toString() ??
            booking['customerId']?.toString() ??
            '';

    final String bookingHotelId =
        booking['hotelId']?.toString() ?? '';

    final String bookingStatus =
        booking['bookingStatus']?.toString() ?? '';

    if (bookingUserId != review.userId) {
      throw Exception(
        'This booking does not belong to the customer.',
      );
    }

    if (bookingHotelId != review.hotelId) {
      throw Exception(
        'This booking does not belong to the selected hotel.',
      );
    }

    const List<String> allowedStatuses =
        <String>[
      'checked_out',
      'completed',
    ];

    if (!allowedStatuses.contains(bookingStatus)) {
      throw Exception(
        'Review is allowed only after checkout or completed stay.',
      );
    }

    final QuerySnapshot<Map<String, dynamic>>
        existingReviewSnapshot =
        await _reviewsCollection
            .where(
              'bookingId',
              isEqualTo: review.bookingId,
            )
            .where(
              'userId',
              isEqualTo: review.userId,
            )
            .limit(1)
            .get();

    if (existingReviewSnapshot.docs.isNotEmpty) {
      throw Exception(
        'A review already exists for this booking.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        reference = _reviewsCollection.doc();

    await reference.set(
      <String, dynamic>{
        ...review.copyWith(
          id: reference.id,
          isVerifiedStay: true,
          reviewStatus: 'published',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          storageUploadUsed: false,
        ).toMap(),
        'reviewId': reference.id,
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    await _updateHotelRating(review.hotelId);

    await _createHotelNotification(
      hotelId: review.hotelId,
      bookingId: review.bookingId,
      title: 'New Hotel Review',
      message:
          '${review.customerName} submitted a ${review.rating.toStringAsFixed(1)} star review.',
      type: 'new_review',
    );

    return reference.id;
  }

  Stream<List<HotelReview>>
      hotelReviewsStream(
    String hotelId, {
    bool publishedOnly = true,
  }) {
    Query<Map<String, dynamic>> query =
        _reviewsCollection.where(
      'hotelId',
      isEqualTo: hotelId,
    );

    if (publishedOnly) {
      query = query.where(
        'reviewStatus',
        isEqualTo: 'published',
      );
    }

    return query.snapshots().map(
      (snapshot) {
        final List<HotelReview> reviews =
            snapshot.docs
                .map(
                  (document) =>
                      HotelReview.fromMap(
                    document.data(),
                    document.id,
                  ),
                )
                .where(
                  (review) =>
                      !review.isHiddenByAdmin,
                )
                .toList();

        reviews.sort(
          (a, b) =>
              b.createdAt.compareTo(a.createdAt),
        );

        return reviews;
      },
    );
  }

  Stream<List<HotelReview>>
      userReviewsStream(
    String userId,
  ) {
    return _reviewsCollection
        .where(
          'userId',
          isEqualTo: userId,
        )
        .snapshots()
        .map(
      (snapshot) {
        final List<HotelReview> reviews =
            snapshot.docs
                .map(
                  (document) =>
                      HotelReview.fromMap(
                    document.data(),
                    document.id,
                  ),
                )
                .toList();

        reviews.sort(
          (a, b) =>
              b.createdAt.compareTo(a.createdAt),
        );

        return reviews;
      },
    );
  }

  Future<HotelReview?> getReviewForBooking({
    required String bookingId,
    required String userId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _reviewsCollection
            .where(
              'bookingId',
              isEqualTo: bookingId,
            )
            .where(
              'userId',
              isEqualTo: userId,
            )
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final document = snapshot.docs.first;

    return HotelReview.fromMap(
      document.data(),
      document.id,
    );
  }

  Future<void> updateCustomerReview({
    required String reviewId,
    required String userId,
    required double rating,
    required String reviewText,
  }) async {
    if (rating < 1 || rating > 5) {
      throw Exception(
        'Rating must be between 1 and 5.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        reference =
        _reviewsCollection.doc(reviewId);

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot = await reference.get();

    if (!snapshot.exists ||
        snapshot.data() == null) {
      throw Exception(
        'Review was not found.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data()!;

    if (data['userId']?.toString() != userId) {
      throw Exception(
        'You cannot edit this review.',
      );
    }

    await reference.set(
      <String, dynamic>{
        'rating': rating,
        'reviewText': reviewText.trim(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final String hotelId =
        data['hotelId']?.toString() ?? '';

    if (hotelId.isNotEmpty) {
      await _updateHotelRating(hotelId);
    }
  }

  Future<void> replyAsHotelOwner({
    required String reviewId,
    required String hotelId,
    required String ownerUserId,
    required String reply,
  }) async {
    if (reply.trim().isEmpty) {
      throw Exception(
        'Reply cannot be empty.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        reference =
        _reviewsCollection.doc(reviewId);

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot = await reference.get();

    if (!snapshot.exists ||
        snapshot.data() == null) {
      throw Exception(
        'Review was not found.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data()!;

    if (data['hotelId']?.toString() != hotelId) {
      throw Exception(
        'This review does not belong to the hotel.',
      );
    }

    await reference.set(
      <String, dynamic>{
        'ownerReply': reply.trim(),
        'ownerRepliedAt':
            FieldValue.serverTimestamp(),
        'ownerRepliedBy': ownerUserId,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final String customerId =
        data['userId']?.toString() ?? '';

    if (customerId.isNotEmpty) {
      await _createCustomerNotification(
        userId: customerId,
        hotelId: hotelId,
        bookingId:
            data['bookingId']?.toString() ?? '',
        title: 'Hotel Replied to Your Review',
        message:
            'The hotel owner replied to your review.',
        type: 'review_reply',
      );
    }
  }

  Future<void> hideReviewAsAdmin({
    required String reviewId,
    required String reason,
    required String adminUserId,
  }) async {
    final DocumentReference<Map<String, dynamic>>
        reference =
        _reviewsCollection.doc(reviewId);

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot = await reference.get();

    if (!snapshot.exists ||
        snapshot.data() == null) {
      throw Exception(
        'Review was not found.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data()!;

    await reference.set(
      <String, dynamic>{
        'reviewStatus': 'hidden',
        'isHiddenByAdmin': true,
        'hiddenReason': reason.trim(),
        'hiddenByAdminId': adminUserId,
        'hiddenAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final String hotelId =
        data['hotelId']?.toString() ?? '';

    if (hotelId.isNotEmpty) {
      await _updateHotelRating(hotelId);
    }
  }

  Future<void> restoreReviewAsAdmin({
    required String reviewId,
    required String adminUserId,
  }) async {
    final DocumentReference<Map<String, dynamic>>
        reference =
        _reviewsCollection.doc(reviewId);

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot = await reference.get();

    if (!snapshot.exists ||
        snapshot.data() == null) {
      throw Exception(
        'Review was not found.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data()!;

    await reference.set(
      <String, dynamic>{
        'reviewStatus': 'published',
        'isHiddenByAdmin': false,
        'hiddenReason': '',
        'restoredByAdminId': adminUserId,
        'restoredAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    final String hotelId =
        data['hotelId']?.toString() ?? '';

    if (hotelId.isNotEmpty) {
      await _updateHotelRating(hotelId);
    }
  }

  Future<void> _updateHotelRating(
    String hotelId,
  ) async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _reviewsCollection
            .where(
              'hotelId',
              isEqualTo: hotelId,
            )
            .where(
              'reviewStatus',
              isEqualTo: 'published',
            )
            .get();

    double ratingTotal = 0;
    int ratingCount = 0;

    for (final document in snapshot.docs) {
      final Map<String, dynamic> data =
          document.data();

      if (data['isHiddenByAdmin'] == true) {
        continue;
      }

      final dynamic value = data['rating'];

      final double rating = value is num
          ? value.toDouble()
          : double.tryParse(
                value?.toString() ?? '',
              ) ??
              0;

      if (rating >= 1 && rating <= 5) {
        ratingTotal += rating;
        ratingCount++;
      }
    }

    final double averageRating =
        ratingCount == 0
            ? 0
            : ratingTotal / ratingCount;

    await _firestore
        .collection(
          'hotel_partner_applications',
        )
        .doc(hotelId)
        .set(
      <String, dynamic>{
        'averageRating': averageRating,
        'reviewCount': ratingCount,
        'ratingUpdatedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await _firestore
        .collection('hotels')
        .doc(hotelId)
        .set(
      <String, dynamic>{
        'averageRating': averageRating,
        'reviewCount': ratingCount,
        'ratingUpdatedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _createHotelNotification({
    required String hotelId,
    required String bookingId,
    required String title,
    required String message,
    required String type,
  }) async {
    final reference = _firestore
        .collection('hotel_notifications')
        .doc();

    await reference.set(
      <String, dynamic>{
        'notificationId': reference.id,
        'hotelId': hotelId,
        'bookingId': bookingId,
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _createCustomerNotification({
    required String userId,
    required String hotelId,
    required String bookingId,
    required String title,
    required String message,
    required String type,
  }) async {
    final reference = _firestore
        .collection('notifications')
        .doc();

    await reference.set(
      <String, dynamic>{
        'notificationId': reference.id,
        'userId': userId,
        'hotelId': hotelId,
        'bookingId': bookingId,
        'title': title,
        'message': message,
        'type': type,
        'isRead': false,
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }
}
