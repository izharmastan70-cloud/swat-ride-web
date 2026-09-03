// lib/food/admin/screens/food_promo_management_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Admin Food Promo Management Screen
//
// Firestore collection:
// food_promos/{promoId}
//
// Real features:
// - Create, edit and delete promo codes
// - Enable / disable promo
// - Percentage / fixed discount
// - Minimum order and maximum discount
// - Start and end dates
// - Global or restaurant-specific promo
// - Total usage and per-user usage limits
// - Search and status filters
// - Live Firestore updates
//
// Existing non-Food modules remain untouched.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum _FoodPromoFilter { all, active, scheduled, expired, disabled }

enum _FoodPromoDiscountType { percentage, fixed }

class FoodPromoManagementScreen extends StatefulWidget {
  const FoodPromoManagementScreen({super.key});

  @override
  State<FoodPromoManagementScreen> createState() =>
      _FoodPromoManagementScreenState();
}

class _FoodPromoManagementScreenState extends State<FoodPromoManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  static const String collectionName = 'food_promos';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();

  _FoodPromoFilter _selectedFilter = _FoodPromoFilter.all;

  String _searchText = '';
  bool _isUpdating = false;

  CollectionReference<Map<String, dynamic>> get _promosRef =>
      _firestore.collection(collectionName);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<_FoodPromo>> _watchPromos() {
    return _promosRef.snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final List<_FoodPromo> promos = snapshot.docs.map((
        QueryDocumentSnapshot<Map<String, dynamic>> document,
      ) {
        return _FoodPromo.fromMap(id: document.id, map: document.data());
      }).toList();

      promos.sort(
        (_FoodPromo first, _FoodPromo second) =>
            second.createdAt.compareTo(first.createdAt),
      );

      return promos;
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<_FoodPromo> _filterPromos(List<_FoodPromo> promos) {
    final DateTime now = DateTime.now();
    final String query = _searchText.trim().toLowerCase();

    return promos.where((_FoodPromo promo) {
      final bool statusMatches;

      switch (_selectedFilter) {
        case _FoodPromoFilter.all:
          statusMatches = true;
          break;
        case _FoodPromoFilter.active:
          statusMatches =
              promo.isEnabled &&
              !now.isBefore(promo.startAt) &&
              !now.isAfter(promo.endAt);
          break;
        case _FoodPromoFilter.scheduled:
          statusMatches = promo.isEnabled && now.isBefore(promo.startAt);
          break;
        case _FoodPromoFilter.expired:
          statusMatches = now.isAfter(promo.endAt);
          break;
        case _FoodPromoFilter.disabled:
          statusMatches = !promo.isEnabled;
          break;
      }

      if (!statusMatches) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final String searchable = <String>[
        promo.code,
        promo.title,
        promo.description,
        promo.restaurantId,
        promo.discountType.name,
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  int _countForFilter(List<_FoodPromo> promos, _FoodPromoFilter filter) {
    final DateTime now = DateTime.now();

    switch (filter) {
      case _FoodPromoFilter.all:
        return promos.length;
      case _FoodPromoFilter.active:
        return promos
            .where(
              (_FoodPromo promo) =>
                  promo.isEnabled &&
                  !now.isBefore(promo.startAt) &&
                  !now.isAfter(promo.endAt),
            )
            .length;
      case _FoodPromoFilter.scheduled:
        return promos
            .where(
              (_FoodPromo promo) =>
                  promo.isEnabled && now.isBefore(promo.startAt),
            )
            .length;
      case _FoodPromoFilter.expired:
        return promos
            .where((_FoodPromo promo) => now.isAfter(promo.endAt))
            .length;
      case _FoodPromoFilter.disabled:
        return promos.where((_FoodPromo promo) => !promo.isEnabled).length;
    }
  }

  Future<void> _savePromo(_FoodPromo promo) async {
    if (_isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final DocumentReference<Map<String, dynamic>> reference =
          promo.id.trim().isEmpty ? _promosRef.doc() : _promosRef.doc(promo.id);

      final _FoodPromo saved = promo.copyWith(
        id: reference.id,
        updatedAt: DateTime.now(),
      );

      await reference.set(saved.toMap(), SetOptions(merge: true));

      _showMessage(
        promo.id.trim().isEmpty
            ? 'Food promo created successfully.'
            : 'Food promo updated successfully.',
      );
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'Unable to save food promo.');
    } catch (error) {
      _showMessage('Unable to save food promo: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _togglePromo(_FoodPromo promo) async {
    if (_isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _promosRef.doc(promo.id).set(<String, dynamic>{
        'isEnabled': !promo.isEnabled,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      _showMessage(!promo.isEnabled ? 'Promo enabled.' : 'Promo disabled.');
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'Unable to update promo status.');
    } catch (error) {
      _showMessage('Unable to update promo status: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _deletePromo(_FoodPromo promo) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Delete Promo?'),
          content: Text(
            'Promo code ${promo.code} will be permanently deleted.',
            style: const TextStyle(color: Colors.grey, height: 1.4),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _promosRef.doc(promo.id).delete();

      _showMessage('Food promo deleted.');
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'Unable to delete food promo.');
    } catch (error) {
      _showMessage('Unable to delete food promo: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _openPromoForm({_FoodPromo? promo}) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final TextEditingController codeController = TextEditingController(
      text: promo?.code ?? '',
    );

    final TextEditingController titleController = TextEditingController(
      text: promo?.title ?? '',
    );

    final TextEditingController descriptionController = TextEditingController(
      text: promo?.description ?? '',
    );

    final TextEditingController valueController = TextEditingController(
      text: promo == null ? '' : promo.discountValue.toStringAsFixed(0),
    );

    final TextEditingController minimumOrderController = TextEditingController(
      text: promo == null ? '0' : promo.minimumOrderAmount.toStringAsFixed(0),
    );

    final TextEditingController maximumDiscountController =
        TextEditingController(
          text: promo == null
              ? '0'
              : promo.maximumDiscountAmount.toStringAsFixed(0),
        );

    final TextEditingController totalUsageLimitController =
        TextEditingController(
          text: promo == null ? '0' : '${promo.totalUsageLimit}',
        );

    final TextEditingController perUserLimitController = TextEditingController(
      text: promo == null ? '1' : '${promo.perUserUsageLimit}',
    );

    final TextEditingController restaurantIdController = TextEditingController(
      text: promo?.restaurantId ?? '',
    );

    _FoodPromoDiscountType discountType =
        promo?.discountType ?? _FoodPromoDiscountType.percentage;

    DateTime startAt = promo?.startAt ?? DateTime.now();

    DateTime endAt =
        promo?.endAt ?? DateTime.now().add(const Duration(days: 30));

    bool isGlobal = promo?.isGlobal ?? true;
    bool isEnabled = promo?.isEnabled ?? true;

    final _FoodPromo? result = await showModalBottomSheet<_FoodPromo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setSheetState,
              ) {
                Future<void> pickStartDate() async {
                  final DateTime? selected = await showDatePicker(
                    context: context,
                    initialDate: startAt,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2035),
                  );

                  if (selected == null) {
                    return;
                  }

                  setSheetState(() {
                    startAt = selected;
                  });
                }

                Future<void> pickEndDate() async {
                  final DateTime? selected = await showDatePicker(
                    context: context,
                    initialDate: endAt,
                    firstDate: startAt,
                    lastDate: DateTime(2035),
                  );

                  if (selected == null) {
                    return;
                  }

                  setSheetState(() {
                    endAt = selected;
                  });
                }

                return SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 18,
                      right: 18,
                      top: 18,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 18,
                    ),
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Center(
                              child: Container(
                                width: 42,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade700,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              promo == null
                                  ? 'Create Food Promo'
                                  : 'Edit Food Promo',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _formField(
                              controller: codeController,
                              label: 'Promo code',
                              icon: Icons.local_offer_outlined,
                              validator: _requiredValidator,
                              textCapitalization: TextCapitalization.characters,
                            ),
                            const SizedBox(height: 12),
                            _formField(
                              controller: titleController,
                              label: 'Promo title',
                              icon: Icons.title,
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            _formField(
                              controller: descriptionController,
                              label: 'Description',
                              icon: Icons.description_outlined,
                              validator: _requiredValidator,
                              minLines: 2,
                              maxLines: 4,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<_FoodPromoDiscountType>(
                              initialValue: discountType,
                              dropdownColor: const Color(0xFF252525),
                              decoration: _inputDecoration(
                                label: 'Discount type',
                                icon: Icons.discount_outlined,
                              ),
                              items: _FoodPromoDiscountType.values
                                  .map(
                                    (_FoodPromoDiscountType type) =>
                                        DropdownMenuItem<
                                          _FoodPromoDiscountType
                                        >(
                                          value: type,
                                          child: Text(
                                            type ==
                                                    _FoodPromoDiscountType
                                                        .percentage
                                                ? 'Percentage'
                                                : 'Fixed Amount',
                                          ),
                                        ),
                                  )
                                  .toList(),
                              onChanged: (_FoodPromoDiscountType? value) {
                                if (value == null) {
                                  return;
                                }

                                setSheetState(() {
                                  discountType = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _numberField(
                              controller: valueController,
                              label:
                                  discountType ==
                                      _FoodPromoDiscountType.percentage
                                  ? 'Discount percentage'
                                  : 'Discount amount',
                              suffix:
                                  discountType ==
                                      _FoodPromoDiscountType.percentage
                                  ? '%'
                                  : 'Rs.',
                              maxValue:
                                  discountType ==
                                      _FoodPromoDiscountType.percentage
                                  ? 100
                                  : 1000000,
                            ),
                            const SizedBox(height: 12),
                            _numberField(
                              controller: minimumOrderController,
                              label: 'Minimum order amount',
                              suffix: 'Rs.',
                              maxValue: 1000000,
                            ),
                            const SizedBox(height: 12),
                            _numberField(
                              controller: maximumDiscountController,
                              label: 'Maximum discount (0 = no limit)',
                              suffix: 'Rs.',
                              maxValue: 1000000,
                            ),
                            const SizedBox(height: 12),
                            _numberField(
                              controller: totalUsageLimitController,
                              label: 'Total usage limit (0 = unlimited)',
                              suffix: '',
                              maxValue: 1000000,
                              integerOnly: true,
                            ),
                            const SizedBox(height: 12),
                            _numberField(
                              controller: perUserLimitController,
                              label: 'Per-user usage limit',
                              suffix: '',
                              maxValue: 100000,
                              integerOnly: true,
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: isGlobal,
                              onChanged: (bool value) {
                                setSheetState(() {
                                  isGlobal = value;
                                });
                              },
                              activeThumbColor: yellow,
                              title: const Text(
                                'Global Promo',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text(
                                'When disabled, promo applies to one restaurant only.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            if (!isGlobal) ...<Widget>[
                              const SizedBox(height: 8),
                              _formField(
                                controller: restaurantIdController,
                                label: 'Restaurant ID',
                                icon: Icons.storefront_outlined,
                                validator: _requiredValidator,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: _dateTile(
                                    title: 'Start Date',
                                    date: startAt,
                                    onTap: pickStartDate,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _dateTile(
                                    title: 'End Date',
                                    date: endAt,
                                    onTap: pickEndDate,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: isEnabled,
                              onChanged: (bool value) {
                                setSheetState(() {
                                  isEnabled = value;
                                });
                              },
                              activeThumbColor: yellow,
                              title: const Text(
                                'Promo Enabled',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: () {
                                  final bool valid =
                                      formKey.currentState?.validate() ?? false;

                                  if (!valid) {
                                    return;
                                  }

                                  if (endAt.isBefore(startAt)) {
                                    return;
                                  }

                                  final DateTime now = DateTime.now();

                                  Navigator.pop(
                                    sheetContext,
                                    _FoodPromo(
                                      id: promo?.id ?? '',
                                      code: codeController.text
                                          .trim()
                                          .toUpperCase(),
                                      title: titleController.text.trim(),
                                      description: descriptionController.text
                                          .trim(),
                                      discountType: discountType,
                                      discountValue: double.parse(
                                        valueController.text.trim(),
                                      ),
                                      minimumOrderAmount: double.parse(
                                        minimumOrderController.text.trim(),
                                      ),
                                      maximumDiscountAmount: double.parse(
                                        maximumDiscountController.text.trim(),
                                      ),
                                      totalUsageLimit: int.parse(
                                        totalUsageLimitController.text.trim(),
                                      ),
                                      perUserUsageLimit: int.parse(
                                        perUserLimitController.text.trim(),
                                      ),
                                      usedCount: promo?.usedCount ?? 0,
                                      isGlobal: isGlobal,
                                      restaurantId: isGlobal
                                          ? ''
                                          : restaurantIdController.text.trim(),
                                      isEnabled: isEnabled,
                                      startAt: startAt,
                                      endAt: endAt,
                                      createdAt: promo?.createdAt ?? now,
                                      updatedAt: now,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: yellow,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: Text(
                                  promo == null
                                      ? 'Create Promo'
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
                    ),
                  ),
                );
              },
        );
      },
    );

    codeController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    valueController.dispose();
    minimumOrderController.dispose();
    maximumDiscountController.dispose();
    totalUsageLimitController.dispose();
    perUserLimitController.dispose();
    restaurantIdController.dispose();

    if (result == null) {
      return;
    }

    await _savePromo(result);
  }

  static String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    return null;
  }

  static Widget _formField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    int minLines = 1,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      textCapitalization: textCapitalization,
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  static Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required double maxValue,
    bool integerOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix.isEmpty ? null : suffix,
        filled: true,
        fillColor: const Color(0xFF252525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (String? value) {
        final String text = value?.trim() ?? '';

        if (text.isEmpty) {
          return 'This field is required';
        }

        if (integerOnly) {
          final int? parsed = int.tryParse(text);

          if (parsed == null || parsed < 0 || parsed > maxValue) {
            return 'Enter a valid whole number';
          }

          return null;
        }

        final double? parsed = double.tryParse(text);

        if (parsed == null || parsed < 0 || parsed > maxValue) {
          return 'Enter a valid value';
        }

        return null;
      },
    );
  }

  static InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: yellow),
      filled: true,
      fillColor: const Color(0xFF252525),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: yellow),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  static Widget _dateTile({
    required String title,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF252525),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const SizedBox(height: 5),
              Text(
                _dateText(date),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _dateText(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');

    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Food Promo Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Create promo',
            onPressed: _isUpdating ? null : () => _openPromoForm(),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUpdating ? null : () => _openPromoForm(),
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create Promo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<_FoodPromo>>(
          stream: _watchPromos(),
          builder:
              (BuildContext context, AsyncSnapshot<List<_FoodPromo>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: yellow),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState();
                }

                final List<_FoodPromo> allPromos =
                    snapshot.data ?? const <_FoodPromo>[];

                final List<_FoodPromo> visiblePromos = _filterPromos(allPromos);

                return Column(
                  children: <Widget>[
                    _buildSummary(allPromos),
                    _buildSearchField(),
                    _buildFilters(allPromos),
                    Expanded(
                      child: visiblePromos.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              color: yellow,
                              onRefresh: () async {
                                setState(() {});
                              },
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  10,
                                  16,
                                  100,
                                ),
                                itemCount: visiblePromos.length,
                                separatorBuilder:
                                    (BuildContext context, int index) =>
                                        const SizedBox(height: 12),
                                itemBuilder: (BuildContext context, int index) {
                                  final _FoodPromo promo = visiblePromos[index];

                                  return _FoodPromoCard(
                                    promo: promo,
                                    isUpdating: _isUpdating,
                                    onEdit: () => _openPromoForm(promo: promo),
                                    onToggle: () => _togglePromo(promo),
                                    onDelete: () => _deletePromo(promo),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
        ),
      ),
    );
  }

  Widget _buildSummary(List<_FoodPromo> promos) {
    final int active = _countForFilter(promos, _FoodPromoFilter.active);

    final int scheduled = _countForFilter(promos, _FoodPromoFilter.scheduled);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 29,
            backgroundColor: Colors.black,
            child: Icon(Icons.local_offer_outlined, color: yellow, size: 31),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Food Promo Codes',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$active active ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¢ $scheduled scheduled',
                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${promos.length}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (String value) {
          setState(() {
            _searchText = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search code, title or restaurant',
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
                  icon: const Icon(Icons.close),
                ),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(List<_FoodPromo> promos) {
    final List<_PromoFilterItem> filters = <_PromoFilterItem>[
      const _PromoFilterItem(filter: _FoodPromoFilter.all, label: 'All'),
      const _PromoFilterItem(filter: _FoodPromoFilter.active, label: 'Active'),
      const _PromoFilterItem(
        filter: _FoodPromoFilter.scheduled,
        label: 'Scheduled',
      ),
      const _PromoFilterItem(
        filter: _FoodPromoFilter.expired,
        label: 'Expired',
      ),
      const _PromoFilterItem(
        filter: _FoodPromoFilter.disabled,
        label: 'Disabled',
      ),
    ];

    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final _PromoFilterItem item = filters[index];

          final bool selected = _selectedFilter == item.filter;

          final int count = _countForFilter(promos, item.filter);

          return ChoiceChip(
            label: Text('${item.label} ($count)'),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedFilter = item.filter;
              });
            },
            selectedColor: yellow,
            backgroundColor: cardColor,
            checkmarkColor: Colors.black,
            labelStyle: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.local_offer_outlined, color: yellow, size: 76),
            SizedBox(height: 16),
            Text(
              'No food promos found',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Create a promo code or change the selected filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.cloud_off, color: Colors.redAccent, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Unable to load food promos',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check Firestore connection and security rules.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodPromoCard extends StatelessWidget {
  const _FoodPromoCard({
    required this.promo,
    required this.isUpdating,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final _FoodPromo promo;
  final bool isUpdating;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = promo.statusColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: statusColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.14),
                child: const Icon(Icons.local_offer_outlined, color: yellow),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      promo.code,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      promo.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  promo.statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            promo.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 7,
            children: <Widget>[
              _tag(Icons.discount_outlined, promo.discountText),
              _tag(
                Icons.shopping_cart_outlined,
                'Min Rs. ${promo.minimumOrderAmount.toStringAsFixed(0)}',
              ),
              _tag(
                Icons.people_outline,
                promo.totalUsageLimit <= 0
                    ? '${promo.usedCount} used'
                    : '${promo.usedCount}/${promo.totalUsageLimit} used',
              ),
              _tag(
                Icons.storefront_outlined,
                promo.isGlobal ? 'Global' : 'Restaurant',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_FoodPromoManagementScreenState._dateText(promo.startAt)} - '
            '${_FoodPromoManagementScreenState._dateText(promo.endAt)}',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 13),
          Row(
            children: <Widget>[
              Switch(
                value: promo.isEnabled,
                onChanged: isUpdating ? null : (_) => onToggle(),
                activeThumbColor: yellow,
              ),
              const Text(
                'Enabled',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Edit promo',
                onPressed: isUpdating ? null : onEdit,
                icon: const Icon(Icons.edit_outlined, color: yellow),
              ),
              IconButton(
                tooltip: 'Delete promo',
                onPressed: isUpdating ? null : onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _tag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF272727),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: yellow, size: 13),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}

class _FoodPromo {
  const _FoodPromo({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minimumOrderAmount,
    required this.maximumDiscountAmount,
    required this.totalUsageLimit,
    required this.perUserUsageLimit,
    required this.usedCount,
    required this.isGlobal,
    required this.restaurantId,
    required this.isEnabled,
    required this.startAt,
    required this.endAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final _FoodPromoDiscountType discountType;
  final double discountValue;
  final double minimumOrderAmount;
  final double maximumDiscountAmount;
  final int totalUsageLimit;
  final int perUserUsageLimit;
  final int usedCount;
  final bool isGlobal;
  final String restaurantId;
  final bool isEnabled;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get discountText {
    if (discountType == _FoodPromoDiscountType.percentage) {
      return '${discountValue.toStringAsFixed(0)}% OFF';
    }

    return 'Rs. ${discountValue.toStringAsFixed(0)} OFF';
  }

  String get statusText {
    final DateTime now = DateTime.now();

    if (!isEnabled) {
      return 'Disabled';
    }

    if (now.isBefore(startAt)) {
      return 'Scheduled';
    }

    if (now.isAfter(endAt)) {
      return 'Expired';
    }

    return 'Active';
  }

  Color get statusColor {
    switch (statusText) {
      case 'Active':
        return Colors.greenAccent;
      case 'Scheduled':
        return Colors.lightBlueAccent;
      case 'Expired':
        return Colors.redAccent;
      case 'Disabled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  factory _FoodPromo.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final String discountType = _stringValue(
      map['discountType'],
      fallback: 'percentage',
    ).toLowerCase();

    return _FoodPromo(
      id: id,
      code: _stringValue(map['code']).toUpperCase(),
      title: _stringValue(map['title']),
      description: _stringValue(map['description']),
      discountType: discountType == 'fixed'
          ? _FoodPromoDiscountType.fixed
          : _FoodPromoDiscountType.percentage,
      discountValue: _doubleValue(map['discountValue']),
      minimumOrderAmount: _doubleValue(map['minimumOrderAmount']),
      maximumDiscountAmount: _doubleValue(map['maximumDiscountAmount']),
      totalUsageLimit: _intValue(map['totalUsageLimit']),
      perUserUsageLimit: _intValue(map['perUserUsageLimit'], fallback: 1),
      usedCount: _intValue(map['usedCount']),
      isGlobal: _boolValue(map['isGlobal'], fallback: true),
      restaurantId: _stringValue(map['restaurantId']),
      isEnabled: _boolValue(map['isEnabled'], fallback: true),
      startAt: _dateTimeValue(map['startAt']) ?? DateTime.now(),
      endAt:
          _dateTimeValue(map['endAt']) ??
          DateTime.now().add(const Duration(days: 30)),
      createdAt: _dateTimeValue(map['createdAt']) ?? DateTime.now(),
      updatedAt: _dateTimeValue(map['updatedAt']) ?? DateTime.now(),
    );
  }

  _FoodPromo copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    _FoodPromoDiscountType? discountType,
    double? discountValue,
    double? minimumOrderAmount,
    double? maximumDiscountAmount,
    int? totalUsageLimit,
    int? perUserUsageLimit,
    int? usedCount,
    bool? isGlobal,
    String? restaurantId,
    bool? isEnabled,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return _FoodPromo(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      maximumDiscountAmount:
          maximumDiscountAmount ?? this.maximumDiscountAmount,
      totalUsageLimit: totalUsageLimit ?? this.totalUsageLimit,
      perUserUsageLimit: perUserUsageLimit ?? this.perUserUsageLimit,
      usedCount: usedCount ?? this.usedCount,
      isGlobal: isGlobal ?? this.isGlobal,
      restaurantId: restaurantId ?? this.restaurantId,
      isEnabled: isEnabled ?? this.isEnabled,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'promoId': id,
      'code': code,
      'title': title,
      'description': description,
      'discountType': discountType.name,
      'discountValue': discountValue,
      'minimumOrderAmount': minimumOrderAmount,
      'maximumDiscountAmount': maximumDiscountAmount,
      'totalUsageLimit': totalUsageLimit,
      'perUserUsageLimit': perUserUsageLimit,
      'usedCount': usedCount,
      'isGlobal': isGlobal,
      'restaurantId': restaurantId,
      'isEnabled': isEnabled,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static String _stringValue(dynamic value, {String fallback = ''}) {
    final String text = value?.toString().trim() ?? '';

    return text.isEmpty ? fallback : text;
  }

  static double _doubleValue(dynamic value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int _intValue(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _boolValue(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text = value?.toString().trim().toLowerCase() ?? '';

    if (text == 'true' || text == '1' || text == 'yes') {
      return true;
    }

    if (text == 'false' || text == '0' || text == 'no') {
      return false;
    }

    return fallback;
  }

  static DateTime? _dateTimeValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    try {
      final dynamic converted = value.toDate();

      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Firestore Timestamp support.
    }

    return DateTime.tryParse(value.toString());
  }
}

class _PromoFilterItem {
  const _PromoFilterItem({required this.filter, required this.label});

  final _FoodPromoFilter filter;
  final String label;
}
