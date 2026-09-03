import 'package:flutter/material.dart';

import 'cargo_admin_pricing_screen.dart';
import 'cargo_admin_drivers_screen.dart';
import 'cargo_admin_orders_screen.dart';
import 'cargo_admin_payment_methods_screen.dart';
import 'cargo_admin_buy_for_me_screen.dart';
import 'cargo_admin_off_platform_reports_screen.dart';
import 'cargo_admin_daily_controls_screen.dart';

class CargoAdminDashboardScreen extends StatelessWidget {
  const CargoAdminDashboardScreen({super.key});

  static const Color _yellow = Color(0xFFFFD60A);
  static const Color _background = Color(0xFF0D0D0D);
  static const Color _card = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final List<_CargoAdminItem> items = <_CargoAdminItem>[
      const _CargoAdminItem(
        title: 'Cargo Orders',
        subtitle: 'View and manage active and completed Cargo bookings.',
        icon: Icons.local_shipping_outlined,
        route: 'orders',
      ),
      const _CargoAdminItem(
        title: 'Cargo Drivers',
        subtitle: 'Review applications, approvals and driver status.',
        icon: Icons.badge_outlined,
        route: 'drivers',
      ),
      const _CargoAdminItem(
        title: 'Pricing & Commission',
        subtitle: 'Base fare, per KM, time, weight, loading and commission.',
        icon: Icons.price_change_outlined,
        route: 'pricing',
      ),
      const _CargoAdminItem(
        title: 'Payment Methods',
        subtitle:
            'Enable or disable Cash, Wallet, JazzCash, Easypaisa and Card.',
        icon: Icons.payments_outlined,
        route: 'payments',
      ),
      const _CargoAdminItem(
        title: 'Buy For Me',
        subtitle:
            'Advance percentage, purchase limit and service availability.',
        icon: Icons.shopping_bag_outlined,
        route: 'buy_for_me',
      ),
      const _CargoAdminItem(
        title: 'Off-platform Reports',
        subtitle:
            'Review reports when drivers ask users to cancel and deal directly.',
        icon: Icons.report_gmailerrorred_outlined,
        route: 'off_platform',
      ),
      const _CargoAdminItem(
        title: 'Daily Controls',
        subtitle: 'Operational switches, surge and day-to-day Cargo settings.',
        icon: Icons.tune_outlined,
        route: 'daily_controls',
      ),
    ];

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('Cargo Admin'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _yellow.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _yellow.withValues(alpha: 0.25)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  color: _yellow,
                  size: 30,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Manage Cargo operations and settings '
                    'without requiring a customer app update.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...items.map((item) => _adminCard(context, item)),
        ],
      ),
    );
  }

  Widget _adminCard(BuildContext context, _CargoAdminItem item) {
    return Card(
      color: _card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _yellow.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(item.icon, color: _yellow),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            item.subtitle,
            style: const TextStyle(fontSize: 12, height: 1.35),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _openSection(context, item);
        },
      ),
    );
  }

  void _openSection(BuildContext context, _CargoAdminItem item) {
    switch (item.route) {
      case 'pricing':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CargoAdminPricingScreen()),
        );
        return;

      case 'payments':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CargoAdminPaymentMethodsScreen(),
          ),
        );
        return;

      case 'drivers':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CargoAdminDriversScreen()),
        );
        return;

      case 'orders':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CargoAdminOrdersScreen()),
        );
        return;

      case 'buy_for_me':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CargoAdminBuyForMeScreen()),
        );
        return;

      case 'off_platform':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CargoAdminOffPlatformReportsScreen(),
          ),
        );
        return;

      case 'daily_controls':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CargoAdminDailyControlsScreen(),
          ),
        );
        return;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.title} connection is next.')),
        );
    }
  }
}

class _CargoAdminItem {
  const _CargoAdminItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}
