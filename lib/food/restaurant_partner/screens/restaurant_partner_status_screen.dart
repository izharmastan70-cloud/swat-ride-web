// lib/food/restaurant_partner/screens/restaurant_partner_status_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Partner Application Status Screen
//
// Connected with:
// - FirebaseAuth
// - RestaurantPartnerService
// - RestaurantPartnerModel
// - RestaurantPartnerRegistrationScreen
//
// This screen shows:
// - No application
// - Pending
// - Under review
// - Approved
// - Rejected
// - Suspended
//
// Existing non-Food modules remain untouched.
// =============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/restaurant_partner_model.dart';
import '../services/restaurant_partner_service.dart';
import 'restaurant_partner_registration_screen.dart';

class RestaurantPartnerStatusScreen extends StatefulWidget {
  const RestaurantPartnerStatusScreen({
    super.key,
  });

  @override
  State<RestaurantPartnerStatusScreen> createState() =>
      _RestaurantPartnerStatusScreenState();
}

class _RestaurantPartnerStatusScreenState
    extends State<RestaurantPartnerStatusScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final RestaurantPartnerService _partnerService =
      RestaurantPartnerService();

  String get _userId {
    return FirebaseAuth.instance.currentUser?.uid ??
        'guest_restaurant_partner';
  }

  void _openRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            const RestaurantPartnerRegistrationScreen(),
      ),
    );
  }

  void _openDashboard(
    RestaurantPartnerModel partner,
  ) {
    Navigator.pushNamed(
      context,
      '/food_partner_dashboard',
      arguments: partner,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Restaurant Partner',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<RestaurantPartnerModel?>(
          stream: _partnerService.watchPartnerByUserId(
            _userId,
          ),
          builder: (
            BuildContext context,
            AsyncSnapshot<RestaurantPartnerModel?> snapshot,
          ) {
            if (snapshot.connectionState ==
                    ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: yellow,
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildMessageState(
                icon: Icons.cloud_off,
                title: 'Unable to load application',
                message:
                    'Check Firebase connection and Firestore rules.',
                buttonText: 'Try Again',
                onPressed: () {
                  setState(() {});
                },
              );
            }

            final RestaurantPartnerModel? partner =
                snapshot.data;

            if (partner == null) {
              return _buildNoApplication();
            }

            return _buildApplicationStatus(partner);
          },
        ),
      ),
    );
  }

  Widget _buildNoApplication() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        const SizedBox(height: 35),
        const Icon(
          Icons.restaurant_menu,
          color: yellow,
          size: 84,
        ),
        const SizedBox(height: 20),
        const Text(
          'Become a Restaurant Partner',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Register your restaurant, submit your details and wait for admin approval.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        _buildBenefit(
          icon: Icons.receipt_long_outlined,
          title: 'Receive food orders',
          subtitle:
              'Manage live customer orders from your dashboard.',
        ),
        const SizedBox(height: 12),
        _buildBenefit(
          icon: Icons.restaurant_outlined,
          title: 'Manage your menu',
          subtitle:
              'Add dishes, prices, variants, add-ons and availability.',
        ),
        const SizedBox(height: 12),
        _buildBenefit(
          icon: Icons.analytics_outlined,
          title: 'Track earnings',
          subtitle:
              'View orders, commission and restaurant performance.',
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _openRegistration,
            icon: const Icon(Icons.app_registration),
            label: const Text(
              'Register Restaurant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationStatus(
    RestaurantPartnerModel partner,
  ) {
    final RestaurantPartnerApplicationStatus status =
        partner.applicationStatus;

    final _StatusPresentation presentation =
        _presentationFor(status);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: presentation.color.withValues(
                alpha: 0.7,
              ),
            ),
          ),
          child: Column(
            children: <Widget>[
              CircleAvatar(
                radius: 36,
                backgroundColor:
                    presentation.color.withValues(
                  alpha: 0.18,
                ),
                child: Icon(
                  presentation.icon,
                  color: presentation.color,
                  size: 39,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                presentation.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                presentation.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPartnerInformation(partner),
        if (status ==
                RestaurantPartnerApplicationStatus.rejected &&
            partner.rejectionReason.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          _buildReasonCard(
            title: 'Rejection reason',
            reason: partner.rejectionReason,
            color: Colors.redAccent,
          ),
        ],
        if (status ==
                RestaurantPartnerApplicationStatus.suspended &&
            partner.suspensionReason.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          _buildReasonCard(
            title: 'Suspension reason',
            reason: partner.suspensionReason,
            color: Colors.orangeAccent,
          ),
        ],
        const SizedBox(height: 22),
        if (partner.canAccessPartnerDashboard)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _openDashboard(partner),
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text(
                'Open Restaurant Dashboard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        if (status ==
            RestaurantPartnerApplicationStatus.rejected)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _openRegistration,
              icon: const Icon(Icons.edit_note),
              label: const Text(
                'Submit New Application',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPartnerInformation(
    RestaurantPartnerModel partner,
  ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        children: <Widget>[
          _InfoRow(
            label: 'Restaurant',
            value: partner.restaurantName,
          ),
          const Divider(color: Colors.white12),
          _InfoRow(
            label: 'Owner',
            value: partner.ownerName,
          ),
          const Divider(color: Colors.white12),
          _InfoRow(
            label: 'Application ID',
            value: partner.partnerId,
          ),
          const Divider(color: Colors.white12),
          _InfoRow(
            label: 'Status',
            value: _statusText(partner.applicationStatus),
            highlight: true,
          ),
          if (partner.restaurantId.trim().isNotEmpty) ...<Widget>[
            const Divider(color: Colors.white12),
            _InfoRow(
              label: 'Restaurant ID',
              value: partner.restaurantId,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReasonCard({
    required String title,
    required String reason,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            color: color,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  reason,
                  style: const TextStyle(
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor:
                yellow.withValues(alpha: 0.12),
            child: Icon(
              icon,
              color: yellow,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              color: yellow,
              size: 70,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
  String _statusText(
  RestaurantPartnerApplicationStatus status,
) {
  switch (status) {
    case RestaurantPartnerApplicationStatus.draft:
      return 'Draft';

    case RestaurantPartnerApplicationStatus.pending:
      return 'Pending';

    case RestaurantPartnerApplicationStatus.underReview:
      return 'Under Review';

    case RestaurantPartnerApplicationStatus.approved:
      return 'Approved';

    case RestaurantPartnerApplicationStatus.rejected:
      return 'Rejected';

    case RestaurantPartnerApplicationStatus.suspended:
      return 'Suspended';
  }
}

  _StatusPresentation _presentationFor(
    RestaurantPartnerApplicationStatus status,
  ) {
    switch (status) {
      case RestaurantPartnerApplicationStatus.draft:
        return const _StatusPresentation(
          title: 'Application Draft',
          message:
              'Complete and submit your restaurant application.',
          icon: Icons.edit_note,
          color: Colors.blueAccent,
        );

      case RestaurantPartnerApplicationStatus.pending:
        return const _StatusPresentation(
          title: 'Application Pending',
          message:
              'Your restaurant application has been submitted. Please wait for admin review.',
          icon: Icons.hourglass_top,
          color: yellow,
        );

      case RestaurantPartnerApplicationStatus.underReview:
        return const _StatusPresentation(
          title: 'Application Under Review',
          message:
              'The SWAT RIDE admin is currently reviewing your restaurant details and documents.',
          icon: Icons.manage_search,
          color: Colors.lightBlueAccent,
        );

      case RestaurantPartnerApplicationStatus.approved:
        return const _StatusPresentation(
          title: 'Restaurant Approved',
          message:
              'Your restaurant is approved. You can now manage your menu and food orders.',
          icon: Icons.verified,
          color: Colors.greenAccent,
        );

      case RestaurantPartnerApplicationStatus.rejected:
        return const _StatusPresentation(
          title: 'Application Rejected',
          message:
              'Review the reason below, correct your details and submit a new application.',
          icon: Icons.cancel_outlined,
          color: Colors.redAccent,
        );

      case RestaurantPartnerApplicationStatus.suspended:
        return const _StatusPresentation(
          title: 'Restaurant Suspended',
          message:
              'Your Restaurant Partner access is temporarily suspended. Contact SWAT RIDE support or admin.',
          icon: Icons.block,
          color: Colors.orangeAccent,
        );
    }
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: highlight ? yellow : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
}
