import 'package:flutter/material.dart';

import '../models/reward_point_model.dart';

enum CashbackHistoryStatus {
  pending,
  completed,
  expired,
  reversed,
  cancelled,
  failed,
}

enum CashbackHistoryDestination {
  rewardWallet,
  paymentWallet,
}

class CashbackHistoryItem {
  const CashbackHistoryItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.module,
    required this.status,
    required this.destination,
    required this.createdAt,
    this.bookingId,
    this.description = '',
    this.rewardPoints = 0,
    this.availableAt,
    this.expiresAt,
    this.metadata = const {},
  });

  final String id;
  final String title;
  final String description;
  final double amount;
  final int rewardPoints;
  final RewardModule module;
  final CashbackHistoryStatus status;
  final CashbackHistoryDestination destination;
  final String? bookingId;
  final DateTime createdAt;
  final DateTime? availableAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  bool get isCredit =>
      status == CashbackHistoryStatus.completed ||
      status == CashbackHistoryStatus.pending;

  factory CashbackHistoryItem.fromMap(Map<String, dynamic> map) {
    return CashbackHistoryItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Cashback',
      description: map['description']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ??
          (map['cashbackAmount'] as num?)?.toDouble() ??
          0,
      rewardPoints: (map['rewardPoints'] as num?)?.toInt() ?? 0,
      module: _enumValue(
        RewardModule.values,
        map['module']?.toString(),
        RewardModule.all,
      ),
      status: _enumValue(
        CashbackHistoryStatus.values,
        map['status']?.toString(),
        CashbackHistoryStatus.pending,
      ),
      destination: _enumValue(
        CashbackHistoryDestination.values,
        map['destination']?.toString(),
        CashbackHistoryDestination.rewardWallet,
      ),
      bookingId: map['bookingId']?.toString() ?? map['sourceId']?.toString(),
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      availableAt: _date(map['availableAt']),
      expiresAt: _date(map['expiresAt']),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'amount': amount,
        'rewardPoints': rewardPoints,
        'module': module.name,
        'status': status.name,
        'destination': destination.name,
        'bookingId': bookingId,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'availableAt': availableAt?.millisecondsSinceEpoch,
        'expiresAt': expiresAt?.millisecondsSinceEpoch,
        'metadata': metadata,
      };

  static T _enumValue<T extends Enum>(
    List<T> values,
    String? value,
    T fallback,
  ) {
    final normalized = value?.split('.').last;
    for (final item in values) {
      if (item.name == normalized) return item;
    }
    return fallback;
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return DateTime.tryParse(value.toString());
  }
}

typedef CashbackHistoryLoader = Future<List<CashbackHistoryItem>> Function(
  String userId,
);

/// Read-only user cashback history.
///
/// Pass [historyLoader] while connecting the screen to CashbackService.
/// Until final integration, the screen safely shows an empty state.
class CashbackHistoryScreen extends StatefulWidget {
  const CashbackHistoryScreen({
    super.key,
    required this.userId,
    this.historyLoader,
    this.initialItems = const [],
  });

  final String userId;
  final CashbackHistoryLoader? historyLoader;
  final List<CashbackHistoryItem> initialItems;

  @override
  State<CashbackHistoryScreen> createState() =>
      _CashbackHistoryScreenState();
}

class _CashbackHistoryScreenState extends State<CashbackHistoryScreen> {
  List<CashbackHistoryItem> _items = const [];
  CashbackHistoryStatus? _filter;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final loader = widget.historyLoader;
      final loaded = loader == null
          ? List<CashbackHistoryItem>.from(widget.initialItems)
          : await loader(widget.userId);
      loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() => _items = loaded);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CashbackHistoryItem> get _filteredItems {
    final filter = _filter;
    if (filter == null) return _items;
    return _items.where((item) => item.status == filter).toList();
  }

  double get _completedTotal => _items
      .where((item) => item.status == CashbackHistoryStatus.completed)
      .fold(0, (total, item) => total + item.amount);

  double get _pendingTotal => _items
      .where((item) => item.status == CashbackHistoryStatus.pending)
      .fold(0, (total, item) => total + item.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashback History'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadHistory,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _items.isEmpty) {
      return const _FullPageMessage(
        icon: Icons.hourglass_top_rounded,
        title: 'Loading cashback history...',
        showProgress: true,
      );
    }

    if (_error != null && _items.isEmpty) {
      return _FullPageMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Cashback history could not be loaded',
        subtitle: 'Please check your connection and try again.',
        action: FilledButton.icon(
          onPressed: _loadHistory,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          sliver: SliverToBoxAdapter(
            child: _SummaryCard(
              completed: _completedTotal,
              pending: _pendingTotal,
              transactions: _items.length,
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildFilters()),
        if (_filteredItems.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyHistory(hasFilter: _filter != null),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList.separated(
              itemCount: _filteredItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _CashbackCard(
                item: _filteredItems[index],
                onTap: () => _showDetails(_filteredItems[index]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilters() {
    const filters = <CashbackHistoryStatus>[
      CashbackHistoryStatus.pending,
      CashbackHistoryStatus.completed,
      CashbackHistoryStatus.expired,
      CashbackHistoryStatus.reversed,
    ];

    return SizedBox(
      height: 52,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _filter == null,
            onSelected: (_) => setState(() => _filter = null),
          ),
          const SizedBox(width: 8),
          for (final status in filters) ...[
            ChoiceChip(
              label: Text(_title(status.name)),
              selected: _filter == status,
              onSelected: (_) => setState(() => _filter = status),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  void _showDetails(CashbackHistoryItem item) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _DetailRow(label: 'Status', value: _title(item.status.name)),
              _DetailRow(label: 'Cashback', value: '${_money(item.amount)} PKR'),
              if (item.rewardPoints > 0)
                _DetailRow(label: 'Reward points', value: '${item.rewardPoints}'),
              _DetailRow(label: 'Module', value: _title(item.module.name)),
              _DetailRow(label: 'Destination', value: _destination(item.destination)),
              _DetailRow(label: 'Created', value: _dateTime(item.createdAt)),
              if (item.availableAt != null)
                _DetailRow(label: 'Available', value: _dateTime(item.availableAt!)),
              if (item.expiresAt != null)
                _DetailRow(label: 'Expires', value: _dateTime(item.expiresAt!)),
              if (item.bookingId != null && item.bookingId!.isNotEmpty)
                _DetailRow(label: 'Booking / Order ID', value: item.bookingId!),
              _DetailRow(label: 'Transaction ID', value: item.id),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(item.description),
              ],
              const SizedBox(height: 16),
              const Text(
                'Cashback rules, limits, status and expiry are controlled by Admin.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.completed, required this.pending, required this.transactions});
  final double completed;
  final double pending;
  final int transactions;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.savings_rounded),
                SizedBox(width: 8),
                Text('Cashback summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _SummaryValue(label: 'Received', value: '${_money(completed)} PKR', color: Colors.green)),
                Expanded(child: _SummaryValue(label: 'Pending', value: '${_money(pending)} PKR', color: Colors.orange)),
                Expanded(child: _SummaryValue(label: 'Records', value: '$transactions')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CashbackCard extends StatelessWidget {
  const _CashbackCard({required this.item, required this.onTap});
  final CashbackHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(_statusIcon(item.status), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${_title(item.module.name)} â€¢ ${_dateTime(item.createdAt)}', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 5),
                    Text(_title(item.status.name), style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${item.isCredit ? '+' : '-'}${_money(item.amount)}', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                  Text(item.destination == CashbackHistoryDestination.rewardWallet ? 'Rewards' : 'Wallet', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.hasFilter});
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.savings_outlined, size: 64),
            const SizedBox(height: 12),
            Text(hasFilter ? 'No cashback with this status' : 'No cashback yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(hasFilter ? 'Choose another filter to view your records.' : 'Eligible cashback will appear here after your booking or order.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _FullPageMessage extends StatelessWidget {
  const _FullPageMessage({required this.icon, required this.title, this.subtitle, this.action, this.showProgress = false});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showProgress) const CircularProgressIndicator() else Icon(icon, size: 58),
                    const SizedBox(height: 14),
                    Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                    if (subtitle != null) ...[const SizedBox(height: 6), Text(subtitle!, textAlign: TextAlign.center)],
                    if (action != null) ...[const SizedBox(height: 16), action!],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

Color _statusColor(CashbackHistoryStatus status) {
  switch (status) {
    case CashbackHistoryStatus.completed:
      return Colors.green;
    case CashbackHistoryStatus.pending:
      return Colors.orange;
    case CashbackHistoryStatus.expired:
      return Colors.grey;
    case CashbackHistoryStatus.reversed:
      return Colors.deepOrange;
    case CashbackHistoryStatus.cancelled:
    case CashbackHistoryStatus.failed:
      return Colors.red;
  }
}

IconData _statusIcon(CashbackHistoryStatus status) {
  switch (status) {
    case CashbackHistoryStatus.completed:
      return Icons.check_rounded;
    case CashbackHistoryStatus.pending:
      return Icons.schedule_rounded;
    case CashbackHistoryStatus.expired:
      return Icons.timer_off_rounded;
    case CashbackHistoryStatus.reversed:
      return Icons.undo_rounded;
    case CashbackHistoryStatus.cancelled:
      return Icons.cancel_rounded;
    case CashbackHistoryStatus.failed:
      return Icons.error_rounded;
  }
}

String _destination(CashbackHistoryDestination destination) {
  return destination == CashbackHistoryDestination.rewardWallet
      ? 'Reward wallet'
      : 'Payment wallet';
}

String _money(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}

String _title(String value) {
  final spaced = value.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  return spaced.isEmpty ? '' : spaced[0].toUpperCase() + spaced.substring(1);
}

String _dateTime(DateTime date) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} '
      '${two(date.hour)}:${two(date.minute)}';
}

