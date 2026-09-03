// lib/food/rider/screens/food_delivery_rider_status_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/food_delivery_rider_model.dart';
import '../services/food_delivery_rider_service.dart';
import 'food_delivery_rider_registration_screen.dart';

class FoodDeliveryRiderStatusScreen extends StatefulWidget {
  const FoodDeliveryRiderStatusScreen({super.key});

  @override
  State<FoodDeliveryRiderStatusScreen> createState() =>
      _FoodDeliveryRiderStatusScreenState();
}

class _FoodDeliveryRiderStatusScreenState
    extends State<FoodDeliveryRiderStatusScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodDeliveryRiderService _riderService =
      FoodDeliveryRiderService();

  String get _userId =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  void _openRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            const FoodDeliveryRiderRegistrationScreen(),
      ),
    );
  }

  void _openDashboard(FoodDeliveryRiderModel rider) {
    Navigator.pushNamed(
      context,
      '/food_rider_dashboard',
      arguments: rider,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Food Rider Status',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _userId.isEmpty
            ? _buildMessageState(
                icon: Icons.lock_outline,
                title: 'Login Required',
                message:
                    'Please log in before opening Food Delivery Rider status.',
                buttonText: 'Go Back',
                onPressed: () => Navigator.pop(context),
              )
            : StreamBuilder<FoodDeliveryRiderModel?>(
                stream: _riderService.watchRiderByUserId(_userId),
                builder: (context, snapshot) {
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
                      icon: Icons.cloud_off_outlined,
                      title: 'Unable to load application',
                      message: snapshot.error.toString(),
                      buttonText: 'Try Again',
                      onPressed: () => setState(() {}),
                    );
                  }

                  final rider = snapshot.data;

                  if (rider == null) {
                    return _buildNoApplication();
                  }

                  return _buildStatus(rider);
                },
              ),
      ),
    );
  }

  Widget _buildNoApplication() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        const SizedBox(height: 45),
        const Icon(
          Icons.delivery_dining_outlined,
          color: yellow,
          size: 84,
        ),
        const SizedBox(height: 18),
        const Text(
          'No Rider Application',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Submit your Food Delivery Rider details and documents to start the admin approval process.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _openRegistration,
            icon: const Icon(Icons.app_registration),
            label: const Text(
              'Register as Food Rider',
              style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildStatus(FoodDeliveryRiderModel rider) {
    final presentation = _presentationFor(rider.status);

    return ListView(
      padding: const EdgeInsets.all(18),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: presentation.color.withValues(alpha: 0.65),
            ),
          ),
          child: Column(
            children: <Widget>[
              CircleAvatar(
                radius: 37,
                backgroundColor:
                    presentation.color.withValues(alpha: 0.15),
                child: Icon(
                  presentation.icon,
                  color: presentation.color,
                  size: 40,
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
        _buildRiderInformation(rider),
        if (rider.status == FoodDeliveryRiderStatus.rejected &&
            rider.rejectionReason.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          _buildReasonCard(
            title: 'Rejection reason',
            reason: rider.rejectionReason,
            color: Colors.redAccent,
          ),
        ],
        if (rider.status == FoodDeliveryRiderStatus.suspended &&
            rider.suspensionReason.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          _buildReasonCard(
            title: 'Suspension reason',
            reason: rider.suspensionReason,
            color: Colors.orangeAccent,
          ),
        ],
        const SizedBox(height: 22),
        if (rider.canAccessRiderDashboard)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _openDashboard(rider),
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text(
                'Open Rider Dashboard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        if (rider.status == FoodDeliveryRiderStatus.rejected)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _openRegistration,
              icon: const Icon(Icons.edit_note),
              label: const Text('Submit New Application'),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRiderInformation(FoodDeliveryRiderModel rider) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        children: <Widget>[
          _InfoRow(label: 'Rider', value: rider.fullName),
          const Divider(color: Colors.white12),
          _InfoRow(label: 'Application ID', value: rider.riderId),
          const Divider(color: Colors.white12),
          _InfoRow(
            label: 'Status',
            value: rider.status.displayName,
            highlight: true,
          ),
          const Divider(color: Colors.white12),
          _InfoRow(
            label: 'Vehicle',
            value: rider.vehicleType.displayName,
          ),
          const Divider(color: Colors.white12),
          _InfoRow(
            label: 'Registration',
            value: rider.registrationNumber,
          ),
          const Divider(color: Colors.white12),
          _InfoRow(label: 'City', value: rider.city),
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
          color: color.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: yellow, size: 70),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                height: 1.4,
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

  _StatusPresentation _presentationFor(
    FoodDeliveryRiderStatus status,
  ) {
    switch (status) {
      case FoodDeliveryRiderStatus.draft:
        return const _StatusPresentation(
          title: 'Application Draft',
          message: 'Complete and submit your Food Rider application.',
          icon: Icons.edit_note,
          color: Colors.blueAccent,
        );
      case FoodDeliveryRiderStatus.pending:
        return const _StatusPresentation(
          title: 'Application Pending',
          message:
              'Your application has been submitted. Please wait for SWAT RIDE admin review.',
          icon: Icons.hourglass_top,
          color: yellow,
        );
      case FoodDeliveryRiderStatus.underReview:
        return const _StatusPresentation(
          title: 'Application Under Review',
          message:
              'The admin is reviewing your personal, vehicle and document information.',
          icon: Icons.manage_search,
          color: Colors.lightBlueAccent,
        );
      case FoodDeliveryRiderStatus.approved:
        return const _StatusPresentation(
          title: 'Food Rider Approved',
          message:
              'Your application is approved. Open your dashboard to receive food delivery orders.',
          icon: Icons.verified,
          color: Colors.greenAccent,
        );
      case FoodDeliveryRiderStatus.rejected:
        return const _StatusPresentation(
          title: 'Application Rejected',
          message:
              'Review the reason below, correct your information and submit a new application.',
          icon: Icons.cancel_outlined,
          color: Colors.redAccent,
        );
      case FoodDeliveryRiderStatus.suspended:
        return const _StatusPresentation(
          title: 'Rider Account Suspended',
          message:
              'Your Food Rider access is temporarily suspended. Contact SWAT RIDE support or admin.',
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
            style: const TextStyle(color: Colors.grey),
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
