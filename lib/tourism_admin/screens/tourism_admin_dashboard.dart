import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'tourism_destination_management_screen.dart';
import 'tour_package_management_screen.dart';
import 'tour_booking_management_screen.dart';
import 'tour_guide_management_screen.dart';
import 'tourism_driver_management_screen.dart';
import 'tourism_reports_analytics_screen.dart';
import 'tourism_notification_management_screen.dart';
import 'tourism_settings_screen.dart';
import 'tourism_vehicle_management_screen.dart';
import 'tourism_pricing_commission_management_screen.dart';
import 'tour_hotel_combined_management_screen.dart';
import 'tourism_export_center_screen.dart';

class TourismAdminDashboard extends StatefulWidget {
  const TourismAdminDashboard({
    super.key,
    this.adminName = 'Tourism Admin',
  });

  final String adminName;

  @override
  State<TourismAdminDashboard> createState() =>
      _TourismAdminDashboardState();
}

class _TourismAdminDashboardState
    extends State<TourismAdminDashboard> {
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Tourism Admin',
          style: TextStyle(
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
          onRefresh: _refreshDashboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            children: [
              _headerCard(),
              const SizedBox(height: 16),
              _overviewSection(),
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
              _pendingAttentionSection(),
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
          color: yellow.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: yellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.travel_explore_outlined,
              color: yellow,
              size: 31,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tourism Control Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.adminName,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Destinations, packages, bookings, guides, drivers and vehicles.',
                  style: TextStyle(
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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('tour_bookings').snapshots(),
      builder: (context, bookingSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore.collection('tour_destinations').snapshots(),
          builder: (context, destinationSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('tour_packages').snapshots(),
              builder: (context, packageSnapshot) {
                final bookings = bookingSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final destinations = destinationSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                final packages = packageSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                int pending = 0;
                int active = 0;
                int completed = 0;
                double revenue = 0;

                for (final booking in bookings) {
                  final data = booking.data();
                  final status = data['bookingStatus']?.toString() ??
                      data['status']?.toString() ??
                      'pending';

                  if (<String>{
                    'pending',
                    'pending_admin_review',
                    'pending_confirmation',
                  }.contains(status)) {
                    pending++;
                  } else if (<String>{
                    'confirmed',
                    'driver_assigned',
                    'guide_assigned',
                    'active',
                    'in_progress',
                  }.contains(status)) {
                    active++;
                  } else if (<String>{
                    'completed',
                    'finished',
                  }.contains(status)) {
                    completed++;
                    revenue += _readNumber(
                      data['totalAmount'] ?? data['finalPrice'],
                    );
                  }
                }

                final activeDestinations = destinations
                    .where((d) => d.data()['isActive'] != false)
                    .length;
                final activePackages = packages
                    .where((d) => d.data()['isActive'] != false)
                    .length;

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.55,
                  children: [
                    _metricCard(
                      title: 'Destinations',
                      value: '$activeDestinations',
                      icon: Icons.location_on_outlined,
                      color: Colors.green,
                    ),
                    _metricCard(
                      title: 'Active Packages',
                      value: '$activePackages',
                      icon: Icons.card_travel_outlined,
                      color: Colors.blue,
                    ),
                    _metricCard(
                      title: 'Pending Bookings',
                      value: '$pending',
                      icon: Icons.pending_actions_outlined,
                      color: Colors.orange,
                    ),
                    _metricCard(
                      title: 'Active Tours',
                      value: '$active',
                      icon: Icons.directions_bus_outlined,
                      color: Colors.purple,
                    ),
                    _metricCard(
                      title: 'Completed',
                      value: '$completed',
                      icon: Icons.task_alt_outlined,
                      color: Colors.teal,
                    ),
                    _metricCard(
                      title: 'Recorded Revenue',
                      value: 'PKR ${_formatMoney(revenue)}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: yellow,
                    ),
                  ],
                );
              },
            );
          },
        );
      },
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
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
    final controls = <Map<String, dynamic>>[
      {
        'icon': Icons.location_city_outlined,
        'title': 'Destinations',
        'subtitle': 'Add, edit and control places',
        'feature': 'Destination Management',
      },
      {
        'icon': Icons.card_travel_outlined,
        'title': 'Tour Packages',
        'subtitle': 'Manage itinerary, days and prices',
        'feature': 'Tour Package Management',
      },
      {
        'icon': Icons.book_online_outlined,
        'title': 'Bookings',
        'subtitle': 'Approve, reject and assign tours',
        'feature': 'Tour Booking Management',
      },
      {
        'icon': Icons.directions_car_outlined,
        'title': 'Vehicles',
        'subtitle': 'Manage vehicles and availability',
        'feature': 'Tour Vehicle Management',
      },
      {
        'icon': Icons.person_pin_circle_outlined,
        'title': 'Tour Guides',
        'subtitle': 'Applications and assignments',
        'feature': 'Tour Guide Management',
      },
      {
        'icon': Icons.airport_shuttle_outlined,
        'title': 'Tour Drivers',
        'subtitle': 'Applications and availability',
        'feature': 'Tourism Driver Management',
      },
      {
        'icon': Icons.payments_outlined,
        'title': 'Pricing',
        'subtitle': 'Prices and commissions',
        'feature': 'Tourism Pricing',
      },
      {
        'icon': Icons.hotel_outlined,
        'title': 'Tour + Hotel',
        'subtitle': 'Combined packages and nights',
        'feature': 'Tour and Hotel Integration',
      },
      {
        'icon': Icons.analytics_outlined,
        'title': 'Reports',
        'subtitle': 'Revenue and booking reports',
        'feature': 'Tourism Reports',
      },
      {
        'icon': Icons.notifications_active_outlined,
        'title': 'Notifications',
        'subtitle': 'Booking, guide and driver alerts',
        'feature': 'Tourism Notifications',
      },
      {
        'icon': Icons.settings_outlined,
        'title': 'Settings',
        'subtitle': 'Visibility, cancellation and policies',
        'feature': 'Tourism Settings',
      },
      {
        'icon': Icons.file_download_outlined,
        'title': 'Export Center',
        'subtitle': 'PDF, CSV and Excel-ready reports',
        'feature': 'Tourism Export Center',
      },
    ];

    return GridView.builder(
      itemCount: controls.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final item = controls[index];
        return _controlCard(
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          subtitle: item['subtitle'] as String,
          onTap: () => _openControl(
            item['feature'] as String,
          ),
        );
      },
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
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: yellow, size: 28),
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

  Widget _pendingAttentionSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('tour_bookings').snapshots(),
      builder: (context, snapshot) {
        final bookings = snapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        final pending = bookings.where((booking) {
          final status = booking.data()['bookingStatus']?.toString() ??
              booking.data()['status']?.toString() ??
              '';
          return <String>{
            'pending',
            'pending_admin_review',
            'pending_confirmation',
          }.contains(status);
        }).toList();

        if (pending.isEmpty) {
          return _emptyAttention();
        }

        return Column(
          children: pending.take(5).map((booking) {
            final data = booking.data();
            final destination =
                data['destinationName']?.toString() ??
                    data['destination']?.toString() ??
                    'Tour Destination';
            final customer =
                data['customerName']?.toString() ??
                    data['userName']?.toString() ??
                    'Customer';
            final amount = _readNumber(
              data['totalAmount'] ?? data['estimatedPrice'],
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.28),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          destination,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    amount > 0
                        ? 'PKR ${_formatMoney(amount)}'
                        : 'Review',
                    style: const TextStyle(
                      color: yellow,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
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
        borderRadius: BorderRadius.circular(16),
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
            'No urgent tourism action',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Pending bookings, guide applications and driver alerts will appear here.',
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
        color: yellow.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: yellow),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'This dashboard works without Firebase Storage or live payment APIs. JazzCash, Easypaisa and real wallet settlement remain disabled until billing and merchant approval are ready.',
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

  Future<void> _refreshDashboard() async {
    await Future.wait([
      _firestore.collection('tour_bookings').get(),
      _firestore.collection('tour_destinations').get(),
      _firestore.collection('tour_packages').get(),
    ]);
  }

  void _openAdminSummary() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Tourism Admin Summary',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This is the main control center for destinations, packages, bookings, drivers, guides, vehicles, pricing, reports and tourism settings.',
            style: TextStyle(
              color: Colors.grey,
              height: 1.45,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
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

  void _openControl(String feature) {
    Widget? screen;

    switch (feature) {
      case 'Destination Management':
        screen =
            const TourismDestinationManagementScreen();
        break;
      case 'Tour Package Management':
        screen =
            const TourPackageManagementScreen();
        break;
      case 'Tour Booking Management':
        screen =
            const TourBookingManagementScreen();
        break;
      case 'Tour Guide Management':
        screen =
            const TourGuideManagementScreen();
        break;
      case 'Tourism Driver Management':
        screen =
            const TourismDriverManagementScreen();
        break;
      case 'Tour Vehicle Management':
        screen =
            const TourismVehicleManagementScreen();
        break;
      case 'Tourism Pricing':
        screen =
            const TourismPricingCommissionManagementScreen();
        break;
      case 'Tour and Hotel Integration':
        screen =
            const TourHotelCombinedManagementScreen();
        break;
      case 'Tourism Export Center':
        screen =
            const TourismExportCenterScreen();
        break;
      case 'Tourism Reports':
        screen =
            const TourismReportsAnalyticsScreen();
        break;
      case 'Tourism Notifications':
        screen =
            const TourismNotificationManagementScreen();
        break;
      case 'Tourism Settings':
        screen =
            const TourismSettingsScreen();
        break;
    }

    if (screen == null) {
      _showComingNext(feature);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => screen!,
      ),
    );
  }

  void _showComingNext(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: darkCard,
          content: Text(
            '$feature screen will be connected in the next Tourism Admin step.',
          ),
        ),
      );
  }

  double _readNumber(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatMoney(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (Match match) => ',',
        );
  }
}
