import 'package:flutter/material.dart';

import '../models/reward_wallet_model.dart';
import '../../help/widgets/contextual_video_guide_button.dart';
import '../services/reward_service.dart';

/// Global reward wallet for Ride, Food, Hotel, Tourism, Cargo, Parcel,
/// Wallet and future SWAT RIDE modules.
class RewardWalletScreen extends StatefulWidget {
  const RewardWalletScreen({
    super.key,
    required this.userId,
    this.rewardService,
    this.onHistoryPressed,
    this.onRedeemPressed,
    this.onCouponsPressed,
    this.onVouchersPressed,
  });

  final String userId;
  final RewardService? rewardService;
  final VoidCallback? onHistoryPressed;
  final VoidCallback? onRedeemPressed;
  final VoidCallback? onCouponsPressed;
  final VoidCallback? onVouchersPressed;

  @override
  State<RewardWalletScreen> createState() => _RewardWalletScreenState();
}

class _RewardWalletScreenState extends State<RewardWalletScreen> {
  late final RewardService _rewardService;
  RewardWalletModel? _wallet;
  bool _isLoading = true;
  bool _rewardsEnabled = false;
  String? _errorMessage;

  static const Color _navy = Color(0xFF09233F);
  static const Color _background = Color(0xFFF5F7FB);

  @override
  void initState() {
    super.initState();
    _rewardService = widget.rewardService ?? RewardService();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    if (widget.userId.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User ID is required to open the reward wallet.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _rewardService.getWallet(widget.userId),
        _rewardService.getSettings(),
      ]);

      if (!mounted) return;

      setState(() {
        _wallet = results[0] as RewardWalletModel;
        _rewardsEnabled = results[1].hasValidConfiguration as bool;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(error);
      });
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    return message.isEmpty ? 'Reward wallet could not be loaded.' : message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text(
          'Reward Wallet',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadWallet,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _StateMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Wallet unavailable',
        message: _errorMessage!,
        buttonText: 'Try again',
        onPressed: _loadWallet,
      );
    }

    final wallet = _wallet;
    if (wallet == null) {
      return _StateMessage(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Wallet not found',
        message: 'Your reward wallet will appear here.',
        buttonText: 'Refresh',
        onPressed: _loadWallet,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWallet,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (!_rewardsEnabled)
            const _NoticeCard(
              icon: Icons.pause_circle_outline_rounded,
              text: 'Rewards are currently disabled by Admin.',
            ),
          if (!wallet.isActive)
            const _NoticeCard(
              icon: Icons.block_rounded,
              text: 'This reward wallet is inactive.',
              isWarning: true,
            ),
          if (wallet.isFrozen)
            _NoticeCard(
              icon: Icons.ac_unit_rounded,
              text: wallet.freezeReason?.trim().isNotEmpty == true
                  ? 'Wallet frozen: ${wallet.freezeReason}'
                  : 'This reward wallet is temporarily frozen.',
              isWarning: true,
            ),
          _BalanceCard(wallet: wallet),
          const SizedBox(height: 20),
          ContextualVideoGuideButton(
            module: 'rewards',
            feature: 'reward_wallet',
            intents: const <String>[
              'reward_points',
              'reward_balance',
              'earn_rewards',
              'redeem_rewards',
              'reward_history',
            ],
            label: 'Need Help? Watch Rewards Guide',
          ),
          const SizedBox(height: 20),
          _sectionTitle('Quick actions'),
          const SizedBox(height: 10),
          _ActionGrid(
            redeemEnabled: _rewardsEnabled && wallet.canRedeem(1),
            onRedeemPressed: widget.onRedeemPressed,
            onHistoryPressed: widget.onHistoryPressed,
            onCouponsPressed: widget.onCouponsPressed,
            onVouchersPressed: widget.onVouchersPressed,
          ),
          const SizedBox(height: 24),
          _sectionTitle('Reward summary'),
          const SizedBox(height: 10),
          _SummaryGrid(wallet: wallet),
          const SizedBox(height: 24),
          _sectionTitle('Points by module'),
          const SizedBox(height: 10),
          _ModulePointsCard(modulePoints: wallet.modulePoints),
          if (wallet.loyaltyLevelId.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            _sectionTitle('Loyalty level'),
            const SizedBox(height: 10),
            _LoyaltyCard(level: wallet.loyaltyLevelId),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _navy,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.wallet});

  final RewardWalletModel wallet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF09233F), Color(0xFF1264E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331264E5),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFFFD166),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'SWAT REWARDS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (wallet.isFrozen)
                const Icon(Icons.lock_rounded, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Available points',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            _formatNumber(wallet.availablePoints),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _BalanceDetail(
                  label: 'Pending',
                  value: wallet.pendingPoints,
                ),
              ),
              Container(width: 1, height: 35, color: Colors.white24),
              Expanded(
                child: _BalanceDetail(
                  label: 'Total tracked',
                  value: wallet.totalTrackedPoints,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceDetail extends StatelessWidget {
  const _BalanceDetail({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60)),
        const SizedBox(height: 3),
        Text(
          '${_formatNumber(value)} pts',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.redeemEnabled,
    this.onRedeemPressed,
    this.onHistoryPressed,
    this.onCouponsPressed,
    this.onVouchersPressed,
  });

  final bool redeemEnabled;
  final VoidCallback? onRedeemPressed;
  final VoidCallback? onHistoryPressed;
  final VoidCallback? onCouponsPressed;
  final VoidCallback? onVouchersPressed;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        'Redeem',
        Icons.redeem_rounded,
        redeemEnabled ? onRedeemPressed : null,
      ),
      _ActionData('History', Icons.receipt_long_rounded, onHistoryPressed),
      _ActionData('Coupons', Icons.local_offer_rounded, onCouponsPressed),
      _ActionData('Vouchers', Icons.card_giftcard_rounded, onVouchersPressed),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.86,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        final enabled = action.onPressed != null;
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: action.onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5EAF2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  action.icon,
                  color: enabled ? const Color(0xFF1264E5) : Colors.grey,
                ),
                const SizedBox(height: 8),
                FittedBox(
                  child: Text(
                    action.label,
                    style: TextStyle(
                      color: enabled ? const Color(0xFF09233F) : Colors.grey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionData {
  const _ActionData(this.label, this.icon, this.onPressed);
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.wallet});

  final RewardWalletModel wallet;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Lifetime earned',
        wallet.lifetimeEarnedPoints,
        Icons.add_circle_rounded,
        const Color(0xFF159B6C),
      ),
      (
        'Redeemed',
        wallet.lifetimeRedeemedPoints,
        Icons.shopping_bag_rounded,
        const Color(0xFF1264E5),
      ),
      (
        'Expired',
        wallet.lifetimeExpiredPoints,
        Icons.schedule_rounded,
        const Color(0xFFE07A24),
      ),
      (
        'Reversed',
        wallet.lifetimeReversedPoints,
        Icons.undo_rounded,
        const Color(0xFFD1495B),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.65,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5EAF2)),
          ),
          child: Row(
            children: [
              Icon(item.$3, color: item.$4),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatNumber(item.$2),
                      style: const TextStyle(
                        color: Color(0xFF09233F),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      item.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF6A7890)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ModulePointsCard extends StatelessWidget {
  const _ModulePointsCard({required this.modulePoints});

  final Map<String, int> modulePoints;

  @override
  Widget build(BuildContext context) {
    final entries =
        modulePoints.entries.where((entry) => entry.value != 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return const _WhiteCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(Icons.inbox_outlined, color: Color(0xFF8491A5)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Complete a booking or order to earn module points.',
                  style: TextStyle(color: Color(0xFF6A7890)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _WhiteCard(
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            _ModuleRow(entry: entries[index]),
            if (index != entries.length - 1)
              const Divider(height: 22, color: Color(0xFFE9EDF4)),
          ],
        ],
      ),
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.entry});

  final MapEntry<String, int> entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_moduleIcon(entry.key), color: const Color(0xFF1264E5)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _moduleLabel(entry.key),
            style: const TextStyle(
              color: Color(0xFF09233F),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '${_formatNumber(entry.value)} pts',
          style: const TextStyle(
            color: Color(0xFF1264E5),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _LoyaltyCard extends StatelessWidget {
  const _LoyaltyCard({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFFFF3D1),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFD89B00),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current membership',
                  style: TextStyle(color: Color(0xFF6A7890)),
                ),
                Text(
                  _moduleLabel(level),
                  style: const TextStyle(
                    color: Color(0xFF09233F),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.text,
    this.isWarning = false,
  });

  final IconData icon;
  final String text;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? const Color(0xFFB54708) : const Color(0xFF1264E5);
    final background = isWarning
        ? const Color(0xFFFFF4E8)
        : const Color(0xFFEAF3FF);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF2)),
      ),
      child: child,
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 58, color: const Color(0xFF8491A5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onPressed, child: Text(buttonText)),
          ],
        ),
      ),
    );
  }
}

String _formatNumber(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

String _moduleLabel(String value) {
  final spaced = value
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      )
      .replaceAll('_', ' ')
      .trim();
  if (spaced.isEmpty) return 'Other';
  return spaced
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}

IconData _moduleIcon(String module) {
  final value = module.toLowerCase();
  if (value.contains('food') || value.contains('restaurant')) {
    return Icons.restaurant_rounded;
  }
  if (value.contains('hotel')) return Icons.hotel_rounded;
  if (value.contains('tour') || value.contains('guide')) {
    return Icons.travel_explore_rounded;
  }
  if (value.contains('cargo')) return Icons.local_shipping_rounded;
  if (value.contains('parcel')) return Icons.inventory_2_rounded;
  if (value.contains('wallet')) return Icons.account_balance_wallet_rounded;
  if (value.contains('student')) return Icons.school_rounded;
  if (value.contains('ride') || value.contains('driver')) {
    return Icons.directions_car_rounded;
  }
  return Icons.stars_rounded;
}
