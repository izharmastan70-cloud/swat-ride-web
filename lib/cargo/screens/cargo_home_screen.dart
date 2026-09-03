import 'package:flutter/material.dart';

import '../../screens/cargo_selection_screen.dart';
import 'cargo_orders_screen.dart';
import '../../rewards/widgets/reward_access_action.dart';

class CargoHomeScreen extends StatelessWidget {
  const CargoHomeScreen({super.key});

  static const Color _yellow = Color(0xFFFFD60A);
  static const Color _background = Color(0xFF0D0D0D);
  static const Color _cardColor = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        actions: const <Widget>[RewardAccessAction(moduleName: 'cargo')],
        backgroundColor: _background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Cargo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
          children: [
            const Text(
              'What do you need?',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a cargo service to continue.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            _cargoOption(
              context: context,
              icon: Icons.inventory_2_outlined,
              title: 'Send Parcel',
              subtitle: 'Documents, packages and small items',
              onTap: () {
                _openVehicleSelection(context, 'parcel');
              },
            ),

            const SizedBox(height: 12),

            _cargoOption(
              context: context,
              icon: Icons.local_shipping_outlined,
              title: 'Move Goods',
              subtitle: 'Boxes, shop goods and larger items',
              onTap: () {
                _openVehicleSelection(context, 'goods');
              },
            ),

            const SizedBox(height: 12),

            _cargoOption(
              context: context,
              icon: Icons.home_work_outlined,
              title: 'House Shifting',
              subtitle: 'Furniture and household moving',
              onTap: () {
                _openVehicleSelection(context, 'shifting');
              },
            ),

            const SizedBox(height: 12),

            _cargoOption(
              context: context,
              icon: Icons.store_mall_directory_outlined,
              title: 'Pickup My Item',
              subtitle: 'Collect my item from a shop, market or person',
              onTap: () {
                _openVehicleSelection(context, 'pickup_my_item');
              },
            ),

            const SizedBox(height: 12),

            _cargoOption(
              context: context,
              icon: Icons.shopping_bag_outlined,
              title: 'Buy For Me',
              subtitle: 'Buy medicine, grocery or small items for me',
              onTap: () {
                _openVehicleSelection(context, 'buy_for_me');
              },
            ),

            const SizedBox(height: 12),

            _cargoOption(
              context: context,
              icon: Icons.receipt_long_outlined,
              title: 'My Cargo Orders',
              subtitle: 'Track current and previous bookings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CargoOrdersScreen()),
                );
              },
            ),

            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _yellow.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _yellow.withValues(alpha: 0.35)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, color: _yellow),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Choose the correct vehicle for your cargo. '
                      'Pickup, drop, pricing and live tracking will be '
                      'added step by step.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cargoOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _cardColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _yellow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: _yellow, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _openVehicleSelection(BuildContext context, String serviceType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CargoSelectionScreen(serviceType: serviceType),
      ),
    );
  }
}
