import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'hotel_booking_details_screen.dart';

class HotelBookingHistoryScreen extends StatefulWidget {
  const HotelBookingHistoryScreen({
    super.key,
  });

  @override
  State<HotelBookingHistoryScreen> createState() =>
      _HotelBookingHistoryScreenState();
}

class _HotelBookingHistoryScreenState
    extends State<HotelBookingHistoryScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedFilter = 'all';
  String _searchText = '';

  User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _searchController.dispose();
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
        title: const Text(
          'Hotel Booking History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: user == null
          ? _messageState(
              icon: Icons.lock_outline,
              title: 'Login Required',
              message:
                  'Please log in to view your hotel booking history.',
            )
          : SafeArea(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore
                    .collection('hotel_bookings')
                    .where(
                      'userId',
                      isEqualTo: user.uid,
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
                          'Unable to Load History',
                      message:
                          snapshot.error.toString(),
                    );
                  }

                  final List<
                          QueryDocumentSnapshot<
                              Map<String, dynamic>>>
                      history =
                      (snapshot.data?.docs ??
                              <QueryDocumentSnapshot<
                                  Map<String, dynamic>>>[])
                          .where(
                    (document) {
                      final String status =
                          document
                                  .data()['bookingStatus']
                                  ?.toString() ??
                              '';

                      return status == 'completed' ||
                          status == 'checked_out' ||
                          status == 'cancelled' ||
                          status == 'rejected' ||
                          status == 'no_show';
                    },
                  ).toList();

                  history.sort(
                    (a, b) => _readDateTime(
                      b.data()['updatedAt'] ??
                          b.data()['checkOut'] ??
                          b.data()['createdAt'],
                    ).compareTo(
                      _readDateTime(
                        a.data()['updatedAt'] ??
                            a.data()['checkOut'] ??
                            a.data()['createdAt'],
                      ),
                    ),
                  );

                  final List<
                          QueryDocumentSnapshot<
                              Map<String, dynamic>>>
                      filtered =
                      _filterHistory(history);

                  return RefreshIndicator(
                    color: yellow,
                    backgroundColor: darkCard,
                    onRefresh: () async {
                      await _firestore
                          .collection(
                            'hotel_bookings',
                          )
                          .where(
                            'userId',
                            isEqualTo: user.uid,
                          )
                          .get();
                    },
                    child: ListView(
                      padding:
                          const EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        28,
                      ),
                      children: [
                        _summaryCard(history),
                        const SizedBox(height: 16),
                        _searchBox(),
                        const SizedBox(height: 12),
                        _filterChips(),
                        const SizedBox(height: 18),
                        if (filtered.isEmpty)
                          _messageState(
                            icon: Icons.history,
                            title:
                                'No Booking History',
                            message:
                                _emptyMessage(),
                          )
                        else
                          ...filtered.map(
                            _historyCard,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _summaryCard(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        documents,
  ) {
    int completed = 0;
    int cancelled = 0;
    int noShow = 0;
    double totalSpent = 0;

    for (final document in documents) {
      final Map<String, dynamic> data =
          document.data();

      final String status =
          data['bookingStatus']?.toString() ??
              '';

      if (status == 'completed' ||
          status == 'checked_out') {
        completed++;
        totalSpent += _readNumber(
          data['totalAmount'],
        );
      } else if (status == 'cancelled' ||
          status == 'rejected') {
        cancelled++;
      } else if (status == 'no_show') {
        noShow++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  icon: Icons.task_alt,
                  title: 'Completed',
                  value: '$completed',
                ),
              ),
              Expanded(
                child: _summaryItem(
                  icon: Icons.cancel_outlined,
                  title: 'Cancelled',
                  value: '$cancelled',
                ),
              ),
              Expanded(
                child: _summaryItem(
                  icon: Icons.person_off_outlined,
                  title: 'No Show',
                  value: '$noShow',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(
            color: Colors.white12,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Completed Stay Value',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                'PKR ${_formatMoney(totalSpent)}',
                style: const TextStyle(
                  color: yellow,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String title,
    required String value,
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 9,
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
            'Search hotel, room or booking ID...',
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

  Widget _filterChips() {
    const List<String> filters =
        <String>[
      'all',
      'completed',
      'cancelled',
      'no_show',
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
                  _filterLabel(filter),
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
                side: BorderSide(
                  color: selected
                      ? yellow
                      : Colors.white.withValues(
                          alpha: 0.06,
                        ),
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

  Widget _historyCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    final String hotelName =
        data['hotelName']?.toString() ??
            'Hotel';

    final String roomName =
        data['roomName']?.toString() ??
            data['roomType']?.toString() ??
            'Selected Room';

    final String status =
        data['bookingStatus']?.toString() ??
            '';

    final DateTime checkIn =
        _readDateTime(data['checkIn']);

    final DateTime checkOut =
        _readDateTime(data['checkOut']);

    final double totalAmount =
        _readNumber(data['totalAmount']);

    final String paymentMethod =
        data['paymentMethod']?.toString() ??
            'Not set';

    final String paymentStatus =
        data['paymentStatus']?.toString() ??
            'pending';

    final int rating =
        _readInt(data['rating']);

    final String cancellationReason =
        data['cancellationReason']?.toString() ??
            data['rejectionReason']?.toString() ??
            '';

    final Color statusColor =
        _statusColor(status);

    return InkWell(
      onTap: () {
        final Map<String, dynamic> booking =
            <String, dynamic>{
          ...data,
          'id': document.id,
          'bookingId':
              data['bookingId'] ??
                  document.id,
        };

        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) =>
                HotelBookingDetailsScreen(
              booking: booking,
            ),
          ),
        );
      },
      borderRadius:
          BorderRadius.circular(18),
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color: statusColor.withValues(
              alpha: 0.28,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration:
                      BoxDecoration(
                    color: statusColor
                        .withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Icon(
                    _statusIcon(status),
                    color: statusColor,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        hotelName,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        roomName,
                        style:
                            const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(status),
              ],
            ),
            const SizedBox(height: 14),
            _detailRow(
              'Stay',
              '${_formatDate(checkIn)} - ${_formatDate(checkOut)}',
            ),
            _detailRow(
              'Payment Method',
              paymentMethod,
            ),
            _detailRow(
              'Payment Status',
              _statusLabel(paymentStatus),
            ),
            _detailRow(
              'Total',
              totalAmount <= 0
                  ? 'Not available'
                  : 'PKR ${_formatMoney(totalAmount)}',
            ),
            if (rating > 0)
              _detailRow(
                'Your Rating',
                '$rating / 5',
              ),
            if (cancellationReason
                .trim()
                .isNotEmpty)
              _detailRow(
                'Reason',
                cancellationReason,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: yellow,
                  size: 17,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Tap to view complete booking details',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color:
                      Colors.grey.shade600,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    final Color color =
        _statusColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.13,
        ),
        borderRadius:
            BorderRadius.circular(18),
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

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
            child: Text(
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
      _filterHistory(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        documents,
  ) {
    final String search =
        _searchText.trim().toLowerCase();

    return documents.where(
      (document) {
        final Map<String, dynamic> data =
            document.data();

        final String status =
            data['bookingStatus']?.toString() ??
                '';

        final String hotelName =
            data['hotelName']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final String roomName =
            data['roomName']
                    ?.toString()
                    .toLowerCase() ??
                data['roomType']
                        ?.toString()
                        .toLowerCase() ??
                    '';

        final String bookingId =
            (data['bookingId'] ??
                    document.id)
                .toString()
                .toLowerCase();

        final bool searchMatch =
            search.isEmpty ||
                hotelName.contains(search) ||
                roomName.contains(search) ||
                bookingId.contains(search);

        bool filterMatch = true;

        if (_selectedFilter ==
            'completed') {
          filterMatch =
              status == 'completed' ||
                  status == 'checked_out';
        } else if (_selectedFilter ==
            'cancelled') {
          filterMatch =
              status == 'cancelled' ||
                  status == 'rejected';
        } else if (_selectedFilter ==
            'no_show') {
          filterMatch =
              status == 'no_show';
        }

        return searchMatch &&
            filterMatch;
      },
    ).toList();
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
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
      ),
    );
  }

  String _emptyMessage() {
    switch (_selectedFilter) {
      case 'completed':
        return 'No completed hotel stays found.';
      case 'cancelled':
        return 'No cancelled hotel bookings found.';
      case 'no_show':
        return 'No no-show hotel bookings found.';
      default:
        return 'Completed and cancelled hotel bookings will appear here.';
    }
  }

  String _filterLabel(
    String filter,
  ) {
    switch (filter) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      default:
        return 'All';
    }
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'completed':
      case 'checked_out':
      case 'paid':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
      case 'failed':
        return Colors.red;
      case 'no_show':
        return Colors.orange;
      default:
        return yellow;
    }
  }

  IconData _statusIcon(
    String status,
  ) {
    switch (status) {
      case 'completed':
      case 'checked_out':
        return Icons.task_alt;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;
      case 'no_show':
        return Icons.person_off_outlined;
      default:
        return Icons.history;
    }
  }

  String _statusLabel(
    String status,
  ) {
    switch (status) {
      case 'completed':
      case 'checked_out':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'no_show':
        return 'No Show';
      case 'paid':
        return 'Paid';
      case 'cash_pending':
        return 'Cash Pending';
      case 'testing_bypassed':
        return 'Testing Bypass';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  int _readInt(
    dynamic value,
  ) {
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

  double _readNumber(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
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
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(
    DateTime value,
  ) {
    if (value.millisecondsSinceEpoch == 0) {
      return 'Not available';
    }

    final String day =
        value.day.toString().padLeft(2, '0');

    final String month =
        value.month.toString().padLeft(2, '0');

    return '$day/$month/${value.year}';
  }

  String _formatMoney(
    double amount,
  ) {
    final String value =
        amount.toStringAsFixed(0);

    return value.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }
}
