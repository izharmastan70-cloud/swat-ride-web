// lib/food/rider/screens/food_delivery_active_delivery_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Food Delivery Rider Active Delivery Screen
//
// Connected with:
// - FoodDeliveryRiderModel
// - FoodDeliveryRiderService
// - FoodOrderModel
//
// Real features:
// - Live Firestore order updates
// - Pickup and delivery information
// - Confirm pickup
// - Start delivery
// - Complete delivery with OTP
// - Rider live-coordinate update
// - Cancel assigned delivery with reason
// - Payment and earning summary
//
// Google Maps rendering remains temporarily bypassed.
// Firestore coordinates and live order updates remain real.
// =============================================================

import 'package:flutter/material.dart';

import '../../models/food_order_model.dart';
import '../models/food_delivery_rider_model.dart';
import '../services/food_delivery_rider_service.dart';
import '../../../safety/models/safety_models.dart';
import '../../../safety/screens/safety_center_screen.dart';

class FoodDeliveryActiveDeliveryScreen
    extends StatefulWidget {
  const FoodDeliveryActiveDeliveryScreen({
    required this.rider,
    required this.order,
    super.key,
  });

  final FoodDeliveryRiderModel rider;
  final FoodOrderModel order;

  @override
  State<FoodDeliveryActiveDeliveryScreen>
      createState() =>
          _FoodDeliveryActiveDeliveryScreenState();
}

class _FoodDeliveryActiveDeliveryScreenState
    extends State<FoodDeliveryActiveDeliveryScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodDeliveryRiderService _riderService =
      FoodDeliveryRiderService();

  bool _isUpdating = false;

  FoodDeliveryRiderModel get initialRider =>
      widget.rider;

  FoodOrderModel get initialOrder =>
      widget.order;

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (_isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await action();
      _showMessage(successMessage);
    } on FoodDeliveryRiderServiceException
        catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(
        'Unable to update delivery: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _confirmPickup(
    FoodDeliveryRiderModel rider,
    FoodOrderModel order,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Confirm Pickup'),
          content: const Text(
            'Confirm that you have received the complete food order from the restaurant.',
            style: TextStyle(
              color: Colors.grey,
              height: 1.45,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Confirm Pickup'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _runAction(
      () => _riderService.confirmPickup(
        riderId: rider.riderId,
        orderId: order.orderId,
      ),
      'Food pickup confirmed.',
    );
  }

  Future<void> _startDelivery(
    FoodDeliveryRiderModel rider,
    FoodOrderModel order,
  ) async {
    await _runAction(
      () => _riderService.startDelivery(
        riderId: rider.riderId,
        orderId: order.orderId,
      ),
      'Delivery started.',
    );
  }

  Future<void> _completeDelivery(
    FoodDeliveryRiderModel rider,
    FoodOrderModel order,
  ) async {
    final TextEditingController controller =
        TextEditingController();

    final String? enteredOtp =
        await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Complete Delivery'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Customer delivery OTP',
              hintText: 'Enter OTP',
              filled: true,
              fillColor: const Color(0xFF252525),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final String value =
                    controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Verify & Complete'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (enteredOtp == null) {
      return;
    }

    final String expectedOtp =
        _readOrderString(
      order,
      'deliveryOtp',
      fallbackKey: 'otp',
    );

    if (expectedOtp.trim().isEmpty) {
      _showMessage(
        'Delivery OTP is missing from this order.',
      );
      return;
    }

    final double earning =
        order.deliveryFee > 0
            ? order.deliveryFee
            : 80;

    final bool cashOrder =
        order.paymentMethod.name
            .toLowerCase()
            .contains('cash');

    await _runAction(
      () => _riderService.completeDelivery(
        riderId: rider.riderId,
        orderId: order.orderId,
        enteredOtp: enteredOtp,
        expectedOtp: expectedOtp,
        riderEarning: earning,
        cashOrder: cashOrder,
      ),
      'Delivery completed successfully.',
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _cancelDelivery(
    FoodDeliveryRiderModel rider,
    FoodOrderModel order,
  ) async {
    final TextEditingController controller =
        TextEditingController();

    final String? reason =
        await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Cancel Assigned Delivery',
          ),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Cancellation reason',
              hintText:
                  'Explain why you cannot continue this delivery',
              filled: true,
              fillColor: const Color(0xFF252525),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () {
                final String value =
                    controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Delivery'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason == null) {
      return;
    }

    await _runAction(
      () => _riderService.cancelAssignedDelivery(
        riderId: rider.riderId,
        orderId: order.orderId,
        reason: reason,
      ),
      'Delivery released for another rider.',
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _updateCoordinates(
    FoodDeliveryRiderModel rider,
  ) async {
    final TextEditingController latitudeController =
        TextEditingController(
      text: rider.currentLatitude == 0
          ? ''
          : rider.currentLatitude
              .toStringAsFixed(6),
    );

    final TextEditingController longitudeController =
        TextEditingController(
      text: rider.currentLongitude == 0
          ? ''
          : rider.currentLongitude
              .toStringAsFixed(6),
    );

    final Map<String, double>? result =
        await showDialog<Map<String, double>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Update Live Coordinates',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: latitudeController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: longitudeController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final double? latitude =
                    double.tryParse(
                  latitudeController.text.trim(),
                );

                final double? longitude =
                    double.tryParse(
                  longitudeController.text.trim(),
                );

                if (latitude == null ||
                    longitude == null) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  <String, double>{
                    'latitude': latitude,
                    'longitude': longitude,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    latitudeController.dispose();
    longitudeController.dispose();

    if (result == null) {
      return;
    }

    await _runAction(
      () => _riderService.updateLiveLocation(
        riderId: rider.riderId,
        latitude: result['latitude']!,
        longitude: result['longitude']!,
      ),
      'Live coordinates updated.',
    );
  }


  void _openUniversalSafetyCenter(
    FoodDeliveryRiderModel rider,
    FoodOrderModel order,
  ) {
    final SafetyLocation? currentLocation =
        rider.currentLatitude == 0 &&
                rider.currentLongitude == 0
            ? null
            : SafetyLocation(
                latitude: rider.currentLatitude,
                longitude: rider.currentLongitude,
                placeName: 'Food rider live location',
              );

    final SafetyLocation destination =
        SafetyLocation(
      latitude: order.deliveryAddress.latitude,
      longitude: order.deliveryAddress.longitude,
      address: order.deliveryAddress.fullAddress,
      placeName: 'Customer delivery',
    );

    final SafetyPersonSnapshot riderPerson =
        SafetyPersonSnapshot(
      userId: rider.userId.isNotEmpty
          ? rider.userId
          : rider.riderId,
      role: SafetyUserRole.foodDeliveryRider,
      fullName: rider.fullName,
      phoneNumber: rider.phoneNumber,
      extraData: <String, dynamic>{
        'riderId': rider.riderId,
      },
    );

    final SafetyVehicleSnapshot vehicle =
        SafetyVehicleSnapshot(
      vehicleId: rider.riderId,
      vehicleType: rider.vehicleType.value,
      vehicleNumber: rider.registrationNumber,
      vehicleModel:
          '${rider.vehicleMake} ${rider.vehicleModel}'.trim(),
      vehicleColor: rider.vehicleColor,
      registrationNumber:
          rider.registrationNumber,
      imageUrl: rider.vehiclePhotoUrl,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return SafetyCenterScreen(
            contextData: SafetyContext(
              serviceType:
                  SafetyServiceType.foodDelivery,
              referenceId: order.orderId,
              initiatedByUserId:
                  rider.userId.isNotEmpty
                      ? rider.userId
                      : rider.riderId,
              initiatedByRole:
                  SafetyUserRole.foodDeliveryRider,
              sourcePage:
                  SafetySourcePage.activeDelivery,
              referenceStatus:
                  order.status.name,
              primaryPerson: riderPerson,
              vehicle: vehicle,
              currentLocation: currentLocation,
              destinationLocation: destination,
              serviceTitle:
                  'Food Delivery Rider Safety',
              serviceSubtitle:
                  order.restaurantName.trim().isEmpty
                      ? 'Active food delivery'
                      : order.restaurantName,
              paymentMethod:
                  order.paymentMethod.name,
              metadata: <String, dynamic>{
                'orderId': order.orderId,
                'riderId': rider.riderId,
                'customerId': order.customerId,
                'restaurantId': order.restaurantId,
                'restaurantName':
                    order.restaurantName,
                'grandTotal': order.grandTotal,
                'deliveryFee': order.deliveryFee,

                // Customer delivery OTP is intentionally
                // excluded from the safety context.
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Active Food Delivery',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Safety & SOS',
            onPressed: () {
              _openUniversalSafetyCenter(
                initialRider,
                initialOrder,
              );
            },
            icon: const Icon(
              Icons.shield_outlined,
              color: Colors.redAccent,
            ),
          ),
          IconButton(
            tooltip: 'Update coordinates',
            onPressed: () =>
                _updateCoordinates(
              initialRider,
            ),
            icon: const Icon(
              Icons.my_location,
            ),
          ),
        ],
      ),
      body:
          StreamBuilder<FoodDeliveryRiderModel?>(
        stream: _riderService.watchRiderById(
          initialRider.riderId,
        ),
        initialData: initialRider,
        builder: (
          BuildContext context,
          AsyncSnapshot<FoodDeliveryRiderModel?>
              riderSnapshot,
        ) {
          final FoodDeliveryRiderModel rider =
              riderSnapshot.data ?? initialRider;

          return StreamBuilder<FoodOrderModel?>(
            stream: _watchOrder(
              initialOrder.orderId,
            ),
            initialData: initialOrder,
            builder: (
              BuildContext context,
              AsyncSnapshot<FoodOrderModel?>
                  orderSnapshot,
            ) {
              if ((riderSnapshot.connectionState ==
                          ConnectionState.waiting ||
                      orderSnapshot.connectionState ==
                          ConnectionState.waiting) &&
                  !riderSnapshot.hasData &&
                  !orderSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: yellow,
                  ),
                );
              }

              if (riderSnapshot.hasError ||
                  orderSnapshot.hasError) {
                return _buildErrorState();
              }

              final FoodOrderModel? order =
                  orderSnapshot.data;

              if (order == null) {
                return const Center(
                  child: Text(
                    'Active food order was not found.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              if (order.riderId.trim().isNotEmpty &&
                  order.riderId != rider.riderId) {
                return _buildAccessDenied();
              }

              return ListView(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  30,
                ),
                children: <Widget>[
                  _buildStatusCard(order),
                  const SizedBox(height: 16),
                  _buildPickupCard(order),
                  const SizedBox(height: 16),
                  _buildDeliveryCard(order),
                  const SizedBox(height: 16),
                  _buildOrderCard(order),
                  const SizedBox(height: 16),
                  _buildPaymentCard(order, rider),
                  const SizedBox(height: 16),
                  _buildLocationCard(rider, order),
                  const SizedBox(height: 20),
                  _buildMainAction(
                    rider,
                    order,
                  ),
                  if (_canCancel(order.status)) ...<Widget>[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isUpdating
                            ? null
                            : () =>
                                _cancelDelivery(
                              rider,
                              order,
                            ),
                        icon: const Icon(
                          Icons.cancel_outlined,
                        ),
                        label: const Text(
                          'Cancel Assigned Delivery',
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              Colors.redAccent,
                          side: const BorderSide(
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Stream<FoodOrderModel?> _watchOrder(
    String orderId,
  ) {
    return _riderService
        .watchRiderActiveOrders(
          initialRider.riderId,
        )
        .map(
          (List<FoodOrderModel> orders) {
        for (final FoodOrderModel order in orders) {
          if (order.orderId == orderId) {
            return order;
          }
        }

        if (initialOrder.orderId == orderId &&
            initialOrder.status !=
                FoodOrderStatus.delivered &&
            initialOrder.status !=
                FoodOrderStatus.cancelled) {
          return initialOrder;
        }

        return null;
      },
    );
  }

  Widget _buildStatusCard(
    FoodOrderModel order,
  ) {
    final Color color =
        _statusColor(order.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: color.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 29,
            backgroundColor:
                color.withValues(alpha: 0.14),
            child: Icon(
              _statusIcon(order.status),
              color: color,
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Delivery status',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusText(order.status),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusDescription(
                    order.status,
                  ),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupCard(
    FoodOrderModel order,
  ) {
    return _sectionCard(
      title: 'Restaurant Pickup',
      icon: Icons.restaurant,
      children: <Widget>[
        _InfoRow(
          label: 'Restaurant ID',
          value: order.restaurantId,
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Order ID',
          value: order.orderId,
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Food items',
          value: '${order.items.length}',
        ),
        const SizedBox(height: 12),
        const Text(
          'Restaurant map rendering is bypassed for now. Pickup workflow and Firestore status updates remain real.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryCard(
    FoodOrderModel order,
  ) {
    return _sectionCard(
      title: 'Customer Delivery',
      icon: Icons.location_on_outlined,
      children: <Widget>[
        Text(
          order.deliveryAddress.fullAddress,
          style: const TextStyle(
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _InfoRow(
          label: 'Customer ID',
          value: order.customerId,
        ),
      ],
    );
  }

  Widget _buildOrderCard(
    FoodOrderModel order,
  ) {
    return _sectionCard(
      title: 'Order Summary',
      icon: Icons.receipt_long_outlined,
      children: <Widget>[
        ...order.items.map(
          (dynamic item) {
            final String name =
                _readItemString(item, 'name');

            final int quantity =
                _readItemInt(item, 'quantity');

            final double total =
                _readItemDouble(
              item,
              'totalPrice',
              fallbackKey: 'total',
            );

            return Container(
              margin:
                  const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      name.isEmpty
                          ? 'Food item'
                          : name,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'x$quantity',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Rs. ${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: yellow,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentCard(
    FoodOrderModel order,
    FoodDeliveryRiderModel rider,
  ) {
    final double earning =
        order.deliveryFee > 0
            ? order.deliveryFee
            : 80;

    final double commission =
        earning *
            (rider.commissionPercentage / 100);

    final double net =
        earning - commission;

    return _sectionCard(
      title: 'Payment & Earning',
      icon: Icons.payments_outlined,
      children: <Widget>[
        _InfoRow(
          label: 'Customer payment',
          value: order.paymentMethod.name,
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Order total',
          value:
              'Rs. ${order.grandTotal.toStringAsFixed(0)}',
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Delivery earning',
          value:
              'Rs. ${earning.toStringAsFixed(0)}',
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label:
              'Commission (${rider.commissionPercentage.toStringAsFixed(0)}%)',
          value:
              '- Rs. ${commission.toStringAsFixed(0)}',
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Estimated net earning',
          value:
              'Rs. ${net.toStringAsFixed(0)}',
          highlight: true,
        ),
      ],
    );
  }

  Widget _buildLocationCard(
    FoodDeliveryRiderModel rider,
    FoodOrderModel order,
  ) {
    return _sectionCard(
      title: 'Live Location',
      icon: Icons.my_location,
      children: <Widget>[
        _InfoRow(
          label: 'Latitude',
          value: rider.currentLatitude == 0
              ? 'Not updated'
              : rider.currentLatitude
                  .toStringAsFixed(6),
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Longitude',
          value: rider.currentLongitude == 0
              ? 'Not updated'
              : rider.currentLongitude
                  .toStringAsFixed(6),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isUpdating
                ? null
                : () =>
                    _updateCoordinates(rider),
            icon: const Icon(
              Icons.edit_location_alt_outlined,
            ),
            label: const Text(
              'Update Coordinates',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: yellow,
              side: const BorderSide(
                color: yellow,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainAction(
    FoodDeliveryRiderModel rider,
    FoodOrderModel order,
  ) {
    switch (order.status) {
      case FoodOrderStatus.readyForPickup:
        return _actionButton(
          label: 'Confirm Restaurant Pickup',
          icon: Icons.shopping_bag_outlined,
          onPressed: () =>
              _confirmPickup(rider, order),
        );

      case FoodOrderStatus.pickedUp:
        return _actionButton(
          label: 'Start Delivery to Customer',
          icon: Icons.route,
          onPressed: () =>
              _startDelivery(rider, order),
        );

      case FoodOrderStatus.onTheWay:
        return _actionButton(
          label: 'Verify OTP & Complete Delivery',
          icon: Icons.verified_outlined,
          onPressed: () =>
              _completeDelivery(rider, order),
          backgroundColor: Colors.greenAccent,
        );

      case FoodOrderStatus.delivered:
        return _completedMessage(
          'This food order has been delivered successfully.',
          Colors.greenAccent,
        );

      case FoodOrderStatus.cancelled:
        return _completedMessage(
          'This food order was cancelled.',
          Colors.redAccent,
        );

      case FoodOrderStatus.pending:
      case FoodOrderStatus.accepted:
      case FoodOrderStatus.preparing:
        return _completedMessage(
          'Waiting for the restaurant to mark this order ready for pickup.',
          Colors.orangeAccent,
        );
    }
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color backgroundColor = yellow,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed:
            _isUpdating ? null : onPressed,
        icon: _isUpdating
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _completedMessage(
    String message,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                icon,
                color: yellow,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  bool _canCancel(
    FoodOrderStatus status,
  ) {
    return status ==
            FoodOrderStatus.readyForPickup ||
        status ==
            FoodOrderStatus.pickedUp;
  }

  Widget _buildErrorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Text(
          'Unable to load active delivery. Check Firestore connection and security rules.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAccessDenied() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.lock_outline,
              color: Colors.redAccent,
              size: 72,
            ),
            SizedBox(height: 16),
            Text(
              'Delivery access unavailable',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This food order is assigned to another rider.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(
    FoodOrderStatus status,
  ) {
    switch (status) {
      case FoodOrderStatus.pending:
        return 'Pending';
      case FoodOrderStatus.accepted:
        return 'Accepted';
      case FoodOrderStatus.preparing:
        return 'Restaurant Preparing';
      case FoodOrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case FoodOrderStatus.pickedUp:
        return 'Food Picked Up';
      case FoodOrderStatus.onTheWay:
        return 'On the Way';
      case FoodOrderStatus.delivered:
        return 'Delivered';
      case FoodOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _statusDescription(
    FoodOrderStatus status,
  ) {
    switch (status) {
      case FoodOrderStatus.pending:
      case FoodOrderStatus.accepted:
      case FoodOrderStatus.preparing:
        return 'Wait until the restaurant marks the food ready.';
      case FoodOrderStatus.readyForPickup:
        return 'Collect and verify the complete order from the restaurant.';
      case FoodOrderStatus.pickedUp:
        return 'Start the customer delivery after leaving the restaurant.';
      case FoodOrderStatus.onTheWay:
        return 'Reach the customer and verify the delivery OTP.';
      case FoodOrderStatus.delivered:
        return 'The delivery workflow is complete.';
      case FoodOrderStatus.cancelled:
        return 'This delivery is no longer active.';
    }
  }

  IconData _statusIcon(
    FoodOrderStatus status,
  ) {
    switch (status) {
      case FoodOrderStatus.pending:
        return Icons.hourglass_top;
      case FoodOrderStatus.accepted:
        return Icons.check_circle_outline;
      case FoodOrderStatus.preparing:
        return Icons.soup_kitchen_outlined;
      case FoodOrderStatus.readyForPickup:
        return Icons.shopping_bag_outlined;
      case FoodOrderStatus.pickedUp:
        return Icons.delivery_dining;
      case FoodOrderStatus.onTheWay:
        return Icons.route;
      case FoodOrderStatus.delivered:
        return Icons.task_alt;
      case FoodOrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Color _statusColor(
    FoodOrderStatus status,
  ) {
    switch (status) {
      case FoodOrderStatus.pending:
        return yellow;
      case FoodOrderStatus.accepted:
      case FoodOrderStatus.preparing:
        return Colors.orangeAccent;
      case FoodOrderStatus.readyForPickup:
      case FoodOrderStatus.pickedUp:
      case FoodOrderStatus.onTheWay:
        return Colors.lightBlueAccent;
      case FoodOrderStatus.delivered:
        return Colors.greenAccent;
      case FoodOrderStatus.cancelled:
        return Colors.redAccent;
    }
  }

  String _readOrderString(
    FoodOrderModel order,
    String key, {
    String? fallbackKey,
  }) {
    try {
      final dynamic map = order.toMap();

      if (map is Map) {
        final dynamic value = map[key] ??
            (fallbackKey == null
                ? null
                : map[fallbackKey]);

        return value?.toString() ?? '';
      }
    } catch (_) {
      // Safe fallback.
    }

    return '';
  }

  String _readItemString(
    dynamic source,
    String key,
  ) {
    if (source is Map) {
      return source[key]?.toString() ?? '';
    }

    try {
      final dynamic map = source.toMap();

      if (map is Map) {
        return map[key]?.toString() ?? '';
      }
    } catch (_) {
      // Safe fallback.
    }

    return '';
  }

  int _readItemInt(
    dynamic source,
    String key,
  ) {
    return int.tryParse(
          _readItemString(source, key),
        ) ??
        0;
  }

  double _readItemDouble(
    dynamic source,
    String key, {
    String? fallbackKey,
  }) {
    String value =
        _readItemString(source, key);

    if (value.isEmpty &&
        fallbackKey != null) {
      value =
          _readItemString(
        source,
        fallbackKey,
      );
    }

    return double.tryParse(value) ?? 0;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  static const Color yellow = Color(0xFFFFD60A);

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value.trim().isEmpty
                ? 'â€”'
                : value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color:
                  highlight ? yellow : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
