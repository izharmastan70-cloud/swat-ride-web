import 'package:flutter/material.dart';

import 'admin/complaint_management_screen.dart';
import 'admin/feedback_admin_dashboard_screen.dart';
import 'admin/feedback_analytics_screen.dart';
import 'admin/feedback_management_screen.dart';

/// Internal route registry for the standalone universal feedback module.
///
/// Ride, Food, Hotel, Tour, Cargo, Parcel, Student Ride and the main app can
/// connect to these routes later without changing the feedback engine.
abstract final class FeedbackRoutes {
  static const String adminDashboard = '/feedback/admin';
  static const String reviewManagement = '/feedback/admin/reviews';
  static const String complaintManagement = '/feedback/admin/complaints';
  static const String analytics = '/feedback/admin/analytics';

  static Map<String, WidgetBuilder> adminRouteMap({
    required String adminId,
    String adminName = '',
  }) {
    return <String, WidgetBuilder>{
      adminDashboard: (_) => FeedbackAdminDashboardScreen(adminId: adminId),
      reviewManagement: (_) => FeedbackManagementScreen(adminId: adminId),
      complaintManagement: (_) =>
          ComplaintManagementScreen(adminId: adminId, adminName: adminName),
      analytics: (_) => const FeedbackAnalyticsScreen(),
    };
  }

  static Route<void>? onGenerateAdminRoute(
    RouteSettings settings, {
    required String adminId,
    String adminName = '',
  }) {
    final builder = adminRouteMap(
      adminId: adminId,
      adminName: adminName,
    )[settings.name];

    if (builder == null) {
      return null;
    }

    return MaterialPageRoute<void>(settings: settings, builder: builder);
  }

  static Future<T?> openAdminDashboard<T>(
    BuildContext context, {
    required String adminId,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (_) => FeedbackAdminDashboardScreen(adminId: adminId),
      ),
    );
  }

  static Future<T?> openReviewManagement<T>(
    BuildContext context, {
    required String adminId,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (_) => FeedbackManagementScreen(adminId: adminId),
      ),
    );
  }

  static Future<T?> openComplaintManagement<T>(
    BuildContext context, {
    required String adminId,
    String adminName = '',
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (_) =>
            ComplaintManagementScreen(adminId: adminId, adminName: adminName),
      ),
    );
  }

  static Future<T?> openAnalytics<T>(BuildContext context) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(builder: (_) => const FeedbackAnalyticsScreen()),
    );
  }
}
