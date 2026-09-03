// lib/food/restaurant_partner/screens/profile_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Partner Profile Screen
//
// This screen fixes the missing ProfileScreen constructor and
// safely supports an optional RestaurantPartnerModel.
// =============================================================

import 'package:flutter/material.dart';

import '../models/restaurant_partner_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.partner,
  });

  final RestaurantPartnerModel? partner;

  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final RestaurantPartnerModel? value = partner;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Restaurant Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: value == null
            ? _buildMissingProfile(context)
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  30,
                ),
                children: <Widget>[
                  _buildHeader(value),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Owner Information',
                    icon: Icons.person_outline,
                    children: <Widget>[
                      _InfoRow(
                        label: 'Owner',
                        value: value.ownerName,
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Phone',
                        value: value.phoneNumber,
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Email',
                        value: value.email,
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'CNIC',
                        value: value.cnicNumber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Restaurant Details',
                    icon: Icons.storefront_outlined,
                    children: <Widget>[
                      _InfoRow(
                        label: 'Restaurant',
                        value: value.restaurantName,
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Type',
                        value: value.restaurantType,
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Categories',
                        value: value.categories.join(', '),
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Opening Hours',
                        value:
                            '${value.openingTime} - ${value.closingTime}',
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Status',
                        value:
                            value.applicationStatus.displayName,
                        highlight: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Location',
                    icon: Icons.location_on_outlined,
                    children: <Widget>[
                      _InfoRow(
                        label: 'Address',
                        value:
                            '${value.address}, ${value.area}, ${value.city}',
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Landmark',
                        value: value.landmark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Business Settings',
                    icon: Icons.settings_outlined,
                    children: <Widget>[
                      _InfoRow(
                        label: 'Minimum Order',
                        value:
                            'Rs. ${value.minimumOrderAmount.toStringAsFixed(0)}',
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Delivery Fee',
                        value:
                            'Rs. ${value.deliveryFee.toStringAsFixed(0)}',
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Delivery Radius',
                        value:
                            '${value.deliveryRadiusKm.toStringAsFixed(1)} KM',
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _InfoRow(
                        label: 'Commission',
                        value:
                            '${value.commissionPercentage.toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(
    RestaurantPartnerModel value,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.black,
            child: Icon(
              Icons.restaurant,
              color: yellow,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value.restaurantName.trim().isEmpty
                      ? 'Restaurant Partner'
                      : value.restaurantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value.ownerName.trim().isEmpty
                      ? 'Owner information unavailable'
                      : value.ownerName,
                  style: const TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified,
            color: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                icon,
                color: yellow,
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMissingProfile(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.account_circle_outlined,
              color: yellow,
              size: 76,
            ),
            const SizedBox(height: 16),
            const Text(
              'Restaurant profile is unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The profile screen opened without restaurant partner data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  static const Color yellow = Color(0xFFFFD60A);

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value.trim().isEmpty ? '—' : value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: highlight
                  ? yellow
                  : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
