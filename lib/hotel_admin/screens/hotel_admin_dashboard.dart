import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'hotel_admin_finance_screen.dart';
import 'hotel_admin_invoice_management_screen.dart';
import 'hotel_admin_housekeeping_screen.dart';
import 'hotel_admin_maintenance_screen.dart';
import 'hotel_admin_export_center_screen.dart';
import 'hotel_admin_staff_screen.dart';

import 'hotel_admin_booking_screen.dart';
import 'hotel_admin_rooms_screen.dart';
import 'hotel_admin_reports_screen.dart';
import 'hotel_admin_settings_screen.dart';

class HotelAdminDashboard extends StatefulWidget {
  const HotelAdminDashboard({
    super.key,
    required this.hotelId,
    this.hotelName = 'Hotel Admin',
  });

  final String hotelId;
  final String hotelName;

  @override
  State<HotelAdminDashboard> createState() =>
      _HotelAdminDashboardState();
}

class _HotelAdminDashboardState
    extends State<HotelAdminDashboard> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

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
        title: Text(
          widget.hotelName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openAdminSummary,
            icon: const Icon(
              Icons.insights_outlined,
              color: yellow,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: yellow,
          backgroundColor: darkCard,
          onRefresh: () async {
            await Future.wait([
              _firestore
                  .collection('hotel_bookings')
                  .where(
                    'hotelId',
                    isEqualTo: widget.hotelId,
                  )
                  .get(),
              _firestore
                  .collection('hotel_rooms')
                  .where(
                    'hotelId',
                    isEqualTo: widget.hotelId,
                  )
                  .get(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              30,
            ),
            children: [
              _headerCard(),

              const SizedBox(height: 16),

              _overviewSection(),

              const SizedBox(height: 20),

              _analyticsSection(),

              const SizedBox(height: 20),

              const Text(
                'Admin Controls',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _controlsGrid(),

              const SizedBox(height: 20),

              const Text(
                'Pending Attention',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _pendingAttention(),

              const SizedBox(height: 18),

              _noticeCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.24,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: yellow.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: yellow,
              size: 31,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hotel Admin Control Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.hotelName,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hotel ID: ${widget.hotelId}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewSection() {
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
            final bookings =
                bookingSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            final rooms =
                roomSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            int pending = 0;
            int active = 0;
            int completed = 0;
            double revenue = 0;

            for (final booking in bookings) {
              final data = booking.data();

              final String status =
                  data['bookingStatus']
                          ?.toString() ??
                      'pending';

              if (status ==
                      'pending_hotel_confirmation' ||
                  status == 'pending') {
                pending++;
              } else if (status == 'confirmed' ||
                  status == 'checked_in' ||
                  status == 'active' ||
                  status == 'in_stay') {
                active++;
              } else if (status == 'completed' ||
                  status == 'checked_out') {
                completed++;
                revenue += _readNumber(
                  data['totalAmount'],
                );
              }
            }

            int availableRooms = 0;

            for (final room in rooms) {
              final data = room.data();

              final String status =
                  data['manualStatus']
                          ?.toString() ??
                      data['status']
                          ?.toString() ??
                      'available';

              final String housekeeping =
                  data['housekeepingStatus']
                          ?.toString() ??
                      'ready';

              if (status == 'available' &&
                  housekeeping != 'dirty' &&
                  housekeeping != 'cleaning') {
                availableRooms++;
              }
            }

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
                  title: 'Pending',
                  value: '$pending',
                  icon: Icons.pending_actions_outlined,
                  color: Colors.orange,
                ),
                _metricCard(
                  title: 'Active',
                  value: '$active',
                  icon: Icons.hotel_outlined,
                  color: Colors.blue,
                ),
                _metricCard(
                  title: 'Completed',
                  value: '$completed',
                  icon: Icons.task_alt,
                  color: Colors.green,
                ),
                _metricCard(
                  title: 'Available Rooms',
                  value: '$availableRooms',
                  icon:
                      Icons.meeting_room_outlined,
                  color: yellow,
                ),
                _metricCard(
                  title: 'Total Rooms',
                  value: '${rooms.length}',
                  icon: Icons.apartment_outlined,
                  color: Colors.purple,
                ),
                _metricCard(
                  title: 'Recorded Revenue',
                  value: 'PKR ${_formatMoney(revenue)}',
                  icon:
                      Icons.account_balance_wallet_outlined,
                  color: Colors.teal,
                ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _analyticsSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('hotel_bookings')
          .where('hotelId', isEqualTo: widget.hotelId)
          .snapshots(),
      builder: (context, bookingSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('hotel_rooms')
              .where('hotelId', isEqualTo: widget.hotelId)
              .snapshots(),
          builder: (context, roomSnapshot) {
            final bookings = bookingSnapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final rooms = roomSnapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final tomorrow = today.add(const Duration(days: 1));
            final weekStart =
                today.subtract(Duration(days: today.weekday - 1));
            final monthStart = DateTime(now.year, now.month, 1);
            final yearStart = DateTime(now.year, 1, 1);

            double todayRevenue = 0;
            double weeklyRevenue = 0;
            double monthlyRevenue = 0;
            double yearlyRevenue = 0;
            double pendingPayments = 0;
            double refunds = 0;

            int cancelled = 0;
            int checkInsToday = 0;
            int checkOutsToday = 0;

            final Map<String, int> guestBookingCount = {};

            for (final booking in bookings) {
              final data = booking.data();
              final status =
                  data['bookingStatus']?.toString() ?? '';
              final createdAt = _readDateTime(data['createdAt']);
              final checkIn = _readDateTime(data['checkIn']);
              final checkOut = _readDateTime(data['checkOut']);
              final total = _readNumber(data['totalAmount']);
              final paid = _readNumber(data['paidAmount']);
              final remaining = _readNumber(data['remainingAmount']);
              final refund = _readNumber(data['refundAmount']);

              if (status == 'cancelled') {
                cancelled++;
              }

              if (_sameDay(checkIn, today)) {
                checkInsToday++;
              }

              if (_sameDay(checkOut, today)) {
                checkOutsToday++;
              }

              final userId = data['userId']?.toString() ??
                  data['customerId']?.toString() ??
                  '';

              if (userId.isNotEmpty) {
                guestBookingCount[userId] =
                    (guestBookingCount[userId] ?? 0) + 1;
              }

              final revenueStatus = <String>{
                'confirmed',
                'checked_in',
                'active',
                'in_stay',
                'completed',
                'checked_out',
              }.contains(status);

              if (revenueStatus) {
                if (!createdAt.isBefore(today) &&
                    createdAt.isBefore(tomorrow)) {
                  todayRevenue += total;
                }
                if (!createdAt.isBefore(weekStart)) {
                  weeklyRevenue += total;
                }
                if (!createdAt.isBefore(monthStart)) {
                  monthlyRevenue += total;
                }
                if (!createdAt.isBefore(yearStart)) {
                  yearlyRevenue += total;
                }
              }

              pendingPayments += remaining > 0
                  ? remaining
                  : (total - paid > 0 ? total - paid : 0);
              refunds += refund;
            }

            final repeatGuests = guestBookingCount.values
                .where((bookingCount) => bookingCount > 1)
                .length;

            int availableRooms = 0;
            int maintenanceRooms = 0;
            int cleaningRooms = 0;

            for (final room in rooms) {
              final data = room.data();
              final status = data['manualStatus']?.toString() ??
                  data['status']?.toString() ??
                  'available';
              final housekeeping =
                  data['housekeepingStatus']?.toString() ?? 'ready';

              if (<String>{'maintenance', 'blocked'}
                  .contains(status)) {
                maintenanceRooms++;
              } else if (housekeeping == 'dirty' ||
                  housekeeping == 'cleaning') {
                cleaningRooms++;
              } else if (status == 'available') {
                availableRooms++;
              }
            }

            final totalRooms = rooms.length;
            final occupiedRooms = (totalRooms -
                    availableRooms -
                    maintenanceRooms -
                    cleaningRooms)
                .clamp(0, totalRooms);

            final occupancy = totalRooms == 0
                ? 0.0
                : (occupiedRooms / totalRooms) * 100;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Analytics',
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
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.45,
                  children: [
                    _metricCard(
                      title: 'Today Revenue',
                      value: 'PKR ${_formatMoney(todayRevenue)}',
                      icon: Icons.today_outlined,
                      color: Colors.teal,
                    ),
                    _metricCard(
                      title: 'Weekly Revenue',
                      value: 'PKR ${_formatMoney(weeklyRevenue)}',
                      icon: Icons.date_range_outlined,
                      color: Colors.blue,
                    ),
                    _metricCard(
                      title: 'Monthly Revenue',
                      value: 'PKR ${_formatMoney(monthlyRevenue)}',
                      icon: Icons.calendar_month_outlined,
                      color: Colors.green,
                    ),
                    _metricCard(
                      title: 'Yearly Revenue',
                      value: 'PKR ${_formatMoney(yearlyRevenue)}',
                      icon: Icons.auto_graph_outlined,
                      color: Colors.purple,
                    ),
                    _metricCard(
                      title: 'Occupancy',
                      value: '${occupancy.toStringAsFixed(0)}%',
                      icon: Icons.pie_chart_outline,
                      color: Colors.cyan,
                    ),
                    _metricCard(
                      title: 'Pending Payments',
                      value: 'PKR ${_formatMoney(pendingPayments)}',
                      icon: Icons.pending_actions_outlined,
                      color: Colors.orange,
                    ),
                    _metricCard(
                      title: 'Refunds',
                      value: 'PKR ${_formatMoney(refunds)}',
                      icon: Icons.currency_exchange_outlined,
                      color: Colors.redAccent,
                    ),
                    _metricCard(
                      title: 'Cancelled',
                      value: '$cancelled',
                      icon: Icons.cancel_outlined,
                      color: Colors.red,
                    ),
                    _metricCard(
                      title: 'Check-ins Today',
                      value: '$checkInsToday',
                      icon: Icons.login,
                      color: Colors.blue,
                    ),
                    _metricCard(
                      title: 'Check-outs Today',
                      value: '$checkOutsToday',
                      icon: Icons.logout,
                      color: Colors.deepPurple,
                    ),
                    _metricCard(
                      title: 'Repeat Guests',
                      value: '$repeatGuests',
                      icon: Icons.group_add_outlined,
                      color: yellow,
                    ),
                    _metricCard(
                      title: 'Rooms in Service',
                      value: '${availableRooms + occupiedRooms}',
                      icon: Icons.apartment_outlined,
                      color: Colors.indigo,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _occupancyBreakdown(
                  totalRooms: totalRooms,
                  availableRooms: availableRooms,
                  occupiedRooms: occupiedRooms,
                  cleaningRooms: cleaningRooms,
                  maintenanceRooms: maintenanceRooms,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _occupancyBreakdown({
    required int totalRooms,
    required int availableRooms,
    required int occupiedRooms,
    required int cleaningRooms,
    required int maintenanceRooms,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Room Status Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _progressRow(
            title: 'Available',
            value: availableRooms,
            total: totalRooms,
            color: Colors.green,
          ),
          _progressRow(
            title: 'Occupied / Booked',
            value: occupiedRooms,
            total: totalRooms,
            color: Colors.blue,
          ),
          _progressRow(
            title: 'Cleaning',
            value: cleaningRooms,
            total: totalRooms,
            color: Colors.orange,
          ),
          _progressRow(
            title: 'Maintenance / Blocked',
            value: maintenanceRooms,
            total: totalRooms,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _progressRow({
    required String title,
    required int value,
    required int total,
    required Color color,
  }) {
    final double ratio =
        total == 0 ? 0 : (value / total).clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
            size: 25,
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

  Widget _controlsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.25,
      children: [
        _controlCard(
          icon: Icons.book_online_outlined,
          title: 'Bookings',
          subtitle:
              'Approve, reject, check-in and check-out',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) =>
                    HotelAdminBookingScreen(
                  hotelId: widget.hotelId,
                ),
              ),
            );
          },
        ),
        _controlCard(
          icon: Icons.meeting_room_outlined,
          title: 'Rooms',
          subtitle:
              'Manage price, status and availability',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) =>
                    HotelAdminRoomsScreen(
                  hotelId: widget.hotelId,
                ),
              ),
            );
          },
        ),
        _controlCard(
          icon:
              Icons.cleaning_services_outlined,
          title: 'Housekeeping',
          subtitle:
              'Cleaning tasks and inspections',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) =>
                    HotelHousekeepingScreen(
                  hotelId: widget.hotelId,
                ),
              ),
            );
          },
        ),
        _controlCard(
          icon: Icons.build_circle_outlined,
          title: 'Maintenance',
          subtitle:
              'Repair, block rooms and inspect completed work',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) =>
                    HotelAdminMaintenanceScreen(
                  hotelId: widget.hotelId,
                ),
              ),
            );
          },
        ),
        _controlCard(
          icon: Icons.groups_outlined,
          title: 'Staff',
          subtitle:
              'Roles, access and permissions',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) =>
                    HotelAdminStaffScreen(
                  hotelId: widget.hotelId,
                ),
              ),
            );
          },
        ),
        _controlCard(
          icon: Icons.payments_outlined,
          title: 'Payments',
          subtitle:
              'Cash, online and settlement records',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) =>
                    HotelAdminFinanceScreen(
                  hotelId: widget.hotelId,
                ),
              ),
            );
          },
        ),
        _controlCard(
          icon: Icons.receipt_long_outlined,
          title: 'Invoices',
          subtitle:
              'Manage, refund, void and archive invoices',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) =>
                    HotelAdminInvoiceManagementScreen(
                  hotelId: widget.hotelId,
                ),
              ),
            );
          },
        ),
        _controlCard(
          icon: Icons.file_download_outlined,
          title: 'Export Center',
          subtitle:
              'PDF, CSV and Excel-ready reports',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) =>
                    HotelAdminExportCenterScreen(
                  hotelId: widget.hotelId,
                  hotelName: widget.hotelName,
                ),
              ),
            );
          },
        ),
        _controlCard(
          icon: Icons.percent_outlined,
          title: 'Commission',
          subtitle:
              'View admin-controlled commission',
          onTap: () {
            _showComingNext(
              'Hotel Commission Settings',
            );
          },
        ),
        _controlCard(
          icon: Icons.analytics_outlined,
          title: 'Reports',
          subtitle:
              'Revenue, occupancy and cancellations',
          onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) =>
          HotelAdminReportsScreen(
        hotelId: widget.hotelId,
      ),
    ),
  );
},
        ),
        _controlCard(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle:
              'Check-in, checkout and hotel policies',
          onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) =>
          HotelAdminSettingsScreen(
        hotelId: widget.hotelId,
      ),
    ),
  );
},
        ),
      ],
    );
  }

  Widget _controlCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius:
              BorderRadius.circular(17),
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
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingAttention() {
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
            snapshot,
      ) {
        final bookings = snapshot.data?.docs ??
            <QueryDocumentSnapshot<
                Map<String, dynamic>>>[];

        final pending = bookings.where(
          (booking) {
            final String status =
                booking.data()['bookingStatus']
                        ?.toString() ??
                    '';

            return status ==
                    'pending_hotel_confirmation' ||
                status == 'pending';
          },
        ).toList();

        if (pending.isEmpty) {
          return _emptyAttention();
        }

        return Column(
          children: pending.take(5).map(
            (booking) {
              final data = booking.data();

              return Container(
                margin:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orange
                        .withValues(
                      alpha: 0.28,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.pending_actions_outlined,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            data['guestName']
                                    ?.toString() ??
                                'Guest',
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            data['roomName']
                                    ?.toString() ??
                                'Room',
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
                      'PKR ${_formatMoney(_readNumber(data['totalAmount']))}',
                      style: const TextStyle(
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
        );
      },
    );
  }

  Widget _emptyAttention() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            'No urgent hotel action',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Pending booking and operational alerts will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
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
              'This dashboard reads current hotel booking and room records. Sensitive financial, commission and staff permission changes will require dedicated screens and admin approval rules.',
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

  void _openAdminSummary() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Hotel Admin Summary',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This is the main control center for hotel bookings, rooms, staff, housekeeping, payments, reports and policies.',
            style: TextStyle(
              color: Colors.grey,
              height: 1.45,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showComingNext(
    String feature,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: darkCard,
          content: Text(
            '$feature screen will be connected in the next Hotel Admin step.',
          ),
        ),
      );
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

  bool _sameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
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

