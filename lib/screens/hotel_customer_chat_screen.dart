import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HotelCustomerChatScreen extends StatefulWidget {
  const HotelCustomerChatScreen({
    super.key,
    required this.booking,
  });

  final Map<String, dynamic> booking;

  @override
  State<HotelCustomerChatScreen> createState() =>
      _HotelCustomerChatScreenState();
}

class _HotelCustomerChatScreenState
    extends State<HotelCustomerChatScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  Timer? _typingTimer;

  bool _isSending = false;
  bool _isTyping = false;
  String _replyToMessageId = '';
  String _replyToText = '';
  String _replyToSender = '';

  User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  String get _bookingId =>
      widget.booking['bookingId']?.toString() ??
      widget.booking['id']?.toString() ??
      '';

  String get _hotelId =>
      widget.booking['hotelId']?.toString() ?? '';

  String get _hotelName =>
      widget.booking['hotelName']?.toString() ??
      'Hotel';

  String get _guestName =>
      widget.booking['guestName']?.toString() ??
      _currentUser?.displayName ??
      'Guest';

  String get _bookingStatus =>
      widget.booking['bookingStatus']?.toString() ??
      'pending';

  bool get _chatClosed {
    const Set<String> closedStatuses = <String>{
      'cancelled',
      'rejected',
      'completed',
      'checked_out',
    };

    return closedStatuses.contains(_bookingStatus);
  }

  DocumentReference<Map<String, dynamic>>
      get _chatReference => _firestore
          .collection('hotel_booking_chats')
          .doc(_bookingId);

  CollectionReference<Map<String, dynamic>>
      get _messagesReference =>
          _chatReference.collection('messages');

  @override
  void initState() {
    super.initState();
    _markHotelMessagesRead();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _setGuestTyping(false);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _currentUser;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              _hotelName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _bookingId.isEmpty
                  ? 'Hotel support chat'
                  : 'Booking: $_bookingId',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      body: user == null
          ? _messageState(
              icon: Icons.lock_outline,
              title: 'Login Required',
              message:
                  'Please log in to chat with the hotel.',
            )
          : _bookingId.isEmpty
              ? _messageState(
                  icon: Icons.error_outline,
                  title: 'Booking Not Available',
                  message:
                      'A valid booking is required to open hotel chat.',
                )
              : SafeArea(
                  child: Column(
                    children: [
                      _bookingBanner(),

                      _hotelTypingIndicator(),

                      Expanded(
                        child: StreamBuilder<
                            QuerySnapshot<
                                Map<String, dynamic>>>(
                          stream: _messagesReference
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
                                child:
                                    CircularProgressIndicator(
                                  color: yellow,
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return _messageState(
                                icon:
                                    Icons.error_outline,
                                title:
                                    'Unable to Load Messages',
                                message:
                                    snapshot.error.toString(),
                              );
                            }

                            final List<
                                    QueryDocumentSnapshot<
                                        Map<String, dynamic>>>
                                messages =
                                (snapshot.data?.docs ??
                                        <QueryDocumentSnapshot<
                                            Map<String, dynamic>>>[])
                                    .where(
                                      (document) =>
                                          document.data()[
                                                  'hiddenForGuest'] !=
                                              true,
                                    )
                                    .toList();

                            WidgetsBinding.instance
                                .addPostFrameCallback(
                              (_) {
                                _scrollToBottom();
                                _markHotelMessagesRead();
                              },
                            );

                            if (messages.isEmpty) {
                              return _messageState(
                                icon:
                                    Icons.chat_bubble_outline,
                                title:
                                    'Start Conversation',
                                message:
                                    'Ask the hotel about check-in, room details, cancellation, late check-out or other booking support.',
                              );
                            }

                            return ListView.builder(
                              controller:
                                  _scrollController,
                              padding:
                                  const EdgeInsets.fromLTRB(
                                14,
                                16,
                                14,
                                16,
                              ),
                              itemCount: messages.length,
                              itemBuilder: (
                                context,
                                index,
                              ) {
                                return _messageBubble(
                                  messages[index],
                                  user.uid,
                                );
                              },
                            );
                          },
                        ),
                      ),

                      if (_chatClosed)
                        _closedChatNotice()
                      else
                        _composer(),
                    ],
                  ),
                ),
    );
  }

  Widget _bookingBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        14,
        10,
        14,
        0,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hotel_outlined,
            color: yellow,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chat directly with $_hotelName about this booking.',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
          _statusBadge(_bookingStatus),
        ],
      ),
    );
  }

  Widget _messageBubble(
    QueryDocumentSnapshot<Map<String, dynamic>>
        document,
    String currentUserId,
  ) {
    final Map<String, dynamic> data =
        document.data();

    final String senderId =
        data['senderId']?.toString() ?? '';

    final String senderRole =
        data['senderRole']?.toString() ??
            'hotel';

    final String message =
        data['message']?.toString() ?? '';

    final DateTime createdAt =
        _readDateTime(data['createdAt']);

    final bool isMine =
        senderId == currentUserId ||
        senderRole == 'guest';

    final String messageId =
        data['messageId']?.toString() ??
            document.id;

    final String replyToText =
        data['replyToText']?.toString() ?? '';

    final String replyToSender =
        data['replyToSender']?.toString() ?? '';

    final bool isReadByHotel =
        data['isReadByHotel'] == true;

    final bool isReadByGuest =
        data['isReadByGuest'] == true;

    return GestureDetector(
      onLongPress: () {
        _showMessageActions(
          document: document,
          messageId: messageId,
          message: message,
          senderName:
              data['senderName']?.toString() ??
                  (isMine ? _guestName : _hotelName),
          isMine: isMine,
        );
      },
      child: Align(
      alignment: isMine
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
        padding: const EdgeInsets.fromLTRB(
          13,
          10,
          13,
          8,
        ),
        decoration: BoxDecoration(
          color: isMine ? yellow : darkCard,
          borderRadius: BorderRadius.only(
            topLeft:
                const Radius.circular(16),
            topRight:
                const Radius.circular(16),
            bottomLeft: Radius.circular(
              isMine ? 16 : 4,
            ),
            bottomRight: Radius.circular(
              isMine ? 4 : 16,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (replyToText.trim().isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(
                  bottom: 7,
                ),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMine
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
                        color: isMine
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
                        color: isMine
                            ? Colors.black54
                            : Colors.grey,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message,
              style: TextStyle(
                color: isMine
                    ? Colors.black
                    : Colors.white,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(createdAt),
                  style: TextStyle(
                    color: isMine
                        ? Colors.black54
                        : Colors.grey,
                    fontSize: 8,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isReadByHotel
                        ? Icons.done_all
                        : Icons.done,
                    size: 12,
                    color: isReadByHotel
                        ? Colors.blue
                        : Colors.black54,
                  ),
                ] else if (isReadByGuest) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all,
                    size: 12,
                    color: Colors.blue,
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

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        12,
      ),
      decoration: const BoxDecoration(
        color: darkBackground,
        border: Border(
          top: BorderSide(
            color: Colors.white10,
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
                color: darkCard,
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
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              textCapitalization:
                  TextCapitalization.sentences,
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
                fillColor: darkCard,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          IconButton.filled(
            onPressed:
                _isSending ? null : _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: Colors.black,
              disabledBackgroundColor:
                  Colors.grey.shade700,
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
                : const Icon(Icons.send),
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _closedChatNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      color: darkCard,
      child: const Text(
        'This booking is closed. Chat history remains available, but new messages are disabled.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey,
          fontSize: 11,
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final User? user = _currentUser;

    if (user == null) {
      _showMessage(
        'Please log in first.',
        isError: true,
      );
      return;
    }

    final String message =
        _messageController.text.trim();

    if (message.isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final WriteBatch batch =
          _firestore.batch();

      batch.set(
        _chatReference,
        <String, dynamic>{
          'bookingId': _bookingId,
          'hotelId': _hotelId,
          'hotelName': _hotelName,
          'guestUserId': user.uid,
          'guestName': _guestName,
          'bookingStatus':
              _bookingStatus,
          'lastMessage': message,
          'lastMessageBy': 'guest',
          'lastMessageAt':
              FieldValue.serverTimestamp(),
          'guestUnreadCount': 0,
          'hotelUnreadCount':
              FieldValue.increment(1),
          'guestIsTyping': false,
          'isClosed': _chatClosed,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final DocumentReference<Map<String, dynamic>>
          messageReference =
          _messagesReference.doc();

      batch.set(
        messageReference,
        <String, dynamic>{
          'messageId': messageReference.id,
          'bookingId': _bookingId,
          'senderId': user.uid,
          'senderRole': 'guest',
          'senderName': _guestName,
          'message': message,
          'messageType': 'text',
          'isReadByGuest': true,
          'isReadByHotel': false,
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

      if (_hotelId.isNotEmpty) {
        final DocumentReference<Map<String, dynamic>>
            notificationReference = _firestore
                .collection(
                  'hotel_notifications',
                )
                .doc();

        batch.set(
          notificationReference,
          <String, dynamic>{
            'hotelId': _hotelId,
            'type': 'guest_message',
            'title': 'New Guest Message',
            'message':
                '$_guestName sent a message for booking $_bookingId.',
            'bookingId': _bookingId,
            'chatId': _bookingId,
            'isRead': false,
            'createdAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      _messageController.clear();
      _clearReply();
      await _setGuestTyping(false);
      _scrollToBottom();
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

  Widget _hotelTypingIndicator() {
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: _chatReference.snapshots(),
      builder: (context, snapshot) {
        final bool hotelIsTyping =
            snapshot.data?.data()?['hotelIsTyping'] ==
                true;

        if (!hotelIsTyping) {
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
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: yellow,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Hotel is typing...',
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
      _setGuestTyping(shouldType);
    }

    _typingTimer?.cancel();

    if (shouldType) {
      _typingTimer = Timer(
        const Duration(seconds: 2),
        () {
          _isTyping = false;
          _setGuestTyping(false);
        },
      );
    }
  }

  Future<void> _setGuestTyping(
    bool value,
  ) async {
    if (_bookingId.isEmpty) {
      return;
    }

    try {
      await _chatReference.set(
        <String, dynamic>{
          'guestIsTyping': value,
          'guestTypingUpdatedAt':
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

  Future<void> _markHotelMessagesRead() async {
    final User? user = _currentUser;

    if (user == null ||
        _bookingId.isEmpty) {
      return;
    }

    try {
      final snapshot =
          await _messagesReference
              .where(
                'isReadByGuest',
                isEqualTo: false,
              )
              .get();

      if (snapshot.docs.isEmpty) {
        await _chatReference.set(
          <String, dynamic>{
            'guestUnreadCount': 0,
            'guestLastReadAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return;
      }

      final WriteBatch batch =
          _firestore.batch();

      for (final document
          in snapshot.docs) {
        batch.set(
          document.reference,
          <String, dynamic>{
            'isReadByGuest': true,
            'readByGuestAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      batch.set(
        _chatReference,
        <String, dynamic>{
          'guestUnreadCount': 0,
          'guestLastReadAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (_) {
      // Read receipts must not break the screen.
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
                        'hiddenForGuest': true,
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
                    subtitle: const Text(
                      'Message text will be replaced.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
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

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.animateTo(
      _scrollController
          .position.maxScrollExtent,
      duration:
          const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    final Color color =
        _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.13,
        ),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: SingleChildScrollView(
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
            children: [
              Icon(
                icon,
                color: yellow,
                size: 46,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign:
                    TextAlign.center,
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
                textAlign:
                    TextAlign.center,
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

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'confirmed':
      case 'checked_in':
      case 'active':
      case 'in_stay':
        return Colors.green;
      case 'completed':
      case 'checked_out':
        return Colors.blueGrey;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(
    String status,
  ) {
    switch (status) {
      case 'pending_hotel_confirmation':
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'checked_in':
      case 'active':
      case 'in_stay':
        return 'Active';
      case 'completed':
      case 'checked_out':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  DateTime _readDateTime(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(
            0,
          );
    }

    return DateTime.fromMillisecondsSinceEpoch(
      0,
    );
  }

  String _formatTime(
    DateTime value,
  ) {
    if (value.millisecondsSinceEpoch == 0) {
      return '';
    }

    final int hour12 =
        value.hour == 0
            ? 12
            : value.hour > 12
                ? value.hour - 12
                : value.hour;

    final String minute =
        value.minute.toString().padLeft(2, '0');

    final String period =
        value.hour >= 12 ? 'PM' : 'AM';

    return '$hour12:$minute $period';
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
