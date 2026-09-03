import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/cargo_booking_model.dart';
import '../models/cargo_driver_application_model.dart';
import '../services/cargo_booking_service.dart';
import '../services/cargo_driver_application_service.dart';

import '../../feedback/models/feedback_model.dart';
import '../../feedback/models/feedback_reply_model.dart';
import '../../feedback/partner/partner_reviews_screen.dart';
import '../../feedback/partner/review_reply_screen.dart';
import 'cargo_driver_booking_details_screen.dart';
import '../../rewards/widgets/reward_access_action.dart';

class CargoDriverDashboardScreen extends StatelessWidget {
  CargoDriverDashboardScreen({super.key});

  final CargoDriverApplicationService _applicationService =
      CargoDriverApplicationService();

  final CargoBookingService _bookingService = CargoBookingService();

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              'Please sign in to access Cargo Driver.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return StreamBuilder<List<CargoDriverApplicationModel>>(
      stream: _applicationService.watchUserApplications(user.uid),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<CargoDriverApplicationModel>> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return const Scaffold(
                body: SafeArea(
                  child: Center(
                    child: Text(
                      'Could not load Cargo Driver status.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final List<CargoDriverApplicationModel> applications =
                snapshot.data ?? <CargoDriverApplicationModel>[];

            CargoDriverApplicationModel? approvedApplication;

            for (final CargoDriverApplicationModel application
                in applications) {
              if (application.status == CargoDriverApplicationModel.approved) {
                approvedApplication = application;
                break;
              }
            }

            if (approvedApplication == null) {
              return _AccessStatusScreen(applications: applications);
            }

            return _ApprovedCargoDriverDashboard(
              application: approvedApplication,
              bookingService: _bookingService,
            );
          },
    );
  }
}

class _ApprovedCargoDriverDashboard extends StatelessWidget {
  const _ApprovedCargoDriverDashboard({
    required this.application,
    required this.bookingService,
  });

  final CargoDriverApplicationModel application;
  final CargoBookingService bookingService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        actions: const <Widget>[RewardAccessAction(moduleName: 'cargoDriver')],
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Cargo Driver',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<CargoBookingModel>>(
          stream: bookingService.watchDriverBookings(application.userId),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<CargoBookingModel>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Could not load Cargo jobs.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final List<CargoBookingModel> bookings =
                    snapshot.data ?? <CargoBookingModel>[];

                final List<CargoBookingModel> activeBookings = bookings.where((
                  CargoBookingModel booking,
                ) {
                  return booking.status != CargoBookingModel.delivered &&
                      booking.status != CargoBookingModel.cancelled;
                }).toList();

                final List<CargoBookingModel> completedBookings = bookings
                    .where((CargoBookingModel booking) {
                      return booking.status == CargoBookingModel.delivered;
                    })
                    .toList();

                final double totalEarnings = completedBookings.fold<double>(
                  0,
                  (double total, CargoBookingModel booking) =>
                      total + booking.driverNetEarning,
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future<void>.delayed(
                      const Duration(milliseconds: 350),
                    );
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      _DriverHeaderCard(application: application),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.local_shipping_outlined,
                              title: 'Active',
                              value: '${activeBookings.length}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.check_circle_outline,
                              title: 'Delivered',
                              value: '${completedBookings.length}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SummaryCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Net Earnings',
                        value: 'Rs ${totalEarnings.toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: 22),
                      _reviewsSection(context),
                      const SizedBox(height: 22),
                      const Text(
                        'Active Cargo Jobs',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (activeBookings.isEmpty)
                        const _EmptyJobsCard()
                      else
                        ...activeBookings.map(
                          (CargoBookingModel booking) => _CargoJobCard(
                            booking: booking,
                            driver: application,
                          ),
                        ),
                      if (completedBookings.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 22),
                        const Text(
                          'Recent Deliveries',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...completedBookings
                            .take(5)
                            .map(
                              (CargoBookingModel booking) => _CargoJobCard(
                                booking: booking,
                                driver: application,
                                completed: true,
                              ),
                            ),
                      ],
                    ],
                  ),
                );
              },
        ),
      ),
    );
  }

  Widget _reviewsSection(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openReviews(
              context,
              serviceType: FeedbackServiceType.cargo,
              targetType: FeedbackTargetType.cargoDriver,
              authorType: FeedbackReplyAuthorType.cargoDriver,
              title: 'Cargo Reviews',
            ),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Cargo Reviews'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openReviews(
              context,
              serviceType: FeedbackServiceType.parcel,
              targetType: FeedbackTargetType.parcelRider,
              authorType: FeedbackReplyAuthorType.parcelRider,
              title: 'Parcel Reviews',
            ),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Parcel Reviews'),
          ),
        ),
      ],
    );
  }

  void _openReviews(
    BuildContext context, {
    required FeedbackServiceType serviceType,
    required FeedbackTargetType targetType,
    required FeedbackReplyAuthorType authorType,
    required String title,
  }) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => PartnerReviewsScreen(
          serviceType: serviceType,
          targetType: targetType,
          targetId: application.userId,
          partnerName: application.fullName,
          onReplyRequested: (review) {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (context) => ReviewReplyScreen(
                  review: review,
                  authorId: application.userId,
                  authorName: application.fullName,
                  authorType: authorType,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DriverHeaderCard extends StatelessWidget {
  const _DriverHeaderCard({required this.application});

  final CargoDriverApplicationModel application;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFE8F5EF),
            foregroundColor: Color(0xFF087F5B),
            child: Icon(Icons.local_shipping_rounded, size: 29),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  application.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${application.vehicleType} â€¢ '
                  '${application.vehicleNumber}',
                  style: const TextStyle(color: Color(0xFF68778A)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EF),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'APPROVED',
              style: TextStyle(
                color: Color(0xFF087F5B),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: const Color(0xFF087F5B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF68778A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CargoJobCard extends StatelessWidget {
  const _CargoJobCard({
    required this.booking,
    required this.driver,
    this.completed = false,
  });

  final CargoBookingModel booking;
  final CargoDriverApplicationModel driver;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final String pickup = booking.pickupAddress?.trim().isNotEmpty == true
        ? booking.pickupAddress!.trim()
        : booking.shopAddress?.trim().isNotEmpty == true
        ? booking.shopAddress!.trim()
        : 'Pickup location';

    final String drop = booking.dropAddress?.trim().isNotEmpty == true
        ? booking.dropAddress!.trim()
        : 'Delivery location';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return CargoDriverBookingDetailsScreen(
                bookingId: booking.bookingId,
                driver: driver,
              );
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    booking.serviceType.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  booking.status.replaceAll('_', ' '),
                  style: TextStyle(
                    color: completed
                        ? const Color(0xFF087F5B)
                        : const Color(0xFFE08B22),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RouteLine(icon: Icons.radio_button_checked, text: pickup),
            const SizedBox(height: 8),
            _RouteLine(icon: Icons.location_on_outlined, text: drop),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Fare: Rs ${booking.totalFare.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  'Net: Rs ${booking.driverNetEarning.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF087F5B),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: const Color(0xFF68778A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: Color(0xFF53606F))),
        ),
      ],
    );
  }
}

class _EmptyJobsCard extends StatelessWidget {
  const _EmptyJobsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: <Widget>[
          Icon(Icons.inventory_2_outlined, size: 38, color: Color(0xFF8A95A4)),
          SizedBox(height: 10),
          Text(
            'No active Cargo jobs',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 4),
          Text(
            'Assigned Cargo bookings will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF68778A)),
          ),
        ],
      ),
    );
  }
}

class _AccessStatusScreen extends StatelessWidget {
  const _AccessStatusScreen({required this.applications});

  final List<CargoDriverApplicationModel> applications;

  @override
  Widget build(BuildContext context) {
    String title = 'Cargo Driver approval required';
    String message =
        'Submit a Cargo Driver application and wait for admin approval.';
    IconData icon = Icons.pending_actions_rounded;

    if (applications.isNotEmpty) {
      final CargoDriverApplicationModel latest = applications.first;

      if (latest.status == CargoDriverApplicationModel.pending) {
        title = 'Application under review';
        message =
            'Your Cargo Driver application is waiting for admin approval.';
      } else if (latest.status == CargoDriverApplicationModel.rejected) {
        title = 'Application rejected';
        message = latest.adminNote?.trim().isNotEmpty == true
            ? latest.adminNote!.trim()
            : 'Your Cargo Driver application was not approved.';
        icon = Icons.cancel_outlined;
      } else if (latest.status == CargoDriverApplicationModel.suspended) {
        title = 'Cargo Driver access suspended';
        message = latest.adminNote?.trim().isNotEmpty == true
            ? latest.adminNote!.trim()
            : 'Please contact support for more information.';
        icon = Icons.block_rounded;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('Cargo Driver'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 58, color: const Color(0xFFE08B22)),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF68778A)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
