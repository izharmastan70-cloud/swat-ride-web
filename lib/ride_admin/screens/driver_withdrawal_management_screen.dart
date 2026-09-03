import 'package:flutter/material.dart';

import '../services/ride_admin_service.dart';

class DriverWithdrawalManagementScreen extends StatefulWidget {
  const DriverWithdrawalManagementScreen({
    super.key,
    this.adminId = 'testing_admin',
  });

  final String adminId;

  @override
  State<DriverWithdrawalManagementScreen> createState() =>
      _DriverWithdrawalManagementScreenState();
}

class _DriverWithdrawalManagementScreenState
    extends State<DriverWithdrawalManagementScreen> {
  static const Color _yellow = Color(0xFFFFD400);
  static const Color _background = Color(0xFF090909);
  static const Color _card = Color(0xFF191919);
  static const List<String> _filters = <String>[
    'all',
    'pending',
    'approved',
    'processing',
    'paid',
    'rejected',
    'failed',
  ];

  final RideAdminService _service = RideAdminService();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _busyRequests = <String>{};
  String _filter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Driver Withdrawals',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildControls(),
            Expanded(
              child: StreamBuilder<List<RideAdminRecord>>(
                stream: _service.watchWithdrawals(status: _filter),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _MessageState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Withdrawals could not be loaded',
                      message: _cleanError(snapshot.error),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: _yellow),
                    );
                  }
                  final List<RideAdminRecord> records =
                      _filterRecords(snapshot.data ?? <RideAdminRecord>[]);
                  if (records.isEmpty) {
                    return const _MessageState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No withdrawal requests',
                      message: 'No requests match the selected filter or search.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildRequestCard(records[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 15),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _yellow.withValues(alpha: 0.1),
              border: Border.all(color: _yellow.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.science_outlined, color: _yellow),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Testing payout bypass is active. Status and wallet settlement can be tested, but no real bank, JazzCash or Easypaisa transfer is sent.',
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search driver, request ID or account',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search_rounded, color: _yellow),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
              filled: true,
              fillColor: _card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters
                  .map((value) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_title(value)),
                          selected: _filter == value,
                          onSelected: (_) => setState(() => _filter = value),
                          selectedColor: _yellow,
                          backgroundColor: _card,
                          side: BorderSide(
                            color: _filter == value ? _yellow : Colors.white24,
                          ),
                          labelStyle: TextStyle(
                            color: _filter == value ? Colors.black : Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                          showCheckmark: false,
                        ),
                      ))
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }

  List<RideAdminRecord> _filterRecords(List<RideAdminRecord> source) {
    final String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return source;
    return source.where((record) {
      final Map<String, dynamic> account = record.map('accountDetails');
      return <String>[
        record.id,
        record.text('requestId'),
        record.text('driverId'),
        record.text('driverName'),
        record.text('phoneNumber'),
        record.text('accountTitle'),
        record.text('accountNumber'),
        account['accountTitle']?.toString() ?? '',
        account['accountNumber']?.toString() ?? '',
      ].join(' ').toLowerCase().contains(query);
    }).toList(growable: false);
  }

  Widget _buildRequestCard(RideAdminRecord record) {
    final String status = record.text('status', fallback: 'pending');
    final bool busy = _busyRequests.contains(record.id);
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: busy ? null : () => _showDetails(record),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _yellow.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: busy
                        ? const Padding(
                            padding: EdgeInsets.all(13),
                            child: CircularProgressIndicator(color: _yellow, strokeWidth: 2),
                          )
                        : const Icon(Icons.account_balance_wallet_outlined, color: _yellow),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          record.text('driverName', fallback: 'SWAT RIDE Driver'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'ID: ${record.text('driverId', fallback: 'Not available')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(child: _summary('Amount', 'Rs ${record.number('amount').toStringAsFixed(0)}')),
                  Expanded(child: _summary('Method', _title(record.text('method', fallback: record.text('paymentMethod', fallback: 'bank'))))),
                  _summary('Requested', _date(record.createdAt), alignEnd: true),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '#${record.text('requestId', fallback: record.id)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                  const Text('View details', style: TextStyle(color: _yellow, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: _yellow),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary(String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Future<void> _showDetails(RideAdminRecord record) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final String status = record.text('status', fallback: 'pending');
        final Map<String, dynamic> account = record.map('accountDetails');
        final String accountTitle = _first(<String>[
          record.text('accountTitle'),
          account['accountTitle']?.toString() ?? '',
        ], 'Not available');
        final String accountNumber = _first(<String>[
          record.text('accountNumber'),
          account['accountNumber']?.toString() ?? '',
          account['iban']?.toString() ?? '',
        ], 'Not available');
        final String method = _title(record.text('method', fallback: record.text('paymentMethod', fallback: 'bank')));
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.6,
          maxChildSize: 0.96,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF151515),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: <Widget>[
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text('Withdrawal details', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                    ),
                    _StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _yellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: <Widget>[
                      const Text('Requested amount', style: TextStyle(color: Colors.white60)),
                      const SizedBox(height: 7),
                      Text(
                        'Rs ${record.number('amount').toStringAsFixed(0)}',
                        style: const TextStyle(color: _yellow, fontSize: 30, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _section('Driver', <Widget>[
                  _detail('Name', record.text('driverName', fallback: 'Not available')),
                  _detail('Driver ID', record.text('driverId', fallback: 'Not available')),
                  _detail('Phone', record.text('phoneNumber', fallback: record.text('phone', fallback: 'Not available'))),
                ]),
                _section('Payout account', <Widget>[
                  _detail('Method', method),
                  _detail('Account title', accountTitle),
                  _detail('Account / IBAN', accountNumber),
                  _detail('Bank / Provider', _first(<String>[
                    record.text('bankName'),
                    account['bankName']?.toString() ?? '',
                    account['provider']?.toString() ?? '',
                  ], method)),
                ]),
                _section('Request activity', <Widget>[
                  _detail('Request ID', record.text('requestId', fallback: record.id)),
                  _detail('Created', _dateTime(record.createdAt)),
                  _detail('Updated', _dateTime(record.updatedAt)),
                  if (record.text('adminNote').isNotEmpty)
                    _detail('Admin note', record.text('adminNote')),
                ]),
                const SizedBox(height: 4),
                _buildActions(sheetContext, record, status),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(color: _yellow, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 115, child: Text(label, style: const TextStyle(color: Colors.white54))),
          Expanded(
            child: SelectableText(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext sheetContext, RideAdminRecord record, String status) {
    if (status == 'paid') {
      return const _FinalStateNotice(
        icon: Icons.verified_rounded,
        color: Colors.green,
        text: 'This request is already marked paid and cannot be paid twice.',
      );
    }
    if (status == 'rejected') {
      return const _FinalStateNotice(
        icon: Icons.cancel_rounded,
        color: Colors.redAccent,
        text: 'This withdrawal request was rejected.',
      );
    }
    return Column(
      children: <Widget>[
        if (status == 'pending')
          _actionButton(
            label: 'Approve Request',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            onPressed: () => _confirmStatus(sheetContext, record, 'approved'),
          ),
        if (status == 'approved')
          _actionButton(
            label: 'Move to Processing',
            icon: Icons.sync_rounded,
            color: Colors.lightBlueAccent,
            onPressed: () => _confirmStatus(sheetContext, record, 'processing'),
          ),
        if (status == 'processing' || status == 'approved')
          _actionButton(
            label: 'Mark Paid (Testing Bypass)',
            icon: Icons.verified_outlined,
            color: _yellow,
            onPressed: () => _confirmStatus(sheetContext, record, 'paid'),
          ),
        if (status != 'paid')
          _actionButton(
            label: 'Reject Request',
            icon: Icons.block_rounded,
            color: Colors.redAccent,
            onPressed: () => _confirmStatus(sheetContext, record, 'rejected', requireNote: true),
          ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmStatus(
    BuildContext sheetContext,
    RideAdminRecord record,
    String nextStatus, {
    bool requireNote = false,
  }) async {
    final TextEditingController noteController = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: sheetContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: Text('${_title(nextStatus)} withdrawal?', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              nextStatus == 'paid'
                  ? 'Testing bypass will update the status and wallet settlement only. No real payout will be sent.'
                  : 'Confirm this admin action for the withdrawal request.',
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              minLines: 2,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: requireNote ? 'Reason (required)' : 'Admin note (optional)',
                labelStyle: const TextStyle(color: Colors.white60),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: _yellow)),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Back')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: nextStatus == 'rejected' ? Colors.redAccent : _yellow,
              foregroundColor: nextStatus == 'rejected' ? Colors.white : Colors.black,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    final String note = noteController.text.trim();
    noteController.dispose();
    if (confirmed != true) return;
    if (requireNote && note.length < 5) {
      if (mounted) _showMessage('Please enter a clear rejection reason.');
      return;
    }
    if (sheetContext.mounted) Navigator.pop(sheetContext);
    setState(() => _busyRequests.add(record.id));
    try {
      await _service.reviewWithdrawal(
        requestId: record.id,
        reviewedBy: widget.adminId,
        nextStatus: nextStatus,
        adminNote: note.isEmpty ? null : note,
      );
      if (!mounted) return;
      _showMessage('Withdrawal marked ${_title(nextStatus)}.', success: true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_cleanError(error));
    } finally {
      if (mounted) setState(() => _busyRequests.remove(record.id));
    }
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: success ? Colors.green : Colors.redAccent, content: Text(message)),
    );
  }

  static String _first(List<String> values, String fallback) {
    for (final String value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return fallback;
  }

  static String _title(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  static String _date(DateTime value) {
    if (value.year <= 2000) return 'N/A';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }

  static String _dateTime(DateTime value) {
    if (value.year <= 2000) return 'Not available';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} ${two(value.hour)}:${two(value.minute)}';
  }

  static String _cleanError(Object? error) =>
      error.toString().replaceFirst('Exception: ', '').trim();
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status.toLowerCase()) {
      'approved' => Colors.lightBlueAccent,
      'processing' => Colors.orangeAccent,
      'paid' => Colors.green,
      'rejected' || 'failed' => Colors.redAccent,
      _ => const Color(0xFFFFD400),
    };
    final String label = status
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}

class _FinalStateNotice extends StatelessWidget {
  const _FinalStateNotice({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, height: 1.35))),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

