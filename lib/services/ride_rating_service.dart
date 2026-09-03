import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/ride_model.dart';

class RideRatingService {
  RideRatingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _rides =>
      _firestore.collection('rides');

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection('drivers');

  CollectionReference<Map<String, dynamic>> get _ratings =>
      _firestore.collection('ride_ratings');

  // =========================================================
  // SUBMIT ONE DRIVER RATING PER COMPLETED RIDE
  // =========================================================

  Future<void> submitDriverRating({
    required String rideId,
    required int stars,
    String? comment,
    List<String> tags = const <String>[],
  }) async {
    final String id = rideId.trim();
    final User? rider = _auth.currentUser;

    if (rider == null) {
      throw Exception('Rider is not logged in.');
    }

    if (id.isEmpty) {
      throw Exception('Ride ID is required.');
    }

    if (stars < 1 || stars > 5) {
      throw Exception('Please select a rating from 1 to 5 stars.');
    }

    final String cleanComment = (comment ?? '').trim();
    if (cleanComment.length > 500) {
      throw Exception('Feedback cannot exceed 500 characters.');
    }

    final List<String> cleanTags = tags
        .map((String tag) => tag.trim().toLowerCase())
        .where((String tag) => tag.isNotEmpty)
        .toSet()
        .take(8)
        .toList(growable: false);

    final DocumentReference<Map<String, dynamic>> rideReference =
        _rides.doc(id);
    final DocumentReference<Map<String, dynamic>> ratingReference =
        _ratings.doc(id);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> rideSnapshot =
          await transaction.get(rideReference);

      if (!rideSnapshot.exists) throw Exception('Ride not found.');

      final Map<String, dynamic> rideData = rideSnapshot.data()!;
      final String riderId = rideData['userId']?.toString().trim() ?? '';
      final String driverId = rideData['driverId']?.toString().trim() ?? '';
      final String status =
          rideData['status']?.toString() ?? RideModel.searching;

      if (riderId != rider.uid) {
        throw Exception('You are not allowed to rate this ride.');
      }

      if (status != RideModel.completed) {
        throw Exception('Rating is available after the ride is completed.');
      }

      if (driverId.isEmpty) {
        throw Exception('Driver information is unavailable.');
      }

      final DocumentReference<Map<String, dynamic>> driverReference =
          _drivers.doc(driverId);
      final DocumentSnapshot<Map<String, dynamic>> ratingSnapshot =
          await transaction.get(ratingReference);
      final DocumentSnapshot<Map<String, dynamic>> driverSnapshot =
          await transaction.get(driverReference);

      if (ratingSnapshot.exists) {
        throw Exception('You have already rated this ride.');
      }

      final Map<String, dynamic> driverData =
          driverSnapshot.data() ?? <String, dynamic>{};
      final int oldRatingCount =
          (driverData['ratingCount'] as num?)?.toInt() ?? 0;
      final double oldRatingSum =
          (driverData['ratingSum'] as num?)?.toDouble() ??
              (((driverData['averageRating'] as num?)?.toDouble() ?? 0) *
                  oldRatingCount);
      final int newRatingCount = oldRatingCount + 1;
      final double newRatingSum = oldRatingSum + stars;
      final double newAverageRating = newRatingSum / newRatingCount;

      transaction.set(ratingReference, <String, dynamic>{
        'ratingId': id,
        'rideId': id,
        'riderId': rider.uid,
        'driverId': driverId,
        'stars': stars,
        'comment': cleanComment.isEmpty ? null : cleanComment,
        'tags': cleanTags,
        'isVisible': true,
        'moderationStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(rideReference, <String, dynamic>{
        'riderRating': stars,
        'riderRatingComment': cleanComment.isEmpty ? null : cleanComment,
        'riderRatingTags': cleanTags,
        'ratedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(
        driverReference,
        <String, dynamic>{
          'ratingCount': newRatingCount,
          'ratingSum': newRatingSum,
          'averageRating':
              double.parse(newAverageRating.toStringAsFixed(2)),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  // =========================================================
  // CHECK / WATCH RATING
  // =========================================================

  Future<bool> hasRatedRide(String rideId) async {
    final String id = rideId.trim();
    if (id.isEmpty) return false;

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _ratings.doc(id).get();
    return snapshot.exists;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchRideRating(
    String rideId,
  ) {
    return _ratings.doc(rideId.trim()).snapshots();
  }
}
