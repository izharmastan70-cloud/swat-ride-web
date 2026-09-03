import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/reward_point_model.dart';
import '../models/reward_settings_model.dart';
import '../models/reward_transaction_model.dart';
import '../models/reward_wallet_model.dart';
import '../services/reward_service.dart';

/// Booking-checkout reward redemption screen.
/// Points are redeemed only after an explicit confirmation dialog.
class RedeemRewardScreen extends StatefulWidget {
  const RedeemRewardScreen({
    super.key,
    required this.userId,
    required this.module,
    required this.sourceId,
    required this.eligibleAmount,
    this.redeemedToday = 0,
    this.redeemedThisMonth = 0,
    this.redeemedThisYear = 0,
    this.rewardService,
    this.onRedeemed,
  });

  final String userId;
  final RewardModule module;
  final String sourceId;
  final double eligibleAmount;
  final int redeemedToday;
  final int redeemedThisMonth;
  final int redeemedThisYear;
  final RewardService? rewardService;
  final ValueChanged<RewardTransactionModel>? onRedeemed;

  @override
  State<RedeemRewardScreen> createState() => _RedeemRewardScreenState();
}

class _RedeemRewardScreenState extends State<RedeemRewardScreen> {
  static const Color _navy = Color(0xFF09233F);
  static const Color _background = Color(0xFFF5F7FB);

  late final RewardService _service;
  final TextEditingController _pointsController = TextEditingController();

  RewardWalletModel? _wallet;
  RewardSettingsModel? _settings;
  bool _isLoading = true;
  bool _isRedeeming = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.rewardService ?? RewardService();
    _loadData();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  int get _selectedPoints => int.tryParse(_pointsController.text.trim()) ?? 0;

  int get _maximumUsablePoints {
    final wallet = _wallet;
    final settings = _settings;
    if (wallet == null || settings == null || settings.pkrValuePerPoint <= 0) {
      return 0;
    }

    var maximum = wallet.availablePoints;
    final bookingCashLimit = widget.eligibleAmount *
        (settings.maximumRedeemPercentage / 100);
    final bookingPointLimit =
        (bookingCashLimit / settings.pkrValuePerPoint).floor();
    if (maximum > bookingPointLimit) maximum = bookingPointLimit;

    final perBooking = settings.maximumRedeemPointsPerBooking;
    if (perBooking != null && maximum > perBooking) maximum = perBooking;

    final daily = settings.dailyRedeemPointsLimit;
    if (daily != null) {
      final remaining = daily - widget.redeemedToday;
      if (maximum > remaining) maximum = remaining;
    }
    final monthly = settings.monthlyRedeemPointsLimit;
    if (monthly != null) {
      final remaining = monthly - widget.redeemedThisMonth;
      if (maximum > remaining) maximum = remaining;
    }
    final yearly = settings.yearlyRedeemPointsLimit;
    if (yearly != null) {
      final remaining = yearly - widget.redeemedThisYear;
      if (maximum > remaining) maximum = remaining;
    }
    return maximum < 0 ? 0 : maximum;
  }

  double get _discountValue {
    final settings = _settings;
    if (settings == null) return 0;
    final value = _selectedPoints * settings.pkrValuePerPoint;
    return value > widget.eligibleAmount ? widget.eligibleAmount : value;
  }

  Future<void> _loadData() async {
    if (widget.userId.trim().isEmpty || widget.sourceId.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User ID and booking/order source ID are required.';
      });
      return;
    }
    if (widget.eligibleAmount <= 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Eligible booking amount must be greater than zero.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _service.getWallet(widget.userId),
        _service.getSettings(),
      ]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as RewardWalletModel;
        _settings = results[1] as RewardSettingsModel;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String? _validationMessage() {
    final wallet = _wallet;
    final settings = _settings;
    if (wallet == null || settings == null) return 'Reward data is unavailable.';
    if (!settings.isRewardEnabledForModule(widget.module)) {
      return 'Reward redemption is disabled by Admin for this service.';
    }
    if (!wallet.isActive) return 'Your reward wallet is inactive.';
    if (wallet.isFrozen) return 'Your reward wallet is temporarily frozen.';
    if (_selectedPoints <= 0) return 'Enter reward points to redeem.';
    if (_selectedPoints < settings.minimumRedeemPoints) {
      return 'Minimum redemption is ${settings.minimumRedeemPoints} points.';
    }
    if (_selectedPoints > _maximumUsablePoints) {
      return 'You can use up to $_maximumUsablePoints points on this booking.';
    }
    final allowed = settings.canRedeemPoints(
      module: widget.module,
      requestedPoints: _selectedPoints,
      availablePoints: wallet.availablePoints,
      redeemedToday: widget.redeemedToday,
      redeemedThisMonth: widget.redeemedThisMonth,
      redeemedThisYear: widget.redeemedThisYear,
    );
    return allowed ? null : 'These points cannot be redeemed under current Admin limits.';
  }

  Future<void> _confirmAndRedeem() async {
    FocusScope.of(context).unfocus();
    final validation = _validationMessage();
    if (validation != null) {
      _showMessage(validation);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm redemption'),
        content: Text(
          'Redeem $_selectedPoints points for PKR ${_money(_discountValue)} on this booking?\n\n'
          'This action will update your reward balance.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isRedeeming = true);
    try {
      final transaction = await _service.redeemPoints(
        userId: widget.userId,
        module: widget.module,
        points: _selectedPoints,
        sourceId: widget.sourceId,
        idempotencyKey:
            'reward_redeem:${widget.userId}:${widget.sourceId}:$_selectedPoints',
        title: 'Reward points redeemed',
        description: 'Redeemed against ${_label(widget.module.name)} booking/order.',
        redeemedToday: widget.redeemedToday,
        redeemedThisMonth: widget.redeemedThisMonth,
        redeemedThisYear: widget.redeemedThisYear,
      );
      if (!mounted) return;
      widget.onRedeemed?.call(transaction);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF159B6C), size: 48),
          title: const Text('Points redeemed'),
          content: Text(
            'PKR ${_money(_discountValue)} reward value has been confirmed for this booking.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ],
        ),
      );
      await _loadData();
      _pointsController.clear();
    } catch (error) {
      if (mounted) _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isRedeeming = false);
    }
  }

  void _useMaximum() {
    _pointsController.text = _maximumUsablePoints.toString();
    setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text('Redeem Rewards', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return _StateMessage(
        icon: Icons.error_outline_rounded,
        title: 'Redemption unavailable',
        message: _errorMessage!.isEmpty ? 'Reward data could not be loaded.' : _errorMessage!,
        onRetry: _loadData,
      );
    }

    final wallet = _wallet!;
    final settings = _settings!;
    final enabled = settings.isRewardEnabledForModule(widget.module);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (!enabled)
          const _Notice(text: 'Reward redemption is disabled by Admin for this service.'),
        if (wallet.isFrozen)
          _Notice(text: wallet.freezeReason?.trim().isNotEmpty == true
              ? 'Wallet frozen: ${wallet.freezeReason}'
              : 'Your reward wallet is temporarily frozen.', warning: true),
        _BalanceCard(wallet: wallet, maximumUsable: _maximumUsablePoints),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5EAF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Points to redeem',
                  style: TextStyle(color: _navy, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 11),
              TextField(
                controller: _pointsController,
                enabled: enabled && wallet.isActive && !wallet.isFrozen && !_isRedeeming,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Enter points',
                  suffixIcon: TextButton(onPressed: _maximumUsablePoints > 0 ? _useMaximum : null,
                      child: const Text('MAX')),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              _DetailRow(label: 'Point value', value: '1 point = PKR ${_money(settings.pkrValuePerPoint)}'),
              _DetailRow(label: 'Reward discount', value: 'PKR ${_money(_discountValue)}', emphasized: true),
              _DetailRow(label: 'Booking amount', value: 'PKR ${_money(widget.eligibleAmount)}'),
              _DetailRow(
                label: 'Remaining payable',
                value: 'PKR ${_money((widget.eligibleAmount - _discountValue).clamp(0, widget.eligibleAmount))}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _SafetyNote(),
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: enabled && wallet.isActive && !wallet.isFrozen && !_isRedeeming
                ? _confirmAndRedeem
                : null,
            icon: _isRedeeming
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.redeem_rounded),
            label: Text(_isRedeeming ? 'Redeeming...' : 'Review & confirm'),
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.wallet, required this.maximumUsable});
  final RewardWalletModel wallet;
  final int maximumUsable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF09233F), Color(0xFF1264E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: const [BoxShadow(color: Color(0x291264E5), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Color(0x24FFFFFF),
            child: Icon(Icons.stars_rounded, color: Color(0xFFFFD166), size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available balance', style: TextStyle(color: Colors.white70)),
                Text('${_number(wallet.availablePoints)} points',
                    style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                Text('Up to ${_number(maximumUsable)} usable here',
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.emphasized = false});
  final String label;
  final String value;
  final bool emphasized;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF6A7890)))),
            Text(value, style: TextStyle(
              color: emphasized ? const Color(0xFF159B6C) : const Color(0xFF09233F),
              fontWeight: FontWeight.w800,
            )),
          ],
        ),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.warning = false});
  final String text;
  final bool warning;
  @override
  Widget build(BuildContext context) {
    final color = warning ? const Color(0xFFB54708) : const Color(0xFF1264E5);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFFF4E8) : const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, color: color),
        const SizedBox(width: 9),
        Expanded(child: Text(text, style: TextStyle(color: color))),
      ]),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: const Color(0xFFFFF8E6), borderRadius: BorderRadius.circular(14)),
        child: const Row(children: [
          Icon(Icons.lock_outline_rounded, color: Color(0xFF9A6A00)),
          SizedBox(width: 9),
          Expanded(child: Text(
            'Points are deducted only after you review and confirm. Payment is never finalized by this screen.',
            style: TextStyle(color: Color(0xFF765A18), fontSize: 12),
          )),
        ]),
      );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.icon, required this.title, required this.message, this.onRetry});
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            Icon(icon, size: 62, color: const Color(0xFF9AA5B5)),
            const SizedBox(height: 15),
            Text(title, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ]),
        ),
      );
}

String _money(num value) {
  final amount = value.toDouble();
  return amount == amount.roundToDouble()
      ? amount.toInt().toString()
      : amount.toStringAsFixed(2);
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

String _label(String value) {
  final spaced = value
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
      .replaceAll('_', ' ')
      .trim();
  if (spaced.isEmpty) return 'Other';
  return spaced.split(' ').map((word) {
    if (word.isEmpty) return word;
    return '${word[0].toUpperCase()}${word.substring(1)}';
  }).join(' ');
}



