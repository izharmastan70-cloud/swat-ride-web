import 'package:flutter/material.dart';

import 'screens/super_admin_access_guard_screen.dart';
import 'screens/super_admin_dashboard_screen.dart';

// =========================================================
// SWAT RIDE — SUPER ADMIN ROUTES
// =========================================================
//
// Global Super Admin route foundation.
//
// Existing Ride / Food / Hotel / Tourism admin routes remain untouched.
// AI Master Control route will be connected after this module analyzes clean.

class SuperAdminRoutes {
  SuperAdminRoutes._();

  static const String access = '/super-admin';
  static const String dashboard = '/super-admin/dashboard';

  static Route<dynamic>? onGenerateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      case access:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              const SuperAdminAccessGuardScreen(),
        );

      case dashboard:
        final Object? arguments = settings.arguments;

        if (arguments is SuperAdminDashboardArguments) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) =>
                SuperAdminDashboardScreen(
              adminId: arguments.adminId,
              adminName: arguments.adminName,
            ),
          );
        }

        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              const SuperAdminAccessGuardScreen(),
        );

      default:
        return null;
    }
  }
}

class SuperAdminDashboardArguments {
  final String adminId;
  final String adminName;

  const SuperAdminDashboardArguments({
    required this.adminId,
    required this.adminName,
  });
}
