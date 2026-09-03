import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HotelGuestChatScreen extends StatefulWidget {
  const HotelGuestChatScreen({
    super.key,
    required this.chatId,
    required this.bookingId,
    required this.hotelId,
    required this.userId,
    required this.guestName,
  });

  final String chatId;
  final String bookingId;
  final String hotelId;
  final String userId;
  final String guestName;

  @override
  State<HotelGuestChatScreen> createState() =>
      _HotelGuestChatScreenState();
}

class _HotelGuestChatScreenState
    extends State<HotelGuestChatScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground =
      Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  bool _isSending = false;
  bool _chatLocked = false;
  bool _isTyping = false;
  String _hotelPhone = '';

  String _replyToMessageId = '';
  String _replyToText = '';
  String _replyToSender = '';

  Timer? _typingTimer;

  CollectionReference<Map<String, dynamic>>
      get _messagesCollection => _firestore
          .collection('hotel_booking_chats')
          .doc(widget.chatId)
          .collection('messages');

 @override
void initState() {
  super.initState();
  _ensureChatDocument();
  _loadBookingStatus();
  _markMessagesRead();
}

  @override
  void dispose() {
    _typingTimer?.cancel();
    _setHotelTyping(false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.guestName.trim().isEmpty
                  ? 'Guest Chat'
                  : widget.guestName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Booking #${_shortId(widget.bookingId)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _guestTypingIndicator(),
            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: _messagesCollection
                    .orderBy(
                      'createdAt',
                      descending: false,
                    )
                    .snapshots(),
                builder: (
                  context,
                  AsyncSnapshot<
                          QuerySnapshot<
                              Map<String, dynamic>>>
                      snapshot,
                ) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: yellow,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _messageState(
                      icon: Icons.error_outline,
                      title: 'Unable to Load Chat',
                      message: snapshot.error.toString(),
                    );
                  }

                  final docs =
                      (snapshot.data?.docs ??
                              <QueryDocumentSnapshot<
                                  Map<String, dynamic>>>[])
                          .where(
                            (document) =>
                                document.data()[
                                        'hiddenForHotel'] !=
                                    true,
                          )
                          .toList();

                  if (docs.isEmpty) {
                    return _messageState(
                      icon:
                          Icons.chat_bubble_outline,
                      title: 'No Messages Yet',
                      message:
                          'Send the first message to the guest.',
                    );
                  }

                  WidgetsBinding.instance
                      .addPostFrameCallback((_) {
                    _markMessagesRead();
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(
                        _scrollController
                            .position.maxScrollExtent,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {

                      return _messageBubble(
                        docs[index],
                      );
                    },
                  );
                },
              ),
            ),
            _chatLocked
    ? _lockedChatPanel()
    : _composer(),
          ],
        ),
      ),
    );
  }

  Widget _messageBubble(
    QueryDocumentSnapshot<Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data();
    final String senderType =
        data['senderRole']?.toString() ??
            data['senderType']?.toString() ??
            'system';

    final String text =
        data['message']?.toString() ??
            data['text']?.toString() ??
            '';

    final bool isHotelMessage =
        senderType == 'hotel' ||
            senderType == 'hotelAgent';

    final bool isSystem =
        senderType == 'system';

    final String messageId =
        data['messageId']?.toString() ??
            document.id;

    final String replyToText =
        data['replyToText']?.toString() ?? '';

    final String replyToSender =
        data['replyToSender']?.toString() ?? '';

    final bool isReadByGuest =
        data['isReadByGuest'] == true ||
            data['isRead'] == true;

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.only(
            bottom: 10,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: yellow.withValues(
              alpha: 0.10,
            ),
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: () {
        _showMessageActions(
          document: document,
          messageId: messageId,
          message: text,
          senderName:
              data['senderName']?.toString() ??
                  (isHotelMessage
                      ? 'Hotel'
                      : widget.guestName),
          isMine: isHotelMessage,
        );
      },
      child: Align(
      alignment: isHotelMessage
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width *
                  0.78,
        ),
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isHotelMessage
              ? yellow
              : darkCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(
              isHotelMessage ? 16 : 4,
            ),
            bottomRight: Radius.circular(
              isHotelMessage ? 4 : 16,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            if (replyToText.trim().isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(
                  bottom: 7,
                ),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isHotelMessage
                      ? Colors.black.withValues(
                          alpha: 0.10,
                        )
                      : Colors.white.withValues(
                          alpha: 0.06,
                        ),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      replyToSender.trim().isEmpty
                          ? 'Reply'
                          : replyToSender,
                      style: TextStyle(
                        color: isHotelMessage
                            ? Colors.black87
                            : yellow,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      replyToText,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isHotelMessage
                            ? Colors.black54
                            : Colors.grey,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              text,
              style: TextStyle(
                color: isHotelMessage
                    ? Colors.black
                    : Colors.white,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(data['createdAt']),
                  style: TextStyle(
                    color: isHotelMessage
                        ? Colors.black54
                        : Colors.grey,
                    fontSize: 9,
                  ),
                ),
                if (isHotelMessage) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isReadByGuest
                        ? Icons.done_all
                        : Icons.done,
                    size: 12,
                    color: isReadByGuest
                        ? Colors.blue
                        : Colors.black54,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
  Widget _lockedChatPanel() {
  final bool hasPhone =
      _hotelPhone.trim().isNotEmpty;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(
      16,
      14,
      16,
      16,
    ),
    decoration: BoxDecoration(
      color: darkCard,
      border: Border(
        top: BorderSide(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: yellow,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Chat Closed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        const Text(
          'The guest has checked in or this booking is no longer active. For room service and hotel assistance, contact the hotel reception.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: darkBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.support_agent,
                color: yellow,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hotel Reception',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      hasPhone
                          ? _hotelPhone
                          : 'Reception number unavailable',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                hasPhone ? _callHotelReception : null,
            icon: const Icon(
              Icons.call,
            ),
            label: const Text(
              'Call Hotel Reception',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        12,
      ),
      decoration: BoxDecoration(
        color: darkCard,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(
              alpha: 0.05,
            ),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyToMessageId.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(
                bottom: 8,
              ),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: darkBackground,
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: yellow.withValues(
                    alpha: 0.22,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.reply,
                    color: yellow,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyToSender,
                          style: const TextStyle(
                            color: yellow,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _replyToText,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _clearReply,
                    icon: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              textInputAction:
                  TextInputAction.newline,
              onChanged: _handleTypingChanged,
              style: const TextStyle(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText:
                    'Write a message...',
                hintStyle: const TextStyle(
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: darkBackground,
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed:
                _isSending ? null : _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: Colors.black,
            ),
            icon: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(
                    Icons.send,
                  ),
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: yellow,
                size: 46,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
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
      ),
    );
  }

  Future<void> _ensureChatDocument() async {
    await _firestore
        .collection('hotel_booking_chats')
        .doc(widget.chatId)
        .set(
      {
        'bookingId': widget.bookingId,
        'hotelId': widget.hotelId,
        'userId': widget.userId,
        'guestUserId': widget.userId,
        'guestName': widget.guestName,
        'hotelUnreadCount': 0,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
  Future<void> _loadBookingStatus() async {
  try {
    final booking = await _firestore
        .collection('hotel_bookings')
        .doc(widget.bookingId)
        .get();

    if (!booking.exists) return;

    final data = booking.data()!;

    final String status =
        data['bookingStatus']?.toString() ?? '';

    final String hotelId =
        data['hotelId']?.toString() ?? '';

    if (status == 'checked_out' ||
        status == 'completed' ||
        status == 'cancelled' ||
        status == 'rejected') {
      final hotelDoc = await _firestore
          .collection('hotels')
          .doc(hotelId)
          .get();

      if (mounted) {
        setState(() {
          _chatLocked = true;

          _hotelPhone =
              hotelDoc.data()?['phoneNumber']
                      ?.toString() ??
                  '';
        });
      }
    }
  } catch (_) {}
}

  Future<void> _markMessagesRead() async {
    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot = await _messagesCollection
              .where(
                'isReadByHotel',
                isEqualTo: false,
              )
              .get();

      final WriteBatch batch =
          _firestore.batch();

      for (final doc in snapshot.docs) {
        final String role =
            doc.data()['senderRole']?.toString() ??
                doc.data()['senderType']?.toString() ??
                '';

        if (role != 'guest' && role != 'user') {
          continue;
        }

        batch.set(
          doc.reference,
          <String, dynamic>{
            'isReadByHotel': true,
            'isRead': true,
            'readByHotelAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      batch.set(
        _firestore
            .collection('hotel_booking_chats')
            .doc(widget.chatId),
        <String, dynamic>{
          'hotelUnreadCount': 0,
          'hotelLastReadAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (_) {
      // Read receipts must not break the chat.
    }
  }

  Future<void> _sendMessage() async {
    final String text =
        _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in first.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final DocumentReference<
              Map<String, dynamic>>
          chatRef = _firestore
              .collection('hotel_booking_chats')
              .doc(widget.chatId);

      final WriteBatch batch =
          _firestore.batch();

      batch.set(
        chatRef,
        {
          'bookingId': widget.bookingId,
          'hotelId': widget.hotelId,
          'userId': widget.userId,
          'guestUserId': widget.userId,
          'guestName': widget.guestName,
          'lastMessage': text,
          'lastMessageBy': 'hotel',
          'lastMessageType': 'text',
          'lastAgentId': user.uid,
          'guestUnreadCount':
              FieldValue.increment(1),
          'hotelUnreadCount': 0,
          'hotelIsTyping': false,
          'lastMessageAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final DocumentReference<Map<String, dynamic>>
          messageReference =
          chatRef.collection('messages').doc();

      batch.set(
        messageReference,
        <String, dynamic>{
          'messageId': messageReference.id,
          'bookingId': widget.bookingId,
          'senderId': user.uid,
          'senderRole': 'hotel',
          'senderType': 'hotelAgent',
          'senderName': 'Hotel',
          'message': text,
          'text': text,
          'messageType': 'text',
          'isRead': false,
          'isReadByHotel': true,
          'isReadByGuest': false,
          'replyToMessageId':
              _replyToMessageId,
          'replyToText': _replyToText,
          'replyToSender':
              _replyToSender,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      _messageController.clear();
      _clearReply();
      await _setHotelTyping(false);
    } catch (error) {
      _showMessage(
        'Unable to send message: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Widget _guestTypingIndicator() {
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('hotel_booking_chats')
          .doc(widget.chatId)
          .snapshots(),
      builder: (context, snapshot) {
        final bool guestIsTyping =
            snapshot.data?.data()?['guestIsTyping'] ==
                true;

        if (!guestIsTyping) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
            14,
            8,
            14,
            0,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: yellow,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Guest is typing...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleTypingChanged(
    String value,
  ) {
    final bool shouldType =
        value.trim().isNotEmpty;

    if (shouldType != _isTyping) {
      _isTyping = shouldType;
      _setHotelTyping(shouldType);
    }

    _typingTimer?.cancel();

    if (shouldType) {
      _typingTimer = Timer(
        const Duration(seconds: 2),
        () {
          _isTyping = false;
          _setHotelTyping(false);
        },
      );
    }
  }

  Future<void> _setHotelTyping(
    bool value,
  ) async {
    try {
      await _firestore
          .collection('hotel_booking_chats')
          .doc(widget.chatId)
          .set(
        <String, dynamic>{
          'hotelIsTyping': value,
          'hotelTypingUpdatedAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Typing state must never block chat.
    }
  }

  void _showMessageActions({
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
    required String messageId,
    required String message,
    required String senderName,
    required bool isMine,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: darkCard,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(14),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.reply,
                    color: yellow,
                  ),
                  title: const Text(
                    'Reply',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                    );

                    setState(() {
                      _replyToMessageId =
                          messageId;
                      _replyToText = message;
                      _replyToSender =
                          senderName;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.orange,
                  ),
                  title: const Text(
                    'Delete for me',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(
                      sheetContext,
                    );

                    await document.reference.set(
                      <String, dynamic>{
                        'hiddenForHotel': true,
                        'updatedAt':
                            FieldValue
                                .serverTimestamp(),
                      },
                      SetOptions(merge: true),
                    );
                  },
                ),
                if (isMine)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.redAccent,
                    ),
                    title: const Text(
                      'Delete for everyone',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(
                        sheetContext,
                      );

                      await document.reference.set(
                        <String, dynamic>{
                          'message':
                              'This message was deleted.',
                          'text':
                              'This message was deleted.',
                          'isDeletedForEveryone':
                              true,
                          'deletedAt':
                              FieldValue
                                  .serverTimestamp(),
                          'updatedAt':
                              FieldValue
                                  .serverTimestamp(),
                        },
                        SetOptions(merge: true),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _clearReply() {
    if (!mounted) {
      _replyToMessageId = '';
      _replyToText = '';
      _replyToSender = '';
      return;
    }

    setState(() {
      _replyToMessageId = '';
      _replyToText = '';
      _replyToSender = '';
    });
  }

  String _formatTime(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) {
      return 'Sending...';
    }

    final String hour =
        date.hour.toString().padLeft(
              2,
              '0',
            );

    final String minute =
        date.minute.toString().padLeft(
              2,
              '0',
            );

    return '$hour:$minute';
  }

  String _shortId(String id) {
    if (id.length <= 8) {
      return id.toUpperCase();
    }

    return id
        .substring(0, 8)
        .toUpperCase();
  }
  Future<void> _callHotelReception() async {
  final String cleanPhone =
      _hotelPhone.replaceAll(
    RegExp(r'[^0-9+]'),
    '',
  );

  if (cleanPhone.isEmpty) {
    _showMessage(
      'Hotel reception number is unavailable.',
      isError: true,
    );
    return;
  }

  final Uri phoneUri = Uri(
    scheme: 'tel',
    path: cleanPhone,
  );

  try {
    final bool opened = await launchUrl(
      phoneUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      _showMessage(
        'Unable to open the phone dialer.',
        isError: true,
      );
    }
  } catch (error) {
    _showMessage(
      'Unable to call hotel: $error',
      isError: true,
    );
  }
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

