import 'package:flutter/material.dart';

import '../../rewards/models/cashback_model.dart';
import '../../rewards/models/reward_point_model.dart';

typedef CashbackSaveCallback = Future<void> Function(CashbackModel rule);
typedef CashbackDeleteCallback = Future<void> Function(String ruleId);

class CashbackManagerScreen extends StatefulWidget {
  final List<CashbackModel> initialRules;
  final bool cashbackEnabled;
  final String adminId;
  final ValueChanged<bool>? onMasterChanged;
  final CashbackSaveCallback? onSave;
  final CashbackDeleteCallback? onDelete;

  const CashbackManagerScreen({
    super.key,
    this.initialRules = const [],
    this.cashbackEnabled = true,
    required this.adminId,
    this.onMasterChanged,
    this.onSave,
    this.onDelete,
  });

  @override
  State<CashbackManagerScreen> createState() => _CashbackManagerScreenState();
}

class _CashbackManagerScreenState extends State<CashbackManagerScreen> {
  static const _navy = Color(0xFF09233F);
  static const _blue = Color(0xFF1264E5);
  static const _background = Color(0xFFF5F7FB);

  late List<CashbackModel> _rules;
  late bool _masterEnabled;
  String _query = '';
  bool? _activeFilter;

  @override
  void initState() {
    super.initState();
    _rules = [...widget.initialRules];
    _masterEnabled = widget.cashbackEnabled;
  }

  List<CashbackModel> get _filtered {
    final query = _query.trim().toLowerCase();
    return _rules.where((rule) {
      if (_activeFilter != null && rule.isActive != _activeFilter) return false;
      return query.isEmpty ||
          rule.name.toLowerCase().contains(query) ||
          rule.description.toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _save(CashbackModel rule) async {
    try {
      await widget.onSave?.call(rule);
      if (!mounted) return;
      setState(() {
        final index = _rules.indexWhere((item) => item.id == rule.id);
        if (index < 0) {
          _rules.add(rule);
        } else {
          _rules[index] = rule;
        }
      });
      _message('Cashback rule saved.');
    } catch (error) {
      if (mounted) _message('Save failed: $error', error: true);
    }
  }

  Future<void> _remove(CashbackModel rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete cashback rule?'),
        content: Text('“${rule.name}” permanently delete ho jayega.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.onDelete?.call(rule.id);
      if (!mounted) return;
      setState(() => _rules.removeWhere((item) => item.id == rule.id));
      _message('Cashback rule deleted.');
    } catch (error) {
      if (mounted) _message('Delete failed: $error', error: true);
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: error ? Colors.red.shade700 : null),
    );
  }

  Future<void> _openEditor([CashbackModel? rule]) async {
    final result = await showDialog<CashbackModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CashbackEditor(rule: rule, adminId: widget.adminId),
    );
    if (result != null) await _save(result);
  }

  @override
  Widget build(BuildContext context) {
    final active = _rules.where((rule) => rule.isActive).length;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Cashback Manager'),
        foregroundColor: Colors.white,
        backgroundColor: _navy,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New rule'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Card(
            child: SwitchListTile(
              value: _masterEnabled,
              activeThumbColor: _blue,
              title: const Text('Global Cashback', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(_masterEnabled ? 'Cashback engine is enabled' : 'All cashback earning is disabled'),
              secondary: const Icon(Icons.savings_outlined, color: _navy),
              onChanged: (value) {
                setState(() => _masterEnabled = value);
                widget.onMasterChanged?.call(value);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _StatCard(label: 'Total rules', value: '${_rules.length}', icon: Icons.rule)),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(label: 'Active rules', value: '$active', icon: Icons.check_circle_outline)),
          ]),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search cashback rules',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool?>(
            segments: const [
              ButtonSegment(value: null, label: Text('All')),
              ButtonSegment(value: true, label: Text('Active')),
              ButtonSegment(value: false, label: Text('Inactive')),
            ],
            selected: {_activeFilter},
            onSelectionChanged: (value) => setState(() => _activeFilter = value.first),
          ),
          const SizedBox(height: 16),
          if (_filtered.isEmpty)
            const _EmptyState()
          else
            ..._filtered.map((rule) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RuleCard(
                rule: rule,
                onEdit: () => _openEditor(rule),
                onDelete: () => _remove(rule),
                onActiveChanged: (value) => _save(rule.copyWith(isActive: value, updatedAt: DateTime.now())),
              ),
            )),
        ],
      ),
    );
  }
}

class _CashbackEditor extends StatefulWidget {
  final CashbackModel? rule;
  final String adminId;
  const _CashbackEditor({this.rule, required this.adminId});

  @override
  State<_CashbackEditor> createState() => _CashbackEditorState();
}

class _CashbackEditorState extends State<_CashbackEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _value;
  late final TextEditingController _minimum;
  late final TextEditingController _maximum;
  late final TextEditingController _pointsPerPkr;
  late final TextEditingController _pendingDays;
  late final TextEditingController _expiryDays;
  late final TextEditingController _daily;
  late final TextEditingController _monthly;
  late final TextEditingController _yearly;
  late final TextEditingController _totalUsage;
  late final TextEditingController _userUsage;

  late CashbackType _type;
  late CashbackDestination _destination;
  late bool _active;
  late bool _promo;
  late bool _coupon;
  late bool _voucher;
  late bool _rewardRedeem;
  late Set<RewardModule> _modules;
  late Set<String> _payments;

  static const _moduleChoices = <RewardModule>[
    RewardModule.ride,
    RewardModule.food,
    RewardModule.hotel,
    RewardModule.tourism,
    RewardModule.cargo,
    RewardModule.parcel,
    RewardModule.wallet,
  ];
  static const _paymentChoices = ['cash', 'wallet', 'jazzcash', 'easypaisa', 'card'];

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    _name = TextEditingController(text: rule?.name ?? '');
    _description = TextEditingController(text: rule?.description ?? '');
    _value = TextEditingController(text: rule?.cashbackValue.toString() ?? '');
    _minimum = TextEditingController(text: rule?.minimumBookingAmount.toString() ?? '0');
    _maximum = TextEditingController(text: rule?.maximumCashbackPerBooking?.toString() ?? '');
    _pointsPerPkr = TextEditingController(text: rule?.rewardPointsPerPkr.toString() ?? '1');
    _pendingDays = TextEditingController(text: rule?.pendingDays.toString() ?? '0');
    _expiryDays = TextEditingController(text: rule?.expiryDays?.toString() ?? '');
    _daily = TextEditingController(text: rule?.dailyCashbackLimit?.toString() ?? '');
    _monthly = TextEditingController(text: rule?.monthlyCashbackLimit?.toString() ?? '');
    _yearly = TextEditingController(text: rule?.yearlyCashbackLimit?.toString() ?? '');
    _totalUsage = TextEditingController(text: rule?.totalUsageLimit?.toString() ?? '');
    _userUsage = TextEditingController(text: rule?.usageLimitPerUser?.toString() ?? '');
    _type = rule?.type ?? CashbackType.percentage;
    _destination = rule?.destination ?? CashbackDestination.rewardWallet;
    _active = rule?.isActive ?? true;
    _promo = rule?.allowWithPromo ?? true;
    _coupon = rule?.allowWithCoupon ?? true;
    _voucher = rule?.allowWithVoucher ?? true;
    _rewardRedeem = rule?.allowWithRewardRedemption ?? false;
    _modules = {...?rule?.supportedModules};
    if (_modules.contains(RewardModule.all)) _modules = {..._moduleChoices};
    if (_modules.isEmpty) _modules = {..._moduleChoices};
    _payments = {...?rule?.supportedPaymentMethods};
  }

  @override
  void dispose() {
    for (final controller in [_name, _description, _value, _minimum, _maximum, _pointsPerPkr, _pendingDays, _expiryDays, _daily, _monthly, _yearly, _totalUsage, _userUsage]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _double(TextEditingController c) => c.text.trim().isEmpty ? null : double.tryParse(c.text.trim());
  int? _int(TextEditingController c) => c.text.trim().isEmpty ? null : int.tryParse(c.text.trim());

  String? _requiredNumber(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || number <= 0) return 'Enter a value greater than 0';
    if (_type == CashbackType.percentage && number > 100) return 'Percentage cannot exceed 100';
    return null;
  }

  String? _optionalNonNegative(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = double.tryParse(value.trim());
    return number == null || number < 0 ? 'Enter 0 or greater' : null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_modules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one module.')));
      return;
    }
    final now = DateTime.now();
    final old = widget.rule;
    Navigator.pop(
      context,
      CashbackModel(
        id: old?.id ?? 'cashback_${now.microsecondsSinceEpoch}',
        name: _name.text.trim(),
        description: _description.text.trim(),
        type: _type,
        destination: _destination,
        cashbackValue: _double(_value)!,
        minimumBookingAmount: _double(_minimum) ?? 0,
        maximumCashbackPerBooking: _double(_maximum),
        rewardPointsPerPkr: _double(_pointsPerPkr) ?? 1,
        supportedModules: _modules.length == _moduleChoices.length ? const [RewardModule.all] : _modules.toList(),
        supportedPaymentMethods: _payments.toList(),
        isActive: _active,
        allowWithPromo: _promo,
        allowWithCoupon: _coupon,
        allowWithVoucher: _voucher,
        allowWithRewardRedemption: _rewardRedeem,
        pendingDays: _int(_pendingDays) ?? 0,
        expiryDays: _int(_expiryDays),
        dailyCashbackLimit: _double(_daily),
        monthlyCashbackLimit: _double(_monthly),
        yearlyCashbackLimit: _double(_yearly),
        totalUsageLimit: _int(_totalUsage),
        usageLimitPerUser: _int(_userUsage),
        usedCount: old?.usedCount ?? 0,
        startDate: old?.startDate,
        expiryDate: old?.expiryDate,
        createdBy: old?.createdBy ?? widget.adminId,
        createdAt: old?.createdAt ?? now,
        updatedAt: now,
        metadata: old?.metadata ?? const {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.rule == null ? 'Create Cashback Rule' : 'Edit Cashback Rule'),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          actions: [TextButton(onPressed: _submit, child: const Text('SAVE'))],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _heading('Basic settings'),
              TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Rule name'), validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _description, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
              SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Rule active'), value: _active, onChanged: (v) => setState(() => _active = v)),
              _heading('Cashback calculation'),
              DropdownButtonFormField<CashbackType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Cashback type'),
                items: CashbackType.values.map((v) => DropdownMenuItem(value: v, child: Text(v == CashbackType.percentage ? 'Percentage' : 'Fixed PKR'))).toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CashbackDestination>(
                initialValue: _destination,
                decoration: const InputDecoration(labelText: 'Destination'),
                items: CashbackDestination.values.map((v) => DropdownMenuItem(value: v, child: Text(v == CashbackDestination.rewardWallet ? 'Reward wallet' : 'Payment wallet'))).toList(),
                onChanged: (v) => setState(() => _destination = v!),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextFormField(controller: _value, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _type == CashbackType.percentage ? 'Cashback %' : 'Cashback PKR'), validator: _requiredNumber)),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _minimum, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minimum booking'), validator: _optionalNonNegative)),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _maximum, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Maximum per booking (optional)'), validator: _optionalNonNegative),
              if (_destination == CashbackDestination.rewardWallet) ...[
                const SizedBox(height: 12),
                TextFormField(controller: _pointsPerPkr, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reward points per 1 PKR'), validator: _requiredNumber),
              ],
              _heading('Valid modules'),
              Wrap(spacing: 8, runSpacing: 8, children: _moduleChoices.map((module) => FilterChip(
                label: Text(_label(module.name)),
                selected: _modules.contains(module),
                onSelected: (selected) => setState(() => selected ? _modules.add(module) : _modules.remove(module)),
              )).toList()),
              _heading('Payment methods'),
              const Text('No selection means all payment methods.', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: _paymentChoices.map((method) => FilterChip(
                label: Text(_label(method)),
                selected: _payments.contains(method),
                onSelected: (selected) => setState(() => selected ? _payments.add(method) : _payments.remove(method)),
              )).toList()),
              _heading('Stacking permissions'),
              _toggle('Allow with promo', _promo, (v) => _promo = v),
              _toggle('Allow with coupon', _coupon, (v) => _coupon = v),
              _toggle('Allow with voucher', _voucher, (v) => _voucher = v),
              _toggle('Allow with reward redemption', _rewardRedeem, (v) => _rewardRedeem = v),
              _heading('Pending and expiry'),
              Row(children: [
                Expanded(child: TextFormField(controller: _pendingDays, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pending days'), validator: _optionalNonNegative)),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _expiryDays, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Expiry days (blank = never)'), validator: _optionalNonNegative)),
              ]),
              _heading('Cashback limits (optional)'),
              TextFormField(controller: _daily, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Daily PKR limit'), validator: _optionalNonNegative),
              const SizedBox(height: 10),
              TextFormField(controller: _monthly, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly PKR limit'), validator: _optionalNonNegative),
              const SizedBox(height: 10),
              TextFormField(controller: _yearly, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Yearly PKR limit'), validator: _optionalNonNegative),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextFormField(controller: _totalUsage, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total uses'), validator: _optionalNonNegative)),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _userUsage, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Uses per user'), validator: _optionalNonNegative)),
              ]),
              const SizedBox(height: 32),
              FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.save_outlined), label: const Text('Save cashback rule')),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF09233F))),
  );

  Widget _toggle(String title, bool value, ValueChanged<bool> update) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    value: value,
    onChanged: (v) => setState(() => update(v)),
  );
}

class _RuleCard extends StatelessWidget {
  final CashbackModel rule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onActiveChanged;
  const _RuleCard({required this.rule, required this.onEdit, required this.onDelete, required this.onActiveChanged});

  @override
  Widget build(BuildContext context) {
    final amount = rule.type == CashbackType.percentage ? '${rule.cashbackValue.toStringAsFixed(1)}%' : 'PKR ${rule.cashbackValue.toStringAsFixed(0)}';
    final modules = rule.supportedModules.contains(RewardModule.all) ? 'All modules' : rule.supportedModules.map((m) => _label(m.name)).join(', ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(rule.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
            Switch(value: rule.isActive, onChanged: onActiveChanged),
          ]),
          Text('$amount cashback • ${rule.destination == CashbackDestination.rewardWallet ? 'Reward wallet' : 'Payment wallet'}', style: const TextStyle(color: Color(0xFF1264E5), fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(modules, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text('Min PKR ${rule.minimumBookingAmount.toStringAsFixed(0)}  •  Used ${rule.usedCount}${rule.totalUsageLimit == null ? '' : '/${rule.totalUsageLimit}'}', style: const TextStyle(color: Colors.black54)),
          const Divider(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined), label: const Text('Edit')),
            TextButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline), label: const Text('Delete'), style: TextButton.styleFrom(foregroundColor: Colors.red.shade700)),
          ]),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(14),
    child: Row(children: [Icon(icon, color: const Color(0xFF1264E5)), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(color: Colors.black54))])]),
  ));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 56),
    child: Column(children: [Icon(Icons.savings_outlined, size: 58, color: Colors.black26), SizedBox(height: 12), Text('No cashback rules found', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))]),
  );
}

String _label(String value) {
  final spaced = value.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}');
  return spaced.isEmpty ? spaced : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}
