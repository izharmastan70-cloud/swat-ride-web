import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TourHotelCombinedManagementScreen extends StatefulWidget {
  const TourHotelCombinedManagementScreen({
    super.key,
  });

  @override
  State<TourHotelCombinedManagementScreen> createState() =>
      _TourHotelCombinedManagementScreenState();
}

class _TourHotelCombinedManagementScreenState
    extends State<TourHotelCombinedManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';
  String _selectedStatus = 'all';
  bool _showInactive = false;
  String _workingPackageId = '';

  CollectionReference<Map<String, dynamic>> get _combinedCollection =>
      _firestore.collection('tour_hotel_packages');

  CollectionReference<Map<String, dynamic>> get _auditCollection =>
      _firestore.collection('tour_hotel_package_audit_logs');

  final List<String> _statuses = const <String>[
    'all',
    'draft',
    'active',
    'inactive',
    'sold_out',
    'archived',
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
          'Tour + Hotel Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add combined package',
            onPressed:
                _workingPackageId.isNotEmpty ? null : _openCreateSheet,
            icon: const Icon(
              Icons.add_circle_outline,
              color: yellow,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _combinedCollection.snapshots(),
          builder: (
            context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: yellow),
              );
            }

            if (snapshot.hasError) {
              return _messageState(
                icon: Icons.error_outline,
                title: 'Unable to Load Tour + Hotel Packages',
                message: snapshot.error.toString(),
              );
            }

            final allDocuments = snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            final visibleDocuments = allDocuments.where((document) {
              final data = document.data();
              final status = data['status']?.toString() ?? 'draft';
              final isActive = data['isActive'] != false;

              if (!_showInactive && !isActive) {
                return false;
              }

              if (_selectedStatus != 'all' &&
                  status != _selectedStatus) {
                return false;
              }

              final query = _searchText.trim().toLowerCase();

              if (query.isEmpty) {
                return true;
              }

              final values = <String>[
                document.id,
                data['combinedPackageId']?.toString() ?? '',
                data['packageName']?.toString() ?? '',
                data['tourPackageName']?.toString() ?? '',
                data['hotelName']?.toString() ?? '',
                data['roomType']?.toString() ?? '',
                status,
              ];

              return values.any(
                (value) => value.toLowerCase().contains(query),
              );
            }).toList();

            visibleDocuments.sort((a, b) {
              final orderCompare = _readInt(
                a.data()['sortOrder'],
                fallback: 9999,
              ).compareTo(
                _readInt(
                  b.data()['sortOrder'],
                  fallback: 9999,
                ),
              );

              if (orderCompare != 0) {
                return orderCompare;
              }

              return (a.data()['packageName']?.toString() ?? '')
                  .compareTo(
                b.data()['packageName']?.toString() ?? '',
              );
            });

            return Column(
              children: [
                _summaryHeader(allDocuments),
                _searchBox(),
                _statusFilters(),
                _inactiveSwitch(),
                Expanded(
                  child: visibleDocuments.isEmpty
                      ? _messageState(
                          icon: Icons.hotel_class_outlined,
                          title: 'No Combined Packages Found',
                          message:
                              'No Tour + Hotel package matches the selected filters.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            24,
                          ),
                          itemCount: visibleDocuments.length,
                          itemBuilder: (context, index) {
                            return _packageCard(
                              visibleDocuments[index],
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            _workingPackageId.isNotEmpty ? null : _openCreateSheet,
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Tour + Hotel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _summaryHeader(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    int active = 0;
    int draft = 0;
    int soldOut = 0;
    int inactive = 0;

    for (final document in documents) {
      final data = document.data();
      final status = data['status']?.toString() ?? 'draft';

      if (data['isActive'] == false || status == 'inactive') {
        inactive++;
      } else if (status == 'draft') {
        draft++;
      } else if (status == 'sold_out') {
        soldOut++;
      } else {
        active++;
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          _summaryItem('Active', active, Colors.green),
          _summaryItem('Draft', draft, Colors.grey),
          _summaryItem('Sold Out', soldOut, Colors.redAccent),
          _summaryItem('Inactive', inactive, Colors.orange),
        ],
      ),
    );
  }

  Widget _summaryItem(
    String title,
    int value,
    Color color,
  ) {
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
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 9,
            ),
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
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search package, hotel, room or tour...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: yellow),
          suffixIcon: _searchText.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchText = '';
                    });
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.grey,
                  ),
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

  Widget _statusFilters() {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _statuses.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final status = _statuses[index];
          final selected = status == _selectedStatus;

          return ChoiceChip(
            selected: selected,
            label: Text(
              status == 'all'
                  ? 'All Status'
                  : status
                      .split('_')
                      .map(_capitalize)
                      .join(' '),
            ),
            selectedColor: yellow.withValues(alpha: 0.24),
            checkmarkColor: yellow,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            onSelected: (_) {
              setState(() {
                _selectedStatus = status;
              });
            },
          );
        },
      ),
    );
  }

  Widget _inactiveSwitch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 8),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_off_outlined,
            color: yellow,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Show inactive packages',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
          Switch(
            value: _showInactive,
            activeThumbColor: yellow,
            onChanged: (value) {
              setState(() {
                _showInactive = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _packageCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final packageName =
        data['packageName']?.toString() ?? 'Tour + Hotel Package';
    final tourPackageName =
        data['tourPackageName']?.toString() ?? 'Tour Package';
    final hotelName =
        data['hotelName']?.toString() ?? 'Hotel';
    final roomType =
        data['roomType']?.toString() ?? 'Room';
    final status =
        data['status']?.toString() ?? 'draft';
    final nights =
        _readInt(data['nights'], fallback: 1);
    final rooms =
        _readInt(data['rooms'], fallback: 1);
    final availableRooms =
        _readInt(data['availableRooms']);
    final adultPrice =
        _readDouble(data['adultPrice']);
    final childPrice =
        _readDouble(data['childPrice']);
    final combinedPrice =
        _readDouble(data['combinedPrice']);
    final hotelCost =
        _readDouble(data['hotelCost']);
    final tourismCommission =
        _readDouble(data['tourismCommissionPercent']);
    final hotelCommission =
        _readDouble(data['hotelCommissionPercent']);
    final mealPlan =
        data['mealPlan']?.toString() ?? 'Not included';
    final isFeatured =
        data['isFeatured'] == true;
    final isActive =
        data['isActive'] != false;
    final working =
        _workingPackageId == document.id;

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
                child: const Icon(
                  Icons.hotel_class_outlined,
                  color: yellow,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      packageName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$tourPackageName â€¢ $hotelName',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              _smallBadge(
                status
                    .split('_')
                    .map(_capitalize)
                    .join(' '),
                _statusColor(status),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isFeatured)
                _smallBadge(
                  'Featured',
                  yellow,
                ),
              _smallBadge(
                '$nights night${nights == 1 ? '' : 's'}',
                Colors.blue,
              ),
              _smallBadge(
                '$rooms room${rooms == 1 ? '' : 's'}',
                Colors.teal,
              ),
              if (!isActive)
                _smallBadge(
                  'Inactive',
                  Colors.orange,
                ),
            ],
          ),
          const SizedBox(height: 11),
          _detailRow('Room Type', roomType),
          _detailRow('Meal Plan', mealPlan),
          _detailRow(
            'Available Rooms',
            '$availableRooms',
          ),
          _detailRow(
            'Hotel Cost',
            hotelCost > 0
                ? 'PKR ${_money(hotelCost)}'
                : 'Not set',
          ),
          _detailRow(
            'Adult Price',
            adultPrice > 0
                ? 'PKR ${_money(adultPrice)}'
                : 'Not set',
          ),
          _detailRow(
            'Child Price',
            childPrice > 0
                ? 'PKR ${_money(childPrice)}'
                : 'Not set',
          ),
          _detailRow(
            'Combined Price',
            combinedPrice > 0
                ? 'PKR ${_money(combinedPrice)}'
                : 'Not set',
          ),
          _detailRow(
            'Tourism Commission',
            '${tourismCommission.toStringAsFixed(2)}%',
          ),
          _detailRow(
            'Hotel Commission',
            '${hotelCommission.toStringAsFixed(2)}%',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: working
                      ? null
                      : () {
                          _openEditSheet(document);
                        },
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
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                  onSelected: (action) {
                    _handleAction(
                      action: action,
                      document: document,
                    );
                  },
                  itemBuilder: (_) => <PopupMenuEntry<String>>[
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: Text(
                        isActive ? 'Disable' : 'Enable',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_featured',
                      child: Text(
                        isFeatured
                            ? 'Remove Featured'
                            : 'Mark Featured',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Text('Duplicate Package'),
                    ),
                    const PopupMenuItem(
                      value: 'history',
                      child: Text('View Audit History'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateSheet() async {
    final result = await _showForm();

    if (result == null) {
      return;
    }

    await _createCombinedPackage(result);
  }

  Future<void> _openEditSheet(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final result = await _showForm(
      existing: document.data(),
    );

    if (result == null) {
      return;
    }

    await _updateCombinedPackage(
      document: document,
      result: result,
    );
  }

  Future<_CombinedFormResult?> _showForm({
    Map<String, dynamic>? existing,
  }) async {
    final packageNameController = TextEditingController(
      text: existing?['packageName']?.toString() ?? '',
    );
    final tourPackageNameController = TextEditingController(
      text: existing?['tourPackageName']?.toString() ?? '',
    );
    final tourPackageIdController = TextEditingController(
      text: existing?['tourPackageId']?.toString() ?? '',
    );
    final hotelNameController = TextEditingController(
      text: existing?['hotelName']?.toString() ?? '',
    );
    final hotelIdController = TextEditingController(
      text: existing?['hotelId']?.toString() ?? '',
    );
    final roomTypeController = TextEditingController(
      text: existing?['roomType']?.toString() ?? '',
    );
    final roomTypeIdController = TextEditingController(
      text: existing?['roomTypeId']?.toString() ?? '',
    );
    final nightsController = TextEditingController(
      text: _readInt(
        existing?['nights'],
        fallback: 1,
      ).toString(),
    );
    final roomsController = TextEditingController(
      text: _readInt(
        existing?['rooms'],
        fallback: 1,
      ).toString(),
    );
    final availableRoomsController = TextEditingController(
      text: _readInt(
        existing?['availableRooms'],
      ).toString(),
    );
    final checkInController = TextEditingController(
      text: existing?['checkInTime']?.toString() ?? '14:00',
    );
    final checkOutController = TextEditingController(
      text: existing?['checkOutTime']?.toString() ?? '12:00',
    );
    final mealPlanController = TextEditingController(
      text: existing?['mealPlan']?.toString() ?? '',
    );
    final hotelCostController = TextEditingController(
      text: _readDouble(
        existing?['hotelCost'],
      ).toStringAsFixed(0),
    );
    final adultPriceController = TextEditingController(
      text: _readDouble(
        existing?['adultPrice'],
      ).toStringAsFixed(0),
    );
    final childPriceController = TextEditingController(
      text: _readDouble(
        existing?['childPrice'],
      ).toStringAsFixed(0),
    );
    final combinedPriceController = TextEditingController(
      text: _readDouble(
        existing?['combinedPrice'],
      ).toStringAsFixed(0),
    );
    final seasonalMultiplierController = TextEditingController(
      text: _readDouble(
        existing?['seasonalMultiplier'],
        fallback: 1,
      ).toStringAsFixed(2),
    );
    final weekendMultiplierController = TextEditingController(
      text: _readDouble(
        existing?['weekendMultiplier'],
        fallback: 1,
      ).toStringAsFixed(2),
    );
    final hotelCommissionController = TextEditingController(
      text: _readDouble(
        existing?['hotelCommissionPercent'],
      ).toStringAsFixed(2),
    );
    final tourismCommissionController = TextEditingController(
      text: _readDouble(
        existing?['tourismCommissionPercent'],
      ).toStringAsFixed(2),
    );
    final cancellationController = TextEditingController(
      text: existing?['cancellationPolicy']?.toString() ?? '',
    );
    final refundController = TextEditingController(
      text: existing?['refundPolicy']?.toString() ?? '',
    );
    final localImageController = TextEditingController(
      text: existing?['localImagePath']?.toString() ?? '',
    );
    final noteController = TextEditingController(
      text: existing?['adminNote']?.toString() ?? '',
    );
    final sortOrderController = TextEditingController(
      text: _readInt(
        existing?['sortOrder'],
        fallback: 100,
      ).toString(),
    );

    String status =
        existing?['status']?.toString() ?? 'draft';
    bool breakfastIncluded =
        existing?['breakfastIncluded'] == true;
    bool lunchIncluded =
        existing?['lunchIncluded'] == true;
    bool dinnerIncluded =
        existing?['dinnerIncluded'] == true;
    bool airportPickupIncluded =
        existing?['airportPickupIncluded'] == true;
    bool isActive =
        existing?['isActive'] != false;
    bool isFeatured =
        existing?['isFeatured'] == true;
    bool roomsAvailable =
        existing?['roomsAvailable'] != false;

    DateTime? availableFrom =
        _readDateTimeNullable(existing?['availableFrom']);
    DateTime? availableTo =
        _readDateTimeNullable(existing?['availableTo']);

    final result =
        await showModalBottomSheet<_CombinedFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
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
                          ? 'Add Tour + Hotel Package'
                          : 'Edit Tour + Hotel Package',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _sectionTitle('Basic Information'),
                    _field(
                      controller: packageNameController,
                      label: 'Combined Package Name',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller: tourPackageNameController,
                      label: 'Tour Package Name',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller: tourPackageIdController,
                      label: 'Tour Package ID',
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Hotel & Room'),
                    _field(
                      controller: hotelNameController,
                      label: 'Hotel Name',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller: hotelIdController,
                      label: 'Hotel ID',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller: roomTypeController,
                      label: 'Room Type',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller: roomTypeIdController,
                      label: 'Room Type ID',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller: nightsController,
                            label: 'Nights',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller: roomsController,
                            label: 'Rooms',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller: availableRoomsController,
                      label: 'Available Rooms',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller: checkInController,
                            label: 'Check-in Time',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller: checkOutController,
                            label: 'Check-out Time',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Meal & Inclusions'),
                    _field(
                      controller: mealPlanController,
                      label: 'Meal Plan',
                    ),
                    _switchTile(
                      title: 'Breakfast Included',
                      value: breakfastIncluded,
                      onChanged: (value) {
                        setSheetState(() {
                          breakfastIncluded = value;
                        });
                      },
                    ),
                    _switchTile(
                      title: 'Lunch Included',
                      value: lunchIncluded,
                      onChanged: (value) {
                        setSheetState(() {
                          lunchIncluded = value;
                        });
                      },
                    ),
                    _switchTile(
                      title: 'Dinner Included',
                      value: dinnerIncluded,
                      onChanged: (value) {
                        setSheetState(() {
                          dinnerIncluded = value;
                        });
                      },
                    ),
                    _switchTile(
                      title: 'Pickup Included',
                      value: airportPickupIncluded,
                      onChanged: (value) {
                        setSheetState(() {
                          airportPickupIncluded = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Pricing'),
                    _field(
                      controller: hotelCostController,
                      label: 'Hotel Cost',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller: adultPriceController,
                            label: 'Adult Price',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller: childPriceController,
                            label: 'Child Price',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller: combinedPriceController,
                      label: 'Combined Price',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller:
                                seasonalMultiplierController,
                            label: 'Seasonal Multiplier',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller:
                                weekendMultiplierController,
                            label: 'Weekend Multiplier',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller:
                                hotelCommissionController,
                            label: 'Hotel Commission %',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller:
                                tourismCommissionController,
                            label: 'Tourism Commission %',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Availability'),
                    _dateField(
                      title: 'Available From',
                      date: availableFrom,
                      onTap: () async {
                        final selected = await _pickDate(
                          initialDate:
                              availableFrom ?? DateTime.now(),
                        );
                        if (selected == null) {
                          return;
                        }
                        setSheetState(() {
                          availableFrom = selected;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _dateField(
                      title: 'Available To',
                      date: availableTo,
                      onTap: () async {
                        final selected = await _pickDate(
                          initialDate:
                              availableTo ??
                                  DateTime.now().add(
                                    const Duration(days: 30),
                                  ),
                        );
                        if (selected == null) {
                          return;
                        }
                        setSheetState(() {
                          availableTo = selected;
                        });
                      },
                    ),
                    _switchTile(
                      title: 'Rooms Available',
                      value: roomsAvailable,
                      onChanged: (value) {
                        setSheetState(() {
                          roomsAvailable = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Policies'),
                    _field(
                      controller: cancellationController,
                      label: 'Cancellation Policy',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller: refundController,
                      label: 'Refund Policy',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Admin Controls'),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      dropdownColor: darkCard,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                      ),
                      items: _statuses
                          .where((item) => item != 'all')
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item
                                    .split('_')
                                    .map(_capitalize)
                                    .join(' '),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setSheetState(() {
                          status = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller: localImageController,
                      label: 'Local Image Path',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller: sortOrderController,
                      label: 'Sort Order',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller: noteController,
                      label: 'Admin Note',
                      maxLines: 3,
                    ),
                    _switchTile(
                      title: 'Active',
                      value: isActive,
                      onChanged: (value) {
                        setSheetState(() {
                          isActive = value;
                        });
                      },
                    ),
                    _switchTile(
                      title: 'Featured',
                      value: isFeatured,
                      onChanged: (value) {
                        setSheetState(() {
                          isFeatured = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (packageNameController.text
                              .trim()
                              .isEmpty) {
                            return;
                          }

                          Navigator.pop(
                            sheetContext,
                            _CombinedFormResult(
                              packageName:
                                  packageNameController.text.trim(),
                              tourPackageName:
                                  tourPackageNameController.text.trim(),
                              tourPackageId:
                                  tourPackageIdController.text.trim(),
                              hotelName:
                                  hotelNameController.text.trim(),
                              hotelId:
                                  hotelIdController.text.trim(),
                              roomType:
                                  roomTypeController.text.trim(),
                              roomTypeId:
                                  roomTypeIdController.text.trim(),
                              nights: int.tryParse(
                                    nightsController.text.trim(),
                                  ) ??
                                  1,
                              rooms: int.tryParse(
                                    roomsController.text.trim(),
                                  ) ??
                                  1,
                              availableRooms: int.tryParse(
                                    availableRoomsController.text
                                        .trim(),
                                  ) ??
                                  0,
                              checkInTime:
                                  checkInController.text.trim(),
                              checkOutTime:
                                  checkOutController.text.trim(),
                              mealPlan:
                                  mealPlanController.text.trim(),
                              breakfastIncluded:
                                  breakfastIncluded,
                              lunchIncluded: lunchIncluded,
                              dinnerIncluded: dinnerIncluded,
                              airportPickupIncluded:
                                  airportPickupIncluded,
                              hotelCost: double.tryParse(
                                    hotelCostController.text.trim(),
                                  ) ??
                                  0,
                              adultPrice: double.tryParse(
                                    adultPriceController.text.trim(),
                                  ) ??
                                  0,
                              childPrice: double.tryParse(
                                    childPriceController.text.trim(),
                                  ) ??
                                  0,
                              combinedPrice: double.tryParse(
                                    combinedPriceController.text
                                        .trim(),
                                  ) ??
                                  0,
                              seasonalMultiplier: double.tryParse(
                                    seasonalMultiplierController.text
                                        .trim(),
                                  ) ??
                                  1,
                              weekendMultiplier: double.tryParse(
                                    weekendMultiplierController.text
                                        .trim(),
                                  ) ??
                                  1,
                              hotelCommissionPercent: double.tryParse(
                                    hotelCommissionController.text
                                        .trim(),
                                  ) ??
                                  0,
                              tourismCommissionPercent:
                                  double.tryParse(
                                        tourismCommissionController.text
                                            .trim(),
                                      ) ??
                                      0,
                              availableFrom: availableFrom,
                              availableTo: availableTo,
                              roomsAvailable: roomsAvailable,
                              cancellationPolicy:
                                  cancellationController.text.trim(),
                              refundPolicy:
                                  refundController.text.trim(),
                              status: status,
                              localImagePath:
                                  localImageController.text.trim(),
                              adminNote:
                                  noteController.text.trim(),
                              sortOrder: int.tryParse(
                                    sortOrderController.text.trim(),
                                  ) ??
                                  100,
                              isActive: isActive,
                              isFeatured: isFeatured,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: yellow,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                        child: Text(
                          existing == null
                              ? 'Create Combined Package'
                              : 'Save Changes',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
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
      packageNameController,
      tourPackageNameController,
      tourPackageIdController,
      hotelNameController,
      hotelIdController,
      roomTypeController,
      roomTypeIdController,
      nightsController,
      roomsController,
      availableRoomsController,
      checkInController,
      checkOutController,
      mealPlanController,
      hotelCostController,
      adultPriceController,
      childPriceController,
      combinedPriceController,
      seasonalMultiplierController,
      weekendMultiplierController,
      hotelCommissionController,
      tourismCommissionController,
      cancellationController,
      refundController,
      localImageController,
      noteController,
      sortOrderController,
    ]) {
      controller.dispose();
    }

    return result;
  }

  Future<void> _createCombinedPackage(
    _CombinedFormResult result,
  ) async {
    final reference = _combinedCollection.doc();

    await _setWorking(
      reference.id,
      () async {
        await reference.set(
          <String, dynamic>{
            'combinedPackageId': reference.id,
            ...result.toMap(),
            'imageUrl': '',
            'storageUploadUsed': false,
            'createdByRole': 'tourism_admin',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        await _saveAudit(
          combinedPackageId: reference.id,
          action: 'combined_package_created',
          details:
              'Tour + Hotel package created: ${result.packageName}.',
        );
      },
    );

    _showMessage(
      'Tour + Hotel package created.',
    );
  }

  Future<void> _updateCombinedPackage({
    required QueryDocumentSnapshot<Map<String, dynamic>> document,
    required _CombinedFormResult result,
  }) async {
    await _setWorking(
      document.id,
      () async {
        await document.reference.set(
          <String, dynamic>{
            ...result.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _saveAudit(
          combinedPackageId: document.id,
          action: 'combined_package_updated',
          details:
              'Tour + Hotel package updated: ${result.packageName}.',
        );
      },
    );

    _showMessage(
      'Tour + Hotel package updated.',
    );
  }

  Future<void> _handleAction({
    required String action,
    required QueryDocumentSnapshot<Map<String, dynamic>> document,
  }) async {
    switch (action) {
      case 'toggle_active':
        final newValue =
            document.data()['isActive'] == false
                ? true
                : false;

        await _updateSimpleField(
          document: document,
          update: <String, dynamic>{
            'isActive': newValue,
            'status': newValue ? 'active' : 'inactive',
          },
          action: newValue
              ? 'combined_package_enabled'
              : 'combined_package_disabled',
          details: newValue
              ? 'Tour + Hotel package enabled.'
              : 'Tour + Hotel package disabled.',
        );
        break;
      case 'toggle_featured':
        final newValue =
            document.data()['isFeatured'] == true
                ? false
                : true;

        await _updateSimpleField(
          document: document,
          update: <String, dynamic>{
            'isFeatured': newValue,
          },
          action: newValue
              ? 'combined_package_featured'
              : 'combined_package_unfeatured',
          details: newValue
              ? 'Tour + Hotel package marked featured.'
              : 'Tour + Hotel package removed from featured.',
        );
        break;
      case 'duplicate':
        await _duplicatePackage(document);
        break;
      case 'history':
        _showHistory(document);
        break;
      case 'delete':
        await _deletePackage(document);
        break;
    }
  }

  Future<void> _duplicatePackage(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data =
        Map<String, dynamic>.from(document.data());
    final reference = _combinedCollection.doc();

    data.remove('createdAt');
    data.remove('updatedAt');
    data.remove('combinedPackageId');

    await _setWorking(
      document.id,
      () async {
        await reference.set(
          <String, dynamic>{
            ...data,
            'combinedPackageId': reference.id,
            'packageName':
                '${data['packageName']?.toString() ?? 'Tour + Hotel Package'} Copy',
            'status': 'draft',
            'isActive': false,
            'isFeatured': false,
            'createdByRole': 'tourism_admin',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        await _saveAudit(
          combinedPackageId: reference.id,
          action: 'combined_package_duplicated',
          details:
              'Combined package duplicated from ${document.id}.',
        );
      },
    );

    _showMessage(
      'Package duplicated as draft.',
    );
  }

  Future<void> _deletePackage(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final confirmed = await _confirmAction(
      title: 'Delete Tour + Hotel Package',
      message:
          'Permanently delete this combined package?',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (!confirmed) {
      return;
    }

    await _setWorking(
      document.id,
      () async {
        await document.reference.delete();

        await _saveAudit(
          combinedPackageId: document.id,
          action: 'combined_package_deleted',
          details:
              'Tour + Hotel package permanently deleted.',
        );
      },
    );

    _showMessage(
      'Tour + Hotel package deleted.',
    );
  }

  Future<void> _updateSimpleField({
    required QueryDocumentSnapshot<Map<String, dynamic>> document,
    required Map<String, dynamic> update,
    required String action,
    required String details,
  }) async {
    await _setWorking(
      document.id,
      () async {
        await document.reference.set(
          <String, dynamic>{
            ...update,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await _saveAudit(
          combinedPackageId: document.id,
          action: action,
          details: details,
        );
      },
    );

    _showMessage(
      'Tour + Hotel package updated.',
    );
  }

  Future<void> _saveAudit({
    required String combinedPackageId,
    required String action,
    required String details,
  }) async {
    await _auditCollection.add(
      <String, dynamic>{
        'combinedPackageId': combinedPackageId,
        'action': action,
        'details': details,
        'performedByRole': 'tourism_admin',
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _setWorking(
    String packageId,
    Future<void> Function() action,
  ) async {
    setState(() {
      _workingPackageId = packageId;
    });

    try {
      await action();
    } catch (error) {
      _showMessage(
        'Unable to update Tour + Hotel package: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _workingPackageId = '';
        });
      }
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _auditCollection
                  .where(
                    'combinedPackageId',
                    isEqualTo: document.id,
                  )
                  .snapshots(),
              builder: (
                context,
                snapshot,
              ) {
                final logs = snapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                logs.sort(
                  (a, b) => _readDateTime(
                    b.data()['createdAt'],
                  ).compareTo(
                    _readDateTime(
                      a.data()['createdAt'],
                    ),
                  ),
                );

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: yellow,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Tour + Hotel Audit History',
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
                                'No combined package history yet.',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                20,
                              ),
                              itemCount: logs.length,
                              itemBuilder: (
                                context,
                                index,
                              ) {
                                final data = logs[index].data();

                                return Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 9,
                                  ),
                                  padding: const EdgeInsets.all(13),
                                  decoration: BoxDecoration(
                                    color: darkCard,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['action']?.toString() ??
                                            'Action',
                                        style: const TextStyle(
                                          color: yellow,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        data['details']?.toString() ??
                                            '',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _formatDateTime(
                                          _readDateTime(
                                            data['createdAt'],
                                          ),
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

  Widget _field({
    required TextEditingController controller,
    required String label,
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

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      value: value,
      activeThumbColor: yellow,
      onChanged: onChanged,
    );
  }

  Widget _dateField({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: title,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: yellow,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date == null ? 'Not set' : _formatDate(date),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate({
    required DateTime initialDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(
        DateTime.now().year - 2,
      ),
      lastDate: DateTime(
        DateTime.now().year + 10,
      ),
    );
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
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
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      destructive ? Colors.red : yellow,
                  foregroundColor:
                      destructive ? Colors.white : Colors.black,
                ),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _smallBadge(
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
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

  Widget _detailRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
              ),
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

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              color: yellow,
              size: 48,
            ),
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
              style: const TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'sold_out':
        return Colors.redAccent;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  int _readInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  double _readDouble(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  DateTime _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime? _readDateTimeNullable(dynamic value) {
    final result = _readDateTime(value);

    if (result.millisecondsSinceEpoch == 0) {
      return null;
    }

    return result;
  }

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) {
      return '';
    }

    final hour =
        date.hour.toString().padLeft(2, '0');
    final minute =
        date.minute.toString().padLeft(2, '0');

    return '${_formatDate(date)} $hour:$minute';
  }

  String _money(num amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
        );
  }

  static String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() +
        value.substring(1);
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : darkCard,
        ),
      );
  }
}

class _CombinedFormResult {
  const _CombinedFormResult({
    required this.packageName,
    required this.tourPackageName,
    required this.tourPackageId,
    required this.hotelName,
    required this.hotelId,
    required this.roomType,
    required this.roomTypeId,
    required this.nights,
    required this.rooms,
    required this.availableRooms,
    required this.checkInTime,
    required this.checkOutTime,
    required this.mealPlan,
    required this.breakfastIncluded,
    required this.lunchIncluded,
    required this.dinnerIncluded,
    required this.airportPickupIncluded,
    required this.hotelCost,
    required this.adultPrice,
    required this.childPrice,
    required this.combinedPrice,
    required this.seasonalMultiplier,
    required this.weekendMultiplier,
    required this.hotelCommissionPercent,
    required this.tourismCommissionPercent,
    required this.availableFrom,
    required this.availableTo,
    required this.roomsAvailable,
    required this.cancellationPolicy,
    required this.refundPolicy,
    required this.status,
    required this.localImagePath,
    required this.adminNote,
    required this.sortOrder,
    required this.isActive,
    required this.isFeatured,
  });

  final String packageName;
  final String tourPackageName;
  final String tourPackageId;
  final String hotelName;
  final String hotelId;
  final String roomType;
  final String roomTypeId;
  final int nights;
  final int rooms;
  final int availableRooms;
  final String checkInTime;
  final String checkOutTime;
  final String mealPlan;
  final bool breakfastIncluded;
  final bool lunchIncluded;
  final bool dinnerIncluded;
  final bool airportPickupIncluded;
  final double hotelCost;
  final double adultPrice;
  final double childPrice;
  final double combinedPrice;
  final double seasonalMultiplier;
  final double weekendMultiplier;
  final double hotelCommissionPercent;
  final double tourismCommissionPercent;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final bool roomsAvailable;
  final String cancellationPolicy;
  final String refundPolicy;
  final String status;
  final String localImagePath;
  final String adminNote;
  final int sortOrder;
  final bool isActive;
  final bool isFeatured;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'packageName': packageName,
      'tourPackageName': tourPackageName,
      'tourPackageId': tourPackageId,
      'hotelName': hotelName,
      'hotelId': hotelId,
      'roomType': roomType,
      'roomTypeId': roomTypeId,
      'nights': nights,
      'rooms': rooms,
      'availableRooms': availableRooms,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'mealPlan': mealPlan,
      'breakfastIncluded': breakfastIncluded,
      'lunchIncluded': lunchIncluded,
      'dinnerIncluded': dinnerIncluded,
      'airportPickupIncluded': airportPickupIncluded,
      'hotelCost': hotelCost,
      'adultPrice': adultPrice,
      'childPrice': childPrice,
      'combinedPrice': combinedPrice,
      'seasonalMultiplier': seasonalMultiplier,
      'weekendMultiplier': weekendMultiplier,
      'hotelCommissionPercent': hotelCommissionPercent,
      'tourismCommissionPercent': tourismCommissionPercent,
      'availableFrom': availableFrom == null
          ? null
          : Timestamp.fromDate(availableFrom!),
      'availableTo': availableTo == null
          ? null
          : Timestamp.fromDate(availableTo!),
      'roomsAvailable': roomsAvailable,
      'cancellationPolicy': cancellationPolicy,
      'refundPolicy': refundPolicy,
      'status': status,
      'localImagePath': localImagePath,
      'adminNote': adminNote,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'isFeatured': isFeatured,
    };
  }
}

