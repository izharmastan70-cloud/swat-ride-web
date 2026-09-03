import 'package:flutter/material.dart';

import '../../rewards/models/reward_point_model.dart';
import '../../rewards/models/voucher_model.dart';
import '../../rewards/services/voucher_service.dart';

class VoucherManagerScreen extends StatefulWidget {
  const VoucherManagerScreen({
    super.key,
    required this.adminId,
    this.voucherService,
  });

  final String adminId;
  final VoucherService? voucherService;

  @override
  State<VoucherManagerScreen> createState() =>
      _VoucherManagerScreenState();
}

class _VoucherManagerScreenState extends State<VoucherManagerScreen> {
  late final VoucherService _service;
  List<VoucherModel> _vouchers = const [];
  bool _loading = true;
  bool _busy = false;
  String _query = '';
  VoucherStatus? _statusFilter;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.voucherService ?? VoucherService();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final vouchers = await _service.getAllVouchers();
      if (!mounted) return;
      setState(() => _vouchers = vouchers);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<VoucherModel> get _filtered {
    final query = _query.trim().toLowerCase();
    return _vouchers.where((voucher) {
      if (_statusFilter != null && voucher.status != _statusFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return voucher.code.toLowerCase().contains(query) ||
          voucher.title.toLowerCase().contains(query) ||
          voucher.description.toLowerCase().contains(query) ||
          (voucher.assignedUserId?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voucher Manager'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading || _busy ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create voucher'),
      ),
      body: Column(
        children: [
          _Toolbar(
            onSearch: (value) => setState(() => _query = value),
            status: _statusFilter,
            onStatusChanged: (value) => setState(() => _statusFilter = value),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading && _vouchers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _vouchers.isEmpty) {
      return _MessageState(
        icon: Icons.cloud_off_rounded,
        text: 'Vouchers could not be loaded.',
        action: FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return _MessageState(
        icon: Icons.card_giftcard_outlined,
        text: _query.isNotEmpty || _statusFilter != null
            ? 'No matching vouchers.'
            : 'No vouchers created.',
        action: _query.isEmpty && _statusFilter == null
            ? FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create voucher'),
              )
            : null,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final voucher = items[index];
          return _VoucherCard(
            voucher: voucher,
            disabled: _busy,
            onEdit: () => _openEditor(voucher),
            onToggle: (value) => _toggle(voucher, value),
            onCancel: () => _cancel(voucher),
            onDelete: () => _delete(voucher),
          );
        },
      ),
    );
  }

  Future<void> _openEditor([VoucherModel? voucher]) async {
    final result = await showDialog<VoucherModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _VoucherEditor(
        adminId: widget.adminId,
        voucher: voucher,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      if (voucher == null) {
        await _service.createVoucher(result);
      } else {
        await _service.updateVoucher(result);
      }
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      _notice(voucher == null ? 'Voucher created.' : 'Voucher updated.');
    } catch (error) {
      if (mounted) _notice('Could not save voucher: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle(VoucherModel voucher, bool active) async {
    final data = voucher.toMap();
    data['isActive'] = active;
    data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    setState(() => _busy = true);
    try {
      await _service.updateVoucher(VoucherModel.fromMap(data));
      await _load();
      if (mounted) _notice('${voucher.code} turned ${active ? 'ON' : 'OFF'}.');
    } catch (error) {
      if (mounted) _notice('Could not update voucher: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(VoucherModel voucher) async {
    final confirmed = await _confirm(
      title: 'Cancel voucher?',
      message: '${voucher.code} will stop working and its status will become cancelled.',
      action: 'Cancel voucher',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.cancelVoucher(voucher.id);
      await _load();
      if (mounted) _notice('Voucher cancelled.');
    } catch (error) {
      if (mounted) _notice('Could not cancel voucher: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(VoucherModel voucher) async {
    final confirmed = await _confirm(
      title: 'Delete voucher permanently?',
      message: '${voucher.code} will be removed permanently. Redemption history should remain in reports.',
      action: 'Delete',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.deleteVoucher(voucher.id);
      await _load();
      if (mounted) _notice('Voucher deleted.');
    } catch (error) {
      if (mounted) _notice('Could not delete voucher: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm({required String title, required String message, required String action, bool danger = false}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
              FilledButton(
                style: danger ? FilledButton.styleFrom(backgroundColor: Colors.red) : null,
                onPressed: () => Navigator.pop(context, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _notice(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _VoucherEditor extends StatefulWidget {
  const _VoucherEditor({required this.adminId, this.voucher});
  final String adminId;
  final VoucherModel? voucher;

  @override
  State<_VoucherEditor> createState() => _VoucherEditorState();
}

class _VoucherEditorState extends State<_VoucherEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _benefit;
  late final TextEditingController _minimum;
  late final TextEditingController _maximum;
  late final TextEditingController _userId;
  late VoucherType _type;
  late VoucherBenefitType _benefitType;
  late Set<RewardModule> _modules;
  late bool _active;
  late bool _singleUse;
  late bool _allowRewards;
  late bool _allowPromo;
  late bool _allowCoupon;
  late bool _allowCashback;
  late DateTime _validFrom;
  late DateTime _expiry;

  static const _availableModules = <RewardModule>[
    RewardModule.ride,
    RewardModule.studentRide,
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
    final voucher = widget.voucher;
    final now = DateTime.now();
    _code = TextEditingController(text: voucher?.code ?? '');
    _title = TextEditingController(text: voucher?.title ?? '');
    _description = TextEditingController(text: voucher?.description ?? '');
    _benefit = TextEditingController(text: voucher == null ? '' : _number(voucher.benefitValue));
    _minimum = TextEditingController(text: voucher == null ? '0' : _number(voucher.minimumAmount));
    _maximum = TextEditingController(text: voucher?.maximumDiscount == null ? '' : _number(voucher!.maximumDiscount!));
    _userId = TextEditingController(text: voucher?.assignedUserId ?? '');
    _type = voucher?.type ?? VoucherType.manual;
    _benefitType = voucher?.benefitType ?? VoucherBenefitType.percentageDiscount;
    _modules = voucher == null ? {RewardModule.all} : Set.of(voucher.supportedModules);
    _active = voucher?.isActive ?? true;
    _singleUse = voucher?.singleUse ?? true;
    _allowRewards = voucher?.allowRewardRedemption ?? false;
    _allowPromo = voucher?.allowPromoStacking ?? false;
    _allowCoupon = voucher?.allowCouponStacking ?? false;
    _allowCashback = voucher?.allowCashback ?? true;
    _validFrom = voucher?.validFrom ?? now;
    _expiry = voucher?.expiryDate ?? now.add(const Duration(days: 30));
  }

  @override
  void dispose() {
    for (final controller in [_code, _title, _description, _benefit, _minimum, _maximum, _userId]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
          title: Text(widget.voucher == null ? 'Create voucher' : 'Edit voucher'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.save_rounded), label: const Text('Review & save')),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              _Section(title: 'Voucher details', children: [
                _text(_code, 'Voucher code', required: true, capitals: true),
                _text(_title, 'Title', required: true),
                _text(_description, 'Description', lines: 3),
                _dropdown<VoucherType>('Voucher type', _type, VoucherType.values, (value) => _type = value),
                SwitchListTile.adaptive(title: const Text('Voucher active'), value: _active, onChanged: (value) => setState(() => _active = value)),
              ]),
              _Section(title: 'Benefit', children: [
                _dropdown<VoucherBenefitType>('Benefit type', _benefitType, VoucherBenefitType.values, (value) => _benefitType = value),
                _numeric(_benefit, _benefitType == VoucherBenefitType.rewardPoints ? 'Reward points' : 'Benefit value', required: true, maximum: _benefitType == VoucherBenefitType.percentageDiscount ? 100 : null),
                _numeric(_minimum, 'Minimum booking/order amount', required: true),
                _numeric(_maximum, 'Maximum discount', optional: true),
              ]),
              _Section(title: 'Distribution & validity', children: [
                _text(_userId, 'Assigned user ID (empty = automatic/unassigned)'),
                _DateTile(label: 'Valid from', value: _validFrom, onTap: () => _pickDate(true)),
                _DateTile(label: 'Expiry date', value: _expiry, onTap: () => _pickDate(false)),
              ]),
              _Section(title: 'Supported modules', children: [
                CheckboxListTile(
                  title: const Text('All current and future modules'),
                  value: _modules.contains(RewardModule.all),
                  onChanged: (value) => setState(() => _modules = value == true ? {RewardModule.all} : {}),
                ),
                if (!_modules.contains(RewardModule.all))
                  ..._availableModules.map((module) => CheckboxListTile(
                        title: Text(_label(module.name)),
                        value: _modules.contains(module),
                        onChanged: (value) => setState(() => value == true ? _modules.add(module) : _modules.remove(module)),
                      )),
              ]),
              _Section(title: 'Usage & stacking', children: [
                _toggle('Single use', _singleUse, (value) => _singleUse = value),
                _toggle('Allow reward redemption', _allowRewards, (value) => _allowRewards = value),
                _toggle('Allow promo stacking', _allowPromo, (value) => _allowPromo = value),
                _toggle('Allow coupon stacking', _allowCoupon, (value) => _allowCoupon = value),
                _toggle('Allow cashback', _allowCashback, (value) => _allowCashback = value),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdown<T extends Enum>(String label, T value, List<T> values, ValueChanged<T> update) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: values.map((item) => DropdownMenuItem(value: item, child: Text(_label(item.name)))).toList(),
        onChanged: (next) {
          if (next != null) setState(() => update(next));
        },
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> update) => SwitchListTile.adaptive(
        title: Text(label),
        value: value,
        onChanged: (next) => setState(() => update(next)),
      );

  Widget _text(TextEditingController controller, String label, {bool required = false, bool capitals = false, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        textCapitalization: capitals ? TextCapitalization.characters : TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) => required && (value == null || value.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _numeric(TextEditingController controller, String label, {bool required = false, bool optional = false, double? maximum}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, hintText: optional ? 'No limit' : null, border: const OutlineInputBorder()),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return required ? 'Required' : null;
          final parsed = double.tryParse(text);
          if (parsed == null) return 'Enter a valid number';
          if (parsed < 0) return 'Cannot be negative';
          if (required && parsed <= 0) return 'Must be greater than zero';
          if (maximum != null && parsed > maximum) return 'Maximum is ${_number(maximum)}';
          return null;
        },
      ),
    );
  }

  Future<void> _pickDate(bool start) async {
    final value = start ? _validFrom : _expiry;
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _validFrom = picked;
      } else {
        _expiry = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_modules.isEmpty) {
      _notice('Select at least one module.');
      return;
    }
    if (_expiry.isBefore(_validFrom)) {
      _notice('Expiry date cannot be before valid-from date.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save voucher?'),
        content: Text('Confirm ${_code.text.trim().toUpperCase()} voucher settings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final now = DateTime.now();
    final current = widget.voucher;
    Navigator.pop(
      context,
      VoucherModel(
        id: current?.id ?? 'voucher_${now.microsecondsSinceEpoch}',
        code: _code.text.trim().toUpperCase(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        type: _type,
        benefitType: _benefitType,
        status: current?.status ?? VoucherStatus.active,
        benefitValue: double.parse(_benefit.text.trim()),
        minimumAmount: double.tryParse(_minimum.text.trim()) ?? 0,
        maximumDiscount: _nullableDouble(_maximum.text),
        assignedUserId: _userId.text.trim().isEmpty ? null : _userId.text.trim(),
        supportedModules: _modules.toList(),
        isActive: _active,
        singleUse: _singleUse,
        allowRewardRedemption: _allowRewards,
        allowPromoStacking: _allowPromo,
        allowCouponStacking: _allowCoupon,
        allowCashback: _allowCashback,
        validFrom: _validFrom,
        expiryDate: _expiry,
        redeemedAt: current?.redeemedAt,
        redeemedSourceId: current?.redeemedSourceId,
        redeemedModule: current?.redeemedModule,
        createdBy: current?.createdBy ?? widget.adminId,
        createdAt: current?.createdAt ?? now,
        updatedAt: now,
        metadata: current?.metadata ?? const {},
      ),
    );
  }

  void _notice(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({required this.voucher, required this.disabled, required this.onEdit, required this.onToggle, required this.onCancel, required this.onDelete});
  final VoucherModel voucher;
  final bool disabled;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final expired = DateTime.now().isAfter(voucher.expiryDate);
    final usable = voucher.isActive && voucher.status == VoucherStatus.active && !expired;
    final color = usable ? Colors.green : Colors.grey;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(Icons.card_giftcard_rounded, color: color)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(voucher.code, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              Text(voucher.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Switch.adaptive(value: voucher.isActive, onChanged: disabled || voucher.status != VoucherStatus.active ? null : onToggle),
            PopupMenuButton<String>(
              enabled: !disabled,
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'cancel') onCancel();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (voucher.status == VoucherStatus.active) const PopupMenuItem(value: 'cancel', child: Text('Cancel voucher')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _Badge(_label(voucher.type.name)),
            _Badge(_benefit(voucher)),
            _Badge(_label(voucher.status.name), danger: voucher.status == VoucherStatus.cancelled || expired),
            _Badge(voucher.assignedUserId == null ? 'Automatic/unassigned' : 'Assigned user'),
          ]),
          const SizedBox(height: 10),
          Text('${_moduleText(voucher.supportedModules)} • ${_date(voucher.validFrom)} to ${_date(voucher.expiryDate)}', style: Theme.of(context).textTheme.bodySmall),
          if (voucher.assignedUserId != null) Text('User: ${voucher.assignedUserId}', style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.onSearch, required this.status, required this.onStatusChanged});
  final ValueChanged<String> onSearch;
  final VoucherStatus? status;
  final ValueChanged<VoucherStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          Expanded(child: TextField(onChanged: onSearch, decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search vouchers or user ID', border: OutlineInputBorder()))),
          const SizedBox(width: 10),
          DropdownButton<VoucherStatus?>(
            value: status,
            hint: const Text('All'),
            items: [const DropdownMenuItem<VoucherStatus?>(value: null, child: Text('All')), ...VoucherStatus.values.map((value) => DropdownMenuItem<VoucherStatus?>(value: value, child: Text(_label(value.name))))],
            onChanged: onStatusChanged,
          ),
        ]),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 14), child: Column(children: [ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))), const Divider(height: 1), ...children]));
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.value, required this.onTap});
  final String label;
  final DateTime value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(title: Text(label), subtitle: Text(_date(value)), trailing: const Icon(Icons.calendar_month_rounded), onTap: onTap);
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {this.danger = false});
  final String text;
  final bool danger;
  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red : Theme.of(context).colorScheme.primary;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)), child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)));
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 58), const SizedBox(height: 12), Text(text), if (action != null) ...[const SizedBox(height: 12), action!]]));
}

String _benefit(VoucherModel voucher) {
  switch (voucher.benefitType) {
    case VoucherBenefitType.percentageDiscount:
      return '${_number(voucher.benefitValue)}% off';
    case VoucherBenefitType.fixedDiscount:
      return '${_number(voucher.benefitValue)} PKR off';
    case VoucherBenefitType.freeDelivery:
      return 'Free delivery';
    case VoucherBenefitType.rewardPoints:
      return '${_number(voucher.benefitValue)} points';
  }
}

String _moduleText(List<RewardModule> modules) => modules.contains(RewardModule.all) ? 'All modules' : modules.map((value) => _label(value.name)).join(', ');
double? _nullableDouble(String value) => value.trim().isEmpty ? null : double.tryParse(value.trim());
String _number(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);
String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
String _label(String value) {
  final spaced = value.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match.group(1)} ${match.group(2)}');
  return spaced.isEmpty ? '' : spaced[0].toUpperCase() + spaced.substring(1);
}
