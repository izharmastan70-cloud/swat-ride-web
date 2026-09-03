import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HotelAdminReportsScreen extends StatefulWidget {
  const HotelAdminReportsScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelAdminReportsScreen> createState() =>
      _HotelAdminReportsScreenState();
}

class _HotelAdminReportsScreenState
    extends State<HotelAdminReportsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String _selectedPeriod = 'month';

  DateTime get _now => DateTime.now();

  DateTime get _periodStart {
    switch (_selectedPeriod) {
      case 'today':
        return DateTime(
          _now.year,
          _now.month,
          _now.day,
        );
      case 'week':
        return DateTime(
          _now.year,
          _now.month,
          _now.day,
        ).subtract(
          Duration(days: _now.weekday - 1),
        );
      default:
        return DateTime(
          _now.year,
          _now.month,
          1,
        );
    }
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
          'Hotel Reports & Analytics',
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
                title: 'Unable to Load Reports',
                message:
                    bookingSnapshot.error.toString(),
              );
            }

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
                        QuerySnapshot<
                            Map<String, dynamic>>>
                    roomSnapshot,
              ) {
                final bookings =
                    bookingSnapshot.data?.docs ??
                        <QueryDocumentSnapshot<
                            Map<String, dynamic>>>[];

                final rooms =
                    roomSnapshot.data?.docs ??
                        <QueryDocumentSnapshot<
                            Map<String, dynamic>>>[];

                final report =
                    _buildReport(
                  bookings: bookings,
                  rooms: rooms,
                );

                return RefreshIndicator(
                  color: yellow,
                  backgroundColor: darkCard,
                  onRefresh: () async {
                    await Future.wait([
                      _firestore
                          .collection(
                            'hotel_bookings',
                          )
                          .where(
                            'hotelId',
                            isEqualTo:
                                widget.hotelId,
                          )
                          .get(),
                      _firestore
                          .collection(
                            'hotel_rooms',
                          )
                          .where(
                            'hotelId',
                            isEqualTo:
                                widget.hotelId,
                          )
                          .get(),
                    ]);
                  },
                  child: ListView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      30,
                    ),
                    children: [
                      _periodSelector(),

                      const SizedBox(height: 16),

                      _overviewGrid(report),

                      const SizedBox(height: 18),

                      _occupancyCard(report),

                      const SizedBox(height: 18),

                      _bookingBreakdown(report),

                      const SizedBox(height: 18),

                      _ratingCard(report),

                      const SizedBox(height: 18),

                      _housekeepingReport(),

                      const SizedBox(height: 18),

                      _staffReport(),

                      const SizedBox(height: 18),

                      _exportCard(),
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
    const List<String> periods =
        <String>[
      'today',
      'week',
      'month',
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        children: periods.map(
          (String period) {
            final bool selected =
                _selectedPeriod == period;

            return Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 4,
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
                    fontWeight:
                        FontWeight.bold,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedPeriod =
                          period;
                    });
                  },
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  _HotelReport _buildReport({
    required List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>
        bookings,
    required List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>
        rooms,
  }) {
    int totalBookings = 0;
    int pending = 0;
    int confirmed = 0;
    int active = 0;
    int completed = 0;
    int cancelled = 0;

    double revenue = 0;
    double refunded = 0;
    double ratingsTotal = 0;
    int ratingsCount = 0;

    int availableRooms = 0;
    int occupiedRooms = 0;
    int maintenanceRooms = 0;

    for (final booking in bookings) {
      final Map<String, dynamic> data =
          booking.data();

      final DateTime createdAt =
          _readDateTime(
        data['createdAt'],
      );

      if (createdAt.isBefore(_periodStart)) {
        continue;
      }

      totalBookings++;

      final String status =
          data['bookingStatus']?.toString() ??
              'pending';

      switch (status) {
        case 'pending':
        case 'pending_hotel_confirmation':
          pending++;
          break;
        case 'confirmed':
          confirmed++;
          break;
        case 'checked_in':
        case 'active':
        case 'in_stay':
          active++;
          break;
        case 'completed':
        case 'checked_out':
          completed++;
          revenue += _readNumber(
            data['totalAmount'],
          );
          break;
        case 'cancelled':
        case 'rejected':
          cancelled++;
          break;
      }

      refunded += _readNumber(
        data['refundAmount'],
      );

      final double rating =
          _readNumber(
        data['rating'] ??
            data['hotelRating'],
      );

      if (rating > 0) {
        ratingsTotal += rating;
        ratingsCount++;
      }
    }

    for (final room in rooms) {
      final Map<String, dynamic> data =
          room.data();

      if (data['isActive'] == false) {
        continue;
      }

      final String status =
          data['manualStatus']?.toString() ??
              data['status']?.toString() ??
              'available';

      if (status == 'occupied') {
        occupiedRooms++;
      } else if (status == 'maintenance' ||
          status == 'blocked') {
        maintenanceRooms++;
      } else {
        availableRooms++;
      }
    }

    final int totalRooms =
        availableRooms +
            occupiedRooms +
            maintenanceRooms;

    final double occupancyRate =
        totalRooms == 0
            ? 0
            : (occupiedRooms / totalRooms) *
                100;

    final double cancellationRate =
        totalBookings == 0
            ? 0
            : (cancelled / totalBookings) *
                100;

    final double averageRating =
        ratingsCount == 0
            ? 0
            : ratingsTotal / ratingsCount;

    return _HotelReport(
      totalBookings: totalBookings,
      pending: pending,
      confirmed: confirmed,
      active: active,
      completed: completed,
      cancelled: cancelled,
      revenue: revenue,
      refunded: refunded,
      availableRooms: availableRooms,
      occupiedRooms: occupiedRooms,
      maintenanceRooms: maintenanceRooms,
      occupancyRate: occupancyRate,
      cancellationRate: cancellationRate,
      averageRating: averageRating,
      ratingsCount: ratingsCount,
    );
  }

  Widget _overviewGrid(
    _HotelReport report,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _metricCard(
          title: 'Bookings',
          value: '${report.totalBookings}',
          icon: Icons.book_online_outlined,
          color: Colors.blue,
        ),
        _metricCard(
          title: 'Revenue',
          value:
              'PKR ${_formatMoney(report.revenue)}',
          icon:
              Icons.account_balance_wallet_outlined,
          color: Colors.green,
        ),
        _metricCard(
          title: 'Occupancy',
          value:
              '${report.occupancyRate.toStringAsFixed(1)}%',
          icon: Icons.hotel_outlined,
          color: Colors.purple,
        ),
        _metricCard(
          title: 'Cancellation',
          value:
              '${report.cancellationRate.toStringAsFixed(1)}%',
          icon: Icons.cancel_outlined,
          color: Colors.redAccent,
        ),
        _metricCard(
          title: 'Average Rating',
          value: report.averageRating <= 0
              ? 'No ratings'
              : report.averageRating
                  .toStringAsFixed(1),
          icon: Icons.star_outline,
          color: yellow,
        ),
        _metricCard(
          title: 'Refunded',
          value:
              'PKR ${_formatMoney(report.refunded)}',
          icon:
              Icons.currency_exchange_outlined,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _occupancyCard(
    _HotelReport report,
  ) {
    final int totalRooms =
        report.availableRooms +
            report.occupiedRooms +
            report.maintenanceRooms;

    return _sectionCard(
      title: 'Room Occupancy',
      icon: Icons.apartment_outlined,
      child: Column(
        children: [
          _detailRow(
            'Total Rooms',
            '$totalRooms',
          ),
          _detailRow(
            'Available',
            '${report.availableRooms}',
          ),
          _detailRow(
            'Occupied',
            '${report.occupiedRooms}',
          ),
          _detailRow(
            'Maintenance',
            '${report.maintenanceRooms}',
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value:
                report.occupancyRate / 100,
            minHeight: 9,
            backgroundColor:
                Colors.white10,
            valueColor:
                const AlwaysStoppedAnimation<Color>(
              yellow,
            ),
            borderRadius:
                BorderRadius.circular(20),
          ),
          const SizedBox(height: 8),
          Text(
            '${report.occupancyRate.toStringAsFixed(1)}% occupancy',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingBreakdown(
    _HotelReport report,
  ) {
    return _sectionCard(
      title: 'Booking Breakdown',
      icon: Icons.analytics_outlined,
      child: Column(
        children: [
          _detailRow(
            'Pending',
            '${report.pending}',
          ),
          _detailRow(
            'Confirmed',
            '${report.confirmed}',
          ),
          _detailRow(
            'Active Stay',
            '${report.active}',
          ),
          _detailRow(
            'Completed',
            '${report.completed}',
          ),
          _detailRow(
            'Cancelled / Rejected',
            '${report.cancelled}',
          ),
        ],
      ),
    );
  }

  Widget _ratingCard(
    _HotelReport report,
  ) {
    return _sectionCard(
      title: 'Guest Ratings',
      icon: Icons.star_outline,
      child: Column(
        children: [
          _detailRow(
            'Average Rating',
            report.averageRating <= 0
                ? 'No ratings yet'
                : '${report.averageRating.toStringAsFixed(1)} / 5',
          ),
          _detailRow(
            'Total Reviews',
            '${report.ratingsCount}',
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children:
                List<Widget>.generate(
              5,
              (int index) {
                return Icon(
                  index <
                          report.averageRating
                              .round()
                      ? Icons.star
                      : Icons.star_border,
                  color: yellow,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _housekeepingReport() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection(
            'hotel_housekeeping_inspections',
          )
          .where(
            'hotelId',
            isEqualTo: widget.hotelId,
          )
          .snapshots(),
      builder: (
        context,
        AsyncSnapshot<
                QuerySnapshot<Map<String, dynamic>>>
            snapshot,
      ) {
        final inspections =
            snapshot.data?.docs ??
                <QueryDocumentSnapshot<
                    Map<String, dynamic>>>[];

        int completed = 0;
        int needsReview = 0;
        int lostAndFound = 0;
        int damageReports = 0;

        for (final inspection in inspections) {
          final Map<String, dynamic> data =
              inspection.data();

          final DateTime createdAt =
              _readDateTime(
            data['createdAt'],
          );

          if (createdAt.isBefore(_periodStart)) {
            continue;
          }

          if (data['reviewStatus'] ==
              'needs_review') {
            needsReview++;
          } else {
            completed++;
          }

          if (data['guestItemsFound'] ==
              true) {
            lostAndFound++;
          }

          if (data['damageFound'] ==
              true) {
            damageReports++;
          }
        }

        return _sectionCard(
          title: 'Housekeeping Performance',
          icon:
              Icons.cleaning_services_outlined,
          child: Column(
            children: [
              _detailRow(
                'Completed Inspections',
                '$completed',
              ),
              _detailRow(
                'Needs Review',
                '$needsReview',
              ),
              _detailRow(
                'Guest Items Found',
                '$lostAndFound',
              ),
              _detailRow(
                'Damage Reports',
                '$damageReports',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _staffReport() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('hotel_staff')
          .where(
            'hotelId',
            isEqualTo: widget.hotelId,
          )
          .snapshots(),
      builder: (
        context,
        AsyncSnapshot<
                QuerySnapshot<Map<String, dynamic>>>
            snapshot,
      ) {
        final staff =
            snapshot.data?.docs ??
                <QueryDocumentSnapshot<
                    Map<String, dynamic>>>[];

        int active = 0;
        int inactive = 0;
        int managers = 0;
        int reception = 0;
        int housekeeping = 0;

        for (final member in staff) {
          final Map<String, dynamic> data =
              member.data();

          if (data['isActive'] == false) {
            inactive++;
            continue;
          }

          active++;

          switch (
              data['role']?.toString() ??
                  'reception') {
            case 'manager':
              managers++;
              break;
            case 'housekeeping':
              housekeeping++;
              break;
            default:
              reception++;
          }
        }

        return _sectionCard(
          title: 'Staff Summary',
          icon: Icons.groups_outlined,
          child: Column(
            children: [
              _detailRow(
                'Active Staff',
                '$active',
              ),
              _detailRow(
                'Inactive Staff',
                '$inactive',
              ),
              _detailRow(
                'Managers',
                '$managers',
              ),
              _detailRow(
                'Reception',
                '$reception',
              ),
              _detailRow(
                'Housekeeping',
                '$housekeeping',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _exportCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.download_outlined,
                color: yellow,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Report Export',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'PDF and Excel export will be enabled in the final reporting phase. Current reports are live and viewable inside the app.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: _showExportBypass,
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                  ),
                  label:
                      const Text('PDF'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed: _showExportBypass,
                  icon: const Icon(
                    Icons.table_chart_outlined,
                  ),
                  label:
                      const Text('Excel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExportBypass() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Report export is prepared for the final production phase.',
          ),
          backgroundColor: darkCard,
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
            BorderRadius.circular(18),
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
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
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
        bottom: 9,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
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
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel(
    String period,
  ) {
    switch (period) {
      case 'today':
        return 'Today';
      case 'week':
        return 'This Week';
      default:
        return 'This Month';
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
          DateTime.fromMillisecondsSinceEpoch(
            0,
          );
    }

    return DateTime.fromMillisecondsSinceEpoch(
      0,
    );
  }

  String _formatMoney(
    double amount,
  ) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }
}

class _HotelReport {
  const _HotelReport({
    required this.totalBookings,
    required this.pending,
    required this.confirmed,
    required this.active,
    required this.completed,
    required this.cancelled,
    required this.revenue,
    required this.refunded,
    required this.availableRooms,
    required this.occupiedRooms,
    required this.maintenanceRooms,
    required this.occupancyRate,
    required this.cancellationRate,
    required this.averageRating,
    required this.ratingsCount,
  });

  final int totalBookings;
  final int pending;
  final int confirmed;
  final int active;
  final int completed;
  final int cancelled;

  final double revenue;
  final double refunded;

  final int availableRooms;
  final int occupiedRooms;
  final int maintenanceRooms;

  final double occupancyRate;
  final double cancellationRate;

  final double averageRating;
  final int ratingsCount;
}
