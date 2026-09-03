import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HotelAnalyticsScreen extends StatefulWidget {
  const HotelAnalyticsScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelAnalyticsScreen> createState() =>
      _HotelAnalyticsScreenState();
}

class _HotelAnalyticsScreenState
    extends State<HotelAnalyticsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String _selectedPeriod = 'month';

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
          'Hotel Analytics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<
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
            if (bookingSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: yellow,
                ),
              );
            }

            if (bookingSnapshot.hasError) {
              return _messageState(
                icon: Icons.error_outline,
                title: 'Unable to Load Analytics',
                message:
                    bookingSnapshot.error.toString(),
              );
            }

            final List<QueryDocumentSnapshot<
                    Map<String, dynamic>>>
                allBookings =
                bookingSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            final List<QueryDocumentSnapshot<
                    Map<String, dynamic>>>
                filteredBookings =
                _filterByPeriod(allBookings);

            return FutureBuilder<_AnalyticsExtraData>(
              future: _loadExtraData(),
              builder: (
                context,
                AsyncSnapshot<_AnalyticsExtraData>
                    extraSnapshot,
              ) {
                final _AnalyticsExtraData extraData =
                    extraSnapshot.data ??
                        const _AnalyticsExtraData(
                          totalRooms: 0,
                          averageRating: 0,
                          totalReviews: 0,
                        );

                final _AnalyticsSummary summary =
                    _buildSummary(
                  bookings: filteredBookings,
                  totalRooms: extraData.totalRooms,
                  averageRating:
                      extraData.averageRating,
                  totalReviews:
                      extraData.totalReviews,
                );

                final List<_ChartPoint> chartData =
                    _buildChartData(
                  filteredBookings,
                );

                return RefreshIndicator(
                  color: yellow,
                  backgroundColor: darkCard,
                  onRefresh: () async {
                    await _loadExtraData();
                    setState(() {});
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      28,
                    ),
                    children: [
                      _periodSelector(),

                      const SizedBox(height: 16),

                      _overviewGrid(summary),

                      const SizedBox(height: 18),

                      _revenueCard(summary),

                      const SizedBox(height: 18),

                      _occupancyCard(summary),

                      const SizedBox(height: 18),

                      _chartCard(
                        title: 'Booking Trend',
                        subtitle:
                            'Bookings grouped by day',
                        points: chartData,
                        valueBuilder: (point) =>
                            point.bookings.toDouble(),
                        valueLabelBuilder: (point) =>
                            '${point.bookings}',
                      ),

                      const SizedBox(height: 18),

                      _chartCard(
                        title: 'Revenue Trend',
                        subtitle:
                            'Booking value grouped by day',
                        points: chartData,
                        valueBuilder: (point) =>
                            point.revenue,
                        valueLabelBuilder: (point) =>
                            'Rs. ${point.revenue.toStringAsFixed(0)}',
                      ),

                      const SizedBox(height: 18),

                      _bookingStatusCard(summary),

                      const SizedBox(height: 18),

                      _upcomingCheckInsCard(
                        filteredBookings,
                      ),

                      const SizedBox(height: 18),

                      _exportNotice(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _periodSelector() {
    const List<String> periods = <String>[
      'week',
      'month',
      'quarter',
      'all',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map(
          (String period) {
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

  Widget _overviewGrid(
    _AnalyticsSummary summary,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        _metricCard(
          icon: Icons.book_online_outlined,
          title: 'Bookings',
          value: '${summary.totalBookings}',
        ),
        _metricCard(
          icon: Icons.payments_outlined,
          title: 'Revenue',
          value:
              'Rs. ${summary.totalRevenue.toStringAsFixed(0)}',
        ),
        _metricCard(
          icon: Icons.groups_outlined,
          title: 'Guests',
          value: '${summary.totalGuests}',
        ),
        _metricCard(
          icon: Icons.star_outline,
          title: 'Average Rating',
          value: summary.totalReviews == 0
              ? 'No ratings'
              : summary.averageRating
                  .toStringAsFixed(1),
        ),
      ],
    );
  }

  Widget _metricCard({
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
            size: 28,
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _revenueCard(
    _AnalyticsSummary summary,
  ) {
    return _sectionCard(
      title: 'Revenue Summary',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        children: [
          _detailRow(
            'Gross Booking Value',
            'Rs. ${summary.totalRevenue.toStringAsFixed(0)}',
          ),
          _detailRow(
            'Advance Received',
            'Rs. ${summary.advanceReceived.toStringAsFixed(0)}',
          ),
          _detailRow(
            'Remaining Amount',
            'Rs. ${summary.remainingAmount.toStringAsFixed(0)}',
          ),
          _detailRow(
            'Average Booking Value',
            'Rs. ${summary.averageBookingValue.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  Widget _occupancyCard(
    _AnalyticsSummary summary,
  ) {
    return _sectionCard(
      title: 'Occupancy',
      icon: Icons.apartment_outlined,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${summary.occupancyRate.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${summary.activeRooms} / ${summary.totalRooms} rooms',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value:
                  (summary.occupancyRate / 100)
                      .clamp(0, 1),
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
          const SizedBox(height: 12),
          _detailRow(
            'Checked-in Guests',
            '${summary.checkedInBookings}',
          ),
          _detailRow(
            'Upcoming Check-ins',
            '${summary.upcomingCheckIns}',
          ),
        ],
      ),
    );
  }

  Widget _chartCard({
    required String title,
    required String subtitle,
    required List<_ChartPoint> points,
    required double Function(_ChartPoint)
        valueBuilder,
    required String Function(_ChartPoint)
        valueLabelBuilder,
  }) {
    final double maxValue = points.isEmpty
        ? 0
        : points
            .map(valueBuilder)
            .fold<double>(
              0,
              (previous, value) =>
                  value > previous
                      ? value
                      : previous,
            );

    return _sectionCard(
      title: title,
      icon: Icons.bar_chart_outlined,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          if (points.isEmpty)
            const Text(
              'No data available for this period.',
              style: TextStyle(
                color: Colors.grey,
              ),
            )
          else
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: points.map(
                  (point) {
                    final double value =
                        valueBuilder(point);

                    final double factor =
                        maxValue <= 0
                            ? 0
                            : value / maxValue;

                    return Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 3,
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.end,
                          children: [
                            Text(
                              valueLabelBuilder(
                                point,
                              ),
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              height:
                                  120 * factor,
                              constraints:
                                  const BoxConstraints(
                                minHeight: 4,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: yellow,
                                borderRadius:
                                    BorderRadius.circular(
                                  6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              point.label,
                              style:
                                  const TextStyle(
                                color: Colors.grey,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bookingStatusCard(
    _AnalyticsSummary summary,
  ) {
    return _sectionCard(
      title: 'Booking Status',
      icon: Icons.analytics_outlined,
      child: Column(
        children: [
          _statusProgress(
            title: 'Confirmed',
            value: summary.confirmedBookings,
            total: summary.totalBookings,
          ),
          _statusProgress(
            title: 'Checked In',
            value: summary.checkedInBookings,
            total: summary.totalBookings,
          ),
          _statusProgress(
            title: 'Completed',
            value: summary.completedBookings,
            total: summary.totalBookings,
          ),
          _statusProgress(
            title: 'Cancelled',
            value: summary.cancelledBookings,
            total: summary.totalBookings,
          ),
          _statusProgress(
            title: 'No Show',
            value: summary.noShowBookings,
            total: summary.totalBookings,
          ),
        ],
      ),
    );
  }

  Widget _statusProgress({
    required String title,
    required int value,
    required int total,
  }) {
    final double ratio =
        total <= 0 ? 0 : value / total;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Column(
        children: [
          Row(
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
              Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 7,
              backgroundColor:
                  Colors.white.withValues(
                alpha: 0.05,
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

  Widget _upcomingCheckInsCard(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        bookings,
  ) {
    final DateTime now = DateTime.now();

    final List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        upcoming = bookings.where(
      (document) {
        final Map<String, dynamic> data =
            document.data();

        final String status =
            data['bookingStatus']?.toString() ??
                '';

        final DateTime checkIn =
            _readDateTime(
          data['checkIn'],
        );

        return status == 'confirmed' &&
            checkIn.isAfter(
              now.subtract(
                const Duration(hours: 12),
              ),
            );
      },
    ).toList();

    upcoming.sort(
      (a, b) => _readDateTime(
        a.data()['checkIn'],
      ).compareTo(
        _readDateTime(
          b.data()['checkIn'],
        ),
      ),
    );

    final List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        visible =
        upcoming.take(5).toList();

    return _sectionCard(
      title: 'Upcoming Check-ins',
      icon: Icons.login,
      child: visible.isEmpty
          ? const Text(
              'No upcoming confirmed check-ins.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            )
          : Column(
              children: visible.map(
                (document) {
                  final Map<String, dynamic>
                      data = document.data();

                  final DateTime checkIn =
                      _readDateTime(
                    data['checkIn'],
                  );

                  final String roomName =
                      data['roomName']
                              ?.toString() ??
                          data['roomType']
                              ?.toString() ??
                          'Hotel Room';

                  final String guestName =
                      data['guestName']
                              ?.toString() ??
                          'Guest';

                  return Container(
                    margin:
                        const EdgeInsets.only(
                      bottom: 10,
                    ),
                    padding:
                        const EdgeInsets.all(12),
                    decoration:
                        BoxDecoration(
                      color: darkBackground,
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: yellow,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                guestName,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                roomName,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatDate(
                            checkIn,
                          ),
                          style:
                              const TextStyle(
                            color: yellow,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
            ),
    );
  }

  Widget _exportNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.download_outlined,
            color: yellow,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Analytics uses live Firestore booking data. PDF/Excel export and automated financial statements will be enabled in the final reporting and billing phase.',
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
        borderRadius:
            BorderRadius.circular(17),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
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

  Widget _detailRow(
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
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<_AnalyticsExtraData>
      _loadExtraData() async {
    final QuerySnapshot<Map<String, dynamic>>
        roomsSnapshot = await _firestore
            .collection('hotel_rooms')
            .where(
              'hotelId',
              isEqualTo: widget.hotelId,
            )
            .get();

    final QuerySnapshot<Map<String, dynamic>>
        reviewSnapshot = await _firestore
            .collection('hotel_reviews')
            .where(
              'hotelId',
              isEqualTo: widget.hotelId,
            )
            .get();

    double ratingTotal = 0;

    for (final document in reviewSnapshot.docs) {
      ratingTotal += _readNumber(
        document.data()['rating'],
      );
    }

    final double averageRating =
        reviewSnapshot.docs.isEmpty
            ? 0
            : ratingTotal /
                reviewSnapshot.docs.length;

    return _AnalyticsExtraData(
      totalRooms: roomsSnapshot.docs.length,
      averageRating: averageRating,
      totalReviews: reviewSnapshot.docs.length,
    );
  }

  _AnalyticsSummary _buildSummary({
    required List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        bookings,
    required int totalRooms,
    required double averageRating,
    required int totalReviews,
  }) {
    int confirmedBookings = 0;
    int checkedInBookings = 0;
    int completedBookings = 0;
    int cancelledBookings = 0;
    int noShowBookings = 0;
    int totalGuests = 0;
    int activeRooms = 0;
    int upcomingCheckIns = 0;

    double totalRevenue = 0;
    double advanceReceived = 0;
    double remainingAmount = 0;

    final DateTime now = DateTime.now();

    for (final document in bookings) {
      final Map<String, dynamic> data =
          document.data();

      final String status =
          data['bookingStatus']?.toString() ??
              'pending';

      final int guests = _readInt(
        data['guests'],
      );

      final int rooms = _readInt(
        data['rooms'],
      );

      final DateTime checkIn =
          _readDateTime(
        data['checkIn'],
      );

      totalGuests += guests;

      if (status == 'confirmed') {
        confirmedBookings++;

        if (checkIn.isAfter(
          now.subtract(
            const Duration(hours: 12),
          ),
        )) {
          upcomingCheckIns++;
        }
      } else if (status == 'checked_in') {
        checkedInBookings++;
        activeRooms += rooms <= 0 ? 1 : rooms;
      } else if (status == 'completed') {
        completedBookings++;
      } else if (status == 'cancelled' ||
          status == 'rejected') {
        cancelledBookings++;
      } else if (status == 'no_show') {
        noShowBookings++;
      }

      if (status != 'cancelled' &&
          status != 'rejected') {
        totalRevenue += _readNumber(
          data['totalAmount'],
        );

        advanceReceived += _readNumber(
          data['advanceAmount'],
        );

        remainingAmount += _readNumber(
          data['remainingAmount'],
        );
      }
    }

    final int totalBookings = bookings.length;

    final double occupancyRate =
        totalRooms <= 0
            ? 0
            : (activeRooms / totalRooms) * 100;

    final double averageBookingValue =
        totalBookings <= 0
            ? 0
            : totalRevenue / totalBookings;

    return _AnalyticsSummary(
      totalBookings: totalBookings,
      confirmedBookings: confirmedBookings,
      checkedInBookings: checkedInBookings,
      completedBookings: completedBookings,
      cancelledBookings: cancelledBookings,
      noShowBookings: noShowBookings,
      totalGuests: totalGuests,
      totalRevenue: totalRevenue,
      advanceReceived: advanceReceived,
      remainingAmount: remainingAmount,
      averageBookingValue:
          averageBookingValue,
      totalRooms: totalRooms,
      activeRooms: activeRooms,
      occupancyRate:
          occupancyRate.clamp(0, 100),
      averageRating: averageRating,
      totalReviews: totalReviews,
      upcomingCheckIns: upcomingCheckIns,
    );
  }

  List<QueryDocumentSnapshot<
          Map<String, dynamic>>>
      _filterByPeriod(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        bookings,
  ) {
    if (_selectedPeriod == 'all') {
      return bookings;
    }

    final DateTime now = DateTime.now();

    DateTime startDate;

    switch (_selectedPeriod) {
      case 'week':
        startDate = now.subtract(
          const Duration(days: 7),
        );
        break;
      case 'quarter':
        startDate = DateTime(
          now.year,
          now.month - 2,
          1,
        );
        break;
      case 'month':
      default:
        startDate = DateTime(
          now.year,
          now.month,
          1,
        );
        break;
    }

    return bookings.where(
      (document) {
        final Map<String, dynamic> data =
            document.data();

        final DateTime createdAt =
            _readDateTime(
          data['createdAt'],
        );

        return !createdAt.isBefore(
          startDate,
        );
      },
    ).toList();
  }

  List<_ChartPoint> _buildChartData(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        bookings,
  ) {
    final Map<String, _ChartPoint>
        grouped = <String, _ChartPoint>{};

    for (final document in bookings) {
      final Map<String, dynamic> data =
          document.data();

      final DateTime date =
          _readDateTime(
        data['createdAt'],
      );

      if (date.millisecondsSinceEpoch == 0) {
        continue;
      }

      final String key =
          '${date.year}-${date.month}-${date.day}';

      final String label =
          '${date.day}/${date.month}';

      final double revenue =
          _readNumber(
        data['totalAmount'],
      );

      final _ChartPoint existing =
          grouped[key] ??
              _ChartPoint(
                date: DateTime(
                  date.year,
                  date.month,
                  date.day,
                ),
                label: label,
                bookings: 0,
                revenue: 0,
              );

      grouped[key] = existing.copyWith(
        bookings: existing.bookings + 1,
        revenue: existing.revenue + revenue,
      );
    }

    final List<_ChartPoint> points =
        grouped.values.toList()
          ..sort(
            (a, b) =>
                a.date.compareTo(b.date),
          );

    if (points.length <= 7) {
      return points;
    }

    return points.sublist(
      points.length - 7,
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

  String _periodLabel(
    String period,
  ) {
    switch (period) {
      case 'week':
        return 'Last 7 Days';
      case 'quarter':
        return 'Last 3 Months';
      case 'all':
        return 'All Time';
      default:
        return 'This Month';
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
    DateTime date,
  ) {
    if (date.millisecondsSinceEpoch == 0) {
      return 'Not set';
    }

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
}

class _AnalyticsExtraData {
  const _AnalyticsExtraData({
    required this.totalRooms,
    required this.averageRating,
    required this.totalReviews,
  });

  final int totalRooms;
  final double averageRating;
  final int totalReviews;
}

class _AnalyticsSummary {
  const _AnalyticsSummary({
    required this.totalBookings,
    required this.confirmedBookings,
    required this.checkedInBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.noShowBookings,
    required this.totalGuests,
    required this.totalRevenue,
    required this.advanceReceived,
    required this.remainingAmount,
    required this.averageBookingValue,
    required this.totalRooms,
    required this.activeRooms,
    required this.occupancyRate,
    required this.averageRating,
    required this.totalReviews,
    required this.upcomingCheckIns,
  });

  final int totalBookings;
  final int confirmedBookings;
  final int checkedInBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int noShowBookings;
  final int totalGuests;
  final double totalRevenue;
  final double advanceReceived;
  final double remainingAmount;
  final double averageBookingValue;
  final int totalRooms;
  final int activeRooms;
  final double occupancyRate;
  final double averageRating;
  final int totalReviews;
  final int upcomingCheckIns;
}

class _ChartPoint {
  const _ChartPoint({
    required this.date,
    required this.label,
    required this.bookings,
    required this.revenue,
  });

  final DateTime date;
  final String label;
  final int bookings;
  final double revenue;

  _ChartPoint copyWith({
    int? bookings,
    double? revenue,
  }) {
    return _ChartPoint(
      date: date,
      label: label,
      bookings: bookings ?? this.bookings,
      revenue: revenue ?? this.revenue,
    );
  }
}
