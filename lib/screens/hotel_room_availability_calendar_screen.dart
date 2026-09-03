import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HotelRoomAvailabilityCalendarScreen
    extends StatefulWidget {
  const HotelRoomAvailabilityCalendarScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelRoomAvailabilityCalendarScreen> createState() =>
      _HotelRoomAvailabilityCalendarScreenState();
}

class _HotelRoomAvailabilityCalendarScreenState
    extends State<HotelRoomAvailabilityCalendarScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  DateTime _selectedDate = DateTime.now();
  bool _isUpdating = false;

  DateTime get _dayStart => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

  DateTime get _dayEnd => _dayStart.add(
        const Duration(days: 1),
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
          'Room Availability Calendar',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: yellow,
          backgroundColor: darkCard,
          onRefresh: () async {
            await _firestore
                .collection('hotel_rooms')
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
              _dateSelector(),

              const SizedBox(height: 16),

              _availabilitySummary(),

              const SizedBox(height: 18),

              _businessSummary(),

              const SizedBox(height: 18),

              _monthlyCalendar(),

              const SizedBox(height: 18),

              _sevenDayOccupancyGraph(),

              const SizedBox(height: 18),

              _bookingConflicts(),

              const SizedBox(height: 18),

              const Text(
                'Rooms',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _roomsList(),

              const SizedBox(height: 18),

              _legend(),

              const SizedBox(height: 14),

              _noticeCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateSelector() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.24,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: yellow,
              ),
              SizedBox(width: 9),
              Text(
                'Selected Date',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: darkBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(_selectedDate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.edit_calendar_outlined,
                    color: yellow,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedDate =
                          _selectedDate.subtract(
                        const Duration(days: 1),
                      );
                    });
                  },
                  icon: const Icon(
                    Icons.chevron_left,
                  ),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                    });
                  },
                  icon: const Icon(
                    Icons.today_outlined,
                  ),
                  label: const Text('Today'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedDate =
                          _selectedDate.add(
                        const Duration(days: 1),
                      );
                    });
                  },
                  icon: const Icon(
                    Icons.chevron_right,
                  ),
                  label: const Text('Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _availabilitySummary() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('hotel_rooms')
          .where(
            'hotelId',
            isEqualTo: widget.hotelId,
          )
          .snapshots(),
      builder: (
        context,
        AsyncSnapshot<
                QuerySnapshot<Map<String, dynamic>>>
            roomSnapshot,
      ) {
        if (roomSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: yellow,
            ),
          );
        }

        final rooms = roomSnapshot.data?.docs ??
            <QueryDocumentSnapshot<
                Map<String, dynamic>>>[];

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('hotel_bookings')
              .where(
                'hotelId',
                isEqualTo: widget.hotelId,
              )
              .snapshots(),
          builder: (
            context,
            AsyncSnapshot<
                    QuerySnapshot<Map<String, dynamic>>>
                bookingSnapshot,
          ) {
            final bookings =
                bookingSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            int available = 0;
            int booked = 0;
            int occupied = 0;
            int housekeeping = 0;
            int maintenance = 0;

            for (final room in rooms) {
              final data = room.data();

              final String roomId =
                  data['roomId']?.toString() ??
                      room.id;

              final String status =
                  _resolveRoomStatus(
                roomId: roomId,
                roomData: data,
                bookings: bookings,
              );

              switch (status) {
                case 'booked':
                  booked++;
                  break;
                case 'occupied':
                  occupied++;
                  break;
                case 'housekeeping':
                  housekeeping++;
                  break;
                case 'maintenance':
                  maintenance++;
                  break;
                default:
                  available++;
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
                  title: 'Available',
                  value: '$available',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
                _summaryTile(
                  title: 'Booked',
                  value: '$booked',
                  icon: Icons.event_busy_outlined,
                  color: Colors.orange,
                ),
                _summaryTile(
                  title: 'Occupied',
                  value: '$occupied',
                  icon: Icons.hotel,
                  color: Colors.blue,
                ),
                _summaryTile(
                  title: 'Housekeeping',
                  value: '$housekeeping',
                  icon: Icons.cleaning_services_outlined,
                  color: Colors.purple,
                ),
                _summaryTile(
                  title: 'Maintenance',
                  value: '$maintenance',
                  icon: Icons.build_outlined,
                  color: Colors.redAccent,
                ),
                _summaryTile(
                  title: 'Total Rooms',
                  value: '${rooms.length}',
                  icon: Icons.meeting_room_outlined,
                  color: yellow,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _businessSummary() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('hotel_rooms')
          .where(
            'hotelId',
            isEqualTo: widget.hotelId,
          )
          .snapshots(),
      builder: (context, roomSnapshot) {
        final rooms = roomSnapshot.data?.docs ??
            <QueryDocumentSnapshot<
                Map<String, dynamic>>>[];

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('hotel_bookings')
              .where(
                'hotelId',
                isEqualTo: widget.hotelId,
              )
              .snapshots(),
          builder: (context, bookingSnapshot) {
            final bookings = bookingSnapshot.data?.docs ??
                <QueryDocumentSnapshot<
                    Map<String, dynamic>>>[];

            int bookedOrOccupied = 0;
            int checkIns = 0;
            int checkOuts = 0;
            int pendingArrivals = 0;
            int lateCheckouts = 0;
            double dailyRevenue = 0;
            double monthlyRevenue = 0;

            for (final room in rooms) {
              final data = room.data();
              final roomId =
                  data['roomId']?.toString() ?? room.id;

              final status = _resolveRoomStatus(
                roomId: roomId,
                roomData: data,
                bookings: bookings,
              );

              if (status == 'booked' ||
                  status == 'occupied') {
                bookedOrOccupied++;
              }
            }

            final DateTime monthStart = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              1,
            );

            final DateTime nextMonthStart =
                _selectedDate.month == 12
                    ? DateTime(
                        _selectedDate.year + 1,
                        1,
                        1,
                      )
                    : DateTime(
                        _selectedDate.year,
                        _selectedDate.month + 1,
                        1,
                      );

            for (final booking in bookings) {
              final data = booking.data();
              final status =
                  data['bookingStatus']?.toString() ?? '';

              if (status == 'cancelled' ||
                  status == 'rejected') {
                continue;
              }

              final checkIn =
                  _readDateTime(data['checkIn']);
              final checkOut =
                  _readDateTime(data['checkOut']);

              if (_sameDay(checkIn, _selectedDate)) {
                checkIns++;

                if (status == 'confirmed' ||
                    status ==
                        'pending_hotel_confirmation') {
                  pendingArrivals++;
                }
              }

              if (_sameDay(checkOut, _selectedDate)) {
                checkOuts++;
              }

              if (data['lateCheckoutRequestStatus']
                          ?.toString() ==
                      'approved' &&
                  _sameDay(checkOut, _selectedDate)) {
                lateCheckouts++;
              }

              final double amount =
                  _readNumber(data['totalAmount']);

              if (_overlapsSelectedDate(
                checkIn: checkIn,
                checkOut: checkOut,
              )) {
                dailyRevenue += amount;
              }

              if (checkIn.isBefore(nextMonthStart) &&
                  checkOut.isAfter(monthStart)) {
                monthlyRevenue += amount;
              }
            }

            final double occupancy = rooms.isEmpty
                ? 0
                : (bookedOrOccupied / rooms.length) * 100;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.55,
                  children: [
                    _summaryTile(
                      title: 'Occupancy',
                      value:
                          '${occupancy.toStringAsFixed(0)}%',
                      icon: Icons.pie_chart_outline,
                      color: Colors.cyan,
                    ),
                    _summaryTile(
                      title: 'Daily Revenue',
                      value:
                          'PKR ${_formatMoney(dailyRevenue)}',
                      icon: Icons.today_outlined,
                      color: Colors.teal,
                    ),
                    _summaryTile(
                      title:
                          '${_monthName(_selectedDate.month)} Revenue',
                      value:
                          'PKR ${_formatMoney(monthlyRevenue)}',
                      icon: Icons.calendar_view_month,
                      color: Colors.green,
                    ),
                    _summaryTile(
                      title: 'Check-ins',
                      value: '$checkIns',
                      icon: Icons.login,
                      color: Colors.blue,
                    ),
                    _summaryTile(
                      title: 'Check-outs',
                      value: '$checkOuts',
                      icon: Icons.logout,
                      color: Colors.purple,
                    ),
                    _summaryTile(
                      title: 'Pending Arrivals',
                      value: '$pendingArrivals',
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                    ),
                    _summaryTile(
                      title: 'Late Check-outs',
                      value: '$lateCheckouts',
                      icon: Icons.more_time,
                      color: Colors.deepOrange,
                    ),
                    _summaryTile(
                      title: 'Total Rooms',
                      value: '${rooms.length}',
                      icon: Icons.meeting_room_outlined,
                      color: yellow,
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _monthlyCalendar() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('hotel_rooms')
          .where(
            'hotelId',
            isEqualTo: widget.hotelId,
          )
          .snapshots(),
      builder: (context, roomSnapshot) {
        final rooms = roomSnapshot.data?.docs ??
            <QueryDocumentSnapshot<
                Map<String, dynamic>>>[];

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('hotel_bookings')
              .where(
                'hotelId',
                isEqualTo: widget.hotelId,
              )
              .snapshots(),
          builder: (context, bookingSnapshot) {
            final bookings = bookingSnapshot.data?.docs ??
                <QueryDocumentSnapshot<
                    Map<String, dynamic>>>[];

            final int daysInMonth = DateTime(
              _selectedDate.year,
              _selectedDate.month + 1,
              0,
            ).day;

            final DateTime firstDay = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              1,
            );

            final int leadingSpaces =
                firstDay.weekday % 7;

            final List<Widget> cells = [];

            for (int i = 0; i < leadingSpaces; i++) {
              cells.add(const SizedBox.shrink());
            }

            for (int day = 1;
                day <= daysInMonth;
                day++) {
              final DateTime date = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                day,
              );

              int bookedCount = 0;
              int checkIns = 0;
              int checkOuts = 0;

              for (final booking in bookings) {
                final data = booking.data();
                final status =
                    data['bookingStatus']?.toString() ?? '';

                if (status == 'cancelled' ||
                    status == 'rejected') {
                  continue;
                }

                final checkIn =
                    _readDateTime(data['checkIn']);
                final checkOut =
                    _readDateTime(data['checkOut']);

                if (checkIn.isBefore(
                      date.add(
                        const Duration(days: 1),
                      ),
                    ) &&
                    checkOut.isAfter(date)) {
                  bookedCount++;
                }

                if (_sameDay(checkIn, date)) {
                  checkIns++;
                }

                if (_sameDay(checkOut, date)) {
                  checkOuts++;
                }
              }

              final double occupancy = rooms.isEmpty
                  ? 0
                  : min(
                      bookedCount / rooms.length,
                      1,
                    );

              final bool selected =
                  _sameDay(date, _selectedDate);

              cells.add(
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  borderRadius:
                      BorderRadius.circular(12),
                  child: Container(
                    padding:
                        const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: selected
                          ? yellow.withValues(
                              alpha: 0.22,
                            )
                          : darkCard,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? yellow
                            : _calendarColor(
                                occupancy,
                              ).withValues(
                                alpha: 0.42,
                              ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            color: selected
                                ? yellow
                                : Colors.white,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: occupancy,
                          minHeight: 4,
                          backgroundColor:
                              Colors.white12,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                            _calendarColor(
                              occupancy,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            if (checkIns > 0)
                              const Icon(
                                Icons.login,
                                size: 11,
                                color: Colors.blue,
                              ),
                            if (checkOuts > 0)
                              const Icon(
                                Icons.logout,
                                size: 11,
                                color: Colors.purple,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text('Sun',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10)),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('Mon',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10)),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('Tue',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10)),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('Wed',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10)),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('Thu',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10)),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('Fri',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10)),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('Sat',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 0.78,
                  children: cells,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sevenDayOccupancyGraph() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('hotel_rooms')
          .where(
            'hotelId',
            isEqualTo: widget.hotelId,
          )
          .snapshots(),
      builder: (context, roomSnapshot) {
        final rooms = roomSnapshot.data?.docs ??
            <QueryDocumentSnapshot<
                Map<String, dynamic>>>[];

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('hotel_bookings')
              .where(
                'hotelId',
                isEqualTo: widget.hotelId,
              )
              .snapshots(),
          builder: (context, bookingSnapshot) {
            final bookings = bookingSnapshot.data?.docs ??
                <QueryDocumentSnapshot<
                    Map<String, dynamic>>>[];

            final List<Map<String, dynamic>> values = [];

            for (int offset = -3;
                offset <= 3;
                offset++) {
              final DateTime date = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day + offset,
              );

              int booked = 0;

              for (final booking in bookings) {
                final data = booking.data();
                final status =
                    data['bookingStatus']?.toString() ?? '';

                if (status == 'cancelled' ||
                    status == 'rejected') {
                  continue;
                }

                final checkIn =
                    _readDateTime(data['checkIn']);
                final checkOut =
                    _readDateTime(data['checkOut']);

                if (checkIn.isBefore(
                      date.add(
                        const Duration(days: 1),
                      ),
                    ) &&
                    checkOut.isAfter(date)) {
                  booked++;
                }
              }

              final double occupancy = rooms.isEmpty
                  ? 0
                  : min(
                      booked / rooms.length,
                      1,
                    );

              values.add({
                'date': date,
                'occupancy': occupancy,
              });
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: darkCard,
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    '7-Day Occupancy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...values.map((item) {
                    final DateTime date =
                        item['date'] as DateTime;
                    final double occupancy =
                        item['occupancy'] as double;

                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text(
                              _weekdayName(
                                date.weekday,
                              ),
                              style:
                                  const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Expanded(
                            child:
                                LinearProgressIndicator(
                              value: occupancy,
                              minHeight: 10,
                              backgroundColor:
                                  Colors.white12,
                              valueColor:
                                  AlwaysStoppedAnimation<
                                      Color>(
                                _calendarColor(
                                  occupancy,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 42,
                            child: Text(
                              '${(occupancy * 100).toStringAsFixed(0)}%',
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
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _bookingConflicts() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('hotel_bookings')
          .where(
            'hotelId',
            isEqualTo: widget.hotelId,
          )
          .snapshots(),
      builder: (context, snapshot) {
        final bookings = snapshot.data?.docs ??
            <QueryDocumentSnapshot<
                Map<String, dynamic>>>[];

        final Map<String, List<Map<String, dynamic>>>
            grouped = {};

        for (final booking in bookings) {
          final data = booking.data();
          final status =
              data['bookingStatus']?.toString() ?? '';

          if (status == 'cancelled' ||
              status == 'rejected') {
            continue;
          }

          final roomId =
              data['roomId']?.toString() ?? '';

          if (roomId.isEmpty) {
            continue;
          }

          grouped
              .putIfAbsent(
                roomId,
                () => [],
              )
              .add({
            ...data,
            '_documentId': booking.id,
          });
        }

        final List<Map<String, dynamic>> conflicts =
            [];

        grouped.forEach((roomId, roomBookings) {
          for (int i = 0;
              i < roomBookings.length;
              i++) {
            for (int j = i + 1;
                j < roomBookings.length;
                j++) {
              final a = roomBookings[i];
              final b = roomBookings[j];

              final aIn =
                  _readDateTime(a['checkIn']);
              final aOut =
                  _readDateTime(a['checkOut']);
              final bIn =
                  _readDateTime(b['checkIn']);
              final bOut =
                  _readDateTime(b['checkOut']);

              final overlaps =
                  aIn.isBefore(bOut) &&
                      aOut.isAfter(bIn);

              if (overlaps) {
                conflicts.add({
                  'roomId': roomId,
                  'roomNumber':
                      a['roomNumber'] ??
                          b['roomNumber'] ??
                          roomId,
                  'bookingA':
                      a['_documentId'],
                  'bookingB':
                      b['_documentId'],
                });
              }
            }
          }
        });

        if (conflicts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  Colors.green.withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color:
                    Colors.green.withValues(
                  alpha: 0.28,
                ),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: Colors.green,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'No room booking conflicts detected.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Conflicts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...conflicts.map(
              (conflict) => Container(
                width: double.infinity,
                margin:
                    const EdgeInsets.only(
                  bottom: 8,
                ),
                padding:
                    const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color:
                      Colors.red.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  border: Border.all(
                    color:
                        Colors.red.withValues(
                      alpha: 0.34,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Room ${conflict['roomNumber']} has overlapping bookings ${conflict['bookingA']} and ${conflict['bookingB']}.',
                        style:
                            const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
          Icon(
            icon,
            color: color,
            size: 24,
          ),
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

  Widget _roomsList() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('hotel_rooms')
          .where(
            'hotelId',
            isEqualTo: widget.hotelId,
          )
          .snapshots(),
      builder: (
        context,
        AsyncSnapshot<
                QuerySnapshot<Map<String, dynamic>>>
            roomSnapshot,
      ) {
        if (roomSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                color: yellow,
              ),
            ),
          );
        }

        if (roomSnapshot.hasError) {
          return _messageState(
            icon: Icons.error_outline,
            title: 'Unable to Load Rooms',
            message: roomSnapshot.error.toString(),
          );
        }

        final rooms = roomSnapshot.data?.docs ??
            <QueryDocumentSnapshot<
                Map<String, dynamic>>>[];

        rooms.sort(
          (a, b) {
            final aNumber =
                a.data()['roomNumber']?.toString() ??
                    a.id;

            final bNumber =
                b.data()['roomNumber']?.toString() ??
                    b.id;

            return aNumber.compareTo(bNumber);
          },
        );

        if (rooms.isEmpty) {
          return _messageState(
            icon: Icons.meeting_room_outlined,
            title: 'No Rooms Found',
            message:
                'Add rooms from Room Management before using the availability calendar.',
          );
        }

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('hotel_bookings')
              .where(
                'hotelId',
                isEqualTo: widget.hotelId,
              )
              .snapshots(),
          builder: (
            context,
            AsyncSnapshot<
                    QuerySnapshot<Map<String, dynamic>>>
                bookingSnapshot,
          ) {
            final bookings =
                bookingSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            return Column(
              children: rooms.map(
                (room) {
                  return _roomCard(
                    room: room,
                    bookings: bookings,
                  );
                },
              ).toList(),
            );
          },
        );
      },
    );
  }

  Widget _roomCard({
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        room,
    required List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>
        bookings,
  }) {
    final data = room.data();

    final String roomId =
        data['roomId']?.toString() ?? room.id;

    final String roomNumber =
        data['roomNumber']?.toString() ??
            roomId;

    final String roomName =
        data['name']?.toString() ??
            data['roomName']?.toString() ??
            data['roomType']?.toString() ??
            'Room';

    final double price =
        _readNumber(
      data['pricePerNight'] ??
          data['price'] ??
          data['roomPrice'],
    );

    final String status =
        _resolveRoomStatus(
      roomId: roomId,
      roomData: data,
      bookings: bookings,
    );

    final Map<String, dynamic>? activeBooking =
        _findBookingForRoom(
      roomId: roomId,
      bookings: bookings,
    );

    final Color statusColor =
        _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 11,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
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
                width: 48,
                height: 48,
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
                      'Room $roomNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roomName,
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
          const SizedBox(height: 12),
          _detailRow(
            'Night Price',
            price <= 0
                ? 'Not set'
                : 'PKR ${_formatMoney(price)}',
          ),
          if (activeBooking != null) ...[
            _detailRow(
              'Guest',
              activeBooking['guestName']
                      ?.toString() ??
                  'Guest',
            ),
            _detailRow(
              'Booking Status',
              _statusLabel(
                activeBooking['bookingStatus']
                        ?.toString() ??
                    '',
              ),
            ),
            _detailRow(
              'Stay',
              '${_formatDate(_readDateTime(activeBooking['checkIn']))} - '
                  '${_formatDate(_readDateTime(activeBooking['checkOut']))}',
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUpdating
                      ? null
                      : () {
                          _showStatusSheet(
                            roomId: roomId,
                            roomNumber:
                                roomNumber,
                            currentStatus:
                                status,
                          );
                        },
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label: const Text(
                    'Change Status',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _resolveRoomStatus({
    required String roomId,
    required Map<String, dynamic> roomData,
    required List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>
        bookings,
  }) {
    final String manualStatus =
        roomData['manualStatus']?.toString() ??
            roomData['status']?.toString() ??
            'available';

    if (manualStatus == 'maintenance' ||
        manualStatus == 'housekeeping' ||
        manualStatus == 'blocked') {
      return manualStatus == 'blocked'
          ? 'maintenance'
          : manualStatus;
    }

    final Map<String, dynamic>? booking =
        _findBookingForRoom(
      roomId: roomId,
      bookings: bookings,
    );

    if (booking == null) {
      return 'available';
    }

    final String bookingStatus =
        booking['bookingStatus']?.toString() ??
            '';

    if (bookingStatus == 'checked_in' ||
        bookingStatus == 'active' ||
        bookingStatus == 'in_stay') {
      return 'occupied';
    }

    if (bookingStatus == 'confirmed' ||
        bookingStatus ==
            'pending_hotel_confirmation') {
      return 'booked';
    }

    return 'available';
  }

  Map<String, dynamic>? _findBookingForRoom({
    required String roomId,
    required List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>
        bookings,
  }) {
    for (final booking in bookings) {
      final data = booking.data();

      final String bookingRoomId =
          data['roomId']?.toString() ?? '';

      if (bookingRoomId != roomId) {
        continue;
      }

      final String status =
          data['bookingStatus']?.toString() ??
              '';

      const Set<String> activeStatuses =
          <String>{
        'pending_hotel_confirmation',
        'confirmed',
        'checked_in',
        'active',
        'in_stay',
      };

      if (!activeStatuses.contains(status)) {
        continue;
      }

      final DateTime checkIn =
          _readDateTime(data['checkIn']);

      final DateTime checkOut =
          _readDateTime(data['checkOut']);

      if (_overlapsSelectedDate(
        checkIn: checkIn,
        checkOut: checkOut,
      )) {
        return data;
      }
    }

    return null;
  }

  bool _overlapsSelectedDate({
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    if (checkIn.millisecondsSinceEpoch == 0 ||
        checkOut.millisecondsSinceEpoch == 0) {
      return false;
    }

    return checkIn.isBefore(_dayEnd) &&
        checkOut.isAfter(_dayStart);
  }

  Future<void> _showStatusSheet({
    required String roomId,
    required String roomNumber,
    required String currentStatus,
  }) async {
    const List<String> statuses = <String>[
      'available',
      'housekeeping',
      'maintenance',
    ];

    final String? selected =
        await showModalBottomSheet<String>(
      context: context,
      backgroundColor: darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Room $roomNumber Status',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                ...statuses.map(
                  (status) {
                    return ListTile(
                      leading: Icon(
                        _statusIcon(status),
                        color:
                            _statusColor(status),
                      ),
                      title: Text(
                        _statusLabel(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      trailing:
                          currentStatus == status
                              ? const Icon(
                                  Icons.check,
                                  color: yellow,
                                )
                              : null,
                      onTap: () {
                        Navigator.pop(
                          context,
                          status,
                        );
                      },
                    );
                  },
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

    await _updateManualStatus(
      roomId: roomId,
      status: selected,
    );
  }

  Future<void> _updateManualStatus({
    required String roomId,
    required String status,
  }) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await _firestore
          .collection('hotel_rooms')
          .doc(roomId)
          .set(
        <String, dynamic>{
          'manualStatus': status,
          'manualStatusDate':
              Timestamp.fromDate(_dayStart),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _showMessage(
        'Room status updated to ${_statusLabel(status)}.',
      );
    } catch (error) {
      _showMessage(
        'Unable to update room status: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime? selected =
        await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ),
      lastDate: DateTime.now().add(
        const Duration(days: 730),
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = selected;
    });
  }

  Widget _statusBadge(
    String status,
  ) {
    final Color color =
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
              textAlign: TextAlign.right,
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

  Widget _legend() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 10,
        children: [
          _legendItem(
            'Available',
            Colors.green,
          ),
          _legendItem(
            'Booked',
            Colors.orange,
          ),
          _legendItem(
            'Occupied',
            Colors.blue,
          ),
          _legendItem(
            'Housekeeping',
            Colors.purple,
          ),
          _legendItem(
            'Maintenance',
            Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _legendItem(
    String title,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
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

  Widget _noticeCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: yellow,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Availability, occupancy, revenue and conflicts are calculated from room status and booking dates. No background timer or per-second Firebase reads are used. Real payment remains bypassed.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                height: 1.4,
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
    return Container(
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
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
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
    );
  }

  bool _sameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  Color _calendarColor(
    double occupancy,
  ) {
    if (occupancy >= 0.95) {
      return Colors.redAccent;
    }

    if (occupancy >= 0.50) {
      return Colors.orange;
    }

    return Colors.green;
  }

  String _monthName(
    int month,
  ) {
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[
        max(1, min(month, 12)) - 1];
  }

  String _weekdayName(
    int weekday,
  ) {
    const days = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return days[
        max(1, min(weekday, 7)) - 1];
  }

  Color _statusColor(
    String status,
  ) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'booked':
        return Colors.orange;
      case 'occupied':
        return Colors.blue;
      case 'housekeeping':
        return Colors.purple;
      case 'maintenance':
        return Colors.redAccent;
      default:
        return yellow;
    }
  }

  IconData _statusIcon(
    String status,
  ) {
    switch (status) {
      case 'available':
        return Icons.check_circle_outline;
      case 'booked':
        return Icons.event_busy_outlined;
      case 'occupied':
        return Icons.hotel;
      case 'housekeeping':
        return Icons.cleaning_services_outlined;
      case 'maintenance':
        return Icons.build_outlined;
      default:
        return Icons.meeting_room_outlined;
    }
  }

  String _statusLabel(
    String status,
  ) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'booked':
        return 'Booked';
      case 'occupied':
        return 'Occupied';
      case 'housekeeping':
        return 'Housekeeping';
      case 'maintenance':
        return 'Maintenance';
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

