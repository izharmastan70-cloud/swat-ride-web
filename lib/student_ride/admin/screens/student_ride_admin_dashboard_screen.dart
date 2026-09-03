import 'package:flutter/material.dart';

import 'student_ride_admin_driver_applications_screen.dart';
import 'student_ride_admin_package_management_screen.dart';
import 'student_ride_admin_route_management_screen.dart';
import 'student_ride_admin_settings_screen.dart';

class StudentRideAdminDashboardScreen extends StatelessWidget {
  const StudentRideAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = <_AdminAction>[
      const _AdminAction(
        title: 'Settings & Commission',
        subtitle:
            'Module, payments, commission, pricing and operational rules',
        icon: Icons.settings_rounded,
        color: Colors.deepPurple,
        screen: StudentRideAdminSettingsScreen(),
      ),
      const _AdminAction(
        title: 'Driver Applications',
        subtitle: 'Review, approve, reject and suspend Student Ride drivers',
        icon: Icons.badge_rounded,
        color: Colors.blue,
        screen: StudentRideAdminDriverApplicationsScreen(),
      ),
      const _AdminAction(
        title: 'Routes',
        subtitle: 'Create and edit shifts, schedules, drivers and vehicles',
        icon: Icons.alt_route_rounded,
        color: Colors.green,
        screen: StudentRideAdminRouteManagementScreen(),
      ),
      const _AdminAction(
        title: 'Packages & Pricing',
        subtitle: 'Manage monthly, daily, route and per-km prices',
        icon: Icons.inventory_2_rounded,
        color: Colors.orange,
        screen: StudentRideAdminPackageManagementScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Student Ride Admin')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF172554), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school_rounded, color: Colors.white, size: 42),
                SizedBox(height: 14),
                Text(
                  'Student Ride Control Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Manage service settings remotely without publishing an app update.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Management',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          ...actions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => action.screen),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: action.color.withValues(alpha: .12),
                          foregroundColor: action.color,
                          child: Icon(action.icon),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                action.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                action.subtitle,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_done_rounded, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Changes are stored in Firestore and become available '
                      'to Student Ride screens without requiring an app update.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminAction {
  const _AdminAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;
}
