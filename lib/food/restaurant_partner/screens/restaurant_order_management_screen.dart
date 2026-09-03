// lib/food/restaurant_partner/screens/restaurant_order_management_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Partner Live Order Management Screen
//
// Connected with:
// - RestaurantPartnerModel
// - FoodOrderModel
// - FoodOrderService
//
// Real features:
// - Live restaurant orders from Firestore
// - Status filtering
// - Accept order
// - Reject order with reason
// - Start preparing
// - Mark ready for pickup
// - Open order details
//
// Existing non-Food modules remain untouched.
// =============================================================

import 'package:flutter/material.dart';

import '../../models/food_order_model.dart';
import '../../services/food_order_service.dart';
import '../models/restaurant_partner_model.dart';

class RestaurantOrderManagementScreen
    extends StatefulWidget {
  const RestaurantOrderManagementScreen({
    required this.partner,
    super.key,
  });

  final RestaurantPartnerModel partner;

  @override
  State<RestaurantOrderManagementScreen>
      createState() =>
          _RestaurantOrderManagementScreenState();
}

class _RestaurantOrderManagementScreenState
    extends State<RestaurantOrderManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodOrderService _orderService =
      FoodOrderService();

  FoodOrderStatus? _selectedStatus;
  bool _isUpdating = false;

  RestaurantPartnerModel get partner =>
      widget.partner;

  String get restaurantId =>
      partner.restaurantId;

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

  List<FoodOrderModel> _filterOrders(
    List<FoodOrderModel> orders,
  ) {
    if (_selectedStatus == null) {
      return orders;
    }

    return orders
        .where(
          (FoodOrderModel order) =>
              order.status == _selectedStatus,
        )
        .toList();
  }

  Future<void> _acceptOrder(
    FoodOrderModel order,
  ) async {
    final TextEditingController controller =
        TextEditingController(
      text: '25',
    );

    final int? minutes = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Accept Order'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText:
                  'Estimated preparation minutes',
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
                    int.tryParse(
                  controller.text.trim(),
                );

                if (value == null || value < 1) {
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

    await _runUpdate(
      () => _orderService.acceptOrder(
        orderId: order.orderId,
        estimatedPreparationMinutes: minutes,
      ),
      'Order accepted.',
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
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Reject Order'),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
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

    await _runUpdate(
      () => _orderService.rejectOrder(
        orderId: order.orderId,
        reason: reason,
      ),
      'Order rejected.',
    );
  }

  Future<void> _runUpdate(
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
    } on FoodOrderServiceException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(
        'Unable to update order: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _openOrderDetails(
    FoodOrderModel order,
  ) {
    Navigator.pushNamed(
      context,
      '/food_partner_order_details',
      arguments: order,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (restaurantId.trim().isEmpty) {
      return _buildMissingRestaurant();
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Live Food Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child:
            StreamBuilder<List<FoodOrderModel>>(
          stream:
              _orderService.watchRestaurantOrders(
            restaurantId,
          ),
          builder: (
            BuildContext context,
            AsyncSnapshot<List<FoodOrderModel>>
                snapshot,
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
              return _buildErrorState();
            }

            final List<FoodOrderModel> orders =
                snapshot.data ??
                    const <FoodOrderModel>[];

            final List<FoodOrderModel>
                visibleOrders =
                _filterOrders(orders);

            return Column(
              children: <Widget>[
                _buildStatusFilters(orders),
                Expanded(
                  child: visibleOrders.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            14,
                            16,
                            30,
                          ),
                          itemCount:
                              visibleOrders.length,
                          separatorBuilder: (
                            BuildContext context,
                            int index,
                          ) =>
                              const SizedBox(
                            height: 12,
                          ),
                          itemBuilder: (
                            BuildContext context,
                            int index,
                          ) {
                            final FoodOrderModel order =
                                visibleOrders[index];

                            return _RestaurantOrderCard(
                              order: order,
                              isUpdating:
                                  _isUpdating,
                              onTap: () =>
                                  _openOrderDetails(
                                order,
                              ),
                              onAccept:
                                  order.status ==
                                          FoodOrderStatus
                                              .pending
                                      ? () =>
                                          _acceptOrder(
                                            order,
                                          )
                                      : null,
                              onReject:
                                  order.status ==
                                          FoodOrderStatus
                                              .pending
                                      ? () =>
                                          _rejectOrder(
                                            order,
                                          )
                                      : null,
                              onStartPreparing:
                                  order.status ==
                                          FoodOrderStatus
                                              .accepted
                                      ? () =>
                                          _runUpdate(
                                            () =>
                                                _orderService
                                                    .startPreparing(
                                              order.orderId,
                                            ),
                                            'Food preparation started.',
                                          )
                                      : null,
                              onMarkReady:
                                  order.status ==
                                          FoodOrderStatus
                                              .preparing
                                      ? () =>
                                          _runUpdate(
                                            () =>
                                                _orderService
                                                    .markReadyForPickup(
                                              order.orderId,
                                            ),
                                            'Order marked ready for pickup.',
                                          )
                                      : null,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusFilters(
    List<FoodOrderModel> orders,
  ) {
    final List<FoodOrderStatus> statuses =
        <FoodOrderStatus>[
      FoodOrderStatus.pending,
      FoodOrderStatus.accepted,
      FoodOrderStatus.preparing,
      FoodOrderStatus.readyForPickup,
      FoodOrderStatus.pickedUp,
      FoodOrderStatus.onTheWay,
      FoodOrderStatus.delivered,
      FoodOrderStatus.cancelled,
    ];

    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: statuses.length + 1,
        separatorBuilder: (
          BuildContext context,
          int index,
        ) =>
            const SizedBox(width: 8),
        itemBuilder: (
          BuildContext context,
          int index,
        ) {
          if (index == 0) {
            return _filterChip(
              label: 'All',
              count: orders.length,
              selected:
                  _selectedStatus == null,
              onTap: () {
                setState(() {
                  _selectedStatus = null;
                });
              },
            );
          }

          final FoodOrderStatus status =
              statuses[index - 1];

          final int count = orders
              .where(
                (FoodOrderModel order) =>
                    order.status == status,
              )
              .length;

          return _filterChip(
            label: _statusText(status),
            count: count,
            selected:
                _selectedStatus == status,
            onTap: () {
              setState(() {
                _selectedStatus = status;
              });
            },
          );
        },
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: yellow,
      backgroundColor: cardColor,
      checkmarkColor: Colors.black,
      labelStyle: TextStyle(
        color:
            selected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
      ),
      side: BorderSide.none,
    );
  }

  String _statusText(
    FoodOrderStatus status,
  ) {
    switch (status) {
      case FoodOrderStatus.pending:
        return 'New';
      case FoodOrderStatus.accepted:
        return 'Accepted';
      case FoodOrderStatus.preparing:
        return 'Preparing';
      case FoodOrderStatus.readyForPickup:
        return 'Ready';
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
            SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Orders matching this status will appear here.',
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

  Widget _buildErrorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Text(
          'Unable to load restaurant orders. Check Firestore connection and rules.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMissingRestaurant() {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text('Live Food Orders'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            'Approved restaurant ID is missing.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class _RestaurantOrderCard
    extends StatelessWidget {
  const _RestaurantOrderCard({
    required this.order,
    required this.isUpdating,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
    required this.onStartPreparing,
    required this.onMarkReady,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodOrderModel order;
  final bool isUpdating;
  final VoidCallback onTap;

  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onStartPreparing;
  final VoidCallback? onMarkReady;

  String get _shortId {
    if (order.orderId.length <= 8) {
      return order.orderId;
    }

    return order.orderId.substring(0, 8);
  }

  Color get _statusColor {
    switch (order.status) {
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

  String get _statusText {
    switch (order.status) {
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Order #$_shortId',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _statusColor.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusText,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${order.items.length} item(s) • Rs. ${order.grandTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                order.deliveryAddress.fullAddress,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              if (onAccept != null ||
                  onReject != null ||
                  onStartPreparing != null ||
                  onMarkReady != null) ...<Widget>[
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    if (onReject != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              isUpdating
                                  ? null
                                  : onReject,
                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor:
                                Colors.redAccent,
                            side: const BorderSide(
                              color:
                                  Colors.redAccent,
                            ),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                    if (onReject != null &&
                        onAccept != null)
                      const SizedBox(width: 10),
                    if (onAccept != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              isUpdating
                                  ? null
                                  : onAccept,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor: yellow,
                            foregroundColor:
                                Colors.black,
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                    if (onStartPreparing != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              isUpdating
                                  ? null
                                  : onStartPreparing,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor: yellow,
                            foregroundColor:
                                Colors.black,
                          ),
                          child: const Text(
                            'Start Preparing',
                          ),
                        ),
                      ),
                    if (onMarkReady != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              isUpdating
                                  ? null
                                  : onMarkReady,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.greenAccent,
                            foregroundColor:
                                Colors.black,
                          ),
                          child: const Text(
                            'Mark Ready',
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
