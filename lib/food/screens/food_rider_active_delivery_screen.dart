// lib/food/screens/food_rider_active_delivery_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Food Rider Active Delivery Screen
//
// Connected with:
// - FoodDeliveryRiderModel
// - FoodDeliveryRiderService
// - FoodOrderModel
//
// Real features:
// - Live rider and order Firestore streams
// - Restaurant pickup and customer delivery details
// - Order items and payment summary
// - Confirm pickup
// - Start delivery
// - OTP verification
// - Complete delivery
// - Rider wallet / commission update through service
// - Restaurant commission settlement through service
// - Customer / restaurant / rider notifications through service
//
// Temporarily bypassed:
// - Paid map rendering
// - Real navigation SDK
// - Direct phone calling
// - SOS (handled separately in another module/chat)
// =============================================================

import 'package:flutter/material.dart';

import '../models/food_order_model.dart';
import '../rider/models/food_delivery_rider_model.dart';
import '../rider/services/food_delivery_rider_service.dart';

class FoodRiderActiveDeliveryScreen
    extends StatefulWidget {
  const FoodRiderActiveDeliveryScreen({
    required this.rider,
    required this.order,
    super.key,
  });

  final FoodDeliveryRiderModel rider;
  final FoodOrderModel order;

  @override
  State<FoodRiderActiveDeliveryScreen>
      createState() =>
          _FoodRiderActiveDeliveryScreenState();
}

class _FoodRiderActiveDeliveryScreenState
    extends State<FoodRiderActiveDeliveryScreen> {
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

  bool _isTerminalStatus(
    FoodOrderStatus status,
  ) {
    return status == FoodOrderStatus.delivered ||
        status == FoodOrderStatus.cancelled;
  }

  bool _isCashOrder(
    FoodOrderModel order,
  ) {
    return order.paymentMethod ==
        FoodPaymentMethod.cash;
  }

  double _riderGrossEarning(
    FoodOrderModel order,
  ) {
    final double deliveryFee =
        order.deliveryFee < 0
            ? 0
            : order.deliveryFee;

    if (deliveryFee > 0) {
      return deliveryFee;
    }

    return 80;
  }

  double _estimatedCommission({
    required FoodOrderModel order,
    required FoodDeliveryRiderModel rider,
  }) {
    final double rate =
        rider.commissionPercentage
            .clamp(0, 100)
            .toDouble();

    return _riderGrossEarning(order) *
        (rate / 100);
  }

  double _estimatedNetEarning({
    required FoodOrderModel order,
    required FoodDeliveryRiderModel rider,
  }) {
    final double gross =
        _riderGrossEarning(order);

    final double commission =
        _estimatedCommission(
      order: order,
      rider: rider,
    );

    final double result =
        gross - commission;

    return result < 0 ? 0 : result;
  }

  Future<void> _runAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
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
    FoodOrderModel order,
    FoodDeliveryRiderModel rider,
  ) async {
    final bool? confirmed =
        await _showConfirmationDialog(
      title: 'Confirm Pickup',
      message:
          'Confirm that you have received the complete food order from the restaurant.',
      confirmText: 'Confirm Pickup',
    );

    if (confirmed != true) {
      return;
    }

    await _runAction(
      action: () =>
          _riderService.confirmPickup(
        riderId: rider.riderId,
        orderId: order.orderId,
      ),
      successMessage:
          'Food pickup confirmed.',
    );
  }

  Future<void> _startDelivery(
    FoodOrderModel order,
    FoodDeliveryRiderModel rider,
  ) async {
    final bool? confirmed =
        await _showConfirmationDialog(
      title: 'Start Delivery',
      message:
          'Start travelling toward the customer delivery address?',
      confirmText: 'Start Delivery',
    );

    if (confirmed != true) {
      return;
    }

    await _runAction(
      action: () =>
          _riderService.startDelivery(
        riderId: rider.riderId,
        orderId: order.orderId,
      ),
      successMessage:
          'Delivery started.',
    );
  }

  Future<void> _completeDelivery(
    FoodOrderModel order,
    FoodDeliveryRiderModel rider,
  ) async {
    final TextEditingController otpController =
        TextEditingController();

    final String? enteredOtp =
        await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Verify Delivery OTP',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Ask the customer for the 4-digit OTP. Complete delivery only after handing over the food.',
                style: TextStyle(
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: otpController,
                autofocus: true,
                maxLength: 4,
                keyboardType:
                    TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  labelText: 'Customer OTP',
                  counterText: '',
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
                final String value =
                    otpController.text.trim();

                if (value.length != 4) {
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
              child: const Text(
                'Verify & Complete',
              ),
            ),
          ],
        );
      },
    );

    otpController.dispose();

    if (enteredOtp == null ||
        enteredOtp.trim().isEmpty) {
      return;
    }

    final double grossEarning =
        _riderGrossEarning(order);

    await _runAction(
      action: () =>
          _riderService.completeDelivery(
        riderId: rider.riderId,
        orderId: order.orderId,
        enteredOtp: enteredOtp.trim(),
        expectedOtp: order.customerOtp,
        riderEarning: grossEarning,
        cashOrder: _isCashOrder(order),
      ),
      successMessage:
          'Delivery completed successfully.',
    );
  }

  Future<void> _cancelAssignedDelivery(
    FoodOrderModel order,
    FoodDeliveryRiderModel rider,
  ) async {
    final TextEditingController controller =
        TextEditingController();

    final String? reason =
        await showDialog<String>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Cancel Assigned Delivery',
          ),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText:
                  'Explain why you cannot complete this delivery',
              border: OutlineInputBorder(),
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
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                'Cancel Delivery',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason == null ||
        reason.trim().isEmpty) {
      return;
    }

    await _runAction(
      action: () =>
          _riderService.cancelAssignedDelivery(
        riderId: rider.riderId,
        orderId: order.orderId,
        reason: reason.trim(),
      ),
      successMessage:
          'Delivery returned to available orders.',
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(title),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  void _showContactBypass(
    String role,
  ) {
    _showMessage(
      '$role calling will be connected when real contact integration is enabled.',
    );
  }

  void _showNavigationBypass(
    String destination,
  ) {
    _showMessage(
      'Navigation to $destination will use the real map route after billing is enabled.',
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
          if (riderSnapshot.hasError) {
            return _buildErrorState(
              'Unable to load rider account.',
            );
          }

          final FoodDeliveryRiderModel rider =
              riderSnapshot.data ??
                  initialRider;

          return StreamBuilder<FoodOrderModel?>(
            stream: _riderService
                .getOrderById(initialOrder.orderId)
                .asStream()
                .asyncExpand(
                  (FoodOrderModel? firstOrder) {
                    return Stream<FoodOrderModel?>.periodic(
                      const Duration(seconds: 2),
                    ).asyncMap(
                      (_) => _riderService.getOrderById(
                        initialOrder.orderId,
                      ),
                    ).startWith(firstOrder);
                  },
                ),
            initialData: initialOrder,
            builder: (
              BuildContext context,
              AsyncSnapshot<FoodOrderModel?>
                  orderSnapshot,
            ) {
              if (orderSnapshot.connectionState ==
                      ConnectionState.waiting &&
                  !orderSnapshot.hasData) {
                return const Center(
                  child:
                      CircularProgressIndicator(
                    color: yellow,
                  ),
                );
              }

              if (orderSnapshot.hasError) {
                return _buildErrorState(
                  'Unable to load active order.',
                );
              }

              final FoodOrderModel? order =
                  orderSnapshot.data;

              if (order == null) {
                return _buildEmptyState();
              }

              return _buildContent(
                order: order,
                rider: rider,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent({
    required FoodOrderModel order,
    required FoodDeliveryRiderModel rider,
  }) {
    final bool assignedToRider =
        order.riderId == rider.riderId;

    if (!assignedToRider &&
        !_isTerminalStatus(order.status)) {
      return _buildErrorState(
        'This order is no longer assigned to this rider.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        30,
      ),
      children: <Widget>[
        _buildStatusCard(order),
        const SizedBox(height: 14),
        _buildMapBypassCard(order),
        const SizedBox(height: 14),
        _buildRestaurantCard(order),
        const SizedBox(height: 14),
        _buildCustomerCard(order),
        const SizedBox(height: 14),
        _buildItemsCard(order),
        const SizedBox(height: 14),
        _buildPaymentCard(
          order: order,
          rider: rider,
        ),
        const SizedBox(height: 14),
        _buildTimeline(order.status),
        const SizedBox(height: 18),
        _buildPrimaryActions(
          order: order,
          rider: rider,
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    FoodOrderModel order,
  ) {
    final Color color =
        _statusColor(order.status);

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(21),
        border: Border.all(
          color: color.withValues(alpha: 0.65),
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 29,
            backgroundColor:
                color.withValues(alpha: 0.15),
            child: Icon(
              _statusIcon(order.status),
              color: color,
              size: 31,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Order #${_shortId(order.orderId)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusTitle(order.status),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusDescription(order.status),
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

  Widget _buildMapBypassCard(
    FoodOrderModel order,
  ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.map_outlined,
                color: yellow,
              ),
              SizedBox(width: 9),
              Text(
                'Delivery Route',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            height: 155,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF262626),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.delivery_dining,
                  color: yellow,
                  size: 47,
                ),
                const SizedBox(height: 9),
                Text(
                  order.status ==
                          FoodOrderStatus.readyForPickup
                      ? 'Navigate to restaurant'
                      : order.status ==
                                  FoodOrderStatus.pickedUp ||
                              order.status ==
                                  FoodOrderStatus.onTheWay
                          ? 'Navigate to customer'
                          : 'Delivery route',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Real map rendering is bypassed until billing is enabled.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(
    FoodOrderModel order,
  ) {
    return _sectionCard(
      title: 'Restaurant Pickup',
      icon: Icons.storefront_outlined,
      children: <Widget>[
        _InfoRow(
          label: 'Restaurant',
          value: order.restaurantName,
        ),
        const Divider(
          color: Colors.white12,
        ),
        _InfoRow(
          label: 'Restaurant ID',
          value: order.restaurantId,
        ),
        const SizedBox(height: 13),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showContactBypass(
                  'Restaurant',
                ),
                icon:
                    const Icon(Icons.call_outlined),
                label: const Text('Call'),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor: yellow,
                  side: const BorderSide(
                    color: yellow,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showNavigationBypass(
                  'restaurant',
                ),
                icon:
                    const Icon(Icons.navigation),
                label:
                    const Text('Navigate'),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: yellow,
                  foregroundColor:
                      Colors.black,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerCard(
    FoodOrderModel order,
  ) {
    return _sectionCard(
      title: 'Customer Delivery',
      icon: Icons.person_pin_circle_outlined,
      children: <Widget>[
        _InfoRow(
          label: 'Customer ID',
          value: order.customerId,
        ),
        const Divider(
          color: Colors.white12,
        ),
        const Text(
          'Delivery address',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          order.deliveryAddress.fullAddress,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showContactBypass(
                  'Customer',
                ),
                icon:
                    const Icon(Icons.call_outlined),
                label: const Text('Call'),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor: yellow,
                  side: const BorderSide(
                    color: yellow,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showNavigationBypass(
                  'customer',
                ),
                icon:
                    const Icon(Icons.navigation),
                label:
                    const Text('Navigate'),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: yellow,
                  foregroundColor:
                      Colors.black,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsCard(
    FoodOrderModel order,
  ) {
    return _sectionCard(
      title: 'Order Items',
      icon: Icons.fastfood_outlined,
      children: <Widget>[
        ...order.items.map(
          (dynamic item) {
            final Map<String, dynamic> map =
                _itemMap(item);

            final String name =
                _stringValue(
              map['name'] ??
                  map['itemName'],
            );

            final int quantity =
                _intValue(map['quantity']);

            final double total =
                _doubleValue(
              map['totalPrice'] ??
                  map['total'],
            );

            final String instructions =
                _stringValue(
              map['specialInstructions'],
            );

            return Container(
              margin:
                  const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color:
                    const Color(0xFF252525),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          name.isEmpty
                              ? 'Food item'
                              : name,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'x${quantity <= 0 ? 1 : quantity}',
                        style:
                            const TextStyle(
                          color: yellow,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rs. ${total.toStringAsFixed(0)}',
                    style:
                        const TextStyle(
                      color: yellow,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  if (instructions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      'Note: $instructions',
                      style:
                          const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentCard({
    required FoodOrderModel order,
    required FoodDeliveryRiderModel rider,
  }) {
    final double gross =
        _riderGrossEarning(order);

    final double commission =
        _estimatedCommission(
      order: order,
      rider: rider,
    );

    final double net =
        _estimatedNetEarning(
      order: order,
      rider: rider,
    );

    return _sectionCard(
      title: 'Payment & Earnings',
      icon: Icons.payments_outlined,
      children: <Widget>[
        _InfoRow(
          label: 'Order total',
          value:
              'Rs. ${order.grandTotal.toStringAsFixed(0)}',
        ),
        const Divider(
          color: Colors.white12,
        ),
        _InfoRow(
          label: 'Payment method',
          value: order.paymentMethod.name,
        ),
        const Divider(
          color: Colors.white12,
        ),
        _InfoRow(
          label: 'Delivery earning',
          value:
              'Rs. ${gross.toStringAsFixed(0)}',
        ),
        const Divider(
          color: Colors.white12,
        ),
        _InfoRow(
          label:
              'Admin commission (${rider.commissionPercentage.toStringAsFixed(1)}%)',
          value:
              '- Rs. ${commission.toStringAsFixed(0)}',
        ),
        const Divider(
          color: Colors.white12,
        ),
        _InfoRow(
          label: 'Estimated net earning',
          value:
              'Rs. ${net.toStringAsFixed(0)}',
          highlight: true,
        ),
        const SizedBox(height: 10),
        Text(
          _isCashOrder(order)
              ? 'Cash order: commission will first be deducted automatically from your existing wallet. Any unpaid amount will remain outstanding.'
              : 'Digital order: admin commission will be retained automatically and your net earning will be credited to your wallet.',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(
    FoodOrderStatus currentStatus,
  ) {
    const List<FoodOrderStatus> flow =
        <FoodOrderStatus>[
      FoodOrderStatus.readyForPickup,
      FoodOrderStatus.pickedUp,
      FoodOrderStatus.onTheWay,
      FoodOrderStatus.delivered,
    ];

    final int currentIndex =
        flow.indexOf(currentStatus);

    return _sectionCard(
      title: 'Delivery Progress',
      icon: Icons.timeline,
      children: <Widget>[
        ...List<Widget>.generate(
          flow.length,
          (int index) {
            final FoodOrderStatus status =
                flow[index];

            final bool completed =
                currentStatus ==
                        FoodOrderStatus.delivered ||
                    (currentIndex >= 0 &&
                        index <= currentIndex);

            return _TimelineItem(
              title: _statusTitle(status),
              completed: completed,
              isLast:
                  index == flow.length - 1,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrimaryActions({
    required FoodOrderModel order,
    required FoodDeliveryRiderModel rider,
  }) {
    if (order.status ==
        FoodOrderStatus.delivered) {
      return _buildCompletedCard(
        title: 'Delivery Completed',
        message:
            'The order, earnings and commission settlement have been recorded.',
        color: Colors.greenAccent,
        icon: Icons.task_alt,
      );
    }

    if (order.status ==
        FoodOrderStatus.cancelled) {
      return _buildCompletedCard(
        title: 'Order Cancelled',
        message:
            'This order is no longer active.',
        color: Colors.redAccent,
        icon: Icons.cancel_outlined,
      );
    }

    VoidCallback? primaryAction;
    String primaryText =
        'Waiting for next step';
    IconData primaryIcon =
        Icons.hourglass_top;

    if (order.status ==
        FoodOrderStatus.readyForPickup) {
      primaryAction = () =>
          _confirmPickup(order, rider);
      primaryText = 'Confirm Food Pickup';
      primaryIcon =
          Icons.shopping_bag_outlined;
    } else if (order.status ==
        FoodOrderStatus.pickedUp) {
      primaryAction = () =>
          _startDelivery(order, rider);
      primaryText = 'Start Delivery';
      primaryIcon = Icons.route;
    } else if (order.status ==
        FoodOrderStatus.onTheWay) {
      primaryAction = () =>
          _completeDelivery(order, rider);
      primaryText =
          'Verify OTP & Complete';
      primaryIcon = Icons.verified_outlined;
    }

    return Column(
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isUpdating
                ? null
                : primaryAction,
            icon: _isUpdating
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Icon(primaryIcon),
            label: Text(
              primaryText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            style:
                ElevatedButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: Colors.black,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        if (order.status ==
                FoodOrderStatus.readyForPickup ||
            order.status ==
                FoodOrderStatus.pickedUp) ...<Widget>[
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _isUpdating
                  ? null
                  : () =>
                      _cancelAssignedDelivery(
                        order,
                        rider,
                      ),
              icon: const Icon(
                Icons.cancel_outlined,
              ),
              label: const Text(
                'Cannot Complete Delivery',
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
  }

  Widget _buildCompletedCard({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius:
            BorderRadius.circular(19),
        border: Border.all(
          color: color.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            color: color,
            size: 50,
          ),
          const SizedBox(height: 11),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context),
            style:
                ElevatedButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: Colors.black,
            ),
            child:
                const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(20),
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
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildErrorState(
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.cloud_off,
              color: Colors.redAccent,
              size: 72,
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load delivery',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 17),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor:
                    Colors.black,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.delivery_dining,
              color: yellow,
              size: 74,
            ),
            SizedBox(height: 15),
            Text(
              'Active order not found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'The assigned food delivery is no longer available.',
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

  String _shortId(String value) {
    if (value.length <= 8) {
      return value;
    }

    return value.substring(0, 8);
  }

  String _statusTitle(
    FoodOrderStatus status,
  ) {
    switch (status) {
      case FoodOrderStatus.pending:
        return 'Waiting for Restaurant';
      case FoodOrderStatus.accepted:
        return 'Restaurant Accepted';
      case FoodOrderStatus.preparing:
        return 'Food is Preparing';
      case FoodOrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case FoodOrderStatus.pickedUp:
        return 'Food Picked Up';
      case FoodOrderStatus.onTheWay:
        return 'On the Way';
      case FoodOrderStatus.delivered:
        return 'Delivery Completed';
      case FoodOrderStatus.cancelled:
        return 'Order Cancelled';
    }
  }

  String _statusDescription(
    FoodOrderStatus status,
  ) {
    switch (status) {
      case FoodOrderStatus.pending:
        return 'The restaurant has not accepted this order yet.';
      case FoodOrderStatus.accepted:
        return 'The restaurant has accepted the order.';
      case FoodOrderStatus.preparing:
        return 'The restaurant is preparing the food.';
      case FoodOrderStatus.readyForPickup:
        return 'Collect the complete order from the restaurant.';
      case FoodOrderStatus.pickedUp:
        return 'Start travelling toward the customer.';
      case FoodOrderStatus.onTheWay:
        return 'Deliver the food and verify the customer OTP.';
      case FoodOrderStatus.delivered:
        return 'Delivery and commission settlement are complete.';
      case FoodOrderStatus.cancelled:
        return 'This order has been cancelled.';
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

  Map<String, dynamic> _itemMap(
    dynamic item,
  ) {
    if (item is Map) {
      return Map<String, dynamic>.from(
        item,
      );
    }

    try {
      final dynamic map = item.toMap();

      if (map is Map) {
        return Map<String, dynamic>.from(
          map,
        );
      }
    } catch (_) {
      // Typed model fallback.
    }

    return <String, dynamic>{};
  }

  String _stringValue(
    dynamic value,
  ) {
    return value?.toString().trim() ?? '';
  }

  int _intValue(
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

  double _doubleValue(
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
                ? '—'
                : value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: highlight
                  ? yellow
                  : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.completed,
    required this.isLast,
  });

  static const Color yellow = Color(0xFFFFD60A);

  final String title;
  final bool completed;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed
                    ? yellow
                    : const Color(0xFF333333),
              ),
              child: Icon(
                completed
                    ? Icons.check
                    : Icons.circle,
                size: completed ? 16 : 7,
                color: completed
                    ? Colors.black
                    : Colors.grey,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 31,
                color: completed
                    ? yellow
                    : Colors.white12,
              ),
          ],
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(top: 3),
            child: Text(
              title,
              style: TextStyle(
                color: completed
                    ? Colors.white
                    : Colors.grey,
                fontWeight: completed
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Small Stream helper so the screen can show the initial order immediately
// and then refresh it from Firestore every two seconds without another
// dependency.
extension _StartWithExtension<T> on Stream<T> {
  Stream<T> startWith(T value) async* {
    yield value;
    yield* this;
  }
}
