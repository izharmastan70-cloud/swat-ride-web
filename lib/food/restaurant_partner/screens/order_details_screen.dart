// lib/food/restaurant_partner/screens/order_details_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Partner Order Details Screen
//
// Connected with:
// - FoodOrderModel
// - FoodOrderService
//
// Real features:
// - Live Firestore order updates
// - Complete order, customer, rider and payment details
// - Ordered items and special instructions
// - Restaurant workflow actions
// - Accept / Reject / Start Preparing / Ready for Pickup
// - Rider assignment visibility
// - Order timeline
// - Loading / error / empty states
//
// Temporarily bypassed:
// - Direct phone calling
// - Printed invoice generation
// - Paid map rendering
// - SOS (handled separately)
// =============================================================

import 'package:flutter/material.dart';

import '../../models/food_order_model.dart';
import '../../services/food_order_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({
    required this.order,
    super.key,
  });

  final FoodOrderModel order;

  @override
  State<OrderDetailsScreen> createState() =>
      _OrderDetailsScreenState();
}

class _OrderDetailsScreenState
    extends State<OrderDetailsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodOrderService _orderService =
      FoodOrderService();

  bool _isUpdating = false;

  FoodOrderModel get initialOrder =>
      widget.order;

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
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

    final int? minutes =
        await showDialog<int>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Accept Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Enter the estimated preparation time for this order.',
                style: TextStyle(
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType:
                    TextInputType.number,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Preparation time',
                  suffixText: 'minutes',
                  border:
                      OutlineInputBorder(),
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
                final int? value =
                    int.tryParse(
                  controller.text.trim(),
                );

                if (value == null ||
                    value < 1 ||
                    value > 240) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              style:
                  ElevatedButton.styleFrom(
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
      successMessage:
          'Order accepted successfully.',
    );
  }

  Future<void> _rejectOrder(
    FoodOrderModel order,
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
          title: const Text('Reject Order'),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration:
                const InputDecoration(
              labelText: 'Rejection reason',
              hintText:
                  'For example: item unavailable',
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
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child:
                  const Text('Reject Order'),
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
      successMessage: 'Order rejected.',
    );
  }

  Future<void> _startPreparing(
    FoodOrderModel order,
  ) async {
    await _runAction(
      action: () =>
          _orderService.startPreparing(
        order.orderId,
      ),
      successMessage:
          'Food preparation started.',
    );
  }

  Future<void> _markReady(
    FoodOrderModel order,
  ) async {
    await _runAction(
      action: () =>
          _orderService.markReadyForPickup(
        order.orderId,
      ),
      successMessage:
          'Order marked ready for pickup.',
    );
  }

  void _showContactBypass(
    String role,
  ) {
    _showMessage(
      '$role calling will be connected when contact integration is enabled.',
    );
  }

  void _showInvoiceBypass() {
    _showMessage(
      'Invoice printing/export will be connected in the final integration phase.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: Text(
          'Order #${_shortId(initialOrder.orderId)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Invoice',
            onPressed: _showInvoiceBypass,
            icon: const Icon(
              Icons.receipt_long_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<FoodOrderModel?>(
          stream: _orderService.watchOrderById(
            initialOrder.orderId,
          ),
          initialData: initialOrder,
          builder: (
            BuildContext context,
            AsyncSnapshot<FoodOrderModel?>
                snapshot,
          ) {
            if (snapshot.connectionState ==
                    ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child:
                    CircularProgressIndicator(
                  color: yellow,
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState();
            }

            final FoodOrderModel? order =
                snapshot.data;

            if (order == null) {
              return _buildEmptyState();
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                30,
              ),
              children: <Widget>[
                _buildHeader(order),
                const SizedBox(height: 14),
                _buildOrderInfo(order),
                const SizedBox(height: 14),
                _buildCustomerInfo(order),
                const SizedBox(height: 14),
                _buildRiderInfo(order),
                const SizedBox(height: 14),
                _buildItems(order),
                const SizedBox(height: 14),
                _buildPaymentSummary(order),
                const SizedBox(height: 14),
                _buildTimeline(order.status),
                const SizedBox(height: 18),
                _buildActions(order),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
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
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusText(order.status),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateTimeText(order.createdAt),
                  style: const TextStyle(
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

  Widget _buildOrderInfo(
    FoodOrderModel order,
  ) {
    return _sectionCard(
      title: 'Order Information',
      icon: Icons.info_outline,
      children: <Widget>[
        _InfoRow(
          label: 'Order ID',
          value: order.orderId,
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Restaurant',
          value: order.restaurantName,
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Restaurant ID',
          value: order.restaurantId,
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Created',
          value:
              _dateTimeText(order.createdAt),
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Updated',
          value:
              _dateTimeText(order.updatedAt),
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Payment method',
          value: order.paymentMethod.name,
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(
    FoodOrderModel order,
  ) {
    return _sectionCard(
      title: 'Customer & Delivery',
      icon: Icons.person_pin_circle_outlined,
      children: <Widget>[
        _InfoRow(
          label: 'Customer ID',
          value: order.customerId,
        ),
        const Divider(color: Colors.white12),
        const Text(
          'Delivery address',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          order.deliveryAddress.fullAddress,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 13),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () =>
                _showContactBypass(
              'Customer',
            ),
            icon: const Icon(
              Icons.call_outlined,
            ),
            label: const Text(
              'Call Customer',
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

  Widget _buildRiderInfo(
    FoodOrderModel order,
  ) {
    final bool hasRider =
        order.riderId.trim().isNotEmpty;

    return _sectionCard(
      title: 'Food Rider',
      icon: Icons.delivery_dining,
      children: <Widget>[
        _InfoRow(
          label: 'Rider status',
          value: hasRider
              ? 'Assigned'
              : 'Not assigned',
        ),
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Rider ID',
          value: hasRider
              ? order.riderId
              : '—',
        ),
        if (hasRider) ...<Widget>[
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _showContactBypass(
                'Food Rider',
              ),
              icon: const Icon(
                Icons.call_outlined,
              ),
              label: const Text(
                'Call Food Rider',
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor: yellow,
                side: const BorderSide(
                  color: yellow,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItems(
    FoodOrderModel order,
  ) {
    return _sectionCard(
      title: 'Ordered Items',
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

            final double unitPrice =
                _doubleValue(
              map['unitPrice'] ??
                  map['price'],
            );

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
                  Row(
                    children: <Widget>[
                      if (unitPrice > 0)
                        Text(
                          'Rs. ${unitPrice.toStringAsFixed(0)} each',
                          style:
                              const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      const Spacer(),
                      Text(
                        'Rs. ${total.toStringAsFixed(0)}',
                        style:
                            const TextStyle(
                          color: yellow,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (instructions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 7),
                    Text(
                      'Special instructions: $instructions',
                      style:
                          const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 11,
                        height: 1.35,
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

  Widget _buildPaymentSummary(
    FoodOrderModel order,
  ) {
    return _sectionCard(
      title: 'Payment Summary',
      icon: Icons.payments_outlined,
      children: <Widget>[
        _InfoRow(
          label: 'Items total',
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
        const Divider(color: Colors.white12),
        _InfoRow(
          label: 'Discount',
          value:
              '- Rs. ${order.discount.toStringAsFixed(0)}',
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

  Widget _buildTimeline(
    FoodOrderStatus currentStatus,
  ) {
    const List<FoodOrderStatus> flow =
        <FoodOrderStatus>[
      FoodOrderStatus.pending,
      FoodOrderStatus.accepted,
      FoodOrderStatus.preparing,
      FoodOrderStatus.readyForPickup,
      FoodOrderStatus.pickedUp,
      FoodOrderStatus.onTheWay,
      FoodOrderStatus.delivered,
    ];

    if (currentStatus ==
        FoodOrderStatus.cancelled) {
      return _sectionCard(
        title: 'Order Timeline',
        icon: Icons.timeline,
        children: const <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.cancel,
                color: Colors.redAccent,
              ),
              SizedBox(width: 10),
              Text(
                'Order Cancelled',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      );
    }

    final int currentIndex =
        flow.indexOf(currentStatus);

    return _sectionCard(
      title: 'Order Timeline',
      icon: Icons.timeline,
      children: <Widget>[
        ...List<Widget>.generate(
          flow.length,
          (int index) {
            final bool completed =
                currentIndex >= 0 &&
                    index <= currentIndex;

            return _TimelineItem(
              title: _statusText(flow[index]),
              completed: completed,
              isLast:
                  index == flow.length - 1,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActions(
    FoodOrderModel order,
  ) {
    if (order.status ==
            FoodOrderStatus.delivered ||
        order.status ==
            FoodOrderStatus.cancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius:
              BorderRadius.circular(19),
        ),
        child: Text(
          order.status ==
                  FoodOrderStatus.delivered
              ? 'This order has been delivered.'
              : 'This order has been cancelled.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: order.status ==
                    FoodOrderStatus.delivered
                ? Colors.greenAccent
                : Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        if (order.status ==
            FoodOrderStatus.pending) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUpdating
                      ? null
                      : () => _rejectOrder(order),
                  icon: const Icon(
                    Icons.close,
                  ),
                  label: const Text('Reject'),
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
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUpdating
                      ? null
                      : () => _acceptOrder(order),
                  icon: const Icon(
                    Icons.check,
                  ),
                  label: const Text('Accept'),
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
        if (order.status ==
            FoodOrderStatus.accepted)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isUpdating
                  ? null
                  : () =>
                      _startPreparing(order),
              icon: const Icon(
                Icons.soup_kitchen_outlined,
              ),
              label: const Text(
                'Start Preparing',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.orangeAccent,
                foregroundColor:
                    Colors.black,
              ),
            ),
          ),
        if (order.status ==
            FoodOrderStatus.preparing)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isUpdating
                  ? null
                  : () => _markReady(order),
              icon: const Icon(
                Icons.shopping_bag_outlined,
              ),
              label: const Text(
                'Ready for Pickup',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.lightBlueAccent,
                foregroundColor:
                    Colors.black,
              ),
            ),
          ),
        if (order.status ==
                FoodOrderStatus.readyForPickup ||
            order.status ==
                FoodOrderStatus.pickedUp ||
            order.status ==
                FoodOrderStatus.onTheWay)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color:
                  Colors.lightBlueAccent
                      .withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(17),
              border: Border.all(
                color:
                    Colors.lightBlueAccent
                        .withValues(alpha: 0.55),
              ),
            ),
            child: Text(
              order.status ==
                      FoodOrderStatus.readyForPickup
                  ? 'Food is ready. Waiting for the assigned rider to collect it.'
                  : 'The rider is handling the delivery. Restaurant status changes are locked.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.lightBlueAccent,
                height: 1.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (_isUpdating) ...<Widget>[
          const SizedBox(height: 12),
          const Center(
            child: CircularProgressIndicator(
              color: yellow,
              strokeWidth: 2,
            ),
          ),
        ],
      ],
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
                  fontWeight: FontWeight.bold,
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

  Widget _buildErrorState() {
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
              'Unable to load order details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check Firestore connection and security rules.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
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
                foregroundColor: Colors.black,
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
              Icons.receipt_long_outlined,
              color: yellow,
              size: 72,
            ),
            SizedBox(height: 15),
            Text(
              'Order not found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _shortId(
    String value,
  ) {
    if (value.length <= 8) {
      return value;
    }

    return value.substring(0, 8);
  }

  static String _dateTimeText(
    DateTime value,
  ) {
    final String day =
        value.day.toString().padLeft(2, '0');

    final String month =
        value.month.toString().padLeft(2, '0');

    final String hour =
        value.hour.toString().padLeft(2, '0');

    final String minute =
        value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year} • $hour:$minute';
  }

  static String _statusText(
    FoodOrderStatus status,
  ) {
    switch (status) {
      case FoodOrderStatus.pending:
        return 'Pending';
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

  static Map<String, dynamic> _itemMap(
    dynamic item,
  ) {
    if (item is Map) {
      return Map<String, dynamic>.from(item);
    }

    try {
      final dynamic map = item.toMap();

      if (map is Map) {
        return Map<String, dynamic>.from(map);
      }
    } catch (_) {
      // Safe typed-model fallback.
    }

    return <String, dynamic>{};
  }

  static String _stringValue(
    dynamic value,
  ) {
    return value?.toString().trim() ?? '';
  }

  static int _intValue(
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

  static double _doubleValue(
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
