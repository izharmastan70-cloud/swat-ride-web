import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/ride_model.dart';
import '../../services/ride_service.dart';
import '../services/driver_ride_service.dart';

class DriverRideRequestsScreen extends StatefulWidget {
  final String driverId;
  final String driverName;
  final String vehicleType;
  final String vehicleNumber;

  const DriverRideRequestsScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.vehicleType,
    required this.vehicleNumber,
  });

  @override
  State<DriverRideRequestsScreen> createState() =>
      _DriverRideRequestsScreenState();
}

class _DriverRideRequestsScreenState
    extends State<DriverRideRequestsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color softCard = Color(0xFF252525);

  final DriverRideService _rideService =
      DriverRideService();
  final RideService _rideStartService = RideService();

  String? _processingRideId;

  bool get _isProcessing =>
      _processingRideId != null;

  // =========================================================
  // ACCEPT REAL RIDE
  // =========================================================

  Future<void> _acceptRide(
    RideModel ride,
  ) async {
    if (_isProcessing) return;

    setState(() {
      _processingRideId = ride.rideId;
    });

    try {
      await _rideService.acceptRide(
        rideId: ride.rideId,
        driverId: widget.driverId,
        driverName: widget.driverName,
        vehicleType: widget.vehicleType,
        vehicleNumber: widget.vehicleNumber,
      );

      if (!mounted) return;

      _showMessage(
        'Ride accepted successfully.',
        Colors.green,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _cleanError(error),
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingRideId = null;
        });
      }
    }
  }

  // =========================================================
  // REJECT CONFIRMATION
  // =========================================================

  Future<void> _confirmReject(
    RideModel ride,
  ) async {
    if (_isProcessing) return;

    final String? reason =
        await showModalBottomSheet<String>(
      context: context,
      backgroundColor: darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Why are you declining?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This request will be offered to another nearby Driver.',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                _rejectReasonTile(
                  context: bottomSheetContext,
                  icon: Icons.route_rounded,
                  title: 'Pickup is too far',
                  value: 'pickup_too_far',
                ),
                _rejectReasonTile(
                  context: bottomSheetContext,
                  icon: Icons.location_off_rounded,
                  title: 'Destination not suitable',
                  value: 'destination_not_suitable',
                ),
                _rejectReasonTile(
                  context: bottomSheetContext,
                  icon: Icons.payments_outlined,
                  title: 'Fare is too low',
                  value: 'fare_too_low',
                ),
                _rejectReasonTile(
                  context: bottomSheetContext,
                  icon: Icons.more_horiz_rounded,
                  title: 'Other reason',
                  value: 'other',
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(bottomSheetContext);
                    },
                    child: const Text(
                      'Keep Request',
                      style: TextStyle(
                        color: yellow,
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

    if (reason == null) return;

    await _rejectRide(
      ride: ride,
      reason: reason,
    );
  }

  Widget _rejectReasonTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white70,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.white38,
      ),
      onTap: () {
        Navigator.pop(context, value);
      },
    );
  }

  // =========================================================
  // REJECT REAL RIDE
  // =========================================================

  Future<void> _rejectRide({
    required RideModel ride,
    required String reason,
  }) async {
    if (_isProcessing) return;

    setState(() {
      _processingRideId = ride.rideId;
    });

    try {
      await _rideService.rejectRide(
        rideId: ride.rideId,
        driverId: widget.driverId,
        reason: reason,
      );

      if (!mounted) return;

      _showMessage(
        'Ride declined. Looking for another request.',
        Colors.orange,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _cleanError(error),
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingRideId = null;
        });
      }
    }
  }

  // =========================================================
  // DRIVER ARRIVING
  // =========================================================

  Future<void> _startPickup(
    RideModel ride,
  ) async {
    if (_isProcessing) return;

    setState(() {
      _processingRideId = ride.rideId;
    });

    try {
      if (ride.status == RideModel.driverAssigned) {
        await _rideService.updateRideStatus(
          rideId: ride.rideId,
          driverId: widget.driverId,
          newStatus: RideModel.driverArriving,
        );
      }

      if (!mounted) return;

      _showMessage(
        'Pickup started. Drive safely.',
        Colors.green,
      );

      // =====================================================
      // FUTURE REAL MAP NAVIGATION
      // =====================================================
      //
      // Google Maps navigation will open here after Maps
      // billing is enabled.
      //
      // Testing mode currently keeps the Driver on the
      // accepted ride card without opening Google Maps.
      // =====================================================
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _cleanError(error),
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingRideId = null;
        });
      }
    }
  }

  // =========================================================
  // DRIVER ARRIVED AT PICKUP
  // =========================================================

  Future<void> _markDriverArrived(
    RideModel ride,
  ) async {
    if (_isProcessing) return;

    if (ride.status != RideModel.driverArriving) {
      _showMessage(
        'Start pickup before marking arrival.',
        Colors.orange,
      );
      return;
    }

    setState(() {
      _processingRideId = ride.rideId;
    });

    try {
      await _rideService.updateRideStatus(
        rideId: ride.rideId,
        driverId: widget.driverId,
        newStatus: RideModel.driverArrived,
      );

      if (!mounted) return;

      _showMessage(
        'Arrival confirmed. Passenger has been notified.',
        Colors.green,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _cleanError(error),
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingRideId = null;
        });
      }
    }
  }

  // =========================================================
  // ENTER PIN + START RIDE
  // =========================================================

  Future<void> _requestRideStartPin(
    RideModel ride,
  ) async {
    if (_isProcessing) return;

    if (ride.status != RideModel.driverArrived) {
      _showMessage(
        'Confirm Driver arrival before starting the ride.',
        Colors.orange,
      );
      return;
    }

    final TextEditingController pinController =
        TextEditingController();

    final String? enteredPin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: yellow),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Start Ride PIN',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ask the Rider for the 4-digit PIN shown in their app.',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: pinController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 10,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  hintStyle: const TextStyle(
                    color: Colors.white24,
                    letterSpacing: 10,
                  ),
                  filled: true,
                  fillColor: softCard,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: yellow, width: 2),
                  ),
                ),
                onSubmitted: (String value) {
                  if (value.length == 4) {
                    Navigator.pop(dialogContext, value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final String pin = pinController.text.trim();
                if (pin.length != 4) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Enter the complete 4-digit PIN.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, pin);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'VERIFY & START',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    pinController.dispose();

    if (enteredPin == null || !mounted) return;

    setState(() {
      _processingRideId = ride.rideId;
    });

    try {
      await _rideStartService.verifyRideStartPinAndStart(
        rideId: ride.rideId,
        driverId: widget.driverId,
        enteredPin: enteredPin,
      );

      if (!mounted) return;

      _showMessage(
        'PIN verified. Ride started successfully.',
        Colors.green,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _cleanError(error),
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingRideId = null;
        });
      }
    }
  }

  // =========================================================
  // COMPLETE ACTIVE RIDE
  // =========================================================

  Future<void> _confirmCompleteRide(
    RideModel ride,
  ) async {
    if (_isProcessing) return;

    if (ride.status != RideModel.rideStarted) {
      _showMessage(
        'Only a started ride can be completed.',
        Colors.orange,
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.flag_rounded, color: yellow),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Complete this ride?',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirm only after the Rider safely reaches the destination.',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: softCard,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      color: yellow,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_paymentName(ride.paymentMethod)} • '
                        'Rs. ${ride.estimatedFare.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Not Yet',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'COMPLETE RIDE',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _processingRideId = ride.rideId;
    });

    try {
      await _rideStartService.completeRide(ride.rideId);

      if (!mounted) return;

      _showMessage(
        'Ride completed successfully.',
        Colors.green,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        _cleanError(error),
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingRideId = null;
        });
      }
    }
  }

  // =========================================================
  // FIRESTORE REFRESH
  // =========================================================

  Future<void> _refreshRequests() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 450),
    );

    if (!mounted) return;

    setState(() {});

    _showMessage(
      'Ride requests refreshed.',
      yellow,
      textColor: Colors.black,
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message,
    Color color, {
    Color textColor = Colors.white,
  }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '');
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
        title: const Text(
          'Ride Requests',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _isProcessing
                    ? null
                    : _refreshRequests,
            icon: const Icon(
              Icons.refresh_rounded,
              color: yellow,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<RideModel?>(
          stream: _rideService.watchActiveDriverRide(
            widget.driverId,
          ),
          builder: (
            context,
            activeRideSnapshot,
          ) {
            if (activeRideSnapshot.hasError) {
              return _buildErrorState(
                activeRideSnapshot.error,
              );
            }

            final RideModel? activeRide =
                activeRideSnapshot.data;

            if (activeRide != null) {
              return _buildScrollableBody(
                children: [
                  _buildDriverCard(
                    isBusy: true,
                  ),
                  const SizedBox(height: 18),
                  _buildActiveRideCard(activeRide),
                  const SizedBox(height: 18),
                  _buildRealModeNotice(),
                ],
              );
            }

            return StreamBuilder<List<RideModel>>(
              stream:
                  _rideService.watchAvailableRides(
                driverId: widget.driverId,
                vehicleType: widget.vehicleType,
              ),
              builder: (
                context,
                requestsSnapshot,
              ) {
                if (requestsSnapshot.connectionState ==
                        ConnectionState.waiting &&
                    !requestsSnapshot.hasData) {
                  return _buildScrollableBody(
                    children: [
                      _buildDriverCard(
                        isBusy: false,
                      ),
                      const SizedBox(height: 18),
                      _buildLoadingCard(),
                    ],
                  );
                }

                if (requestsSnapshot.hasError) {
                  return _buildErrorState(
                    requestsSnapshot.error,
                  );
                }

                final List<RideModel> rides =
                    requestsSnapshot.data ??
                        <RideModel>[];

                return _buildScrollableBody(
                  children: [
                    _buildDriverCard(
                      isBusy: false,
                    ),
                    const SizedBox(height: 20),
                    _buildRequestHeader(
                      rides.length,
                    ),
                    const SizedBox(height: 14),
                    if (rides.isEmpty)
                      _buildEmptyState()
                    else
                      ...rides.map(
                        (ride) => Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 14,
                          ),
                          child:
                              _buildRideRequestCard(
                            ride,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    _buildRealModeNotice(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildScrollableBody({
    required List<Widget> children,
  }) {
    return RefreshIndicator(
      color: yellow,
      backgroundColor: darkCard,
      onRefresh: _refreshRequests,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          30,
        ),
        children: children,
      ),
    );
  }

  // =========================================================
  // DRIVER CARD
  // =========================================================

  Widget _buildDriverCard({
    required bool isBusy,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: yellow.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_taxi_rounded,
              color: yellow,
              size: 29,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.driverName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${widget.vehicleType} • '
                  '${widget.vehicleNumber}',
                  style: TextStyle(
                    color:
                        Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _statusBadge(
            isBusy: isBusy,
          ),
        ],
      ),
    );
  }

  Widget _statusBadge({
    required bool isBusy,
  }) {
    final Color statusColor =
        isBusy ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(
          alpha: 0.14,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 4,
            backgroundColor: statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            isBusy ? 'BUSY' : 'READY',
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // REQUEST HEADER
  // =========================================================

  Widget _buildRequestHeader(
    int requestCount,
  ) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Nearby requests',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Requests matching your vehicle',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          constraints: const BoxConstraints(
            minWidth: 38,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: yellow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$requestCount',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // REAL RIDE REQUEST CARD
  // =========================================================

  Widget _buildRideRequestCard(
    RideModel ride,
  ) {
    final bool processingThisRide =
        _processingRideId == ride.rideId;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: yellow.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.25,
            ),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: yellow,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: const Text(
                  'NEW RIDE',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _requestTimeText(
                  ride.createdAt,
                ),
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: const BoxDecoration(
                  color: softCard,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SWAT RIDE Passenger',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ride ID: ${_shortRideId(ride.rideId)}',
                      style: TextStyle(
                        color:
                            Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.verified_rounded,
                color: Colors.blue,
                size: 21,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildRouteBox(ride),
          const SizedBox(height: 14),
          _buildRideDetails(ride),
          const SizedBox(height: 14),
          _buildFareBox(ride),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isProcessing
                          ? null
                          : () {
                            _confirmReject(ride);
                          },
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        Colors.white,
                    side: BorderSide(
                      color:
                          Colors.grey.shade700,
                    ),
                    minimumSize:
                        const Size(0, 54),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed:
                      _isProcessing
                          ? null
                          : () {
                            _acceptRide(ride);
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor:
                        Colors.black,
                    disabledBackgroundColor:
                        yellow.withValues(
                      alpha: 0.45,
                    ),
                    minimumSize:
                        const Size(0, 54),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),
                  child:
                      processingThisRide
                          ? const SizedBox(
                            width: 21,
                            height: 21,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.black,
                            ),
                          )
                          : const Text(
                            'ACCEPT RIDE',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ROUTE BOX
  // =========================================================

  Widget _buildRouteBox(
    RideModel ride,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softCard,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          _locationRow(
            color: Colors.green,
            label: 'PICKUP',
            value: _locationText(
              ride.pickupLocation.placeName,
              ride.pickupLocation.address,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 5),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 26,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),
          _locationRow(
            color: Colors.red,
            label: 'DESTINATION',
            value: _locationText(
              ride.destinationLocation.placeName,
              ride.destinationLocation.address,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationRow({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // RIDE DETAILS
  // =========================================================

  Widget _buildRideDetails(
    RideModel ride,
  ) {
    return Row(
      children: [
        Expanded(
          child: _detailBox(
            icon: Icons.route_rounded,
            label: 'Distance',
            value:
                '${ride.distanceKm.toStringAsFixed(1)} km',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _detailBox(
            icon: Icons.access_time_rounded,
            label: 'Trip time',
            value:
                '${ride.estimatedMinutes} min',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _detailBox(
            icon: Icons.local_taxi_rounded,
            label: 'Vehicle',
            value: ride.vehicleName,
          ),
        ),
      ],
    );
  }

  Widget _detailBox({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: softCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: yellow,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FARE BOX
  // =========================================================

  Widget _buildFareBox(
    RideModel ride,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.28,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 41,
            height: 41,
            decoration: BoxDecoration(
              color: yellow.withValues(
                alpha: 0.14,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: yellow,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _paymentName(
                    ride.paymentMethod,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                Text(
                  'Payment after ride',
                  style: TextStyle(
                    color:
                        Colors.grey.shade500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Rs. ${ride.estimatedFare.toStringAsFixed(0)}',
            style: const TextStyle(
              color: yellow,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ACTIVE RIDE CARD
  // =========================================================

  Widget _buildActiveRideCard(
    RideModel ride,
  ) {
    final bool processingThisRide =
        _processingRideId == ride.rideId;
    final bool canStartPickup =
        ride.status == RideModel.driverAssigned;
    final bool canMarkArrived =
        ride.status == RideModel.driverArriving;
    final bool canStartRide =
        ride.status == RideModel.driverArrived;
    final bool canCompleteRide =
        ride.status == RideModel.rideStarted;
    final bool canUpdatePickup =
        canStartPickup ||
        canMarkArrived ||
        canStartRide ||
        canCompleteRide;

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.green.withValues(
            alpha: 0.50,
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
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(
                    alpha: 0.15,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.green,
                  size: 29,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Ride',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusName(ride.status),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildRouteBox(ride),
          const SizedBox(height: 14),
          _buildFareBox(ride),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed:
                  _isProcessing || !canUpdatePickup
                      ? null
                      : () {
                        if (canStartPickup) {
                          _startPickup(ride);
                        } else if (canMarkArrived) {
                          _markDriverArrived(ride);
                        } else if (canStartRide) {
                          _requestRideStartPin(ride);
                        } else {
                          _confirmCompleteRide(ride);
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canMarkArrived || canStartRide
                        ? Colors.green
                        : yellow,
                foregroundColor:
                    canMarkArrived || canStartRide
                        ? Colors.white
                        : Colors.black,
                disabledBackgroundColor:
                    Colors.grey.shade800,
                disabledForegroundColor:
                    Colors.white54,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
              icon:
                  processingThisRide
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: canMarkArrived || canStartRide
                              ? Colors.white
                              : Colors.black,
                        ),
                      )
                      : Icon(
                        canMarkArrived
                            ? Icons.pin_drop_rounded
                            : canStartRide
                                ? Icons.lock_open_rounded
                            : canCompleteRide
                                ? Icons.flag_rounded
                            : canStartPickup
                                ? Icons.navigation_rounded
                                : Icons.hourglass_top_rounded,
                      ),
              label: Text(
                canStartPickup
                    ? 'START PICKUP'
                    : canMarkArrived
                        ? 'I HAVE ARRIVED'
                        : canStartRide
                            ? 'ENTER PIN & START RIDE'
                            : canCompleteRide
                                ? 'COMPLETE RIDE'
                                : 'RIDE IN PROGRESS',
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Google Maps navigation will be connected after Maps billing is enabled.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // LOADING
  // =========================================================

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 55,
      ),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(
            color: yellow,
          ),
          SizedBox(height: 18),
          Text(
            'Checking real ride requests...',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 42,
      ),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: yellow.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.radar_rounded,
              color: yellow,
              size: 45,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Looking for rides',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'A real Rider booking matching your vehicle will appear here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _refreshRequests,
            style: OutlinedButton.styleFrom(
              foregroundColor: yellow,
              side: const BorderSide(
                color: yellow,
              ),
              minimumSize:
                  const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'CHECK AGAIN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _buildErrorState(
    Object? error,
  ) {
    return RefreshIndicator(
      color: yellow,
      onRefresh: _refreshRequests,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          _buildDriverCard(
            isBusy: false,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: darkCard,
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Unable to load requests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _cleanError(
                    error ?? 'Unknown error',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        Colors.grey.shade400,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _refreshRequests,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor:
                        Colors.black,
                  ),
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: const Text(
                    'Retry',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // REAL MODE NOTICE
  // =========================================================

  Widget _buildRealModeNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_done_rounded,
            color: Colors.green,
            size: 20,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Real Firestore matching is active. Maps navigation remains safely bypassed until billing is enabled.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DISPLAY HELPERS
  // =========================================================

  String _locationText(
    String placeName,
    String address,
  ) {
    final String cleanPlace =
        placeName.trim();

    final String cleanAddress =
        address.trim();

    if (cleanPlace.isNotEmpty &&
        cleanAddress.isNotEmpty &&
        cleanPlace != cleanAddress) {
      return '$cleanPlace\n$cleanAddress';
    }

    if (cleanPlace.isNotEmpty) {
      return cleanPlace;
    }

    if (cleanAddress.isNotEmpty) {
      return cleanAddress;
    }

    return 'Location unavailable';
  }

  String _shortRideId(
    String rideId,
  ) {
    if (rideId.length <= 8) {
      return rideId;
    }

    return rideId.substring(
      rideId.length - 8,
    );
  }

  String _paymentName(
    String paymentMethod,
  ) {
    switch (paymentMethod
        .trim()
        .toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'wallet':
        return 'SWAT RIDE Wallet';
      case 'jazzcash':
        return 'JazzCash';
      case 'easypaisa':
        return 'Easypaisa';
      case 'card':
        return 'Card';
      default:
        return paymentMethod.isEmpty
            ? 'Cash'
            : paymentMethod;
    }
  }

  String _statusName(
    String status,
  ) {
    switch (status) {
      case RideModel.driverAssigned:
        return 'Ride Accepted';
      case RideModel.driverArriving:
        return 'Going to Pickup';
      case RideModel.driverArrived:
        return 'Driver Arrived';
      case RideModel.rideStarted:
        return 'Ride in Progress';
      case RideModel.completed:
        return 'Ride Completed';
      case RideModel.cancelled:
        return 'Ride Cancelled';
      default:
        return 'Active Ride';
    }
  }

  String _requestTimeText(
    DateTime createdAt,
  ) {
    final Duration difference =
        DateTime.now().difference(createdAt);

    if (difference.inSeconds < 30) {
      return 'Just now';
    }

    if (difference.inMinutes < 1) {
      return '${difference.inSeconds}s ago';
    }

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }

    return '${difference.inHours}h ago';
  }
}
