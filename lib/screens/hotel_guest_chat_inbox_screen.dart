import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'hotel_guest_chat_screen.dart';

class HotelGuestChatInboxScreen extends StatefulWidget {
  const HotelGuestChatInboxScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelGuestChatInboxScreen> createState() =>
      _HotelGuestChatInboxScreenState();
}

class _HotelGuestChatInboxScreenState
    extends State<HotelGuestChatInboxScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController =
      TextEditingController();

  String _selectedTab = 'active';
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Guest Chats',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _searchBox(),
            _tabs(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore
                    .collection('hotel_booking_chats')
                    .where('hotelId', isEqualTo: widget.hotelId)
                    .orderBy('updatedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: yellow),
                    );
                  }

                  if (snapshot.hasError) {
                    return _emptyState(
                      icon: Icons.error_outline,
                      title: 'Unable to Load Chats',
                      message: snapshot.error.toString(),
                    );
                  }

                  final docs = snapshot.data?.docs ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                  if (docs.isEmpty) {
                    return _emptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'No Guest Chats',
                      message:
                          'Guest conversations will appear here after hotel bookings are created.',
                    );
                  }

                  return FutureBuilder<List<_ChatItem>>(
                    future: _prepareItems(docs),
                    builder: (context, itemSnapshot) {
                      if (itemSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: yellow),
                        );
                      }

                      if (itemSnapshot.hasError) {
                        return _emptyState(
                          icon: Icons.error_outline,
                          title: 'Unable to Prepare Chats',
                          message: itemSnapshot.error.toString(),
                        );
                      }

                      final allItems =
                          itemSnapshot.data ?? <_ChatItem>[];

                      final filtered = allItems.where((item) {
                        final tabMatch = _selectedTab == 'active'
                            ? item.isActive
                            : !item.isActive;

                        final query = _searchText.trim().toLowerCase();

                        final searchMatch = query.isEmpty ||
                            item.guestName.toLowerCase().contains(query) ||
                            item.roomName.toLowerCase().contains(query) ||
                            item.bookingId.toLowerCase().contains(query);

                        return tabMatch && searchMatch;
                      }).toList();

                      if (filtered.isEmpty) {
                        return _emptyState(
                          icon: _selectedTab == 'active'
                              ? Icons.mark_chat_unread_outlined
                              : Icons.archive_outlined,
                          title: _selectedTab == 'active'
                              ? 'No Active Chats'
                              : 'No Archived Chats',
                          message: _searchText.isEmpty
                              ? _selectedTab == 'active'
                                  ? 'Pending and confirmed booking chats will appear here.'
                                  : 'Checked-in, completed, cancelled and rejected chats will appear here.'
                              : 'No guest chat matches your search.',
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _chatCard(filtered[index]);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search guest, room or booking...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: yellow),
          suffixIcon: _searchText.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchText = '';
                    });
                  },
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
          filled: true,
          fillColor: darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              value: 'active',
              label: 'Active Chats',
              icon: Icons.chat_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _tabButton(
              value: 'archived',
              label: 'Archived',
              icon: Icons.archive_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final selected = _selectedTab == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = value;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? yellow : darkCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.black : yellow,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatCard(_ChatItem item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => HotelGuestChatScreen(
              chatId: item.chatId,
              bookingId: item.bookingId,
              hotelId: widget.hotelId,
              userId: item.userId,
              guestName: item.guestName,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(17),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: item.unreadCount > 0
                ? yellow.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: yellow.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: yellow,
                    size: 28,
                  ),
                ),
                if (item.unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.unreadCount > 99
                            ? '99+'
                            : '${item.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.guestName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: item.unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(item.updatedAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.lastMessage.trim().isEmpty
                        ? 'No message yet'
                        : item.lastMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: item.unreadCount > 0
                          ? Colors.white
                          : Colors.grey,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  if (item.guestIsTyping) ...[
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: yellow,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Guest is typing...',
                          style: TextStyle(
                            color: yellow,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (item.aiSuggestionAvailable) ...[
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.purpleAccent,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'AI reply suggestion ready',
                          style: TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _badge(Icons.bed_outlined, item.roomName),
                      _badge(
                        Icons.confirmation_number_outlined,
                        '#${_shortId(item.bookingId)}',
                      ),
                      _statusBadge(item.bookingStatus),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: yellow, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _emptyState({
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
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(icon, color: yellow, size: 48),
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
      ),
    );
  }

  Future<List<_ChatItem>> _prepareItems(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> chatDocs,
  ) async {
    final List<_ChatItem> items = <_ChatItem>[];

    for (final chatDoc in chatDocs) {
      final Map<String, dynamic> chatData =
          chatDoc.data();

      final String bookingId =
          chatData['bookingId']?.toString() ??
              chatDoc.id;

      final String userId =
          chatData['guestUserId']?.toString() ??
              chatData['userId']?.toString() ??
              '';

      Map<String, dynamic> bookingData =
          <String, dynamic>{};

      try {
        final snapshot = await _firestore
            .collection('hotel_bookings')
            .doc(bookingId)
            .get();

        bookingData =
            snapshot.data() ?? <String, dynamic>{};
      } catch (_) {
        // Inbox should still work from chat metadata.
      }

      final String status =
          bookingData['bookingStatus']?.toString() ??
              chatData['bookingStatus']?.toString() ??
              'pending';

      final String roomId =
          bookingData['roomId']?.toString() ??
              chatData['roomId']?.toString() ??
              '';

      final String roomName =
          bookingData['roomName']?.toString() ??
              bookingData['roomType']?.toString() ??
              chatData['roomName']?.toString() ??
              await _loadRoomName(roomId);

      final String guestName =
          chatData['guestName']?.toString().trim().isNotEmpty ==
                  true
              ? chatData['guestName'].toString()
              : bookingData['guestName']
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                      true
                  ? bookingData['guestName'].toString()
                  : await _loadGuestName(userId);

      int unreadCount =
          _readInt(chatData['hotelUnreadCount']);

      if (unreadCount == 0) {
        try {
          final unreadSnapshot =
              await chatDoc.reference
                  .collection('messages')
                  .where(
                    'isReadByHotel',
                    isEqualTo: false,
                  )
                  .get();

          unreadCount = unreadSnapshot.docs
              .where(
                (document) =>
                    document.data()['senderRole']
                            ?.toString() ==
                        'guest',
              )
              .length;
        } catch (_) {
          // Use metadata count if query/index is unavailable.
        }
      }

      items.add(
        _ChatItem(
          chatId: chatDoc.id,
          bookingId: bookingId,
          userId: userId,
          guestName: guestName,
          roomName: roomName,
          bookingStatus: status,
          lastMessage:
              chatData['lastMessage']?.toString() ?? '',
          updatedAt: _readDateTime(
            chatData['lastMessageAt'] ??
                chatData['updatedAt'],
          ),
          unreadCount: unreadCount,
          isActive: _isActiveStatus(status) &&
              chatData['isClosed'] != true,
          guestIsTyping:
              chatData['guestIsTyping'] == true,
          aiSuggestionAvailable:
              chatData['aiSuggestionAvailable'] == true,
        ),
      );
    }

    items.sort(
      (a, b) => b.updatedAt.compareTo(a.updatedAt),
    );

    return items;
  }

  Future<String> _loadGuestName(String userId) async {
    if (userId.trim().isEmpty) {
      return 'Guest';
    }

    try {
      final snapshot =
          await _firestore.collection('users').doc(userId).get();

      final data = snapshot.data() ?? <String, dynamic>{};

      final name = data['name']?.toString().trim() ?? '';
      final fullName =
          data['fullName']?.toString().trim() ?? '';

      if (name.isNotEmpty) {
        return name;
      }

      if (fullName.isNotEmpty) {
        return fullName;
      }

      return 'Guest';
    } catch (_) {
      return 'Guest';
    }
  }

  Future<String> _loadRoomName(String roomId) async {
    if (roomId.trim().isEmpty) {
      return 'Room';
    }

    try {
      final snapshot = await _firestore
          .collection('hotel_rooms')
          .doc(roomId)
          .get();

      final data = snapshot.data() ?? <String, dynamic>{};
      final name = data['name']?.toString().trim() ?? '';

      return name.isEmpty ? 'Room' : name;
    } catch (_) {
      return 'Room';
    }
  }

  bool _isActiveStatus(String status) {
    return status == 'pending' ||
        status == 'pending_hotel_confirmation' ||
        status == 'confirmed' ||
        status == 'checked_in' ||
        status == 'active' ||
        status == 'in_stay';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'checked_in':
        return Colors.blue;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return yellow;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
      case 'pending_hotel_confirmation':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'checked_in':
        return 'Checked In';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  DateTime _readDateTime(dynamic value) {
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

  String _formatDateTime(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) {
      return '';
    }

    final now = DateTime.now();

    final sameDay = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    if (sameDay) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  String _shortId(String id) {
    if (id.length <= 8) {
      return id.toUpperCase();
    }

    return id.substring(0, 8).toUpperCase();
  }
}

class _ChatItem {
  const _ChatItem({
    required this.chatId,
    required this.bookingId,
    required this.userId,
    required this.guestName,
    required this.roomName,
    required this.bookingStatus,
    required this.lastMessage,
    required this.updatedAt,
    required this.unreadCount,
    required this.isActive,
    required this.guestIsTyping,
    required this.aiSuggestionAvailable,
  });

  final String chatId;
  final String bookingId;
  final String userId;
  final String guestName;
  final String roomName;
  final String bookingStatus;
  final String lastMessage;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isActive;
  final bool guestIsTyping;
  final bool aiSuggestionAvailable;
}
