import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/agent_call_ride_booking_idempotency_reservation.dart';
import 'agent_call_ride_booking_authorization_broker.dart';

/// Persistent duplicate-suppression store for Phase 49 Call Booking.
///
/// IMPORTANT:
/// - Reservation is NOT authorization.
/// - It does NOT create a Ride.
/// - It does NOT prove caller identity.
/// - Production Firestore rules/backend execution must still prevent
///   unauthorized clients from treating this record as booking authority.
///
/// The transaction guarantees that one idempotency key cannot silently acquire
/// a different caller/contact/action binding.
class AgentCallRideBookingIdempotencyRepository
    implements AgentCallRideBookingIdempotencyReservationGateway {
  AgentCallRideBookingIdempotencyRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionPath = 'agent_call_ride_booking_idempotency';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionPath);

  @override
  Future<AgentCallRideBookingIdempotencyReservation> reserve({
    required String idempotencyKey,
    required String roleId,
    required String actionId,
    required String requestedBy,
    required String trustedCallerReferenceId,
    required String trustedContactReferenceId,
  }) async {
    final String key = idempotencyKey.trim();
    final String role = roleId.trim();
    final String action = actionId.trim();
    final String actor = requestedBy.trim();
    final String caller = trustedCallerReferenceId.trim();
    final String contact = trustedContactReferenceId.trim();

    if (key.isEmpty ||
        key.length > 200 ||
        role.isEmpty ||
        action.isEmpty ||
        actor.isEmpty ||
        caller.isEmpty ||
        contact.isEmpty) {
      throw const AgentCallRideBookingIdempotencyException(
        'Valid idempotency key and complete trusted binding are required.',
      );
    }

    final String reservationId = encodeIdempotencyKey(key);
    final DocumentReference<Map<String, dynamic>> reference = _collection.doc(
      reservationId,
    );

    return _firestore.runTransaction<
      AgentCallRideBookingIdempotencyReservation
    >((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
          .get(reference);

      if (snapshot.exists) {
        final AgentCallRideBookingIdempotencyReservation existing =
            _fromSnapshot(snapshot);

        if (existing.idempotencyKey != key ||
            !existing.matchesBinding(
              roleId: role,
              actionId: action,
              requestedBy: actor,
              trustedCallerReferenceId: caller,
              trustedContactReferenceId: contact,
            )) {
          throw const AgentCallRideBookingIdempotencyException(
            'Idempotency key is already bound to a different request.',
          );
        }

        return existing.copyWith(reusedExistingReservation: true);
      }

      final DateTime now = DateTime.now().toUtc();

      final AgentCallRideBookingIdempotencyReservation reservation =
          AgentCallRideBookingIdempotencyReservation(
            reservationId: reservationId,
            idempotencyKey: key,
            roleId: role,
            actionId: action,
            requestedBy: actor,
            trustedCallerReferenceId: caller,
            trustedContactReferenceId: contact,
            status: AgentCallRideBookingIdempotencyReservationStatus.reserved,
            createdAt: now,
            reusedExistingReservation: false,
          );

      reservation.validate();

      transaction.set(reference, <String, dynamic>{
        'reservationId': reservation.reservationId,
        'idempotencyKey': reservation.idempotencyKey,
        'roleId': reservation.roleId,
        'actionId': reservation.actionId,
        'requestedBy': reservation.requestedBy,
        'trustedCallerReferenceId': reservation.trustedCallerReferenceId,
        'trustedContactReferenceId': reservation.trustedContactReferenceId,
        'status': reservation.status,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return reservation;
    });
  }

  static String encodeIdempotencyKey(String key) {
    final String normalized = key.trim();

    if (normalized.isEmpty || normalized.length > 200) {
      throw const AgentCallRideBookingIdempotencyException(
        'Invalid idempotency key.',
      );
    }

    return base64Url.encode(utf8.encode(normalized)).replaceAll('=', '');
  }

  AgentCallRideBookingIdempotencyReservation _fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};

    final AgentCallRideBookingIdempotencyReservation reservation =
        AgentCallRideBookingIdempotencyReservation(
          reservationId: (data['reservationId'] ?? snapshot.id)
              .toString()
              .trim(),
          idempotencyKey: (data['idempotencyKey'] ?? '').toString().trim(),
          roleId: (data['roleId'] ?? '').toString().trim(),
          actionId: (data['actionId'] ?? '').toString().trim(),
          requestedBy: (data['requestedBy'] ?? '').toString().trim(),
          trustedCallerReferenceId: (data['trustedCallerReferenceId'] ?? '')
              .toString()
              .trim(),
          trustedContactReferenceId: (data['trustedContactReferenceId'] ?? '')
              .toString()
              .trim(),
          status:
              (data['status'] ??
                      AgentCallRideBookingIdempotencyReservationStatus.reserved)
                  .toString()
                  .trim(),
          createdAt: _dateTime(data['createdAt']),
          reusedExistingReservation: true,
        );

    reservation.validate();
    return reservation;
  }

  DateTime _dateTime(dynamic value) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  bool get createsRide => false;
  bool get changesPayment => false;
  bool get changesDriverState => false;
  bool get sendsSms => false;
  bool get isAuthorizationSource => false;

  /// This Flutter Firestore repository is retained only as a bounded
  /// pre-production/test implementation of duplicate suppression.
  ///
  /// Production Call Ride Booking must replace this with trusted backend
  /// atomic idempotency persistence. Firestore client rules intentionally
  /// deny access to this collection.
  bool get productionClientPersistenceAllowed => false;
  bool get requiresTrustedBackendReplacementForProduction => true;
  bool get firestoreClientAccessMustRemainDenied => true;
  bool get productionBookingAuthority => false;
}
