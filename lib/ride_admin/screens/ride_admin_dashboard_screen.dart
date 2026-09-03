import 'package:flutter/material.dart';

import '../services/ride_admin_service.dart';
import 'driver_application_management_screen.dart';
import 'driver_management_screen.dart';
import 'driver_withdrawal_management_screen.dart';
import '../../feedback/admin/complaint_management_screen.dart';
import '../../feedback/admin/feedback_management_screen.dart';
import '../../feedback/models/feedback_model.dart';
import 'ride_analytics_screen.dart';
import 'ride_commission_settlement_screen.dart';
import 'ride_management_screen.dart';
import 'ride_payment_management_screen.dart';
import 'ride_pricing_management_screen.dart';
import 'ride_service_control_screen.dart';
import 'phone_call_dispatch_screen.dart';

class RideAdminDashboardScreen extends StatefulWidget {
  const RideAdminDashboardScreen({
    super.key,
    this.adminId = 'testing_admin',
    this.adminName = 'SWAT RIDE Admin',
  });

  final String adminId;
  final String adminName;

  @override
  State<RideAdminDashboardScreen> createState() =>
      _RideAdminDashboardScreenState();
}

class _RideAdminDashboardScreenState extends State<RideAdminDashboardScreen> {
  static const Color _yellow = Color(0xFFFFD400);
  static const Color _background = Color(0xFF090909);
  static const Color _card = Color(0xFF191919);

  final RideAdminService _service = RideAdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'SWAT RIDE Admin',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
            ),
            Text(
              'Normal Ride + Driver',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Admin information',
            onPressed: _showAdminInformation,
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _yellow,
          backgroundColor: _card,
          onRefresh: () async {
            setState(() {});
            await Future<void>.delayed(const Duration(milliseconds: 450));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: <Widget>[
              _buildWelcomeHeader(),
              const SizedBox(height: 18),
              const _SectionTitle(
                title: 'Live overview',
                subtitle: 'Firestore data for the normal Ride module',
              ),
              const SizedBox(height: 12),
              _buildOverviewGrid(),
              const SizedBox(height: 24),
              const _SectionTitle(
                title: 'Management',
                subtitle: 'Open a section to review or update its records',
              ),
              const SizedBox(height: 12),
              _buildManagementGrid(),
              const SizedBox(height: 22),
              _buildSystemStatus(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFD400), Color(0xFFFFB800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.local_taxi_rounded,
              color: Colors.black,
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Welcome, ${widget.adminName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Manage drivers, rides, pricing, payments and settlements.',
                  style: TextStyle(color: Colors.black87, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            SizedBox(
              width: width,
              child: _LiveCountCard(
                title: 'Pending Applications',
                icon: Icons.assignment_ind_outlined,
                color: Colors.orangeAccent,
                stream: _service.watchDriverApplications(status: 'pending'),
                onTap: () => _open(_applicationsScreen()),
              ),
            ),
            SizedBox(
              width: width,
              child: _LiveCountCard(
                title: 'Approved Drivers',
                icon: Icons.drive_eta_rounded,
                color: Colors.green,
                stream: _service.watchDrivers(status: 'approved'),
                onTap: () => _open(_driversScreen()),
              ),
            ),
            SizedBox(
              width: width,
              child: _LiveCountCard(
                title: 'Searching Rides',
                icon: Icons.radar_rounded,
                color: _yellow,
                stream: _service.watchRides(status: 'searching'),
                onTap: () => _open(_ridesScreen()),
              ),
            ),
            SizedBox(
              width: width,
              child: _LiveCountCard(
                title: 'Pending Withdrawals',
                icon: Icons.account_balance_wallet_outlined,
                color: Colors.lightBlueAccent,
                stream: _service.watchWithdrawals(status: 'pending'),
                onTap: () => _open(_withdrawalsScreen()),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildManagementGrid() {
    final List<_DashboardItem> items = <_DashboardItem>[
      _DashboardItem(
        title: 'Driver Applications',
        subtitle: 'Approve or reject new drivers',
        icon: Icons.assignment_ind_outlined,
        color: Colors.orangeAccent,
        screenBuilder: _applicationsScreen,
      ),
      _DashboardItem(
        title: 'Drivers',
        subtitle: 'Accounts, status and suspension',
        icon: Icons.people_alt_outlined,
        color: Colors.green,
        screenBuilder: _driversScreen,
      ),
      _DashboardItem(
        title: 'Rides',
        subtitle: 'Live, completed and cancelled',
        icon: Icons.local_taxi_outlined,
        color: _yellow,
        screenBuilder: _ridesScreen,
      ),
      _DashboardItem(
        title: 'Phone Call Dispatch',
        subtitle: 'Assign a driver and notify the passenger',
        icon: Icons.phone_in_talk_outlined,
        color: Colors.lightGreenAccent,
        screenBuilder: () => const PhoneCallDispatchScreen(),
      ),
      _DashboardItem(
        title: 'Pricing',
        subtitle: 'Vehicle fares and commission',
        icon: Icons.price_change_outlined,
        color: Colors.purpleAccent,
        screenBuilder: _pricingScreen,
      ),
      _DashboardItem(
        title: 'Payments',
        subtitle: 'Methods, toggles and test mode',
        icon: Icons.payments_outlined,
        color: Colors.lightBlueAccent,
        screenBuilder: _paymentsScreen,
      ),
      _DashboardItem(
        title: 'Service Control',
        subtitle: 'Master ON/OFF and maintenance mode',
        icon: Icons.power_settings_new_rounded,
        color: Colors.redAccent,
        screenBuilder: () => RideServiceControlScreen(
          adminId: widget.adminId,
          adminName: widget.adminName,
        ),
      ),
      _DashboardItem(
        title: 'Ratings & Reviews',
        subtitle: 'Review and moderate Normal Ride ratings',
        icon: Icons.star_rate_rounded,
        color: Colors.amberAccent,
        screenBuilder: _rideReviewsScreen,
      ),
      _DashboardItem(
        title: 'Complaints & Disputes',
        subtitle: 'Review Ride complaints and dispute history',
        icon: Icons.gavel_outlined,
        color: Colors.deepOrangeAccent,
        screenBuilder: _rideComplaintsScreen,
      ),
      _DashboardItem(
        title: 'Analytics & Reports',
        subtitle: 'Ride performance, revenue and activity',
        icon: Icons.analytics_outlined,
        color: Colors.indigoAccent,
        screenBuilder: _analyticsScreen,
      ),
      _DashboardItem(
        title: 'Commission Settlement',
        subtitle: 'Ledger, settlement and controlled adjustments',
        icon: Icons.receipt_long_outlined,
        color: Colors.cyanAccent,
        screenBuilder: _commissionSettlementScreen,
      ),
      _DashboardItem(
        title: 'Withdrawals',
        subtitle: 'Review driver payout requests',
        icon: Icons.account_balance_outlined,
        color: Colors.tealAccent,
        screenBuilder: _withdrawalsScreen,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = constraints.maxWidth >= 760 ? 3 : 2;
        final double spacing = 10;
        final double itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: _ManagementCard(
                    item: item,
                    onTap: () => _open(item.screenBuilder()),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.health_and_safety_outlined, color: _yellow),
              SizedBox(width: 10),
              Text(
                'System status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _StatusRow(
            label: 'Firestore admin connection',
            value: 'REAL',
            color: Colors.green,
          ),
          _StatusRow(
            label: 'Cash ride commission',
            value: 'ACTIVE',
            color: Colors.green,
          ),
          _StatusRow(
            label: 'Online payment providers',
            value: 'TEST MODE',
            color: _yellow,
          ),
          _StatusRow(
            label: 'Driver payout providers',
            value: 'PAUSED',
            color: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }

  Widget _applicationsScreen() => DriverApplicationManagementScreen(
    adminId: widget.adminId,
    adminName: widget.adminName,
  );

  Widget _driversScreen() => DriverManagementScreen(adminId: widget.adminId);

  Widget _ridesScreen() => RideManagementScreen(adminId: widget.adminId);

  Widget _pricingScreen() =>
      RidePricingManagementScreen(adminId: widget.adminId);

  Widget _paymentsScreen() =>
      RidePaymentManagementScreen(adminId: widget.adminId);

  Widget _rideReviewsScreen() => FeedbackManagementScreen(
    adminId: widget.adminId,
    initialServiceType: FeedbackServiceType.ride,
    lockServiceType: true,
  );

  Widget _rideComplaintsScreen() => ComplaintManagementScreen(
    adminId: widget.adminId,
    adminName: widget.adminName,
    initialServiceType: FeedbackServiceType.ride,
    lockServiceType: true,
  );

  Widget _analyticsScreen() => const RideAnalyticsScreen();

  Widget _commissionSettlementScreen() => RideCommissionSettlementScreen(
    adminId: widget.adminId,
    adminName: widget.adminName,
  );

  Widget _withdrawalsScreen() =>
      DriverWithdrawalManagementScreen(adminId: widget.adminId);

  Future<void> _open(Widget screen) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _showAdminInformation() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF191919),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Admin session',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              _InfoRow(label: 'Name', value: widget.adminName),
              _InfoRow(label: 'Admin ID', value: widget.adminId),
              const _InfoRow(label: 'Module', value: 'Normal Ride + Driver'),
              const _InfoRow(label: 'Payments', value: 'Testing bypass'),
              const SizedBox(height: 12),
              const Text(
                'Production must replace the testing admin ID with the authenticated Firebase Admin user ID and enforce Admin-only Firestore rules.',
                style: TextStyle(color: Colors.white54, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveCountCard extends StatelessWidget {
  const _LiveCountCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Stream<List<RideAdminRecord>> stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF191919),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: StreamBuilder<List<RideAdminRecord>>(
            stream: stream,
            builder: (context, snapshot) {
              final String count = snapshot.hasError
                  ? '!'
                  : snapshot.hasData
                  ? '${snapshot.data!.length}'
                  : '...';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 37,
                        height: 37,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(icon, color: color, size: 21),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white24,
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    count,
                    style: TextStyle(
                      color: color,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardItem {
  const _DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screenBuilder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget Function() screenBuilder;
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({required this.item, required this.onTap});

  final _DashboardItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF191919),
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(height: 13),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white54)),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white60)),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 95,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(
            child: SelectableText(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
