import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/student_ride_route_model.dart';
import '../../services/student_ride_route_service.dart';

class StudentRideAdminRouteManagementScreen extends StatefulWidget {
  const StudentRideAdminRouteManagementScreen({super.key});

  @override
  State<StudentRideAdminRouteManagementScreen> createState() =>
      _StudentRideAdminRouteManagementScreenState();
}

class _StudentRideAdminRouteManagementScreenState
    extends State<StudentRideAdminRouteManagementScreen> {
  final StudentRideRouteService _service = StudentRideRouteService();
  StudentRideRouteShift? _shiftFilter;
  StudentRideRouteStatus? _statusFilter;
  String? _busyRouteId;

  String get _adminId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Admin is not logged in.');
    return user.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Ride Routes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRouteForm(),
        icon: const Icon(Icons.add_road_rounded),
        label: const Text('New Route'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<StudentRideRouteShift?>(
                    initialValue: _shiftFilter,
                    decoration: const InputDecoration(
                      labelText: 'Shift',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All shifts'),
                      ),
                      ...StudentRideRouteShift.values.map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_shiftLabel(value)),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _shiftFilter = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<StudentRideRouteStatus?>(
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All statuses'),
                      ),
                      ...StudentRideRouteStatus.values.map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_statusLabel(value)),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _statusFilter = value),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<StudentRideRouteModel>>(
              stream: _service.watchAllRoutesForAdmin(
                shift: _shiftFilter,
                status: _statusFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MessageView(
                    icon: Icons.error_outline_rounded,
                    message: 'Routes could not be loaded.\n${snapshot.error}',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final routes = snapshot.data!;
                if (routes.isEmpty) {
                  return const _MessageView(
                    icon: Icons.alt_route_rounded,
                    message: 'No Student Ride routes found.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: routes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    return _RouteCard(
                      route: route,
                      isBusy: _busyRouteId == route.routeId,
                      onEdit: () => _openRouteForm(route),
                      onStatus: (status) => _changeStatus(route, status),
                      onDelete: () => _deleteRoute(route),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRouteForm([StudentRideRouteModel? route]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _RouteEditorScreen(
          service: _service,
          adminId: _adminId,
          route: route,
        ),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(route == null ? 'Route created.' : 'Route updated.')),
      );
    }
  }

  Future<void> _changeStatus(
    StudentRideRouteModel route,
    StudentRideRouteStatus status,
  ) async {
    if (_busyRouteId != null || status == route.status) return;
    String message = '';
    if (status != StudentRideRouteStatus.active) {
      final controller = TextEditingController(text: route.disabledMessage);
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Set route to ${_statusLabel(status)}'),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Message for parents (optional)',
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
              child: const Text('Update'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (result == null) return;
      message = result;
    }

    setState(() => _busyRouteId = route.routeId);
    try {
      await _service.setRouteStatus(
        routeId: route.routeId,
        status: status,
        adminId: _adminId,
        disabledMessage: message,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Route status changed to ${_statusLabel(status)}.')),
        );
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busyRouteId = null);
    }
  }

  Future<void> _deleteRoute(StudentRideRouteModel route) async {
    if (_busyRouteId != null) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete route?'),
            content: Text(
              '${route.routeName} will be permanently deleted. '
              'A route with assigned students cannot be deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    setState(() => _busyRouteId = route.routeId);
    try {
      await _service.deleteRoute(routeId: route.routeId, adminId: _adminId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route deleted.')),
        );
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _busyRouteId = null);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _RouteEditorScreen extends StatefulWidget {
  const _RouteEditorScreen({
    required this.service,
    required this.adminId,
    this.route,
  });

  final StudentRideRouteService service;
  final String adminId;
  final StudentRideRouteModel? route;

  @override
  State<_RouteEditorScreen> createState() => _RouteEditorScreenState();
}

class _RouteEditorScreenState extends State<_RouteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  late StudentRideRouteShift _shift;
  late StudentRideRouteStatus _status;
  late Set<int> _weekdays;
  late bool _waitlistEnabled;
  bool _saving = false;

  StudentRideRouteModel? get _route => widget.route;

  @override
  void initState() {
    super.initState();
    final route = _route;
    _shift = route?.shift ?? StudentRideRouteShift.morning;
    _status = route?.status ?? StudentRideRouteStatus.draft;
    _weekdays = (route?.operatingWeekdays ?? const [1, 2, 3, 4, 5])
        .whereType<num>()
        .map((value) => value.toInt())
        .toSet();
    _waitlistEnabled = route?.waitlistEnabled ?? true;
    _set('routeName', route?.routeName);
    _set('schoolId', route?.schoolId);
    _set('schoolName', route?.schoolName);
    _set('schoolAddress', route?.schoolAddress);
    _set('schoolLatitude', route?.schoolLatitude.toString());
    _set('schoolLongitude', route?.schoolLongitude.toString());
    _set('routeStartTime', route?.routeStartTime);
    _set('schoolArrivalTime', route?.schoolArrivalTime);
    _set('driverId', route?.driverId);
    _set('driverName', route?.driverName);
    _set('vehicleId', route?.vehicleId);
    _set('vehicleRegistrationNumber', route?.vehicleRegistrationNumber);
    _set('vehicleCapacity', (route?.vehicleCapacity ?? 1).toString());
    _set('reservedSeatCount', (route?.reservedSeatCount ?? 0).toString());
    _set('estimatedDistanceKm', (route?.estimatedDistanceKm ?? 0).toString());
    _set(
      'estimatedDurationMinutes',
      (route?.estimatedDurationMinutes ?? 0).toString(),
    );
    _set('disabledMessage', route?.disabledMessage);
  }

  void _set(String key, String? value) {
    _controllers[key] = TextEditingController(text: value ?? '');
  }

  String _text(String key) => _controllers[key]!.text.trim();
  double _double(String key) => double.tryParse(_text(key)) ?? 0;
  int _int(String key) => int.tryParse(_text(key)) ?? 0;

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
        title: Text(_route == null ? 'Create Route' : 'Edit Route'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _section('Route and school'),
            _field('routeName', 'Route name', required: true),
            Row(
              children: [
                Expanded(child: _field('schoolId', 'School ID', required: true)),
                const SizedBox(width: 10),
                Expanded(
                  child: _field('schoolName', 'School name', required: true),
                ),
              ],
            ),
            _field('schoolAddress', 'School address'),
            Row(
              children: [
                Expanded(
                  child: _field(
                    'schoolLatitude',
                    'School latitude',
                    number: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    'schoolLongitude',
                    'School longitude',
                    number: true,
                  ),
                ),
              ],
            ),
            _section('Shift and schedule'),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<StudentRideRouteShift>(
                    initialValue: _shift,
                    decoration: const InputDecoration(
                      labelText: 'Shift',
                      border: OutlineInputBorder(),
                    ),
                    items: StudentRideRouteShift.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(_shiftLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _shift = value!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<StudentRideRouteStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: StudentRideRouteStatus.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(_statusLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _status = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _field('routeStartTime', 'Route start time', required: true),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    'schoolArrivalTime',
                    'School arrival time',
                    required: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
            _section('Driver and vehicle'),
            Row(
              children: [
                Expanded(child: _field('driverId', 'Driver ID')),
                const SizedBox(width: 10),
                Expanded(child: _field('driverName', 'Driver name')),
              ],
            ),
            Row(
              children: [
                Expanded(child: _field('vehicleId', 'Vehicle ID')),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    'vehicleRegistrationNumber',
                    'Registration number',
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _field(
                    'vehicleCapacity',
                    'Vehicle capacity',
                    number: true,
                    required: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    'reservedSeatCount',
                    'Reserved seats',
                    number: true,
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Waitlist enabled'),
              value: _waitlistEnabled,
              onChanged: (value) => setState(() => _waitlistEnabled = value),
            ),
            _section('Route estimate and message'),
            Row(
              children: [
                Expanded(
                  child: _field(
                    'estimatedDistanceKm',
                    'Distance (km)',
                    number: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    'estimatedDurationMinutes',
                    'Duration (minutes)',
                    number: true,
                  ),
                ),
              ],
            ),
            _field(
              'disabledMessage',
              'Unavailable/disabled message',
              lines: 3,
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving...' : 'Save Route'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
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
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
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
        const SnackBar(content: Text('Select at least one operating weekday.')),
      );
      return;
    }
    if (_status == StudentRideRouteStatus.active &&
        (_text('driverId').isEmpty ||
            _text('vehicleId').isEmpty ||
            _text('vehicleRegistrationNumber').isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Assign an approved driver and vehicle before activating route.',
          ),
        ),
      );
      return;
    }

    final existing = _route;
    final route = StudentRideRouteModel(
      routeId: existing?.routeId ?? '',
      routeName: _text('routeName'),
      shift: _shift,
      status: _status,
      schoolId: _text('schoolId'),
      schoolName: _text('schoolName'),
      schoolAddress: _text('schoolAddress'),
      schoolLatitude: _double('schoolLatitude'),
      schoolLongitude: _double('schoolLongitude'),
      routeStartTime: _text('routeStartTime'),
      schoolArrivalTime: _text('schoolArrivalTime'),
      operatingWeekdays: (_weekdays.toList()..sort()),
      driverId: _text('driverId'),
      driverName: _text('driverName'),
      vehicleId: _text('vehicleId'),
      vehicleRegistrationNumber: _text('vehicleRegistrationNumber'),
      vehicleCapacity: _int('vehicleCapacity'),
      stops: existing?.stops ?? const <StudentRideRouteStopModel>[],
      estimatedDistanceKm: _double('estimatedDistanceKm'),
      estimatedDurationMinutes: _int('estimatedDurationMinutes'),
      assignedStudentCount: existing?.assignedStudentCount ?? 0,
      reservedSeatCount: _int('reservedSeatCount'),
      waitlistEnabled: _waitlistEnabled,
      disabledMessage: _text('disabledMessage'),
      createdBy: existing?.createdBy ?? widget.adminId,
      updatedBy: widget.adminId,
      createdAt: existing?.createdAt,
      updatedAt: existing?.updatedAt,
    );

    setState(() => _saving = true);
    try {
      await widget.service.saveRoute(route: route, adminId: widget.adminId);
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

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.isBusy,
    required this.onEdit,
    required this.onStatus,
    required this.onDelete,
  });

  final StudentRideRouteModel route;
  final bool isBusy;
  final VoidCallback onEdit;
  final ValueChanged<StudentRideRouteStatus> onStatus;
  final VoidCallback onDelete;

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
                const CircleAvatar(child: Icon(Icons.alt_route_rounded)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(route.routeName, style: Theme.of(context).textTheme.titleMedium),
                      Text('${route.schoolName} · ${_shiftLabel(route.shift)}'),
                    ],
                  ),
                ),
                Chip(label: Text(_statusLabel(route.status))),
              ],
            ),
            const SizedBox(height: 10),
            Text('Time: ${route.routeStartTime} → ${route.schoolArrivalTime}'),
            Text(
              'Driver: ${route.driverName.isEmpty ? "Not assigned" : route.driverName}',
            ),
            Text(
              'Vehicle: ${route.vehicleRegistrationNumber.isEmpty ? "Not assigned" : route.vehicleRegistrationNumber}',
            ),
            Text(
              'Seats: ${route.assignedStudentCount}/${route.vehicleCapacity} · '
              '${route.availableSeats} available',
            ),
            if (isBusy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ] else ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit'),
                  ),
                  PopupMenuButton<StudentRideRouteStatus>(
                    onSelected: onStatus,
                    itemBuilder: (context) => StudentRideRouteStatus.values
                        .where((status) => status != route.status)
                        .map(
                          (status) => PopupMenuItem(
                            value: status,
                            child: Text('Set ${_statusLabel(status)}'),
                          ),
                        )
                        .toList(),
                    child: const Chip(
                      avatar: Icon(Icons.tune_rounded, size: 18),
                      label: Text('Change status'),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                  ),
                ],
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
  Widget build(BuildContext context) {
    return Center(
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
}

String _shiftLabel(StudentRideRouteShift shift) {
  return shift == StudentRideRouteShift.morning ? 'Morning' : 'Afternoon';
}

String _statusLabel(StudentRideRouteStatus status) {
  return switch (status) {
    StudentRideRouteStatus.draft => 'Draft',
    StudentRideRouteStatus.active => 'Active',
    StudentRideRouteStatus.paused => 'Paused',
    StudentRideRouteStatus.full => 'Full',
    StudentRideRouteStatus.disabled => 'Disabled',
  };
}
