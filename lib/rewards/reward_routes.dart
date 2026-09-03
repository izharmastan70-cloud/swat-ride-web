// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/rewards/reward_routes.dart
//
// Central User and Admin reward navigation.
// Existing Food/Ride routes remain independent.
// =============================================================

import 'package:flutter/material.dart';

import '../admin_rewards/screens/cashback_manager_screen.dart';
import '../admin_rewards/screens/coupon_manager_screen.dart';
import '../admin_rewards/screens/loyalty_levels_screen.dart';
import '../admin_rewards/screens/referral_manager_screen.dart';
import '../admin_rewards/screens/reward_analytics_screen.dart';
import '../admin_rewards/screens/reward_dashboard_screen.dart';
import '../admin_rewards/screens/reward_history_screen.dart';
import '../admin_rewards/screens/reward_reports_screen.dart';
import '../admin_rewards/screens/reward_settings_screen.dart';
import '../admin_rewards/screens/voucher_manager_screen.dart';
import 'models/reward_point_model.dart';
import 'models/reward_transaction_model.dart';
import 'screens/cashback_history_screen.dart';
import 'screens/coupons_screen.dart';
import 'screens/redeem_reward_screen.dart';
import 'screens/referral_screen.dart';
import 'screens/reward_details_screen.dart';
import 'screens/reward_history_screen.dart';
import 'screens/reward_levels_screen.dart';
import 'screens/reward_settings_screen.dart';
import 'screens/reward_wallet_screen.dart';
import 'screens/vouchers_screen.dart';

class RewardRouteNames {
  const RewardRouteNames._();

  static const wallet = '/rewards/wallet';
  static const history = '/rewards/history';
  static const details = '/rewards/details';
  static const coupons = '/rewards/coupons';
  static const vouchers = '/rewards/vouchers';
  static const referral = '/rewards/referral';
  static const redeem = '/rewards/redeem';
  static const levels = '/rewards/levels';
  static const settings = '/rewards/settings';
  static const cashbackHistory = '/rewards/cashback-history';

  static const adminDashboard = '/admin-rewards/dashboard';
  static const adminSettings = '/admin-rewards/settings';
  static const adminAnalytics = '/admin-rewards/analytics';
  static const adminCoupons = '/admin-rewards/coupons';
  static const adminVouchers = '/admin-rewards/vouchers';
  static const adminReferrals = '/admin-rewards/referrals';
  static const adminCashback = '/admin-rewards/cashback';
  static const adminLoyaltyLevels = '/admin-rewards/loyalty-levels';
  static const adminHistory = '/admin-rewards/history';
  static const adminReports = '/admin-rewards/reports';

  static const Set<String> all = {
    wallet,
    history,
    details,
    coupons,
    vouchers,
    referral,
    redeem,
    levels,
    settings,
    cashbackHistory,
    adminDashboard,
    adminSettings,
    adminAnalytics,
    adminCoupons,
    adminVouchers,
    adminReferrals,
    adminCashback,
    adminLoyaltyLevels,
    adminHistory,
    adminReports,
  };
}

class RewardRouteArguments {
  final String userId;
  final String adminId;
  final RewardModule? module;
  final String sourceId;
  final double eligibleAmount;
  final String loyaltyLevelId;
  final bool isFirstBooking;
  final bool phoneVerified;
  final bool identityVerified;
  final String? referralCode;
  final RewardTransactionModel? transaction;
  final int redeemedToday;
  final int redeemedThisMonth;
  final int redeemedThisYear;

  const RewardRouteArguments({
    this.userId = '',
    this.adminId = '',
    this.module,
    this.sourceId = '',
    this.eligibleAmount = 0,
    this.loyaltyLevelId = '',
    this.isFirstBooking = false,
    this.phoneVerified = false,
    this.identityVerified = false,
    this.referralCode,
    this.transaction,
    this.redeemedToday = 0,
    this.redeemedThisMonth = 0,
    this.redeemedThisYear = 0,
  });

  RewardRouteArguments copyWith({
    String? userId,
    String? adminId,
    RewardModule? module,
    bool removeModule = false,
    String? sourceId,
    double? eligibleAmount,
    String? loyaltyLevelId,
    bool? isFirstBooking,
    bool? phoneVerified,
    bool? identityVerified,
    String? referralCode,
    bool removeReferralCode = false,
    RewardTransactionModel? transaction,
    bool removeTransaction = false,
    int? redeemedToday,
    int? redeemedThisMonth,
    int? redeemedThisYear,
  }) {
    return RewardRouteArguments(
      userId: userId ?? this.userId,
      adminId: adminId ?? this.adminId,
      module: removeModule ? null : module ?? this.module,
      sourceId: sourceId ?? this.sourceId,
      eligibleAmount: eligibleAmount ?? this.eligibleAmount,
      loyaltyLevelId: loyaltyLevelId ?? this.loyaltyLevelId,
      isFirstBooking: isFirstBooking ?? this.isFirstBooking,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      identityVerified: identityVerified ?? this.identityVerified,
      referralCode: removeReferralCode
          ? null
          : referralCode ?? this.referralCode,
      transaction: removeTransaction ? null : transaction ?? this.transaction,
      redeemedToday: redeemedToday ?? this.redeemedToday,
      redeemedThisMonth: redeemedThisMonth ?? this.redeemedThisMonth,
      redeemedThisYear: redeemedThisYear ?? this.redeemedThisYear,
    );
  }

  factory RewardRouteArguments.fromDynamic(dynamic value) {
    if (value is RewardRouteArguments) {
      return value;
    }

    if (value is String) {
      return RewardRouteArguments(userId: value);
    }

    if (value is RewardTransactionModel) {
      return RewardRouteArguments(
        userId: value.userId,
        module: value.module,
        sourceId: value.sourceId ?? '',
        transaction: value,
      );
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return RewardRouteArguments(
        userId: map['userId']?.toString() ?? '',
        adminId: map['adminId']?.toString() ?? '',
        module: _moduleFromValue(map['module']),
        sourceId: map['sourceId']?.toString() ?? '',
        eligibleAmount: (map['eligibleAmount'] as num?)?.toDouble() ?? 0,
        loyaltyLevelId: map['loyaltyLevelId']?.toString() ?? '',
        isFirstBooking: map['isFirstBooking'] as bool? ?? false,
        phoneVerified: map['phoneVerified'] as bool? ?? false,
        identityVerified: map['identityVerified'] as bool? ?? false,
        referralCode: map['referralCode']?.toString(),
        transaction: map['transaction'] is RewardTransactionModel
            ? map['transaction'] as RewardTransactionModel
            : null,
        redeemedToday: (map['redeemedToday'] as num?)?.toInt() ?? 0,
        redeemedThisMonth: (map['redeemedThisMonth'] as num?)?.toInt() ?? 0,
        redeemedThisYear: (map['redeemedThisYear'] as num?)?.toInt() ?? 0,
      );
    }

    return const RewardRouteArguments();
  }

  static RewardModule? _moduleFromValue(dynamic value) {
    if (value is RewardModule) return value;
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) return null;

    for (final module in RewardModule.values) {
      if (module.name == text || module.toString() == text) return module;
    }

    return null;
  }
}

class RewardRoutes {
  const RewardRoutes._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name;

    if (name == null || !RewardRouteNames.all.contains(name)) {
      return null;
    }

    final arguments = RewardRouteArguments.fromDynamic(settings.arguments);

    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (context) =>
          _buildScreen(context: context, routeName: name, arguments: arguments),
    );
  }

  static Widget _buildScreen({
    required BuildContext context,
    required String routeName,
    required RewardRouteArguments arguments,
  }) {
    switch (routeName) {
      case RewardRouteNames.wallet:
        return _requireUser(
          arguments,
          builder: (userId) => RewardWalletScreen(
            userId: userId,
            onHistoryPressed: () => _open(
              context,
              RewardRouteNames.history,
              arguments.copyWith(userId: userId),
            ),
            onCouponsPressed: () => _open(
              context,
              RewardRouteNames.coupons,
              arguments.copyWith(userId: userId),
            ),
            onVouchersPressed: () => _open(
              context,
              RewardRouteNames.vouchers,
              arguments.copyWith(userId: userId),
            ),
            onRedeemPressed: () => _showRedeemInformation(context),
          ),
        );

      case RewardRouteNames.history:
        return _requireUser(
          arguments,
          builder: (userId) => RewardHistoryScreen(userId: userId),
        );

      case RewardRouteNames.details:
        final transaction = arguments.transaction;
        return transaction == null
            ? const RewardRouteErrorScreen(
                message: 'Reward transaction is required.',
              )
            : RewardDetailsScreen(transaction: transaction);

      case RewardRouteNames.coupons:
        return _requireUser(
          arguments,
          builder: (userId) => CouponsScreen(
            userId: userId,
            loyaltyLevelId: arguments.loyaltyLevelId,
            module: arguments.module,
            isFirstBooking: arguments.isFirstBooking,
          ),
        );

      case RewardRouteNames.vouchers:
        return _requireUser(
          arguments,
          builder: (userId) => VouchersScreen(
            userId: userId,
            module: arguments.module,
            bookingAmount: arguments.eligibleAmount,
          ),
        );

      case RewardRouteNames.referral:
        return _requireUser(
          arguments,
          builder: (userId) => ReferralScreen(
            userId: userId,
            referralCode: arguments.referralCode,
            phoneVerified: arguments.phoneVerified,
            identityVerified: arguments.identityVerified,
          ),
        );

      case RewardRouteNames.redeem:
        if (arguments.userId.trim().isEmpty ||
            arguments.module == null ||
            arguments.sourceId.trim().isEmpty ||
            arguments.eligibleAmount <= 0) {
          return const RewardRouteErrorScreen(
            message:
                'Redeem Rewards must be opened from an active booking checkout.',
          );
        }

        return RedeemRewardScreen(
          userId: arguments.userId,
          module: arguments.module!,
          sourceId: arguments.sourceId,
          eligibleAmount: arguments.eligibleAmount,
          redeemedToday: arguments.redeemedToday,
          redeemedThisMonth: arguments.redeemedThisMonth,
          redeemedThisYear: arguments.redeemedThisYear,
        );

      case RewardRouteNames.levels:
        return _requireUser(
          arguments,
          builder: (userId) =>
              RewardLevelsScreen(userId: userId, module: arguments.module),
        );

      case RewardRouteNames.settings:
        return RewardSettingsScreen(module: arguments.module);

      case RewardRouteNames.cashbackHistory:
        return _requireUser(
          arguments,
          builder: (userId) => CashbackHistoryScreen(userId: userId),
        );

      case RewardRouteNames.adminDashboard:
        return _requireAdmin(
          arguments,
          builder: (adminId) => RewardDashboardScreen(
            onOpenSettings: () => _openAdmin(
              context,
              RewardRouteNames.adminSettings,
              arguments,
              adminId,
            ),
            onOpenAnalytics: () => _openAdmin(
              context,
              RewardRouteNames.adminAnalytics,
              arguments,
              adminId,
            ),
            onOpenCoupons: () => _openAdmin(
              context,
              RewardRouteNames.adminCoupons,
              arguments,
              adminId,
            ),
            onOpenVouchers: () => _openAdmin(
              context,
              RewardRouteNames.adminVouchers,
              arguments,
              adminId,
            ),
            onOpenReferrals: () => _openAdmin(
              context,
              RewardRouteNames.adminReferrals,
              arguments,
              adminId,
            ),
            onOpenCashback: () => _openAdmin(
              context,
              RewardRouteNames.adminCashback,
              arguments,
              adminId,
            ),
            onOpenLoyaltyLevels: () => _openAdmin(
              context,
              RewardRouteNames.adminLoyaltyLevels,
              arguments,
              adminId,
            ),
            onOpenHistory: () => _openAdmin(
              context,
              RewardRouteNames.adminHistory,
              arguments,
              adminId,
            ),
            onOpenReports: () => _openAdmin(
              context,
              RewardRouteNames.adminReports,
              arguments,
              adminId,
            ),
          ),
        );

      case RewardRouteNames.adminSettings:
        return _requireAdmin(
          arguments,
          builder: (adminId) => AdminRewardSettingsScreen(adminId: adminId),
        );

      case RewardRouteNames.adminAnalytics:
        return const RewardAnalyticsScreen();

      case RewardRouteNames.adminCoupons:
        return _requireAdmin(
          arguments,
          builder: (adminId) => CouponManagerScreen(adminId: adminId),
        );

      case RewardRouteNames.adminVouchers:
        return _requireAdmin(
          arguments,
          builder: (adminId) => VoucherManagerScreen(adminId: adminId),
        );

      case RewardRouteNames.adminReferrals:
        return _requireAdmin(
          arguments,
          builder: (adminId) => ReferralManagerScreen(adminId: adminId),
        );

      case RewardRouteNames.adminCashback:
        return _requireAdmin(
          arguments,
          builder: (adminId) => CashbackManagerScreen(adminId: adminId),
        );

      case RewardRouteNames.adminLoyaltyLevels:
        return const LoyaltyLevelsScreen();

      case RewardRouteNames.adminHistory:
        return const AdminRewardHistoryScreen();

      case RewardRouteNames.adminReports:
        return const RewardReportsScreen();
    }

    return RewardRouteErrorScreen(message: 'Unknown reward route: $routeName');
  }

  static Widget _requireUser(
    RewardRouteArguments arguments, {
    required Widget Function(String userId) builder,
  }) {
    final userId = arguments.userId.trim();
    return userId.isEmpty
        ? const RewardRouteErrorScreen(
            message: 'Please sign in before opening Rewards.',
          )
        : builder(userId);
  }

  static Widget _requireAdmin(
    RewardRouteArguments arguments, {
    required Widget Function(String adminId) builder,
  }) {
    final adminId = arguments.adminId.trim();
    return adminId.isEmpty
        ? const RewardRouteErrorScreen(
            message: 'Verified Admin access is required.',
          )
        : builder(adminId);
  }

  static Future<void> _open(
    BuildContext context,
    String routeName,
    RewardRouteArguments arguments,
  ) async {
    await Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }

  static void _openAdmin(
    BuildContext context,
    String routeName,
    RewardRouteArguments arguments,
    String adminId,
  ) {
    _open(context, routeName, arguments.copyWith(adminId: adminId));
  }

  static Future<void> _showRedeemInformation(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Redeem Rewards'),
        content: const Text(
          'Reward points can be redeemed from an eligible booking or order '
          'checkout. Nothing will be applied without your confirmation.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class RewardRouteErrorScreen extends StatelessWidget {
  final String message;

  const RewardRouteErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SWAT RIDE Rewards')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 52),
              const SizedBox(height: 14),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
