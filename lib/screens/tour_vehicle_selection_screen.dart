import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/tour_booking.dart';
import '../services/tour_booking_service.dart';
import '../services/tourism_pricing_service.dart';
import 'tour_hotel_selection_screen.dart';

class TourVehicleSelectionScreen extends StatefulWidget {
  const TourVehicleSelectionScreen({
    super.key,
    this.destinationName = '',
    this.startDate,
    this.endDate,
    this.pickupLocation = '',
    this.selectedDestinations = const <String>[],
    this.tourDays = 3,
    this.guests = 4,
    this.includeHotel = true,
    this.includeJeep = false,
    this.estimatedTourAmount = 0,
    this.estimatedAdvanceAmount = 0,
    this.estimatedRemainingAmount = 0,
    this.estimatedVehicleDailyRate = 0,
    this.estimatedBaseBeforeCommission = 0,
    this.estimatedHotelAmount = 0,
    this.estimatedAdminCommissionPercent = -1,
    this.estimatedAdvancePercentage = 30,    this.initialVehicleName = '',
  });

  final String destinationName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String pickupLocation;
  final List<String> selectedDestinations;
  final int tourDays;
  final int guests;
  final bool includeHotel;
  final bool includeJeep;
  final double estimatedTourAmount;
  final double estimatedAdvanceAmount;
  final double estimatedRemainingAmount;
  final double estimatedVehicleDailyRate;
  final double estimatedBaseBeforeCommission;
  final double estimatedHotelAmount;
  final double estimatedAdminCommissionPercent;
  final double estimatedAdvancePercentage;  final String initialVehicleName;

  @override
  State<TourVehicleSelectionScreen> createState() =>
      _TourVehicleSelectionScreenState();
}

class _TourVehicleSelectionScreenState
    extends State<TourVehicleSelectionScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final TourBookingService _bookingService =
      TourBookingService();

  final TourismPricingService _pricingService =
      TourismPricingService();

  bool _isWorking = false;
  String _selectedVehicle = '';

  Map<String, dynamic>? _selectedHotelResult;
  final Map<String, double>
      _adminVehicleDailyRates =
      <String, double>{};
  final Map<String, String>
      _adminVehiclePricingRuleIds =
      <String, String>{};

  final Map<String, double>
      _adminCommissionPercents =
      <String, double>{};

  final Map<String, String>
      _adminCommissionRuleIds =
      <String, String>{};

  bool _adminPricingLoading = false;
  bool _adminPricingStarted = false;
  String? _adminPricingError;

  static const List<Map<String, dynamic>> _vehicles =
      <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'corolla_gli',
      'name': 'Corolla GLi',
      'subtitle': 'Comfortable private car for families',
      'icon': Icons.directions_car,
      'capacity': 4,
      'dailyRate': 10000.0,
    },
    <String, dynamic>{
      'id': 'toyota_brv',
      'name': 'Toyota BR-V',
      'subtitle': 'Spacious family vehicle',
      'icon': Icons.directions_car_filled,
      'capacity': 6,
      'dailyRate': 13500.0,
    },
    <String, dynamic>{
      'id': 'fortuner',
      'name': 'SUV / Fortuner',
      'subtitle': 'Premium vehicle for VIP family tours',
      'icon': Icons.directions_car,
      'capacity': 6,
      'dailyRate': 22000.0,
    },
    <String, dynamic>{
      'id': 'hiace_grand_cabin',
      'name': 'HiAce Grand Cabin',
      'subtitle': 'Shared group and large family vehicle',
      'icon': Icons.airport_shuttle,
      'capacity': 12,
      'dailyRate': 20000.0,
    },
    <String, dynamic>{
      'id': 'coaster',
      'name': 'Coaster',
      'subtitle': 'Large group and family tour vehicle',
      'icon': Icons.directions_bus,
      'capacity': 20,
      'dailyRate': 30000.0,
    },
  ];

  @override
  void initState() {
    super.initState();

    final String initial =
        widget.initialVehicleName.trim();

    if (_vehicles.any(
      (vehicle) => vehicle['name'] == initial,
    )) {
      _selectedVehicle = initial;
    } else {
      _selectedVehicle =
          _recommendedVehicle['name'].toString();
    }
  }

  Map<String, dynamic> get _recommendedVehicle {
    for (final vehicle in _vehicles) {
      final int capacity =
          (vehicle['capacity'] as num).toInt();

      if (capacity >= widget.guests) {
        return vehicle;
      }
    }

    return _vehicles.last;
  }

  Map<String, dynamic>? get _selectedVehicleData {
    for (final vehicle in _vehicles) {
      if (vehicle['name'] == _selectedVehicle) {
        return vehicle;
      }
    }

    return null;
  }

  bool get _usesUpstreamQuotation =>
      widget.estimatedTourAmount > 0;

  double _pricingNumber(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double _adminVehicleRateFor(
    Map<String, dynamic> vehicle,
  ) {
    final String vehicleId =
        vehicle['id']?.toString() ?? '';

    if (_usesUpstreamQuotation &&
        widget.estimatedVehicleDailyRate > 0) {
      return widget.estimatedVehicleDailyRate;
    }
    final double adminRate =
        _adminVehicleDailyRates[
                vehicleId] ??
            0;

    if (adminRate > 0) {
      return adminRate;
    }

    // Private Family already carries an
    // Admin-controlled upstream quotation.
    if (_usesUpstreamQuotation) {
      return _pricingNumber(
        vehicle['dailyRate'],
      );
    }

    // Package / standalone booking must not
    // use hardcoded pricing as authority.
    return 0;
  }

  double _commissionPercentFor(
    Map<String, dynamic> vehicle,
  ) {
    if (_usesUpstreamQuotation &&
        widget.estimatedAdminCommissionPercent >= 0) {
      return widget
          .estimatedAdminCommissionPercent
          .clamp(0, 100)
          .toDouble();
    }

    final String vehicleId =
        vehicle['id']?.toString() ?? '';

    return (_adminCommissionPercents[
                vehicleId] ??
            0)
        .clamp(0, 100)
        .toDouble();
  }

  bool _nearlyEqual(
    double left,
    double right,
  ) {
    return (left - right).abs() < 0.01;
  }

  String _vehiclePricingRuleIdFor(
    Map<String, dynamic> vehicle,
  ) {
    final String vehicleId =
        vehicle['id']?.toString() ?? '';

    final String ruleId =
        _adminVehiclePricingRuleIds[
                vehicleId] ??
            '';

    if (!_usesUpstreamQuotation) {
      return ruleId;
    }

    final double liveRate =
        _adminVehicleDailyRates[
                vehicleId] ??
            0;

    if (ruleId.isNotEmpty &&
        widget.estimatedVehicleDailyRate > 0 &&
        _nearlyEqual(
          liveRate,
          widget.estimatedVehicleDailyRate,
        )) {
      return ruleId;
    }

    return '';
  }

  String _commissionPricingRuleIdFor(
    Map<String, dynamic> vehicle,
  ) {
    final String vehicleId =
        vehicle['id']?.toString() ?? '';

    final String ruleId =
        _adminCommissionRuleIds[
                vehicleId] ??
            '';

    if (!_usesUpstreamQuotation) {
      return ruleId;
    }

    final double livePercent =
        _adminCommissionPercents[
                vehicleId] ??
            0;

    if (ruleId.isNotEmpty &&
        widget.estimatedAdminCommissionPercent >= 0 &&
        _nearlyEqual(
          livePercent,
          widget.estimatedAdminCommissionPercent,
        )) {
      return ruleId;
    }

    return '';
  }
  Future<void> _loadAdminVehiclePricing() async {
    if (_adminPricingLoading) {
      return;
    }

    if (mounted) {
      setState(() {
        _adminPricingLoading = true;
        _adminPricingError = null;
      });
    }

    try {
      final DateTime effectiveDate =
          widget.startDate ??
              DateTime.now();

      final Map<String, double> loadedRates =
          <String, double>{};
      final Map<String, String>
          loadedVehicleRuleIds =
          <String, String>{};

      final Map<String, double>
          loadedCommissionPercents =
          <String, double>{};

      final Map<String, String>
          loadedCommissionRuleIds =
          <String, String>{};

      for (
        final Map<String, dynamic> vehicle
            in _vehicles
      ) {
        final String vehicleId =
            vehicle['id']?.toString() ?? '';

        final String vehicleName =
            vehicle['name']?.toString() ?? '';

        if (vehicleId.isEmpty ||
            vehicleName.isEmpty) {
          continue;
        }

        final Map<String, dynamic>? vehicleRule =
            await _pricingService
                .getBestPricingRule(
          appliesTo: 'private_tour',
          ruleType: 'vehicle',
          targetId: vehicleId,
          targetName: vehicleName,
          at: effectiveDate,
        );

        if (vehicleRule != null) {
          final String valueType =
              vehicleRule['valueType']
                      ?.toString()
                      .trim()
                      .toLowerCase() ??
                  'fixed';

          final double amount =
              _pricingNumber(
            vehicleRule['amount'],
          );

          if (valueType != 'percentage' &&
              amount > 0) {
            loadedRates[vehicleId] =
                amount;

            final String ruleId =
                vehicleRule['pricingRuleId']
                        ?.toString()
                        .trim() ??
                    '';

            if (ruleId.isNotEmpty) {
              loadedVehicleRuleIds[
                      vehicleId] =
                  ruleId;
            }
          }
        }

        final Map<String, dynamic>? commissionRule =
            await _pricingService
                .getBestPricingRule(
          appliesTo: 'private_tour',
          ruleType: 'commission',
          targetId: vehicleId,
          targetName: vehicleName,
          at: effectiveDate,
        );

        if (commissionRule != null) {
          final String valueType =
              commissionRule['valueType']
                      ?.toString()
                      .trim()
                      .toLowerCase() ??
                  '';

          final double percentage =
              _pricingNumber(
            commissionRule['percentage'],
          );

          if (valueType == 'percentage' &&
              percentage >= 0) {
            loadedCommissionPercents[
                    vehicleId] =
                percentage
                    .clamp(0, 100)
                    .toDouble();

            final String ruleId =
                commissionRule[
                            'pricingRuleId']
                        ?.toString()
                        .trim() ??
                    '';

            if (ruleId.isNotEmpty) {
              loadedCommissionRuleIds[
                      vehicleId] =
                  ruleId;
            }
          }
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _adminVehicleDailyRates
          ..clear()
          ..addAll(loadedRates);
        _adminVehiclePricingRuleIds
          ..clear()
          ..addAll(loadedVehicleRuleIds);

        _adminCommissionPercents
          ..clear()
          ..addAll(loadedCommissionPercents);

        _adminCommissionRuleIds
          ..clear()
          ..addAll(loadedCommissionRuleIds);

        _adminPricingLoading = false;
        _adminPricingError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _adminVehicleDailyRates.clear();
        _adminVehiclePricingRuleIds.clear();
        _adminCommissionPercents.clear();
        _adminCommissionRuleIds.clear();
        _adminPricingLoading = false;
        _adminPricingError =
            error.toString();
      });
    }
  }
  double get _vehicleTotal {
    final Map<String, dynamic>? vehicle =
        _selectedVehicleData;

    if (vehicle == null) {
      return 0;
    }

    final double dailyRate =
        _adminVehicleRateFor(
      vehicle,
    );

    return dailyRate *
        widget.tourDays;
  }
  double get _hotelTotal {
    return (_selectedHotelResult?[
                'hotelTotalAmount'] as num?)
            ?.toDouble() ??
        0;
  }

  double get _legacyJeepAmount {
    return widget.includeJeep
        ? 18000
        : 0;
  }

  double get _adminCommissionPercent {
    final Map<String, dynamic>? vehicle =
        _selectedVehicleData;

    if (vehicle == null) {
      return 0;
    }

    return _commissionPercentFor(
      vehicle,
    );
  }

  double get _baseBeforeAdminCommission {
    if (_usesUpstreamQuotation &&
        widget.estimatedBaseBeforeCommission > 0) {
      final double replacementHotel =
          widget.includeHotel
              ? _hotelTotal
              : 0;

      final double value =
          widget.estimatedBaseBeforeCommission -
              widget.estimatedHotelAmount +
              replacementHotel;

      return value < 0
          ? 0
          : value;
    }

    if (_usesUpstreamQuotation) {
      final double original =
          widget.estimatedTourAmount;

      final double percent =
          _adminCommissionPercent;

      if (original <= 0) {
        return 0;
      }

      if (percent <= 0) {
        return original;
      }

      return original /
          (1 + (percent / 100));
    }

    return _vehicleTotal +
        _hotelTotal +
        _legacyJeepAmount;
  }

  double get _adminCommissionAmount {
    final double percent =
        _adminCommissionPercent;

    if (percent <= 0) {
      return 0;
    }

    return _baseBeforeAdminCommission *
        (percent / 100);
  }

  double get _providerReceivableAmount {
    final double value =
        _finalTotal -
            _adminCommissionAmount;

    return value < 0
        ? 0
        : value;
  }

  double get _finalTotal {
    return _baseBeforeAdminCommission +
        _adminCommissionAmount;
  }

  double get _effectiveAdvancePercentage {
    if (_usesUpstreamQuotation) {
      return widget
          .estimatedAdvancePercentage
          .clamp(0, 100)
          .toDouble();
    }

    return 30;
  }

  double get _advanceAmount {
    return _finalTotal *
        (_effectiveAdvancePercentage / 100);
  }

  double get _remainingAmount {
    return _finalTotal - _advanceAmount;
  }

  @override
  Widget build(BuildContext context) {
    if (!_adminPricingStarted) {
      _adminPricingStarted = true;

      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (mounted) {
          _loadAdminVehiclePricing();
        }
      });
    }
    final Map<String, dynamic> recommended =
        _recommendedVehicle;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme:
            const IconThemeData(color: Colors.white),
        title: const Text(
          'Tour Vehicle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                30,
              ),
              children: <Widget>[
                const Text(
                  'Choose Your Vehicle',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.guests} guests • ${widget.tourDays} days • ${widget.destinationName.isEmpty ? 'Swat Tour' : widget.destinationName}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 18),
                _recommendedCard(recommended),
                const SizedBox(height: 22),
                const Text(
                  'Available Vehicles',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                ..._vehicles.map(
                  (vehicle) => _vehicleCard(
                    vehicle: vehicle,
                  ),
                ),
                const SizedBox(height: 22),
                if (widget.includeHotel)
                  _hotelSelectionCard(),
                if (widget.includeHotel)
                  const SizedBox(height: 22),
                _priceSummary(),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isWorking ? null : _continueFlow,
                    icon: _isWorking
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline,
                          ),
                    label: Text(
                      _isWorking
                          ? 'Creating Booking...'
                          : widget.includeHotel &&
                                  _selectedHotelResult ==
                                      null
                              ? 'Select Hotel & Continue'
                              : 'Confirm Tour Booking',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor: yellow,
                      foregroundColor:
                          Colors.black,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Firestore booking is active in testing mode. Firebase Storage and real payment remain bypassed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _recommendedCard(
    Map<String, dynamic> vehicle,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: yellow.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: yellow.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.auto_awesome,
            color: yellow,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Recommended for ${widget.guests} guest(s): ${vehicle['name']}',
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

  Widget _vehicleCard({
    required Map<String, dynamic> vehicle,
  }) {
    final String name =
        vehicle['name'].toString();
    final int capacity =
        (vehicle['capacity'] as num).toInt();
    final double dailyRate =
        _adminVehicleRateFor(vehicle);

    final bool isSelected =
        _selectedVehicle == name;
    final bool capacityEnough =
        capacity >= widget.guests;

    return InkWell(
      onTap: capacityEnough
          ? () {
              setState(() {
                _selectedVehicle = name;
              });
            }
          : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        margin:
            const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? yellow
                : Colors.white.withValues(
                    alpha: 0.06,
                  ),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color:
                    yellow.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                vehicle['icon'] as IconData,
                color: capacityEnough
                    ? yellow
                    : Colors.grey,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    style: TextStyle(
                      color: capacityEnough
                          ? Colors.white
                          : Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    vehicle['subtitle'].toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Up to $capacity guests • PKR ${_money(dailyRate)}/day',
                    style: TextStyle(
                      color: capacityEnough
                          ? yellow
                          : Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!capacityEnough)
                    const Text(
                      'Not enough capacity',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color:
                  isSelected ? yellow : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _hotelSelectionCard() {
    final bool selected =
        _selectedHotelResult != null;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? yellow
              : Colors.white.withValues(
                  alpha: 0.06,
                ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.hotel,
                color: yellow,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tour Hotel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle
                    : Icons.pending_outlined,
                color: selected
                    ? Colors.green
                    : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            selected
                ? '${_selectedHotelResult!['hotelName']} • ${_selectedHotelResult!['roomName']}'
                : 'Select an approved hotel and room for this tour.',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          if (selected) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'Hotel total: PKR ${_money(_hotelTotal)}',
              style: const TextStyle(
                color: yellow,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _selectHotel,
              icon: const Icon(
                Icons.search,
              ),
              label: Text(
                selected
                    ? 'Change Hotel'
                    : 'Select Hotel',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: <Widget>[
          _priceRow(
            'Vehicle total',
            _vehicleTotal,
          ),
          if (widget.includeHotel)
            _priceRow(
              'Hotel total',
              _hotelTotal,
            ),
          if (widget.includeJeep)
            _priceRow(
              '4x4 service',
              18000,
            ),
          const Divider(
            color: Colors.white12,
            height: 24,
          ),
          _priceRow(
            'Estimated total',
            _finalTotal,
            total: true,
          ),
          _priceRow(
            'Advance (30%)',
            _advanceAmount,
          ),
          _priceRow(
            'Remaining',
            _remainingAmount,
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String title,
    double value, {
    bool total = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: total
                    ? Colors.white
                    : Colors.grey,
                fontWeight: total
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          Text(
            'PKR ${_money(value)}',
            style: TextStyle(
              color: total
                  ? yellow
                  : Colors.white,
              fontSize: total ? 17 : 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectHotel() async {
    final Map<String, dynamic>? result =
        await Navigator.push<
            Map<String, dynamic>>(
      context,
      MaterialPageRoute<
          Map<String, dynamic>>(
        builder: (context) =>
            TourHotelSelectionScreen(
          destinationName:
              widget.destinationName,
          startDate: widget.startDate,
          endDate: widget.endDate,
          guests: widget.guests,
          initialHotelId:
              _selectedHotelResult?[
                          'hotelId']
                      ?.toString() ??
                  '',
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _selectedHotelResult = result;
    });
  }

  Future<void> _continueFlow() async {
    final Map<String, dynamic>? vehicle =
        _selectedVehicleData;

    if (vehicle == null) {
      _showMessage(
        'Please select a vehicle.',
        isError: true,
      );
      return;
    }

    final int capacity =
        (vehicle['capacity'] as num).toInt();

    if (capacity < widget.guests) {
      _showMessage(
        'Selected vehicle does not have enough capacity.',
        isError: true,
      );
      return;
    }

    if (!_usesUpstreamQuotation) {
      if (_adminPricingLoading) {
        _showMessage(
          'Please wait while the latest admin vehicle pricing loads.',
        );
        return;
      }

      final double activeAdminRate =
          _adminVehicleRateFor(
        vehicle,
      );

      if (activeAdminRate <= 0) {
        _showMessage(
          _adminPricingError == null
              ? 'No active admin rate is available for the selected vehicle.'
              : 'Unable to load the latest admin vehicle pricing.',
          isError: true,
        );
        return;
      }
    }
    if (widget.includeHotel &&
        _selectedHotelResult == null) {
      await _selectHotel();
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in before creating the tour booking.',
        isError: true,
      );
      return;
    }

    final DateTime startDate =
        widget.startDate ?? DateTime.now();
    final DateTime endDate =
        widget.endDate ??
            startDate.add(
              Duration(days: widget.tourDays),
            );

    setState(() {
      _isWorking = true;
    });

    try {
      final double effectiveVehicleDailyRate =
          _adminVehicleRateFor(
        vehicle,
      );

      final double effectiveCommissionPercent =
          _commissionPercentFor(
        vehicle,
      );

      final String vehiclePricingRuleId =
          _vehiclePricingRuleIdFor(
        vehicle,
      );

      final String commissionPricingRuleId =
          _commissionPricingRuleIdFor(
        vehicle,
      );

      final Map<String, dynamic> pricingSnapshot =
          <String, dynamic>{
        'pricingVersion':
            'private_tour_admin_v1',
        'pricingSource':
            _usesUpstreamQuotation
                ? 'upstream_admin_quotation'
                : 'vehicle_selection_admin_pricing',
        'commissionSemantics':
            'company_profit_markup',
        'effectiveDate':
            startDate.toIso8601String(),
        'vehicleId':
            vehicle['id']?.toString() ?? '',
        'vehicleName':
            vehicle['name']?.toString() ?? '',
        'vehicleDailyRate':
            effectiveVehicleDailyRate,
        'vehiclePricingRuleId':
            vehiclePricingRuleId,
        'tourDays':
            widget.tourDays,
        'vehicleTotal':
            _vehicleTotal,
        'estimatedHotelAmount':
            widget.estimatedHotelAmount,
        'actualHotelTotal':
            _hotelTotal,
        'legacyJeepAmount':
            _legacyJeepAmount,
        'baseBeforeAdminCommission':
            _baseBeforeAdminCommission,
        'adminCommissionPercent':
            effectiveCommissionPercent,
        'adminCommissionAmount':
            _adminCommissionAmount,
        'commissionPricingRuleId':
            commissionPricingRuleId,
        'providerReceivableAmount':
            _providerReceivableAmount,
        'totalAmount':
            _finalTotal,
        'advancePercentage':
            _effectiveAdvancePercentage,
        'advanceAmount':
            _advanceAmount,
        'remainingAmount':
            _remainingAmount,
        'upstreamQuotedAmount':
            widget.estimatedTourAmount,
        'upstreamBaseBeforeCommission':
            widget.estimatedBaseBeforeCommission,
        'upstreamVehicleDailyRate':
            widget.estimatedVehicleDailyRate,
        'upstreamAdminCommissionPercent':
            widget.estimatedAdminCommissionPercent,
      };
      final TourBooking booking =
          TourBooking(
        id: '',
        userId: user.uid,
        packageId: '',
        tourType: 'private',
        startLocation:
            widget.pickupLocation,
        destination:
            widget.destinationName.isEmpty
                ? widget.selectedDestinations
                    .join(', ')
                : widget.destinationName,
        startDate: startDate,
        endDate: endDate,
        guests: widget.guests,
        vehicleId:
            vehicle['id'].toString(),
        hotelId:
            _selectedHotelResult?['hotelId']
                    ?.toString() ??
                '',
        hotelRoomId:
            _selectedHotelResult?[
                        'hotelRoomId']
                    ?.toString() ??
                '',
        totalAmount: _finalTotal,
        advanceAmount: _advanceAmount,
        remainingAmount:
            _remainingAmount,
        paymentStatus:
            'testing_bypassed',
        bookingStatus:
            'pending_admin_review',
        driverId: '',
        guideId: '',
        specialRequest:
            'Destinations: ${widget.selectedDestinations.join(', ')}'
            '${widget.includeJeep ? ' • Include 4x4 Jeep' : ''}',
        assignmentStatus:
            'partially_assigned',
        isTestingMode: true,
        realPaymentProcessed: false,
        storageUploadUsed: false,
        createdAt: DateTime.now(),
      );

      final String bookingId =
          await _bookingService.createBooking(
            booking,
            vehicleDailyRate:
                effectiveVehicleDailyRate,
            adminCommissionPercent:
                effectiveCommissionPercent,
            adminCommissionAmount:
                _adminCommissionAmount,
            providerReceivableAmount:
                _providerReceivableAmount,
            vehiclePricingRuleId:
                vehiclePricingRuleId,
            commissionPricingRuleId:
                commissionPricingRuleId,
            pricingSnapshot:
                pricingSnapshot,
          );

      if (!mounted) return;

      await _showConfirmation(
        bookingId: bookingId,
        vehicle: vehicle,
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        <String, dynamic>{
          'bookingId': bookingId,
          'vehicleId': vehicle['id'],
          'vehicleName': vehicle['name'],
          'hotel': _selectedHotelResult,
          'totalAmount': _finalTotal,
          'advanceAmount': _advanceAmount,
          'remainingAmount':
              _remainingAmount,
        },
      );
    } catch (error) {
      _showMessage(
        'Unable to create tour booking: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }

    // =======================================================
    // REAL PAYMENT / BILLING CODE - KEEP COMMENTED
    // =======================================================
    //
    // Current behavior:
    // - Firestore booking is created.
    // - paymentStatus = testing_bypassed.
    // - bookingStatus = pending_admin_review.
    // - No real money is charged.
    //
    // Production behavior after billing/payment activation:
    // 1. Recheck live vehicle and hotel availability.
    // 2. Load admin-controlled price and commission.
    // 3. Start Wallet/JazzCash/Easypaisa transaction.
    // 4. Confirm payment server-side.
    // 5. Set realPaymentProcessed = true.
    // 6. Confirm booking and notify assigned partners.
    //
    // Firebase Storage remains bypassed by project decision.
    // =======================================================
  }

  Future<void> _showConfirmation({
    required String bookingId,
    required Map<String, dynamic> vehicle,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Row(
            children: <Widget>[
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tour Booking Created',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _dialogRow(
                'Booking ID',
                bookingId,
              ),
              _dialogRow(
                'Vehicle',
                vehicle['name'].toString(),
              ),
              _dialogRow(
                'Hotel',
                _selectedHotelResult?[
                            'hotelName']
                        ?.toString() ??
                    'Not included',
              ),
              _dialogRow(
                'Total',
                'PKR ${_money(_finalTotal)}',
              ),
              _dialogRow(
                'Payment',
                'Testing bypass',
              ),
              const SizedBox(height: 12),
              const Text(
                'Booking was saved to Firestore. Admin will assign the tourism driver and guide.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor:
                    Colors.black,
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogRow(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _money(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(
            r'\B(?=(\d{3})+(?!\d))',
          ),
          (match) => ',',
        );
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
          backgroundColor:
              isError ? Colors.red : darkCard,
        ),
      );
  }
}
