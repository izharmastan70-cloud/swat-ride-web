import 'package:cloud_firestore/cloud_firestore.dart';

/// Caps concurrent phone-call dispatch agents at [maxConcurrentAgents] using
/// a Firestore-enforced seat counter. Stale seats (no heartbeat) are
/// reclaimed so a crashed/closed session does not permanently hold a seat.
class AgentSeatService {
  AgentSeatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int maxConcurrentAgents = 5;
  static const Duration staleAfter = Duration(minutes: 3);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _seats =>
      _firestore.collection('phone_call_agent_seats');

  DocumentReference<Map<String, dynamic>> get _counter =>
      _firestore.collection('phone_call_agent_seat_capacity').doc('counter');

  /// Reserves a seat for [agentId]. Throws [AgentSeatLimitException] when all
  /// [maxConcurrentAgents] seats are occupied by agents with a recent
  /// heartbeat.
  Future<void> joinSeat({
    required String agentId,
    required String agentName,
  }) async {
    await _releaseStaleSeats();

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> counterSnapshot =
          await transaction.get(_counter);
      final DocumentReference<Map<String, dynamic>> seatReference = _seats
          .doc(agentId);
      final DocumentSnapshot<Map<String, dynamic>> seatSnapshot =
          await transaction.get(seatReference);

      final bool alreadyOnline =
          seatSnapshot.exists && seatSnapshot.data()?['status'] == 'online';
      int activeSeatCount =
          (counterSnapshot.data()?['activeSeatCount'] as num?)?.toInt() ?? 0;

      if (!alreadyOnline) {
        if (activeSeatCount >= maxConcurrentAgents) {
          throw const AgentSeatLimitException();
        }
        activeSeatCount += 1;
      }

      transaction.set(seatReference, <String, dynamic>{
        'agentId': agentId,
        'agentName': agentName,
        'status': 'online',
        'joinedAt': seatSnapshot.data()?['joinedAt'] ?? FieldValue.serverTimestamp(),
        'lastHeartbeatAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(_counter, <String, dynamic>{
        'activeSeatCount': activeSeatCount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> sendHeartbeat(String agentId) async {
    await _seats.doc(agentId).set(<String, dynamic>{
      'lastHeartbeatAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> leaveSeat(String agentId) => _leaveSeatById(agentId);

  Stream<int> watchActiveSeatCount() {
    return _counter.snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> snapshot) =>
          (snapshot.data()?['activeSeatCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> _releaseStaleSeats() async {
    final DateTime cutoff = DateTime.now().subtract(staleAfter);
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _seats.get();

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      final Map<String, dynamic> data = doc.data();
      if (data['status'] != 'online') continue;

      final Timestamp? lastHeartbeat = data['lastHeartbeatAt'] as Timestamp?;
      if (lastHeartbeat != null && lastHeartbeat.toDate().isAfter(cutoff)) {
        continue;
      }

      await _leaveSeatById(doc.id);
    }
  }

  Future<void> _leaveSeatById(String agentId) async {
    final DocumentReference<Map<String, dynamic>> seatReference = _seats.doc(
      agentId,
    );

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> seatSnapshot =
          await transaction.get(seatReference);
      if (!seatSnapshot.exists || seatSnapshot.data()?['status'] != 'online') {
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> counterSnapshot =
          await transaction.get(_counter);
      final int activeSeatCount =
          (counterSnapshot.data()?['activeSeatCount'] as num?)?.toInt() ?? 0;

      transaction.set(seatReference, <String, dynamic>{
        'status': 'offline',
        'leftAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(_counter, <String, dynamic>{
        'activeSeatCount': activeSeatCount > 0 ? activeSeatCount - 1 : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}

class AgentSeatLimitException implements Exception {
  const AgentSeatLimitException();

  @override
  String toString() =>
      '${AgentSeatService.maxConcurrentAgents} agents are already online. '
      'Please try again shortly.';
}
