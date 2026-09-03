import 'package:flutter/material.dart';

import '../../rewards/models/loyalty_level_model.dart';
import '../../rewards/models/reward_point_model.dart';

typedef LoyaltyLevelSaveCallback = Future<void> Function(LoyaltyLevelModel level);
typedef LoyaltyLevelDeleteCallback = Future<void> Function(String levelId);

class LoyaltyLevelsScreen extends StatefulWidget {
  final List<LoyaltyLevelModel> initialLevels;
  final LoyaltyLevelSaveCallback? onSave;
  final LoyaltyLevelDeleteCallback? onDelete;

  const LoyaltyLevelsScreen({
    super.key,
    this.initialLevels = const [],
    this.onSave,
    this.onDelete,
  });

  @override
  State<LoyaltyLevelsScreen> createState() =>
      _LoyaltyLevelsAdminScreenState();
}

class _LoyaltyLevelsAdminScreenState
    extends State<LoyaltyLevelsScreen> {
  static const _navy = Color(0xFF09233F);
  static const _blue = Color(0xFF1264E5);
  static const _background = Color(0xFFF5F7FB);

  late List<LoyaltyLevelModel> _levels;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _levels = [...widget.initialLevels];
  }

  List<LoyaltyLevelModel> get _visibleLevels {
    final query = _query.trim().toLowerCase();
    return _levels.where((level) {
      return query.isEmpty ||
          level.name.toLowerCase().contains(query) ||
          level.description.toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }

  Future<void> _openEditor([LoyaltyLevelModel? level]) async {
    final result = await showDialog<LoyaltyLevelModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LevelEditor(level: level),
    );
    if (result != null) await _save(result);
  }

  Future<void> _save(LoyaltyLevelModel level) async {
    if (level.isDefaultLevel &&
        _levels.any((item) =>
            item.id != level.id && item.isDefaultLevel)) {
      _message('Only one default loyalty level is allowed.', error: true);
      return;
    }
    try {
      await widget.onSave?.call(level);
      if (!mounted) return;
      setState(() {
        final index = _levels.indexWhere((item) => item.id == level.id);
        if (index < 0) {
          _levels.add(level);
        } else {
          _levels[index] = level;
        }
      });
      _message('Loyalty level saved.');
    } catch (error) {
      if (mounted) _message('Save failed: $error', error: true);
    }
  }

  Future<void> _delete(LoyaltyLevelModel level) async {
    if (level.isDefaultLevel) {
      _message('Default level cannot be deleted. Set another default first.',
          error: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete loyalty level?'),
        content: Text('“${level.name}” permanently delete ho jayega.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.onDelete?.call(level.id);
      if (!mounted) return;
      setState(() => _levels.removeWhere((item) => item.id == level.id));
      _message('Loyalty level deleted.');
    } catch (error) {
      if (mounted) _message('Delete failed: $error', error: true);
    }
  }

  void _message(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _levels.where((level) => level.isActive).length;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Loyalty Levels'),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New level'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total levels',
                  value: '${_levels.length}',
                  icon: Icons.workspace_premium_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Active levels',
                  value: '$activeCount',
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search loyalty levels',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          const _InfoCard(),
          const SizedBox(height: 16),
          if (_visibleLevels.isEmpty)
            const _EmptyState()
          else
            ..._visibleLevels.map(
              (level) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LevelCard(
                  level: level,
                  onEdit: () => _openEditor(level),
                  onDelete: () => _delete(level),
                  onActiveChanged: (value) => _save(
                    level.copyWith(
                      isActive: value,
                      updatedAt: DateTime.now(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelEditor extends StatefulWidget {
  final LoyaltyLevelModel? level;
  const _LevelEditor({this.level});

  @override
  State<_LevelEditor> createState() => _LevelEditorState();
}

class _LevelEditorState extends State<_LevelEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _order;
  late final TextEditingController _minimumPoints;
  late final TextEditingController _maximumPoints;
  late final TextEditingController _minimumBookings;
  late final TextEditingController _multiplier;
  late final TextEditingController _cashbackBonus;
  late final TextEditingController _discount;
  late final TextEditingController _maximumDiscount;
  late final TextEditingController _badgeName;
  late final TextEditingController _badgeIconUrl;
  late final TextEditingController _colorHex;
  late final TextEditingController _benefit;

  late bool _active;
  late bool _defaultLevel;
  late bool _prioritySupport;
  late bool _freeDelivery;
  late bool _exclusiveOffers;
  late Set<RewardModule> _modules;
  late List<String> _benefits;

  static const _moduleChoices = <RewardModule>[
    RewardModule.ride,
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
    final level = widget.level;
    _name = TextEditingController(text: level?.name ?? '');
    _description = TextEditingController(text: level?.description ?? '');
    _order = TextEditingController(text: level?.displayOrder.toString() ?? '0');
    _minimumPoints = TextEditingController(
        text: level?.minimumLifetimePoints.toString() ?? '0');
    _maximumPoints = TextEditingController(
        text: level?.maximumLifetimePoints?.toString() ?? '');
    _minimumBookings = TextEditingController(
        text: level?.minimumCompletedBookings.toString() ?? '0');
    _multiplier = TextEditingController(
        text: level?.pointsEarningMultiplier.toString() ?? '1');
    _cashbackBonus = TextEditingController(
        text: level?.cashbackBonusPercentage.toString() ?? '0');
    _discount = TextEditingController(
        text: level?.levelDiscountPercentage.toString() ?? '0');
    _maximumDiscount = TextEditingController(
        text: level?.maximumLevelDiscount?.toString() ?? '');
    _badgeName = TextEditingController(text: level?.badgeName ?? '');
    _badgeIconUrl = TextEditingController(text: level?.badgeIconUrl ?? '');
    _colorHex =
        TextEditingController(text: level?.colorHex ?? '#CD7F32');
    _benefit = TextEditingController();
    _active = level?.isActive ?? true;
    _defaultLevel = level?.isDefaultLevel ?? false;
    _prioritySupport = level?.prioritySupportEnabled ?? false;
    _freeDelivery = level?.freeDeliveryEnabled ?? false;
    _exclusiveOffers = level?.exclusiveOffersEnabled ?? false;
    _benefits = [...?level?.benefits];
    _modules = {...?level?.supportedModules};
    if (_modules.contains(RewardModule.all)) _modules = {..._moduleChoices};
    if (_modules.isEmpty) _modules = {..._moduleChoices};
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _description,
      _order,
      _minimumPoints,
      _maximumPoints,
      _minimumBookings,
      _multiplier,
      _cashbackBonus,
      _discount,
      _maximumDiscount,
      _badgeName,
      _badgeIconUrl,
      _colorHex,
      _benefit,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  int? _int(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : int.tryParse(value);
  }

  double? _double(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : double.tryParse(value);
  }

  String? _nonNegative(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    return number == null || number < 0 ? 'Enter 0 or greater' : null;
  }

  String? _optionalNonNegative(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _nonNegative(value);
  }

  String? _percentage(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || number < 0 || number > 100) {
      return 'Enter percentage from 0 to 100';
    }
    return null;
  }

  String? _positive(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    return number == null || number <= 0 ? 'Enter value greater than 0' : null;
  }

  void _addBenefit() {
    final value = _benefit.text.trim();
    if (value.isEmpty || _benefits.contains(value)) return;
    setState(() {
      _benefits.add(value);
      _benefit.clear();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_modules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one module.')),
      );
      return;
    }
    final minimum = _int(_minimumPoints) ?? 0;
    final maximum = _int(_maximumPoints);
    if (maximum != null && maximum < minimum) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Maximum points cannot be below minimum points.')),
      );
      return;
    }
    final now = DateTime.now();
    final old = widget.level;
    Navigator.pop(
      context,
      LoyaltyLevelModel(
        id: old?.id ?? 'loyalty_${now.microsecondsSinceEpoch}',
        name: _name.text.trim(),
        description: _description.text.trim(),
        displayOrder: _int(_order) ?? 0,
        minimumLifetimePoints: minimum,
        maximumLifetimePoints: maximum,
        minimumCompletedBookings: _int(_minimumBookings) ?? 0,
        pointsEarningMultiplier: _double(_multiplier) ?? 1,
        cashbackBonusPercentage: _double(_cashbackBonus) ?? 0,
        levelDiscountPercentage: _double(_discount) ?? 0,
        maximumLevelDiscount: _double(_maximumDiscount),
        supportedModules: _modules.length == _moduleChoices.length
            ? const [RewardModule.all]
            : _modules.toList(),
        benefits: _benefits,
        badgeName: _badgeName.text.trim(),
        badgeIconUrl: _badgeIconUrl.text.trim(),
        colorHex: _colorHex.text.trim(),
        isActive: _active,
        isDefaultLevel: _defaultLevel,
        prioritySupportEnabled: _prioritySupport,
        freeDeliveryEnabled: _freeDelivery,
        exclusiveOffersEnabled: _exclusiveOffers,
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
          title: Text(widget.level == null
              ? 'Create Loyalty Level'
              : 'Edit Loyalty Level'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(onPressed: _submit, child: const Text('SAVE')),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _heading('Basic settings'),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Level name (Bronze, Gold, VIP)'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Level name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _order,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Display order'),
                validator: _nonNegative,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Level active'),
                value: _active,
                onChanged: (value) => setState(() => _active = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Default starting level'),
                subtitle: const Text('Only one level can be default.'),
                value: _defaultLevel,
                onChanged: (value) => setState(() => _defaultLevel = value),
              ),
              _heading('Qualification'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minimumPoints,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Minimum points'),
                      validator: _nonNegative,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _maximumPoints,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Maximum points (optional)'),
                      validator: _optionalNonNegative,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minimumBookings,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Minimum completed bookings/orders'),
                validator: _nonNegative,
              ),
              _heading('Rewards and discounts'),
              TextFormField(
                controller: _multiplier,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Points multiplier (1, 1.5, 2)'),
                validator: _positive,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cashbackBonus,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Cashback bonus %'),
                      validator: _percentage,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _discount,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Level discount %'),
                      validator: _percentage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maximumDiscount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Maximum level discount PKR (optional)'),
                validator: _optionalNonNegative,
              ),
              _heading('Valid modules'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _moduleChoices.map((module) {
                  return FilterChip(
                    label: Text(_label(module.name)),
                    selected: _modules.contains(module),
                    onSelected: (selected) {
                      setState(() => selected
                          ? _modules.add(module)
                          : _modules.remove(module));
                    },
                  );
                }).toList(),
              ),
              _heading('Special benefits'),
              _toggle(
                'Priority support',
                _prioritySupport,
                (value) => _prioritySupport = value,
              ),
              _toggle(
                'Free delivery',
                _freeDelivery,
                (value) => _freeDelivery = value,
              ),
              _toggle(
                'Exclusive offers',
                _exclusiveOffers,
                (value) => _exclusiveOffers = value,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _benefit,
                      decoration:
                          const InputDecoration(labelText: 'Custom benefit'),
                      onSubmitted: (_) => _addBenefit(),
                    ),
                  ),
                  IconButton(
                    onPressed: _addBenefit,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              if (_benefits.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _benefits.map((benefit) {
                    return InputChip(
                      label: Text(benefit),
                      onDeleted: () =>
                          setState(() => _benefits.remove(benefit)),
                    );
                  }).toList(),
                ),
              ],
              _heading('Badge appearance'),
              TextFormField(
                controller: _badgeName,
                decoration: const InputDecoration(labelText: 'Badge name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorHex,
                decoration:
                    const InputDecoration(labelText: 'Badge color (#CD7F32)'),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(text)
                      ? null
                      : 'Use six-digit HEX color, e.g. #CD7F32';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _badgeIconUrl,
                decoration:
                    const InputDecoration(labelText: 'Badge icon URL (optional)'),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save loyalty level'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF09233F),
          ),
        ),
      );

  Widget _toggle(
    String title,
    bool value,
    ValueChanged<bool> update,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: (changed) => setState(() => update(changed)),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final LoyaltyLevelModel level;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onActiveChanged;

  const _LevelCard({
    required this.level,
    required this.onEdit,
    required this.onDelete,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = _hexColor(level.colorHex);
    final maximum = level.maximumLifetimePoints == null
        ? 'No maximum'
        : '${level.maximumLifetimePoints} points maximum';
    final modules = level.supportedModules.contains(RewardModule.all)
        ? 'All modules'
        : level.supportedModules.map((module) => _label(module.name)).join(', ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.16),
                  child: Icon(Icons.workspace_premium, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              level.name,
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (level.isDefaultLevel) ...[
                            const SizedBox(width: 6),
                            const Chip(label: Text('Default')),
                          ],
                        ],
                      ),
                      Text('Order ${level.displayOrder}'),
                    ],
                  ),
                ),
                Switch(value: level.isActive, onChanged: onActiveChanged),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${level.minimumLifetimePoints} points minimum • $maximum',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              '${level.pointsEarningMultiplier}x points • ${level.cashbackBonusPercentage}% cashback bonus • ${level.levelDiscountPercentage}% discount',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 5),
            Text(modules, maxLines: 2, overflow: TextOverflow.ellipsis),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1264E5)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w800)),
                Text(label, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: Color(0xFFEAF3FF),
      child: ListTile(
        leading: Icon(Icons.info_outline, color: Color(0xFF1264E5)),
        title: Text('Lower display order appears first.'),
        subtitle: Text(
            'Keep point ranges separate and select only one default level.'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(Icons.workspace_premium_outlined,
              size: 58, color: Colors.black26),
          SizedBox(height: 12),
          Text('No loyalty levels found',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

Color _hexColor(String value) {
  final cleaned = value.replaceAll('#', '').trim();
  final parsed = int.tryParse('FF$cleaned', radix: 16);
  return parsed == null ? const Color(0xFF1264E5) : Color(parsed);
}

String _label(String value) {
  final spaced = value.replaceAllMapped(
    RegExp(r'([A-Z])'),
    (match) => ' ${match.group(1)}',
  );
  return spaced.isEmpty
      ? spaced
      : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}
