import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HotelNotificationsScreen extends StatefulWidget {
  const HotelNotificationsScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelNotificationsScreen> createState() =>
      _HotelNotificationsScreenState();
}

class _HotelNotificationsScreenState
    extends State<HotelNotificationsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedFilter = 'all';
  String _selectedDateFilter = 'all_time';
  String _searchText = '';
  bool _isWorking = false;
  String _workingNotificationId = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>>
      get _notificationsCollection =>
          _firestore.collection(
            'hotel_notifications',
          );

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
        title: const Text(
          'Hotel Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          StreamBuilder<
              DocumentSnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('hotel_notification_settings')
                .doc(widget.hotelId)
                .snapshots(),
            builder: (context, snapshot) {
              final bool muted =
                  snapshot.data?.data()?['isMuted'] == true;

              return IconButton(
                tooltip: muted
                    ? 'Enable notifications'
                    : 'Mute notifications',
                onPressed: _isWorking
                    ? null
                    : () => _toggleMute(muted),
                icon: Icon(
                  muted
                      ? Icons.notifications_off
                      : Icons.notifications_active,
                  color: muted
                      ? Colors.grey
                      : yellow,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: _isWorking
                ? null
                : _markAllAsRead,
            icon: const Icon(
              Icons.done_all,
              color: yellow,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _notificationsCollection
              .where(
                'hotelId',
                isEqualTo: widget.hotelId,
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
                title:
                    'Unable to Load Notifications',
                message:
                    snapshot.error.toString(),
              );
            }

            final List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>
                allDocuments =
                snapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            final documents = allDocuments
                .where(
                  (document) =>
                      document.data()['isDeleted'] !=
                      true,
                )
                .toList();

            documents.sort(
              (a, b) => _readDateTime(
                b.data()['createdAt'],
              ).compareTo(
                _readDateTime(
                  a.data()['createdAt'],
                ),
              ),
            );

            final filtered =
                _filterNotifications(
              documents,
            ).where((document) {
              final Map<String, dynamic> data =
                  document.data();

              final String query =
                  _searchText.trim().toLowerCase();

              final bool searchMatch =
                  query.isEmpty ||
                      (data['title']
                                  ?.toString()
                                  .toLowerCase() ??
                              '')
                          .contains(query) ||
                      (data['message']
                                  ?.toString()
                                  .toLowerCase() ??
                              '')
                          .contains(query) ||
                      (data['bookingId']
                                  ?.toString()
                                  .toLowerCase() ??
                              '')
                          .contains(query) ||
                      (data['userId']
                                  ?.toString()
                                  .toLowerCase() ??
                              '')
                          .contains(query);

              return searchMatch &&
                  _matchesDateFilter(
                    _readDateTime(
                      data['createdAt'],
                    ),
                  );
            }).toList();

            filtered.sort((a, b) {
              final bool aPinned =
                  a.data()['isPinned'] == true;
              final bool bPinned =
                  b.data()['isPinned'] == true;

              if (aPinned != bPinned) {
                return aPinned ? -1 : 1;
              }

              return _readDateTime(
                b.data()['createdAt'],
              ).compareTo(
                _readDateTime(
                  a.data()['createdAt'],
                ),
              );
            });

            final int unreadCount = documents
                .where(
                  (document) =>
                      document.data()['isRead'] !=
                      true,
                )
                .length;

            return RefreshIndicator(
              color: yellow,
              backgroundColor: darkCard,
              onRefresh: () async {
                await _notificationsCollection
                    .where(
                      'hotelId',
                      isEqualTo: widget.hotelId,
                    )
                    .get();
              },
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  28,
                ),
                children: [
                  _summaryCard(
                    total: documents.length,
                    unread: unreadCount,
                  ),
                  const SizedBox(height: 16),
                  _searchBox(),
                  const SizedBox(height: 12),
                  _dateFilterChips(),
                  const SizedBox(height: 12),
                  _filterChips(),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    _messageState(
                      icon:
                          Icons.notifications_none,
                      title:
                          'No Notifications',
                      message:
                          'Booking, payment, check-in, check-out, room, review and reminder updates will appear here.',
                    )
                  else
                    ...filtered.map(
                      _notificationCard,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _summaryCard({
    required int total,
    required int unread,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              title: 'Total',
              value: '$total',
              icon:
                  Icons.notifications_outlined,
            ),
          ),
          Expanded(
            child: _summaryItem(
              title: 'Unread',
              value: '$unread',
              icon:
                  Icons.mark_email_unread_outlined,
            ),
          ),
          Expanded(
            child: _summaryItem(
              title: 'Read',
              value: '${total - unread}',
              icon:
                  Icons.mark_email_read_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: yellow,
          size: 24,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchText = value;
        });
      },
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText:
            'Search title, message, booking or customer...',
        hintStyle: const TextStyle(
          color: Colors.grey,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: yellow,
        ),
        suffixIcon: _searchText.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchText = '';
                  });
                },
                icon: const Icon(
                  Icons.close,
                  color: Colors.grey,
                ),
              ),
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dateFilterChips() {
    const List<String> filters =
        <String>[
      'all_time',
      'today',
      'yesterday',
      'this_week',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map(
          (String filter) {
            final bool selected =
                _selectedDateFilter == filter;

            return Padding(
              padding:
                  const EdgeInsets.only(
                right: 8,
              ),
              child: ChoiceChip(
                selected: selected,
                label: Text(
                  _dateFilterLabel(filter),
                ),
                selectedColor:
                    Colors.blue.withValues(
                  alpha: 0.24,
                ),
                checkmarkColor: Colors.blue,
                labelStyle: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.grey,
                  fontWeight:
                      FontWeight.bold,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedDateFilter =
                        filter;
                  });
                },
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _filterChips() {
    const List<String> filters =
        <String>[
      'all',
      'unread',
      'booking',
      'payment',
      'stay',
      'reminder',
      'review',
      'chat',
      'promo',
    ];

    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,
      child: Row(
        children: filters.map(
          (String filter) {
            final bool selected =
                _selectedFilter ==
                    filter;

            return Padding(
              padding:
                  const EdgeInsets.only(
                right: 8,
              ),
              child: ChoiceChip(
                selected: selected,
                label: Text(
                  _filterLabel(
                    filter,
                  ),
                ),
                selectedColor:
                    yellow.withValues(
                  alpha: 0.25,
                ),
                checkmarkColor: yellow,
                labelStyle: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.grey,
                  fontWeight:
                      FontWeight.bold,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedFilter =
                        filter;
                  });
                },
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _notificationCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    final String type =
        data['type']?.toString() ??
            'general';

    final String title =
        data['title']?.toString() ??
            _defaultTitle(type);

    final String message =
        data['message']?.toString() ??
            '';

    final bool isRead =
        data['isRead'] == true;

    final bool isPinned =
        data['isPinned'] == true;

    final bool aiGenerated =
        data['aiGenerated'] == true ||
            data['source']?.toString() ==
                'ai_agent';

    final DateTime createdAt =
        _readDateTime(
      data['createdAt'],
    );

    final bool working =
        _workingNotificationId ==
            document.id;

    return InkWell(
      onTap: working
          ? null
          : () async {
              if (!isRead) {
                await _markAsRead(
                  document.reference,
                );
              }

              if (!mounted) {
                return;
              }

              _openNotificationDetails(
                title: title,
                message: message,
                type: type,
                data: data,
              );
            },
      borderRadius:
          BorderRadius.circular(16),
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 11,
        ),
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? darkCard
              : yellow.withValues(
                  alpha: 0.08,
                ),
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? Colors.white.withValues(
                    alpha: 0.05,
                  )
                : yellow.withValues(
                    alpha: 0.28,
                  ),
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    _notificationColor(
                  type,
                ).withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                _notificationIcon(type),
                color:
                    _notificationColor(
                  type,
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontSize: 13,
                            fontWeight:
                                isRead
                                    ? FontWeight
                                        .w600
                                    : FontWeight
                                        .bold,
                          ),
                        ),
                      ),
                      if (aiGenerated)
                        const Padding(
                          padding:
                              EdgeInsets.only(
                            right: 6,
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color:
                                Colors.purpleAccent,
                            size: 15,
                          ),
                        ),
                      if (isPinned)
                        const Padding(
                          padding:
                              EdgeInsets.only(
                            right: 6,
                          ),
                          child: Icon(
                            Icons.push_pin,
                            color: yellow,
                            size: 15,
                          ),
                        ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration:
                              const BoxDecoration(
                            color: yellow,
                            shape:
                                BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (message
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      message,
                      maxLines: 3,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      _typeBadge(type),
                      const Spacer(),
                      Text(
                        _formatDateTime(
                          createdAt,
                        ),
                        style:
                            const TextStyle(
                          color:
                              Colors.grey,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            working
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: yellow,
                    ),
                  )
                : PopupMenuButton<String>(
                    color: darkCard,
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.grey,
                    ),
                    onSelected: (value) {
                      if (value == 'read') {
                        _markAsRead(
                          document.reference,
                        );
                      } else if (value ==
                          'pin') {
                        _togglePin(
                          document.reference,
                          isPinned,
                        );
                      } else if (value ==
                          'delete') {
                        _confirmDelete(
                          document,
                        );
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem(
                          value: 'pin',
                          child: Text(
                            isPinned
                                ? 'Unpin'
                                : 'Pin notification',
                          ),
                        ),
                        if (!isRead)
                          const PopupMenuItem(
                            value: 'read',
                            child: Text(
                              'Mark as read',
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                          ),
                        ),
                      ];
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(
    String type,
  ) {
    final Color color =
        _notificationColor(type);

    return Container(
      padding:
          const EdgeInsets.symmetric(
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
        _typeLabel(type),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _markAsRead(
    DocumentReference<
            Map<String, dynamic>>
        reference,
  ) async {
    try {
      await reference.set(
        <String, dynamic>{
          'isRead': true,
          'readAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (error) {
      _showMessage(
        'Unable to mark notification as read: $error',
        isError: true,
      );
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _isWorking = true;
    });

    try {
      final QuerySnapshot<
              Map<String, dynamic>>
          snapshot =
          await _notificationsCollection
              .where(
                'hotelId',
                isEqualTo:
                    widget.hotelId,
              )
              .where(
                'isRead',
                isEqualTo: false,
              )
              .get();

      final unreadDocuments =
          snapshot.docs.where(
        (document) =>
            document.data()['isDeleted'] != true,
      );

      if (unreadDocuments.isEmpty) {
        _showMessage(
          'No unread notifications.',
        );
        return;
      }

      final WriteBatch batch =
          _firestore.batch();

      for (final document
          in unreadDocuments) {
        batch.set(
          document.reference,
          <String, dynamic>{
            'isRead': true,
            'readAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      _showMessage(
        'All notifications marked as read.',
      );
    } catch (error) {
      _showMessage(
        'Unable to update notifications: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _confirmDelete(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Delete Notification',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: const Text(
            'Remove this notification from the inbox?',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _workingNotificationId =
          document.id;
    });

    try {
      await document.reference.set(
        <String, dynamic>{
          'isDeleted': true,
          'deletedAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _showMessage(
        'Notification removed.',
      );
    } catch (error) {
      _showMessage(
        'Unable to delete notification: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _workingNotificationId = '';
        });
      }
    }
  }

  void _openNotificationDetails({
    required String title,
    required String message,
    required String type,
    required Map<String, dynamic> data,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          darkBackground,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              18,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration:
                          BoxDecoration(
                        color:
                            _notificationColor(
                          type,
                        ).withValues(
                          alpha: 0.12,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                      ),
                      child: Icon(
                        _notificationIcon(
                          type,
                        ),
                        color:
                            _notificationColor(
                          type,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 19,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  message.isEmpty
                      ? 'No additional details available.'
                      : message,
                  style:
                      const TextStyle(
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                _detailRow(
                  'Booking ID',
                  data['bookingId']
                          ?.toString() ??
                      '',
                ),
                _detailRow(
                  'Guest / Customer ID',
                  data['userId']
                          ?.toString() ??
                      '',
                ),
                _detailRow(
                  'Payment Status',
                  data['paymentStatus']
                          ?.toString() ??
                      '',
                ),
                _detailRow(
                  'Paid Amount',
                  _moneyOrEmpty(
                    data['paidAmount'],
                  ),
                ),
                _detailRow(
                  'Remaining Amount',
                  _moneyOrEmpty(
                    data['remainingAmount'],
                  ),
                ),
                _detailRow(
                  'Chat ID',
                  data['chatId']
                          ?.toString() ??
                      '',
                ),
                _detailRow(
                  'Promo Code',
                  data['promoCode']
                          ?.toString() ??
                      '',
                ),
                const SizedBox(
                  height: 18,
                ),
                SizedBox(
                  width:
                      double.infinity,
                  child:
                      ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        sheetContext,
                      );
                    },
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          yellow,
                      foregroundColor:
                          Colors.black,
                    ),
                    child:
                        const Text(
                      'Close',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String title,
    String value,
  ) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: SelectableText(
              value,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot<
          Map<String, dynamic>>>
      _filterNotifications(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        documents,
  ) {
    if (_selectedFilter ==
        'all') {
      return documents;
    }

    return documents.where(
      (document) {
        final Map<String, dynamic>
            data = document.data();

        final String type =
            data['type']?.toString() ??
                'general';

        if (_selectedFilter ==
            'unread') {
          return data['isRead'] != true;
        }

        if (_selectedFilter ==
            'booking') {
          return <String>[
            'new_booking',
            'booking_cancelled',
            'booking_confirmed',
            'booking_rejected',
            'cancellation_approved',
          ].contains(type);
        }

        if (_selectedFilter ==
            'payment') {
          return <String>[
            'payment_updated',
          ].contains(type);
        }

        if (_selectedFilter ==
            'stay') {
          return <String>[
            'room_assigned',
            'room_changed',
            'checked_in',
            'checked_out',
            'stay_extended',
            'qr_ready',
            'staff_assigned',
          ].contains(type);
        }

        if (_selectedFilter ==
            'reminder') {
          return <String>[
            'check_in_reminder',
            'check_out_reminder',
            'late_checkout_approved',
            'late_checkout_rejected',
          ].contains(type);
        }

        if (_selectedFilter ==
            'review') {
          return <String>[
            'new_review',
            'review_reply',
          ].contains(type);
        }

        if (_selectedFilter ==
            'chat') {
          return type ==
              'guest_message';
        }

        if (_selectedFilter ==
            'promo') {
          return <String>[
            'promo_expiry',
            'promo_usage',
          ].contains(type);
        }

        return true;
      },
    ).toList();
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(22),
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
            style:
                const TextStyle(
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
            style:
                const TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(
    String filter,
  ) {
    switch (filter) {
      case 'unread':
        return 'Unread';
      case 'booking':
        return 'Bookings';
      case 'payment':
        return 'Payments';
      case 'stay':
        return 'Stay';
      case 'reminder':
        return 'Reminders';
      case 'review':
        return 'Reviews';
      case 'chat':
        return 'Guest Chat';
      case 'promo':
        return 'Promo';
      default:
        return 'All';
    }
  }

  String _defaultTitle(
    String type,
  ) {
    switch (type) {
      case 'new_booking':
        return 'New Booking';
      case 'booking_cancelled':
        return 'Booking Cancelled';
      case 'booking_confirmed':
        return 'Booking Confirmed';
      case 'booking_rejected':
        return 'Booking Rejected';
      case 'cancellation_approved':
        return 'Cancellation Approved';
      case 'room_assigned':
        return 'Room Assigned';
      case 'room_changed':
        return 'Room Changed';
      case 'checked_in':
        return 'Guest Checked In';
      case 'checked_out':
        return 'Guest Checked Out';
      case 'stay_extended':
        return 'Stay Extended';
      case 'payment_updated':
        return 'Payment Updated';
      case 'qr_ready':
        return 'QR Ready';
      case 'staff_assigned':
        return 'Staff Assigned';
      case 'new_review':
        return 'New Review';
      case 'review_reply':
        return 'Review Reply';
      case 'late_checkout_approved':
        return 'Late Check-out Approved';
      case 'late_checkout_rejected':
        return 'Late Check-out Rejected';
      case 'guest_message':
        return 'New Guest Message';
      case 'check_in_reminder':
        return 'Check-in Reminder';
      case 'check_out_reminder':
        return 'Check-out Reminder';
      case 'promo_expiry':
        return 'Promo Expiry Alert';
      case 'promo_usage':
        return 'Promo Code Used';
      default:
        return 'Hotel Notification';
    }
  }

  String _typeLabel(
    String type,
  ) {
    if (<String>[
      'new_booking',
      'booking_cancelled',
      'booking_confirmed',
      'booking_rejected',
      'cancellation_approved',
    ].contains(type)) {
      return 'Booking';
    }

    if (type == 'payment_updated') {
      return 'Payment';
    }

    if (<String>[
      'room_assigned',
      'room_changed',
      'checked_in',
      'checked_out',
      'stay_extended',
      'qr_ready',
      'staff_assigned',
    ].contains(type)) {
      return 'Stay';
    }

    if (<String>[
      'check_in_reminder',
      'check_out_reminder',
      'late_checkout_approved',
      'late_checkout_rejected',
    ].contains(type)) {
      return 'Reminder';
    }

    if (<String>[
      'new_review',
      'review_reply',
    ].contains(type)) {
      return 'Review';
    }

    if (type == 'guest_message') {
      return 'Chat';
    }

    if (<String>[
      'promo_expiry',
      'promo_usage',
    ].contains(type)) {
      return 'Promo';
    }

    return 'General';
  }

  IconData _notificationIcon(
    String type,
  ) {
    switch (type) {
      case 'new_booking':
        return Icons.book_online_outlined;
      case 'booking_cancelled':
      case 'booking_rejected':
        return Icons.cancel_outlined;
      case 'booking_confirmed':
      case 'cancellation_approved':
        return Icons.check_circle_outline;
      case 'payment_updated':
        return Icons.payments_outlined;
      case 'room_assigned':
        return Icons.meeting_room_outlined;
      case 'room_changed':
        return Icons.swap_horiz;
      case 'checked_in':
        return Icons.login;
      case 'checked_out':
        return Icons.logout;
      case 'stay_extended':
        return Icons.more_time;
      case 'qr_ready':
        return Icons.qr_code_2;
      case 'staff_assigned':
        return Icons.badge_outlined;
      case 'new_review':
      case 'review_reply':
        return Icons.star_outline;
      case 'guest_message':
        return Icons.chat_bubble_outline;
      case 'check_in_reminder':
      case 'check_out_reminder':
      case 'late_checkout_approved':
      case 'late_checkout_rejected':
        return Icons.schedule_outlined;
      case 'promo_expiry':
        return Icons.timer_off_outlined;
      case 'promo_usage':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _notificationColor(
    String type,
  ) {
    switch (type) {
      case 'new_booking':
      case 'booking_confirmed':
      case 'cancellation_approved':
      case 'checked_in':
      case 'checked_out':
        return Colors.green;
      case 'booking_cancelled':
      case 'booking_rejected':
      case 'late_checkout_rejected':
        return Colors.red;
      case 'payment_updated':
        return Colors.teal;
      case 'room_assigned':
      case 'room_changed':
      case 'stay_extended':
      case 'staff_assigned':
        return Colors.blue;
      case 'qr_ready':
        return Colors.cyan;
      case 'new_review':
      case 'review_reply':
      case 'promo_expiry':
      case 'promo_usage':
        return Colors.purple;
      case 'guest_message':
        return Colors.indigo;
      case 'check_in_reminder':
      case 'check_out_reminder':
      case 'late_checkout_approved':
        return Colors.orange;
      default:
        return yellow;
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
      return DateTime.tryParse(
            value,
          ) ??
          DateTime
              .fromMillisecondsSinceEpoch(
            0,
          );
    }

    return DateTime
        .fromMillisecondsSinceEpoch(
      0,
    );
  }

  String _formatDateTime(
    DateTime date,
  ) {
    if (date.millisecondsSinceEpoch ==
        0) {
      return '';
    }

    final String day =
        date.day
            .toString()
            .padLeft(2, '0');

    final String month =
        date.month
            .toString()
            .padLeft(2, '0');

    final String hour =
        date.hour
            .toString()
            .padLeft(2, '0');

    final String minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    return '$day/$month/${date.year} $hour:$minute';
  }

  String _moneyOrEmpty(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    final double amount = value is num
        ? value.toDouble()
        : double.tryParse(
              value.toString(),
            ) ??
            0;

    return 'PKR ${amount.toStringAsFixed(0)}';
  }

  bool _matchesDateFilter(
    DateTime date,
  ) {
    if (_selectedDateFilter == 'all_time') {
      return true;
    }

    if (date.millisecondsSinceEpoch == 0) {
      return false;
    }

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime valueDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    if (_selectedDateFilter == 'today') {
      return valueDate == today;
    }

    if (_selectedDateFilter ==
        'yesterday') {
      return valueDate ==
          today.subtract(
            const Duration(days: 1),
          );
    }

    if (_selectedDateFilter ==
        'this_week') {
      final DateTime weekStart =
          today.subtract(
        Duration(
          days: today.weekday - 1,
        ),
      );

      final DateTime weekEnd =
          weekStart.add(
        const Duration(days: 7),
      );

      return !valueDate.isBefore(weekStart) &&
          valueDate.isBefore(weekEnd);
    }

    return true;
  }

  String _dateFilterLabel(
    String filter,
  ) {
    switch (filter) {
      case 'today':
        return 'Today';
      case 'yesterday':
        return 'Yesterday';
      case 'this_week':
        return 'This Week';
      default:
        return 'All Time';
    }
  }

  Future<void> _togglePin(
    DocumentReference<Map<String, dynamic>>
        reference,
    bool currentlyPinned,
  ) async {
    try {
      await reference.set(
        <String, dynamic>{
          'isPinned': !currentlyPinned,
          'pinnedAt': !currentlyPinned
              ? FieldValue.serverTimestamp()
              : null,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _showMessage(
        currentlyPinned
            ? 'Notification unpinned.'
            : 'Notification pinned.',
      );
    } catch (error) {
      _showMessage(
        'Unable to update pin: $error',
        isError: true,
      );
    }
  }

  Future<void> _toggleMute(
    bool currentlyMuted,
  ) async {
    setState(() {
      _isWorking = true;
    });

    try {
      await _firestore
          .collection(
            'hotel_notification_settings',
          )
          .doc(widget.hotelId)
          .set(
        <String, dynamic>{
          'hotelId': widget.hotelId,
          'isMuted': !currentlyMuted,
          'mutedAt': !currentlyMuted
              ? FieldValue.serverTimestamp()
              : null,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _showMessage(
        currentlyMuted
            ? 'Hotel notifications enabled.'
            : 'Hotel notifications muted.',
      );
    } catch (error) {
      _showMessage(
        'Unable to update notification setting: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
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
              isError
                  ? Colors.red
                  : darkCard,
        ),
      );
  }
}
