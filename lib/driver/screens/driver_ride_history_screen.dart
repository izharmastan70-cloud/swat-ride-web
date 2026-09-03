import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/ride_model.dart';

class DriverRideHistoryScreen extends StatefulWidget {
  const DriverRideHistoryScreen({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  final String driverId;
  final String driverName;

  @override
  State<DriverRideHistoryScreen> createState() =>
      _DriverRideHistoryScreenState();
}

class _DriverRideHistoryScreenState
    extends State<DriverRideHistoryScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color darkCard = Color(0xFF1A1A1A);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'all';

  Stream<QuerySnapshot<Map<String, dynamic>>> _rideStream() {
    return _firestore
        .collection('rides')
        .where('driverId', isEqualTo: widget.driverId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text(
          'Ride History & Earnings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _rideStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: yellow),
            );
          }

          if (snapshot.hasError) {
            return _buildMessage(
              icon: Icons.cloud_off,
              title: 'History could not be loaded',
              subtitle: _cleanError(snapshot.error!),
            );
          }

          final List<_DriverRideRecord> allRides = snapshot.data!.docs
              .map(_DriverRideRecord.fromDocument)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          final _EarningSummary summary =
              _EarningSummary.fromRides(allRides);

          final List<_DriverRideRecord> filtered = allRides.where((ride) {
            if (_selectedFilter == 'completed') {
              return ride.status == RideModel.completed;
            }
            if (_selectedFilter == 'cancelled') {
              return ride.status == RideModel.cancelled;
            }
            return true;
          }).toList();

          return SafeArea(
            top: false,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildLiveSummary(summary),
                        const SizedBox(height: 16),
                        _buildFilters(),
                        const SizedBox(height: 14),
                        Text(
                          '${filtered.length} ride${filtered.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildMessage(
                      icon: Icons.route_outlined,
                      title: 'No rides found',
                      subtitle: _selectedFilter == 'all'
                          ? 'Your assigned rides will appear here.'
                          : 'There are no $_selectedFilter rides yet.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, index) =>
                          _buildRideCard(filtered[index]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2510), Color(0xFF171717)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: yellow.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: yellow,
            child: Icon(Icons.person, color: Colors.black, size: 29),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Your real completed ride earnings',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(_EarningSummary summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Net earnings',
                value: 'Rs ${_money(summary.net)}',
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryTile(
                icon: Icons.check_circle_outline,
                label: 'Completed',
                value: '${summary.completedRides}',
                color: yellow,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryTile(
                icon: Icons.payments_outlined,
                label: 'Gross fare',
                value: 'Rs ${_money(summary.gross)}',
                color: Colors.lightBlueAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryTile(
                icon: Icons.receipt_long_outlined,
                label: 'Commission',
                value: 'Rs ${_money(summary.commission)}',
                color: Colors.orangeAccent,
              ),
            ),
          ],
        ),
        if (summary.cashOutstanding > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orangeAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cash commission outstanding: Rs ${_money(summary.cashOutstanding)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLiveSummary(
    _EarningSummary rideSummary,
  ) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('drivers')
          .doc(widget.driverId)
          .snapshots(),
      builder: (context, snapshot) {
        final double outstanding =
            (snapshot.data?.data()?['outstandingCommission'] as num?)
                    ?.toDouble() ??
                rideSummary.cashOutstanding;

        return _buildSummary(
          rideSummary.withCashOutstanding(outstanding),
        );
      },
    );
  }

  Widget _summaryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
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
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('all', 'All rides'),
          const SizedBox(width: 8),
          _filterChip('completed', 'Completed'),
          const SizedBox(width: 8),
          _filterChip('cancelled', 'Cancelled'),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final bool selected = _selectedFilter == value;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      label: Text(label),
      selectedColor: yellow,
      backgroundColor: darkCard,
      side: BorderSide(color: selected ? yellow : Colors.white12),
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white70,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildRideCard(_DriverRideRecord ride) {
    final bool completed = ride.status == RideModel.completed;
    final bool cancelled = ride.status == RideModel.cancelled;
    final Color statusColor = completed
        ? Colors.greenAccent
        : cancelled
            ? Colors.redAccent
            : yellow;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(ride.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(ride.date),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _routeRow(
            icon: Icons.my_location,
            color: Colors.greenAccent,
            label: ride.pickup,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Container(width: 1, height: 15, color: Colors.white24),
          ),
          _routeRow(
            icon: Icons.location_on,
            color: Colors.redAccent,
            label: ride.destination,
          ),
          const Divider(color: Colors.white10, height: 25),
          Row(
            children: [
              _smallDetail(Icons.directions_car_outlined, ride.vehicleName),
              const SizedBox(width: 14),
              _smallDetail(Icons.route, '${ride.distanceKm.toStringAsFixed(1)} km'),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs ${_money(ride.fare)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (completed)
                    Text(
                      'Net Rs ${_money(ride.netEarning)}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (ride.paymentMethod.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Payment: ${_titleCase(ride.paymentMethod)}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _routeRow({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _smallDetail(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white38, size: 15),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: yellow, size: 48),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 7),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  String _money(double value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 2);

  String _titleCase(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');

  String _statusLabel(String status) => _titleCase(status);

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final int hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final String minute = date.minute.toString().padLeft(2, '0');
    final String period = date.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/${date.year}  $hour:$minute $period';
  }
}

class _DriverRideRecord {
  const _DriverRideRecord({
    required this.rideId,
    required this.status,
    required this.pickup,
    required this.destination,
    required this.vehicleName,
    required this.paymentMethod,
    required this.distanceKm,
    required this.fare,
    required this.commission,
    required this.cashOutstanding,
    required this.date,
  });

  final String rideId;
  final String status;
  final String pickup;
  final String destination;
  final String vehicleName;
  final String paymentMethod;
  final double distanceKm;
  final double fare;
  final double commission;
  final double cashOutstanding;
  final DateTime date;

  double get netEarning {
    final double value = fare - commission;
    return value < 0 ? 0 : value;
  }

  factory _DriverRideRecord.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();
    return _DriverRideRecord(
      rideId: data['rideId'] as String? ?? document.id,
      status: data['status'] as String? ?? RideModel.searching,
      pickup: _locationName(data['pickupLocation'], 'Pickup location'),
      destination:
          _locationName(data['destinationLocation'], 'Destination'),
      vehicleName: data['vehicleName'] as String? ?? 'Ride vehicle',
      paymentMethod: data['paymentMethod'] as String? ?? 'cash',
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
      fare: (data['estimatedFare'] as num?)?.toDouble() ?? 0,
      commission: (data['commissionAmount'] as num?)?.toDouble() ?? 0,
      cashOutstanding:
          (data['outstandingCommission'] as num?)?.toDouble() ?? 0,
      date: _date(data['completedAt']) ??
          _date(data['updatedAt']) ??
          _date(data['createdAt']) ??
          DateTime.now(),
    );
  }

  static String _locationName(dynamic raw, String fallback) {
    if (raw is Map) {
      final Map<String, dynamic> location =
          Map<String, dynamic>.from(raw);
      final String placeName = location['placeName'] as String? ?? '';
      final String address = location['address'] as String? ?? '';
      if (placeName.trim().isNotEmpty) return placeName;
      if (address.trim().isNotEmpty) return address;
    }
    return fallback;
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class _EarningSummary {
  const _EarningSummary({
    required this.completedRides,
    required this.gross,
    required this.commission,
    required this.net,
    required this.cashOutstanding,
  });

  final int completedRides;
  final double gross;
  final double commission;
  final double net;
  final double cashOutstanding;

  _EarningSummary withCashOutstanding(
    double value,
  ) {
    return _EarningSummary(
      completedRides: completedRides,
      gross: gross,
      commission: commission,
      net: net,
      cashOutstanding: value < 0 ? 0 : value,
    );
  }

  factory _EarningSummary.fromRides(List<_DriverRideRecord> rides) {
    int completedRides = 0;
    double gross = 0;
    double commission = 0;
    double cashOutstanding = 0;

    for (final ride in rides) {
      if (ride.status != RideModel.completed) continue;
      completedRides++;
      gross += ride.fare;
      commission += ride.commission;
      cashOutstanding += ride.cashOutstanding;
    }

    final double net = gross - commission;
    return _EarningSummary(
      completedRides: completedRides,
      gross: gross,
      commission: commission,
      net: net < 0 ? 0 : net,
      cashOutstanding: cashOutstanding,
    );
  }
}
