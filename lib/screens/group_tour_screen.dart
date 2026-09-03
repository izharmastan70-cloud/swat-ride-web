import 'package:flutter/material.dart';

import '../services/tourism_pricing_service.dart';

class GroupTourScreen extends StatefulWidget {
  const GroupTourScreen({
    super.key,
    required this.destinationName,
  });

  final String destinationName;

  @override
  State<GroupTourScreen> createState() =>
      _GroupTourScreenState();
}

class _GroupTourScreenState extends State<GroupTourScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final TourismPricingService _pricingService =
      TourismPricingService();

  String selectedTourDuration = '3 Days / 2 Nights';
  String selectedHotelCategory = 'Standard';
  String pickupLocation = 'Mingora, Swat';

  DateTime? tourStartDate;

  int guests = 1;

  // =========================================================
  // REAL ADMIN / FIRESTORE PRICING
  // =========================================================

  double _adminBasePricePerPerson = 0;
  double _adminHotelCategoryExtra = 0;
  double _advancePercentage = 30;

  bool _pricingLoading = true;
  String? _pricingError;

  @override
  void initState() {
    super.initState();
    _loadAdminPricing();
  }

  Future<void> _loadAdminPricing() async {
    if (mounted) {
      setState(() {
        _pricingLoading = true;
        _pricingError = null;
      });
    }

    try {
      final DateTime effectiveDate =
          tourStartDate ?? DateTime.now();

      final List<Map<String, dynamic>> rules =
          await _pricingService.getActivePricingRules(
        appliesTo: 'group_tour',
        targetName: widget.destinationName,
        at: effectiveDate,
      );

      double basePrice = 0;
      double hotelExtra = 0;
      double advancePercentage = 30;

      for (final Map<String, dynamic> rule in rules) {
        final String ruleType =
            rule['ruleType']?.toString().trim().toLowerCase() ?? '';
        final String ruleCode =
            rule['ruleCode']?.toString().trim().toLowerCase() ?? '';
        final String targetName =
            rule['targetName']?.toString().trim().toLowerCase() ?? '';
        final String valueType =
            rule['valueType']?.toString().trim().toLowerCase() ?? '';

        final double amount = _readDouble(rule['amount']);
        final double percentage =
            _readDouble(rule['percentage']);

        final bool durationMatch =
            targetName == selectedTourDuration.toLowerCase() ||
                ruleCode.contains(
                  _durationCode(selectedTourDuration),
                );

        final bool hotelMatch =
            targetName == selectedHotelCategory.toLowerCase() ||
                ruleCode.contains(
                  selectedHotelCategory.toLowerCase(),
                );

        final bool isAdvance =
            ruleType.contains('advance') ||
                ruleCode.contains('advance');

        final bool isHotel =
            ruleType.contains('hotel') ||
                ruleCode.contains('hotel');

        final bool isBase =
            ruleType.contains('base') ||
                ruleType.contains('package') ||
                ruleType.contains('price') ||
                ruleCode.contains('base') ||
                ruleCode.contains('package') ||
                ruleCode.contains('per_person');

        if (isAdvance &&
            valueType == 'percentage' &&
            percentage > 0) {
          advancePercentage = percentage;
          continue;
        }

        if (isHotel &&
            hotelMatch &&
            valueType != 'percentage' &&
            amount >= 0) {
          hotelExtra = amount;
          continue;
        }

        if (isBase &&
            durationMatch &&
            valueType != 'percentage' &&
            amount > 0) {
          basePrice = amount;
        }
      }

      if (basePrice <= 0) {
        throw Exception(
          'No active admin group-tour price found for '
          '$selectedTourDuration / ${widget.destinationName}.',
        );
      }

      if (!mounted) return;

      setState(() {
        _adminBasePricePerPerson = basePrice;
        _adminHotelCategoryExtra = hotelExtra;
        _advancePercentage = advancePercentage;
        _pricingLoading = false;
        _pricingError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _adminBasePricePerPerson = 0;
        _adminHotelCategoryExtra = 0;
        _pricingLoading = false;
        _pricingError = error.toString();
      });
    }
  }

  String _durationCode(String duration) {
    return duration
        .toLowerCase()
        .replaceAll(' / ', '_')
        .replaceAll(' ', '_');
  }

  double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  final List<String> tourDurations = const [
    '2 Days / 1 Night',
    '3 Days / 2 Nights',
    '4 Days / 3 Nights',
    '5 Days / 4 Nights',
  ];

  final List<String> hotelCategories = const [
    'Budget',
    'Standard',
    'Family',
    'Luxury',
  ];

  double get _pricePerPerson {
    return _adminBasePricePerPerson +
        _adminHotelCategoryExtra;
  }

  Map<String, double> get _quotation {
    return _pricingService.calculateGroupTour(
      pricePerPerson: _pricePerPerson,
      numberOfGuests: guests,
    );
  }

  double get _finalPrice {
    return _quotation['finalPrice'] ?? 0;
  }

  double get _advanceAmount {
    return _pricingService.calculateAdvancePayment(
      finalPrice: _finalPrice,
      advancePercentage: _advancePercentage,
    );
  }

  double get _remainingAmount {
    return _pricingService.calculateRemainingPayment(
      finalPrice: _finalPrice,
      advancePaid: _advanceAmount,
    );
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
          'Group / Sharing Tour',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Join a Group Tour',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Explore Swat with other travellers and enjoy an affordable per-person tour package.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // =================================================
              // SELECTED DESTINATION
              // =================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: yellow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: yellow.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: yellow,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.destinationName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // =================================================
              // PICKUP LOCATION
              // =================================================
              _sectionTitle('Pickup Location'),
              const SizedBox(height: 10),
              InkWell(
                onTap: _openPickupLocationSelector,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        color: yellow,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tour Pickup',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pickupLocation,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_right,
                        color: yellow,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // =================================================
              // TOUR START DATE
              // =================================================
              _sectionTitle('Tour Start Date'),
              const SizedBox(height: 10),
              InkWell(
                onTap: _selectTourStartDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: yellow,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Date',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(tourStartDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_right,
                        color: yellow,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // =================================================
              // TOUR DURATION
              // =================================================
              _sectionTitle('Select Tour Duration'),
              const SizedBox(height: 10),
              _dropdownCard(
                value: selectedTourDuration,
                items: tourDurations,
                icon: Icons.calendar_month,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    selectedTourDuration = value;
                  });
                  _loadAdminPricing();
                },
              ),
              const SizedBox(height: 22),

              // =================================================
              // HOTEL CATEGORY
              // =================================================
              _sectionTitle('Hotel Category'),
              const SizedBox(height: 10),
              _dropdownCard(
                value: selectedHotelCategory,
                items: hotelCategories,
                icon: Icons.hotel,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    selectedHotelCategory = value;
                  });
                  _loadAdminPricing();
                },
              ),
              const SizedBox(height: 22),

              // =================================================
              // NUMBER OF GUESTS
              // =================================================
              _sectionTitle('Number of Guests'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: yellow.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.groups,
                        color: yellow,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Travellers',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Select how many people will join the tour.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: guests > 1
                          ? () {
                              setState(() {
                                guests--;
                              });
                            }
                          : null,
                      icon: Icon(
                        Icons.remove_circle,
                        color: guests > 1
                            ? yellow
                            : Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '$guests',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: guests < 20
                          ? () {
                              setState(() {
                                guests++;
                              });
                            }
                          : null,
                      icon: Icon(
                        Icons.add_circle,
                        color: guests < 20
                            ? yellow
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // =================================================
              // PACKAGE INCLUDES
              // =================================================
              _sectionTitle('Tour Package Includes'),
              const SizedBox(height: 12),
              _includedItem(
                icon: Icons.directions_bus,
                title: 'Group Transport',
                subtitle:
                    'Shared HiAce, Grand Cabin or another suitable group vehicle.',
              ),
              _includedItem(
                icon: Icons.hotel,
                title: 'Hotel Stay',
                subtitle:
                    '$selectedHotelCategory hotel accommodation according to the selected package.',
              ),
              _includedItem(
                icon: Icons.local_gas_station,
                title: 'Fuel',
                subtitle:
                    'Fuel cost is included according to the selected group package.',
              ),
              _includedItem(
                icon: Icons.terrain,
                title: 'Jeep / 4x4',
                subtitle:
                    'A 4x4 vehicle may be arranged for difficult routes when required.',
              ),
              _includedItem(
                icon: Icons.map,
                title: 'Tour Route',
                subtitle:
                    'Planned route covering the selected destination and nearby attractions.',
              ),
              const SizedBox(height: 24),

              // =================================================
              // NOT INCLUDED
              // =================================================
              _sectionTitle('Not Included'),
              const SizedBox(height: 12),
              _excludedItem('Food and personal meals'),
              _excludedItem(
                'Chairlift and adventure activity tickets',
              ),
              _excludedItem(
                'Boating and other activity charges',
              ),
              _excludedItem(
                'Personal shopping expenses',
              ),
              const SizedBox(height: 24),

              // =================================================
              // SUMMARY
              // =================================================
              _sectionTitle('Tour Summary'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  children: [
                    _summaryRow(
                      'Destination',
                      widget.destinationName,
                    ),
                    _summaryRow(
                      'Pickup',
                      pickupLocation,
                    ),
                    _summaryRow(
                      'Start Date',
                      _formatDate(tourStartDate),
                    ),
                    _summaryRow(
                      'Duration',
                      selectedTourDuration,
                    ),
                    _summaryRow(
                      'Travellers',
                      '$guests',
                    ),
                    _summaryRow(
                      'Hotel',
                      selectedHotelCategory,
                    ),
                    _summaryRow(
                      'Transport',
                      'Shared Group Vehicle',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // =================================================
              // ESTIMATED PRICE
              // =================================================
              _sectionTitle('Estimated Price'),
              const SizedBox(height: 12),
              _buildEstimatedPriceCard(),
              const SizedBox(height: 24),

              // =================================================
              // QUOTATION BUTTON
              // =================================================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _pricingLoading || _pricePerPerson <= 0
                          ? null
                          : _requestQuotation,
                  icon: const Icon(
                    Icons.request_quote,
                    color: Colors.black,
                  ),
                  label: const Text(
                    'Request Tour Quotation',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Tour pricing is loaded from active Admin/Firestore rules. Live payment and Firebase booking remain paused until their billing-dependent phase.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPickupLocationSelector() async {
    final String? result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: darkBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        final List<String> locations = [
          'Mingora, Swat',
          'Saidu Sharif, Swat',
          'Fizagat, Swat',
          'Bahrain, Swat',
          'Kalam, Swat',
          'Current Location (Testing)',
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              18,
              16,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Pickup Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a local testing pickup point. Real GPS will be enabled later.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: locations.map(
                      (location) {
                        final bool selected =
                            pickupLocation == location;

                        return ListTile(
                          leading: Icon(
                            location ==
                                    'Current Location (Testing)'
                                ? Icons.my_location
                                : Icons.location_on,
                            color: yellow,
                          ),
                          title: Text(
                            location,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          trailing: Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selected
                                ? yellow
                                : Colors.grey,
                          ),
                          onTap: () {
                            Navigator.pop(
                              sheetContext,
                              location,
                            );
                          },
                        );
                      },
                    ).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      pickupLocation = result;
    });

    // =======================================================
    // REAL GPS CODE - KEEP FOR LATER
    // =======================================================
    //
    // Current Location select hone par production mein:
    // permission, coordinates aur reverse-geocoded address
    // load hoga aur booking mein save hoga.
    //
    // =======================================================
  }

  Future<void> _selectTourStartDate() async {
    final DateTime today = DateTime.now();

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: tourStartDate ?? today,
      firstDate: today,
      lastDate: today.add(
        const Duration(days: 365),
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      tourStartDate = selected;
    });

    await _loadAdminPricing();

    // REAL FIREBASE CODE - KEEP FOR LATER
    //
    // Production mein date Firestore Timestamp mein save hogi.
    // Seat schedule aur seasonal rate bhi isi date par re-check
    // honge.
  }

  void _requestQuotation() {
    if (_pricingLoading) {
      _showMessage(
        'Please wait while the latest admin pricing loads.',
      );
      return;
    }

    if (_pricePerPerson <= 0) {
      _showMessage(
        'No active admin price is available for this tour selection.',
      );
      return;
    }

    if (pickupLocation.trim().isEmpty) {
      _showMessage(
        'Please select a pickup location.',
      );
      return;
    }

    if (tourStartDate == null) {
      _showMessage(
        'Please select a tour start date.',
      );
      return;
    }

    // =======================================================
    // REAL FIREBASE / BILLING CODE - KEEP FOR LATER
    // =======================================================
    //
    // Production flow:
    //
    // 1. Load active group schedule from Firestore.
    // 2. Check available seats.
    // 3. Load per-person admin-controlled package price.
    // 4. Apply hotel category and seasonal rates.
    // 5. Apply promo, commission and taxes.
    // 6. Save pickup, GPS, start date and quotation.
    // 7. Save booking in Firestore.
    // 8. Process advance payment.
    //
    // Firebase Storage billing is currently unavailable.
    // Real code will be enabled after billing is active.
    //
    // =======================================================

    // =======================================================
    // TEMPORARY TESTING BYPASS
    // =======================================================
    //
    // No payment is charged.
    // No Firebase write or Storage upload is performed.
    // Local quotation dialog is shown for app testing.
    //
    // =======================================================

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: yellow,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Group Tour Request',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _dialogSummaryRow(
                  'Destination',
                  widget.destinationName,
                ),
                _dialogSummaryRow(
                  'Pickup',
                  pickupLocation,
                ),
                _dialogSummaryRow(
                  'Start Date',
                  _formatDate(tourStartDate),
                ),
                _dialogSummaryRow(
                  'Duration',
                  selectedTourDuration,
                ),
                _dialogSummaryRow(
                  'Guests',
                  '$guests',
                ),
                _dialogSummaryRow(
                  'Hotel',
                  selectedHotelCategory,
                ),
                _dialogSummaryRow(
                  'Per Person',
                  'PKR ${_formatMoney(_pricePerPerson)}',
                ),
                const Divider(
                  color: Colors.white12,
                  height: 22,
                ),
                _dialogSummaryRow(
                  'Estimated Total',
                  'PKR ${_formatMoney(_finalPrice)}',
                ),
                _dialogSummaryRow(
                  'Advance (${_formatPercentage(_advancePercentage)}%)',
                  'PKR ${_formatMoney(_advanceAmount)}',
                ),
                _dialogSummaryRow(
                  'Remaining',
                  'PKR ${_formatMoney(_remainingAmount)}',
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: yellow.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Price is loaded from active Admin/Firestore rules. Seat availability, live payment and final Firebase booking remain paused for their later phase.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                _showMessage(
                  'Group tour request tested successfully.',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'Confirm Test',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEstimatedPriceCard() {
    if (_pricingLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: yellow.withValues(alpha: 0.18),
          ),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(
              color: yellow,
            ),
            SizedBox(height: 12),
            Text(
              'Loading latest admin pricing...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_pricingError != null ||
        _pricePerPerson <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.price_change_outlined,
              color: Colors.redAccent,
              size: 34,
            ),
            const SizedBox(height: 10),
            const Text(
              'Admin price is not available',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _pricingError ??
                  'Create and activate a matching group-tour pricing rule in Admin.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadAdminPricing,
              icon: const Icon(
                Icons.refresh,
                color: yellow,
              ),
              label: const Text(
                'Retry Pricing',
                style: TextStyle(
                  color: yellow,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          _priceRow(
            'Base price per person',
            _adminBasePricePerPerson,
          ),
          _priceRow(
            '$selectedHotelCategory hotel extra',
            _adminHotelCategoryExtra,
          ),
          _priceRow(
            'Price per person',
            _pricePerPerson,
          ),
          _priceRow(
            'Travellers',
            guests.toDouble(),
            isCount: true,
          ),
          const Divider(
            color: Colors.white12,
            height: 24,
          ),
          _priceRow(
            'Estimated Total',
            _finalPrice,
            isTotal: true,
          ),
          _priceRow(
            'Advance (${_formatPercentage(_advancePercentage)}%)',
            _advanceAmount,
          ),
          _priceRow(
            'Remaining',
            _remainingAmount,
          ),
          const SizedBox(height: 10),
          const Text(
            'Rates are loaded from active Admin/Firestore tourism pricing rules.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String title,
    double value, {
    bool isTotal = false,
    bool isCount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isTotal
                    ? Colors.white
                    : Colors.grey,
                fontSize: isTotal ? 15 : 13,
                fontWeight: isTotal
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isCount
                ? value.round().toString()
                : 'PKR ${_formatMoney(value)}',
            style: TextStyle(
              color: isTotal
                  ? yellow
                  : Colors.white,
              fontSize: isTotal ? 17 : 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _dropdownCard({
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: darkCard,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: yellow,
          ),
          items: items.map(
            (item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: yellow,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _includedItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: yellow.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: yellow,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _excludedItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.remove_circle_outline,
            color: Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogSummaryRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select tour date';
    }

    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatPercentage(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1);
  }

  String _formatMoney(double amount) {
    final int rounded = amount.round();
    final String value = rounded.toString();

    return value.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: darkCard,
          duration: const Duration(
            seconds: 3,
          ),
        ),
      );
  }
}

