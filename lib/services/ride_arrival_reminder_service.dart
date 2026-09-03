import 'package:cloud_firestore/cloud_firestore.dart';

/// Controls the one-time Rider reminder shown shortly before destination.
///
/// The foreground testing flow works without Firebase Storage, billing,
/// Google Directions, or Cloud Functions. A production FCM implementation is
/// documented below and intentionally remains disabled until backend setup.
class RideArrivalReminderService {
  RideArrivalReminderService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const Duration reminderLeadTime = Duration(minutes: 3);

  static const String title = 'You are almost there';

  static const String message =
      'You are approaching your destination. Please check your phone, '
      'wallet, bags and other belongings before leaving the vehicle.';

  /// Atomically reserves the reminder so one ride cannot show it twice.
  ///
  /// During local testing, permission-denied falls back to the screen's
  /// in-memory one-time guard. Production rules/backend should allow only the
  /// trusted notification worker to write these reminder fields.
  Future<bool> claimReminder(String rideId) async {
    final String id = rideId.trim();
    if (id.isEmpty) return false;

    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final reference = _firestore.collection('rides').doc(id);
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists) return false;

        final data = snapshot.data() ?? <String, dynamic>{};
        if (data['status'] != 'ride_started') return false;
        if (data['arrivalReminderSentAt'] != null) return false;

        transaction.update(reference, <String, dynamic>{
          'arrivalReminderSentAt': FieldValue.serverTimestamp(),
          'arrivalReminderChannel': 'in_app_testing',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied' || error.code == 'unavailable') {
        return true;
      }
      rethrow;
    }
  }

  /*
   * PRODUCTION FCM CODE - INTENTIONALLY DISABLED FOR NOW
   * ----------------------------------------------------
   * A trusted Cloud Function / backend worker should observe an active ride,
   * calculate live remaining ETA from the Directions provider, and when ETA
   * becomes <= 3 minutes:
   *
   * 1. Atomically check arrivalReminderSentAt == null.
   * 2. Write arrivalReminderSentAt using server timestamp.
   * 3. Read the Rider's registered FCM token.
   * 4. Send title/message above with rideId in notification data.
   * 5. Set arrivalReminderChannel to "fcm".
   *
   * Keep this operation on the trusted backend; never place FCM server keys
   * inside the Flutter application. Enable it after backend/billing setup.
   */
}
