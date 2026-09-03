import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HotelPricingManagementScreen extends StatefulWidget {
  const HotelPricingManagementScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelPricingManagementScreen> createState() =>
      _HotelPricingManagementScreenState();
}

class _HotelPricingManagementScreenState
    extends State<HotelPricingManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _isSaving = false;
  String _searchText = '';

  final TextEditingController _searchController =
      TextEditingController();

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
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Hotel Pricing',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('hotel_rooms')
              .where(
                'hotelId',
                isEqualTo: widget.hotelId,
              )
              .snapshots(),
          builder: (
            context,
            AsyncSnapshot<
                    QuerySnapshot<
                        Map<String, dynamic>>>
                snapshot,
          ) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: yellow,
                ),
              );
            }

            if (snapshot.hasError) {
              return _messageState(
                icon: Icons.error_outline,
                title: 'Unable to Load Rooms',
                message: snapshot.error.toString(),
              );
            }

            final List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>
                rooms = snapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            final String search =
                _searchText.trim().toLowerCase();

            final filteredRooms = rooms.where(
              (room) {
                final Map<String, dynamic> data =
                    room.data();

                final String name =
                    data['name']?.toString() ??
                        data['roomName']
                            ?.toString() ??
                        'Room';

                final String type =
                    data['roomType']?.toString() ??
                        data['type']?.toString() ??
                        '';

                return search.isEmpty ||
                    name.toLowerCase().contains(
                          search,
                        ) ||
                    type.toLowerCase().contains(
                          search,
                        );
              },
            ).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                28,
              ),
              children: [
                _infoCard(),
                const SizedBox(height: 16),
                _searchBox(),
                const SizedBox(height: 16),
                if (filteredRooms.isEmpty)
                  _messageState(
                    icon: Icons.meeting_room_outlined,
                    title: 'No Rooms Found',
                    message:
                        'Add hotel rooms first. Room pricing will appear here automatically.',
                  )
                else
                  ...filteredRooms.map(
                    (room) => _roomPricingCard(
                      room,
                    ),
                  ),
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
        color: yellow.withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: yellow,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Set room-wise base, weekend, seasonal and holiday prices. Discounts and charges are saved in Firestore. Real payment settlement remains bypassed until billing is enabled.',
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
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText:
            'Search room name or type...',
        hintStyle: const TextStyle(
          color: Colors.grey,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: yellow,
        ),
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
          borderRadius:
              BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _roomPricingCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        room,
  ) {
    final Map<String, dynamic> data =
        room.data();

    final String name =
        data['name']?.toString() ??
            data['roomName']?.toString() ??
            'Room';

    final String type =
        data['roomType']?.toString() ??
            data['type']?.toString() ??
            'Standard';

    final Map<String, dynamic> pricing =
        data['pricing'] is Map
            ? Map<String, dynamic>.from(
                data['pricing'] as Map,
              )
            : <String, dynamic>{};

    final double basePrice = _readNumber(
      pricing['basePrice'] ??
          data['pricePerNight'] ??
          data['price'],
    );

    final double weekendPrice = _readNumber(
      pricing['weekendPrice'],
    );

    final double seasonalPrice = _readNumber(
      pricing['seasonalPrice'],
    );

    final double holidayPrice = _readNumber(
      pricing['holidayPrice'],
    );

    final double discountPercent =
        _readNumber(
      pricing['discountPercent'],
    );

    final double extraGuestCharge =
        _readNumber(
      pricing['extraGuestCharge'],
    );

    final double childCharge = _readNumber(
      pricing['childCharge'],
    );

    final double taxPercent = _readNumber(
      pricing['taxPercent'],
    );

    final double serviceChargePercent =
        _readNumber(
      pricing['serviceChargePercent'],
    );

    final double adminCommissionPercent =
        _readNumber(
      pricing['adminCommissionPercent'],
    );

    final bool breakfastIncluded =
        pricing['breakfastIncluded'] ==
            true;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: yellow.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bed_outlined,
                  color: yellow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Rs. ${basePrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: yellow,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _priceRow(
            'Weekend',
            weekendPrice,
          ),
          _priceRow(
            'Seasonal',
            seasonalPrice,
          ),
          _priceRow(
            'Holiday',
            holidayPrice,
          ),
          _priceRow(
            'Discount',
            discountPercent,
            suffix: '%',
          ),
          _priceRow(
            'Extra Guest',
            extraGuestCharge,
          ),
          _priceRow(
            'Child Charge',
            childCharge,
          ),
          _priceRow(
            'Tax',
            taxPercent,
            suffix: '%',
          ),
          _priceRow(
            'Service Charge',
            serviceChargePercent,
            suffix: '%',
          ),
          _priceRow(
            'Admin Commission',
            adminCommissionPercent,
            suffix: '%',
          ),
          _priceRow(
            'Breakfast',
            breakfastIncluded ? 1 : 0,
            customValue: breakfastIncluded
                ? 'Included'
                : 'Not Included',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving
                  ? null
                  : () {
                      _openPricingEditor(
                        room: room,
                        roomName: name,
                        initialPricing: pricing,
                        currentBasePrice:
                            basePrice,
                      );
                    },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor:
                    Colors.black,
              ),
              icon: const Icon(
                Icons.edit_outlined,
              ),
              label: const Text(
                'Edit Pricing',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String title,
    double value, {
    String suffix = 'Rs.',
    String? customValue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 7,
      ),
      child: Row(
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
          Text(
            customValue ??
                (value <= 0
                    ? 'Not set'
                    : suffix == '%'
                        ? '${value.toStringAsFixed(0)}%'
                        : 'Rs. ${value.toStringAsFixed(0)}'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPricingEditor({
    required QueryDocumentSnapshot<
            Map<String, dynamic>>
        room,
    required String roomName,
    required Map<String, dynamic>
        initialPricing,
    required double currentBasePrice,
  }) async {
    final GlobalKey<FormState> formKey =
        GlobalKey<FormState>();

    final TextEditingController
        baseController =
        TextEditingController(
      text: _numberText(
        initialPricing['basePrice'] ??
            currentBasePrice,
      ),
    );

    final TextEditingController
        weekendController =
        TextEditingController(
      text: _numberText(
        initialPricing['weekendPrice'],
      ),
    );

    final TextEditingController
        seasonalController =
        TextEditingController(
      text: _numberText(
        initialPricing['seasonalPrice'],
      ),
    );

    final TextEditingController
        holidayController =
        TextEditingController(
      text: _numberText(
        initialPricing['holidayPrice'],
      ),
    );

    final TextEditingController
        discountController =
        TextEditingController(
      text: _numberText(
        initialPricing['discountPercent'],
      ),
    );

    final TextEditingController
        extraGuestController =
        TextEditingController(
      text: _numberText(
        initialPricing['extraGuestCharge'],
      ),
    );

    final TextEditingController
        childController =
        TextEditingController(
      text: _numberText(
        initialPricing['childCharge'],
      ),
    );

    final TextEditingController
        taxController =
        TextEditingController(
      text: _numberText(
        initialPricing['taxPercent'],
      ),
    );

    final TextEditingController
        serviceChargeController =
        TextEditingController(
      text: _numberText(
        initialPricing[
            'serviceChargePercent'],
      ),
    );

    final TextEditingController
        commissionController =
        TextEditingController(
      text: _numberText(
        initialPricing[
            'adminCommissionPercent'],
      ),
    );

    bool breakfastIncluded =
        initialPricing[
                'breakfastIncluded'] ==
            true;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: darkBackground,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            return SafeArea(
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  MediaQuery.of(context)
                          .viewInsets
                          .bottom +
                      20,
                ),
                child:
                    SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          '$roomName Pricing',
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontSize: 21,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        _numberField(
                          controller:
                              baseController,
                          label:
                              'Base price per night',
                          suffix: 'Rs.',
                          required: true,
                        ),
                        _numberField(
                          controller:
                              weekendController,
                          label:
                              'Weekend price',
                          suffix: 'Rs.',
                        ),
                        _numberField(
                          controller:
                              seasonalController,
                          label:
                              'Seasonal price',
                          suffix: 'Rs.',
                        ),
                        _numberField(
                          controller:
                              holidayController,
                          label:
                              'Holiday price',
                          suffix: 'Rs.',
                        ),
                        _numberField(
                          controller:
                              discountController,
                          label:
                              'Discount',
                          suffix: '%',
                          isPercentage:
                              true,
                        ),
                        _numberField(
                          controller:
                              extraGuestController,
                          label:
                              'Extra guest charge',
                          suffix: 'Rs.',
                        ),
                        _numberField(
                          controller:
                              childController,
                          label:
                              'Child charge',
                          suffix: 'Rs.',
                        ),
                        _numberField(
                          controller:
                              taxController,
                          label: 'Tax',
                          suffix: '%',
                          isPercentage:
                              true,
                        ),
                        _numberField(
                          controller:
                              serviceChargeController,
                          label:
                              'Service charge',
                          suffix: '%',
                          isPercentage:
                              true,
                        ),
                        _numberField(
                          controller:
                              commissionController,
                          label:
                              'Admin commission preview',
                          suffix: '%',
                          isPercentage:
                              true,
                        ),
                        SwitchListTile(
                          value:
                              breakfastIncluded,
                          onChanged:
                              (value) {
                            setSheetState(
                              () {
                                breakfastIncluded =
                                    value;
                              },
                            );
                          },
                          activeThumbColor:
                              yellow,
                          contentPadding:
                              EdgeInsets.zero,
                          title: const Text(
                            'Breakfast Included',
                            style: TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle:
                              const Text(
                            'Show breakfast as included in room price.',
                            style: TextStyle(
                              color:
                                  Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        _previewCard(
                          baseController:
                              baseController,
                          taxController:
                              taxController,
                          serviceChargeController:
                              serviceChargeController,
                          commissionController:
                              commissionController,
                          discountController:
                              discountController,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        SizedBox(
                          width:
                              double.infinity,
                          child:
                              ElevatedButton.icon(
                            onPressed:
                                () async {
                              final bool valid =
                                  formKey
                                          .currentState
                                          ?.validate() ??
                                      false;

                              if (!valid) {
                                return;
                              }

                              Navigator.pop(
                                sheetContext,
                              );

                              await _savePricing(
                                roomReference:
                                    room.reference,
                                basePrice:
                                    _toDouble(
                                  baseController
                                      .text,
                                ),
                                weekendPrice:
                                    _toNullableDouble(
                                  weekendController
                                      .text,
                                ),
                                seasonalPrice:
                                    _toNullableDouble(
                                  seasonalController
                                      .text,
                                ),
                                holidayPrice:
                                    _toNullableDouble(
                                  holidayController
                                      .text,
                                ),
                                discountPercent:
                                    _toNullableDouble(
                                  discountController
                                      .text,
                                ),
                                extraGuestCharge:
                                    _toNullableDouble(
                                  extraGuestController
                                      .text,
                                ),
                                childCharge:
                                    _toNullableDouble(
                                  childController
                                      .text,
                                ),
                                taxPercent:
                                    _toNullableDouble(
                                  taxController.text,
                                ),
                                serviceChargePercent:
                                    _toNullableDouble(
                                  serviceChargeController
                                      .text,
                                ),
                                adminCommissionPercent:
                                    _toNullableDouble(
                                  commissionController
                                      .text,
                                ),
                                breakfastIncluded:
                                    breakfastIncluded,
                              );
                            },
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  yellow,
                              foregroundColor:
                                  Colors.black,
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                vertical: 15,
                              ),
                            ),
                            icon: const Icon(
                              Icons.save_outlined,
                            ),
                            label: const Text(
                              'Save Pricing',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
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

    baseController.dispose();
    weekendController.dispose();
    seasonalController.dispose();
    holidayController.dispose();
    discountController.dispose();
    extraGuestController.dispose();
    childController.dispose();
    taxController.dispose();
    serviceChargeController.dispose();
    commissionController.dispose();
  }

  Widget _numberField({
    required TextEditingController
        controller,
    required String label,
    required String suffix,
    bool required = false,
    bool isPercentage = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(
          decimal: true,
        ),
        validator: (value) {
          final String text =
              value?.trim() ?? '';

          if (required && text.isEmpty) {
            return 'This field is required.';
          }

          if (text.isEmpty) {
            return null;
          }

          final double? number =
              double.tryParse(text);

          if (number == null) {
            return 'Enter a valid number.';
          }

          if (number < 0) {
            return 'Value cannot be negative.';
          }

          if (isPercentage &&
              number > 100) {
            return 'Percentage cannot exceed 100.';
          }

          return null;
        },
        style: const TextStyle(
          color: Colors.white,
        ),
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
            borderRadius:
                BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _previewCard({
    required TextEditingController
        baseController,
    required TextEditingController
        taxController,
    required TextEditingController
        serviceChargeController,
    required TextEditingController
        commissionController,
    required TextEditingController
        discountController,
  }) {
    final double base =
        _toNullableDouble(
              baseController.text,
            ) ??
            0;

    final double discount =
        _toNullableDouble(
              discountController.text,
            ) ??
            0;

    final double tax =
        _toNullableDouble(
              taxController.text,
            ) ??
            0;

    final double serviceCharge =
        _toNullableDouble(
              serviceChargeController.text,
            ) ??
            0;

    final double commission =
        _toNullableDouble(
              commissionController.text,
            ) ??
            0;

    final double discounted =
        base - (base * discount / 100);

    final double customerTotal =
        discounted +
            (discounted * tax / 100) +
            (discounted *
                serviceCharge /
                100);

    final double adminShare =
        discounted * commission / 100;

    final double hotelReceivable =
        customerTotal - adminShare;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _previewRow(
            'Customer Price',
            customerTotal,
          ),
          _previewRow(
            'Admin Commission',
            adminShare,
          ),
          _previewRow(
            'Hotel Receivable',
            hotelReceivable,
          ),
        ],
      ),
    );
  }

  Widget _previewRow(
    String title,
    double value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
          Text(
            'Rs. ${value.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePricing({
    required DocumentReference<
            Map<String, dynamic>>
        roomReference,
    required double basePrice,
    required double? weekendPrice,
    required double? seasonalPrice,
    required double? holidayPrice,
    required double? discountPercent,
    required double? extraGuestCharge,
    required double? childCharge,
    required double? taxPercent,
    required double? serviceChargePercent,
    required double? adminCommissionPercent,
    required bool breakfastIncluded,
  }) async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in first.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await roomReference.set(
        <String, dynamic>{
          'pricePerNight': basePrice,
          'price': basePrice,
          'pricing': <String, dynamic>{
            'basePrice': basePrice,
            'weekendPrice': weekendPrice,
            'seasonalPrice': seasonalPrice,
            'holidayPrice': holidayPrice,
            'discountPercent': discountPercent,
            'extraGuestCharge':
                extraGuestCharge,
            'childCharge': childCharge,
            'taxPercent': taxPercent,
            'serviceChargePercent':
                serviceChargePercent,
            'adminCommissionPercent':
                adminCommissionPercent,
            'breakfastIncluded':
                breakfastIncluded,
            'updatedBy': user.uid,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _showMessage(
        'Room pricing updated successfully.',
      );
    } catch (error) {
      _showMessage(
        'Unable to save room pricing: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: yellow,
            size: 46,
          ),
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

  double _toDouble(
    String value,
  ) {
    return double.tryParse(
          value.trim(),
        ) ??
        0;
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

  String _numberText(
    dynamic value,
  ) {
    final double number =
        _readNumber(value);

    if (number <= 0) {
      return '';
    }

    return number == number.roundToDouble()
        ? number.toStringAsFixed(0)
        : number.toStringAsFixed(2);
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
