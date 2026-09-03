import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/location_model.dart';
import '../models/map_location_model.dart';
import '../models/payment_model.dart';
import '../models/ride_pricing_model.dart';
import '../models/vehicle_model.dart';
import '../services/ride_payment_service.dart';
import '../services/ride_pricing_service.dart';
import '../help/widgets/contextual_video_guide_button.dart';
import '../services/ride_service.dart';
import '../widgets/open_map_view_widget.dart';
import 'ride_searching_screen.dart';

class RideConfirmationScreen extends StatefulWidget {
  final LocationModel pickupLocation;
  final LocationModel destinationLocation;
  final VehicleModel selectedVehicle;

  const RideConfirmationScreen({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.selectedVehicle,
  });

  @override
  State<RideConfirmationScreen> createState() => _RideConfirmationScreenState();
}

class _RideConfirmationScreenState extends State<RideConfirmationScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color darkCard = Color(0xFF1A1A1A);

  // =========================================================
  // PAYMENT
  // =========================================================

  RidePaymentMethod _selectedPaymentMethod = RidePaymentMethod.cash;

  final RideService _rideService = RideService();
  final RidePaymentService _paymentService = RidePaymentService();
  final RidePricingService _pricingService = RidePricingService();

  List<RidePaymentMethodConfig> _paymentMethods =
      const <RidePaymentMethodConfig>[];
  bool _loadingPaymentMethods = true;

  // =========================================================
  // BOOKING STATE
  // =========================================================

  bool _isBooking = false;

  // =========================================================
  // PROMO
  // =========================================================

  final TextEditingController promoController = TextEditingController();

  bool promoApplied = false;

  // =========================================================
  // REAL PRICING / TESTING ROUTE BYPASS
  // =========================================================

  RideFareEstimate? _fareEstimate;
  bool _loadingFare = true;
  String? _fareError;

  double promoDiscount = 0.0;

  double get distanceKm => _fareEstimate?.distanceKm ?? 0;
  int get estimatedMinutes => _fareEstimate?.estimatedMinutes ?? 0;
  double get baseFare => _fareEstimate?.baseFare ?? 0;
  double get estimatedFareBeforePromo => _fareEstimate?.estimatedFare ?? 0;

  @override
  void initState() {
    super.initState();
    _loadFareEstimate();
  }

  Future<void> _loadFareEstimate() async {
    if (mounted) {
      setState(() {
        _loadingFare = true;
        _fareError = null;
      });
    }

    try {
      final RideFareEstimate estimate = await _pricingService.estimateFare(
        pickup: widget.pickupLocation,
        destination: widget.destinationLocation,
        vehicle: widget.selectedVehicle,
      );

      if (!mounted) return;
      setState(() {
        _fareEstimate = estimate;
        _loadingFare = false;
      });
      await _loadPaymentMethods();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _fareEstimate = null;
        _loadingFare = false;
        _fareError = _cleanError(error);
        _paymentMethods = const <RidePaymentMethodConfig>[];
        _loadingPaymentMethods = false;
      });
    }
  }

  Future<void> _loadPaymentMethods() async {
    final List<RidePaymentMethodConfig> methods = await _paymentService
        .getEnabledPaymentMethods(amount: finalFare);

    if (!mounted) return;
    setState(() {
      _paymentMethods = methods;
      _loadingPaymentMethods = false;
      if (methods.isNotEmpty &&
          !methods.any(
            (RidePaymentMethodConfig item) =>
                item.method == _selectedPaymentMethod,
          )) {
        _selectedPaymentMethod = methods.first.method;
      }
    });
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    promoController.dispose();
    super.dispose();
  }

  // =========================================================
  // FINAL FARE
  // =========================================================

  double get finalFare {
    final double fare = estimatedFareBeforePromo - promoDiscount;

    return fare < 0 ? 0 : fare;
  }

  // =========================================================
  // APPLY PROMO
  // =========================================================

  void _applyPromo() {
    final String code = promoController.text.trim().toUpperCase();

    if (code.isEmpty) {
      _showError('Please enter a promo code.');
      return;
    }

    // Temporary promo testing
    if (code == 'SWAT10') {
      setState(() {
        promoDiscount = 10.0;
        promoApplied = true;
      });

      _showSuccess('Promo code applied successfully.');
      _loadPaymentMethods();
    } else {
      setState(() {
        promoDiscount = 0.0;
        promoApplied = false;
      });

      _showError('Invalid or expired promo code.');
      _loadPaymentMethods();
    }
  }

  // =========================================================
  // CONFIRM RIDE
  // =========================================================

  Future<void> _confirmRide() async {
    if (_isBooking) {
      return;
    }

    final RideFareEstimate? fareEstimate = _fareEstimate;
    if (_loadingFare || fareEstimate == null) {
      _showError(_fareError ?? 'Fare is still being calculated.');
      return;
    }

    if (_loadingPaymentMethods || _paymentMethods.isEmpty) {
      _showError('No payment method is currently available.');
      return;
    }

    final String? userId = _rideService.currentUserId;
    if (userId == null || userId.isEmpty) {
      _showError('Please login before booking a ride.');
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      final String rideId = await _rideService.createRide(
        pickupLocation: widget.pickupLocation,
        destinationLocation: widget.destinationLocation,
        selectedVehicle: widget.selectedVehicle,
        distanceKm: distanceKm,
        estimatedMinutes: estimatedMinutes,
        baseFare: baseFare,
        estimatedFare: finalFare,
        paymentMethod: _selectedPaymentMethod.firestoreValue,
        promoCode: promoApplied
            ? promoController.text.trim().toUpperCase()
            : null,
        promoDiscount: promoDiscount,
        commissionAmount: fareEstimate.adminCommissionAmount,
      );

      if (!mounted) {
        return;
      }

      // Payment record uses the same real ride ID. During testing, paid
      // providers use the protected bypass in RidePaymentService.
      try {
        await _paymentService.createPayment(
          rideId: rideId,
          userId: userId,
          method: _selectedPaymentMethod,
          amount: finalFare,
        );
      } catch (paymentError) {
        // The ride is already created. Do not leave the rider stuck on this
        // screen because of a temporary payment-record network failure.
        debugPrint('RIDE PAYMENT RECORD ERROR: $paymentError');
      }

      if (!mounted) return;

      // Ride has been created in Firestore. Open the live matching screen
      // with the same real ride ID so Rider and Driver use one document.
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (BuildContext context) =>
              RideSearchingScreen(rideId: rideId),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('================================');
      debugPrint('CONFIRM RIDE ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('================================');

      if (!mounted) {
        return;
      }

      _showError('Booking failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  // =========================================================
  // ERROR SNACKBAR
  // =========================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(message)),
    );
  }

  // =========================================================
  // SUCCESS
  // =========================================================

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.green, content: Text(message)),
    );
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  // =========================================================
  // LOCATION ROW
  // =========================================================

  Widget _locationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // INFO ROW
  // =========================================================

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: yellow, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PAYMENT METHOD
  // =========================================================

  Widget _paymentOption(RidePaymentMethodConfig config) {
    final bool selected = _selectedPaymentMethod == config.method;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _isBooking
          ? null
          : () {
              setState(() {
                _selectedPaymentMethod = config.method;
              });
            },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? yellow.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? yellow : Colors.white24),
        ),
        child: Row(
          children: [
            Icon(
              _paymentIcon(config.method),
              color: selected ? yellow : Colors.white70,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                config.title,
                style: TextStyle(
                  color: selected ? yellow : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? yellow : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  IconData _paymentIcon(RidePaymentMethod method) {
    switch (method) {
      case RidePaymentMethod.cash:
        return Icons.money;
      case RidePaymentMethod.wallet:
        return Icons.account_balance_wallet;
      case RidePaymentMethod.jazzCash:
        return Icons.phone_android;
      case RidePaymentMethod.easypaisa:
        return Icons.mobile_friendly;
      case RidePaymentMethod.bankCard:
        return Icons.credit_card;
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: _isBooking
              ? null
              : () {
                  Navigator.pop(context);
                },
        ),
        title: const Text(
          'Confirm Your Ride',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // ROUTE CARD
              // =================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _locationRow(
                      icon: Icons.my_location,
                      iconColor: Colors.green,
                      title: 'Pickup',
                      value: widget.pickupLocation.placeName,
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: Colors.white24),
                    ),

                    _locationRow(
                      icon: Icons.location_on,
                      iconColor: Colors.red,
                      title: 'Destination',
                      value: widget.destinationLocation.placeName,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_loadingFare)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: darkCard,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: <Widget>[
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: yellow,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Calculating distance, time and fare...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_fareError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.error_outline, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _fareError!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        onPressed: _loadFareEstimate,
                        icon: const Icon(Icons.refresh, color: yellow),
                      ),
                    ],
                  ),
                ),

              // =================================================
              // RIDE DETAILS
              // =================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _infoRow(
                      icon: Icons.directions_car,
                      title: 'Vehicle',
                      value: widget.selectedVehicle.name,
                    ),

                    const SizedBox(height: 16),

                    _infoRow(
                      icon: Icons.route,
                      title: 'Distance',
                      value: _loadingFare
                          ? 'Calculating...'
                          : '${distanceKm.toStringAsFixed(1)} km',
                    ),

                    const SizedBox(height: 16),

                    _infoRow(
                      icon: Icons.access_time,
                      title: 'Estimated Time',
                      value: _loadingFare
                          ? 'Calculating...'
                          : '$estimatedMinutes min',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // =================================================
              // MAP ROUTE PREVIEW
              // =================================================
              SizedBox(
                height: 180,
                width: double.infinity,
                child: OpenMapViewWidget(
                  initialLocation: MapLocation.fromCoordinates(
                    widget.pickupLocation.latitude,
                    widget.pickupLocation.longitude,
                    addressName: widget.pickupLocation.placeName,
                  ),
                  onLocationChanged: (_) {},
                  showCenterPin: false,
                  showLocationCard: false,
                  markerColor: Colors.green,
                  markerSize: 36,
                  additionalPins: <MapPin>[
                    MapPin(
                      location: MapLocation.fromCoordinates(
                        widget.destinationLocation.latitude,
                        widget.destinationLocation.longitude,
                      ),
                      color: Colors.red,
                    ),
                  ],
                  routePoints: _fareEstimate?.routeGeometry
                          .map((point) => LatLng(point.latitude, point.longitude))
                          .toList(growable: false) ??
                      const <LatLng>[],
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // FARE
              // =================================================
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _infoRow(
                      icon: Icons.payments_outlined,
                      title: 'Estimated Fare',
                      value: _loadingFare
                          ? 'Calculating...'
                          : 'Rs ${estimatedFareBeforePromo.toStringAsFixed(0)}',
                    ),

                    if (promoApplied) ...[
                      const SizedBox(height: 12),

                      _infoRow(
                        icon: Icons.discount,
                        title: 'Promo Discount',
                        value: '- Rs ${promoDiscount.toStringAsFixed(0)}',
                      ),
                    ],

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: Colors.white24),
                    ),

                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Total Fare',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Text(
                          'Rs ${finalFare.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: yellow,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // =================================================
              // PROMO CODE
              // =================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: promoController,
                        enabled: !_isBooking && !promoApplied,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Enter promo code',
                          hintStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(
                            Icons.local_offer_outlined,
                            color: yellow,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    ElevatedButton(
                      onPressed: _isBooking || promoApplied
                          ? null
                          : _applyPromo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: yellow,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(promoApplied ? 'Applied' : 'Apply'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // =================================================
              // PAYMENT METHOD
              // =================================================
              const Text(
                'Payment Method',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (_loadingPaymentMethods)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: yellow),
                  ),
                )
              else if (_paymentMethods.isEmpty)
                const Text(
                  'No payment method is available. Please contact support.',
                  style: TextStyle(color: Colors.redAccent),
                )
              else
                ..._paymentMethods.map(
                  (RidePaymentMethodConfig config) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _paymentOption(config),
                  ),
                ),

              const SizedBox(height: 24),

              // =================================================
              // CONFIRM RIDE
              // =================================================
              ContextualVideoGuideButton(
                module: 'ride',
                feature: 'ride_confirmation',
                intents: const <String>[
                  'confirm_ride',
                  'ride_booking',
                  'pickup_dropoff',
                  'ride_fare',
                ],
                label: 'Need Help? Watch Guide',
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _isBooking ||
                          _loadingFare ||
                          _fareEstimate == null ||
                          _loadingPaymentMethods ||
                          _paymentMethods.isEmpty
                      ? null
                      : _confirmRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade700,
                    disabledForegroundColor: Colors.white54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isBooking
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'Confirm Ride â€¢ Rs ${finalFare.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
}
