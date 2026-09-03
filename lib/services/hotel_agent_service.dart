import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/hotel_agent.dart';

class HotelAgentService {
  HotelAgentService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String agentsCollection =
      'hotel_agents';

  static const String hotelChatsCollection =
      'hotel_chats';

  static const String hotelChatMessagesCollection =
      'messages';

  // =========================================================
  // AGENT READ
  // =========================================================

  Future<HotelAgent?> getAgent(
    String agentId,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection(agentsCollection)
            .doc(agentId)
            .get();

    if (!snapshot.exists ||
        snapshot.data() == null) {
      return null;
    }

    return HotelAgent.fromMap(
      snapshot.data()!,
      snapshot.id,
    );
  }

  Stream<List<HotelAgent>> hotelAgentsStream(
    String hotelId,
  ) {
    return _firestore
        .collection(agentsCollection)
        .where(
          'hotelId',
          isEqualTo: hotelId,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => HotelAgent.fromMap(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Stream<List<HotelAgent>>
      activeHotelAgentsStream(
    String hotelId,
  ) {
    return _firestore
        .collection(agentsCollection)
        .where(
          'hotelId',
          isEqualTo: hotelId,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .where(
          'isApprovedByAdmin',
          isEqualTo: true,
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => HotelAgent.fromMap(
                  doc.data(),
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Future<bool> canAgentAccessHotelPanel(
    String agentId,
  ) async {
    final HotelAgent? agent =
        await getAgent(agentId);

    return agent?.canAccessHotelPanel ?? false;
  }

  // =========================================================
  // ADMIN AGENT MANAGEMENT
  // =========================================================
  //
  // Firestore Security Rules must restrict these methods to
  // authenticated SWAT RIDE admins only.
  //
  // Disabling an agent NEVER disables the hotel.
  // Other approved and active agents keep working normally.
  //
  // =========================================================

  Future<String> adminCreateAgent(
    HotelAgent agent,
  ) async {
    final Map<String, dynamic> data = {
      ...agent.toMap(),
      'isActive': false,
      'isApprovedByAdmin': false,
      'createdAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    final DocumentReference<Map<String, dynamic>>
        document = await _firestore
            .collection(agentsCollection)
            .add(data);

    return document.id;
  }

  Future<void> adminApproveAgent({
    required String agentId,
    required String adminId,
  }) async {
    await _firestore
        .collection(agentsCollection)
        .doc(agentId)
        .update({
      'isApprovedByAdmin': true,
      'isActive': true,
      'activatedByAdminId': adminId,
      'deactivatedByAdminId': '',
      'deactivationReason': '',
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminActivateAgent({
    required String agentId,
    required String adminId,
  }) async {
    await _firestore
        .collection(agentsCollection)
        .doc(agentId)
        .update({
      'isActive': true,
      'activatedByAdminId': adminId,
      'deactivatedByAdminId': '',
      'deactivationReason': '',
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminDeactivateAgent({
    required String agentId,
    required String adminId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError(
        'Agent deactivation reason is required.',
      );
    }

    await _firestore
        .collection(agentsCollection)
        .doc(agentId)
        .update({
      'isActive': false,
      'deactivatedByAdminId': adminId,
      'deactivationReason':
          reason.trim(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminRejectAgent({
    required String agentId,
    required String adminId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw ArgumentError(
        'Agent rejection reason is required.',
      );
    }

    await _firestore
        .collection(agentsCollection)
        .doc(agentId)
        .update({
      'isApprovedByAdmin': false,
      'isActive': false,
      'deactivatedByAdminId': adminId,
      'deactivationReason':
          reason.trim(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminUpdateAgentRole({
    required String agentId,
    required String role,
  }) async {
    await _firestore
        .collection(agentsCollection)
        .doc(agentId)
        .update({
      'role': role,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminUpdateAgentPermissions({
    required String agentId,
    required List<String> permissions,
  }) async {
    await _firestore
        .collection(agentsCollection)
        .doc(agentId)
        .update({
      'permissions': permissions,
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> adminDeleteAgent(
    String agentId,
  ) async {
    await _firestore
        .collection(agentsCollection)
        .doc(agentId)
        .delete();
  }

  // =========================================================
  // HOTEL OWNER / MANAGER AGENT CREATION REQUEST
  // =========================================================
  //
  // Owner may submit a new staff member, but the agent cannot
  // access the partner panel until SWAT RIDE admin approval.
  //
  // =========================================================

  Future<String> submitAgentRequest(
    HotelAgent agent,
  ) async {
    final Map<String, dynamic> data = {
      ...agent.toMap(),
      'isActive': false,
      'isApprovedByAdmin': false,
      'createdAt':
          FieldValue.serverTimestamp(),
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    final DocumentReference<Map<String, dynamic>>
        document = await _firestore
            .collection(agentsCollection)
            .add(data);

    return document.id;
  }

  // =========================================================
  // AUTO-REPLY CHAT
  // =========================================================
  //
  // This is real Firestore chat structure and does not depend
  // on payment billing or Firebase Storage.
  //
  // Booking accept/reject must still be performed by an
  // authorized hotel agent. Auto replies only acknowledge,
  // inform and guide the user.
  //
  // =========================================================

  Future<void> createBookingReceivedAutoReply({
    required String chatId,
    required String bookingId,
    required String hotelId,
    required String userId,
  }) async {
    await _sendSystemMessage(
      chatId: chatId,
      bookingId: bookingId,
      hotelId: hotelId,
      userId: userId,
      messageType: 'booking_received',
      text:
          'Your booking request has been received. The hotel is reviewing it and will respond shortly.',
    );
  }

  Future<void> createWaitingAutoReply({
    required String chatId,
    required String bookingId,
    required String hotelId,
    required String userId,
  }) async {
    await _sendSystemMessage(
      chatId: chatId,
      bookingId: bookingId,
      hotelId: hotelId,
      userId: userId,
      messageType: 'waiting_for_hotel',
      text:
          'We are still waiting for the hotel confirmation. An active hotel agent has been notified.',
    );
  }

  Future<void> createNoAgentResponseAutoReply({
    required String chatId,
    required String bookingId,
    required String hotelId,
    required String userId,
  }) async {
    await _sendSystemMessage(
      chatId: chatId,
      bookingId: bookingId,
      hotelId: hotelId,
      userId: userId,
      messageType: 'agent_response_delayed',
      text:
          'The hotel response is delayed. The hotel owner and other active agents have been alerted.',
    );
  }

  Future<void> sendAgentQuickReply({
    required String chatId,
    required String bookingId,
    required String hotelId,
    required String userId,
    required String agentId,
    required String quickReplyCode,
  }) async {
    final HotelAgent? agent =
        await getAgent(agentId);

    if (agent == null ||
        !agent.hasPermission(
          'chatWithGuests',
        )) {
      throw StateError(
        'This agent is not allowed to chat with guests.',
      );
    }

    final Map<String, String> replies = {
      'booking_accepted':
          'Your booking has been accepted by the hotel.',
      'room_not_available':
          'The selected room is not available for these dates.',
      'please_wait':
          'Please wait while the hotel checks your booking.',
      'upgrade_available':
          'An upgraded room option is available.',
      'contact_hotel':
          'Please contact the hotel for further assistance.',
      'room_ready':
          'Your room is ready.',
      'early_check_in_approved':
          'Your early check-in request has been approved.',
      'late_check_out_approved':
          'Your late check-out request has been approved.',
    };

    final String? text =
        replies[quickReplyCode];

    if (text == null) {
      throw ArgumentError(
        'Unknown quick reply code.',
      );
    }

    await _sendAgentMessage(
      chatId: chatId,
      bookingId: bookingId,
      hotelId: hotelId,
      userId: userId,
      agentId: agentId,
      text: text,
      messageType: quickReplyCode,
    );
  }

  Future<void> sendAgentCustomMessage({
    required String chatId,
    required String bookingId,
    required String hotelId,
    required String userId,
    required String agentId,
    required String text,
  }) async {
    final String cleanText = text.trim();

    if (cleanText.isEmpty) {
      throw ArgumentError(
        'Message cannot be empty.',
      );
    }

    final HotelAgent? agent =
        await getAgent(agentId);

    if (agent == null ||
        !agent.hasPermission(
          'chatWithGuests',
        )) {
      throw StateError(
        'This agent is not allowed to chat with guests.',
      );
    }

    await _sendAgentMessage(
      chatId: chatId,
      bookingId: bookingId,
      hotelId: hotelId,
      userId: userId,
      agentId: agentId,
      text: cleanText,
      messageType: 'custom',
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      hotelChatMessagesStream(
    String chatId,
  ) {
    return _firestore
        .collection(hotelChatsCollection)
        .doc(chatId)
        .collection(hotelChatMessagesCollection)
        .orderBy(
          'createdAt',
          descending: false,
        )
        .snapshots();
  }

  Future<void> _sendSystemMessage({
    required String chatId,
    required String bookingId,
    required String hotelId,
    required String userId,
    required String messageType,
    required String text,
  }) async {
    final DocumentReference<Map<String, dynamic>>
        chatRef = _firestore
            .collection(hotelChatsCollection)
            .doc(chatId);

    final DocumentReference<Map<String, dynamic>>
        messageRef = chatRef
            .collection(
              hotelChatMessagesCollection,
            )
            .doc();

    final WriteBatch batch =
        _firestore.batch();

    batch.set(
      chatRef,
      {
        'bookingId': bookingId,
        'hotelId': hotelId,
        'userId': userId,
        'lastMessage': text,
        'lastMessageType': messageType,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      messageRef,
      {
        'senderType': 'system',
        'senderId': 'auto_agent',
        'messageType': messageType,
        'text': text,
        'isRead': false,
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  Future<void> _sendAgentMessage({
    required String chatId,
    required String bookingId,
    required String hotelId,
    required String userId,
    required String agentId,
    required String text,
    required String messageType,
  }) async {
    final DocumentReference<Map<String, dynamic>>
        chatRef = _firestore
            .collection(hotelChatsCollection)
            .doc(chatId);

    final DocumentReference<Map<String, dynamic>>
        messageRef = chatRef
            .collection(
              hotelChatMessagesCollection,
            )
            .doc();

    final WriteBatch batch =
        _firestore.batch();

    batch.set(
      chatRef,
      {
        'bookingId': bookingId,
        'hotelId': hotelId,
        'userId': userId,
        'lastMessage': text,
        'lastMessageType': messageType,
        'lastAgentId': agentId,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    batch.set(
      messageRef,
      {
        'senderType': 'hotelAgent',
        'senderId': agentId,
        'messageType': messageType,
        'text': text,
        'isRead': false,
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }
}
