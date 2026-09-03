import 'package:flutter/material.dart';

import '../models/reward_point_model.dart';
import '../models/reward_settings_model.dart';
import '../services/reward_service.dart';

/// Read-only summary of the reward program configured by Admin.
/// Users cannot change global reward settings from this screen.
class RewardSettingsScreen extends StatefulWidget {
  const RewardSettingsScreen({
    super.key,
    this.module,
    this.rewardService,
  });

  final RewardModule? module;
  final RewardService? rewardService;

  @override
  State<RewardSettingsScreen> createState() =>
      _RewardSettingsScreenState();
}

class _RewardSettingsScreenState extends State<RewardSettingsScreen> {
  late final RewardService _rewardService;
  RewardSettingsModel? _settings;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _rewardService = widget.rewardService ?? RewardService();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final settings = await _rewardService.getSettings();
      if (!mounted) return;
      setState(() => _settings = settings);
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
        title: const Text('Reward Settings'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadSettings,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSettings,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading && _settings == null) {
      return const _ScrollableMessage(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _settings == null) {
      return _ScrollableMessage(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52),
            const SizedBox(height: 12),
            const Text('Reward settings could not be loaded.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadSettings,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final settings = _settings!;
    final module = widget.module;
    final rewardsAvailable = module == null
        ? settings.rewardsEnabled
        : settings.isRewardEnabledForModule(module);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _StatusBanner(
          enabled: rewardsAvailable,
          title: rewardsAvailable
              ? 'Rewards are available'
              : 'Rewards are currently unavailable',
          subtitle: module == null
              ? 'These settings are managed by SWAT RIDE Admin.'
              : 'For ${_friendlyName(module.name)}. Settings are managed by Admin.',
        ),
        if (!settings.hasValidConfiguration) ...[
          const SizedBox(height: 12),
          const _WarningCard(
            text: 'Admin configuration is incomplete. Earning and redemption may remain disabled.',
          ),
        ],
        const SizedBox(height: 16),
        _SettingsSection(
          title: 'Point value & redemption',
          icon: Icons.stars_rounded,
          children: [
            _ValueTile(
              label: '1 reward point',
              value: '${_number(settings.pkrValuePerPoint)} PKR',
            ),
            _ValueTile(
              label: 'Minimum redeem',
              value: '${settings.minimumRedeemPoints} points',
            ),
            _ValueTile(
              label: 'Maximum per booking',
              value: _pointsOrNoLimit(
                settings.maximumRedeemPointsPerBooking,
              ),
            ),
            _ValueTile(
              label: 'Maximum booking payment',
              value: '${_number(settings.maximumRedeemPercentage)}%',
            ),
          ],
        ),
        _SettingsSection(
          title: 'Reward expiry',
          icon: Icons.event_available_rounded,
          children: [
            _ValueTile(
              label: 'Expiry policy',
              value: settings.expiryPolicy == RewardExpiryPolicy.never
                  ? 'Points never expire'
                  : '${settings.rewardExpiryDays ?? 0} days',
            ),
            _ValueTile(
              label: 'Expiry reminder',
              value: settings.expiryNotificationsEnabled
                  ? '${settings.expiryReminderDays} days before'
                  : 'Off',
            ),
          ],
        ),
        _SettingsSection(
          title: module == null
              ? 'Available benefits'
              : '${_friendlyName(module.name)} benefits',
          icon: Icons.card_giftcard_rounded,
          children: _benefitTiles(settings, module),
        ),
        _SettingsSection(
          title: 'Bonuses',
          icon: Icons.celebration_rounded,
          children: [
            _SwitchInfoTile(
              label: 'Signup bonus',
              enabled: settings.signupBonusEnabled,
              detail: settings.signupBonusEnabled
                  ? _bonusDetail(
                      settings.signupBonusPoints,
                      settings.signupBonusCouponId,
                      settings.signupBonusVoucherId,
                    )
                  : null,
            ),
            _SwitchInfoTile(
              label: 'First booking bonus',
              enabled: settings.firstBookingBonusEnabled,
              detail: settings.firstBookingBonusEnabled
                  ? _bonusDetail(
                      settings.firstBookingBonusPoints,
                      settings.firstBookingBonusCouponId,
                      settings.firstBookingBonusVoucherId,
                    )
                  : null,
            ),
          ],
        ),
        _SettingsSection(
          title: 'Earning limits',
          icon: Icons.trending_up_rounded,
          children: [
            _ValueTile(label: 'Per booking', value: _pointsOrNoLimit(settings.maximumEarnPointsPerBooking)),
            _ValueTile(label: 'Daily', value: _pointsOrNoLimit(settings.dailyEarnPointsLimit)),
            _ValueTile(label: 'Monthly', value: _pointsOrNoLimit(settings.monthlyEarnPointsLimit)),
            _ValueTile(label: 'Yearly', value: _pointsOrNoLimit(settings.yearlyEarnPointsLimit)),
          ],
        ),
        _SettingsSection(
          title: 'Redemption limits',
          icon: Icons.redeem_rounded,
          children: [
            _ValueTile(label: 'Daily', value: _pointsOrNoLimit(settings.dailyRedeemPointsLimit)),
            _ValueTile(label: 'Monthly', value: _pointsOrNoLimit(settings.monthlyRedeemPointsLimit)),
            _ValueTile(label: 'Yearly', value: _pointsOrNoLimit(settings.yearlyRedeemPointsLimit)),
          ],
        ),
        _SettingsSection(
          title: 'Combination rules',
          icon: Icons.layers_rounded,
          children: [
            _SwitchInfoTile(label: 'Promo with rewards', enabled: settings.allowPromoWithRewards),
            _SwitchInfoTile(label: 'Coupon with rewards', enabled: settings.allowCouponWithRewards),
            _SwitchInfoTile(label: 'Voucher with rewards', enabled: settings.allowVoucherWithRewards),
            _SwitchInfoTile(label: 'Cashback with rewards', enabled: settings.allowCashbackWithRewards),
            _SwitchInfoTile(label: 'Promo with coupon', enabled: settings.allowPromoWithCoupon),
            _SwitchInfoTile(label: 'Promo with voucher', enabled: settings.allowPromoWithVoucher),
            _SwitchInfoTile(label: 'Coupon with voucher', enabled: settings.allowCouponWithVoucher),
          ],
        ),
        _SettingsSection(
          title: 'Safety & notifications',
          icon: Icons.verified_user_rounded,
          children: [
            _SwitchInfoTile(label: 'Completed booking required', enabled: settings.requireCompletedBooking),
            _SwitchInfoTile(label: 'Successful payment required', enabled: settings.requireSuccessfulPayment),
            _SwitchInfoTile(label: 'Cancellation reversal', enabled: settings.reverseRewardOnCancellation),
            _SwitchInfoTile(label: 'Refund reversal', enabled: settings.reverseRewardOnRefund),
            _SwitchInfoTile(label: 'Negative balance protection', enabled: settings.preventNegativeRewardBalance),
            _SwitchInfoTile(label: 'Duplicate reward protection', enabled: settings.duplicateRewardProtectionEnabled),
            _SwitchInfoTile(label: 'Reward notifications', enabled: settings.rewardNotificationsEnabled),
            _SwitchInfoTile(label: 'Loyalty upgrade notifications', enabled: settings.loyaltyUpgradeNotificationsEnabled),
          ],
        ),
        _SettingsSection(
          title: 'AI assistance',
          icon: Icons.auto_awesome_rounded,
          children: [
            _SwitchInfoTile(
              label: 'Personalized recommendations',
              enabled: settings.aiRecommendationsEnabled,
              detail: 'AI only recommends offers.',
            ),
            const _SwitchInfoTile(
              label: 'Automatic discount/payment',
              enabled: false,
              detail: 'Always requires user or Admin confirmation.',
            ),
          ],
        ),
        Text(
          'Last updated: ${_date(settings.updatedAt)}  •  Version ${settings.version}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  List<Widget> _benefitTiles(
    RewardSettingsModel settings,
    RewardModule? module,
  ) {
    bool value(bool global, bool Function(RewardModule) moduleCheck) {
      return module == null ? global : moduleCheck(module);
    }

    return [
      _SwitchInfoTile(label: 'Reward points', enabled: value(settings.rewardsEnabled, settings.isRewardEnabledForModule)),
      _SwitchInfoTile(label: 'Promo codes', enabled: value(settings.promoEnabled, settings.isPromoEnabledForModule)),
      _SwitchInfoTile(label: 'Coupons', enabled: value(settings.couponEnabled, settings.isCouponEnabledForModule)),
      _SwitchInfoTile(label: 'Vouchers', enabled: value(settings.voucherEnabled, settings.isVoucherEnabledForModule)),
      _SwitchInfoTile(label: 'Cashback', enabled: value(settings.cashbackEnabled, settings.isCashbackEnabledForModule)),
      _SwitchInfoTile(label: 'Referral rewards', enabled: value(settings.referralEnabled, settings.isReferralEnabledForModule)),
      _SwitchInfoTile(label: 'Loyalty levels', enabled: value(settings.loyaltyEnabled, settings.isLoyaltyEnabledForModule)),
    ];
  }

  static String _pointsOrNoLimit(int? value) =>
      value == null ? 'No Admin limit' : '$value points';

  static String _bonusDetail(int points, String? coupon, String? voucher) {
    final benefits = <String>[];
    if (points > 0) benefits.add('$points points');
    if (coupon != null && coupon.isNotEmpty) benefits.add('coupon');
    if (voucher != null && voucher.isNotEmpty) benefits.add('voucher');
    return benefits.isEmpty ? 'Configured by Admin' : benefits.join(' + ');
  }

  static String _number(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);

  static String _friendlyName(String value) {
    final spaced = value.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  static String _date(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _SwitchInfoTile extends StatelessWidget {
  const _SwitchInfoTile({required this.label, required this.enabled, this.detail});
  final String label;
  final bool enabled;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.green : Theme.of(context).colorScheme.outline;
    return ListTile(
      dense: true,
      leading: Icon(enabled ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color),
      title: Text(label),
      subtitle: detail == null ? null : Text(detail!),
      trailing: Text(enabled ? 'ON' : 'OFF', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.enabled, required this.title, required this.subtitle});
  final bool enabled;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Colors.green : Colors.orange;
    return Card(
      margin: EdgeInsets.zero,
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(enabled ? Icons.workspace_premium_rounded : Icons.info_rounded, color: color, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded),
        title: Text(text),
      ),
    );
  }
}

class _ScrollableMessage extends StatelessWidget {
  const _ScrollableMessage({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}
