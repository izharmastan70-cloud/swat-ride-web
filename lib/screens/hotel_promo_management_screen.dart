import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HotelPromoManagementScreen extends StatefulWidget {
  const HotelPromoManagementScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelPromoManagementScreen> createState() =>
      _HotelPromoManagementScreenState();
}

class _HotelPromoManagementScreenState
    extends State<HotelPromoManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';
  String _selectedFilter = 'all';
  bool _isWorking = false;

  CollectionReference<Map<String, dynamic>> get _promoCollection =>
      _firestore.collection('hotel_promo_codes');

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
          'Hotel Promo Codes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isWorking
            ? null
            : () {
                _openPromoForm();
              },
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create Promo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _promoCollection
              .where('hotelId', isEqualTo: widget.hotelId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: yellow),
              );
            }

            if (snapshot.hasError) {
              return _messageState(
                icon: Icons.error_outline,
                title: 'Unable to Load Promo Codes',
                message: snapshot.error.toString(),
              );
            }

            final docs = snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            docs.sort((a, b) {
              final DateTime aDate = _readDateTime(a.data()['updatedAt']);
              final DateTime bDate = _readDateTime(b.data()['updatedAt']);
              return bDate.compareTo(aDate);
            });

            final filtered = docs.where((doc) {
              final data = doc.data();
              final String code =
                  data['code']?.toString().toLowerCase() ?? '';
              final String title =
                  data['title']?.toString().toLowerCase() ?? '';
              final bool isActive = data['isActive'] == true;
              final DateTime endDate = _readDateTime(data['endDate']);
              final bool expired = endDate.isBefore(DateTime.now());

              final String query = _searchText.trim().toLowerCase();
              final bool searchMatch = query.isEmpty ||
                  code.contains(query) ||
                  title.contains(query);

              bool filterMatch = true;

              if (_selectedFilter == 'active') {
                filterMatch = isActive && !expired;
              } else if (_selectedFilter == 'inactive') {
                filterMatch = !isActive;
              } else if (_selectedFilter == 'expired') {
                filterMatch = expired;
              }

              return searchMatch && filterMatch;
            }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _infoCard(),
                const SizedBox(height: 16),
                _searchBox(),
                const SizedBox(height: 10),
                _filterChips(),
                const SizedBox(height: 18),
                if (filtered.isEmpty)
                  _messageState(
                    icon: Icons.local_offer_outlined,
                    title: 'No Promo Codes',
                    message: _searchText.isEmpty
                        ? 'Create hotel discount codes for selected rooms and booking periods.'
                        : 'No promo code matches your search.',
                  )
                else
                  ...filtered.map(_promoCard),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: yellow.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: yellow),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Create percentage or fixed discounts. Promo validation works through Firestore. Real payment deduction will follow the same discount data after billing integration is enabled.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchText = value;
        });
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search promo code or title...',
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
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _filterChips() {
    const filters = <String>[
      'all',
      'active',
      'inactive',
      'expired',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final bool selected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              label: Text(_filterLabel(filter)),
              selectedColor: yellow.withValues(alpha: 0.25),
              checkmarkColor: yellow,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
              side: BorderSide(
                color: selected
                    ? yellow
                    : Colors.white.withValues(alpha: 0.06),
              ),
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _promoCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final String code = data['code']?.toString() ?? 'PROMO';
    final String title = data['title']?.toString() ?? code;
    final String discountType =
        data['discountType']?.toString() ?? 'percentage';
    final double discountValue = _readNumber(data['discountValue']);
    final double minimumBookingAmount =
        _readNumber(data['minimumBookingAmount']);
    final double maximumDiscount =
        _readNumber(data['maximumDiscount']);
    final int usageLimit = _readInt(data['usageLimit']);
    final int usedCount = _readInt(data['usedCount']);
    final bool isActive = data['isActive'] == true;

    final DateTime startDate = _readDateTime(data['startDate']);
    final DateTime endDate = _readDateTime(data['endDate']);

    final bool expired = endDate.isBefore(DateTime.now());
    final bool fullyUsed = usageLimit > 0 && usedCount >= usageLimit;
    final bool currentlyActive =
        isActive && !expired && !fullyUsed;

    final List<String> roomIds = data['applicableRoomIds'] is List
        ? List<String>.from(
            (data['applicableRoomIds'] as List)
                .map((item) => item.toString()),
          )
        : <String>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: currentlyActive
              ? yellow.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: yellow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  color: yellow,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      code.toUpperCase(),
                      style: const TextStyle(
                        color: yellow,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(
                expired
                    ? 'expired'
                    : fullyUsed
                        ? 'used'
                        : currentlyActive
                            ? 'active'
                            : 'inactive',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _detailRow(
            'Discount',
            discountType == 'fixed'
                ? 'Rs. ${discountValue.toStringAsFixed(0)}'
                : '${discountValue.toStringAsFixed(0)}%',
          ),
          _detailRow(
            'Minimum Booking',
            minimumBookingAmount <= 0
                ? 'No minimum'
                : 'Rs. ${minimumBookingAmount.toStringAsFixed(0)}',
          ),
          if (discountType == 'percentage')
            _detailRow(
              'Maximum Discount',
              maximumDiscount <= 0
                  ? 'No limit'
                  : 'Rs. ${maximumDiscount.toStringAsFixed(0)}',
            ),
          _detailRow(
            'Valid Dates',
            '${_formatDate(startDate)} - ${_formatDate(endDate)}',
          ),
          _detailRow(
            'Usage',
            usageLimit <= 0
                ? '$usedCount / Unlimited'
                : '$usedCount / $usageLimit',
          ),
          _detailRow(
            'Applicable Rooms',
            roomIds.isEmpty
                ? 'All rooms'
                : '${roomIds.length} selected',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isWorking
                      ? null
                      : () {
                          _openPromoForm(
                            existingDocument: document,
                          );
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
              IconButton(
                tooltip: isActive ? 'Disable' : 'Enable',
                onPressed: _isWorking
                    ? null
                    : () {
                        _togglePromo(
                          document.reference,
                          !isActive,
                        );
                      },
                style: IconButton.styleFrom(
                  backgroundColor: isActive
                      ? Colors.orange.withValues(alpha: 0.12)
                      : Colors.green.withValues(alpha: 0.12),
                  foregroundColor:
                      isActive ? Colors.orange : Colors.green,
                ),
                icon: Icon(
                  isActive
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Delete',
                onPressed: _isWorking
                    ? null
                    : () {
                        _confirmDelete(document);
                      },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.12),
                  foregroundColor: Colors.red,
                ),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'Active';
        break;
      case 'expired':
        color = Colors.orange;
        label = 'Expired';
        break;
      case 'used':
        color = Colors.blueGrey;
        label = 'Fully Used';
        break;
      default:
        color = Colors.red;
        label = 'Inactive';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
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
                fontSize: 12,
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
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPromoForm({
    QueryDocumentSnapshot<Map<String, dynamic>>? existingDocument,
  }) async {
    final bool isEdit = existingDocument != null;
    final Map<String, dynamic> existingData =
        existingDocument?.data() ?? <String, dynamic>{};

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final TextEditingController codeController =
        TextEditingController(
      text: existingData['code']?.toString() ?? '',
    );

    final TextEditingController titleController =
        TextEditingController(
      text: existingData['title']?.toString() ?? '',
    );

    final TextEditingController discountController =
        TextEditingController(
      text: _numberText(existingData['discountValue']),
    );

    final TextEditingController minimumController =
        TextEditingController(
      text: _numberText(existingData['minimumBookingAmount']),
    );

    final TextEditingController maximumController =
        TextEditingController(
      text: _numberText(existingData['maximumDiscount']),
    );

    final TextEditingController usageLimitController =
        TextEditingController(
      text: _integerText(existingData['usageLimit']),
    );

    String discountType =
        existingData['discountType']?.toString() ?? 'percentage';

    bool isActive =
        existingData['isActive'] != false;

    DateTime startDate = existingData['startDate'] == null
        ? DateTime.now()
        : _readDateTime(existingData['startDate']);

    DateTime endDate = existingData['endDate'] == null
        ? DateTime.now().add(const Duration(days: 30))
        : _readDateTime(existingData['endDate']);

    final List<String> selectedRoomIds =
        existingData['applicableRoomIds'] is List
            ? List<String>.from(
                (existingData['applicableRoomIds'] as List)
                    .map((item) => item.toString()),
              )
            : <String>[];

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: darkBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit
                              ? 'Edit Promo Code'
                              : 'Create Promo Code',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _textField(
                          controller: codeController,
                          label: 'Promo code',
                          hint: 'Example: SWAT20',
                          icon: Icons.code,
                          validator: (value) {
                            final String code =
                                value?.trim().toUpperCase() ?? '';

                            if (code.length < 3) {
                              return 'Promo code must contain at least 3 characters.';
                            }

                            if (!RegExp(r'^[A-Z0-9_-]+$').hasMatch(code)) {
                              return 'Use letters, numbers, underscore or dash only.';
                            }

                            return null;
                          },
                        ),
                        _textField(
                          controller: titleController,
                          label: 'Offer title',
                          hint: 'Example: Summer Discount',
                          icon: Icons.title,
                          validator: _requiredValidator,
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: darkCard,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: discountType,
                              isExpanded: true,
                              dropdownColor: darkCard,
                              items: const [
                                DropdownMenuItem(
                                  value: 'percentage',
                                  child: Text('Percentage Discount'),
                                ),
                                DropdownMenuItem(
                                  value: 'fixed',
                                  child: Text('Fixed Discount'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }

                                setSheetState(() {
                                  discountType = value;
                                });
                              },
                            ),
                          ),
                        ),
                        _numberField(
                          controller: discountController,
                          label: discountType == 'fixed'
                              ? 'Fixed discount amount'
                              : 'Discount percentage',
                          suffix:
                              discountType == 'fixed' ? 'Rs.' : '%',
                          required: true,
                          isPercentage:
                              discountType == 'percentage',
                        ),
                        _numberField(
                          controller: minimumController,
                          label: 'Minimum booking amount',
                          suffix: 'Rs.',
                        ),
                        if (discountType == 'percentage')
                          _numberField(
                            controller: maximumController,
                            label: 'Maximum discount',
                            suffix: 'Rs.',
                          ),
                        _numberField(
                          controller: usageLimitController,
                          label: 'Maximum usage limit',
                          suffix: 'uses',
                          wholeNumber: true,
                        ),
                        _dateTile(
                          title: 'Start Date',
                          date: startDate,
                          onTap: () async {
                            final DateTime? selected =
                                await _pickDate(startDate);

                            if (selected != null) {
                              setSheetState(() {
                                startDate = selected;
                              });
                            }
                          },
                        ),
                        _dateTile(
                          title: 'End Date',
                          date: endDate,
                          onTap: () async {
                            final DateTime? selected =
                                await _pickDate(endDate);

                            if (selected != null) {
                              setSheetState(() {
                                endDate = selected;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Applicable Rooms',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _roomSelector(
                          selectedRoomIds: selectedRoomIds,
                          onChanged: () {
                            setSheetState(() {});
                          },
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          value: isActive,
                          onChanged: (value) {
                            setSheetState(() {
                              isActive = value;
                            });
                          },
                          activeThumbColor: yellow,
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Promo Active',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            'Inactive promos remain saved but cannot be applied.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final bool valid =
                                  formKey.currentState?.validate() ??
                                      false;

                              if (!valid) {
                                return;
                              }

                              if (endDate.isBefore(startDate)) {
                                _showMessage(
                                  'End date cannot be before start date.',
                                  isError: true,
                                );
                                return;
                              }

                              Navigator.pop(sheetContext);

                              await _savePromo(
                                existingDocument: existingDocument,
                                code: codeController.text
                                    .trim()
                                    .toUpperCase(),
                                title: titleController.text.trim(),
                                discountType: discountType,
                                discountValue: _toDouble(
                                  discountController.text,
                                ),
                                minimumBookingAmount:
                                    _toNullableDouble(
                                  minimumController.text,
                                ),
                                maximumDiscount:
                                    discountType == 'percentage'
                                        ? _toNullableDouble(
                                            maximumController.text,
                                          )
                                        : null,
                                usageLimit: _toNullableInt(
                                  usageLimitController.text,
                                ),
                                startDate: startDate,
                                endDate: endDate,
                                applicableRoomIds: selectedRoomIds,
                                isActive: isActive,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: yellow,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                            ),
                            icon: const Icon(Icons.save_outlined),
                            label: Text(
                              isEdit
                                  ? 'Save Changes'
                                  : 'Create Promo Code',
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
    discountController.dispose();
    minimumController.dispose();
    maximumController.dispose();
    usageLimitController.dispose();
  }

  Widget _roomSelector({
    required List<String> selectedRoomIds,
    required VoidCallback onChanged,
  }) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _firestore
          .collection('hotel_rooms')
          .where('hotelId', isEqualTo: widget.hotelId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const LinearProgressIndicator(
            color: yellow,
          );
        }

        final rooms = snapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        if (rooms.isEmpty) {
          return const Text(
            'No rooms found. Leave empty to apply promo to all rooms.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          );
        }

        return Column(
          children: [
            CheckboxListTile(
              value: selectedRoomIds.isEmpty,
              onChanged: (value) {
                if (value == true) {
                  selectedRoomIds.clear();
                  onChanged();
                }
              },
              activeColor: yellow,
              checkColor: Colors.black,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'All Rooms',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...rooms.map((room) {
              final data = room.data();
              final String name =
                  data['name']?.toString() ??
                      data['roomName']?.toString() ??
                      'Room';

              final bool selected =
                  selectedRoomIds.contains(room.id);

              return CheckboxListTile(
                value: selected,
                onChanged: (value) {
                  if (value == true) {
                    if (!selectedRoomIds.contains(room.id)) {
                      selectedRoomIds.add(room.id);
                    }
                  } else {
                    selectedRoomIds.remove(room.id);
                  }

                  onChanged();
                },
                activeColor: yellow,
                checkColor: Colors.black,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: yellow),
          filled: true,
          fillColor: darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    bool required = false,
    bool isPercentage = false,
    bool wholeNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(
          decimal: !wholeNumber,
        ),
        validator: (value) {
          final String text = value?.trim() ?? '';

          if (required && text.isEmpty) {
            return 'This field is required.';
          }

          if (text.isEmpty) {
            return null;
          }

          final double? number = double.tryParse(text);

          if (number == null) {
            return 'Enter a valid number.';
          }

          if (number < 0) {
            return 'Value cannot be negative.';
          }

          if (isPercentage && number > 100) {
            return 'Percentage cannot exceed 100.';
          }

          if (wholeNumber && number != number.roundToDouble()) {
            return 'Enter a whole number.';
          }

          return null;
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          prefixIcon: const Icon(
            Icons.payments_outlined,
            color: yellow,
          ),
          filled: true,
          fillColor: darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _dateTile({
    required String title,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(
          Icons.calendar_month_outlined,
          color: yellow,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _formatDate(date),
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
      ),
    );
  }

  Future<DateTime?> _pickDate(
    DateTime initialDate,
  ) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ),
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ),
    );
  }

  Future<void> _savePromo({
    required QueryDocumentSnapshot<Map<String, dynamic>>?
        existingDocument,
    required String code,
    required String title,
    required String discountType,
    required double discountValue,
    required double? minimumBookingAmount,
    required double? maximumDiscount,
    required int? usageLimit,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> applicableRoomIds,
    required bool isActive,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in first.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      final QuerySnapshot<Map<String, dynamic>> duplicate =
          await _promoCollection
              .where('hotelId', isEqualTo: widget.hotelId)
              .where('code', isEqualTo: code)
              .limit(1)
              .get();

      if (duplicate.docs.isNotEmpty &&
          duplicate.docs.first.id != existingDocument?.id) {
        throw StateError(
          'This promo code already exists for the hotel.',
        );
      }

      final Map<String, dynamic> payload =
          <String, dynamic>{
        'hotelId': widget.hotelId,
        'code': code,
        'title': title,
        'discountType': discountType,
        'discountValue': discountValue,
        'minimumBookingAmount':
            minimumBookingAmount ?? 0,
        'maximumDiscount': maximumDiscount,
        'usageLimit': usageLimit ?? 0,
        'usedCount':
            existingDocument?.data()['usedCount'] ?? 0,
        'startDate': Timestamp.fromDate(
          DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          ),
        ),
        'endDate': Timestamp.fromDate(
          DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
          ),
        ),
        'applicableRoomIds':
            List<String>.from(applicableRoomIds),
        'isActive': isActive,
        'updatedBy': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (existingDocument == null) {
        payload['createdBy'] = user.uid;
        payload['createdAt'] =
            FieldValue.serverTimestamp();

        await _promoCollection.add(payload);
      } else {
        await existingDocument.reference.set(
          payload,
          SetOptions(merge: true),
        );
      }

      _showMessage(
        existingDocument == null
            ? 'Promo code created successfully.'
            : 'Promo code updated successfully.',
      );
    } catch (error) {
      _showMessage(
        error.toString(),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _togglePromo(
    DocumentReference<Map<String, dynamic>> reference,
    bool isActive,
  ) async {
    setState(() {
      _isWorking = true;
    });

    try {
      await reference.update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showMessage(
        isActive
            ? 'Promo code enabled.'
            : 'Promo code disabled.',
      );
    } catch (error) {
      _showMessage(
        'Unable to update promo code: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _confirmDelete(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final String code =
        document.data()['code']?.toString() ?? 'promo';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Delete Promo Code',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Delete $code permanently?',
            style: const TextStyle(
              color: Colors.grey,
            ),
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
                backgroundColor: Colors.red,
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
      _isWorking = true;
    });

    try {
      await document.reference.delete();

      _showMessage(
        'Promo code deleted.',
      );
    } catch (error) {
      _showMessage(
        'Unable to delete promo code: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: yellow, size: 46),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
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
    );
  }

  String _filterLabel(
    String filter,
  ) {
    switch (filter) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'expired':
        return 'Expired';
      default:
        return 'All';
    }
  }

  String? _requiredValidator(
    String? value,
  ) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  double _readNumber(
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

  int _readInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
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

  String _numberText(
    dynamic value,
  ) {
    final double number = _readNumber(value);

    if (number <= 0) {
      return '';
    }

    return number == number.roundToDouble()
        ? number.toStringAsFixed(0)
        : number.toStringAsFixed(2);
  }

  String _integerText(
    dynamic value,
  ) {
    final int number = _readInt(value);

    return number <= 0 ? '' : '$number';
  }

  double _toDouble(
    String value,
  ) {
    return double.tryParse(value.trim()) ?? 0;
  }

  double? _toNullableDouble(
    String value,
  ) {
    final String clean = value.trim();

    if (clean.isEmpty) {
      return null;
    }

    return double.tryParse(clean);
  }

  int? _toNullableInt(
    String value,
  ) {
    final String clean = value.trim();

    if (clean.isEmpty) {
      return null;
    }

    return int.tryParse(clean);
  }

  String _formatDate(
    DateTime date,
  ) {
    if (date.millisecondsSinceEpoch == 0) {
      return 'Not set';
    }

    final String day =
        date.day.toString().padLeft(2, '0');
    final String month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
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
