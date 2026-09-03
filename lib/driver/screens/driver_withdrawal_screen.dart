import 'package:flutter/material.dart';

import '../services/driver_settlement_service.dart';

class DriverWithdrawalScreen extends StatefulWidget {
  const DriverWithdrawalScreen({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  final String driverId;
  final String driverName;

  @override
  State<DriverWithdrawalScreen> createState() =>
      _DriverWithdrawalScreenState();
}

class _DriverWithdrawalScreenState extends State<DriverWithdrawalScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color darkCard = Color(0xFF1A1A1A);

  final DriverSettlementService _service = DriverSettlementService();
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text(
          'Wallet & Withdrawals',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DriverSettlementSummary>(
        stream: _service.watchSettlementSummary(widget.driverId),
        builder: (context, summarySnapshot) {
          if (summarySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: yellow),
            );
          }
          if (summarySnapshot.hasError) {
            return _messageView(
              icon: Icons.cloud_off,
              title: 'Wallet could not be loaded',
              subtitle: _cleanError(summarySnapshot.error!),
            );
          }

          final DriverSettlementSummary summary = summarySnapshot.data ??
              const DriverSettlementSummary.empty();

          return StreamBuilder<List<DriverWithdrawalRequest>>(
            stream: _service.watchRequests(widget.driverId),
            builder: (context, requestsSnapshot) {
              final List<DriverWithdrawalRequest> requests =
                  requestsSnapshot.data ?? const <DriverWithdrawalRequest>[];
              final bool hasPending = requests.any(
                (request) =>
                    request.status == DriverWithdrawalStatus.pending ||
                    request.status == DriverWithdrawalStatus.approved ||
                    request.status == DriverWithdrawalStatus.processing,
              );

              return SafeArea(
                top: false,
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _walletCard(summary),
                            const SizedBox(height: 14),
                            _balanceDetails(summary),
                            const SizedBox(height: 14),
                            _withdrawButton(
                              summary: summary,
                              hasPending: hasPending,
                            ),
                            const SizedBox(height: 12),
                            _testingNotice(),
                            const SizedBox(height: 22),
                            const Text(
                              'Withdrawal history',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 11),
                          ],
                        ),
                      ),
                    ),
                    if (requestsSnapshot.connectionState ==
                        ConnectionState.waiting)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(color: yellow),
                        ),
                      )
                    else if (requestsSnapshot.hasError)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _messageView(
                          icon: Icons.error_outline,
                          title: 'History could not be loaded',
                          subtitle: _cleanError(requestsSnapshot.error!),
                        ),
                      )
                    else if (requests.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _messageView(
                          icon: Icons.receipt_long_outlined,
                          title: 'No withdrawal requests',
                          subtitle: 'Your requests and Admin decisions will appear here.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                        sliver: SliverList.separated(
                          itemCount: requests.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 11),
                          itemBuilder: (_, index) =>
                              _requestCard(requests[index]),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _walletCard(DriverSettlementSummary summary) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF30290B), Color(0xFF171717)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: yellow.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: yellow),
              const SizedBox(width: 9),
              const Text(
                'Available balance',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Rs ${_money(summary.availableBalance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            summary.pendingWithdrawalAmount > 0
                ? 'Rs ${_money(summary.pendingWithdrawalAmount)} is reserved for a pending request.'
                : 'Net online earnings and wallet top-ups appear here.',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _balanceDetails(DriverSettlementSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _detailTile(
            label: 'Wallet balance',
            value: 'Rs ${_money(summary.walletBalance)}',
            color: Colors.lightBlueAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _detailTile(
            label: 'Commission due',
            value: 'Rs ${_money(summary.outstandingCommission)}',
            color: summary.outstandingCommission > 0
                ? Colors.orangeAccent
                : Colors.greenAccent,
          ),
        ),
      ],
    );
  }

  Widget _detailTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _withdrawButton({
    required DriverSettlementSummary summary,
    required bool hasPending,
  }) {
    final bool hasCommission = summary.outstandingCommission > 0;
    final bool hasMinimum = summary.availableBalance >=
        DriverSettlementService.minimumWithdrawalAmount;
    final bool enabled = !hasPending && !hasCommission && hasMinimum;

    String label = 'REQUEST WITHDRAWAL';
    if (hasPending) label = 'REQUEST ALREADY PENDING';
    if (hasCommission) label = 'SETTLE COMMISSION FIRST';
    if (!hasMinimum && !hasPending && !hasCommission) {
      label = 'MINIMUM RS ${DriverSettlementService.minimumWithdrawalAmount.toStringAsFixed(0)}';
    }

    return SizedBox(
      height: 55,
      child: ElevatedButton.icon(
        onPressed: enabled ? () => _openWithdrawalForm(summary) : null,
        icon: const Icon(Icons.payments_outlined),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: yellow,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white12,
          disabledForegroundColor: Colors.white38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _testingNotice() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.24)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: Colors.orangeAccent, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Testing payout bypass is active. Requests remain pending for Admin approval; no real money is transferred.',
              style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestCard(DriverWithdrawalRequest request) {
    final Color color = _statusColor(request.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _titleCase(request.status.name),
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(request.createdAt),
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rs ${_money(request.amount)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_payoutLabel(request.payoutMethod)} • ${_masked(request.accountNumber)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (request.status == DriverWithdrawalStatus.pending)
                TextButton(
                  onPressed: _isCancelling
                      ? null
                      : () => _confirmCancel(request),
                  child: const Text('Cancel'),
                ),
            ],
          ),
          if ((request.adminNote ?? '').trim().isNotEmpty) ...[
            const Divider(color: Colors.white10, height: 22),
            Text(
              'Admin: ${request.adminNote}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openWithdrawalForm(
    DriverSettlementSummary summary,
  ) async {
    final bool? submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WithdrawalFormSheet(
        service: _service,
        driverId: widget.driverId,
        driverName: widget.driverName,
        maximumAmount: summary.availableBalance,
      ),
    );
    if (!mounted || submitted != true) return;
    _showMessage('Withdrawal request submitted for Admin approval.', Colors.green);
  }

  Future<void> _confirmCancel(DriverWithdrawalRequest request) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: darkCard,
            title: const Text('Cancel request?',
                style: TextStyle(color: Colors.white)),
            content: const Text(
              'The reserved amount will return to your available wallet balance.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Keep'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Cancel request'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    setState(() => _isCancelling = true);
    try {
      await _service.cancelPendingRequest(
        requestId: request.requestId,
        driverId: widget.driverId,
      );
      if (mounted) _showMessage('Withdrawal request cancelled.', Colors.green);
    } catch (error) {
      if (mounted) _showMessage(_cleanError(error), Colors.red);
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  Widget _messageView({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: yellow, size: 47),
            const SizedBox(height: 13),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 7),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(backgroundColor: color, content: Text(message)));
  }

  Color _statusColor(DriverWithdrawalStatus status) {
    switch (status) {
      case DriverWithdrawalStatus.paid:
        return Colors.greenAccent;
      case DriverWithdrawalStatus.rejected:
      case DriverWithdrawalStatus.failed:
      case DriverWithdrawalStatus.cancelled:
        return Colors.redAccent;
      case DriverWithdrawalStatus.approved:
      case DriverWithdrawalStatus.processing:
        return Colors.lightBlueAccent;
      case DriverWithdrawalStatus.pending:
        return Colors.orangeAccent;
    }
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
  String _money(double value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  String _titleCase(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
  String _payoutLabel(DriverPayoutMethod method) {
    if (method == DriverPayoutMethod.jazzCash) return 'JazzCash';
    if (method == DriverPayoutMethod.easypaisa) return 'Easypaisa';
    return 'Bank';
  }
  String _masked(String value) {
    if (value.length <= 4) return value;
    return '•••• ${value.substring(value.length - 4)}';
  }
  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _WithdrawalFormSheet extends StatefulWidget {
  const _WithdrawalFormSheet({
    required this.service,
    required this.driverId,
    required this.driverName,
    required this.maximumAmount,
  });

  final DriverSettlementService service;
  final String driverId;
  final String driverName;
  final double maximumAmount;

  @override
  State<_WithdrawalFormSheet> createState() => _WithdrawalFormSheetState();
}

class _WithdrawalFormSheetState extends State<_WithdrawalFormSheet> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _number = TextEditingController();
  final TextEditingController _bank = TextEditingController();
  DriverPayoutMethod _method = DriverPayoutMethod.jazzCash;
  bool _submitting = false;

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _number.dispose();
    _bank.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 11, 18, 25),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 43,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Request withdrawal',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text('Available: Rs ${widget.maximumAmount.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 18),
                DropdownButtonFormField<DriverPayoutMethod>(
                  initialValue: _method,
                  dropdownColor: darkCard,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('Payout method', Icons.payments_outlined),
                  items: const [
                    DropdownMenuItem(
                        value: DriverPayoutMethod.jazzCash,
                        child: Text('JazzCash')),
                    DropdownMenuItem(
                        value: DriverPayoutMethod.easypaisa,
                        child: Text('Easypaisa')),
                    DropdownMenuItem(
                        value: DriverPayoutMethod.bank,
                        child: Text('Bank account')),
                  ],
                  onChanged: (value) =>
                      setState(() => _method = value ?? _method),
                ),
                const SizedBox(height: 12),
                if (_method == DriverPayoutMethod.bank) ...[
                  TextFormField(
                    controller: _bank,
                    style: const TextStyle(color: Colors.white),
                    decoration: _decoration('Bank name', Icons.account_balance),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Bank name is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _title,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('Account title', Icons.person_outline),
                  validator: (value) => (value ?? '').trim().length < 3
                      ? 'Enter valid account title'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _number,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: _decoration(
                    _method == DriverPayoutMethod.bank
                        ? 'Account / IBAN number'
                        : 'Mobile account number',
                    Icons.numbers,
                  ),
                  validator: (value) => (value ?? '').trim().length < 8
                      ? 'Enter valid account number'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amount,
                  style: const TextStyle(color: Colors.white),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoration('Amount (Rs)', Icons.currency_rupee),
                  validator: (value) {
                    final double? amount = double.tryParse((value ?? '').trim());
                    if (amount == null) return 'Enter valid amount';
                    if (amount < DriverSettlementService.minimumWithdrawalAmount) {
                      return 'Minimum Rs ${DriverSettlementService.minimumWithdrawalAmount.toStringAsFixed(0)}';
                    }
                    if (amount > widget.maximumAmount) {
                      return 'Amount exceeds available balance';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 9),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _amount.text = widget.maximumAmount.toStringAsFixed(0);
                    },
                    child: const Text('Use full balance'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yellow,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.black),
                          )
                        : const Text('SUBMIT REQUEST',
                            style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: yellow),
      filled: true,
      fillColor: darkCard,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: yellow),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await widget.service.requestWithdrawal(
        driverId: widget.driverId,
        driverName: widget.driverName,
        amount: double.parse(_amount.text.trim()),
        payoutMethod: _method,
        accountTitle: _title.text,
        accountNumber: _number.text,
        bankName: _bank.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
