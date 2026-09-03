import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/hotel_notification_service.dart';
import '../../models/hotel_booking.dart';
import '../../services/hotel_booking_operations_service.dart';

class HotelAdminBookingScreen extends StatefulWidget {
  const HotelAdminBookingScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelAdminBookingScreen> createState() =>
      _HotelAdminBookingScreenState();
}

class _HotelAdminBookingScreenState
    extends State<HotelAdminBookingScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final HotelNotificationService _notificationService =
      HotelNotificationService();

  final HotelBookingOperationsService _bookingOperationsService =
      HotelBookingOperationsService();

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedFilter = 'all';
  String _searchText = '';
  String _workingBookingId = '';

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
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Hotel Booking Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('hotel_bookings')
              .where('hotelId', isEqualTo: widget.hotelId)
              .snapshots(),
          builder: (context, snapshot) {
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
                title: 'Unable to Load Bookings',
                message: snapshot.error.toString(),
              );
            }

            final bookings = snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            bookings.sort(
              (a, b) => _readDateTime(
                b.data()['updatedAt'] ??
                    b.data()['createdAt'],
              ).compareTo(
                _readDateTime(
                  a.data()['updatedAt'] ??
                      a.data()['createdAt'],
                ),
              ),
            );

            final filtered =
                _filterBookings(bookings);

            return RefreshIndicator(
              color: yellow,
              backgroundColor: darkCard,
              onRefresh: () async {
                await _firestore
                    .collection('hotel_bookings')
                    .where(
                      'hotelId',
                      isEqualTo: widget.hotelId,
                    )
                    .get();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  30,
                ),
                children: [
                  _summaryCard(bookings),
                  const SizedBox(height: 16),
                  _searchBox(),
                  const SizedBox(height: 12),
                  _filterChips(),
                  const SizedBox(height: 18),
                  if (filtered.isEmpty)
                    _messageState(
                      icon: Icons.book_online_outlined,
                      title: 'No Bookings Found',
                      message:
                          'No booking matches the selected filter.',
                    )
                  else
                    ...filtered.map(_bookingCard),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _summaryCard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        bookings,
  ) {
    int pending = 0;
    int confirmed = 0;
    int active = 0;
    int completed = 0;

    for (final booking in bookings) {
      final status =
          booking.data()['bookingStatus']?.toString() ??
              'pending';

      if (status == 'pending' ||
          status == 'pending_hotel_confirmation') {
        pending++;
      } else if (status == 'confirmed') {
        confirmed++;
      } else if (status == 'checked_in' ||
          status == 'active' ||
          status == 'in_stay') {
        active++;
      } else if (status == 'completed' ||
          status == 'checked_out') {
        completed++;
      }
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.65,
      children: [
        _summaryTile(
          title: 'Pending',
          value: '$pending',
          icon: Icons.pending_actions_outlined,
          color: Colors.orange,
        ),
        _summaryTile(
          title: 'Confirmed',
          value: '$confirmed',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        _summaryTile(
          title: 'Active',
          value: '$active',
          icon: Icons.hotel_outlined,
          color: Colors.blue,
        ),
        _summaryTile(
          title: 'Completed',
          value: '$completed',
          icon: Icons.task_alt,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _summaryTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
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
      ),
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
            'Search guest, room, phone or booking ID...',
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
    const filters = <String>[
      'all',
      'pending',
      'confirmed',
      'active',
      'completed',
      'cancelled',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map(
          (filter) {
            final selected =
                _selectedFilter == filter;

            return Padding(
              padding:
                  const EdgeInsets.only(
                right: 8,
              ),
              child: ChoiceChip(
                selected: selected,
                label: Text(
                  _statusLabel(filter),
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
                    _selectedFilter = filter;
                  });
                },
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _bookingCard(
    QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
  ) {
    final data = booking.data();

    final bookingId =
        data['bookingId']?.toString() ??
            booking.id;

    final guestName =
        data['guestName']?.toString() ??
            'Guest';

    final guestPhone =
        data['guestPhone']?.toString() ??
            '';

    final roomName =
        data['roomName']?.toString() ??
            data['roomType']?.toString() ??
            'Room';

    final roomNumber =
        data['roomNumber']?.toString() ??
            '';

    final status =
        data['bookingStatus']?.toString() ??
            'pending';

    final checkIn =
        _readDateTime(data['checkIn']);

    final checkOut =
        _readDateTime(data['checkOut']);

    final totalAmount =
        _readNumber(data['totalAmount']);

    final paymentMethod =
        data['paymentMethod']?.toString() ??
            'Not set';

    final paymentStatus =
        data['paymentStatus']?.toString() ??
            'pending';

    final cancellationRequested =
        data['cancellationRequested'] == true;

    final lateCheckoutRequested =
        data['lateCheckoutRequested'] == true;

    final statusColor =
        _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(15),
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
                decoration: BoxDecoration(
                  color: statusColor.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  _statusIcon(status),
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      guestName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roomNumber.isEmpty
                          ? roomName
                          : '$roomName - Room $roomNumber',
                      style: const TextStyle(
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
          const SizedBox(height: 13),
          _detailRow(
            'Booking ID',
            bookingId,
          ),
          if (guestPhone.isNotEmpty)
            _detailRow(
              'Guest Phone',
              guestPhone,
            ),
          _detailRow(
            'Stay',
            '${_formatDate(checkIn)} - ${_formatDate(checkOut)}',
          ),
          _detailRow(
            'Payment',
            '$paymentMethod Ã¢â‚¬Â¢ ${_statusLabel(paymentStatus)}',
          ),
          _detailRow(
            'Total',
            totalAmount <= 0
                ? 'Not available'
                : 'PKR ${_formatMoney(totalAmount)}',
          ),
          _detailRow(
            'Nights',
            '${_readInt(data['nights'], fallback: _calculateNights(checkIn, checkOut))}',
          ),
          _detailRow(
            'Rooms',
            '${_readInt(data['rooms'], fallback: 1)}',
          ),
          _detailRow(
            'Adults / Children',
            '${_readInt(data['adults'])} / ${_readInt(data['children'])}',
          ),
          if ((data['assignedStaffName']?.toString() ?? '').isNotEmpty)
            _detailRow(
              'Assigned Staff',
              data['assignedStaffName'].toString(),
            ),
          if ((data['verificationPin']?.toString() ?? '').isNotEmpty &&
              status == 'confirmed')
            _detailRow(
              'Check-in Verification',
              'QR or Booking ID + PIN',
            ),
          if (cancellationRequested)
            _alertRow(
              icon: Icons.cancel_outlined,
              text:
                  'Cancellation request pending review',
              color: Colors.redAccent,
            ),
          if (lateCheckoutRequested)
            _alertRow(
              icon: Icons.schedule_outlined,
              text:
                  'Late check-out request pending review',
              color: Colors.orange,
            ),
          const SizedBox(height: 10),
          _actionButtons(
            booking: booking,
            status: status,
            cancellationRequested:
                cancellationRequested,
            lateCheckoutRequested:
                lateCheckoutRequested,
          ),
        ],
      ),
    );
  }

  Widget _actionButtons({
    required QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
    required String status,
    required bool cancellationRequested,
    required bool lateCheckoutRequested,
  }) {
    final bool working =
        _workingBookingId == booking.id;

    return Column(
      children: [
        if (status == 'pending' ||
            status == 'pending_hotel_confirmation')
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: working
                      ? null
                      : () {
                          _rejectBooking(booking);
                        },
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        Colors.redAccent,
                    side: const BorderSide(
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: working
                      ? null
                      : () {
                          _approveWithRoomAssignment(
                            booking,
                          );
                        },
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor:
                        Colors.black,
                  ),
                ),
              ),
            ],
          ),
        if (status == 'confirmed') ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: working
                      ? null
                      : () {
                          _assignRoomNumber(
                            booking,
                          );
                        },
                  icon: const Icon(
                    Icons.meeting_room_outlined,
                  ),
                  label: const Text('Assign Room'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: working
                      ? null
                      : () {
                          _assignStaff(booking);
                        },
                  icon: const Icon(
                    Icons.badge_outlined,
                  ),
                  label: const Text('Assign Staff'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: working
                  ? null
                  : () {
                      _verifyAndCheckInGuest(
                        booking,
                      );
                    },
              icon: const Icon(
                Icons.qr_code_scanner,
              ),
              label: const Text(
                'Verify QR / PIN & Check In',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
        if (status == 'checked_in' ||
            status == 'active' ||
            status == 'in_stay') ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: working
                      ? null
                      : () {
                          _changeRoom(booking);
                        },
                  icon: const Icon(
                    Icons.swap_horiz,
                  ),
                  label: const Text('Change Room'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: working
                      ? null
                      : () {
                          _extendStay(booking);
                        },
                  icon: const Icon(
                    Icons.more_time,
                  ),
                  label: const Text('Extend Stay'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: working
                  ? null
                  : () {
                      _checkOutGuest(booking);
                    },
              icon: const Icon(Icons.logout),
              label: const Text('Check Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: working
                    ? null
                    : () {
                        _showPaymentPanel(
                          booking,
                        );
                      },
                icon: const Icon(
                  Icons.payments_outlined,
                ),
                label: const Text('Payment'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: working
                    ? null
                    : () {
                        _showTimeline(booking);
                      },
                icon: const Icon(Icons.timeline),
                label: const Text('Timeline'),
              ),
            ),
          ],
        ),
        if (cancellationRequested) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: working
                  ? null
                  : () {
                      _reviewCancellation(
                        booking,
                      );
                    },
              icon: const Icon(
                Icons.rule_outlined,
              ),
              label: const Text(
                'Review Cancellation',
              ),
            ),
          ),
        ],
        if (lateCheckoutRequested) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: working
                  ? null
                  : () {
                      _reviewLateCheckout(
                        booking,
                      );
                    },
              icon: const Icon(
                Icons.more_time_outlined,
              ),
              label: const Text(
                'Review Late Check-out',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _approveWithRoomAssignment(
    QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
  ) async {
    final Map<String, dynamic>? room =
        await _selectAvailableRoom(
      booking: booking,
      title: 'Approve & Assign Room',
      allowSkip: true,
    );

    if (!mounted) {
      return;
    }

    await _runBookingWork(
      booking.id,
      () async {
        final String adminUserId =
            FirebaseAuth.instance.currentUser?.uid ??
                'hotel_admin_testing';

        final Map<String, dynamic> bookingData =
            Map<String, dynamic>.from(
          booking.data(),
        );

        if (room != null) {
          bookingData['roomId'] =
              room['roomId'];
        }

        final HotelBooking bookingModel =
            HotelBooking.fromMap(
          bookingData,
          booking.id,
        );

        await _bookingOperationsService.acceptBooking(
          booking: bookingModel,
          agentUserId: adminUserId,
        );

        final Map<String, dynamic> updates =
            <String, dynamic>{
          'approvedAt':
              FieldValue.serverTimestamp(),
          'approvedBy':
              adminUserId,
          'updatedAt':
              FieldValue.serverTimestamp(),
        };

        if (room != null) {
          updates.addAll(
            <String, dynamic>{
              'assignedRoomId':
                  room['roomId'],
              'roomId':
                  room['roomId'],
              'roomNumber':
                  room['roomNumber'],
              'roomName':
                  room['roomName'],
              'roomAssignedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        }

        await booking.reference.set(
          updates,
          SetOptions(merge: true),
        );

        await _saveAuditLog(
          bookingId: booking.id,
          action: 'booking_approved',
          details: room == null
              ? 'Booking approved without room assignment.'
              : 'Booking approved and room ${room['roomNumber']} assigned.',
        );

        final Map<String, dynamic> data =
            booking.data();

        final String userId =
            data['userId']?.toString() ??
                data['customerId']?.toString() ??
                '';

        if (userId.isNotEmpty) {
          await _notificationService
              .notifyBookingApproved(
            userId: userId,
            hotelId: widget.hotelId,
            bookingId:
                data['bookingId']?.toString() ??
                    booking.id,
            hotelName:
                data['hotelName']?.toString() ??
                    'Hotel',
            roomNumber:
                room?['roomNumber']?.toString() ??
                    '',
          );

          await _notificationService
              .notifyQrReady(
            userId: userId,
            hotelId: widget.hotelId,
            bookingId:
                data['bookingId']?.toString() ??
                    booking.id,
          );
        }
      },
      'Booking approved successfully.',
    );
  }
  Future<void> _assignRoomNumber(
    QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
  ) async {
    final Map<String, dynamic>? room =
        await _selectAvailableRoom(
      booking: booking,
      title: 'Assign Room',
    );

    if (room == null) {
      return;
    }

    await _runBookingWork(
      booking.id,
      () async {
        await booking.reference.set(
          <String, dynamic>{
            'assignedRoomId':
                room['roomId'],
            'roomId': room['roomId'],
            'roomNumber':
                room['roomNumber'],
            'roomName': room['roomName'],
            'roomAssignedAt':
                FieldValue.serverTimestamp(),
            'roomAssignedBy':
                FirebaseAuth.instance.currentUser?.uid ??
                    'hotel_admin_testing',
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _saveAuditLog(
          bookingId: booking.id,
          action: 'room_assigned',
          details:
              'Room ${room['roomNumber']} assigned.',
        );

        final Map<String, dynamic> data =
            booking.data();

        final String userId =
            data['userId']?.toString() ??
                data['customerId']?.toString() ??
                '';

        if (userId.isNotEmpty) {
          await _notificationService
              .notifyRoomAssigned(
            userId: userId,
            hotelId: widget.hotelId,
            bookingId:
                data['bookingId']?.toString() ??
                    booking.id,
            roomNumber:
                room['roomNumber']?.toString() ??
                    '',
          );
        }
      },
      'Room assigned successfully.',
    );
  }

  Future<Map<String, dynamic>?> _selectAvailableRoom({
    required QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
    required String title,
    bool allowSkip = false,
  }) async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection('hotel_rooms')
            .where(
              'hotelId',
              isEqualTo: widget.hotelId,
            )
            .get();

    final List<Map<String, dynamic>> rooms =
        snapshot.docs.map((document) {
      final Map<String, dynamic> data =
          document.data();

      return <String, dynamic>{
        ...data,
        'roomId': document.id,
        'roomNumber':
            data['roomNumber']?.toString() ??
                document.id,
        'roomName':
            data['roomName']?.toString() ??
                data['roomType']?.toString() ??
                'Room',
      };
    }).where((room) {
      final String status =
          room['manualStatus']?.toString() ??
              room['status']?.toString() ??
              'available';

      return status != 'occupied' &&
          status != 'maintenance' &&
          status != 'blocked';
    }).toList();

    if (!mounted) {
      return null;
    }

    return showModalBottomSheet<
        Map<String, dynamic>>(
      context: context,
      backgroundColor: darkCard,
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
          child: SizedBox(
            height:
                MediaQuery.sizeOf(context).height *
                    0.70,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.meeting_room,
                        color: yellow,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (allowSkip)
                  ListTile(
                    leading: const Icon(
                      Icons.skip_next,
                      color: Colors.orange,
                    ),
                    title: const Text(
                      'Approve without room assignment',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                        null,
                      );
                    },
                  ),
                Expanded(
                  child: rooms.isEmpty
                      ? const Center(
                          child: Padding(
                            padding:
                                EdgeInsets.all(24),
                            child: Text(
                              'No available room found. Add rooms or clear occupied/maintenance status first.',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: rooms.length,
                          itemBuilder:
                              (context, index) {
                            final room =
                                rooms[index];

                            return ListTile(
                              leading:
                                  const CircleAvatar(
                                backgroundColor:
                                    Color(
                                  0x22FFD60A,
                                ),
                                child: Icon(
                                  Icons.bed_outlined,
                                  color: yellow,
                                ),
                              ),
                              title: Text(
                                '${room['roomName']} Ã¢â‚¬Â¢ Room ${room['roomNumber']}',
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Status: ${room['manualStatus'] ?? room['status'] ?? 'available'}',
                                style:
                                    const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                              trailing:
                                  const Icon(
                                Icons.chevron_right,
                                color: yellow,
                              ),
                              onTap: () {
                                Navigator.pop(
                                  sheetContext,
                                  room,
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
      },
    );
  }

  Future<void> _assignStaff(
    QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
  ) async {
    final QuerySnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection('hotel_staff')
            .where(
              'hotelId',
              isEqualTo: widget.hotelId,
            )
            .get();

    final List<Map<String, dynamic>> staff =
        snapshot.docs.map((document) {
      return <String, dynamic>{
        ...document.data(),
        'staffId': document.id,
      };
    }).where((item) {
      final bool active =
          item['isActive'] != false;

      return active;
    }).toList();

    if (!mounted) {
      return;
    }

    final Map<String, dynamic>? selected =
        await showModalBottomSheet<
            Map<String, dynamic>>(
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
          child: SizedBox(
            height:
                MediaQuery.sizeOf(context).height *
                    0.65,
            child: Column(
              children: [
                const Padding(
                  padding:
                      EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        color: yellow,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Assign Staff',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: staff.isEmpty
                      ? const Center(
                          child: Text(
                            'No active hotel staff found.',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: staff.length,
                          itemBuilder:
                              (context, index) {
                            final item =
                                staff[index];

                            return ListTile(
                              leading:
                                  const CircleAvatar(
                                backgroundColor:
                                    Color(
                                  0x22FFD60A,
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: yellow,
                                ),
                              ),
                              title: Text(
                                item['fullName']
                                        ?.toString() ??
                                    item['name']
                                        ?.toString() ??
                                    'Staff',
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                item['role']
                                        ?.toString() ??
                                    'Hotel Staff',
                                style:
                                    const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(
                                  sheetContext,
                                  item,
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
      },
    );

    if (selected == null) {
      return;
    }

    await _runBookingWork(
      booking.id,
      () async {
        await booking.reference.set(
          <String, dynamic>{
            'assignedStaffId':
                selected['staffId'],
            'assignedStaffName':
                selected['fullName'] ??
                    selected['name'],
            'assignedStaffRole':
                selected['role'],
            'staffAssignedAt':
                FieldValue.serverTimestamp(),
            'staffAssignedBy':
                FirebaseAuth.instance.currentUser?.uid ??
                    'hotel_admin_testing',
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _saveAuditLog(
          bookingId: booking.id,
          action: 'staff_assigned',
          details:
              'Staff ${selected['fullName'] ?? selected['name']} assigned.',
        );
      },
      'Staff assigned successfully.',
    );
  }

  Future<void> _verifyAndCheckInGuest(
    QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
  ) async {
    final TextEditingController bookingController =
        TextEditingController(
      text: booking.data()['bookingId']?.toString() ??
          booking.id,
    );
    final TextEditingController pinController =
        TextEditingController();

    final bool? verified =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Verify Booking',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Use QR scanner when connected, or verify manually with Booking ID and 6-digit PIN.',
                style: TextStyle(
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller:
                    bookingController,
                style: const TextStyle(
                  color: Colors.white,
                ),
                decoration:
                    const InputDecoration(
                  labelText: 'Booking ID',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller:
                    pinController,
                keyboardType:
                    TextInputType.number,
                obscureText: true,
                maxLength: 6,
                style: const TextStyle(
                  color: Colors.white,
                ),
                decoration:
                    const InputDecoration(
                  labelText:
                      '6-digit Verification PIN',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final String savedBookingId =
                    booking.data()['bookingId']
                            ?.toString() ??
                        booking.id;
                final String savedPin =
                    booking.data()['verificationPin']
                            ?.toString() ??
                        '';

                final bool match =
                    bookingController.text.trim() ==
                            savedBookingId &&
                        pinController.text.trim() ==
                            savedPin &&
                        booking.data()[
                                'verificationPinIsActive'] !=
                            false;

                Navigator.pop(
                  dialogContext,
                  match,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor:
                    Colors.black,
              ),
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );

    bookingController.dispose();
    pinController.dispose();

    if (verified != true) {
      _showMessage(
        'Booking ID or verification PIN is incorrect.',
        isError: true,
      );
      return;
    }

    await _checkInGuest(
      booking,
      checkInMethod: 'manual_booking_id_pin',
    );
  }

    Future<void> _checkInGuest(
    QueryDocumentSnapshot<Map<String, dynamic>>
        booking, {
    String checkInMethod = 'admin_manual',
  }) async {
    final confirmed =
        await _confirmDialog(
      title: 'Check-in Guest',
      message:
          'Confirm that the guest has arrived and room handover is complete.',
      confirmText: 'Check In',
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
    });

    try {
      final Map<String, dynamic> data =
          booking.data();

      final String roomId =
          data['roomId']?.toString() ?? '';

      final String adminUserId =
          FirebaseAuth.instance.currentUser?.uid ??
              'hotel_admin_testing';

      final HotelBooking bookingModel =
          HotelBooking.fromMap(
        Map<String, dynamic>.from(data),
        booking.id,
      );

      // Central service owns confirmed -> checked_in.
      await _bookingOperationsService.markCheckedIn(
        booking: bookingModel,
        agentUserId: adminUserId,
      );

      final WriteBatch batch =
          _firestore.batch();

      // Preserve verification metadata.
      batch.set(
        booking.reference,
        <String, dynamic>{
          'checkInMethod': checkInMethod,
          'checkedInBy': adminUserId,
          'verificationPinIsActive': false,
          'qrIsActive': false,
          'qrUsedAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Preserve room operational state.
      if (roomId.isNotEmpty) {
        batch.set(
          _firestore
              .collection('hotel_rooms')
              .doc(roomId),
          <String, dynamic>{
            'manualStatus': 'occupied',
            'currentBookingId': booking.id,
            'currentGuestName':
                data['guestName']?.toString() ??
                    '',
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      await _saveAuditLog(
        bookingId: booking.id,
        action: 'guest_checked_in',
        details:
            'Guest checked in using $checkInMethod.',
      );

      final String userId =
          data['userId']?.toString() ??
              data['customerId']?.toString() ??
              '';

      if (userId.isNotEmpty) {
        await _notificationService.notifyCheckedIn(
          userId: userId,
          hotelId: widget.hotelId,
          bookingId:
              data['bookingId']?.toString() ??
                  booking.id,
          hotelName:
              data['hotelName']?.toString() ??
                  'Hotel',
        );
      }

      _showMessage(
        'Guest checked in successfully.',
      );
    } catch (error) {
      _showMessage(
        'Unable to check in guest: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
        });
      }
    }
  }
  Future<void> _checkOutGuest(
    QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
  ) async {
    final confirmed =
        await _confirmDialog(
      title: 'Check-out Guest',
      message:
          'Confirm final room handover. The room will be sent to housekeeping.',
      confirmText: 'Check Out',
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
    });

    try {
      final Map<String, dynamic> data =
          booking.data();

      final String roomId =
          data['roomId']?.toString() ?? '';

      final String adminUserId =
          FirebaseAuth.instance.currentUser?.uid ??
              'hotel_admin_testing';

      final HotelBooking bookingModel =
          HotelBooking.fromMap(
        Map<String, dynamic>.from(data),
        booking.id,
      );

      // Central lifecycle owns checked_in -> completed.
      // It also creates the canonical completion notification.
      await _bookingOperationsService.markCheckedOut(
        booking: bookingModel,
        agentUserId: adminUserId,
      );

      final WriteBatch batch =
          _firestore.batch();

      // Preserve Hotel Admin room housekeeping state.
      if (roomId.isNotEmpty) {
        batch.set(
          _firestore
              .collection('hotel_rooms')
              .doc(roomId),
          <String, dynamic>{
            'manualStatus': 'housekeeping',
            'housekeepingStatus': 'dirty',
            'currentBookingId':
                FieldValue.delete(),
            'currentGuestName':
                FieldValue.delete(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      // Preserve housekeeping workflow/task.
      final DocumentReference<Map<String, dynamic>>
          taskReference = _firestore
              .collection('hotel_housekeeping_tasks')
              .doc();

      batch.set(
        taskReference,
        <String, dynamic>{
          'taskId': taskReference.id,
          'hotelId': widget.hotelId,
          'bookingId': booking.id,
          'roomId': roomId,
          'roomNumber':
              data['roomNumber']?.toString() ??
                  '',
          'taskStatus': 'dirty',
          'priority': 'high',
          'source': 'guest_checkout',
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      await _saveAuditLog(
        bookingId: booking.id,
        action: 'guest_checked_out',
        details:
            'Guest checked out and housekeeping task created.',
      );

      // Customer completion notification is intentionally
      // NOT duplicated here. markCheckedOut() already sends
      // the canonical hotel_booking_completed notification.

      _showMessage(
        'Guest checked out and housekeeping task created.',
      );
    } catch (error) {
      _showMessage(
        'Unable to check out guest: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
        });
      }
    }
  }
  Future<void> _rejectBooking(
    QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
  ) async {
    final TextEditingController controller =
        TextEditingController();

    final String? reason =
        await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Reject Booking',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration: const InputDecoration(
              hintText:
                  'Enter rejection reason',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason == null || reason.isEmpty) {
      return;
    }

    await _runBookingWork(
      booking.id,
      () async {
        final Map<String, dynamic> data =
            booking.data();

        final String adminUserId =
            FirebaseAuth.instance.currentUser?.uid ??
                'hotel_admin_testing';

        final HotelBooking bookingModel =
            HotelBooking.fromMap(
          Map<String, dynamic>.from(data),
          booking.id,
        );

        await _bookingOperationsService.rejectBooking(
          booking: bookingModel,
          agentUserId: adminUserId,
          reason: reason,
        );
      },
      'Booking rejected successfully.',
    );
  }
  Future<void> _reviewCancellation(
    QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
  ) async {
    final action =
        await _reviewSheet(
      title: 'Cancellation Review',
      approveLabel: 'Approve Cancellation',
      rejectLabel: 'Reject Cancellation',
    );

    if (action == null) {
      return;
    }

    if (action == 'approve') {
      setState(() {
        _workingBookingId = booking.id;
      });

      try {
        final Map<String, dynamic> data =
            booking.data();

        final String adminUserId =
            FirebaseAuth.instance.currentUser?.uid ??
                'hotel_admin_testing';

        final HotelBooking bookingModel =
            HotelBooking.fromMap(
          Map<String, dynamic>.from(data),
          booking.id,
        );

        await _bookingOperationsService.cancelBooking(
          booking: bookingModel,
          agentUserId: adminUserId,
        );

        _showMessage(
          'Cancellation approved.',
        );

        final String userId =
            data['userId']?.toString() ??
                data['customerId']?.toString() ??
                '';

        if (userId.isNotEmpty) {
          await _notificationService
              .createCustomerNotification(
            userId: userId,
            hotelId: widget.hotelId,
            bookingId:
                data['bookingId']?.toString() ??
                    booking.id,
            title: 'Cancellation Approved',
            message:
                'Your hotel booking cancellation request has been approved.',
            type: 'cancellation_approved',
          );
        }
      } catch (error) {
        _showMessage(
          'Unable to approve cancellation: $error',
          isError: true,
        );
      } finally {
        if (mounted) {
          setState(() {
            _workingBookingId = '';
          });
        }
      }
    } else {
      await _updateBookingStatus(
        booking: booking,
        status:
            booking.data()['bookingStatus']
                    ?.toString() ??
                'confirmed',
        message:
            'Cancellation request rejected.',
        extraData: <String, dynamic>{
          'cancellationRequested': false,
          'cancellationRequestStatus':
              'rejected',
          'cancellationRejectedAt':
              FieldValue.serverTimestamp(),
        },
      );
    }

    // Real refund remains bypassed.
  }
Future<void> _reviewLateCheckout(
    QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
  ) async {
    final action =
        await _reviewSheet(
      title: 'Late Check-out Review',
      approveLabel: 'Approve Request',
      rejectLabel: 'Reject Request',
    );

    if (action == null) {
      return;
    }

    if (action == 'approve') {
      final requestedAt =
          booking.data()['requestedCheckoutAt'];

      await _updateBookingStatus(
        booking: booking,
        status:
            booking.data()['bookingStatus']
                    ?.toString() ??
                'confirmed',
        message:
            'Late check-out approved.',
        extraData: <String, dynamic>{
          'lateCheckoutRequestStatus':
              'approved',
          'lateCheckoutApprovedAt':
              FieldValue.serverTimestamp(),
          'approvedCheckoutAt': ?requestedAt,
        },
      );

      final Map<String, dynamic> data =
          booking.data();

      final String userId =
          data['userId']?.toString() ??
              data['customerId']?.toString() ??
              '';

      if (userId.isNotEmpty) {
        await _notificationService
            .createCustomerNotification(
          userId: userId,
          hotelId: widget.hotelId,
          bookingId:
              data['bookingId']?.toString() ??
                  booking.id,
          title: 'Late Check-out Approved',
          message:
              'Your late check-out request has been approved.',
          type: 'late_checkout_approved',
        );
      }
    } else {
      await _updateBookingStatus(
        booking: booking,
        status:
            booking.data()['bookingStatus']
                    ?.toString() ??
                'confirmed',
        message:
            'Late check-out rejected.',
        extraData: <String, dynamic>{
          'lateCheckoutRequested': false,
          'lateCheckoutRequestStatus':
              'rejected',
          'lateCheckoutRejectedAt':
              FieldValue.serverTimestamp(),
        },
      );

      final Map<String, dynamic> data =
          booking.data();

      final String userId =
          data['userId']?.toString() ??
              data['customerId']?.toString() ??
              '';

      if (userId.isNotEmpty) {
        await _notificationService
            .createCustomerNotification(
          userId: userId,
          hotelId: widget.hotelId,
          bookingId:
              data['bookingId']?.toString() ??
                  booking.id,
          title: 'Late Check-out Rejected',
          message:
              'Your late check-out request was not approved.',
          type: 'late_checkout_rejected',
        );
      }
    }

    // Real extra payment remains bypassed.
  }

  Future<String?> _reviewSheet({
    required String title,
    required String approveLabel,
    required String rejectLabel,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: darkCard,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  title: Text(approveLabel),
                  onTap: () {
                    Navigator.pop(
                      context,
                      'approve',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.redAccent,
                  ),
                  title: Text(rejectLabel),
                  onTap: () {
                    Navigator.pop(
                      context,
                      'reject',
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

  Future<void> _updateBookingStatus({
    required QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
    required String status,
    required String message,
    Map<String, dynamic>? extraData,
  }) async {
    setState(() {
    });

    try {
      await booking.reference.set(
        <String, dynamic>{
          'bookingStatus': status,
          'lastUpdatedBy':
              FirebaseAuth.instance.currentUser?.uid ??
                  'hotel_admin_testing',
          'updatedAt':
              FieldValue.serverTimestamp(),
          ...?extraData,
        },
        SetOptions(merge: true),
      );

      _showMessage(message);
    } catch (error) {
      _showMessage(
        'Unable to update booking: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
        });
      }
    }
  }

  Future<void> _runBookingWork(
    String bookingId,
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() {
      _workingBookingId = bookingId;
    });

    try {
      await action();
      _showMessage(successMessage);
    } catch (error) {
      _showMessage(
        'Unable to complete action: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _workingBookingId = '';
        });
      }
    }
  }

  Future<void> _changeRoom(
    QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
  ) async {
    final Map<String, dynamic>? room =
        await _selectAvailableRoom(
      booking: booking,
      title: 'Change Guest Room',
    );

    if (room == null) {
      return;
    }

    final Map<String, dynamic> oldData =
        booking.data();

    await _runBookingWork(
      booking.id,
      () async {
        await booking.reference.set(
          <String, dynamic>{
            'previousRoomId':
                oldData['roomId'],
            'previousRoomNumber':
                oldData['roomNumber'],
            'roomId': room['roomId'],
            'assignedRoomId':
                room['roomId'],
            'roomNumber':
                room['roomNumber'],
            'roomName': room['roomName'],
            'roomChangedAt':
                FieldValue.serverTimestamp(),
            'roomChangedBy':
                FirebaseAuth.instance.currentUser?.uid ??
                    'hotel_admin_testing',
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _saveAuditLog(
          bookingId: booking.id,
          action: 'room_changed',
          details:
              'Room changed from ${oldData['roomNumber'] ?? 'not assigned'} to ${room['roomNumber']}.',
        );

        final String userId =
            oldData['userId']?.toString() ??
                oldData['customerId']?.toString() ??
                '';

        if (userId.isNotEmpty) {
          await _notificationService
              .notifyRoomChanged(
            userId: userId,
            hotelId: widget.hotelId,
            bookingId:
                oldData['bookingId']?.toString() ??
                    booking.id,
            roomNumber:
                room['roomNumber']?.toString() ??
                    '',
          );
        }
      },
      'Room changed successfully.',
    );
  }

  Future<void> _extendStay(
    QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
  ) async {
    final int? extraNights =
        await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        int value = 1;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: darkCard,
              title: const Text(
                'Extend Stay',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              content: Row(
                children: [
                  IconButton(
                    onPressed: value > 1
                        ? () {
                            setDialogState(() {
                              value--;
                            });
                          }
                        : null,
                    icon: const Icon(
                      Icons.remove_circle,
                      color: yellow,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$value extra night(s)',
                      textAlign:
                          TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: value < 30
                        ? () {
                            setDialogState(() {
                              value++;
                            });
                          }
                        : null,
                    icon: const Icon(
                      Icons.add_circle,
                      color: yellow,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                      const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      value,
                    );
                  },
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor:
                        Colors.black,
                  ),
                  child:
                      const Text('Extend'),
                ),
              ],
            );
          },
        );
      },
    );

    if (extraNights == null) {
      return;
    }

    final Map<String, dynamic> data =
        booking.data();
    final DateTime oldCheckOut =
        _readDateTime(data['checkOut']);
    final DateTime newCheckOut =
        oldCheckOut.add(
      Duration(days: extraNights),
    );

    final double baseNightPrice =
        _readNumber(
      data['baseNightPrice'] ??
          data['pricePerNight'],
    );
    final int rooms =
        _readInt(data['rooms'], fallback: 1);
    final double addedAmount =
        baseNightPrice *
            rooms *
            extraNights;

    await _runBookingWork(
      booking.id,
      () async {
        await booking.reference.set(
          <String, dynamic>{
            'checkOut':
                Timestamp.fromDate(newCheckOut),
            'nights': _readInt(
                  data['nights'],
                  fallback: _calculateNights(
                    _readDateTime(
                      data['checkIn'],
                    ),
                    oldCheckOut,
                  ),
                ) +
                extraNights,
            'stayExtensionNights':
                FieldValue.increment(
              extraNights,
            ),
            'stayExtensionAmount':
                FieldValue.increment(
              addedAmount,
            ),
            'totalAmount':
                FieldValue.increment(
              addedAmount,
            ),
            'paymentStatus':
                'extension_payment_pending',
            'stayExtendedAt':
                FieldValue.serverTimestamp(),
            'stayExtendedBy':
                FirebaseAuth.instance.currentUser?.uid ??
                    'hotel_admin_testing',
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _saveAuditLog(
          bookingId: booking.id,
          action: 'stay_extended',
          details:
              'Stay extended by $extraNights night(s). Added amount PKR ${_formatMoney(addedAmount)}.',
        );

        final String userId =
            data['userId']?.toString() ??
                data['customerId']?.toString() ??
                '';

        if (userId.isNotEmpty) {
          await _notificationService
              .notifyStayExtended(
            userId: userId,
            hotelId: widget.hotelId,
            bookingId:
                data['bookingId']?.toString() ??
                    booking.id,
            extraNights: extraNights,
            addedAmount: addedAmount,
          );
        }
      },
      'Stay extended successfully.',
    );

    // Real extra-night payment remains bypassed.
  }

  Future<void> _showPaymentPanel(
    QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
  ) async {
    final Map<String, dynamic> data =
        booking.data();

    final double total =
        _readNumber(data['totalAmount']);
    final double paid =
        _readNumber(data['paidAmount']);
    final double remaining =
        max(total - paid, 0);

    final String? action =
        await showModalBottomSheet<String>(
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
                const EdgeInsets.all(18),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Text(
                  'Booking Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _detailRow(
                  'Total',
                  'PKR ${_formatMoney(total)}',
                ),
                _detailRow(
                  'Paid',
                  'PKR ${_formatMoney(paid)}',
                ),
                _detailRow(
                  'Remaining',
                  'PKR ${_formatMoney(remaining)}',
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.payments,
                    color: yellow,
                  ),
                  title: const Text(
                    'Mark Cash Received',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      'cash_received',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.account_balance_wallet,
                    color: yellow,
                  ),
                  title: const Text(
                    'Mark Testing Payment',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  subtitle: const Text(
                    'Wallet/JazzCash/Easypaisa bypass',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      'testing_paid',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null) {
      return;
    }

    await _runBookingWork(
      booking.id,
      () async {
        await booking.reference.set(
          <String, dynamic>{
            'paidAmount': total,
            'remainingAmount': 0,
            'paymentStatus':
                action == 'cash_received'
                    ? 'cash_received'
                    : 'paid_testing',
            'paymentReceivedAt':
                FieldValue.serverTimestamp(),
            'paymentReceivedBy':
                FirebaseAuth.instance.currentUser?.uid ??
                    'hotel_admin_testing',
            'realPaymentProcessed':
                false,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _saveAuditLog(
          bookingId: booking.id,
          action: 'payment_updated',
          details: action ==
                  'cash_received'
              ? 'Cash payment marked received.'
              : 'Testing payment marked paid.',
        );

        final String userId =
            data['userId']?.toString() ??
                data['customerId']?.toString() ??
                '';

        if (userId.isNotEmpty) {
          await _notificationService
              .notifyPaymentUpdated(
            userId: userId,
            hotelId: widget.hotelId,
            bookingId:
                data['bookingId']?.toString() ??
                    booking.id,
            paymentStatus:
                action == 'cash_received'
                    ? 'cash_received'
                    : 'paid_testing',
            paidAmount: total,
            remainingAmount: 0,
          );
        }
      },
      'Payment status updated.',
    );
  }

  void _showTimeline(
    QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
  ) {
    final Map<String, dynamic> data =
        booking.data();

    final List<Map<String, dynamic>> events =
        <Map<String, dynamic>>[
      <String, dynamic>{
        'title': 'Booking Created',
        'time': data['createdAt'],
        'done': data['createdAt'] != null,
      },
      <String, dynamic>{
        'title': 'Hotel Approved',
        'time': data['approvedAt'],
        'done': data['approvedAt'] != null ||
            data['bookingStatus'] ==
                'confirmed',
      },
      <String, dynamic>{
        'title': 'Room Assigned',
        'time': data['roomAssignedAt'],
        'done': (data['roomNumber']
                    ?.toString() ??
                '')
            .isNotEmpty,
      },
      <String, dynamic>{
        'title': 'Guest Checked In',
        'time': data['checkedInAt'],
        'done':
            data['checkedInAt'] != null,
      },
      <String, dynamic>{
        'title': 'Stay Extended',
        'time': data['stayExtendedAt'],
        'done':
            data['stayExtendedAt'] != null,
      },
      <String, dynamic>{
        'title': 'Guest Checked Out',
        'time': data['checkedOutAt'],
        'done':
            data['checkedOutAt'] != null,
      },
    ];

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
                const EdgeInsets.all(18),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Text(
                  'Booking Timeline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                ...events.map((event) {
                  final bool done =
                      event['done'] == true;

                  return ListTile(
                    leading: Icon(
                      done
                          ? Icons.check_circle
                          : Icons
                              .radio_button_unchecked,
                      color: done
                          ? yellow
                          : Colors.grey,
                    ),
                    title: Text(
                      event['title']
                          .toString(),
                      style: TextStyle(
                        color: done
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),
                    subtitle:
                        event['time'] == null
                            ? null
                            : Text(
                                _formatDateTime(
                                  _readDateTime(
                                    event['time'],
                                  ),
                                ),
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveAuditLog({
    required String bookingId,
    required String action,
    required String details,
  }) async {
    final DocumentReference<Map<String, dynamic>>
        reference = _firestore
            .collection(
              'hotel_booking_audit_logs',
            )
            .doc();

    await reference.set(
      <String, dynamic>{
        'logId': reference.id,
        'hotelId': widget.hotelId,
        'bookingId': bookingId,
        'action': action,
        'details': details,
        'actorUserId':
            FirebaseAuth.instance.currentUser?.uid ??
                'hotel_admin_testing',
        'createdAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.45,
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _filterBookings(
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        bookings,
  ) {
    final search =
        _searchText.trim().toLowerCase();

    return bookings.where(
      (booking) {
        final data = booking.data();

        final status =
            data['bookingStatus']?.toString() ??
                'pending';

        final guestName =
            data['guestName']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final guestPhone =
            data['guestPhone']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final roomName =
            data['roomName']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final bookingId =
            (data['bookingId'] ??
                    booking.id)
                .toString()
                .toLowerCase();

        final searchMatch =
            search.isEmpty ||
                guestName.contains(search) ||
                guestPhone.contains(search) ||
                roomName.contains(search) ||
                bookingId.contains(search);

        bool filterMatch = true;

        switch (_selectedFilter) {
          case 'pending':
            filterMatch =
                status == 'pending' ||
                    status ==
                        'pending_hotel_confirmation';
            break;
          case 'confirmed':
            filterMatch =
                status == 'confirmed';
            break;
          case 'active':
            filterMatch =
                status == 'checked_in' ||
                    status == 'active' ||
                    status == 'in_stay';
            break;
          case 'completed':
            filterMatch =
                status == 'completed' ||
                    status == 'checked_out';
            break;
          case 'cancelled':
            filterMatch =
                status == 'cancelled' ||
                    status == 'rejected';
            break;
        }

        return searchMatch && filterMatch;
      },
    ).toList();
  }

  Widget _alertRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        top: 8,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    final color =
        _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
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
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
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
    );
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'checked_in':
      case 'active':
      case 'in_stay':
        return Colors.blue;
      case 'completed':
      case 'checked_out':
        return Colors.purple;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(
    String status,
  ) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'checked_in':
      case 'active':
      case 'in_stay':
        return Icons.hotel_outlined;
      case 'completed':
      case 'checked_out':
        return Icons.task_alt;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.pending_actions_outlined;
    }
  }

  static String _statusLabel(
    String status,
  ) {
    switch (status) {
      case 'all':
        return 'All';
      case 'pending':
      case 'pending_hotel_confirmation':
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
      case 'paid':
        return 'Paid';
      case 'cash_pending':
        return 'Cash Pending';
      case 'cash_received':
        return 'Cash Received';
      case 'paid_testing':
        return 'Paid (Testing)';
      case 'extension_payment_pending':
        return 'Extension Payment Pending';
      case 'testing_bypassed':
        return 'Testing Bypass';
      default:
        return status;
    }
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

    final day =
        value.day.toString().padLeft(2, '0');

    final month =
        value.month.toString().padLeft(2, '0');

    return '$day/$month/${value.year}';
  }

  int _readInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  int _calculateNights(
    DateTime checkIn,
    DateTime checkOut,
  ) {
    final int value =
        checkOut.difference(checkIn).inDays;

    return value > 0 ? value : 0;
  }

  String _formatDateTime(
    DateTime value,
  ) {
    if (value.millisecondsSinceEpoch == 0) {
      return 'Not available';
    }

    final String day =
        value.day.toString().padLeft(2, '0');
    final String month =
        value.month.toString().padLeft(2, '0');
    final String hour =
        value.hour.toString().padLeft(2, '0');
    final String minute =
        value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year} $hour:$minute';
  }

  String _formatMoney(
    double amount,
  ) {
    final value =
        amount.toStringAsFixed(0);

    return value.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
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

