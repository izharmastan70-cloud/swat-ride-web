import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TourismPricingCommissionManagementScreen extends StatefulWidget {
  const TourismPricingCommissionManagementScreen({
    super.key,
  });

  @override
  State<TourismPricingCommissionManagementScreen> createState() =>
      _TourismPricingCommissionManagementScreenState();
}

class _TourismPricingCommissionManagementScreenState
    extends State<TourismPricingCommissionManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';
  String _selectedType = 'all';
  bool _showInactive = false;
  String _workingRuleId = '';

  CollectionReference<Map<String, dynamic>> get _rulesCollection =>
      _firestore.collection('tourism_pricing_rules');

  CollectionReference<Map<String, dynamic>> get _auditCollection =>
      _firestore.collection('tourism_pricing_audit_logs');

  final List<String> _types = const <String>[
    'all',
    'package',
    'vehicle',
    'guide',
    'driver',
    'hotel',
    'seasonal',
    'weekend',
    'holiday',
    'commission',
    'tax',
    'discount',
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
          'Tourism Pricing & Commission',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add pricing rule',
            onPressed:
                _workingRuleId.isNotEmpty ? null : _openCreateRuleSheet,
            icon: const Icon(
              Icons.add_circle_outline,
              color: yellow,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _rulesCollection.snapshots(),
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
                title: 'Unable to Load Pricing Rules',
                message: snapshot.error.toString(),
              );
            }

            final allDocuments = snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            final visibleDocuments = allDocuments.where((document) {
              final data = document.data();
              final type = data['ruleType']?.toString() ?? 'package';
              final isActive = data['isActive'] != false;

              if (!_showInactive && !isActive) {
                return false;
              }

              if (_selectedType != 'all' && type != _selectedType) {
                return false;
              }

              final query = _searchText.trim().toLowerCase();
              if (query.isEmpty) {
                return true;
              }

              final values = <String>[
                document.id,
                data['ruleName']?.toString() ?? '',
                data['ruleCode']?.toString() ?? '',
                data['targetId']?.toString() ?? '',
                data['targetName']?.toString() ?? '',
                type,
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

              return (a.data()['ruleName']?.toString() ?? '').compareTo(
                b.data()['ruleName']?.toString() ?? '',
              );
            });

            return Column(
              children: [
                _summaryHeader(allDocuments),
                _searchBox(),
                _typeFilters(),
                _inactiveSwitch(),
                Expanded(
                  child: visibleDocuments.isEmpty
                      ? _messageState(
                          icon: Icons.price_change_outlined,
                          title: 'No Pricing Rules Found',
                          message:
                              'No rule matches the selected search and filters.',
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
                            return _pricingCard(
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
        onPressed: _workingRuleId.isNotEmpty ? null : _openCreateRuleSheet,
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Pricing Rule',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _summaryHeader(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    int active = 0;
    int inactive = 0;
    int commissions = 0;
    int discounts = 0;

    for (final document in documents) {
      final data = document.data();

      if (data['isActive'] == false) {
        inactive++;
      } else {
        active++;
      }

      final type = data['ruleType']?.toString() ?? '';
      if (type == 'commission') {
        commissions++;
      }
      if (type == 'discount') {
        discounts++;
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
          _summaryItem('Inactive', inactive, Colors.orange),
          _summaryItem('Commission', commissions, Colors.blue),
          _summaryItem('Discount', discounts, Colors.purple),
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
          hintText: 'Search rule, code, package, vehicle or guide...',
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

  Widget _typeFilters() {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = _types[index];
          final selected = type == _selectedType;

          return ChoiceChip(
            selected: selected,
            label: Text(
              type == 'all' ? 'All Types' : _capitalize(type),
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
                _selectedType = type;
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
              'Show inactive pricing rules',
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

  Widget _pricingCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final ruleName =
        data['ruleName']?.toString() ?? 'Pricing Rule';
    final ruleCode =
        data['ruleCode']?.toString() ?? '';
    final ruleType =
        data['ruleType']?.toString() ?? 'package';
    final valueType =
        data['valueType']?.toString() ?? 'fixed';
    final amount = _readDouble(data['amount']);
    final percentage = _readDouble(data['percentage']);
    final minimumAmount =
        _readDouble(data['minimumAmount']);
    final maximumAmount =
        _readDouble(data['maximumAmount']);
    final targetName =
        data['targetName']?.toString() ?? '';
    final isActive = data['isActive'] != false;
    final isStackable =
        data['isStackable'] == true;
    final priority = _readInt(
      data['priority'],
      fallback: 100,
    );
    final startDate =
        _readDateTime(data['startDate']);
    final endDate =
        _readDateTime(data['endDate']);
    final working =
        _workingRuleId == document.id;

    final valueText = valueType == 'percentage'
        ? '${percentage.toStringAsFixed(2)}%'
        : 'PKR ${_money(amount)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: (isActive ? Colors.green : Colors.orange)
              .withValues(alpha: 0.28),
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
                child: Icon(
                  _typeIcon(ruleType),
                  color: yellow,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ruleName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (ruleCode.isNotEmpty) ruleCode,
                        _capitalize(ruleType),
                        if (targetName.isNotEmpty) targetName,
                      ].join(' • '),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              _smallBadge(
                isActive ? 'Active' : 'Inactive',
                isActive ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _smallBadge(
                valueText,
                ruleType == 'discount'
                    ? Colors.purple
                    : ruleType == 'commission'
                        ? Colors.blue
                        : yellow,
              ),
              _smallBadge(
                'Priority $priority',
                Colors.blueGrey,
              ),
              if (isStackable)
                _smallBadge(
                  'Stackable',
                  Colors.teal,
                ),
              if (startDate.millisecondsSinceEpoch != 0)
                _smallBadge(
                  'From ${_formatDate(startDate)}',
                  Colors.indigo,
                ),
              if (endDate.millisecondsSinceEpoch != 0)
                _smallBadge(
                  'To ${_formatDate(endDate)}',
                  Colors.deepOrange,
                ),
            ],
          ),
          const SizedBox(height: 11),
          _detailRow(
            'Minimum Amount',
            minimumAmount > 0
                ? 'PKR ${_money(minimumAmount)}'
                : 'Not set',
          ),
          _detailRow(
            'Maximum Amount',
            maximumAmount > 0
                ? 'PKR ${_money(maximumAmount)}'
                : 'Not set',
          ),
          _detailRow(
            'Applies To',
            data['appliesTo']?.toString() ?? 'all',
          ),
          _detailRow(
            'Calculation Order',
            '${_readInt(data['calculationOrder'], fallback: 100)}',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: working
                      ? null
                      : () {
                          _openEditRuleSheet(document);
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
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Text('Duplicate Rule'),
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

  Future<void> _openCreateRuleSheet() async {
    final result = await _showPricingForm();

    if (result == null) {
      return;
    }

    await _createRule(result);
  }

  Future<void> _openEditRuleSheet(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final result = await _showPricingForm(
      existing: document.data(),
    );

    if (result == null) {
      return;
    }

    await _updateRule(
      document: document,
      result: result,
    );
  }

  Future<_PricingFormResult?> _showPricingForm({
    Map<String, dynamic>? existing,
  }) async {
    final ruleNameController = TextEditingController(
      text: existing?['ruleName']?.toString() ?? '',
    );
    final ruleCodeController = TextEditingController(
      text: existing?['ruleCode']?.toString() ?? '',
    );
    final targetNameController = TextEditingController(
      text: existing?['targetName']?.toString() ?? '',
    );
    final targetIdController = TextEditingController(
      text: existing?['targetId']?.toString() ?? '',
    );
    final amountController = TextEditingController(
      text: _readDouble(
        existing?['amount'],
      ).toStringAsFixed(0),
    );
    final percentageController = TextEditingController(
      text: _readDouble(
        existing?['percentage'],
      ).toStringAsFixed(2),
    );
    final minimumAmountController = TextEditingController(
      text: _readDouble(
        existing?['minimumAmount'],
      ).toStringAsFixed(0),
    );
    final maximumAmountController = TextEditingController(
      text: _readDouble(
        existing?['maximumAmount'],
      ).toStringAsFixed(0),
    );
    final priorityController = TextEditingController(
      text: _readInt(
        existing?['priority'],
        fallback: 100,
      ).toString(),
    );
    final calculationOrderController = TextEditingController(
      text: _readInt(
        existing?['calculationOrder'],
        fallback: 100,
      ).toString(),
    );
    final noteController = TextEditingController(
      text: existing?['adminNote']?.toString() ?? '',
    );

    String ruleType =
        existing?['ruleType']?.toString() ?? 'package';
    String valueType =
        existing?['valueType']?.toString() ?? 'fixed';
    String appliesTo =
        existing?['appliesTo']?.toString() ?? 'all';

    bool isActive =
        existing?['isActive'] != false;
    bool isStackable =
        existing?['isStackable'] == true;
    bool applyBeforeTax =
        existing?['applyBeforeTax'] != false;

    DateTime? startDate =
        _readDateTimeNullable(existing?['startDate']);
    DateTime? endDate =
        _readDateTimeNullable(existing?['endDate']);

    final result =
        await showModalBottomSheet<_PricingFormResult>(
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
                          ? 'Add Pricing Rule'
                          : 'Edit Pricing Rule',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _sectionTitle('Basic Information'),
                    _field(
                      controller: ruleNameController,
                      label: 'Rule Name',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller: ruleCodeController,
                      label: 'Rule Code',
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: ruleType,
                      dropdownColor: darkCard,
                      decoration: const InputDecoration(
                        labelText: 'Rule Type',
                      ),
                      items: _types
                          .where((item) => item != 'all')
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                _capitalize(item),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setSheetState(() {
                          ruleType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: appliesTo,
                      dropdownColor: darkCard,
                      decoration: const InputDecoration(
                        labelText: 'Applies To',
                      ),
                      items: const <String>[
                        'all',
                        'group_tour',
                        'private_tour',
                        'family_tour',
                        'tour_hotel',
                        'vehicle_only',
                        'guide_only',
                      ]
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
                          appliesTo = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Target'),
                    _field(
                      controller: targetNameController,
                      label:
                          'Target Name (package, vehicle, guide, etc.)',
                    ),
                    const SizedBox(height: 10),
                    _field(
                      controller: targetIdController,
                      label: 'Target ID',
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Price / Percentage'),
                    DropdownButtonFormField<String>(
                      initialValue: valueType,
                      dropdownColor: darkCard,
                      decoration: const InputDecoration(
                        labelText: 'Value Type',
                      ),
                      items: const <String>[
                        'fixed',
                        'percentage',
                      ]
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                _capitalize(item),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setSheetState(() {
                          valueType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    if (valueType == 'fixed')
                      _field(
                        controller: amountController,
                        label: 'Fixed Amount (PKR)',
                        keyboardType: TextInputType.number,
                      )
                    else
                      _field(
                        controller: percentageController,
                        label: 'Percentage',
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller:
                                minimumAmountController,
                            label: 'Minimum Amount',
                            keyboardType:
                                TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller:
                                maximumAmountController,
                            label: 'Maximum Amount',
                            keyboardType:
                                TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Validity'),
                    _dateField(
                      title: 'Start Date',
                      date: startDate,
                      onTap: () async {
                        final selected = await _pickDate(
                          initialDate:
                              startDate ?? DateTime.now(),
                        );
                        if (selected == null) {
                          return;
                        }
                        setSheetState(() {
                          startDate = selected;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    _dateField(
                      title: 'End Date',
                      date: endDate,
                      onTap: () async {
                        final selected = await _pickDate(
                          initialDate:
                              endDate ??
                                  DateTime.now().add(
                                    const Duration(days: 30),
                                  ),
                        );
                        if (selected == null) {
                          return;
                        }
                        setSheetState(() {
                          endDate = selected;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle('Admin Controls'),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller:
                                priorityController,
                            label: 'Priority',
                            keyboardType:
                                TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            controller:
                                calculationOrderController,
                            label:
                                'Calculation Order',
                            keyboardType:
                                TextInputType.number,
                          ),
                        ),
                      ],
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
                      title: 'Stackable',
                      value: isStackable,
                      onChanged: (value) {
                        setSheetState(() {
                          isStackable = value;
                        });
                      },
                    ),
                    _switchTile(
                      title: 'Apply Before Tax',
                      value: applyBeforeTax,
                      onChanged: (value) {
                        setSheetState(() {
                          applyBeforeTax = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (ruleNameController.text
                              .trim()
                              .isEmpty) {
                            return;
                          }

                          Navigator.pop(
                            sheetContext,
                            _PricingFormResult(
                              ruleName:
                                  ruleNameController.text.trim(),
                              ruleCode:
                                  ruleCodeController.text.trim(),
                              ruleType: ruleType,
                              appliesTo: appliesTo,
                              targetName:
                                  targetNameController.text.trim(),
                              targetId:
                                  targetIdController.text.trim(),
                              valueType: valueType,
                              amount: double.tryParse(
                                    amountController.text.trim(),
                                  ) ??
                                  0,
                              percentage: double.tryParse(
                                    percentageController.text.trim(),
                                  ) ??
                                  0,
                              minimumAmount: double.tryParse(
                                    minimumAmountController.text
                                        .trim(),
                                  ) ??
                                  0,
                              maximumAmount: double.tryParse(
                                    maximumAmountController.text
                                        .trim(),
                                  ) ??
                                  0,
                              startDate: startDate,
                              endDate: endDate,
                              priority: int.tryParse(
                                    priorityController.text.trim(),
                                  ) ??
                                  100,
                              calculationOrder: int.tryParse(
                                    calculationOrderController.text
                                        .trim(),
                                  ) ??
                                  100,
                              adminNote:
                                  noteController.text.trim(),
                              isActive: isActive,
                              isStackable: isStackable,
                              applyBeforeTax: applyBeforeTax,
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
                              ? 'Create Pricing Rule'
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
      ruleNameController,
      ruleCodeController,
      targetNameController,
      targetIdController,
      amountController,
      percentageController,
      minimumAmountController,
      maximumAmountController,
      priorityController,
      calculationOrderController,
      noteController,
    ]) {
      controller.dispose();
    }

    return result;
  }

  Future<void> _createRule(
    _PricingFormResult result,
  ) async {
    final reference = _rulesCollection.doc();

    await _setWorking(
      reference.id,
      () async {
        await reference.set(
          <String, dynamic>{
            'pricingRuleId': reference.id,
            ...result.toMap(),
            'createdByRole': 'tourism_admin',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        await _saveAudit(
          pricingRuleId: reference.id,
          action: 'pricing_rule_created',
          details:
              'Pricing rule created: ${result.ruleName}.',
        );
      },
    );

    _showMessage(
      'Pricing rule created.',
    );
  }

  Future<void> _updateRule({
    required QueryDocumentSnapshot<Map<String, dynamic>> document,
    required _PricingFormResult result,
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
          pricingRuleId: document.id,
          action: 'pricing_rule_updated',
          details:
              'Pricing rule updated: ${result.ruleName}.',
        );
      },
    );

    _showMessage(
      'Pricing rule updated.',
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
          },
          action: newValue
              ? 'pricing_rule_enabled'
              : 'pricing_rule_disabled',
          details: newValue
              ? 'Pricing rule enabled.'
              : 'Pricing rule disabled.',
        );
        break;
      case 'duplicate':
        await _duplicateRule(document);
        break;
      case 'history':
        _showHistory(document);
        break;
      case 'delete':
        await _deleteRule(document);
        break;
    }
  }

  Future<void> _duplicateRule(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data =
        Map<String, dynamic>.from(document.data());
    final reference = _rulesCollection.doc();

    data.remove('createdAt');
    data.remove('updatedAt');
    data.remove('pricingRuleId');

    await _setWorking(
      document.id,
      () async {
        await reference.set(
          <String, dynamic>{
            ...data,
            'pricingRuleId': reference.id,
            'ruleName':
                '${data['ruleName']?.toString() ?? 'Pricing Rule'} Copy',
            'ruleCode':
                '${data['ruleCode']?.toString() ?? 'RULE'}-COPY',
            'isActive': false,
            'createdByRole': 'tourism_admin',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        await _saveAudit(
          pricingRuleId: reference.id,
          action: 'pricing_rule_duplicated',
          details:
              'Pricing rule duplicated from ${document.id}.',
        );
      },
    );

    _showMessage(
      'Pricing rule duplicated as inactive.',
    );
  }

  Future<void> _deleteRule(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final confirmed = await _confirmAction(
      title: 'Delete Pricing Rule',
      message:
          'Permanently delete this tourism pricing rule?',
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
          pricingRuleId: document.id,
          action: 'pricing_rule_deleted',
          details:
              'Tourism pricing rule permanently deleted.',
        );
      },
    );

    _showMessage(
      'Pricing rule deleted.',
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
          pricingRuleId: document.id,
          action: action,
          details: details,
        );
      },
    );

    _showMessage(
      'Pricing rule updated.',
    );
  }

  Future<void> _saveAudit({
    required String pricingRuleId,
    required String action,
    required String details,
  }) async {
    await _auditCollection.add(
      <String, dynamic>{
        'pricingRuleId': pricingRuleId,
        'action': action,
        'details': details,
        'performedByRole': 'tourism_admin',
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> _setWorking(
    String ruleId,
    Future<void> Function() action,
  ) async {
    setState(() {
      _workingRuleId = ruleId;
    });

    try {
      await action();
    } catch (error) {
      _showMessage(
        'Unable to update pricing rule: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _workingRuleId = '';
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
                    'pricingRuleId',
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
                            'Pricing Audit History',
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
                                'No pricing history yet.',
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
                style: const TextStyle(
                  color: Colors.white,
                ),
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
        DateTime.now().year - 5,
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
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
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

  IconData _typeIcon(String type) {
    switch (type) {
      case 'vehicle':
        return Icons.directions_car_outlined;
      case 'guide':
        return Icons.person_pin_circle_outlined;
      case 'driver':
        return Icons.airport_shuttle_outlined;
      case 'hotel':
        return Icons.hotel_outlined;
      case 'commission':
        return Icons.percent_outlined;
      case 'tax':
        return Icons.receipt_long_outlined;
      case 'discount':
        return Icons.local_offer_outlined;
      case 'seasonal':
      case 'weekend':
      case 'holiday':
        return Icons.calendar_month_outlined;
      default:
        return Icons.price_change_outlined;
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
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  DateTime _readDateTime(
    dynamic value,
  ) {
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

  DateTime? _readDateTimeNullable(
    dynamic value,
  ) {
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

class _PricingFormResult {
  const _PricingFormResult({
    required this.ruleName,
    required this.ruleCode,
    required this.ruleType,
    required this.appliesTo,
    required this.targetName,
    required this.targetId,
    required this.valueType,
    required this.amount,
    required this.percentage,
    required this.minimumAmount,
    required this.maximumAmount,
    required this.startDate,
    required this.endDate,
    required this.priority,
    required this.calculationOrder,
    required this.adminNote,
    required this.isActive,
    required this.isStackable,
    required this.applyBeforeTax,
  });

  final String ruleName;
  final String ruleCode;
  final String ruleType;
  final String appliesTo;
  final String targetName;
  final String targetId;
  final String valueType;
  final double amount;
  final double percentage;
  final double minimumAmount;
  final double maximumAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final int priority;
  final int calculationOrder;
  final String adminNote;
  final bool isActive;
  final bool isStackable;
  final bool applyBeforeTax;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ruleName': ruleName,
      'ruleCode': ruleCode,
      'ruleType': ruleType,
      'appliesTo': appliesTo,
      'targetName': targetName,
      'targetId': targetId,
      'valueType': valueType,
      'amount': amount,
      'percentage': percentage,
      'minimumAmount': minimumAmount,
      'maximumAmount': maximumAmount,
      'startDate': startDate == null
          ? null
          : Timestamp.fromDate(startDate!),
      'endDate': endDate == null
          ? null
          : Timestamp.fromDate(endDate!),
      'priority': priority,
      'calculationOrder': calculationOrder,
      'adminNote': adminNote,
      'isActive': isActive,
      'isStackable': isStackable,
      'applyBeforeTax': applyBeforeTax,
    };
  }
}
