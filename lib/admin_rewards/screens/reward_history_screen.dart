import 'package:flutter/material.dart';

import '../../rewards/models/reward_point_model.dart';
import '../../rewards/models/reward_transaction_model.dart';

typedef RewardHistoryLoader = Future<List<RewardTransactionModel>> Function();
typedef RewardHistoryExportCallback = Future<void> Function(
  List<RewardTransactionModel> transactions,
);

class AdminRewardHistoryScreen extends StatefulWidget {
  final List<RewardTransactionModel> initialTransactions;
  final RewardHistoryLoader? onLoad;
  final RewardHistoryExportCallback? onExport;

  const AdminRewardHistoryScreen({
    super.key,
    this.initialTransactions = const [],
    this.onLoad,
    this.onExport,
  });

  @override
  State<AdminRewardHistoryScreen> createState() =>
      _AdminRewardHistoryScreenState();
}

class _AdminRewardHistoryScreenState
    extends State<AdminRewardHistoryScreen> {
  static const _navy = Color(0xFF09233F);
  static const _blue = Color(0xFF1264E5);
  static const _background = Color(0xFFF5F7FB);

  late List<RewardTransactionModel> _transactions;
  bool _loading = false;
  bool _exporting = false;
  String _query = '';
  RewardModule? _module;
  RewardTransactionType? _type;
  RewardTransactionStatus? _status;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _transactions = [...widget.initialTransactions];
    if (widget.onLoad != null) _load();
  }

  List<RewardTransactionModel> get _filtered {
    final query = _query.trim().toLowerCase();
    return _transactions.where((transaction) {
      if (_module != null &&
          transaction.module != _module &&
          transaction.module != RewardModule.all) {
        return false;
      }
      if (_type != null && transaction.type != _type) return false;
      if (_status != null && transaction.status != _status) return false;
      if (_dateRange != null) {
        final start = DateTime(
          _dateRange!.start.year,
          _dateRange!.start.month,
          _dateRange!.start.day,
        );
        final end = DateTime(
          _dateRange!.end.year,
          _dateRange!.end.month,
          _dateRange!.end.day,
          23,
          59,
          59,
          999,
        );
        if (transaction.createdAt.isBefore(start) ||
            transaction.createdAt.isAfter(end)) {
          return false;
        }
      }
      if (query.isEmpty) return true;
      return transaction.id.toLowerCase().contains(query) ||
          transaction.userId.toLowerCase().contains(query) ||
          (transaction.sourceId?.toLowerCase().contains(query) ?? false) ||
          transaction.title.toLowerCase().contains(query) ||
          transaction.description.toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int get _creditPoints => _filtered
      .where((item) => item.points > 0)
      .fold(0, (total, item) => total + item.points);

  int get _debitPoints => _filtered
      .where((item) => item.points < 0)
      .fold(0, (total, item) => total + item.points.abs());

  Future<void> _load() async {
    if (widget.onLoad == null || _loading) return;
    setState(() => _loading = true);
    try {
      final transactions = await widget.onLoad!.call();
      if (!mounted) return;
      setState(() => _transactions = transactions);
    } catch (error) {
      if (mounted) _message('History load failed: $error', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _export() async {
    if (widget.onExport == null) {
      _message('Export service will be connected with Admin backend.');
      return;
    }
    setState(() => _exporting = true);
    try {
      await widget.onExport!.call(_filtered);
      if (mounted) _message('Reward history export completed.');
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

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _dateRange,
    );
    if (selected != null) setState(() => _dateRange = selected);
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _module = null;
      _type = null;
      _status = null;
      _dateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Reward History'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Export filtered history',
            onPressed: _exporting ? null : _export,
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
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Transactions',
                    value: '${filtered.length}',
                    icon: Icons.receipt_long_outlined,
                    color: _blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: 'Credits',
                    value: '+$_creditPoints',
                    icon: Icons.add_circle_outline,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    title: 'Debits',
                    value: '-$_debitPoints',
                    icon: Icons.remove_circle_outline,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search user, transaction or source ID',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            _FilterPanel(
              module: _module,
              type: _type,
              status: _status,
              dateRange: _dateRange,
              onModuleChanged: (value) => setState(() => _module = value),
              onTypeChanged: (value) => setState(() => _type = value),
              onStatusChanged: (value) => setState(() => _status = value),
              onDatePressed: _selectDateRange,
              onClearDate: () => setState(() => _dateRange = null),
              onClearAll: _clearFilters,
            ),
            const SizedBox(height: 16),
            if (_loading && _transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              const _EmptyState()
            else
              ...filtered.map(
                (transaction) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TransactionCard(
                    transaction: transaction,
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (context) =>
                          _TransactionDetails(transaction: transaction),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final RewardModule? module;
  final RewardTransactionType? type;
  final RewardTransactionStatus? status;
  final DateTimeRange? dateRange;
  final ValueChanged<RewardModule?> onModuleChanged;
  final ValueChanged<RewardTransactionType?> onTypeChanged;
  final ValueChanged<RewardTransactionStatus?> onStatusChanged;
  final VoidCallback onDatePressed;
  final VoidCallback onClearDate;
  final VoidCallback onClearAll;

  const _FilterPanel({
    required this.module,
    required this.type,
    required this.status,
    required this.dateRange,
    required this.onModuleChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onDatePressed,
    required this.onClearDate,
    required this.onClearAll,
  });

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
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.filter_alt_outlined),
        title: const Text('Filters',
            style: TextStyle(fontWeight: FontWeight.w700)),
        trailing: TextButton(
          onPressed: onClearAll,
          child: const Text('Clear all'),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          DropdownButtonFormField<RewardModule?>(
            initialValue: module,
            decoration: const InputDecoration(labelText: 'Module'),
            items: [
              const DropdownMenuItem<RewardModule?>(
                  value: null, child: Text('All modules')),
              ..._modules.map(
                (value) => DropdownMenuItem<RewardModule?>(
                  value: value,
                  child: Text(_label(value.name)),
                ),
              ),
            ],
            onChanged: onModuleChanged,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<RewardTransactionType?>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Transaction type'),
            items: [
              const DropdownMenuItem<RewardTransactionType?>(
                  value: null, child: Text('All types')),
              ...RewardTransactionType.values.map(
                (value) => DropdownMenuItem<RewardTransactionType?>(
                  value: value,
                  child: Text(_label(value.name)),
                ),
              ),
            ],
            onChanged: onTypeChanged,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<RewardTransactionStatus?>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              const DropdownMenuItem<RewardTransactionStatus?>(
                  value: null, child: Text('All statuses')),
              ...RewardTransactionStatus.values.map(
                (value) => DropdownMenuItem<RewardTransactionStatus?>(
                  value: value,
                  child: Text(_label(value.name)),
                ),
              ),
            ],
            onChanged: onStatusChanged,
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.date_range_outlined),
            title: Text(
              dateRange == null
                  ? 'All dates'
                  : '${_date(dateRange!.start)} — ${_date(dateRange!.end)}',
            ),
            onTap: onDatePressed,
            trailing: dateRange == null
                ? const Icon(Icons.chevron_right)
                : IconButton(
                    onPressed: onClearDate,
                    icon: const Icon(Icons.close),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final RewardTransactionModel transaction;
  final VoidCallback onTap;

  const _TransactionCard({required this.transaction, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final credit = transaction.points > 0;
    final color = credit ? Colors.green.shade700 : Colors.red.shade700;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  credit ? Icons.add : Icons.remove,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title.isEmpty
                          ? _label(transaction.type.name)
                          : transaction.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'User: ${transaction.userId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_label(transaction.module.name)} • ${_label(transaction.status.name)} • ${_dateTime(transaction.createdAt)}',
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${credit ? '+' : ''}${transaction.points}',
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionDetails extends StatelessWidget {
  final RewardTransactionModel transaction;
  const _TransactionDetails({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transaction Details'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _row('Transaction ID', transaction.id),
              _row('User ID', transaction.userId),
              _row('Module', _label(transaction.module.name)),
              _row('Type', _label(transaction.type.name)),
              _row('Status', _label(transaction.status.name)),
              _row('Points', '${transaction.points}'),
              _row('Balance before', '${transaction.balanceBefore}'),
              _row('Balance after', '${transaction.balanceAfter}'),
              _row('Source ID', transaction.sourceId ?? '—'),
              _row('Reward rule ID', transaction.rewardRuleId ?? '—'),
              _row('Title', transaction.title),
              _row('Description',
                  transaction.description.isEmpty ? '—' : transaction.description),
              _row('Created', _dateTime(transaction.createdAt)),
              _row('Completed', transaction.completedAt == null
                  ? '—'
                  : _dateTime(transaction.completedAt!)),
              _row('Expires', transaction.expiresAt == null
                  ? 'Never'
                  : _dateTime(transaction.expiresAt!)),
              _row('Reversed transaction',
                  transaction.reversedTransactionId ?? '—'),
              _row('Idempotency key', transaction.idempotencyKey ?? '—'),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Text(title,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(Icons.history, size: 58, color: Colors.black26),
          SizedBox(height: 12),
          Text(
            'No reward transactions found',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ],
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

String _dateTime(DateTime value) {
  return '${_date(value)} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
