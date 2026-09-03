import 'package:flutter/material.dart';

import '../../rewards/models/reward_point_model.dart';
import '../../rewards/models/reward_transaction_model.dart';

enum RewardReportExportFormat { csv, pdf }

typedef RewardReportLoader = Future<List<RewardTransactionModel>> Function(
  DateTimeRange dateRange,
  RewardModule? module,
);

typedef RewardReportExportCallback = Future<void> Function(
  RewardReportExportFormat format,
  DateTimeRange dateRange,
  RewardModule? module,
  List<RewardTransactionModel> transactions,
);

class RewardReportsScreen extends StatefulWidget {
  final List<RewardTransactionModel> initialTransactions;
  final RewardReportLoader? onLoad;
  final RewardReportExportCallback? onExport;

  const RewardReportsScreen({
    super.key,
    this.initialTransactions = const [],
    this.onLoad,
    this.onExport,
  });

  @override
  State<RewardReportsScreen> createState() => _RewardReportsScreenState();
}

class _RewardReportsScreenState extends State<RewardReportsScreen> {
  static const _navy = Color(0xFF09233F);
  static const _blue = Color(0xFF1264E5);
  static const _background = Color(0xFFF5F7FB);

  late List<RewardTransactionModel> _transactions;
  late DateTimeRange _dateRange;
  RewardModule? _module;
  bool _loading = false;
  bool _exporting = false;

  static const _modules = <RewardModule>[
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
    _transactions = [...widget.initialTransactions];
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    if (widget.onLoad != null) _load();
  }

  List<RewardTransactionModel> get _filtered {
    final start = DateTime(
      _dateRange.start.year,
      _dateRange.start.month,
      _dateRange.start.day,
    );
    final end = DateTime(
      _dateRange.end.year,
      _dateRange.end.month,
      _dateRange.end.day,
      23,
      59,
      59,
      999,
    );
    return _transactions.where((transaction) {
      if (transaction.createdAt.isBefore(start) ||
          transaction.createdAt.isAfter(end)) {
        return false;
      }
      return _module == null ||
          transaction.module == _module ||
          transaction.module == RewardModule.all;
    }).toList();
  }

  int get _earned => _filtered
      .where((item) =>
          item.points > 0 &&
          item.status == RewardTransactionStatus.completed)
      .fold(0, (total, item) => total + item.points);

  int get _redeemed => _filtered
      .where((item) =>
          item.type == RewardTransactionType.redeemed &&
          item.status == RewardTransactionStatus.completed)
      .fold(0, (total, item) => total + item.points.abs());

  int get _expired => _filtered
      .where((item) =>
          item.type == RewardTransactionType.expired ||
          item.status == RewardTransactionStatus.expired)
      .fold(0, (total, item) => total + item.points.abs());

  int get _netPoints => _filtered
      .where((item) => item.status == RewardTransactionStatus.completed)
      .fold(0, (total, item) => total + item.points);

  int get _activeUsers => _filtered.map((item) => item.userId).toSet().length;

  Future<void> _load() async {
    if (widget.onLoad == null || _loading) return;
    setState(() => _loading = true);
    try {
      final result = await widget.onLoad!.call(_dateRange, _module);
      if (!mounted) return;
      setState(() => _transactions = result);
    } catch (error) {
      if (mounted) _message('Report load failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _dateRange,
    );
    if (selected == null) return;
    setState(() => _dateRange = selected);
    await _load();
  }

  Future<void> _setPreset(int days) async {
    final now = DateTime.now();
    setState(() {
      _dateRange = DateTimeRange(
        start: DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: days - 1)),
        end: now,
      );
    });
    await _load();
  }

  Future<void> _export(RewardReportExportFormat format) async {
    if (widget.onExport == null) {
      _message('${_label(format.name)} export will connect with Admin backend.');
      return;
    }
    setState(() => _exporting = true);
    try {
      await widget.onExport!
          .call(format, _dateRange, _module, _filtered);
      if (mounted) _message('${_label(format.name)} report exported.');
    } catch (error) {
      if (mounted) _message('Export failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  Map<RewardModule, _ModuleTotal> get _moduleTotals {
    final totals = <RewardModule, _ModuleTotal>{};
    for (final transaction in _filtered) {
      final old = totals[transaction.module] ?? const _ModuleTotal();
      totals[transaction.module] = _ModuleTotal(
        earned: old.earned + (transaction.points > 0 ? transaction.points : 0),
        spent: old.spent + (transaction.points < 0 ? transaction.points.abs() : 0),
        transactions: old.transactions + 1,
      );
    }
    return totals;
  }

  Map<RewardTransactionType, int> get _typeTotals {
    final totals = <RewardTransactionType, int>{};
    for (final transaction in _filtered) {
      totals.update(transaction.type, (value) => value + 1,
          ifAbsent: () => 1);
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Reward Reports'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<RewardReportExportFormat>(
            enabled: !_exporting,
            tooltip: 'Export report',
            onSelected: _export,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: RewardReportExportFormat.csv,
                child: ListTile(
                  leading: Icon(Icons.table_view_outlined),
                  title: Text('Export CSV'),
                ),
              ),
              PopupMenuItem(
                value: RewardReportExportFormat.pdf,
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined),
                  title: Text('Export PDF'),
                ),
              ),
            ],
            icon: _exporting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _ReportFilters(
              dateRange: _dateRange,
              module: _module,
              modules: _modules,
              onRangePressed: _selectRange,
              onPresetPressed: _setPreset,
              onModuleChanged: (value) async {
                setState(() => _module = value);
                await _load();
              },
            ),
            const SizedBox(height: 16),
            if (_loading)
              const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.45,
              children: [
                _MetricCard(
                  label: 'Points earned',
                  value: _number(_earned),
                  icon: Icons.add_circle_outline,
                  color: Colors.green.shade700,
                ),
                _MetricCard(
                  label: 'Points redeemed',
                  value: _number(_redeemed),
                  icon: Icons.redeem_outlined,
                  color: Colors.orange.shade800,
                ),
                _MetricCard(
                  label: 'Points expired',
                  value: _number(_expired),
                  icon: Icons.timer_off_outlined,
                  color: Colors.red.shade700,
                ),
                _MetricCard(
                  label: 'Net points',
                  value: _signed(_netPoints),
                  icon: Icons.account_balance_wallet_outlined,
                  color: _blue,
                ),
                _MetricCard(
                  label: 'Transactions',
                  value: _number(_filtered.length),
                  icon: Icons.receipt_long_outlined,
                  color: Colors.purple.shade700,
                ),
                _MetricCard(
                  label: 'Active users',
                  value: _number(_activeUsers),
                  icon: Icons.people_outline,
                  color: Colors.teal.shade700,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SectionHeader(
              title: 'Module breakdown',
              subtitle: '${_filtered.length} filtered transactions',
            ),
            const SizedBox(height: 10),
            _ModuleBreakdown(totals: _moduleTotals),
            const SizedBox(height: 22),
            const _SectionHeader(
              title: 'Transaction type breakdown',
              subtitle: 'Count by reward activity',
            ),
            const SizedBox(height: 10),
            _TypeBreakdown(totals: _typeTotals),
            const SizedBox(height: 22),
            _ReportSummary(
              earned: _earned,
              redeemed: _redeemed,
              expired: _expired,
              transactionCount: _filtered.length,
              activeUsers: _activeUsers,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportFilters extends StatelessWidget {
  final DateTimeRange dateRange;
  final RewardModule? module;
  final List<RewardModule> modules;
  final VoidCallback onRangePressed;
  final ValueChanged<int> onPresetPressed;
  final ValueChanged<RewardModule?> onModuleChanged;

  const _ReportFilters({
    required this.dateRange,
    required this.module,
    required this.modules,
    required this.onRangePressed,
    required this.onPresetPressed,
    required this.onModuleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report filters',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RewardModule?>(
              initialValue: module,
              decoration: const InputDecoration(labelText: 'Module'),
              items: [
                const DropdownMenuItem<RewardModule?>(
                  value: null,
                  child: Text('All modules'),
                ),
                ...modules.map(
                  (value) => DropdownMenuItem<RewardModule?>(
                    value: value,
                    child: Text(_label(value.name)),
                  ),
                ),
              ],
              onChanged: onModuleChanged,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range_outlined),
              title: Text('${_date(dateRange.start)} — ${_date(dateRange.end)}'),
              subtitle: Text('${dateRange.duration.inDays + 1} days'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onRangePressed,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('7 days'),
                  onPressed: () => onPresetPressed(7),
                ),
                ActionChip(
                  label: const Text('30 days'),
                  onPressed: () => onPresetPressed(30),
                ),
                ActionChip(
                  label: const Text('90 days'),
                  onPressed: () => onPresetPressed(90),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 7),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleTotal {
  final int earned;
  final int spent;
  final int transactions;

  const _ModuleTotal({
    this.earned = 0,
    this.spent = 0,
    this.transactions = 0,
  });
}

class _ModuleBreakdown extends StatelessWidget {
  final Map<RewardModule, _ModuleTotal> totals;
  const _ModuleBreakdown({required this.totals});

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) return const _EmptyReportCard();
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.transactions.compareTo(a.value.transactions));
    final maximum = entries
        .map((entry) => entry.value.transactions)
        .fold(1, (current, value) => value > current ? value : current);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: entries.map((entry) {
            final total = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _label(entry.key.name),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text('${total.transactions} transactions'),
                    ],
                  ),
                  const SizedBox(height: 7),
                  LinearProgressIndicator(
                    value: total.transactions / maximum,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '+${_number(total.earned)} earned  •  -${_number(total.spent)} spent',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TypeBreakdown extends StatelessWidget {
  final Map<RewardTransactionType, int> totals;
  const _TypeBreakdown({required this.totals});

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) return const _EmptyReportCard();
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final all = totals.values.fold(0, (total, value) => total + value);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: entries.map((entry) {
            final percentage = all == 0 ? 0.0 : (entry.value / all) * 100;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                child: Icon(Icons.bolt_outlined),
              ),
              title: Text(_label(entry.key.name)),
              subtitle: Text('${percentage.toStringAsFixed(1)}% of activity'),
              trailing: Text(
                '${entry.value}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ReportSummary extends StatelessWidget {
  final int earned;
  final int redeemed;
  final int expired;
  final int transactionCount;
  final int activeUsers;

  const _ReportSummary({
    required this.earned,
    required this.redeemed,
    required this.expired,
    required this.transactionCount,
    required this.activeUsers,
  });

  @override
  Widget build(BuildContext context) {
    final redemptionRate = earned == 0 ? 0.0 : (redeemed / earned) * 100;
    final expiryRate = earned == 0 ? 0.0 : (expired / earned) * 100;
    final average = activeUsers == 0 ? 0.0 : earned / activeUsers;
    return Card(
      color: const Color(0xFFEAF3FF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report summary',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _summaryRow('Redemption rate', '${redemptionRate.toStringAsFixed(1)}%'),
            _summaryRow('Expiry rate', '${expiryRate.toStringAsFixed(1)}%'),
            _summaryRow('Average earned per user', average.toStringAsFixed(1)),
            _summaryRow('Transactions per user', activeUsers == 0
                ? '0.0'
                : (transactionCount / activeUsers).toStringAsFixed(1)),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _EmptyReportCard extends StatelessWidget {
  const _EmptyReportCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.query_stats, size: 44, color: Colors.black26),
              SizedBox(height: 8),
              Text('No report data for selected filters'),
            ],
          ),
        ),
      ),
    );
  }
}

String _label(String value) {
  final spaced = value.replaceAllMapped(
    RegExp(r'([A-Z])'),
    (match) => ' ${match.group(1)}',
  );
  return spaced.isEmpty
      ? spaced
      : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

String _date(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String _number(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

String _signed(int value) => '${value > 0 ? '+' : ''}${_number(value)}';
