import 'package:flutter/material.dart';

import '../../rewards/models/reward_point_model.dart';

enum RewardAnalyticsRange {
  today,
  last7Days,
  last30Days,
  last90Days,
  custom,
}

class RewardModuleAnalytics {
  const RewardModuleAnalytics({
    required this.module,
    this.pointsEarned = 0,
    this.pointsRedeemed = 0,
    this.cashback = 0,
    this.transactions = 0,
  });

  final RewardModule module;
  final int pointsEarned;
  final int pointsRedeemed;
  final double cashback;
  final int transactions;

  factory RewardModuleAnalytics.fromMap(Map<String, dynamic> map) {
    return RewardModuleAnalytics(
      module: RewardModule.values.firstWhere(
        (value) => value.name == map['module']?.toString(),
        orElse: () => RewardModule.all,
      ),
      pointsEarned: (map['pointsEarned'] as num?)?.toInt() ?? 0,
      pointsRedeemed: (map['pointsRedeemed'] as num?)?.toInt() ?? 0,
      cashback: (map['cashback'] as num?)?.toDouble() ?? 0,
      transactions: (map['transactions'] as num?)?.toInt() ?? 0,
    );
  }
}

class RewardAnalyticsData {
  const RewardAnalyticsData({
    this.totalMembers = 0,
    this.newMembers = 0,
    this.pointsEarned = 0,
    this.pointsRedeemed = 0,
    this.pointsExpired = 0,
    this.pointsReversed = 0,
    this.cashbackIssued = 0,
    this.couponUses = 0,
    this.voucherUses = 0,
    this.referralInvites = 0,
    this.referralConversions = 0,
    this.failedTransactions = 0,
    this.suspiciousTransactions = 0,
    this.moduleAnalytics = const [],
    this.loyaltyDistribution = const {},
    this.dailyPoints = const {},
  });

  final int totalMembers;
  final int newMembers;
  final int pointsEarned;
  final int pointsRedeemed;
  final int pointsExpired;
  final int pointsReversed;
  final double cashbackIssued;
  final int couponUses;
  final int voucherUses;
  final int referralInvites;
  final int referralConversions;
  final int failedTransactions;
  final int suspiciousTransactions;
  final List<RewardModuleAnalytics> moduleAnalytics;
  final Map<String, int> loyaltyDistribution;
  final Map<DateTime, int> dailyPoints;

  double get redemptionRate =>
      pointsEarned <= 0 ? 0 : (pointsRedeemed / pointsEarned) * 100;

  double get referralConversionRate => referralInvites <= 0
      ? 0
      : (referralConversions / referralInvites) * 100;

  factory RewardAnalyticsData.fromMap(Map<String, dynamic> map) {
    final rawModules = map['moduleAnalytics'] as List? ?? const [];
    final rawLoyalty = map['loyaltyDistribution'] as Map? ?? const {};
    final rawDaily = map['dailyPoints'] as Map? ?? const {};
    final daily = <DateTime, int>{};
    for (final entry in rawDaily.entries) {
      final date = DateTime.tryParse(entry.key.toString());
      if (date != null) daily[date] = (entry.value as num?)?.toInt() ?? 0;
    }
    return RewardAnalyticsData(
      totalMembers: (map['totalMembers'] as num?)?.toInt() ?? 0,
      newMembers: (map['newMembers'] as num?)?.toInt() ?? 0,
      pointsEarned: (map['pointsEarned'] as num?)?.toInt() ?? 0,
      pointsRedeemed: (map['pointsRedeemed'] as num?)?.toInt() ?? 0,
      pointsExpired: (map['pointsExpired'] as num?)?.toInt() ?? 0,
      pointsReversed: (map['pointsReversed'] as num?)?.toInt() ?? 0,
      cashbackIssued: (map['cashbackIssued'] as num?)?.toDouble() ?? 0,
      couponUses: (map['couponUses'] as num?)?.toInt() ?? 0,
      voucherUses: (map['voucherUses'] as num?)?.toInt() ?? 0,
      referralInvites: (map['referralInvites'] as num?)?.toInt() ?? 0,
      referralConversions:
          (map['referralConversions'] as num?)?.toInt() ?? 0,
      failedTransactions:
          (map['failedTransactions'] as num?)?.toInt() ?? 0,
      suspiciousTransactions:
          (map['suspiciousTransactions'] as num?)?.toInt() ?? 0,
      moduleAnalytics: rawModules
          .whereType<Map>()
          .map((value) => RewardModuleAnalytics.fromMap(
                Map<String, dynamic>.from(value),
              ))
          .toList(),
      loyaltyDistribution: rawLoyalty.map(
        (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
      ),
      dailyPoints: daily,
    );
  }
}

typedef RewardAnalyticsLoader = Future<RewardAnalyticsData> Function(
  DateTime start,
  DateTime end,
);

class RewardAnalyticsScreen extends StatefulWidget {
  const RewardAnalyticsScreen({
    super.key,
    this.analyticsLoader,
    this.initialData = const RewardAnalyticsData(),
    this.onExport,
    this.onReviewFailed,
    this.onReviewSuspicious,
  });

  final RewardAnalyticsLoader? analyticsLoader;
  final RewardAnalyticsData initialData;
  final void Function(DateTime start, DateTime end)? onExport;
  final VoidCallback? onReviewFailed;
  final VoidCallback? onReviewSuspicious;

  @override
  State<RewardAnalyticsScreen> createState() =>
      _RewardAnalyticsScreenState();
}

class _RewardAnalyticsScreenState extends State<RewardAnalyticsScreen> {
  RewardAnalyticsRange _range = RewardAnalyticsRange.last30Days;
  late DateTime _start;
  late DateTime _end;
  RewardAnalyticsData _data = const RewardAnalyticsData();
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _setDates(RewardAnalyticsRange.last30Days, notify: false);
    _load();
  }

  void _setDates(RewardAnalyticsRange range, {bool notify = true}) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    DateTime start;
    switch (range) {
      case RewardAnalyticsRange.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case RewardAnalyticsRange.last7Days:
        start = end.subtract(const Duration(days: 6));
        break;
      case RewardAnalyticsRange.last30Days:
        start = end.subtract(const Duration(days: 29));
        break;
      case RewardAnalyticsRange.last90Days:
        start = end.subtract(const Duration(days: 89));
        break;
      case RewardAnalyticsRange.custom:
        start = _start;
        break;
    }
    if (notify) {
      setState(() {
        _range = range;
        _start = start;
        _end = end;
      });
    } else {
      _range = range;
      _start = start;
      _end = end;
    }
  }

  Future<void> _chooseCustomRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _range = RewardAnalyticsRange.custom;
      _start = DateTime(selected.start.year, selected.start.month, selected.start.day);
      _end = DateTime(selected.end.year, selected.end.month, selected.end.day, 23, 59, 59);
    });
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loader = widget.analyticsLoader;
      final data = loader == null
          ? widget.initialData
          : await loader(_start, _end);
      if (!mounted) return;
      setState(() => _data = data);
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
        title: const Text('Reward Analytics'),
        actions: [
          IconButton(
            tooltip: 'Export report',
            onPressed: widget.onExport == null
                ? null
                : () => widget.onExport!(_start, _end),
            icon: const Icon(Icons.download_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _data.totalMembers == 0) {
      return const _FullPage(child: CircularProgressIndicator());
    }
    if (_error != null && _data.totalMembers == 0) {
      return _FullPage(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 54),
            const SizedBox(height: 12),
            const Text('Analytics could not be loaded.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
      children: [
        _RangeSelector(
          selected: _range,
          start: _start,
          end: _end,
          onSelected: (range) {
            if (range == RewardAnalyticsRange.custom) {
              _chooseCustomRange();
            } else {
              _setDates(range);
              _load();
            }
          },
        ),
        const SizedBox(height: 14),
        if (_loading) const LinearProgressIndicator(),
        if (_loading) const SizedBox(height: 10),
        _KpiGrid(data: _data),
        if (_data.failedTransactions > 0 ||
            _data.suspiciousTransactions > 0) ...[
          const SizedBox(height: 18),
          _RiskPanel(
            failed: _data.failedTransactions,
            suspicious: _data.suspiciousTransactions,
            onFailed: widget.onReviewFailed,
            onSuspicious: widget.onReviewSuspicious,
          ),
        ],
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Points trend',
          icon: Icons.show_chart_rounded,
          child: _DailyPointsChart(values: _data.dailyPoints),
        ),
        _SectionCard(
          title: 'Module performance',
          icon: Icons.apps_rounded,
          child: _ModuleTable(items: _data.moduleAnalytics),
        ),
        _SectionCard(
          title: 'Loyalty distribution',
          icon: Icons.workspace_premium_rounded,
          child: _DistributionBars(values: _data.loyaltyDistribution),
        ),
        _SectionCard(
          title: 'Campaign performance',
          icon: Icons.campaign_rounded,
          child: _CampaignSummary(data: _data),
        ),
        const _SafetyNote(),
      ],
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selected, required this.start, required this.end, required this.onSelected});
  final RewardAnalyticsRange selected;
  final DateTime start;
  final DateTime end;
  final ValueChanged<RewardAnalyticsRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_date(start)} – ${_date(end)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Today', RewardAnalyticsRange.today),
                _chip('7 days', RewardAnalyticsRange.last7Days),
                _chip('30 days', RewardAnalyticsRange.last30Days),
                _chip('90 days', RewardAnalyticsRange.last90Days),
                _chip('Custom', RewardAnalyticsRange.custom),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, RewardAnalyticsRange value) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.data});
  final RewardAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final items = [
      _Kpi('Members', _compact(data.totalMembers), Icons.people_rounded, Colors.blue),
      _Kpi('New members', _compact(data.newMembers), Icons.person_add_rounded, Colors.teal),
      _Kpi('Points earned', _compact(data.pointsEarned), Icons.add_circle_rounded, Colors.green),
      _Kpi('Points redeemed', _compact(data.pointsRedeemed), Icons.redeem_rounded, Colors.deepPurple),
      _Kpi('Expired', _compact(data.pointsExpired), Icons.timer_off_rounded, Colors.orange),
      _Kpi('Reversed', _compact(data.pointsReversed), Icons.undo_rounded, Colors.red),
      _Kpi('Cashback', '${_money(data.cashbackIssued)} PKR', Icons.savings_rounded, Colors.pink),
      _Kpi('Redeem rate', '${data.redemptionRate.toStringAsFixed(1)}%', Icons.percent_rounded, Colors.indigo),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 850 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) => _KpiCard(item: items[index]),
        );
      },
    );
  }
}

class _Kpi {
  const _Kpi(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});
  final _Kpi item;

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
            Icon(item.icon, color: item.color),
            Text(item.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(item.label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RiskPanel extends StatelessWidget {
  const _RiskPanel({required this.failed, required this.suspicious, this.onFailed, this.onSuspicious});
  final int failed;
  final int suspicious;
  final VoidCallback? onFailed;
  final VoidCallback? onSuspicious;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.red.withValues(alpha: 0.08),
      child: Column(
        children: [
          if (failed > 0)
            ListTile(
              onTap: onFailed,
              leading: const Icon(Icons.error_outline_rounded, color: Colors.red),
              title: Text('$failed failed transactions'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          if (suspicious > 0)
            ListTile(
              onTap: onSuspicious,
              leading: const Icon(Icons.shield_outlined, color: Colors.orange),
              title: Text('$suspicious suspicious activities'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
        ],
      ),
    );
  }
}

class _DailyPointsChart extends StatelessWidget {
  const _DailyPointsChart({required this.values});
  final Map<DateTime, int> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const _Empty(text: 'No points trend data for this period.');
    final entries = values.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final visible = entries.length > 14 ? entries.sublist(entries.length - 14) : entries;
    final maximum = visible.fold<int>(1, (max, item) => item.value > max ? item.value : max);
    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: visible.map((entry) {
          final ratio = entry.value / maximum;
          return Expanded(
            child: Tooltip(
              message: '${_date(entry.key)}: ${entry.value} points',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(_compact(entry.value), style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Container(
                      height: 130 * ratio,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text('${entry.key.day}', style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ModuleTable extends StatelessWidget {
  const _ModuleTable({required this.items});
  final List<RewardModuleAnalytics> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _Empty(text: 'No module analytics available.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Module')),
          DataColumn(label: Text('Earned'), numeric: true),
          DataColumn(label: Text('Redeemed'), numeric: true),
          DataColumn(label: Text('Cashback'), numeric: true),
          DataColumn(label: Text('Transactions'), numeric: true),
        ],
        rows: items.map((item) => DataRow(cells: [
          DataCell(Text(_title(item.module.name))),
          DataCell(Text(_compact(item.pointsEarned))),
          DataCell(Text(_compact(item.pointsRedeemed))),
          DataCell(Text('${_money(item.cashback)} PKR')),
          DataCell(Text(_compact(item.transactions))),
        ])).toList(),
      ),
    );
  }
}

class _DistributionBars extends StatelessWidget {
  const _DistributionBars({required this.values});
  final Map<String, int> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const _Empty(text: 'No loyalty distribution available.');
    final maximum = values.values.fold<int>(1, (max, value) => value > max ? value : max);
    return Column(
      children: values.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              SizedBox(width: 75, child: Text(_title(entry.key))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: entry.value / maximum, minHeight: 12),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(width: 50, child: Text(_compact(entry.value), textAlign: TextAlign.end)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CampaignSummary extends StatelessWidget {
  const _CampaignSummary({required this.data});
  final RewardAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryRow('Coupon uses', _compact(data.couponUses)),
        _SummaryRow('Voucher uses', _compact(data.voucherUses)),
        _SummaryRow('Referral invites', _compact(data.referralInvites)),
        _SummaryRow('Referral conversions', _compact(data.referralConversions)),
        _SummaryRow('Referral conversion rate', '${data.referralConversionRate.toStringAsFixed(1)}%'),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))]),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.only(top: 14),
      child: ListTile(
        leading: Icon(Icons.info_outline_rounded),
        title: Text('Analytics is read-only'),
        subtitle: Text('Reports never change balances, discounts, bookings or payments.'),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text(text, textAlign: TextAlign.center)),
      );
}

class _FullPage extends StatelessWidget {
  const _FullPage({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [SizedBox(height: constraints.maxHeight, child: Center(child: child))],
        ),
      );
}

String _compact(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}

String _money(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _title(String value) {
  final spaced = value.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match.group(1)} ${match.group(2)}');
  return spaced.isEmpty ? '' : spaced[0].toUpperCase() + spaced.substring(1);
}
