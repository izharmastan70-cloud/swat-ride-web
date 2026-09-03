// lib/food/restaurant_partner/screens/restaurant_order_details_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Partner Order Details Screen
//
// Connected with:
// - FoodOrderModel
// - FoodOrderService
//
// Features:
// - Live order updates
// - Customer and address details
// - Ordered items and price summary
// - Accept / reject
// - Start preparing
// - Mark ready for pickup
// - Rider assignment visibility
//
// SOS, ratings and reviews are intentionally not handled here.
// =============================================================

import 'package:flutter/material.dart';

import '../../models/cart_item_model.dart';
import '../../models/food_order_model.dart';
import '../../services/food_order_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../safety/models/safety_models.dart';
import '../../../safety/screens/safety_center_screen.dart';

class RestaurantOrderDetailsScreen extends StatefulWidget {
  const RestaurantOrderDetailsScreen({
    required this.order,
    super.key,
  });

  final FoodOrderModel order;

  @override
  State<RestaurantOrderDetailsScreen> createState() =>
      _RestaurantOrderDetailsScreenState();
}

class _RestaurantOrderDetailsScreenState
    extends State<RestaurantOrderDetailsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodOrderService _orderService = FoodOrderService();

  bool _isUpdating = false;

  FoodOrderModel get initialOrder => widget.order;

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
    } on FoodOrderServiceException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(
        'Unable to update food order: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _acceptOrder(
    FoodOrderModel order,
  ) async {
    final TextEditingController controller =
        TextEditingController(text: '25');

    final int? minutes = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Accept Food Order'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Preparation time in minutes',
              border: OutlineInputBorder(),
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
                final int? value =
                    int.tryParse(controller.text.trim());

                if (value == null || value < 1) {
                  return;
                }

                Navigator.pop(dialogContext, value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (minutes == null) {
      return;
    }

    await _runAction(
      action: () => _orderService.acceptOrder(
        orderId: order.orderId,
        estimatedPreparationMinutes: minutes,
      ),
      successMessage: 'Food order accepted.',
    );
  }

  Future<void> _rejectOrder(
    FoodOrderModel order,
  ) async {
    final TextEditingController controller =
        TextEditingController();

    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Reject Food Order'),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Rejection reason',
              border: OutlineInputBorder(),
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

                Navigator.pop(dialogContext, value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
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
      action: () => _orderService.rejectOrder(
        orderId: order.orderId,
        reason: reason,
      ),
      successMessage: 'Food order rejected.',
    );
  }


  void _openUniversalSafetyCenter(
    FoodOrderModel order,
  ) {
    final String currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    final SafetyLocation destination =
        SafetyLocation(
      latitude: order.deliveryAddress.latitude,
      longitude: order.deliveryAddress.longitude,
      address: order.deliveryAddress.fullAddress,
      placeName: 'Customer delivery',
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return SafetyCenterScreen(
            contextData: SafetyContext(
              serviceType:
                  SafetyServiceType.restaurantPartner,
              referenceId: order.orderId,
              initiatedByUserId: currentUserId,
              initiatedByRole:
                  SafetyUserRole.restaurantOwner,
              sourcePage:
                  SafetySourcePage.orderTracking,
              referenceStatus: order.status.name,
              destinationLocation: destination,
              serviceTitle:
                  'Restaurant Partner Safety',
              serviceSubtitle:
                  order.restaurantName.trim().isEmpty
                      ? 'Food order safety'
                      : order.restaurantName,
              paymentMethod:
                  order.paymentMethod.name,
              metadata: <String, dynamic>{
                'orderId': order.orderId,
                'restaurantId':
                    order.restaurantId,
                'restaurantName':
                    order.restaurantName,
                'customerId':
                    order.customerId,
                'riderId':
                    order.riderId,
                'grandTotal':
                    order.grandTotal,
                'deliveryFee':
                    order.deliveryFee,

                // Partner ID is not guessed here.
                // Customer OTP and verification secrets
                // are intentionally excluded.
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
          actions: <Widget>[
            IconButton(
              tooltip: 'Safety & SOS',
              onPressed: () {
                _openUniversalSafetyCenter(
                  initialOrder,
                );
              },
              icon: const Icon(
                Icons.shield_outlined,
                color: Colors.redAccent,
              ),
            ),
          ],
        backgroundColor: background,
        title: const Text(
          'Food Order Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<FoodOrderModel?>(
        stream: _orderService.watchOrderById(
          initialOrder.orderId,
        ),
        initialData: initialOrder,
        builder: (
          BuildContext context,
          AsyncSnapshot<FoodOrderModel?> snapshot,
        ) {
          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: yellow,
              ),
            );
          }

          if (snapshot.hasError) {
            return _messageState(
              icon: Icons.cloud_off,
              title: 'Unable to load order',
              message: snapshot.error.toString(),
            );
          }

          final FoodOrderModel? order = snapshot.data;

          if (order == null) {
            return _messageState(
              icon: Icons.receipt_long_outlined,
              title: 'Order not found',
              message:
                  'This food order is no longer available.',
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
              const SizedBox(height: 16),
              _buildCustomerCard(order),
              const SizedBox(height: 16),
              _buildAddressCard(order),
              const SizedBox(height: 16),
              _buildItemsCard(order),
              const SizedBox(height: 16),
              _buildPaymentCard(order),
              const SizedBox(height: 16),
              _buildRiderCard(order),
              const SizedBox(height: 20),
              _buildActions(order),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(
    FoodOrderModel order,
  ) {
    final Color color = _statusColor(order.status);

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 27,
            backgroundColor:
                color.withValues(alpha: 0.16),
            child: Icon(
              _statusIcon(order.status),
              color: color,
              size: 29,
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
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _statusText(order.status),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _dateText(order.createdAt),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(
    FoodOrderModel order,
  ) {
    return _sectionCard(
      title: 'Customer',
      icon: Icons.person_outline,
      children: <Widget>[
        _InfoRow(
          label: 'Customer ID',
          value: order.customerId,
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Receiver',
          value: order.deliveryAddress.receiverName,
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Phone',
          value: order.deliveryAddress.receiverPhone,
        ),
      ],
    );
  }

  Widget _buildAddressCard(
    FoodOrderModel order,
  ) {
    return _sectionCard(
      title: 'Delivery Address',
      icon: Icons.location_on_outlined,
      children: <Widget>[
        Text(
          order.deliveryAddress.fullAddress,
          style: const TextStyle(
            height: 1.45,
          ),
        ),
        if (order.deliveryAddress
            .deliveryInstructions
            .trim()
            .isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              'Instructions: '
              '${order.deliveryAddress.deliveryInstructions}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItemsCard(
    FoodOrderModel order,
  ) {
    return _sectionCard(
      title: 'Ordered Items',
      icon: Icons.fastfood_outlined,
      children: <Widget>[
        ...List<Widget>.generate(
          order.items.length,
          (int index) {
            final CartItemModel item =
                order.items[index];

            return Column(
              children: <Widget>[
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: yellow,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.menuItemName,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          if (item.selectedOptionsText
                              .trim()
                              .isNotEmpty) ...<Widget>[
                            const SizedBox(height: 3),
                            Text(
                              item.selectedOptionsText,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          if (item.specialInstructions
                              .trim()
                              .isNotEmpty) ...<Widget>[
                            const SizedBox(height: 3),
                            Text(
                              'Note: '
                              '${item.specialInstructions}',
                              style: const TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: yellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (index != order.items.length - 1)
                  const Divider(
                    color: Colors.white12,
                    height: 24,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaymentCard(
    FoodOrderModel order,
  ) {
    return _sectionCard(
      title: 'Payment Summary',
      icon: Icons.payments_outlined,
      children: <Widget>[
        _InfoRow(
          label: 'Items subtotal',
          value:
              'Rs. ${order.itemsTotal.toStringAsFixed(0)}',
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Delivery fee',
          value:
              'Rs. ${order.deliveryFee.toStringAsFixed(0)}',
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Service fee',
          value:
              'Rs. ${order.serviceFee.toStringAsFixed(0)}',
        ),
        if (order.discount > 0) ...<Widget>[
          const Divider(color: Colors.white12),
          _InfoRow(
            label: 'Discount',
            value:
                '- Rs. ${order.discount.toStringAsFixed(0)}',
          ),
        ],
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Payment method',
          value: _paymentText(order.paymentMethod),
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Grand total',
          value:
              'Rs. ${order.grandTotal.toStringAsFixed(0)}',
          highlight: true,
        ),
      ],
    );
  }

  Widget _buildRiderCard(
    FoodOrderModel order,
  ) {
    return _sectionCard(
      title: 'Delivery Rider',
      icon: Icons.delivery_dining,
      children: <Widget>[
        _InfoRow(
          label: 'Rider status',
          value: order.riderId.trim().isEmpty
              ? 'Waiting for rider assignment'
              : 'Rider assigned',
          highlight:
              order.riderId.trim().isNotEmpty,
        ),
        if (order.riderId.trim().isNotEmpty) ...<Widget>[
          const Divider(color: Colors.white12),
          _InfoRow(
            label: 'Rider ID',
            value: order.riderId,
          ),
        ],
      ],
    );
  }

  Widget _buildActions(
    FoodOrderModel order,
  ) {
    if (order.status == FoodOrderStatus.delivered ||
        order.status == FoodOrderStatus.cancelled ||
        order.status == FoodOrderStatus.readyForPickup ||
        order.status == FoodOrderStatus.pickedUp ||
        order.status == FoodOrderStatus.onTheWay) {
      return const SizedBox.shrink();
    }

    if (order.status == FoodOrderStatus.pending) {
      return Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isUpdating
                  ? null
                  : () => _rejectOrder(order),
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(
                  color: Colors.redAccent,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isUpdating
                  ? null
                  : () => _acceptOrder(order),
              icon: const Icon(Icons.check),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (order.status == FoodOrderStatus.accepted) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _isUpdating
              ? null
              : () => _runAction(
                    action: () =>
                        _orderService.startPreparing(
                      order.orderId,
                    ),
                    successMessage:
                        'Food preparation started.',
                  ),
          icon: const Icon(Icons.soup_kitchen_outlined),
          label: const Text('Start Preparing'),
          style: ElevatedButton.styleFrom(
            backgroundColor: yellow,
            foregroundColor: Colors.black,
          ),
        ),
      );
    }

    if (order.status == FoodOrderStatus.preparing) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _isUpdating
              ? null
              : () => _runAction(
                    action: () =>
                        _orderService.markReadyForPickup(
                      order.orderId,
                    ),
                    successMessage:
                        'Order marked ready for pickup.',
                  ),
          icon: const Icon(Icons.shopping_bag_outlined),
          label: const Text('Mark Ready for Pickup'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            foregroundColor: Colors.black,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
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
              Icon(icon, color: yellow),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              color: yellow,
              size: 68,
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _shortId(String value) {
    return value.length <= 8
        ? value
        : value.substring(0, 8);
  }

  static String _dateText(DateTime value) {
    final String day =
        value.day.toString().padLeft(2, '0');
    final String month =
        value.month.toString().padLeft(2, '0');

    return '$day-$month-${value.year}';
  }

  static String _paymentText(
    FoodPaymentMethod method,
  ) {
    switch (method) {
      case FoodPaymentMethod.cash:
        return 'Cash on Delivery';
      case FoodPaymentMethod.wallet:
        return 'SWAT RIDE Wallet';
      case FoodPaymentMethod.jazzCash:
        return 'JazzCash';
      case FoodPaymentMethod.easypaisa:
        return 'Easypaisa';
      case FoodPaymentMethod.card:
        return 'Card';
    }
  }

  static String _statusText(
    FoodOrderStatus status,
  ) {
    switch (status) {
      case FoodOrderStatus.pending:
        return 'New Order';
      case FoodOrderStatus.accepted:
        return 'Accepted';
      case FoodOrderStatus.preparing:
        return 'Preparing';
      case FoodOrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case FoodOrderStatus.pickedUp:
        return 'Picked Up';
      case FoodOrderStatus.onTheWay:
        return 'On The Way';
      case FoodOrderStatus.delivered:
        return 'Delivered';
      case FoodOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static Color _statusColor(
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

  static IconData _statusIcon(
    FoodOrderStatus status,
  ) {
    switch (status) {
      case FoodOrderStatus.pending:
        return Icons.fiber_new;
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
            value.trim().isEmpty ? 'â€”' : value,
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
