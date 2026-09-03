import 'package:flutter/material.dart';

import '../../rewards/models/referral_model.dart';
import '../../rewards/models/reward_point_model.dart';
import '../../rewards/services/referral_service.dart';

typedef AdminReferralLoader = Future<List<ReferralModel>> Function();

class ReferralManagerScreen extends StatefulWidget {
  const ReferralManagerScreen({
    super.key,
    required this.adminId,
    this.referralService,
    this.referralLoader,
  });

  final String adminId;
  final ReferralService? referralService;
  final AdminReferralLoader? referralLoader;

  @override
  State<ReferralManagerScreen> createState() =>
      _ReferralManagerScreenState();
}

class _ReferralManagerScreenState extends State<ReferralManagerScreen> {
  late final ReferralService _service;
  List<ReferralModel> _items = const [];
  bool _enabled = true;
  bool _loading = true;
  bool _busy = false;
  Object? _error;
  String _query = '';
  ReferralStatus? _filter;

  @override
  void initState() {
    super.initState();
    _service = widget.referralService ?? ReferralService();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final enabled = await _service.isReferralEnabled();
      final items = widget.referralLoader == null
          ? _items
          : await widget.referralLoader!();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() {
        _enabled = enabled;
        _items = items;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ReferralModel> get _filtered {
    final query = _query.trim().toLowerCase();
    return _items.where((item) {
      if (_filter != null && item.status != _filter) return false;
      if (query.isEmpty) return true;
      return item.referralCode.toLowerCase().contains(query) ||
          item.inviterUserId.toLowerCase().contains(query) ||
          (item.invitedUserId?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral Manager'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading || _busy ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: !_enabled || _busy ? null : () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create referral'),
      ),
      body: Column(
        children: [
          _MasterControl(
            enabled: _enabled,
            disabled: _busy,
            onChanged: _setEnabled,
          ),
          _Toolbar(
            filter: _filter,
            onQuery: (value) => setState(() => _query = value),
            onFilter: (value) => setState(() => _filter = value),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return _StateMessage(
        icon: Icons.cloud_off_rounded,
        text: 'Referrals could not be loaded.',
        action: FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return _StateMessage(
        icon: Icons.group_add_outlined,
        text: widget.referralLoader == null
            ? 'Admin list loader will be connected during final integration.'
            : 'No matching referrals.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return _ReferralCard(
            referral: item,
            disabled: _busy,
            onEdit: () => _openEditor(item),
            onApprove: () => _approve(item),
            onReject: () => _reject(item),
            onFraud: () => _markFraud(item),
          );
        },
      ),
    );
  }

  Future<void> _setEnabled(bool enabled) async {
    final confirmed = await _confirm(
      title: '${enabled ? 'Enable' : 'Disable'} referrals?',
      message: enabled
          ? 'New referral activity will be allowed.'
          : 'New referrals and qualification processing will stop.',
      action: enabled ? 'Enable' : 'Disable',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.setReferralEnabled(
        enabled: enabled,
        updatedBy: widget.adminId,
      );
      if (!mounted) return;
      setState(() => _enabled = enabled);
      _notice('Referral program turned ${enabled ? 'ON' : 'OFF'}.');
    } catch (error) {
      if (mounted) _notice('Could not update referral program: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openEditor([ReferralModel? referral]) async {
    final saved = await showDialog<ReferralModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ReferralEditor(
        adminId: widget.adminId,
        referral: referral,
      ),
    );
    if (saved == null || !mounted) return;
    setState(() => _busy = true);
    try {
      if (referral == null) {
        await _service.createReferral(saved);
      } else {
        await _service.updateReferral(saved);
      }
      await _load();
      if (mounted) _notice(referral == null ? 'Referral created.' : 'Referral updated.');
    } catch (error) {
      if (mounted) _notice('Could not save referral: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve(ReferralModel referral) async {
    final confirmed = await _confirm(
      title: 'Approve manual review?',
      message: 'Fraud flags will be cleared for ${referral.referralCode}.',
      action: 'Approve',
    );
    if (!confirmed || !mounted) return;
    await _runAction(() => _service.approveManualReview(
          referralId: referral.id,
          reviewedBy: widget.adminId,
        ));
  }

  Future<void> _reject(ReferralModel referral) async {
    final reason = await _askReason('Reject referral');
    if (reason == null || !mounted) return;
    await _runAction(() => _service.rejectReferral(
          referralId: referral.id,
          reason: reason,
          reviewedBy: widget.adminId,
        ));
  }

  Future<void> _markFraud(ReferralModel referral) async {
    final reason = await _askReason('Mark suspected fraud');
    if (reason == null || !mounted) return;
    await _runAction(() => _service.markFraudSuspected(
          referralId: referral.id,
          reason: reason,
          reviewedBy: widget.adminId,
        ));
  }

  Future<void> _runAction(
    Future<ReferralActionResult> Function() operation,
  ) async {
    setState(() => _busy = true);
    try {
      final result = await operation();
      if (!mounted) return;
      _notice(result.message);
      await _load();
    } catch (error) {
      if (mounted) _notice('Referral action failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askReason(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Required reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<bool> _confirm({required String title, required String message, required String action}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
            ],
          ),
        ) ??
        false;
  }

  void _notice(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _ReferralEditor extends StatefulWidget {
  const _ReferralEditor({required this.adminId, this.referral});
  final String adminId;
  final ReferralModel? referral;

  @override
  State<_ReferralEditor> createState() => _ReferralEditorState();
}

class _ReferralEditorState extends State<_ReferralEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _inviter;
  late final TextEditingController _invited;
  late final TextEditingController _requiredBookings;
  late final TextEditingController _minimumAmount;
  late final TextEditingController _inviterValue;
  late final TextEditingController _inviterBenefit;
  late final TextEditingController _invitedValue;
  late final TextEditingController _invitedBenefit;
  late RewardModule _module;
  late ReferralRewardType _inviterType;
  late ReferralRewardType _invitedType;
  DateTime? _expiry;

  @override
  void initState() {
    super.initState();
    final item = widget.referral;
    _code = TextEditingController(text: item?.referralCode ?? '');
    _inviter = TextEditingController(text: item?.inviterUserId ?? '');
    _invited = TextEditingController(text: item?.invitedUserId ?? '');
    _requiredBookings = TextEditingController(text: '${item?.requiredCompletedBookings ?? 1}');
    _minimumAmount = TextEditingController(text: _number(item?.minimumQualifyingAmount ?? 0));
    _inviterValue = TextEditingController(text: _number(item?.inviterRewardValue ?? 0));
    _inviterBenefit = TextEditingController(text: item?.inviterBenefitId ?? '');
    _invitedValue = TextEditingController(text: _number(item?.invitedUserRewardValue ?? 0));
    _invitedBenefit = TextEditingController(text: item?.invitedUserBenefitId ?? '');
    _module = item?.qualifyingModule ?? RewardModule.all;
    _inviterType = item?.inviterRewardType ?? ReferralRewardType.rewardPoints;
    _invitedType = item?.invitedUserRewardType ?? ReferralRewardType.rewardPoints;
    _expiry = item?.expiryDate;
  }

  @override
  void dispose() {
    for (final controller in [_code, _inviter, _invited, _requiredBookings, _minimumAmount, _inviterValue, _inviterBenefit, _invitedValue, _invitedBenefit]) {
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
          title: Text(widget.referral == null ? 'Create referral rule' : 'Edit referral'),
          actions: [Padding(padding: const EdgeInsets.only(right: 12), child: FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.save_rounded), label: const Text('Review & save')))],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              _Section(title: 'Referral identity', children: [
                _text(_code, 'Referral code', required: true, capitals: true),
                _text(_inviter, 'Inviter user ID', required: true),
                _text(_invited, 'Invited user ID (optional)'),
                _dropdown<RewardModule>('Qualifying module', _module, RewardModule.values.where((value) => value != RewardModule.future).toList(), (value) => _module = value),
              ]),
              _Section(title: 'Qualification rules', children: [
                _numeric(_requiredBookings, 'Required completed bookings/orders', integer: true, minimum: 1),
                _numeric(_minimumAmount, 'Minimum qualifying amount'),
                ListTile(
                  title: const Text('Expiry date'),
                  subtitle: Text(_expiry == null ? 'Never' : _date(_expiry!)),
                  trailing: Wrap(children: [
                    IconButton(onPressed: _pickExpiry, icon: const Icon(Icons.calendar_month_rounded)),
                    if (_expiry != null) IconButton(onPressed: () => setState(() => _expiry = null), icon: const Icon(Icons.clear_rounded)),
                  ]),
                ),
              ]),
              _rewardSection('Inviter reward', true),
              _rewardSection('Invited-user reward', false),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.security_rounded),
                  title: Text('Fraud protection is enforced'),
                  subtitle: Text('Phone/identity checks, idempotency and manual review prevent duplicate rewards.'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rewardSection(String title, bool inviter) {
    final type = inviter ? _inviterType : _invitedType;
    final value = inviter ? _inviterValue : _invitedValue;
    final benefit = inviter ? _inviterBenefit : _invitedBenefit;
    return _Section(title: title, children: [
      _dropdown<ReferralRewardType>('Reward type', type, ReferralRewardType.values, (next) {
        if (inviter) {
          _inviterType = next;
        } else {
          _invitedType = next;
        }
      }),
      if (type != ReferralRewardType.none)
        _numeric(value, type == ReferralRewardType.rewardPoints ? 'Points' : type == ReferralRewardType.walletCredit ? 'Wallet credit' : 'Benefit value'),
      if (type == ReferralRewardType.coupon || type == ReferralRewardType.voucher)
        _text(benefit, '${_label(type.name)} ID', required: true),
    ]);
  }

  Widget _dropdown<T extends Enum>(String label, T value, List<T> values, ValueChanged<T> update) => Padding(
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

  Widget _text(TextEditingController controller, String label, {bool required = false, bool capitals = false}) => Padding(
        padding: const EdgeInsets.all(12),
        child: TextFormField(
          controller: controller,
          textCapitalization: capitals ? TextCapitalization.characters : TextCapitalization.none,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          validator: (value) => required && (value == null || value.trim().isEmpty) ? 'Required' : null,
        ),
      );

  Widget _numeric(TextEditingController controller, String label, {bool integer = false, double minimum = 0}) => Padding(
        padding: const EdgeInsets.all(12),
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: !integer),
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          validator: (value) {
            final parsed = double.tryParse(value?.trim() ?? '');
            if (parsed == null) return 'Enter a valid number';
            if (parsed < minimum) return 'Minimum is ${_number(minimum)}';
            return null;
          },
        ),
      );

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && mounted) setState(() => _expiry = DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save referral settings?'),
        content: const Text('Rewards will only be issued after qualification and verification.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final now = DateTime.now();
    final current = widget.referral;
    Navigator.pop(context, ReferralModel(
      id: current?.id ?? 'referral_${now.microsecondsSinceEpoch}',
      referralCode: _code.text.trim().toUpperCase(),
      inviterUserId: _inviter.text.trim(),
      invitedUserId: _invited.text.trim().isEmpty ? null : _invited.text.trim(),
      status: current?.status ?? ReferralStatus.pending,
      qualifyingModule: _module,
      requiredCompletedBookings: int.parse(_requiredBookings.text.trim()),
      minimumQualifyingAmount: double.parse(_minimumAmount.text.trim()),
      inviterRewardType: _inviterType,
      inviterRewardValue: _inviterType == ReferralRewardType.none ? 0 : double.parse(_inviterValue.text.trim()),
      inviterBenefitId: _benefitId(_inviterType, _inviterBenefit.text),
      invitedUserRewardType: _invitedType,
      invitedUserRewardValue: _invitedType == ReferralRewardType.none ? 0 : double.parse(_invitedValue.text.trim()),
      invitedUserBenefitId: _benefitId(_invitedType, _invitedBenefit.text),
      inviterRewardIssued: current?.inviterRewardIssued ?? false,
      invitedUserRewardIssued: current?.invitedUserRewardIssued ?? false,
      inviterRewardTransactionId: current?.inviterRewardTransactionId,
      invitedUserRewardTransactionId: current?.invitedUserRewardTransactionId,
      completedQualifyingBookings: current?.completedQualifyingBookings ?? 0,
      phoneVerified: current?.phoneVerified ?? false,
      identityVerified: current?.identityVerified ?? false,
      requiresManualReview: current?.requiresManualReview ?? false,
      isFraudSuspected: current?.isFraudSuspected ?? false,
      reviewReason: current?.reviewReason,
      reviewedBy: current?.reviewedBy,
      idempotencyKey: current?.idempotencyKey ?? 'referral:${_code.text.trim().toUpperCase()}:${_inviter.text.trim()}',
      createdAt: current?.createdAt ?? now,
      registeredAt: current?.registeredAt,
      qualifiedAt: current?.qualifiedAt,
      rewardedAt: current?.rewardedAt,
      reviewedAt: current?.reviewedAt,
      expiryDate: _expiry,
      updatedAt: now,
      metadata: current?.metadata ?? const {},
    ));
  }

  String? _benefitId(ReferralRewardType type, String value) =>
      type == ReferralRewardType.coupon || type == ReferralRewardType.voucher
          ? value.trim()
          : null;
}

class _MasterControl extends StatelessWidget {
  const _MasterControl({required this.enabled, required this.disabled, required this.onChanged});
  final bool enabled;
  final bool disabled;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        color: (enabled ? Colors.green : Colors.orange).withValues(alpha: 0.10),
        child: SwitchListTile.adaptive(
          secondary: const Icon(Icons.group_add_rounded),
          title: Text(enabled ? 'Referral program is ON' : 'Referral program is OFF', style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: const Text('Admin confirmation is required to change this setting.'),
          value: enabled,
          onChanged: disabled ? null : onChanged,
        ),
      );
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.filter, required this.onQuery, required this.onFilter});
  final ReferralStatus? filter;
  final ValueChanged<String> onQuery;
  final ValueChanged<ReferralStatus?> onFilter;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(children: [
          Expanded(child: TextField(onChanged: onQuery, decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Code or user ID', border: OutlineInputBorder()))),
          const SizedBox(width: 10),
          DropdownButton<ReferralStatus?>(
            value: filter,
            hint: const Text('All'),
            items: [const DropdownMenuItem<ReferralStatus?>(value: null, child: Text('All')), ...ReferralStatus.values.map((value) => DropdownMenuItem<ReferralStatus?>(value: value, child: Text(_label(value.name))))],
            onChanged: onFilter,
          ),
        ]),
      );
}

class _ReferralCard extends StatelessWidget {
  const _ReferralCard({required this.referral, required this.disabled, required this.onEdit, required this.onApprove, required this.onReject, required this.onFraud});
  final ReferralModel referral;
  final bool disabled;
  final VoidCallback onEdit;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onFraud;
  @override
  Widget build(BuildContext context) {
    final danger = referral.isFraudSuspected || referral.status == ReferralStatus.rejected;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: (danger ? Colors.red : Colors.blue).withValues(alpha: 0.12), child: Icon(danger ? Icons.warning_rounded : Icons.group_add_rounded, color: danger ? Colors.red : Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(referral.referralCode, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)), Text('${referral.inviterUserId} → ${referral.invitedUserId ?? 'Not registered'}', maxLines: 1, overflow: TextOverflow.ellipsis)])),
            PopupMenuButton<String>(
              enabled: !disabled,
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'approve') onApprove();
                if (value == 'reject') onReject();
                if (value == 'fraud') onFraud();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (referral.requiresManualReview) const PopupMenuItem(value: 'approve', child: Text('Approve review')),
                if (referral.status != ReferralStatus.rejected) const PopupMenuItem(value: 'reject', child: Text('Reject')),
                if (!referral.isFraudSuspected) const PopupMenuItem(value: 'fraud', child: Text('Mark suspected fraud')),
              ],
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _Badge(_label(referral.status.name), danger: danger),
            _Badge(_label(referral.qualifyingModule.name)),
            if (referral.requiresManualReview) const _Badge('Manual review', danger: true),
            if (referral.phoneVerified) const _Badge('Phone verified'),
            if (referral.identityVerified) const _Badge('Identity verified'),
          ]),
          const SizedBox(height: 10),
          Text('Progress ${referral.completedQualifyingBookings}/${referral.requiredCompletedBookings} • Inviter: ${_reward(referral.inviterRewardType, referral.inviterRewardValue)} • Invited: ${_reward(referral.invitedUserRewardType, referral.invitedUserRewardValue)}', style: Theme.of(context).textTheme.bodySmall),
          if (referral.reviewReason != null) Text('Review: ${referral.reviewReason}', style: const TextStyle(color: Colors.red)),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 14), child: Column(children: [ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))), const Divider(height: 1), ...children]));
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

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 58), const SizedBox(height: 12), Text(text, textAlign: TextAlign.center), if (action != null) ...[const SizedBox(height: 12), action!]])));
}

String _reward(ReferralRewardType type, double value) => type == ReferralRewardType.none ? 'None' : '${_number(value)} ${_label(type.name)}';
String _number(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);
String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
String _label(String value) {
  final spaced = value.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match.group(1)} ${match.group(2)}');
  return spaced.isEmpty ? '' : spaced[0].toUpperCase() + spaced.substring(1);
}
