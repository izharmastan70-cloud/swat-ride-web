import 'package:flutter/material.dart';

import '../../rewards/models/coupon_model.dart';
import '../../rewards/models/global_promo_code_model.dart';
import '../../rewards/models/reward_point_model.dart';
import '../../rewards/services/coupon_service.dart';

class CouponManagerScreen extends StatefulWidget {
  const CouponManagerScreen({
    super.key,
    required this.adminId,
    this.couponService,
  });

  final String adminId;
  final CouponService? couponService;

  @override
  State<CouponManagerScreen> createState() =>
      _CouponManagerScreenState();
}

class _CouponManagerScreenState extends State<CouponManagerScreen> {
  late final CouponService _service;
  late Stream<List<CouponModel>> _stream;
  String _query = '';
  bool _activeOnly = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _service = widget.couponService ?? CouponService();
    _refreshStream();
  }

  void _refreshStream() {
    _stream = _service.watchCoupons(activeOnly: _activeOnly);
  }

  void _refresh() {
    setState(_refreshStream);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coupon Manager'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create coupon'),
      ),
      body: Column(
        children: [
          _Toolbar(
            query: _query,
            activeOnly: _activeOnly,
            onQueryChanged: (value) => setState(() => _query = value),
            onActiveOnlyChanged: (value) {
              setState(() {
                _activeOnly = value;
                _refreshStream();
              });
            },
          ),
          Expanded(
            child: StreamBuilder<List<CouponModel>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ErrorState(onRetry: _refresh);
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final query = _query.trim().toLowerCase();
                final coupons = snapshot.data!.where((coupon) {
                  if (query.isEmpty) return true;
                  return coupon.code.toLowerCase().contains(query) ||
                      coupon.title.toLowerCase().contains(query) ||
                      coupon.description.toLowerCase().contains(query);
                }).toList();
                if (coupons.isEmpty) {
                  return _EmptyState(
                    filtered: query.isNotEmpty || _activeOnly,
                    onCreate: () => _openEditor(),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: coupons.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) => _CouponCard(
                      coupon: coupons[index],
                      disabled: _busy,
                      onEdit: () => _openEditor(coupons[index]),
                      onToggle: (value) =>
                          _setActive(coupons[index], value),
                      onDelete: () => _delete(coupons[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor([CouponModel? coupon]) async {
    final saved = await showDialog<CouponModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CouponEditorDialog(
        adminId: widget.adminId,
        coupon: coupon,
      ),
    );
    if (saved == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.saveCoupon(saved);
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(coupon == null
              ? 'Coupon created successfully.'
              : 'Coupon updated successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save coupon: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setActive(CouponModel coupon, bool value) async {
    setState(() => _busy = true);
    try {
      await _service.setCouponActive(couponId: coupon.id, isActive: value);
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${coupon.code} turned ${value ? 'ON' : 'OFF'}.' )),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update coupon: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(CouponModel coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete coupon permanently?'),
        content: Text(
          '${coupon.code} will be permanently deleted. Usage history should remain in reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.deleteCoupon(coupon.id);
      if (!mounted) return;
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coupon deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete coupon: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _CouponEditorDialog extends StatefulWidget {
  const _CouponEditorDialog({required this.adminId, this.coupon});
  final String adminId;
  final CouponModel? coupon;

  @override
  State<_CouponEditorDialog> createState() => _CouponEditorDialogState();
}

class _CouponEditorDialogState extends State<_CouponEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _discount;
  late final TextEditingController _minimum;
  late final TextEditingController _maximum;
  late final TextEditingController _totalLimit;
  late final TextEditingController _userLimit;
  late final TextEditingController _assignedUsers;
  late final TextEditingController _loyaltyLevels;

  late GlobalPromoDiscountType _discountType;
  late CouponDistributionType _distributionType;
  late Set<RewardModule> _modules;
  late bool _active;
  late bool _singleUse;
  late bool _allowRewards;
  late bool _allowPromo;
  late bool _allowVoucher;
  late bool _allowCashback;
  DateTime? _start;
  DateTime? _expiry;

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
    final coupon = widget.coupon;
    _code = TextEditingController(text: coupon?.code ?? '');
    _title = TextEditingController(text: coupon?.title ?? '');
    _description = TextEditingController(text: coupon?.description ?? '');
    _discount = TextEditingController(
      text: coupon == null ? '' : _number(coupon.discountValue),
    );
    _minimum = TextEditingController(
      text: coupon == null ? '0' : _number(coupon.minimumAmount),
    );
    _maximum = TextEditingController(
      text: coupon?.maximumDiscount == null
          ? ''
          : _number(coupon!.maximumDiscount!),
    );
    _totalLimit = TextEditingController(
      text: coupon?.totalUsageLimit?.toString() ?? '',
    );
    _userLimit = TextEditingController(
      text: coupon?.usageLimitPerUser?.toString() ?? '1',
    );
    _assignedUsers = TextEditingController(
      text: coupon?.assignedUserIds.join(', ') ?? '',
    );
    _loyaltyLevels = TextEditingController(
      text: coupon?.requiredLoyaltyLevelIds.join(', ') ?? '',
    );
    _discountType = coupon?.discountType ?? GlobalPromoDiscountType.percentage;
    _distributionType = coupon?.distributionType ?? CouponDistributionType.public;
    _modules = coupon == null
        ? {RewardModule.all}
        : Set<RewardModule>.from(coupon.supportedModules);
    _active = coupon?.isActive ?? true;
    _singleUse = coupon?.singleUsePerUser ?? true;
    _allowRewards = coupon?.allowRewardRedemption ?? false;
    _allowPromo = coupon?.allowPromoStacking ?? false;
    _allowVoucher = coupon?.allowVoucherStacking ?? false;
    _allowCashback = coupon?.allowCashback ?? true;
    _start = coupon?.startDate;
    _expiry = coupon?.expiryDate;
  }

  @override
  void dispose() {
    for (final controller in [
      _code,
      _title,
      _description,
      _discount,
      _minimum,
      _maximum,
      _totalLimit,
      _userLimit,
      _assignedUsers,
      _loyaltyLevels,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.coupon != null;
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
          title: Text(editing ? 'Edit coupon' : 'Create coupon'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Review & save'),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              _FormSection(
                title: 'Coupon details',
                children: [
                  _text(_code, 'Coupon code', required: true, uppercase: true),
                  _text(_title, 'Title', required: true),
                  _text(_description, 'Description', lines: 3),
                  SwitchListTile.adaptive(
                    title: const Text('Coupon active'),
                    value: _active,
                    onChanged: (value) => setState(() => _active = value),
                  ),
                ],
              ),
              _FormSection(
                title: 'Discount',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: DropdownButtonFormField<GlobalPromoDiscountType>(
                      initialValue: _discountType,
                      decoration: const InputDecoration(
                        labelText: 'Discount type',
                        border: OutlineInputBorder(),
                      ),
                      items: GlobalPromoDiscountType.values
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(_label(value.name)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _discountType = value);
                      },
                    ),
                  ),
                  _numeric(_discount, 'Discount value', required: true, maximum: _discountType == GlobalPromoDiscountType.percentage ? 100 : null),
                  _numeric(_minimum, 'Minimum booking/order amount', required: true),
                  _numeric(_maximum, 'Maximum discount', optional: true),
                ],
              ),
              _FormSection(
                title: 'Availability',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: DropdownButtonFormField<CouponDistributionType>(
                      initialValue: _distributionType,
                      decoration: const InputDecoration(
                        labelText: 'Distribution type',
                        border: OutlineInputBorder(),
                      ),
                      items: CouponDistributionType.values
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(_label(value.name)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _distributionType = value);
                      },
                    ),
                  ),
                  if (_distributionType == CouponDistributionType.selectedUsers ||
                      _distributionType == CouponDistributionType.manual)
                    _text(_assignedUsers, 'Assigned user IDs (comma separated)', required: true),
                  if (_distributionType == CouponDistributionType.loyaltyLevel)
                    _text(_loyaltyLevels, 'Loyalty level IDs (comma separated)', required: true),
                  _DateTile(label: 'Start date', value: _start, onPick: () => _pickDate(start: true), onClear: () => setState(() => _start = null)),
                  _DateTile(label: 'Expiry date', value: _expiry, onPick: () => _pickDate(start: false), onClear: () => setState(() => _expiry = null)),
                ],
              ),
              _FormSection(
                title: 'Supported modules',
                children: [
                  CheckboxListTile(
                    title: const Text('All current and future modules'),
                    value: _modules.contains(RewardModule.all),
                    onChanged: (value) => setState(() {
                      if (value == true) {
                        _modules = {RewardModule.all};
                      } else {
                        _modules = {};
                      }
                    }),
                  ),
                  if (!_modules.contains(RewardModule.all))
                    ..._availableModules.map((module) => CheckboxListTile(
                          title: Text(_label(module.name)),
                          value: _modules.contains(module),
                          onChanged: (value) => setState(() {
                            value == true ? _modules.add(module) : _modules.remove(module);
                          }),
                        )),
                ],
              ),
              _FormSection(
                title: 'Usage limits',
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Single use per user'),
                    value: _singleUse,
                    onChanged: (value) => setState(() {
                      _singleUse = value;
                      if (value) _userLimit.text = '1';
                    }),
                  ),
                  _numeric(_totalLimit, 'Total usage limit', optional: true, integer: true),
                  _numeric(_userLimit, 'Usage limit per user', optional: true, integer: true),
                ],
              ),
              _FormSection(
                title: 'Stacking rules',
                children: [
                  _toggle('Allow reward redemption', _allowRewards, (value) => _allowRewards = value),
                  _toggle('Allow promo stacking', _allowPromo, (value) => _allowPromo = value),
                  _toggle('Allow voucher stacking', _allowVoucher, (value) => _allowVoucher = value),
                  _toggle('Allow cashback', _allowCashback, (value) => _allowCashback = value),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggle(String title, bool value, ValueChanged<bool> update) {
    return SwitchListTile.adaptive(
      title: Text(title),
      value: value,
      onChanged: (next) => setState(() => update(next)),
    );
  }

  Widget _text(TextEditingController controller, String label, {bool required = false, bool uppercase = false, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) => required && (value == null || value.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _numeric(TextEditingController controller, String label, {bool required = false, bool optional = false, bool integer = false, double? maximum}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: !integer),
        decoration: InputDecoration(labelText: label, hintText: optional ? 'No limit' : null, border: const OutlineInputBorder()),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty) return required ? 'Required' : null;
          final number = integer ? int.tryParse(text)?.toDouble() : double.tryParse(text);
          if (number == null) return 'Enter a valid number';
          if (number < 0) return 'Cannot be negative';
          if (maximum != null && number > maximum) return 'Maximum is ${_number(maximum)}';
          return null;
        },
      ),
    );
  }

  Future<void> _pickDate({required bool start}) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: (start ? _start : _expiry) ?? DateTime.now(),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (start) {
        _start = selected;
      } else {
        _expiry = DateTime(selected.year, selected.month, selected.day, 23, 59, 59);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_modules.isEmpty) {
      _message('Select at least one module.');
      return;
    }
    if (_start != null && _expiry != null && _expiry!.isBefore(_start!)) {
      _message('Expiry date cannot be before start date.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save coupon?'),
        content: Text('Confirm ${_code.text.trim().toUpperCase()} coupon settings.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final now = DateTime.now();
    final current = widget.coupon;
    Navigator.pop(
      context,
      CouponModel(
        id: current?.id ?? 'coupon_${now.microsecondsSinceEpoch}',
        code: _code.text.trim().toUpperCase(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        discountType: _discountType,
        discountValue: double.parse(_discount.text.trim()),
        minimumAmount: double.tryParse(_minimum.text.trim()) ?? 0,
        maximumDiscount: _nullableDouble(_maximum.text),
        supportedModules: _modules.toList(),
        distributionType: _distributionType,
        assignedUserIds: _csv(_assignedUsers.text),
        requiredLoyaltyLevelIds: _csv(_loyaltyLevels.text),
        isActive: _active,
        singleUsePerUser: _singleUse,
        allowRewardRedemption: _allowRewards,
        allowPromoStacking: _allowPromo,
        allowVoucherStacking: _allowVoucher,
        allowCashback: _allowCashback,
        totalUsageLimit: _nullableInt(_totalLimit.text),
        usageLimitPerUser: _singleUse ? 1 : _nullableInt(_userLimit.text),
        usedCount: current?.usedCount ?? 0,
        startDate: _start,
        expiryDate: _expiry,
        createdBy: current?.createdBy ?? widget.adminId,
        createdAt: current?.createdAt ?? now,
        updatedAt: now,
        metadata: current?.metadata ?? const {},
      ),
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.coupon, required this.disabled, required this.onEdit, required this.onToggle, required this.onDelete});
  final CouponModel coupon;
  final bool disabled;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final expired = coupon.expiryDate != null && DateTime.now().isAfter(coupon.expiryDate!);
    final color = coupon.isActive && !expired ? Colors.green : Colors.grey;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(Icons.local_offer_rounded, color: color)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                  Text(coupon.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Switch.adaptive(value: coupon.isActive, onChanged: disabled ? null : onToggle),
                PopupMenuButton<String>(
                  enabled: !disabled,
                  onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _Badge(_discountLabel(coupon)),
              _Badge(_label(coupon.distributionType.name)),
              _Badge(coupon.singleUsePerUser ? 'Single use' : 'Multiple use'),
              if (expired) const _Badge('Expired', danger: true),
            ]),
            const SizedBox(height: 10),
            Text('Used ${coupon.usedCount}${coupon.totalUsageLimit == null ? '' : ' / ${coupon.totalUsageLimit}'} • ${_moduleLabel(coupon.supportedModules)}', style: Theme.of(context).textTheme.bodySmall),
            if (coupon.expiryDate != null)
              Text('Expires ${_date(coupon.expiryDate!)}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.query, required this.activeOnly, required this.onQueryChanged, required this.onActiveOnlyChanged});
  final String query;
  final bool activeOnly;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<bool> onActiveOnlyChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(child: TextField(onChanged: onQueryChanged, decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search coupons', border: OutlineInputBorder()))),
          const SizedBox(width: 10),
          FilterChip(label: const Text('Active only'), selected: activeOnly, onSelected: onActiveOnlyChanged),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Column(children: [ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))), const Divider(height: 1), ...children]),
      );
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.value, required this.onPick, required this.onClear});
  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(label),
        subtitle: Text(value == null ? 'Not set' : _date(value!)),
        onTap: onPick,
        trailing: value == null ? const Icon(Icons.calendar_month_rounded) : IconButton(onPressed: onClear, icon: const Icon(Icons.clear_rounded)),
      );
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {this.danger = false});
  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: (danger ? Colors.red : Theme.of(context).colorScheme.primary).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: danger ? Colors.red : Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered, required this.onCreate});
  final bool filtered;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.local_offer_outlined, size: 62),
        const SizedBox(height: 12),
        Text(filtered ? 'No matching coupons' : 'No coupons created'),
        const SizedBox(height: 12),
        if (!filtered) FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.add_rounded), label: const Text('Create coupon')),
      ]));
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 54),
        const SizedBox(height: 12),
        const Text('Coupons could not be loaded.'),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
      ]));
}

String _discountLabel(CouponModel coupon) {
  switch (coupon.discountType) {
    case GlobalPromoDiscountType.percentage:
      return '${_number(coupon.discountValue)}% off';
    case GlobalPromoDiscountType.fixedAmount:
      return '${_number(coupon.discountValue)} PKR off';
    case GlobalPromoDiscountType.freeDelivery:
      return 'Free delivery';
  }
}

String _moduleLabel(List<RewardModule> modules) => modules.contains(RewardModule.all)
    ? 'All modules'
    : modules.map((value) => _label(value.name)).join(', ');

List<String> _csv(String value) => value.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toSet().toList();
double? _nullableDouble(String value) => value.trim().isEmpty ? null : double.tryParse(value.trim());
int? _nullableInt(String value) => value.trim().isEmpty ? null : int.tryParse(value.trim());
String _number(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);
String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
String _label(String value) {
  final spaced = value.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match.group(1)} ${match.group(2)}');
  return spaced.isEmpty ? '' : spaced[0].toUpperCase() + spaced.substring(1);
}
