import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/hotel_agent.dart';

class HotelAgentManagementService {
  HotelAgentManagementService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName =
      'hotel_agents';

  Stream<List<HotelAgent>> hotelAgentsStream(
    String hotelId,
  ) {
    return _firestore
        .collection(collectionName)
        .where(
          'hotelId',
          isEqualTo: hotelId,
        )
        .snapshots()
        .map(
          (snapshot) {
            final List<HotelAgent> agents =
                snapshot.docs
                    .map(
                      (doc) => HotelAgent.fromMap(
                        doc.data(),
                        doc.id,
                      ),
                    )
                    .toList();

            agents.sort(
              (a, b) {
                final DateTime aDate =
                    a.updatedAt ??
                        a.createdAt ??
                        DateTime.fromMillisecondsSinceEpoch(
                          0,
                        );

                final DateTime bDate =
                    b.updatedAt ??
                        b.createdAt ??
                        DateTime.fromMillisecondsSinceEpoch(
                          0,
                        );

                return bDate.compareTo(aDate);
              },
            );

            return agents;
          },
        );
  }

  Future<String> submitAgentRequest({
    required HotelAgent agent,
    required String requestedByOwnerId,
  }) async {
    _validateAgent(agent);

    final DocumentReference<Map<String, dynamic>>
        document = await _firestore
            .collection(collectionName)
            .add({
      ...agent.toMap(),
      'isActive': false,
      'isApprovedByAdmin': false,
      'requestedByOwnerId':
          requestedByOwnerId,
      'requestStatus': 'pending',
      'createdAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Future<void> updatePendingAgent({
    required HotelAgent agent,
    required String requestedByOwnerId,
  }) async {
    if (agent.id.trim().isEmpty) {
      throw ArgumentError(
        'Agent ID is required.',
      );
    }

    _validateAgent(agent);

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(collectionName)
            .doc(agent.id)
            .get();

    if (!snapshot.exists ||
        snapshot.data() == null) {
      throw StateError(
        'Agent request was not found.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data()!;

    if (data['requestedByOwnerId'] !=
        requestedByOwnerId) {
      throw StateError(
        'You cannot update this agent request.',
      );
    }

    if (data['isApprovedByAdmin'] == true) {
      throw StateError(
        'Approved agents can only be changed by SWAT RIDE admin.',
      );
    }

    await snapshot.reference.update({
      'userId': agent.userId,
      'fullName': agent.fullName,
      'phoneNumber': agent.phoneNumber,
      'email': agent.email,
      'role': agent.role,
      'permissions': agent.permissions,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelPendingRequest({
    required String agentId,
    required String requestedByOwnerId,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(collectionName)
            .doc(agentId)
            .get();

    if (!snapshot.exists ||
        snapshot.data() == null) {
      return;
    }

    final Map<String, dynamic> data =
        snapshot.data()!;

    if (data['requestedByOwnerId'] !=
        requestedByOwnerId) {
      throw StateError(
        'You cannot remove this agent request.',
      );
    }

    if (data['isApprovedByAdmin'] == true) {
      throw StateError(
        'Approved agents must be disabled or removed by SWAT RIDE admin.',
      );
    }

    await snapshot.reference.delete();
  }

  Future<void> requestAgentDeactivation({
    required String agentId,
    required String requestedByOwnerId,
    required String reason,
  }) async {
    final String cleanReason =
        reason.trim();

    if (cleanReason.isEmpty) {
      throw ArgumentError(
        'Deactivation reason is required.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        reference = _firestore
            .collection(collectionName)
            .doc(agentId);

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot = await reference.get();

    if (!snapshot.exists ||
        snapshot.data() == null) {
      throw StateError(
        'Agent was not found.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data()!;

    if (data['hotelId'] == null) {
      throw StateError(
        'Agent hotel information is missing.',
      );
    }

    await reference.update({
      'ownerDeactivationRequested': true,
      'ownerDeactivationReason':
          cleanReason,
      'ownerDeactivationRequestedBy':
          requestedByOwnerId,
      'ownerDeactivationRequestedAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });

    await _firestore
        .collection('admin_notifications')
        .add({
      'type':
          'hotel_agent_deactivation_request',
      'agentId': agentId,
      'hotelId': data['hotelId'],
      'requestedByOwnerId':
          requestedByOwnerId,
      'reason': cleanReason,
      'isRead': false,
      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  void _validateAgent(
    HotelAgent agent,
  ) {
    if (agent.hotelId.trim().isEmpty) {
      throw ArgumentError(
        'Hotel ID is required.',
      );
    }

    if (agent.fullName.trim().isEmpty) {
      throw ArgumentError(
        'Agent name is required.',
      );
    }

    if (agent.phoneNumber.trim().isEmpty) {
      throw ArgumentError(
        'Agent phone number is required.',
      );
    }

    if (agent.role.trim().isEmpty) {
      throw ArgumentError(
        'Agent role is required.',
      );
    }

    if (agent.permissions.isEmpty) {
      throw ArgumentError(
        'Select at least one permission.',
      );
    }
  }
}
