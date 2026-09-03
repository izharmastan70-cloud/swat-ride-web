import 'package:flutter/material.dart';

import '../services/tourism_pricing_service.dart';
import 'tour_vehicle_selection_screen.dart';

class PrivateFamilyTourScreen extends StatefulWidget {
  const PrivateFamilyTourScreen({
    super.key,
    required this.destinationName,
  });

  final String destinationName;

  @override
  State<PrivateFamilyTourScreen> createState() =>
      _PrivateFamilyTourScreenState();
}

class _PrivateFamilyTourScreenState
    extends State<PrivateFamilyTourScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final TourismPricingService _pricingService =
      TourismPricingService();

  // =========================================================
  // REAL ADMIN / FIRESTORE PRICING
  // =========================================================

  double _vehicleDailyRate = 0;
  double _hotelRoomPerNight = 0;
  double _driverAllowancePerDay = 0;
  double _jeepServiceCost = 0;
  double _profitPercentage = 0;
  double _advancePercentage = 30;

  bool _pricingLoading = true;
  String? _pricingError;

  int selectedDays = 3;
  int selectedGuests = 4;

  String selectedVehicle = '';
  String pickupLocation = 'Mingora, Swat';
  DateTime? tourStartDate;

  bool includeHotel = true;
  bool includeJeep = false;

  final List<String> selectedDestinations = [];

  double get _selectedVehicleDailyRate {
    return _vehicleDailyRate;
  }

  int get _estimatedRooms {
    return (selectedGuests / 3).ceil();
  }

  int get _estimatedNights {
    return selectedDays > 1 ? selectedDays - 1 : 0;
  }

  Map<String, dynamic> get _quotation {
    return _pricingService.createPrivateTourQuotation(
      vehiclePerDay: _selectedVehicleDailyRate,
      numberOfDays: selectedDays,
      hotelPerNight:
          includeHotel ? _hotelRoomPerNight : 0,
      numberOfRooms:
          includeHotel ? _estimatedRooms : 0,
      numberOfNights:
          includeHotel ? _estimatedNights : 0,
      driverAllowancePerDay:
          _driverAllowancePerDay,
      jeepCost:
          includeJeep ? _jeepServiceCost : 0,
      profitPercentage:
          _profitPercentage,
      advancePercentage:
          _advancePercentage,
    );
  }

  final List<String> destinations = const [
    'Mingora',
    'Fizagat',
    'Malam Jabba',
    'Bahrain',
    'Kalam',
    'Mahodand Lake',
    'Ushu Forest',
    'Matiltan',
    'Kundol Lake',
    'Izmis Lake',
    'Gabral Valley',
    'White Palace Marghazar',
  ];

  final List<Map<String, dynamic>> vehicles = const [
    {
      'name': 'Suzuki Alto',
      'subtitle': 'Best for up to 3 passengers',
      'icon': Icons.directions_car,
    },
    {
      'name': 'Suzuki Wagon R',
      'subtitle': 'Comfortable for up to 4 passengers',
      'icon': Icons.airport_shuttle,
    },
    {
      'name': 'Toyota Corolla',
      'subtitle': 'Comfortable sedan for up to 4 passengers',
      'icon': Icons.directions_car_filled,
    },
    {
      'name': 'Corolla Fielder',
      'subtitle': 'Spacious vehicle for up to 5 passengers',
      'icon': Icons.directions_car,
    },
    {
      'name': 'Toyota Hiace',
      'subtitle': 'Suitable for large families and groups',
      'icon': Icons.airport_shuttle,
    },
    {
      'name': '4x4 Jeep',
      'subtitle': 'For difficult mountain and lake routes',
      'icon': Icons.terrain,
    },
  ];

  @override
  void initState() {
    super.initState();

    final String initialDestination = widget.destinationName.trim();

    if (initialDestination.isNotEmpty &&
        initialDestination != 'Complete All Swat Tour' &&
        destinations.contains(initialDestination)) {
      selectedDestinations.add(initialDestination);
    }

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

      final List<Map<String, dynamic>> privateRules =
          await _pricingService.getActivePricingRules(
        appliesTo: 'private_tour',
        at: effectiveDate,
      );

      final List<Map<String, dynamic>> familyRules =
          await _pricingService.getActivePricingRules(
        appliesTo: 'family_tour',
        at: effectiveDate,
      );

      final List<Map<String, dynamic>> rules = <Map<String, dynamic>>[
        ...privateRules,
        ...familyRules,
      ];

      double vehicleRate = 0;
      double hotelRate = 0;
      double driverRate = 0;
      double jeepRate = 0;
      double profitPercentage = 0;
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
        final double percentage = _readDouble(rule['percentage']);

        final bool vehicleMatch =
            selectedVehicle.isNotEmpty &&
                (targetName == selectedVehicle.toLowerCase() ||
                    ruleCode.contains(_normaliseCode(selectedVehicle)));

        final bool isVehicle =
            ruleType == 'vehicle' || ruleCode.contains('vehicle');

        final bool isHotel =
            ruleType == 'hotel' || ruleCode.contains('hotel');

        final bool isDriver =
            ruleType == 'driver' || ruleCode.contains('driver');

        final bool isJeep =
            targetName.contains('jeep') ||
                ruleCode.contains('jeep') ||
                ruleCode.contains('4x4');

        final bool isProfit =
            ruleType == 'commission' ||
                ruleCode.contains('profit') ||
                ruleCode.contains('margin') ||
                ruleCode.contains('commission');

        final bool isAdvance =
            ruleCode.contains('advance') ||
                targetName.contains('advance');

        if (isAdvance &&
            valueType == 'percentage' &&
            percentage >= 0) {
          advancePercentage = percentage;
          continue;
        }

        if (isProfit &&
            valueType == 'percentage' &&
            percentage >= 0) {
          profitPercentage = percentage;
          continue;
        }

        if (isJeep &&
            valueType != 'percentage' &&
            amount >= 0) {
          jeepRate = amount;
          continue;
        }

        if (isDriver &&
            valueType != 'percentage' &&
            amount >= 0) {
          driverRate = amount;
          continue;
        }

        if (isHotel &&
            valueType != 'percentage' &&
            amount >= 0) {
          hotelRate = amount;
          continue;
        }

        if (isVehicle &&
            vehicleMatch &&
            valueType != 'percentage' &&
            amount > 0) {
          vehicleRate = amount;
        }
      }

      if (selectedVehicle.isNotEmpty && vehicleRate <= 0) {
        throw Exception(
          'No active admin vehicle rate found for $selectedVehicle.',
        );
      }

      if (!mounted) return;

      setState(() {
        _vehicleDailyRate = vehicleRate;
        _hotelRoomPerNight = hotelRate;
        _driverAllowancePerDay = driverRate;
        _jeepServiceCost = jeepRate;
        _profitPercentage = profitPercentage;
        _advancePercentage = advancePercentage;
        _pricingLoading = false;
        _pricingError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _vehicleDailyRate = 0;
        _hotelRoomPerNight = 0;
        _driverAllowancePerDay = 0;
        _jeepServiceCost = 0;
        _profitPercentage = 0;
        _pricingLoading = false;
        _pricingError = error.toString();
      });
    }
  }

  String _normaliseCode(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
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
          'Private Family Tour',
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
                'Plan Your Private Tour',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a private family tour with your own vehicle, driver, hotel and selected destinations.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 26),

              // =================================================
              // PICKUP LOCATION
              // =================================================
              _sectionTitle('Pickup Location'),
              const SizedBox(height: 12),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 24),

              // =================================================
              // TOUR START DATE
              // =================================================
              _sectionTitle('Tour Start Date'),
              const SizedBox(height: 12),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tour Date',
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
              const SizedBox(height: 24),

              // =================================================
              // GUESTS
              // =================================================
              _sectionTitle('Number of Guests'),
              const SizedBox(height: 12),
              _counterCard(
                icon: Icons.people,
                title: 'Guests',
                value: selectedGuests,
                min: 1,
                max: 20,
                onChanged: (value) {
                  setState(() {
                    selectedGuests = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // =================================================
              // DAYS
              // =================================================
              _sectionTitle('Tour Duration'),
              const SizedBox(height: 12),
              _counterCard(
                icon: Icons.calendar_month,
                title: 'Number of Days',
                value: selectedDays,
                min: 1,
                max: 10,
                onChanged: (value) {
                  setState(() {
                    selectedDays = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // =================================================
              // VEHICLE
              // =================================================
              _sectionTitle('Select Vehicle'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openVehicleSelector,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.directions_car),
                  label: Text(
                    selectedVehicle.isEmpty
                        ? 'Select Vehicle'
                        : selectedVehicle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // =================================================
              // DESTINATIONS
              // =================================================
              _sectionTitle('Select Destinations'),
              const SizedBox(height: 8),
              const Text(
                'Choose all the places you want to visit.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              ...destinations.map(
                (destination) {
                  final bool isSelected =
                      selectedDestinations.contains(destination);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            if (!selectedDestinations
                                .contains(destination)) {
                              selectedDestinations.add(destination);
                            }
                          } else {
                            selectedDestinations.remove(destination);
                          }
                        });
                      },
                      activeColor: yellow,
                      checkColor: Colors.black,
                      tileColor: darkCard,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        destination,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      secondary: const Icon(
                        Icons.location_on,
                        color: yellow,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // =================================================
              // HOTEL
              // =================================================
              _switchCard(
                icon: Icons.hotel,
                title: 'Include Hotel Booking',
                subtitle:
                    'Add hotel accommodation to your tour package.',
                value: includeHotel,
                onChanged: (value) {
                  setState(() {
                    includeHotel = value;
                  });
                  _loadAdminPricing();
                },
              ),
              const SizedBox(height: 12),

              // =================================================
              // JEEP
              // =================================================
              _switchCard(
                icon: Icons.terrain,
                title: 'Include 4x4 Jeep',
                subtitle:
                    'Recommended for Mahodand Lake and difficult mountain routes.',
                value: includeJeep,
                onChanged: (value) {
                  setState(() {
                    includeJeep = value;
                  });
                  _loadAdminPricing();
                },
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _summaryRow(
                      'Tour',
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
                      'Guests',
                      '$selectedGuests',
                    ),
                    _summaryRow(
                      'Days',
                      '$selectedDays',
                    ),
                    _summaryRow(
                      'Vehicle',
                      selectedVehicle.isEmpty
                          ? 'Not Selected'
                          : selectedVehicle,
                    ),
                    _summaryRow(
                      'Hotel',
                      includeHotel ? 'Included' : 'Not Included',
                    ),
                    _summaryRow(
                      '4x4 Jeep',
                      includeJeep ? 'Included' : 'Not Included',
                    ),
                    const Divider(
                      color: Colors.grey,
                    ),
                    const Text(
                      'Selected Destinations',
                      style: TextStyle(
                        color: yellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedDestinations.isEmpty
                          ? 'No destination selected'
                          : selectedDestinations.join(', '),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        height: 1.5,
                      ),
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
                      _pricingLoading ||
                              selectedVehicle.isEmpty ||
                              _selectedVehicleDailyRate <= 0
                          ? null
                          : _continueToQuotation,
                  icon: const Icon(
                    Icons.calculate,
                    color: Colors.black,
                  ),
                  label: const Text(
                    'Get Tour Quotation',
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
                  'Tour rates are loaded from active Admin/Firestore pricing rules. Live payment remains in testing bypass until its billing-dependent phase.',
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

  Future<void> _openVehicleSelector() async {
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
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Tour Vehicle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a suitable vehicle for your family and route.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: vehicles.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 10);
                    },
                    itemBuilder: (context, index) {
                      final Map<String, dynamic> vehicle =
                          vehicles[index];
                      final String name = vehicle['name'] as String;
                      final String subtitle =
                          vehicle['subtitle'] as String;
                      final IconData icon =
                          vehicle['icon'] as IconData;
                      final bool selected =
                          selectedVehicle == name;

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(sheetContext, name);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: darkCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? yellow
                                  : Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: yellow.withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  icon,
                                  color: yellow,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: selected
                                    ? yellow
                                    : Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
      selectedVehicle = result;
    });

    await _loadAdminPricing();
  }

  Future<void> _continueToQuotation() async {
    if (_pricingLoading) {
      _showMessage(
        'Please wait while the latest admin pricing loads.',
      );
      return;
    }

    if (selectedVehicle.isEmpty) {
      _showMessage('Please select a vehicle.');
      return;
    }

    if (_selectedVehicleDailyRate <= 0) {
      _showMessage(
        'No active admin rate is available for the selected vehicle.',
      );
      return;
    }

    if (pickupLocation.trim().isEmpty) {
      _showMessage('Please select a pickup location.');
      return;
    }

    if (tourStartDate == null) {
      _showMessage('Please select a tour start date.');
      return;
    }

    if (selectedDestinations.isEmpty) {
      _showMessage('Please select at least one destination.');
      return;
    }

    final DateTime endDate = tourStartDate!.add(
      Duration(days: selectedDays),
    );

    final Map<String, dynamic>? result =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (context) => TourVehicleSelectionScreen(
          destinationName: widget.destinationName,
          startDate: tourStartDate,
          endDate: endDate,
          pickupLocation: pickupLocation,
          selectedDestinations:
              List<String>.from(selectedDestinations),
          tourDays: selectedDays,
          guests: selectedGuests,
          includeHotel: includeHotel,
          includeJeep: includeJeep,
          estimatedTourAmount:
              _quotationValue('finalPrice'),
          estimatedAdvanceAmount:
              _quotationValue('advanceAmount'),
          estimatedRemainingAmount:
              _quotationValue('remainingAmount'),
          estimatedVehicleDailyRate:
              _selectedVehicleDailyRate,
          estimatedBaseBeforeCommission:
              _quotationValue('baseCost'),
          estimatedHotelAmount:
              _quotationValue('hotelCost'),
          estimatedAdminCommissionPercent:
              _profitPercentage,
          estimatedAdvancePercentage:
              _advancePercentage,          initialVehicleName: selectedVehicle,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    final String bookingId =
        result['bookingId']?.toString() ?? '';

    _showMessage(
      bookingId.isEmpty
          ? 'Tour selection completed.'
          : 'Tour booking created: ${_shortId(bookingId)}',
    );

    // =======================================================
    // REAL PAYMENT / BILLING CODE - KEEP COMMENTED
    // =======================================================
    //
    // TourVehicleSelectionScreen currently creates a Firestore
    // booking in testing mode. Real payment remains bypassed.
    //
    // Production payment flow:
    // 1. Re-load admin-controlled live tour and partner rates.
    // 2. Re-check hotel room and vehicle availability.
    // 3. Calculate final commission, promo and tax.
    // 4. Start Wallet/JazzCash/Easypaisa payment.
    // 5. Mark realPaymentProcessed = true after verification.
    // 6. Confirm booking and notify customer/partners.
    //
    // Firebase Storage remains bypassed by project decision.
    // =======================================================
  }

  String _shortId(String id) {
    if (id.length <= 10) {
      return id.toUpperCase();
    }

    return id.substring(0, 10).toUpperCase();
  }

  // ignore: unused_element
  void _showTemporaryQuotation() {
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
                  'Tour Request Ready',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogSummaryRow(
                  'Tour',
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
                  'Guests',
                  '$selectedGuests',
                ),
                _dialogSummaryRow(
                  'Days',
                  '$selectedDays',
                ),
                _dialogSummaryRow(
                  'Vehicle',
                  selectedVehicle,
                ),
                _dialogSummaryRow(
                  'Hotel',
                  includeHotel ? 'Included' : 'No',
                ),
                _dialogSummaryRow(
                  '4x4 Jeep',
                  includeJeep ? 'Included' : 'No',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Destinations',
                  style: TextStyle(
                    color: yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedDestinations.join(', '),
                  style: const TextStyle(
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(
                  color: Colors.white12,
                ),
                const SizedBox(height: 8),
                _dialogSummaryRow(
                  'Estimated Total',
                  'PKR ${_formatMoney(_quotationValue('finalPrice'))}',
                ),
                _dialogSummaryRow(
                  'Advance (${_formatPercentage(_advancePercentage)}%)',
                  'PKR ${_formatMoney(_quotationValue('advanceAmount'))}',
                ),
                _dialogSummaryRow(
                  'Remaining',
                  'PKR ${_formatMoney(_quotationValue('remainingAmount'))}',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: yellow.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pricing is loaded from active Admin/Firestore rules. Live GPS/payment remain in their testing phase.',
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
                  'Tour request tested successfully.',
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
            CircularProgressIndicator(color: yellow),
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

    if (_pricingError != null) {
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
              'Admin pricing is not available',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _pricingError!,
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
              icon: const Icon(Icons.refresh, color: yellow),
              label: const Text(
                'Retry Pricing',
                style: TextStyle(color: yellow),
              ),
            ),
          ],
        ),
      );
    }

    final Map<String, dynamic> quotation = _quotation;

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
          _priceRow('Vehicle/day', _selectedVehicleDailyRate),
          _priceRow(
            'Hotel/night',
            includeHotel ? _hotelRoomPerNight : 0,
          ),
          _priceRow('Driver/day', _driverAllowancePerDay),
          _priceRow(
            '4x4 Jeep',
            includeJeep ? _jeepServiceCost : 0,
          ),
          const Divider(
            color: Colors.white12,
            height: 24,
          ),
          _priceRow(
            'Vehicle total',
            _quotationValueFrom(quotation, 'vehicleCost'),
          ),
          _priceRow(
            'Hotel total',
            _quotationValueFrom(quotation, 'hotelCost'),
          ),
          _priceRow(
            'Driver total',
            _quotationValueFrom(quotation, 'driverCost'),
          ),
          _priceRow(
            'Company profit (${_formatPercentage(_profitPercentage)}%)',
            _quotationValueFrom(quotation, 'companyProfit'),
          ),
          const Divider(
            color: Colors.white12,
            height: 26,
          ),
          _priceRow(
            'Estimated Total',
            _quotationValueFrom(quotation, 'finalPrice'),
            isTotal: true,
          ),
          const SizedBox(height: 4),
          _priceRow(
            'Advance (${_formatPercentage(_advancePercentage)}%)',
            _quotationValueFrom(quotation, 'advanceAmount'),
          ),
          _priceRow(
            'Remaining',
            _quotationValueFrom(quotation, 'remainingAmount'),
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
    double amount, {
    bool isTotal = false,
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
            'PKR ${_formatMoney(amount)}',
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

  double _quotationValue(String key) {
    return _quotationValueFrom(
      _quotation,
      key,
    );
  }

  double _quotationValueFrom(
    Map<String, dynamic> quotation,
    String key,
  ) {
    final dynamic value = quotation[key];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _counterCard({
    required IconData icon,
    required String title,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: yellow,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: value > min
                ? () {
                    onChanged(value - 1);
                  }
                : null,
            icon: Icon(
              Icons.remove_circle,
              color: value > min
                  ? yellow
                  : Colors.grey.shade700,
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: value < max
                ? () {
                    onChanged(value + 1);
                  }
                : null,
            icon: Icon(
              Icons.add_circle,
              color: value < max
                  ? yellow
                  : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: yellow,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: yellow,
            onChanged: onChanged,
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
      padding: const EdgeInsets.only(bottom: 8),
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

    // =======================================================
    // REAL FIREBASE CODE - KEEP FOR LATER
    // =======================================================
    //
    // Production booking mein selected date Firestore
    // Timestamp ke roop mein save hogi. Admin availability,
    // seasonal rates aur driver schedule bhi isi date par
    // re-check honge.
    //
    // =======================================================
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select tour date';
    }

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
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
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Choose a local testing pickup point. Real GPS support will be enabled later.',
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
    // "Current Location" select hone par production flow:
    //
    // 1. Location permission request hogi.
    // 2. Device GPS coordinates milengi.
    // 3. Reverse geocoding se readable address milega.
    // 4. Latitude, longitude aur address booking mein save honge.
    //
    // Abhi local testing location selection use ho rahi hai.
    //
    // =======================================================
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: darkCard,
          duration: const Duration(seconds: 3),
        ),
      );
  }
}


