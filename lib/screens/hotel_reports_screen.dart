import 'package:flutter/material.dart';

import '../models/hotel_booking.dart';
import '../models/hotel_room.dart';
import '../services/hotel_booking_operations_service.dart';
import '../services/tourism_service.dart';

class HotelReportsScreen extends StatefulWidget {
  const HotelReportsScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelReportsScreen> createState() =>
      _HotelReportsScreenState();
}

class _HotelReportsScreenState
    extends State<HotelReportsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final HotelBookingOperationsService _bookingService =
      HotelBookingOperationsService();

  final TourismService _tourismService = TourismService();

  String _selectedPeriod = 'all';

  final List<String> _periods = const <String>[
    'today',
    'week',
    'month',
    'all',
  ];

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
          'Hotel Reports',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<HotelBooking>>(
          stream: _bookingService.hotelBookingsStream(
            widget.hotelId,
          ),
          builder: (
            context,
            AsyncSnapshot<List<HotelBooking>> snapshot,
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
                title: 'Unable to Load Reports',
                message: snapshot.error.toString(),
              );
            }

            final List<HotelBooking> allBookings =
                snapshot.data ?? <HotelBooking>[];

            final List<HotelBooking> bookings =
                _filterBookingsByPeriod(
              allBookings,
            );

            return FutureBuilder<List<HotelRoom>>(
              future: _tourismService.getHotelRooms(
                widget.hotelId,
              ),
              builder: (
                context,
                AsyncSnapshot<List<HotelRoom>> roomSnapshot,
              ) {
                final List<HotelRoom> rooms =
                    roomSnapshot.data ?? <HotelRoom>[];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    24,
                  ),
                  children: [
                    _periodSelector(),

                    const SizedBox(height: 16),

                    _summaryGrid(
                      bookings: bookings,
                      rooms: rooms,
                    ),

                    const SizedBox(height: 18),

                    _occupancyCard(
                      bookings: bookings,
                      rooms: rooms,
                    ),

                    const SizedBox(height: 18),

                    _earningsCard(bookings),

                    const SizedBox(height: 18),

                    _bookingStatusCard(bookings),

                    const SizedBox(height: 18),

                    _recentCompletedCard(bookings),

                    const SizedBox(height: 18),

                    _billingNotice(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _periodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periods.map(
          (period) {
            final bool selected =
                _selectedPeriod == period;

            return Padding(
              padding: const EdgeInsets.only(
                right: 8,
              ),
              child: ChoiceChip(
                selected: selected,
                label: Text(
                  _periodLabel(period),
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
                  fontWeight: FontWeight.bold,
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
                    _selectedPeriod = period;
                  });
                },
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _summaryGrid({
    required List<HotelBooking> bookings,
    required List<HotelRoom> rooms,
  }) {
    final int totalBookings = bookings.length;

    final int confirmed = bookings
        .where(
          (booking) =>
              booking.bookingStatus == 'confirmed',
        )
        .length;

    final int checkedIn = bookings
        .where(
          (booking) =>
              booking.bookingStatus == 'checked_in',
        )
        .length;

    final int completed = bookings
        .where(
          (booking) =>
              booking.bookingStatus == 'completed',
        )
        .length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _summaryCard(
          icon: Icons.book_online_outlined,
          title: 'Bookings',
          value: '$totalBookings',
        ),
        _summaryCard(
          icon: Icons.check_circle_outline,
          title: 'Confirmed',
          value: '$confirmed',
        ),
        _summaryCard(
          icon: Icons.hotel_outlined,
          title: 'Checked In',
          value: '$checkedIn',
        ),
        _summaryCard(
          icon: Icons.task_alt,
          title: 'Completed',
          value: '$completed',
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: yellow,
            size: 27,
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _occupancyCard({
    required List<HotelBooking> bookings,
    required List<HotelRoom> rooms,
  }) {
    final int activeStays = bookings
        .where(
          (booking) =>
              booking.bookingStatus == 'checked_in',
        )
        .fold<int>(
          0,
          (sum, booking) =>
              sum + booking.rooms,
        );

    final int totalRooms = rooms.length;

    final double occupancy = totalRooms == 0
        ? 0
        : (activeStays / totalRooms)
            .clamp(0, 1)
            .toDouble();

    return _sectionCard(
      title: 'Current Occupancy',
      icon: Icons.apartment_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${(occupancy * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$activeStays / $totalRooms rooms',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: occupancy,
              minHeight: 10,
              backgroundColor:
                  Colors.white.withValues(
                alpha: 0.06,
              ),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                yellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _earningsCard(
    List<HotelBooking> bookings,
  ) {
    final double totalSales = bookings
        .where(
          (booking) =>
              booking.bookingStatus != 'rejected' &&
              booking.bookingStatus != 'cancelled',
        )
        .fold<double>(
          0,
          (sum, booking) =>
              sum + booking.totalAmount,
        );

    final double received = bookings.fold<double>(
      0,
      (sum, booking) =>
          sum + booking.advanceAmount,
    );

    final double remaining = bookings
        .where(
          (booking) =>
              booking.bookingStatus != 'rejected' &&
              booking.bookingStatus != 'cancelled',
        )
        .fold<double>(
          0,
          (sum, booking) =>
              sum + booking.remainingAmount,
        );

    return _sectionCard(
      title: 'Earnings Summary',
      icon: Icons.payments_outlined,
      child: Column(
        children: [
          _reportRow(
            'Total Booking Value',
            'Rs. ${totalSales.toStringAsFixed(0)}',
          ),
          _reportRow(
            'Advance Received',
            'Rs. ${received.toStringAsFixed(0)}',
          ),
          _reportRow(
            'Remaining Amount',
            'Rs. ${remaining.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  Widget _bookingStatusCard(
    List<HotelBooking> bookings,
  ) {
    final Map<String, int> counts =
        <String, int>{
      'pending': 0,
      'confirmed': 0,
      'checked_in': 0,
      'completed': 0,
      'cancelled': 0,
      'rejected': 0,
      'no_show': 0,
    };

    for (final HotelBooking booking in bookings) {
      final String key =
          booking.bookingStatus ==
                  'pending_hotel_confirmation'
              ? 'pending'
              : booking.bookingStatus;

      if (counts.containsKey(key)) {
        counts[key] = counts[key]! + 1;
      }
    }

    return _sectionCard(
      title: 'Booking Status',
      icon: Icons.analytics_outlined,
      child: Column(
        children: counts.entries
            .where(
              (entry) => entry.value > 0,
            )
            .map(
              (entry) => _reportRow(
                _statusLabel(entry.key),
                '${entry.value}',
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _recentCompletedCard(
    List<HotelBooking> bookings,
  ) {
    final List<HotelBooking> completed =
        bookings
            .where(
              (booking) =>
                  booking.bookingStatus ==
                  'completed',
            )
            .take(5)
            .toList();

    return _sectionCard(
      title: 'Recent Completed Stays',
      icon: Icons.history,
      child: completed.isEmpty
          ? const Text(
              'No completed stays in this period.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            )
          : Column(
              children: completed
                  .map(
                    (booking) => Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  'Booking #${_shortId(booking.id)}',
                                  style:
                                      const TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(
                                  height: 3,
                                ),
                                Text(
                                  '${_formatDate(booking.checkIn)} - ${_formatDate(booking.checkOut)}',
                                  style:
                                      const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rs. ${booking.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: yellow,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: yellow,
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _reportRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _billingNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: yellow,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'These reports use booking records already stored in Firestore. Online settlement, payment reconciliation and downloadable invoices will be enabled after billing integration.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
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
                size: 48,
              ),
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

  List<HotelBooking> _filterBookingsByPeriod(
    List<HotelBooking> bookings,
  ) {
    if (_selectedPeriod == 'all') {
      return bookings;
    }

    final DateTime now = DateTime.now();

    DateTime startDate;

    switch (_selectedPeriod) {
      case 'today':
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        );
        break;
      case 'week':
        startDate = now.subtract(
          const Duration(days: 7),
        );
        break;
      case 'month':
        startDate = DateTime(
          now.year,
          now.month,
          1,
        );
        break;
      default:
        return bookings;
    }

    return bookings.where(
      (booking) {
        return !booking.createdAt.isBefore(
          startDate,
        );
      },
    ).toList();
  }

  String _periodLabel(
    String period,
  ) {
    switch (period) {
      case 'today':
        return 'Today';
      case 'week':
        return 'Last 7 Days';
      case 'month':
        return 'This Month';
      default:
        return 'All Time';
    }
  }

  String _statusLabel(
    String status,
  ) {
    switch (status) {
      case 'pending':
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
      case 'no_show':
        return 'No Show';
      default:
        return status;
    }
  }

  String _formatDate(
    DateTime date,
  ) {
    final String day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    final String month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    return '$day/$month/${date.year}';
  }

  String _shortId(
    String id,
  ) {
    if (id.length <= 8) {
      return id.toUpperCase();
    }

    return id
        .substring(0, 8)
        .toUpperCase();
  }
}
