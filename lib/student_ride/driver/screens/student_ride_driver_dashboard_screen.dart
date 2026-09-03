import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/student_ride_driver_application_model.dart';
import '../../models/student_ride_route_model.dart';
import '../../../safety/models/safety_models.dart';
import '../../../safety/screens/safety_center_screen.dart';
import '../../services/student_ride_driver_application_service.dart';

import '../../../feedback/models/feedback_model.dart';
import '../../../feedback/models/feedback_reply_model.dart';
import '../../../feedback/partner/partner_reviews_screen.dart';
import '../../../feedback/partner/review_reply_screen.dart';
import 'student_ride_driver_application_status_screen.dart';
import '../../../rewards/widgets/reward_access_action.dart';

class StudentRideDriverDashboardScreen extends StatefulWidget {
  const StudentRideDriverDashboardScreen({super.key});

  @override
  State<StudentRideDriverDashboardScreen> createState() =>
      _StudentRideDriverDashboardScreenState();
}

class _StudentRideDriverDashboardScreenState
    extends State<StudentRideDriverDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StudentRideDriverApplicationService _applicationService =
      StudentRideDriverApplicationService();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const _DashboardMessage(
        icon: Icons.login_rounded,
        title: 'Login required',
        message: 'Please login before opening the Student Ride dashboard.',
      );
    }

    return StreamBuilder<StudentRideDriverApplicationModel?>(
      stream: _applicationService.watchMyApplication(),
      builder: (context, applicationSnapshot) {
        if (applicationSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final application = applicationSnapshot.data;
        if (application == null || !application.isApproved) {
          return Scaffold(
            appBar: AppBar(title: const Text('Student Ride Driver')),
            body: _DashboardMessage(
              icon: Icons.verified_user_outlined,
              title: 'Approval required',
              message:
                  'Only approved Student Ride Drivers can access this dashboard.',
              buttonLabel: 'View Application Status',
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => StudentRideDriverApplicationStatusScreen(),
                ),
              ),
            ),
          );
        }

        final driverId = application.existingNormalDriverId.trim().isNotEmpty
            ? application.existingNormalDriverId.trim()
            : application.userId.trim();

        return _approvedDashboard(driverId);
      },
    );
  }

  Widget _approvedDashboard(String driverId) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Ride Driver'),
        actions: [
          const RewardAccessAction(moduleName: 'studentDriver'),
          IconButton(
            tooltip: 'Application status',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => StudentRideDriverApplicationStatusScreen(),
              ),
            ),
            icon: const Icon(Icons.verified_rounded),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('drivers').doc(driverId).snapshots(),
        builder: (context, driverSnapshot) {
          if (driverSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final driverData = driverSnapshot.data?.data();
          if (driverData == null ||
              driverData['studentRideApproved'] != true ||
              driverData['studentRideStatus']?.toString() != 'approved') {
            return const _DashboardMessage(
              icon: Icons.lock_clock_rounded,
              title: 'Driver account is being prepared',
              message:
                  'Admin approval is complete, but the Student Ride Driver account is not active yet.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _firestore.collection('drivers').doc(driverId).get();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _driverHeader(driverData),
                const SizedBox(height: 16),
                _financeCards(driverData),
                const SizedBox(height: 22),
                _reviewsCard(driverId, driverData),
                const SizedBox(height: 22),
                Text(
                  'Assigned school routes',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                _assignedRoutes(driverId),
                const SizedBox(height: 22),
                _safetyNotice(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _reviewsCard(String driverId, Map<String, dynamic> driverData) {
    final name = driverData['name']?.toString().trim() ?? '';
    final driverName = name.isEmpty ? 'Student Ride Driver' : name;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.rate_review_outlined),
        title: const Text('My Reviews'),
        subtitle: const Text('Parent ratings and public replies'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (context) => PartnerReviewsScreen(
                serviceType: FeedbackServiceType.studentRide,
                targetType: FeedbackTargetType.studentRideDriver,
                targetId: driverId,
                partnerName: driverName,
                onReplyRequested: (review) {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => ReviewReplyScreen(
                        review: review,
                        authorId: driverId,
                        authorName: driverName,
                        authorType: FeedbackReplyAuthorType.studentRideDriver,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _driverHeader(Map<String, dynamic> data) {
    final morning = data['studentRideMorningAvailable'] == true;
    final afternoon = data['studentRideAfternoonAvailable'] == true;
    final name = data['name']?.toString().trim() ?? '';
    final vehicle = <String>[
      data['vehicleMake']?.toString() ?? '',
      data['vehicleModel']?.toString() ?? '',
    ].where((value) => value.trim().isNotEmpty).join(' ');

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  child: Icon(Icons.directions_bus_rounded, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Approved Driver' : name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(vehicle.isEmpty ? 'Student Ride vehicle' : vehicle),
                    ],
                  ),
                ),
                const Icon(Icons.verified_rounded, color: Colors.green),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (morning) const Chip(label: Text('Morning available')),
                if (afternoon) const Chip(label: Text('Afternoon available')),
                Chip(
                  label: Text(
                    'Capacity: ${_readInt(data['studentRideVehicleCapacity'], 1)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _financeCards(Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            'Wallet',
            'PKR ${_money(data['walletBalance'])}',
            Icons.account_balance_wallet_rounded,
            Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            'Commission due',
            'PKR ${_money(data['outstandingCommission'])}',
            Icons.receipt_long_rounded,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 3),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assignedRoutes(String driverId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('student_ride_routes')
          .where('driverId', isEqualTo: driverId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Unable to load routes: ${snapshot.error}'),
            ),
          );
        }

        final routes =
            (snapshot.data?.docs ?? const [])
                .map(
                  (document) => StudentRideRouteModel.fromMap(
                    document.data(),
                    documentId: document.id,
                  ),
                )
                .where(
                  (route) => route.status != StudentRideRouteStatus.disabled,
                )
                .toList()
              ..sort((first, second) {
                final shift = first.shift.index.compareTo(second.shift.index);
                return shift != 0
                    ? shift
                    : first.routeName.compareTo(second.routeName);
              });

        if (routes.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No route is assigned yet. Admin will assign morning or afternoon school routes.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(children: routes.map(_routeCard).toList());
      },
    );
  }

  void _openStudentRouteSafety(StudentRideRouteModel route) {
    final bool isMorning = route.shift == StudentRideRouteShift.morning;

    final List<StudentRideRouteStopModel> stops = route.orderedStops
        .where((stop) => stop.isActive)
        .toList();

    SafetyLocation? pickupLocation;
    SafetyLocation? destinationLocation;

    if (isMorning) {
      if (stops.isNotEmpty) {
        final firstStop = stops.first;

        pickupLocation = SafetyLocation(
          latitude: firstStop.latitude,
          longitude: firstStop.longitude,
          address: firstStop.address,
          placeName: firstStop.studentName,
        );
      }

      destinationLocation = SafetyLocation(
        latitude: route.schoolLatitude,
        longitude: route.schoolLongitude,
        address: route.schoolAddress,
        placeName: route.schoolName,
      );
    } else {
      pickupLocation = SafetyLocation(
        latitude: route.schoolLatitude,
        longitude: route.schoolLongitude,
        address: route.schoolAddress,
        placeName: route.schoolName,
      );

      if (stops.isNotEmpty) {
        final lastStop = stops.last;

        destinationLocation = SafetyLocation(
          latitude: lastStop.latitude,
          longitude: lastStop.longitude,
          address: lastStop.address,
          placeName: lastStop.studentName,
        );
      }
    }

    final SafetyVehicleSnapshot vehicle = SafetyVehicleSnapshot(
      vehicleId: route.vehicleId,
      vehicleType: 'Student Ride',
      vehicleNumber: route.vehicleRegistrationNumber,
      registrationNumber: route.vehicleRegistrationNumber,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return SafetyCenterScreen(
            contextData: SafetyContext(
              serviceType: SafetyServiceType.studentRide,
              referenceId: route.routeId,
              initiatedByUserId: route.driverId,
              initiatedByRole: SafetyUserRole.studentDriver,
              sourcePage: SafetySourcePage.studentTracking,
              referenceStatus: route.status.name,
              vehicle: vehicle,
              pickupLocation: pickupLocation,
              destinationLocation: destinationLocation,
              serviceTitle: 'Student Ride Safety',
              serviceSubtitle: route.routeName.isEmpty
                  ? '${isMorning ? 'Morning' : 'Afternoon'} school route'
                  : route.routeName,
              metadata: <String, dynamic>{
                'routeId': route.routeId,
                'routeName': route.routeName,
                'shift': route.shift.name,
                'schoolId': route.schoolId,
                'schoolName': route.schoolName,
                'driverId': route.driverId,
                'driverName': route.driverName,
                'vehicleId': route.vehicleId,
                'vehicleRegistrationNumber': route.vehicleRegistrationNumber,
                'assignedStudentCount': route.assignedStudentCount,
                'estimatedDistanceKm': route.estimatedDistanceKm,
                'estimatedDurationMinutes': route.estimatedDurationMinutes,

                // No pickup PIN, handover PIN or other
                // secret authorization credential is included.
                'activeStopCount': stops.length,
              },
            ),
          );
        },
      ),
    );
  }

  Widget _routeCard(StudentRideRouteModel route) {
    final isMorning = route.shift == StudentRideRouteShift.morning;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Icon(isMorning ? Icons.wb_sunny : Icons.nights_stay),
        ),
        title: Text(
          route.routeName.isEmpty ? 'School Route' : route.routeName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${isMorning ? 'Morning' : 'Afternoon'} Ã¢â‚¬Â¢ ${route.assignedStudentCount} students',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _routeDetail('School', route.schoolName),
          _routeDetail('School address', route.schoolAddress),
          _routeDetail('Route start', route.routeStartTime),
          _routeDetail('School time', route.schoolArrivalTime),
          _routeDetail('Vehicle', route.vehicleRegistrationNumber),
          _routeDetail('Stops', '${route.stops.length}'),
          _routeDetail(
            'Estimated distance',
            '${route.estimatedDistanceKm.toStringAsFixed(1)} km',
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _openStudentRouteSafety(route);
              },
              icon: const Icon(Icons.shield_outlined),
              label: const Text(
                'SAFETY & SOS',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value.trim().isEmpty ? 'Not set' : value)),
        ],
      ),
    );
  }

  Widget _safetyNotice() {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.health_and_safety_rounded, color: Colors.red),
        title: Text('Student safety comes first'),
        subtitle: Text(
          'Use authorized pickup/handover checks, follow the assigned stop order, and report any incident immediately.',
        ),
      ),
    );
  }

  int _readInt(dynamic value, int fallback) {
    return value is num ? value.toInt() : fallback;
  }

  String _money(dynamic value) {
    final amount = value is num ? value.toDouble() : 0.0;
    return amount.toStringAsFixed(2);
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            if (buttonLabel != null && onPressed != null) ...[
              const SizedBox(height: 22),
              FilledButton(onPressed: onPressed, child: Text(buttonLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
