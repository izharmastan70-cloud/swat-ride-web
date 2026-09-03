import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/student_ride_package_model.dart';
import '../../services/student_ride_package_service.dart';

class StudentRideAdminPackageManagementScreen extends StatefulWidget {
  const StudentRideAdminPackageManagementScreen({super.key});

  @override
  State<StudentRideAdminPackageManagementScreen> createState() =>
      _StudentRideAdminPackageManagementScreenState();
}

class _StudentRideAdminPackageManagementScreenState
    extends State<StudentRideAdminPackageManagementScreen> {
  final StudentRidePackageService _service = StudentRidePackageService();
  String? _busyPackageId;

  String get _adminId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Admin is not logged in.');
    return user.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Ride Packages')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Package'),
      ),
      body: StreamBuilder<List<StudentRidePackageModel>>(
        stream: _service.watchAllPackagesForAdmin(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageView(
              icon: Icons.error_outline_rounded,
              message: 'Packages could not be loaded.\n${snapshot.error}',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final packages = snapshot.data!;
          if (packages.isEmpty) {
            return const _MessageView(
              icon: Icons.inventory_2_outlined,
              message: 'No Student Ride packages found.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
            itemCount: packages.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final package = packages[index];
              return _PackageCard(
                package: package,
                isBusy: _busyPackageId == package.packageId,
                onEdit: () => _openEditor(package),
                onToggle: (enabled) => _togglePackage(package, enabled),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor([StudentRidePackageModel? package]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _PackageEditorScreen(
          service: _service,
          adminId: _adminId,
          package: package,
        ),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(package == null ? 'Package created.' : 'Package updated.'),
        ),
      );
    }
  }

  Future<void> _togglePackage(
    StudentRidePackageModel package,
    bool enabled,
  ) async {
    if (_busyPackageId != null) return;
    String disabledMessage = package.disabledMessage;

    if (!enabled) {
      final controller = TextEditingController(text: disabledMessage);
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Disable package?'),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Message for parents',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Disable'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (result == null) return;
      disabledMessage = result;
    }

    setState(() => _busyPackageId = package.packageId);
    try {
      await _service.setPackageEnabled(
        packageId: package.packageId,
        enabled: enabled,
        adminId: _adminId,
        disabledMessage: disabledMessage,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyPackageId = null);
    }
  }
}

class _PackageEditorScreen extends StatefulWidget {
  const _PackageEditorScreen({
    required this.service,
    required this.adminId,
    this.package,
  });

  final StudentRidePackageService service;
  final String adminId;
  final StudentRidePackageModel? package;

  @override
  State<_PackageEditorScreen> createState() => _PackageEditorScreenState();
}

class _PackageEditorScreenState extends State<_PackageEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  late StudentRidePackageTripType _tripType;
  late StudentRidePackagePriceMode _priceMode;
  late Set<int> _weekdays;
  late bool _enabled;
  late bool _doorToDoor;
  late bool _sharedVehicle;
  late bool _siblingDiscount;
  late bool _autoRenew;
  late bool _pauseAllowed;
  late bool _cancellationAllowed;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final package = widget.package;
    _tripType = package?.tripType ?? StudentRidePackageTripType.twoWay;
    _priceMode = package?.priceMode ?? StudentRidePackagePriceMode.fixedMonthly;
    _weekdays = (package?.operatingWeekdays ?? const [1, 2, 3, 4, 5]).toSet();
    _enabled = package?.isEnabled ?? true;
    _doorToDoor = package?.doorToDoor ?? true;
    _sharedVehicle = package?.sharedVehicle ?? true;
    _siblingDiscount = package?.siblingDiscountAllowed ?? false;
    _autoRenew = package?.autoRenewAllowed ?? true;
    _pauseAllowed = package?.pauseAllowed ?? false;
    _cancellationAllowed = package?.cancellationAllowed ?? true;
    _set('name', package?.name);
    _set('description', package?.description);
    _set('schoolIds', package?.schoolIds.join(', '));
    _set('routeIds', package?.routeIds.join(', '));
    _set('vehicleTypes', package?.vehicleTypes.join(', '));
    _set('basePrice', (package?.basePrice ?? 0).toString());
    _set('perKmPrice', (package?.perKmPrice ?? 0).toString());
    _set('perDayPrice', (package?.perDayPrice ?? 0).toString());
    _set('doorToDoorCharge', (package?.doorToDoorCharge ?? 0).toString());
    _set('registrationFee', (package?.registrationFee ?? 0).toString());
    _set(
      'siblingDiscountPercent',
      (package?.siblingDiscountPercent ?? 0).toString(),
    );
    _set(
      'maximumDiscountAmount',
      (package?.maximumDiscountAmount ?? 0).toString(),
    );
    _set('currencyCode', package?.currencyCode ?? 'PKR');
    _set('minimumDays', (package?.minimumDays ?? 1).toString());
    _set('maximumStudents', (package?.maximumStudents ?? 1).toString());
    _set('paymentDueDay', (package?.paymentDueDay ?? 5).toString());
    _set('paymentGraceDays', (package?.paymentGraceDays ?? 3).toString());
    _set('displayOrder', (package?.displayOrder ?? 0).toString());
    _set('disabledMessage', package?.disabledMessage);
  }

  void _set(String key, String? value) {
    _controllers[key] = TextEditingController(text: value ?? '');
  }

  String _text(String key) => _controllers[key]!.text.trim();
  double _double(String key) => double.tryParse(_text(key)) ?? 0;
  int _int(String key) => int.tryParse(_text(key)) ?? 0;

  List<String> _list(String key) => _text(key)
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.package == null ? 'Create Package' : 'Edit Package'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _section('Package'),
            _field('name', 'Package name', required: true),
            _field('description', 'Description', lines: 3),
            DropdownButtonFormField<StudentRidePackageTripType>(
              initialValue: _tripType,
              decoration: const InputDecoration(
                labelText: 'Trip type',
                border: OutlineInputBorder(),
              ),
              items: StudentRidePackageTripType.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(_tripTypeLabel(value)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _tripType = value!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<StudentRidePackagePriceMode>(
              initialValue: _priceMode,
              decoration: const InputDecoration(
                labelText: 'Pricing mode',
                border: OutlineInputBorder(),
              ),
              items: StudentRidePackagePriceMode.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(_priceModeLabel(value)),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _priceMode = value!),
            ),
            _section('Remote pricing'),
            Row(
              children: [
                Expanded(child: _field('basePrice', 'Base/monthly price', number: true)),
                const SizedBox(width: 10),
                Expanded(child: _field('perDayPrice', 'Per-day price', number: true)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _field('perKmPrice', 'Per-km price', number: true)),
                const SizedBox(width: 10),
                Expanded(
                  child: _field('doorToDoorCharge', 'Door-to-door charge', number: true),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: _field('registrationFee', 'Registration fee', number: true)),
                const SizedBox(width: 10),
                Expanded(child: _field('currencyCode', 'Currency', required: true)),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _field(
                    'siblingDiscountPercent',
                    'Sibling discount %',
                    number: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    'maximumDiscountAmount',
                    'Maximum discount',
                    number: true,
                  ),
                ),
              ],
            ),
            _section('Availability'),
            _field('schoolIds', 'School IDs (comma separated)'),
            _field('routeIds', 'Route IDs (comma separated)'),
            _field('vehicleTypes', 'Vehicle types (comma separated)'),
            const Text('Operating weekdays'),
            Wrap(
              spacing: 6,
              children: List.generate(7, (index) {
                final day = index + 1;
                return FilterChip(
                  label: Text(const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index]),
                  selected: _weekdays.contains(day),
                  onSelected: (selected) => setState(() {
                    selected ? _weekdays.add(day) : _weekdays.remove(day);
                  }),
                );
              }),
            ),
            _section('Package rules'),
            Row(
              children: [
                Expanded(child: _field('minimumDays', 'Minimum days', number: true)),
                const SizedBox(width: 10),
                Expanded(child: _field('maximumStudents', 'Maximum students', number: true)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _field('paymentDueDay', 'Payment due day', number: true)),
                const SizedBox(width: 10),
                Expanded(
                  child: _field('paymentGraceDays', 'Grace days', number: true),
                ),
              ],
            ),
            _field('displayOrder', 'Display order', number: true),
            _switch('Package enabled', _enabled, (value) => _enabled = value),
            _switch('Door-to-door', _doorToDoor, (value) => _doorToDoor = value),
            _switch('Shared vehicle', _sharedVehicle, (value) => _sharedVehicle = value),
            _switch(
              'Sibling discount allowed',
              _siblingDiscount,
              (value) => _siblingDiscount = value,
            ),
            _switch('Auto renew allowed', _autoRenew, (value) => _autoRenew = value),
            _switch('Pause allowed', _pauseAllowed, (value) => _pauseAllowed = value),
            _switch(
              'Cancellation allowed',
              _cancellationAllowed,
              (value) => _cancellationAllowed = value,
            ),
            _field('disabledMessage', 'Disabled message', lines: 3),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving...' : 'Save Package'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _switch(String title, bool value, ValueChanged<bool> update) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: (next) => setState(() => update(next)),
    );
  }

  Widget _field(
    String key,
    String label, {
    bool required = false,
    bool number = false,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        minLines: lines,
        maxLines: lines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) return '$label is required.';
          if (number && text.isNotEmpty && double.tryParse(text) == null) {
            return 'Enter a valid number.';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one weekday.')),
      );
      return;
    }
    final existing = widget.package;
    final package = StudentRidePackageModel(
      packageId: existing?.packageId ?? '',
      name: _text('name'),
      description: _text('description'),
      isEnabled: _enabled,
      tripType: _tripType,
      priceMode: _priceMode,
      doorToDoor: _doorToDoor,
      sharedVehicle: _sharedVehicle,
      siblingDiscountAllowed: _siblingDiscount,
      schoolIds: _list('schoolIds'),
      routeIds: _list('routeIds'),
      vehicleTypes: _list('vehicleTypes'),
      operatingWeekdays: (_weekdays.toList()..sort()),
      basePrice: _double('basePrice'),
      perKmPrice: _double('perKmPrice'),
      perDayPrice: _double('perDayPrice'),
      doorToDoorCharge: _double('doorToDoorCharge'),
      registrationFee: _double('registrationFee'),
      siblingDiscountPercent: _double('siblingDiscountPercent'),
      maximumDiscountAmount: _double('maximumDiscountAmount'),
      currencyCode: _text('currencyCode').toUpperCase(),
      minimumDays: _int('minimumDays'),
      maximumStudents: _int('maximumStudents'),
      paymentDueDay: _int('paymentDueDay'),
      paymentGraceDays: _int('paymentGraceDays'),
      autoRenewAllowed: _autoRenew,
      pauseAllowed: _pauseAllowed,
      cancellationAllowed: _cancellationAllowed,
      displayOrder: _int('displayOrder'),
      disabledMessage: _text('disabledMessage'),
      createdBy: existing?.createdBy ?? widget.adminId,
      updatedBy: widget.adminId,
      createdAt: existing?.createdAt,
      updatedAt: existing?.updatedAt,
    );

    setState(() => _saving = true);
    try {
      await widget.service.savePackage(package: package, adminId: widget.adminId);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.isBusy,
    required this.onEdit,
    required this.onToggle,
  });

  final StudentRidePackageModel package;
  final bool isBusy;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(package.isEnabled ? Icons.check_rounded : Icons.block_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(package.name, style: Theme.of(context).textTheme.titleMedium),
                      Text('${_tripTypeLabel(package.tripType)} · ${_priceModeLabel(package.priceMode)}'),
                    ],
                  ),
                ),
                Switch(value: package.isEnabled, onChanged: isBusy ? null : onToggle),
              ],
            ),
            const SizedBox(height: 10),
            Text('Base: ${package.currencyCode} ${package.basePrice.toStringAsFixed(0)}'),
            Text(
              'Daily: ${package.perDayPrice.toStringAsFixed(0)} · '
              'Per km: ${package.perKmPrice.toStringAsFixed(0)}',
            ),
            Text(
              'Registration: ${package.registrationFee.toStringAsFixed(0)} · '
              'Sibling discount: ${package.siblingDiscountPercent.toStringAsFixed(0)}%',
            ),
            if (isBusy) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ] else ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit package and pricing'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

String _tripTypeLabel(StudentRidePackageTripType value) => switch (value) {
      StudentRidePackageTripType.morningOnly => 'Morning only',
      StudentRidePackageTripType.afternoonOnly => 'Afternoon only',
      StudentRidePackageTripType.twoWay => 'Two way',
    };

String _priceModeLabel(StudentRidePackagePriceMode value) => switch (value) {
      StudentRidePackagePriceMode.fixedMonthly => 'Monthly',
      StudentRidePackagePriceMode.daily => 'Daily',
      StudentRidePackagePriceMode.routeBased => 'Route based',
      StudentRidePackagePriceMode.distanceBased => 'Distance based',
    };
