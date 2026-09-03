import 'package:flutter/material.dart';

import '../../rewards/models/reward_point_model.dart';
import '../../rewards/models/reward_settings_model.dart';
import '../../rewards/services/reward_service.dart';

class AdminRewardDashboardMetrics {
  const AdminRewardDashboardMetrics({
    this.totalMembers = 0,
    this.activeMembers = 0,
    this.pointsIssued = 0,
    this.pointsRedeemed = 0,
    this.pointsExpired = 0,
    this.cashbackIssued = 0,
    this.activeCoupons = 0,
    this.activeVouchers = 0,
    this.pendingReferrals = 0,
    this.failedTransactions = 0,
  });

  final int totalMembers;
  final int activeMembers;
  final int pointsIssued;
  final int pointsRedeemed;
  final int pointsExpired;
  final double cashbackIssued;
  final int activeCoupons;
  final int activeVouchers;
  final int pendingReferrals;
  final int failedTransactions;

  factory AdminRewardDashboardMetrics.fromMap(Map<String, dynamic> map) {
    return AdminRewardDashboardMetrics(
      totalMembers: (map['totalMembers'] as num?)?.toInt() ?? 0,
      activeMembers: (map['activeMembers'] as num?)?.toInt() ?? 0,
      pointsIssued: (map['pointsIssued'] as num?)?.toInt() ?? 0,
      pointsRedeemed: (map['pointsRedeemed'] as num?)?.toInt() ?? 0,
      pointsExpired: (map['pointsExpired'] as num?)?.toInt() ?? 0,
      cashbackIssued: (map['cashbackIssued'] as num?)?.toDouble() ?? 0,
      activeCoupons: (map['activeCoupons'] as num?)?.toInt() ?? 0,
      activeVouchers: (map['activeVouchers'] as num?)?.toInt() ?? 0,
      pendingReferrals: (map['pendingReferrals'] as num?)?.toInt() ?? 0,
      failedTransactions: (map['failedTransactions'] as num?)?.toInt() ?? 0,
    );
  }
}

typedef AdminRewardMetricsLoader =
    Future<AdminRewardDashboardMetrics> Function();

class RewardDashboardScreen extends StatefulWidget {
  const RewardDashboardScreen({
    super.key,
    this.rewardService,
    this.metricsLoader,
    this.onOpenSettings,
    this.onOpenAnalytics,
    this.onOpenCoupons,
    this.onOpenVouchers,
    this.onOpenReferrals,
    this.onOpenCashback,
    this.onOpenLoyaltyLevels,
    this.onOpenHistory,
    this.onOpenReports,
  });

  final RewardService? rewardService;
  final AdminRewardMetricsLoader? metricsLoader;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenAnalytics;
  final VoidCallback? onOpenCoupons;
  final VoidCallback? onOpenVouchers;
  final VoidCallback? onOpenReferrals;
  final VoidCallback? onOpenCashback;
  final VoidCallback? onOpenLoyaltyLevels;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenReports;

  @override
  State<RewardDashboardScreen> createState() =>
      _RewardDashboardScreenState();
}

class _RewardDashboardScreenState extends State<RewardDashboardScreen> {
  late final RewardService _rewardService;
  RewardSettingsModel? _settings;
  AdminRewardDashboardMetrics _metrics =
      const AdminRewardDashboardMetrics();
  bool _loading = true;
  Object? _error;

  static const List<RewardModule> _customerModules = [
    RewardModule.ride,
    RewardModule.food,
    RewardModule.hotel,
    RewardModule.tourism,
    RewardModule.cargo,
    RewardModule.parcel,
    RewardModule.wallet,
  ];

  @override
  void initState() {
    super.initState();
    _rewardService = widget.rewardService ?? RewardService();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final settingsFuture = _rewardService.getSettings();
      final metricsFuture = widget.metricsLoader?.call() ??
          Future.value(const AdminRewardDashboardMetrics());
      final results = await Future.wait<Object>([
        settingsFuture,
        metricsFuture,
      ]);
      if (!mounted) return;
      setState(() {
        _settings = results[0] as RewardSettingsModel;
        _metrics = results[1] as AdminRewardDashboardMetrics;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reward Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _loading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _settings == null) {
      return const _FullPageState(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _settings == null) {
      return _FullPageState(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56),
            const SizedBox(height: 12),
            const Text('Reward dashboard could not be loaded.'),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final settings = _settings!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
      children: [
        _MasterStatusCard(
          settings: settings,
          onManage: widget.onOpenSettings,
        ),
        if (!settings.hasValidConfiguration) ...[
          const SizedBox(height: 12),
          const _AlertCard(
            icon: Icons.warning_amber_rounded,
            title: 'Configuration requires attention',
            message:
                'Point value, redemption limits or expiry settings are invalid.',
            color: Colors.orange,
          ),
        ],
        if (_metrics.failedTransactions > 0) ...[
          const SizedBox(height: 12),
          _AlertCard(
            icon: Icons.error_outline_rounded,
            title: 'Failed transactions',
            message:
                '${_metrics.failedTransactions} reward transactions require review.',
            color: Colors.red,
            onTap: widget.onOpenHistory,
          ),
        ],
        const SizedBox(height: 20),
        const _SectionTitle(
          title: 'Program overview',
          icon: Icons.insights_rounded,
        ),
        const SizedBox(height: 10),
        _MetricsGrid(metrics: _metrics),
        const SizedBox(height: 22),
        const _SectionTitle(
          title: 'Global controls',
          icon: Icons.tune_rounded,
        ),
        const SizedBox(height: 10),
        _GlobalControlsCard(settings: settings),
        const SizedBox(height: 22),
        const _SectionTitle(
          title: 'Module coverage',
          icon: Icons.apps_rounded,
        ),
        const SizedBox(height: 10),
        _ModuleCoverageCard(
          settings: settings,
          modules: _customerModules,
        ),
        const SizedBox(height: 22),
        const _SectionTitle(
          title: 'Management',
          icon: Icons.admin_panel_settings_rounded,
        ),
        const SizedBox(height: 10),
        _ManagementGrid(
          onOpenSettings: widget.onOpenSettings,
          onOpenAnalytics: widget.onOpenAnalytics,
          onOpenCoupons: widget.onOpenCoupons,
          onOpenVouchers: widget.onOpenVouchers,
          onOpenReferrals: widget.onOpenReferrals,
          onOpenCashback: widget.onOpenCashback,
          onOpenLoyaltyLevels: widget.onOpenLoyaltyLevels,
          onOpenHistory: widget.onOpenHistory,
          onOpenReports: widget.onOpenReports,
        ),
        const SizedBox(height: 22),
        _SafetyCard(settings: settings),
        const SizedBox(height: 14),
        Text(
          'Configuration version ${settings.version} • Updated ${_date(settings.updatedAt)}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MasterStatusCard extends StatelessWidget {
  const _MasterStatusCard({required this.settings, this.onManage});
  final RewardSettingsModel settings;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    final enabled = settings.rewardsEnabled;
    final color = enabled ? Colors.green : Colors.orange;
    return Card(
      margin: EdgeInsets.zero,
      color: color.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withValues(alpha: 0.16),
              child: Icon(
                enabled ? Icons.workspace_premium_rounded : Icons.pause_rounded,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enabled ? 'Rewards engine is ON' : 'Rewards engine is OFF',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    enabled
                        ? 'Earning and redemption follow Admin rules.'
                        : 'Users cannot earn or redeem reward points.',
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Manage settings',
              onPressed: onManage,
              icon: const Icon(Icons.settings_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});
  final AdminRewardDashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricData('Members', _compact(metrics.totalMembers), Icons.people_alt_rounded, Colors.blue),
      _MetricData('Active members', _compact(metrics.activeMembers), Icons.person_pin_rounded, Colors.teal),
      _MetricData('Points issued', _compact(metrics.pointsIssued), Icons.add_circle_rounded, Colors.green),
      _MetricData('Points redeemed', _compact(metrics.pointsRedeemed), Icons.redeem_rounded, Colors.deepPurple),
      _MetricData('Points expired', _compact(metrics.pointsExpired), Icons.timer_off_rounded, Colors.orange),
      _MetricData('Cashback', '${_money(metrics.cashbackIssued)} PKR', Icons.savings_rounded, Colors.pink),
      _MetricData('Active coupons', '${metrics.activeCoupons}', Icons.local_offer_rounded, Colors.indigo),
      _MetricData('Active vouchers', '${metrics.activeVouchers}', Icons.card_giftcard_rounded, Colors.cyan),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
                ? 3
                : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) => _MetricCard(data: cards[index]),
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(data.icon, color: data.color),
            Text(
              data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(data.label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _GlobalControlsCard extends StatelessWidget {
  const _GlobalControlsCard({required this.settings});
  final RewardSettingsModel settings;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _StatusTile('Reward points', settings.rewardsEnabled),
          _StatusTile('Promo codes', settings.promoEnabled),
          _StatusTile('Coupons', settings.couponEnabled),
          _StatusTile('Vouchers', settings.voucherEnabled),
          _StatusTile('Cashback', settings.cashbackEnabled),
          _StatusTile('Referral', settings.referralEnabled),
          _StatusTile('Loyalty levels', settings.loyaltyEnabled),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile(this.label, this.enabled);
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.green : Theme.of(context).colorScheme.outline;
    return ListTile(
      dense: true,
      leading: Icon(
        enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: color,
      ),
      title: Text(label),
      trailing: Text(
        enabled ? 'ON' : 'OFF',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ModuleCoverageCard extends StatelessWidget {
  const _ModuleCoverageCard({required this.settings, required this.modules});
  final RewardSettingsModel settings;
  final List<RewardModule> modules;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Module')),
            DataColumn(label: Text('Reward')),
            DataColumn(label: Text('Promo')),
            DataColumn(label: Text('Coupon')),
            DataColumn(label: Text('Voucher')),
            DataColumn(label: Text('Cashback')),
            DataColumn(label: Text('Referral')),
            DataColumn(label: Text('Loyalty')),
          ],
          rows: modules.map((module) {
            return DataRow(
              cells: [
                DataCell(Text(_title(module.name))),
                DataCell(_TableStatus(settings.isRewardEnabledForModule(module))),
                DataCell(_TableStatus(settings.isPromoEnabledForModule(module))),
                DataCell(_TableStatus(settings.isCouponEnabledForModule(module))),
                DataCell(_TableStatus(settings.isVoucherEnabledForModule(module))),
                DataCell(_TableStatus(settings.isCashbackEnabledForModule(module))),
                DataCell(_TableStatus(settings.isReferralEnabledForModule(module))),
                DataCell(_TableStatus(settings.isLoyaltyEnabledForModule(module))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TableStatus extends StatelessWidget {
  const _TableStatus(this.enabled);
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Icon(
      enabled ? Icons.check_circle_rounded : Icons.remove_circle_outline,
      color: enabled ? Colors.green : Theme.of(context).colorScheme.outline,
      size: 20,
    );
  }
}

class _ManagementGrid extends StatelessWidget {
  const _ManagementGrid({
    this.onOpenSettings,
    this.onOpenAnalytics,
    this.onOpenCoupons,
    this.onOpenVouchers,
    this.onOpenReferrals,
    this.onOpenCashback,
    this.onOpenLoyaltyLevels,
    this.onOpenHistory,
    this.onOpenReports,
  });

  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenAnalytics;
  final VoidCallback? onOpenCoupons;
  final VoidCallback? onOpenVouchers;
  final VoidCallback? onOpenReferrals;
  final VoidCallback? onOpenCashback;
  final VoidCallback? onOpenLoyaltyLevels;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenReports;

  @override
  Widget build(BuildContext context) {
    final items = [
      _ManagementData('Settings', Icons.settings_rounded, onOpenSettings),
      _ManagementData('Analytics', Icons.query_stats_rounded, onOpenAnalytics),
      _ManagementData('Coupons', Icons.local_offer_rounded, onOpenCoupons),
      _ManagementData('Vouchers', Icons.card_giftcard_rounded, onOpenVouchers),
      _ManagementData('Referrals', Icons.group_add_rounded, onOpenReferrals),
      _ManagementData('Cashback', Icons.savings_rounded, onOpenCashback),
      _ManagementData('Loyalty levels', Icons.workspace_premium_rounded, onOpenLoyaltyLevels),
      _ManagementData('History', Icons.history_rounded, onOpenHistory),
      _ManagementData('Reports', Icons.description_rounded, onOpenReports),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 800 ? 4 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 29),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ManagementData {
  const _ManagementData(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard({required this.settings});
  final RewardSettingsModel settings;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security_rounded),
                SizedBox(width: 8),
                Text('Safety controls', style: TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            _SafetyRow('Successful payment required', settings.requireSuccessfulPayment),
            _SafetyRow('Completed booking required', settings.requireCompletedBooking),
            _SafetyRow('Duplicate protection', settings.duplicateRewardProtectionEnabled),
            _SafetyRow('Negative balance protection', settings.preventNegativeRewardBalance),
            _SafetyRow('AI recommendations', settings.aiRecommendationsEnabled),
            const _SafetyRow('AI automatic payment/discount', false),
          ],
        ),
      ),
    );
  }
}

class _SafetyRow extends StatelessWidget {
  const _SafetyRow(this.label, this.enabled);
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_rounded : Icons.close_rounded,
            color: enabled ? Colors.green : Colors.red,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: color.withValues(alpha: 0.10),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(message),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _FullPageState extends StatelessWidget {
  const _FullPageState({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: constraints.maxHeight, child: Center(child: child)),
        ],
      ),
    );
  }
}

String _compact(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}

String _money(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

String _title(String value) {
  final spaced = value.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  return spaced.isEmpty ? '' : spaced[0].toUpperCase() + spaced.substring(1);
}

String _date(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.day)}/${two(value.month)}/${value.year}';
}
