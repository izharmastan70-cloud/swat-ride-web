import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TourismVehicleManagementScreen extends StatefulWidget {
  const TourismVehicleManagementScreen({super.key});

  @override
  State<TourismVehicleManagementScreen> createState() =>
      _TourismVehicleManagementScreenState();
}

class _TourismVehicleManagementScreenState
    extends State<TourismVehicleManagementScreen> {
  static const yellow = Color(0xFFFFD60A);
  static const darkCard = Color(0xFF1A1A1A);
  static const darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _search = '';
  String _type = 'all';
  String _status = 'all';
  bool _showArchived = false;
  String _workingId = '';

  CollectionReference<Map<String, dynamic>> get _vehicles =>
      _firestore.collection('tour_vehicles');

  CollectionReference<Map<String, dynamic>> get _audit =>
      _firestore.collection('tour_vehicle_audit_logs');

  static const _types = <String>[
    'all',
    'car',
    'suv',
    'jeep',
    'van',
    'hiace',
    'coaster',
    'bus',
    'pickup',
    'other',
  ];

  static const _statuses = <String>[
    'all',
    'available',
    'unavailable',
    'maintenance',
    'blocked',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Tourism Vehicle Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _workingId.isNotEmpty ? null : _openCreate,
            icon: const Icon(Icons.add_circle_outline, color: yellow),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _vehicles.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: yellow),
              );
            }

            if (snapshot.hasError) {
              return _message(
                Icons.error_outline,
                'Unable to Load Vehicles',
                snapshot.error.toString(),
              );
            }

            final all = snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            final visible = all.where((doc) {
              final data = doc.data();
              final archived = data['isArchived'] == true;
              if (_showArchived != archived) return false;

              final type =
                  data['vehicleType']?.toString().toLowerCase() ?? 'other';
              if (_type != 'all' && type != _type) return false;

              final status = _normalizedStatus(data);
              if (_status != 'all' && status != _status) return false;

              final query = _search.trim().toLowerCase();
              if (query.isEmpty) return true;

              final values = <String>[
                doc.id,
                data['vehicleId']?.toString() ?? '',
                data['registrationNumber']?.toString() ?? '',
                data['brand']?.toString() ?? '',
                data['model']?.toString() ?? '',
                data['ownerName']?.toString() ?? '',
                data['driverName']?.toString() ?? '',
                type,
                status,
              ];
              return values.any((value) => value.toLowerCase().contains(query));
            }).toList()
              ..sort((a, b) {
                final order = _readInt(a.data()['sortOrder'], fallback: 9999)
                    .compareTo(
                  _readInt(b.data()['sortOrder'], fallback: 9999),
                );
                if (order != 0) return order;
                return (a.data()['registrationNumber']?.toString() ?? '')
                    .compareTo(
                  b.data()['registrationNumber']?.toString() ?? '',
                );
              });

            return Column(
              children: [
                _summary(all),
                _searchBox(),
                _choiceBar(
                  _types,
                  _type,
                  (value) => value == 'all' ? 'All Types' : _capitalize(value),
                  (value) => setState(() => _type = value),
                ),
                _choiceBar(
                  _statuses,
                  _status,
                  _statusLabel,
                  (value) => setState(() => _status = value),
                ),
                _archiveSwitch(),
                Expanded(
                  child: visible.isEmpty
                      ? _message(
                          Icons.directions_car_outlined,
                          'No Vehicles Found',
                          'No tourism vehicle matches the selected filters.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: visible.length,
                          itemBuilder: (context, index) =>
                              _vehicleCard(visible[index]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _workingId.isNotEmpty ? null : _openCreate,
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Vehicle',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _summary(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    int available = 0;
    int unavailable = 0;
    int maintenance = 0;
    int archived = 0;

    for (final doc in docs) {
      final data = doc.data();
      if (data['isArchived'] == true) {
        archived++;
        continue;
      }
      switch (_normalizedStatus(data)) {
        case 'available':
          available++;
          break;
        case 'maintenance':
          maintenance++;
          break;
        default:
          unavailable++;
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: yellow.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _summaryItem('Available', available, Colors.green),
          _summaryItem('Unavailable', unavailable, Colors.orange),
          _summaryItem('Maintenance', maintenance, Colors.redAccent),
          _summaryItem('Archived', archived, Colors.grey),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _search = value),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search vehicle, number, owner or driver...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: yellow),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
          filled: true,
          fillColor: darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _choiceBar(
    List<String> items,
    String selected,
    String Function(String) labelBuilder,
    ValueChanged<String> onSelected,
  ) {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = items[index];
          final active = value == selected;
          return ChoiceChip(
            selected: active,
            label: Text(labelBuilder(value)),
            selectedColor: yellow.withValues(alpha: 0.24),
            checkmarkColor: yellow,
            labelStyle: TextStyle(
              color: active ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            onSelected: (_) => onSelected(value),
          );
        },
      ),
    );
  }

  Widget _archiveSwitch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.archive_outlined, color: yellow, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Show archived vehicles',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
          Switch(
            value: _showArchived,
            activeThumbColor: yellow,
            onChanged: (value) => setState(() => _showArchived = value),
          ),
        ],
      ),
    );
  }

  Widget _vehicleCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final registration =
        data['registrationNumber']?.toString() ?? 'No Registration';
    final type = data['vehicleType']?.toString() ?? 'other';
    final brand = data['brand']?.toString() ?? '';
    final model = data['model']?.toString() ?? '';
    final year = _readInt(data['year']);
    final seats = _readInt(data['seatCapacity'], fallback: 1);
    final luggage = _readInt(data['luggageCapacity']);
    final status = _normalizedStatus(data);
    final dailyRate = _readDouble(data['dailyRate']);
    final perKmRate = _readDouble(data['perKmRate']);
    final owner = data['ownerName']?.toString() ?? '';
    final driver = data['driverName']?.toString() ?? '';
    final isFeatured = data['isFeatured'] == true;
    final isArchived = data['isArchived'] == true;
    final verified = data['documentsVerified'] == true;
    final maintenance = data['maintenanceStatus']?.toString() ?? 'clear';
    final working = _workingId == document.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _statusColor(status).withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: yellow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_typeIcon(type), color: yellow),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        _capitalize(type),
                        if (brand.isNotEmpty) brand,
                        if (model.isNotEmpty) model,
                        if (year > 0) '$year',
                      ].join(' â€¢ '),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
              _badge(
                isArchived ? 'Archived' : _statusLabel(status),
                _statusColor(isArchived ? 'archived' : status),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isFeatured) _badge('Featured', yellow),
              if (verified) _badge('Documents Verified', Colors.teal),
              if (data['hasAc'] == true) _badge('AC', Colors.blue),
              if (data['hasHeater'] == true)
                _badge('Heater', Colors.deepOrange),
              if (data['is4x4'] == true) _badge('4x4', Colors.indigo),
              if (maintenance != 'clear')
                _badge(
                  maintenance.split('_').map(_capitalize).join(' '),
                  Colors.redAccent,
                ),
            ],
          ),
          const SizedBox(height: 11),
          _detail('Capacity', '$seats seats â€¢ $luggage luggage'),
          _detail(
            'Daily Rate',
            dailyRate > 0 ? 'PKR ${_money(dailyRate)}' : 'Not set',
          ),
          _detail(
            'Per KM Rate',
            perKmRate > 0 ? 'PKR ${_money(perKmRate)}' : 'Not set',
          ),
          _detail('Owner', owner.isEmpty ? 'Not assigned' : owner),
          _detail('Driver', driver.isEmpty ? 'Not assigned' : driver),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: working ? null : () => _openEdit(document),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: yellow,
                    side: const BorderSide(color: yellow),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (working)
                const SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    color: yellow,
                    strokeWidth: 2,
                  ),
                )
              else
                PopupMenuButton<String>(
                  color: darkCard,
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (action) => _handleAction(action, document),
                  itemBuilder: (_) => <PopupMenuEntry<String>>[
                    if (!isArchived)
                      PopupMenuItem(
                        value: 'availability',
                        child: Text(
                          status == 'available'
                              ? 'Mark Unavailable'
                              : 'Mark Available',
                        ),
                      ),
                    if (!isArchived)
                      const PopupMenuItem(
                        value: 'maintenance',
                        child: Text('Set Maintenance Status'),
                      ),
                    if (!isArchived)
                      const PopupMenuItem(
                        value: 'verify',
                        child: Text('Verify Documents'),
                      ),
                    if (!isArchived)
                      PopupMenuItem(
                        value: 'featured',
                        child: Text(
                          isFeatured
                              ? 'Remove Featured'
                              : 'Mark Featured',
                        ),
                      ),
                    PopupMenuItem(
                      value: isArchived ? 'restore' : 'archive',
                      child: Text(isArchived ? 'Restore' : 'Archive'),
                    ),
                    const PopupMenuItem(
                      value: 'history',
                      child: Text('View Audit History'),
                    ),
                    if (isArchived)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Permanently'),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openCreate() async {
    final result = await _showForm();
    if (result == null) return;

    final ref = _vehicles.doc();
    await _working(ref.id, () async {
      await ref.set({
        'vehicleId': ref.id,
        ...result.toMap(),
        'isArchived': false,
        'imageUrl': '',
        'storageUploadUsed': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _saveAudit(
        ref.id,
        'vehicle_created',
        'Tourism vehicle created: ${result.registrationNumber}.',
      );
    });
    _showMessage('Tourism vehicle created.');
  }

  Future<void> _openEdit(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final result = await _showForm(existing: document.data());
    if (result == null) return;

    await _working(document.id, () async {
      await document.reference.set(
        {
          ...result.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await _saveAudit(
        document.id,
        'vehicle_updated',
        'Tourism vehicle updated.',
      );
    });
    _showMessage('Vehicle updated.');
  }

  Future<_VehicleFormResult?> _showForm({
    Map<String, dynamic>? existing,
  }) async {
    final registration = TextEditingController(
      text: existing?['registrationNumber']?.toString() ?? '',
    );
    final brand = TextEditingController(
      text: existing?['brand']?.toString() ?? '',
    );
    final model = TextEditingController(
      text: existing?['model']?.toString() ?? '',
    );
    final year = TextEditingController(
      text: _readInt(existing?['year']).toString(),
    );
    final seats = TextEditingController(
      text: _readInt(existing?['seatCapacity'], fallback: 4).toString(),
    );
    final luggage = TextEditingController(
      text: _readInt(existing?['luggageCapacity']).toString(),
    );
    final fuel = TextEditingController(
      text: existing?['fuelType']?.toString() ?? '',
    );
    final ownerName = TextEditingController(
      text: existing?['ownerName']?.toString() ?? '',
    );
    final ownerId = TextEditingController(
      text: existing?['ownerId']?.toString() ?? '',
    );
    final driverName = TextEditingController(
      text: existing?['driverName']?.toString() ?? '',
    );
    final driverId = TextEditingController(
      text: existing?['driverId']?.toString() ?? '',
    );
    final dailyRate = TextEditingController(
      text: _readDouble(existing?['dailyRate']).toStringAsFixed(0),
    );
    final perKmRate = TextEditingController(
      text: _readDouble(existing?['perKmRate']).toStringAsFixed(0),
    );
    final minimumCharge = TextEditingController(
      text: _readDouble(existing?['minimumCharge']).toStringAsFixed(0),
    );
    final localImage = TextEditingController(
      text: existing?['localImagePath']?.toString() ?? '',
    );
    final note = TextEditingController(
      text: existing?['adminNote']?.toString() ?? '',
    );
    final sortOrder = TextEditingController(
      text: _readInt(existing?['sortOrder'], fallback: 100).toString(),
    );

    String vehicleType = existing?['vehicleType']?.toString() ?? 'car';
    String status = _normalizedStatus(existing ?? <String, dynamic>{});
    if (status == 'archived') status = 'unavailable';
    String maintenanceStatus =
        existing?['maintenanceStatus']?.toString() ?? 'clear';
    bool hasAc = existing?['hasAc'] == true;
    bool hasHeater = existing?['hasHeater'] == true;
    bool is4x4 = existing?['is4x4'] == true;
    bool isActive = existing?['isActive'] != false;
    bool isFeatured = existing?['isFeatured'] == true;
    bool verified = existing?['documentsVerified'] == true;

    final result = await showModalBottomSheet<_VehicleFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existing == null
                          ? 'Add Tourism Vehicle'
                          : 'Edit Tourism Vehicle',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _sectionTitle('Basic Information'),
                    _field(registration, 'Registration Number'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: vehicleType,
                      dropdownColor: darkCard,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Type',
                      ),
                      items: _types
                          .where((item) => item != 'all')
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(_capitalize(item)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => vehicleType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _field(brand, 'Brand')),
                        const SizedBox(width: 10),
                        Expanded(child: _field(model, 'Model')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _field(year, 'Year', keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _sectionTitle('Capacity & Features'),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            seats,
                            'Seats',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            luggage,
                            'Luggage Capacity',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _field(fuel, 'Fuel Type'),
                    _switch('Air Conditioning', hasAc, (value) {
                      setSheetState(() => hasAc = value);
                    }),
                    _switch('Heater', hasHeater, (value) {
                      setSheetState(() => hasHeater = value);
                    }),
                    _switch('4x4', is4x4, (value) {
                      setSheetState(() => is4x4 = value);
                    }),
                    const SizedBox(height: 16),
                    _sectionTitle('Owner & Driver'),
                    _field(ownerName, 'Owner Name'),
                    const SizedBox(height: 10),
                    _field(ownerId, 'Owner ID'),
                    const SizedBox(height: 10),
                    _field(driverName, 'Driver Name'),
                    const SizedBox(height: 10),
                    _field(driverId, 'Driver ID'),
                    const SizedBox(height: 16),
                    _sectionTitle('Pricing'),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            dailyRate,
                            'Daily Rate',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            perKmRate,
                            'Per KM Rate',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _field(
                      minimumCharge,
                      'Minimum Charge',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Availability & Maintenance'),
                    DropdownButtonFormField<String>(
                      initialValue: _statuses.contains(status)
                          ? status
                          : 'unavailable',
                      dropdownColor: darkCard,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Status',
                      ),
                      items: _statuses
                          .where((item) => item != 'all')
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(_statusLabel(item)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: maintenanceStatus,
                      dropdownColor: darkCard,
                      decoration: const InputDecoration(
                        labelText: 'Maintenance Status',
                      ),
                      items: const <String>[
                        'clear',
                        'inspection_due',
                        'service_due',
                        'repair_required',
                        'in_repair',
                      ]
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                item.split('_').map(_capitalize).join(' '),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => maintenanceStatus = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Admin Controls'),
                    _field(localImage, 'Local Image Path'),
                    const SizedBox(height: 10),
                    _field(
                      sortOrder,
                      'Sort Order',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    _field(note, 'Admin Note', maxLines: 3),
                    _switch('Active', isActive, (value) {
                      setSheetState(() => isActive = value);
                    }),
                    _switch('Featured', isFeatured, (value) {
                      setSheetState(() => isFeatured = value);
                    }),
                    _switch('Documents Verified', verified, (value) {
                      setSheetState(() => verified = value);
                    }),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (registration.text.trim().isEmpty) return;
                          Navigator.pop(
                            sheetContext,
                            _VehicleFormResult(
                              registrationNumber: registration.text.trim(),
                              vehicleType: vehicleType,
                              brand: brand.text.trim(),
                              model: model.text.trim(),
                              year: int.tryParse(year.text.trim()) ?? 0,
                              seatCapacity:
                                  int.tryParse(seats.text.trim()) ?? 1,
                              luggageCapacity:
                                  int.tryParse(luggage.text.trim()) ?? 0,
                              fuelType: fuel.text.trim(),
                              hasAc: hasAc,
                              hasHeater: hasHeater,
                              is4x4: is4x4,
                              ownerName: ownerName.text.trim(),
                              ownerId: ownerId.text.trim(),
                              driverName: driverName.text.trim(),
                              driverId: driverId.text.trim(),
                              dailyRate:
                                  double.tryParse(dailyRate.text.trim()) ?? 0,
                              perKmRate:
                                  double.tryParse(perKmRate.text.trim()) ?? 0,
                              minimumCharge:
                                  double.tryParse(minimumCharge.text.trim()) ??
                                      0,
                              status: status,
                              maintenanceStatus: maintenanceStatus,
                              localImagePath: localImage.text.trim(),
                              adminNote: note.text.trim(),
                              sortOrder:
                                  int.tryParse(sortOrder.text.trim()) ?? 100,
                              isActive: isActive,
                              isFeatured: isFeatured,
                              documentsVerified: verified,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: yellow,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(
                          existing == null ? 'Create Vehicle' : 'Save Changes',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    for (final controller in <TextEditingController>[
      registration,
      brand,
      model,
      year,
      seats,
      luggage,
      fuel,
      ownerName,
      ownerId,
      driverName,
      driverId,
      dailyRate,
      perKmRate,
      minimumCharge,
      localImage,
      note,
      sortOrder,
    ]) {
      controller.dispose();
    }

    return result;
  }

  Future<void> _handleAction(
    String action,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    switch (action) {
      case 'availability':
        final newStatus = _normalizedStatus(document.data()) == 'available'
            ? 'unavailable'
            : 'available';
        await _simpleUpdate(
          document,
          {
            'status': newStatus,
            'isAvailable': newStatus == 'available',
          },
          'vehicle_availability_changed',
          'Vehicle status changed to $newStatus.',
        );
        break;
      case 'maintenance':
        await _maintenanceDialog(document);
        break;
      case 'verify':
        await _simpleUpdate(
          document,
          {
            'documentsVerified': true,
            'documentsVerifiedAt': FieldValue.serverTimestamp(),
          },
          'vehicle_documents_verified',
          'Vehicle documents verified.',
        );
        break;
      case 'featured':
        final newValue = document.data()['isFeatured'] != true;
        await _simpleUpdate(
          document,
          {'isFeatured': newValue},
          newValue ? 'vehicle_featured' : 'vehicle_unfeatured',
          newValue
              ? 'Vehicle marked featured.'
              : 'Vehicle removed from featured.',
        );
        break;
      case 'archive':
        await _setArchived(document, true);
        break;
      case 'restore':
        await _setArchived(document, false);
        break;
      case 'history':
        _showHistory(document);
        break;
      case 'delete':
        await _deleteVehicle(document);
        break;
    }
  }

  Future<void> _maintenanceDialog(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    String status =
        document.data()['maintenanceStatus']?.toString() ?? 'clear';
    final note = TextEditingController(
      text: document.data()['maintenanceNote']?.toString() ?? '',
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: darkCard,
              title: const Text(
                'Maintenance Status',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    dropdownColor: darkCard,
                    decoration: const InputDecoration(
                      labelText: 'Maintenance Status',
                    ),
                    items: const <String>[
                      'clear',
                      'inspection_due',
                      'service_due',
                      'repair_required',
                      'in_repair',
                    ]
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(
                              item.split('_').map(_capitalize).join(' '),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => status = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _field(note, 'Maintenance Note', maxLines: 3),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, {
                      'maintenanceStatus': status,
                      'maintenanceNote': note.text.trim(),
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    note.dispose();
    if (result == null) return;

    final maintenance = result['maintenanceStatus']?.toString() ?? 'clear';
    await _simpleUpdate(
      document,
      {
        ...result,
        'status': maintenance == 'clear' ? 'available' : 'maintenance',
        'isAvailable': maintenance == 'clear',
        'maintenanceUpdatedAt': FieldValue.serverTimestamp(),
      },
      'vehicle_maintenance_updated',
      'Maintenance status changed to $maintenance.',
    );
  }

  Future<void> _setArchived(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    bool archived,
  ) async {
    await _simpleUpdate(
      document,
      {
        'isArchived': archived,
        if (archived) 'archivedAt': FieldValue.serverTimestamp(),
        if (!archived) 'restoredAt': FieldValue.serverTimestamp(),
      },
      archived ? 'vehicle_archived' : 'vehicle_restored',
      archived ? 'Tourism vehicle archived.' : 'Tourism vehicle restored.',
    );
  }

  Future<void> _deleteVehicle(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    if (document.data()['isArchived'] != true) {
      _showMessage(
        'Archive the vehicle before permanent deletion.',
        isError: true,
      );
      return;
    }

    final confirmed = await _confirm(
      'Delete Vehicle',
      'Permanently delete this archived tourism vehicle?',
      'Delete',
      destructive: true,
    );
    if (!confirmed) return;

    await _working(document.id, () async {
      await document.reference.delete();
      await _saveAudit(
        document.id,
        'vehicle_deleted',
        'Archived tourism vehicle permanently deleted.',
      );
    });
    _showMessage('Vehicle deleted.');
  }

  Future<void> _simpleUpdate(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    Map<String, dynamic> update,
    String action,
    String details,
  ) async {
    await _working(document.id, () async {
      await document.reference.set(
        {
          ...update,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await _saveAudit(document.id, action, details);
    });
    _showMessage('Vehicle updated.');
  }

  Future<void> _saveAudit(
    String vehicleId,
    String action,
    String details,
  ) async {
    await _audit.add({
      'vehicleId': vehicleId,
      'action': action,
      'details': details,
      'performedByRole': 'tourism_admin',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _working(
    String id,
    Future<void> Function() action,
  ) async {
    setState(() => _workingId = id);
    try {
      await action();
    } catch (error) {
      _showMessage(
        'Unable to update vehicle: $error',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _workingId = '');
    }
  }

  void _showHistory(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _audit
                  .where('vehicleId', isEqualTo: document.id)
                  .snapshots(),
              builder: (context, snapshot) {
                final logs = snapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                logs.sort(
                  (a, b) => _readDateTime(b.data()['createdAt'])
                      .compareTo(_readDateTime(a.data()['createdAt'])),
                );

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Icon(Icons.history, color: yellow),
                          SizedBox(width: 9),
                          Text(
                            'Vehicle Audit History',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: logs.isEmpty
                          ? const Center(
                              child: Text(
                                'No vehicle history yet.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: logs.length,
                              itemBuilder: (context, index) {
                                final data = logs[index].data();
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 9),
                                  padding: const EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                    color: darkCard,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['action']?.toString() ?? 'Action',
                                        style: const TextStyle(
                                          color: yellow,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        data['details']?.toString() ?? '',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _formatDateTime(
                                          _readDateTime(data['createdAt']),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: yellow,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: darkBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _switch(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      activeThumbColor: yellow,
      onChanged: onChanged,
    );
  }

  Future<bool> _confirm(
    String title,
    String message,
    String confirmLabel, {
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: darkCard,
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: destructive ? Colors.red : yellow,
                  foregroundColor: destructive ? Colors.white : Colors.black,
                ),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _detail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(
    IconData icon,
    String title,
    String message,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, color: yellow, size: 48),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizedStatus(Map<String, dynamic> data) {
    if (data['isArchived'] == true) return 'archived';
    final raw = data['status']?.toString() ?? '';
    if (raw.isNotEmpty) return raw;

    final maintenance = data['maintenanceStatus']?.toString();
    if (maintenance != null && maintenance != 'clear') {
      return 'maintenance';
    }

    return data['isAvailable'] == false ? 'unavailable' : 'available';
  }

  static String _statusLabel(String status) {
    if (status == 'all') return 'All Status';
    return status.split('_').map(_capitalize).join(' ');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'maintenance':
        return Colors.redAccent;
      case 'blocked':
        return Colors.red;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'suv':
      case 'jeep':
        return Icons.directions_car_filled_outlined;
      case 'van':
      case 'hiace':
        return Icons.airport_shuttle_outlined;
      case 'coaster':
      case 'bus':
        return Icons.directions_bus_outlined;
      case 'pickup':
        return Icons.local_shipping_outlined;
      default:
        return Icons.directions_car_outlined;
    }
  }

  int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDateTime(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }

  String _money(num amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        );
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : darkCard,
        ),
      );
  }
}

class _VehicleFormResult {
  const _VehicleFormResult({
    required this.registrationNumber,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.year,
    required this.seatCapacity,
    required this.luggageCapacity,
    required this.fuelType,
    required this.hasAc,
    required this.hasHeater,
    required this.is4x4,
    required this.ownerName,
    required this.ownerId,
    required this.driverName,
    required this.driverId,
    required this.dailyRate,
    required this.perKmRate,
    required this.minimumCharge,
    required this.status,
    required this.maintenanceStatus,
    required this.localImagePath,
    required this.adminNote,
    required this.sortOrder,
    required this.isActive,
    required this.isFeatured,
    required this.documentsVerified,
  });

  final String registrationNumber;
  final String vehicleType;
  final String brand;
  final String model;
  final int year;
  final int seatCapacity;
  final int luggageCapacity;
  final String fuelType;
  final bool hasAc;
  final bool hasHeater;
  final bool is4x4;
  final String ownerName;
  final String ownerId;
  final String driverName;
  final String driverId;
  final double dailyRate;
  final double perKmRate;
  final double minimumCharge;
  final String status;
  final String maintenanceStatus;
  final String localImagePath;
  final String adminNote;
  final int sortOrder;
  final bool isActive;
  final bool isFeatured;
  final bool documentsVerified;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'registrationNumber': registrationNumber,
      'vehicleType': vehicleType,
      'brand': brand,
      'model': model,
      'year': year,
      'seatCapacity': seatCapacity,
      'luggageCapacity': luggageCapacity,
      'fuelType': fuelType,
      'hasAc': hasAc,
      'hasHeater': hasHeater,
      'is4x4': is4x4,
      'ownerName': ownerName,
      'ownerId': ownerId,
      'driverName': driverName,
      'driverId': driverId,
      'dailyRate': dailyRate,
      'perKmRate': perKmRate,
      'minimumCharge': minimumCharge,
      'status': status,
      'isAvailable': status == 'available',
      'maintenanceStatus': maintenanceStatus,
      'localImagePath': localImagePath,
      'adminNote': adminNote,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'documentsVerified': documentsVerified,
    };
  }
}

