import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TourismReportsAnalyticsScreen extends StatefulWidget {
  const TourismReportsAnalyticsScreen({
    super.key,
  });

  @override
  State<TourismReportsAnalyticsScreen> createState() =>
      _TourismReportsAnalyticsScreenState();
}

class _TourismReportsAnalyticsScreenState
    extends State<TourismReportsAnalyticsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedRange = 'all';

  final List<String> _rangeFilters = const <String>[
    'all',
    'today',
    'week',
    'month',
    'year',
    'custom',
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
          'Tourism Reports & Analytics',
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
              .collection('tour_bookings')
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
                title:
                    'Unable to Load Analytics',
                message:
                    bookingSnapshot.error.toString(),
              );
            }

            return StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection(
                    'tour_guide_applications',
                  )
                  .snapshots(),
              builder: (
                context,
                guideSnapshot,
              ) {
                return StreamBuilder<
                    QuerySnapshot<
                        Map<String, dynamic>>>(
                  stream: _firestore
                      .collection(
                        'tourism_driver_applications',
                      )
                      .snapshots(),
                  builder: (
                    context,
                    driverSnapshot,
                  ) {
                    return StreamBuilder<
                        QuerySnapshot<
                            Map<String, dynamic>>>(
                      stream: _firestore
                          .collection(
                            'tour_packages',
                          )
                          .snapshots(),
                      builder: (
                        context,
                        packageSnapshot,
                      ) {
                        final bookings =
                            bookingSnapshot
                                    .data?.docs ??
                                <QueryDocumentSnapshot<
                                    Map<String,
                                        dynamic>>>[];

                        final guides =
                            guideSnapshot.data?.docs ??
                                <QueryDocumentSnapshot<
                                    Map<String,
                                        dynamic>>>[];

                        final drivers =
                            driverSnapshot.data?.docs ??
                                <QueryDocumentSnapshot<
                                    Map<String,
                                        dynamic>>>[];

                        final packages =
                            packageSnapshot.data?.docs ??
                                <QueryDocumentSnapshot<
                                    Map<String,
                                        dynamic>>>[];

                        final filteredBookings =
                            bookings.where(
                          (document) {
                            return _matchesDateRange(
                              _readDateTime(
                                document.data()[
                                        'createdAt'] ??
                                    document.data()[
                                        'startDate'],
                              ),
                            );
                          },
                        ).toList();

                        final analytics =
                            _buildAnalytics(
                          filteredBookings,
                          guides,
                          drivers,
                          packages,
                        );

                        return RefreshIndicator(
                          color: yellow,
                          backgroundColor:
                              darkCard,
                          onRefresh:
                              _refreshAnalytics,
                          child:
                              SingleChildScrollView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(
                              16,
                              16,
                              16,
                              30,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                _headerCard(),
                                const SizedBox(
                                  height: 16,
                                ),
                                _rangeFiltersBar(),
                                if (_selectedRange ==
                                    'custom') ...[
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  _customDateRange(),
                                ],
                                const SizedBox(
                                  height: 18,
                                ),
                                _revenueSection(
                                  analytics,
                                ),
                                const SizedBox(
                                  height: 18,
                                ),
                                _bookingSection(
                                  analytics,
                                ),
                                const SizedBox(
                                  height: 18,
                                ),
                                _performanceSection(
                                  analytics,
                                ),
                                const SizedBox(
                                  height: 18,
                                ),
                                _popularDestinations(
                                  analytics
                                      .destinationCounts,
                                ),
                                const SizedBox(
                                  height: 18,
                                ),
                                _popularPackages(
                                  analytics
                                      .packageCounts,
                                ),
                                const SizedBox(
                                  height: 18,
                                ),
                                _vehicleUsage(
                                  analytics
                                      .vehicleCounts,
                                ),
                                const SizedBox(
                                  height: 18,
                                ),
                                _noticeCard(),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.analytics_outlined,
            color: yellow,
            size: 34,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Tourism Business Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Revenue, booking, driver, guide, package and destination performance.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeFiltersBar() {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _rangeFilters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (
          context,
          index,
        ) {
          final range =
              _rangeFilters[index];

          final bool selected =
              _selectedRange == range;

          return ChoiceChip(
            selected: selected,
            label: Text(
              _rangeLabel(range),
            ),
            selectedColor:
                yellow.withValues(
              alpha: 0.24,
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
                _selectedRange = range;

                if (range != 'custom') {
                  _startDate = null;
                  _endDate = null;
                }
              });
            },
          );
        },
      ),
    );
  }

  Widget _customDateRange() {
    return Row(
      children: [
        Expanded(
          child: _dateCard(
            title: 'Start Date',
            date: _startDate,
            onTap: _selectStartDate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _dateCard(
            title: 'End Date',
            date: _endDate,
            onTap: _selectEndDate,
          ),
        ),
      ],
    );
  }

  Widget _dateCard({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: yellow,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    date == null
                        ? 'Select'
                        : _formatDate(date),
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
          ],
        ),
      ),
    );
  }

  Widget _revenueSection(
    _TourismAnalytics analytics,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
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
          childAspectRatio: 1.48,
          children: [
            _metricCard(
              title: 'Total Revenue',
              value:
                  'PKR ${_money(analytics.totalRevenue)}',
              icon:
                  Icons.payments_outlined,
              color: Colors.green,
            ),
            _metricCard(
              title:
                  'Average Booking Value',
              value:
                  'PKR ${_money(analytics.averageBookingValue)}',
              icon:
                  Icons.calculate_outlined,
              color: Colors.blue,
            ),
            _metricCard(
              title: 'Refund Total',
              value:
                  'PKR ${_money(analytics.refundTotal)}',
              icon:
                  Icons.currency_exchange_outlined,
              color: Colors.redAccent,
            ),
            _metricCard(
              title:
                  'Pending Payments',
              value:
                  'PKR ${_money(analytics.pendingPayments)}',
              icon:
                  Icons.pending_actions_outlined,
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _bookingSection(
    _TourismAnalytics analytics,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Booking Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
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
          childAspectRatio: 1.48,
          children: [
            _metricCard(
              title: 'Total Bookings',
              value:
                  '${analytics.totalBookings}',
              icon:
                  Icons.book_online_outlined,
              color: yellow,
            ),
            _metricCard(
              title:
                  'Pending Bookings',
              value:
                  '${analytics.pendingBookings}',
              icon:
                  Icons.pending_actions_outlined,
              color: Colors.orange,
            ),
            _metricCard(
              title:
                  'Confirmed Tours',
              value:
                  '${analytics.confirmedBookings}',
              icon:
                  Icons.check_circle_outline,
              color: Colors.blue,
            ),
            _metricCard(
              title: 'Completed Tours',
              value:
                  '${analytics.completedBookings}',
              icon:
                  Icons.task_alt_outlined,
              color: Colors.green,
            ),
            _metricCard(
              title:
                  'Cancelled Tours',
              value:
                  '${analytics.cancelledBookings}',
              icon:
                  Icons.cancel_outlined,
              color: Colors.red,
            ),
            _metricCard(
              title:
                  'Repeat Tourists',
              value:
                  '${analytics.repeatTourists}',
              icon:
                  Icons.group_add_outlined,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _performanceSection(
    _TourismAnalytics analytics,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Operations Performance',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
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
          childAspectRatio: 1.48,
          children: [
            _metricCard(
              title: 'Approved Guides',
              value:
                  '${analytics.approvedGuides}',
              icon:
                  Icons.person_pin_circle_outlined,
              color: Colors.teal,
            ),
            _metricCard(
              title: 'Approved Drivers',
              value:
                  '${analytics.approvedDrivers}',
              icon:
                  Icons.airport_shuttle_outlined,
              color: Colors.indigo,
            ),
            _metricCard(
              title: 'Active Packages',
              value:
                  '${analytics.activePackages}',
              icon:
                  Icons.card_travel_outlined,
              color: Colors.blueGrey,
            ),
            _metricCard(
              title: 'Active Tours',
              value:
                  '${analytics.activeBookings}',
              icon:
                  Icons.route_outlined,
              color: Colors.deepPurple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 25,
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
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

  Widget _popularDestinations(
    Map<String, int> counts,
  ) {
    return _rankingSection(
      title: 'Popular Destinations',
      icon: Icons.location_on_outlined,
      counts: counts,
      emptyText:
          'No destination booking data yet.',
    );
  }

  Widget _popularPackages(
    Map<String, int> counts,
  ) {
    return _rankingSection(
      title: 'Popular Packages',
      icon: Icons.card_travel_outlined,
      counts: counts,
      emptyText:
          'No package booking data yet.',
    );
  }

  Widget _vehicleUsage(
    Map<String, int> counts,
  ) {
    return _rankingSection(
      title: 'Vehicle Usage',
      icon:
          Icons.directions_car_outlined,
      counts: counts,
      emptyText:
          'No vehicle usage data yet.',
    );
  }

  Widget _rankingSection({
    required String title,
    required IconData icon,
    required Map<String, int> counts,
    required String emptyText,
  }) {
    final entries =
        counts.entries.toList()
          ..sort(
            (a, b) =>
                b.value.compareTo(a.value),
          );

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
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            )
          else
            ...entries.take(5).map(
              (entry) {
                final maxValue =
                    entries.first.value;

                final ratio =
                    maxValue == 0
                        ? 0.0
                        : entry.value /
                            maxValue;

                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        flex: 4,
                        child:
                            LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                          backgroundColor:
                              Colors.white12,
                          valueColor:
                              const AlwaysStoppedAnimation<
                                  Color>(
                            yellow,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${entry.value}',
                          textAlign:
                              TextAlign.right,
                          style:
                              const TextStyle(
                            color: yellow,
                            fontWeight:
                                FontWeight
                                    .bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
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
              'Analytics are calculated from Firestore records and work without Firebase Storage or live payment APIs. Real JazzCash, Easypaisa and wallet settlements remain on hold.',
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

  _TourismAnalytics _buildAnalytics(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        bookings,
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        guides,
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        drivers,
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        packages,
  ) {
    double totalRevenue = 0;
    double refundTotal = 0;
    double pendingPayments = 0;

    int pendingBookings = 0;
    int confirmedBookings = 0;
    int activeBookings = 0;
    int completedBookings = 0;
    int cancelledBookings = 0;

    final Map<String, int>
        destinationCounts =
        <String, int>{};

    final Map<String, int>
        packageCounts =
        <String, int>{};

    final Map<String, int>
        vehicleCounts =
        <String, int>{};

    final Map<String, int>
        userBookingCounts =
        <String, int>{};

    for (final booking in bookings) {
      final data = booking.data();
      final status =
          _normalizeBookingStatus(data);

      final total = _readDouble(
        data['totalAmount'] ??
            data['finalPrice'] ??
            data['estimatedPrice'],
      );

      final paid = _readDouble(
        data['paidAmount'],
      );

      final remaining = _readDouble(
        data['remainingAmount'],
        fallback:
            total - paid > 0
                ? total - paid
                : 0,
      );

      final refund = _readDouble(
        data['refundAmount'],
      );

      if (<String>{
        'completed',
        'confirmed',
        'assigned',
        'in_progress',
      }.contains(status)) {
        totalRevenue += total;
      }

      refundTotal += refund;
      pendingPayments += remaining;

      switch (status) {
        case 'pending':
          pendingBookings++;
          break;
        case 'confirmed':
        case 'assigned':
          confirmedBookings++;
          break;
        case 'in_progress':
          activeBookings++;
          break;
        case 'completed':
          completedBookings++;
          break;
        case 'cancelled':
          cancelledBookings++;
          break;
      }

      final destination =
          data['destinationName']
                  ?.toString() ??
              data['destination']
                  ?.toString() ??
              '';

      if (destination.isNotEmpty) {
        destinationCounts[destination] =
            (destinationCounts[
                        destination] ??
                    0) +
                1;
      }

      final packageName =
          data['packageName']
                  ?.toString() ??
              '';

      if (packageName.isNotEmpty) {
        packageCounts[packageName] =
            (packageCounts[
                        packageName] ??
                    0) +
                1;
      }

      final vehicle =
          data['vehicleName']
                  ?.toString() ??
              data['vehicleType']
                  ?.toString() ??
              '';

      if (vehicle.isNotEmpty) {
        vehicleCounts[vehicle] =
            (vehicleCounts[vehicle] ??
                    0) +
                1;
      }

      final userId =
          data['userId']?.toString() ??
              data['customerId']
                  ?.toString() ??
              '';

      if (userId.isNotEmpty) {
        userBookingCounts[userId] =
            (userBookingCounts[userId] ??
                    0) +
                1;
      }
    }

    final totalBookings =
        bookings.length;

    final averageBookingValue =
        totalBookings == 0
            ? 0.0
            : totalRevenue /
                totalBookings;

    final repeatTourists =
        userBookingCounts.values
            .where(
              (count) => count > 1,
            )
            .length;

    final approvedGuides =
        guides.where(
      (document) {
        final data = document.data();
        return (data['applicationStatus']
                    ?.toString() ??
                data['status']
                    ?.toString()) ==
            'approved';
      },
    ).length;

    final approvedDrivers =
        drivers.where(
      (document) {
        final data = document.data();
        return (data['applicationStatus']
                    ?.toString() ??
                data['status']
                    ?.toString()) ==
            'approved';
      },
    ).length;

    final activePackages =
        packages.where(
      (document) =>
          document.data()['isActive'] !=
              false &&
          document.data()['isArchived'] !=
              true,
    ).length;

    return _TourismAnalytics(
      totalRevenue: totalRevenue,
      refundTotal: refundTotal,
      pendingPayments:
          pendingPayments,
      averageBookingValue:
          averageBookingValue,
      totalBookings: totalBookings,
      pendingBookings:
          pendingBookings,
      confirmedBookings:
          confirmedBookings,
      activeBookings: activeBookings,
      completedBookings:
          completedBookings,
      cancelledBookings:
          cancelledBookings,
      repeatTourists:
          repeatTourists,
      approvedGuides:
          approvedGuides,
      approvedDrivers:
          approvedDrivers,
      activePackages:
          activePackages,
      destinationCounts:
          destinationCounts,
      packageCounts: packageCounts,
      vehicleCounts: vehicleCounts,
    );
  }

  bool _matchesDateRange(
    DateTime date,
  ) {
    if (date.millisecondsSinceEpoch ==
        0) {
      return _selectedRange == 'all';
    }

    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    switch (_selectedRange) {
      case 'today':
        return date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
      case 'week':
        final start = today.subtract(
          Duration(
            days: today.weekday - 1,
          ),
        );
        final end = start.add(
          const Duration(days: 7),
        );
        return !date.isBefore(start) &&
            date.isBefore(end);
      case 'month':
        return date.year == now.year &&
            date.month == now.month;
      case 'year':
        return date.year == now.year;
      case 'custom':
        if (_startDate != null) {
          final start = DateTime(
            _startDate!.year,
            _startDate!.month,
            _startDate!.day,
          );

          if (date.isBefore(start)) {
            return false;
          }
        }

        if (_endDate != null) {
          final end = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
          ).add(
            const Duration(days: 1),
          );

          if (!date.isBefore(end)) {
            return false;
          }
        }

        return true;
      default:
        return true;
    }
  }

  Future<void> _refreshAnalytics() async {
    await Future.wait(
      <Future<QuerySnapshot<
          Map<String, dynamic>>>>[
        _firestore
            .collection('tour_bookings')
            .get(),
        _firestore
            .collection(
              'tour_guide_applications',
            )
            .get(),
        _firestore
            .collection(
              'tourism_driver_applications',
            )
            .get(),
        _firestore
            .collection('tour_packages')
            .get(),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final now = DateTime.now();

    final selected =
        await showDatePicker(
      context: context,
      initialDate:
          _startDate ??
              now.subtract(
                const Duration(days: 30),
              ),
      firstDate:
          DateTime(now.year - 10),
      lastDate: now.add(
        const Duration(days: 730),
      ),
    );

    if (selected == null ||
        !mounted) {
      return;
    }

    setState(() {
      _startDate = selected;

      if (_endDate != null &&
          _endDate!.isBefore(selected)) {
        _endDate = selected;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final now = DateTime.now();

    final selected =
        await showDatePicker(
      context: context,
      initialDate:
          _endDate ?? now,
      firstDate:
          _startDate ??
              DateTime(now.year - 10),
      lastDate: now.add(
        const Duration(days: 730),
      ),
    );

    if (selected == null ||
        !mounted) {
      return;
    }

    setState(() {
      _endDate = selected;
    });
  }

  String _normalizeBookingStatus(
    Map<String, dynamic> data,
  ) {
    final raw =
        data['bookingStatus']
                ?.toString() ??
            data['status']?.toString() ??
            'pending';

    if (<String>{
      'pending_admin_review',
      'pending_confirmation',
    }.contains(raw)) {
      return 'pending';
    }

    if (<String>{
      'driver_assigned',
      'guide_assigned',
    }.contains(raw)) {
      return 'assigned';
    }

    if (<String>{
      'active',
      'started',
    }.contains(raw)) {
      return 'in_progress';
    }

    if (raw == 'finished') {
      return 'completed';
    }

    return raw;
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              color: yellow,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 19,
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

  String _rangeLabel(
    String range,
  ) {
    switch (range) {
      case 'all':
        return 'All Time';
      case 'week':
        return 'This Week';
      case 'month':
        return 'This Month';
      case 'year':
        return 'This Year';
      case 'custom':
        return 'Custom';
      default:
        return 'Today';
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

    return DateTime
        .fromMillisecondsSinceEpoch(
      0,
    );
  }

  double _readDouble(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day
            .toString()
            .padLeft(2, '0');

    final month =
        date.month
            .toString()
            .padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _money(
    num amount,
  ) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(
            r'\B(?=(\d{3})+(?!\d))',
          ),
          (Match match) => ',',
        );
  }
}

class _TourismAnalytics {
  const _TourismAnalytics({
    required this.totalRevenue,
    required this.refundTotal,
    required this.pendingPayments,
    required this.averageBookingValue,
    required this.totalBookings,
    required this.pendingBookings,
    required this.confirmedBookings,
    required this.activeBookings,
    required this.completedBookings,
    required this.cancelledBookings,
    required this.repeatTourists,
    required this.approvedGuides,
    required this.approvedDrivers,
    required this.activePackages,
    required this.destinationCounts,
    required this.packageCounts,
    required this.vehicleCounts,
  });

  final double totalRevenue;
  final double refundTotal;
  final double pendingPayments;
  final double averageBookingValue;

  final int totalBookings;
  final int pendingBookings;
  final int confirmedBookings;
  final int activeBookings;
  final int completedBookings;
  final int cancelledBookings;
  final int repeatTourists;

  final int approvedGuides;
  final int approvedDrivers;
  final int activePackages;

  final Map<String, int>
      destinationCounts;
  final Map<String, int>
      packageCounts;
  final Map<String, int>
      vehicleCounts;
}
