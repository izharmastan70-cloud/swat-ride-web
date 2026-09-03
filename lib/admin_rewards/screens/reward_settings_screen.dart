import 'package:flutter/material.dart';

import '../../rewards/models/reward_point_model.dart';
import '../../rewards/models/reward_settings_model.dart';
import '../../rewards/services/reward_service.dart';

class AdminRewardSettingsScreen extends StatefulWidget {
  const AdminRewardSettingsScreen({
    super.key,
    required this.adminId,
    this.rewardService,
    this.onSaved,
  });

  final String adminId;
  final RewardService? rewardService;
  final ValueChanged<RewardSettingsModel>? onSaved;

  @override
  State<AdminRewardSettingsScreen> createState() =>
      _AdminRewardSettingsScreenState();
}

class _AdminRewardSettingsScreenState
    extends State<AdminRewardSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final RewardService _service;
  RewardSettingsModel? _original;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  Object? _error;

  final Map<String, bool> _flags = {};
  final Map<String, Map<String, bool>> _moduleFlags = {};
  final Map<String, TextEditingController> _numbers = {};
  int _expiryPreset = 0;

  static const _modules = <RewardModule>[
    RewardModule.ride,
    RewardModule.studentRide,
    RewardModule.food,
    RewardModule.hotel,
    RewardModule.tourism,
    RewardModule.cargo,
    RewardModule.parcel,
    RewardModule.wallet,
  ];

  static const _globalFlagKeys = <String>[
    'rewardsEnabled',
    'promoEnabled',
    'couponEnabled',
    'voucherEnabled',
    'cashbackEnabled',
    'referralEnabled',
    'loyaltyEnabled',
    'signupBonusEnabled',
    'firstBookingBonusEnabled',
    'allowPromoWithRewards',
    'allowCouponWithRewards',
    'allowVoucherWithRewards',
    'allowCashbackWithRewards',
    'allowPromoWithCoupon',
    'allowPromoWithVoucher',
    'allowCouponWithVoucher',
    'requireCompletedBooking',
    'requireSuccessfulPayment',
    'reverseRewardOnCancellation',
    'reverseRewardOnRefund',
    'preventNegativeRewardBalance',
    'duplicateRewardProtectionEnabled',
    'rewardNotificationsEnabled',
    'expiryNotificationsEnabled',
    'loyaltyUpgradeNotificationsEnabled',
    'aiRecommendationsEnabled',
  ];

  static const _moduleMapKeys = <String>[
    'moduleRewardEnabled',
    'modulePromoEnabled',
    'moduleCouponEnabled',
    'moduleVoucherEnabled',
    'moduleCashbackEnabled',
    'moduleReferralEnabled',
    'moduleLoyaltyEnabled',
  ];

  static const _numberKeys = <String>[
    'pkrValuePerPoint',
    'minimumRedeemPoints',
    'maximumRedeemPointsPerBooking',
    'maximumRedeemPercentage',
    'maximumEarnPointsPerBooking',
    'dailyEarnPointsLimit',
    'monthlyEarnPointsLimit',
    'yearlyEarnPointsLimit',
    'dailyRedeemPointsLimit',
    'monthlyRedeemPointsLimit',
    'yearlyRedeemPointsLimit',
    'signupBonusPoints',
    'firstBookingBonusPoints',
    'rewardExpiryDays',
    'expiryReminderDays',
  ];

  @override
  void initState() {
    super.initState();
    _service = widget.rewardService ?? RewardService();
    for (final key in _numberKeys) {
      _numbers[key] = TextEditingController();
    }
    _load();
  }

  @override
  void dispose() {
    for (final controller in _numbers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final settings = await _service.getSettings();
      if (!mounted) return;
      _applySettings(settings);
      setState(() {
        _original = settings;
        _loading = false;
        _dirty = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _applySettings(RewardSettingsModel settings) {
    final map = settings.toMap();
    for (final key in _globalFlagKeys) {
      _flags[key] = map[key] as bool? ?? false;
    }
    for (final key in _moduleMapKeys) {
      _moduleFlags[key] = Map<String, bool>.from(
        map[key] as Map? ?? const {'all': false},
      );
    }
    for (final key in _numberKeys) {
      final value = map[key];
      _numbers[key]!.text = value == null ? '' : _cleanNumber(value);
    }
    final days = settings.rewardExpiryDays;
    if (settings.expiryPolicy == RewardExpiryPolicy.never) {
      _expiryPreset = 0;
    } else if (days == 30 || days == 90 || days == 180 || days == 365) {
      _expiryPreset = days!;
    } else {
      _expiryPreset = -1;
    }
  }

  void _changed() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty || _saving) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text('Unsaved reward settings will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final original = _original;
    if (original == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save reward settings?'),
        content: const Text(
          'These changes can affect Ride, Food, Hotel, Tourism, Cargo, Parcel and Wallet users. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm & save'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final map = <String, dynamic>{
        ...original.toMap(),
        ..._flags,
        ..._moduleFlags,
        'updatedBy': widget.adminId,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'expiryPolicy': _expiryPreset == 0
            ? RewardExpiryPolicy.never.name
            : RewardExpiryPolicy.customDays.name,
        'rewardExpiryDays': _expiryPreset == 0
            ? null
            : _intValue('rewardExpiryDays'),
        'aiAutoApplyEnabled': false,
      };

      for (final key in _numberKeys) {
        if (key == 'rewardExpiryDays') continue;
        map[key] = key == 'pkrValuePerPoint' ||
                key == 'maximumRedeemPercentage'
            ? _doubleValue(key)
            : _nullableIntValue(key);
      }
      map['minimumRedeemPoints'] = _intValue('minimumRedeemPoints');
      map['signupBonusPoints'] = _intValue('signupBonusPoints');
      map['firstBookingBonusPoints'] = _intValue('firstBookingBonusPoints');
      map['expiryReminderDays'] = _intValue('expiryReminderDays');

      final updated = RewardSettingsModel.fromMap(map);
      if (!updated.hasValidConfiguration) {
        throw const FormatException('Reward configuration is invalid.');
      }
      await _service.saveSettings(updated);
      final saved = await _service.getSettings();
      if (!mounted) return;
      _applySettings(saved);
      setState(() {
        _original = saved;
        _dirty = false;
      });
      widget.onSaved?.call(saved);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reward settings saved successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save settings: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reward Settings'),
          actions: [
            IconButton(
              tooltip: 'Reload',
              onPressed: _loading || _saving ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: !_dirty || _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _original == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 54),
            const SizedBox(height: 12),
            const Text('Reward settings could not be loaded.'),
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

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          const _AdminNotice(),
          const SizedBox(height: 14),
          _Section(
            title: 'Global master controls',
            icon: Icons.power_settings_new_rounded,
            children: [
              _flag('Reward engine', 'rewardsEnabled'),
              _flag('Promo codes', 'promoEnabled'),
              _flag('Coupons', 'couponEnabled'),
              _flag('Vouchers', 'voucherEnabled'),
              _flag('Cashback', 'cashbackEnabled'),
              _flag('Referral', 'referralEnabled'),
              _flag('Loyalty levels', 'loyaltyEnabled'),
            ],
          ),
          _Section(
            title: 'Point value & redemption',
            icon: Icons.stars_rounded,
            children: [
              _number('PKR value of 1 point', 'pkrValuePerPoint', decimal: true, minimum: 0.01),
              _number('Minimum redeem points', 'minimumRedeemPoints'),
              _number('Maximum points per booking', 'maximumRedeemPointsPerBooking', optional: true),
              _number('Maximum booking payment (%)', 'maximumRedeemPercentage', decimal: true, maximum: 100),
            ],
          ),
          _Section(
            title: 'Signup & first booking bonuses',
            icon: Icons.celebration_rounded,
            children: [
              _flag('Signup bonus', 'signupBonusEnabled'),
              if (_flags['signupBonusEnabled'] == true)
                _number('Signup bonus points', 'signupBonusPoints'),
              _flag('First booking bonus', 'firstBookingBonusEnabled'),
              if (_flags['firstBookingBonusEnabled'] == true)
                _number('First booking bonus points', 'firstBookingBonusPoints'),
            ],
          ),
          _Section(
            title: 'Reward expiry',
            icon: Icons.event_busy_rounded,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<int>(
                  initialValue: _expiryPreset,
                  decoration: const InputDecoration(
                    labelText: 'Expiry policy',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Never expire')),
                    DropdownMenuItem(value: 30, child: Text('30 days')),
                    DropdownMenuItem(value: 90, child: Text('90 days')),
                    DropdownMenuItem(value: 180, child: Text('180 days')),
                    DropdownMenuItem(value: 365, child: Text('1 year')),
                    DropdownMenuItem(value: -1, child: Text('Custom days')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _expiryPreset = value;
                      if (value > 0) {
                        _numbers['rewardExpiryDays']!.text = '$value';
                      } else if (value == 0) {
                        _numbers['rewardExpiryDays']!.clear();
                      }
                      _dirty = true;
                    });
                  },
                ),
              ),
              if (_expiryPreset == -1)
                _number('Custom expiry days', 'rewardExpiryDays', minimum: 1),
              _number('Reminder days before expiry', 'expiryReminderDays'),
            ],
          ),
          _Section(
            title: 'Earning limits',
            icon: Icons.trending_up_rounded,
            children: [
              _number('Maximum per booking', 'maximumEarnPointsPerBooking', optional: true),
              _number('Daily earn limit', 'dailyEarnPointsLimit', optional: true),
              _number('Monthly earn limit', 'monthlyEarnPointsLimit', optional: true),
              _number('Yearly earn limit', 'yearlyEarnPointsLimit', optional: true),
            ],
          ),
          _Section(
            title: 'Redemption limits',
            icon: Icons.redeem_rounded,
            children: [
              _number('Daily redeem limit', 'dailyRedeemPointsLimit', optional: true),
              _number('Monthly redeem limit', 'monthlyRedeemPointsLimit', optional: true),
              _number('Yearly redeem limit', 'yearlyRedeemPointsLimit', optional: true),
            ],
          ),
          _Section(
            title: 'Module-wise controls',
            icon: Icons.apps_rounded,
            children: [
              _ModuleMatrix(
                modules: _modules,
                values: _moduleFlags,
                onChanged: (mapKey, module, enabled) {
                  setState(() {
                    _moduleFlags[mapKey]![module.name] = enabled;
                    _dirty = true;
                  });
                },
              ),
            ],
          ),
          _Section(
            title: 'Combination rules',
            icon: Icons.layers_rounded,
            children: [
              _flag('Allow promo with rewards', 'allowPromoWithRewards'),
              _flag('Allow coupon with rewards', 'allowCouponWithRewards'),
              _flag('Allow voucher with rewards', 'allowVoucherWithRewards'),
              _flag('Allow cashback with rewards', 'allowCashbackWithRewards'),
              _flag('Allow promo with coupon', 'allowPromoWithCoupon'),
              _flag('Allow promo with voucher', 'allowPromoWithVoucher'),
              _flag('Allow coupon with voucher', 'allowCouponWithVoucher'),
            ],
          ),
          _Section(
            title: 'Booking & wallet safety',
            icon: Icons.security_rounded,
            children: [
              _flag('Completed booking required', 'requireCompletedBooking'),
              _flag('Successful payment required', 'requireSuccessfulPayment'),
              _flag('Reverse on cancellation', 'reverseRewardOnCancellation'),
              _flag('Reverse on refund', 'reverseRewardOnRefund'),
              _flag('Prevent negative balance', 'preventNegativeRewardBalance'),
              _flag('Duplicate reward protection', 'duplicateRewardProtectionEnabled'),
            ],
          ),
          _Section(
            title: 'Notifications & AI',
            icon: Icons.auto_awesome_rounded,
            children: [
              _flag('Reward notifications', 'rewardNotificationsEnabled'),
              _flag('Expiry notifications', 'expiryNotificationsEnabled'),
              _flag('Loyalty upgrade notifications', 'loyaltyUpgradeNotificationsEnabled'),
              _flag('AI recommendations', 'aiRecommendationsEnabled'),
              const ListTile(
                leading: Icon(Icons.lock_rounded, color: Colors.red),
                title: Text('AI automatic discount/payment'),
                subtitle: Text('Locked OFF â€” requires Admin or user confirmation.'),
                trailing: Text('OFF', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flag(String label, String key) {
    return SwitchListTile.adaptive(
      title: Text(label),
      value: _flags[key] ?? false,
      onChanged: _saving
          ? null
          : (value) {
              setState(() {
                _flags[key] = value;
                _dirty = true;
              });
            },
    );
  }

  Widget _number(
    String label,
    String key, {
    bool optional = false,
    bool decimal = false,
    double minimum = 0,
    double? maximum,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextFormField(
        controller: _numbers[key],
        enabled: !_saving,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: optional ? 'Leave empty for no limit' : null,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => _changed(),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return optional ? null : 'Required';
          final parsed = decimal ? double.tryParse(text) : int.tryParse(text)?.toDouble();
          if (parsed == null) return 'Enter a valid number';
          if (parsed < minimum) return 'Minimum is ${_cleanNumber(minimum)}';
          if (maximum != null && parsed > maximum) {
            return 'Maximum is ${_cleanNumber(maximum)}';
          }
          return null;
        },
      ),
    );
  }

  int _intValue(String key) => int.tryParse(_numbers[key]!.text.trim()) ?? 0;

  int? _nullableIntValue(String key) {
    final value = _numbers[key]!.text.trim();
    return value.isEmpty ? null : int.tryParse(value);
  }

  double _doubleValue(String key) =>
      double.tryParse(_numbers[key]!.text.trim()) ?? 0;
}

class _ModuleMatrix extends StatelessWidget {
  const _ModuleMatrix({required this.modules, required this.values, required this.onChanged});
  final List<RewardModule> modules;
  final Map<String, Map<String, bool>> values;
  final void Function(String mapKey, RewardModule module, bool enabled) onChanged;

  static const _columns = <String, String>{
    'moduleRewardEnabled': 'Reward',
    'modulePromoEnabled': 'Promo',
    'moduleCouponEnabled': 'Coupon',
    'moduleVoucherEnabled': 'Voucher',
    'moduleCashbackEnabled': 'Cashback',
    'moduleReferralEnabled': 'Referral',
    'moduleLoyaltyEnabled': 'Loyalty',
  };

  bool _value(String mapKey, RewardModule module) {
    final map = values[mapKey] ?? const {};
    return map[module.name] ?? map[RewardModule.all.name] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Module')),
          ..._columns.values.map((label) => DataColumn(label: Text(label))),
        ],
        rows: modules.map((module) {
          return DataRow(
            cells: [
              DataCell(Text(_label(module.name))),
              ..._columns.keys.map((key) {
                return DataCell(
                  Checkbox(
                    value: _value(key, module),
                    onChanged: (value) => onChanged(key, module, value ?? false),
                  ),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.children});
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
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _AdminNotice extends StatelessWidget {
  const _AdminNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.blue.withValues(alpha: 0.10),
      child: const ListTile(
        leading: Icon(Icons.admin_panel_settings_rounded, color: Colors.blue),
        title: Text('Admin-only controls', style: TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('Changes require confirmation and are recorded with Admin identity and version.'),
      ),
    );
  }
}

String _cleanNumber(dynamic value) {
  final number = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  return number == number.roundToDouble()
      ? number.toInt().toString()
      : number.toStringAsFixed(2);
}

String _label(String value) {
  final spaced = value.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  return spaced.isEmpty ? '' : spaced[0].toUpperCase() + spaced.substring(1);
}

