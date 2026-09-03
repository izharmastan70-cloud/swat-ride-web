// lib/food/restaurant_partner/screens/orders_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Partner Live Orders Screen
//
// Connected with:
// - RestaurantPartnerModel
// - FoodOrderModel
// - FoodOrderService
//
// Real features:
// - Live Firestore restaurant orders
// - New / Preparing / Ready / Active / Completed / Cancelled filters
// - Search by order, customer, rider and address
// - Accept order with preparation time
// - Reject order with reason
// - Start preparing
// - Mark ready for pickup
// - Open order details
//
// SOS is intentionally not included here.
// Paid maps and payment-gateway actions remain bypassed.
// =============================================================

import 'package:flutter/material.dart';

import '../../models/food_order_model.dart';
import '../../services/food_order_service.dart';
import '../models/restaurant_partner_model.dart';

enum _PartnerOrderFilter {
  all,
  newOrders,
  preparing,
  ready,
  activeDelivery,
  delivered,
  cancelled,
}

class RestaurantPartnerOrdersScreen
    extends StatefulWidget {
  const RestaurantPartnerOrdersScreen({
    required this.partner,
    super.key,
  });

  final RestaurantPartnerModel partner;

  @override
  State<RestaurantPartnerOrdersScreen>
      createState() =>
          _RestaurantPartnerOrdersScreenState();
}

// Compatibility wrapper for projects/routes that already use OrdersScreen.
class OrdersScreen extends RestaurantPartnerOrdersScreen {
  const OrdersScreen({
    required super.partner,
    super.key,
  });
}

class _RestaurantPartnerOrdersScreenState
    extends State<RestaurantPartnerOrdersScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodOrderService _orderService =
      FoodOrderService();

  final TextEditingController _searchController =
      TextEditingController();

  _PartnerOrderFilter _selectedFilter =
      _PartnerOrderFilter.all;

  String _searchText = '';
  bool _isUpdating = false;

  RestaurantPartnerModel get partner =>
      widget.partner;

  String get restaurantId =>
      partner.restaurantId.trim();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  bool _matchesFilter(
    FoodOrderModel order,
  ) {
    switch (_selectedFilter) {
      case _PartnerOrderFilter.all:
        return true;

      case _PartnerOrderFilter.newOrders:
        return order.status ==
            FoodOrderStatus.pending;

      case _PartnerOrderFilter.preparing:
        return order.status ==
                FoodOrderStatus.accepted ||
            order.status ==
                FoodOrderStatus.preparing;

      case _PartnerOrderFilter.ready:
        return order.status ==
            FoodOrderStatus.readyForPickup;

      case _PartnerOrderFilter.activeDelivery:
        return order.status ==
                FoodOrderStatus.pickedUp ||
            order.status ==
                FoodOrderStatus.onTheWay;

      case _PartnerOrderFilter.delivered:
        return order.status ==
            FoodOrderStatus.delivered;

      case _PartnerOrderFilter.cancelled:
        return order.status ==
            FoodOrderStatus.cancelled;
    }
  }

  List<FoodOrderModel> _visibleOrders(
    List<FoodOrderModel> orders,
  ) {
    final String query =
        _searchText.trim().toLowerCase();

    return orders.where(
      (FoodOrderModel order) {
        if (!_matchesFilter(order)) {
          return false;
        }

        if (query.isEmpty) {
          return true;
        }

        final String searchable = <String>[
          order.orderId,
          order.customerId,
          order.riderId,
          order.restaurantName,
          order.deliveryAddress.fullAddress,
          order.status.name,
          order.paymentMethod.name,
        ].join(' ').toLowerCase();

        return searchable.contains(query);
      },
    ).toList();
  }

  int _count(
    List<FoodOrderModel> orders,
    _PartnerOrderFilter filter,
  ) {
    final _PartnerOrderFilter previous =
        _selectedFilter;

    _selectedFilter = filter;
    final int count = orders
        .where(_matchesFilter)
        .length;
    _selectedFilter = previous;

    return count;
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

  Future<void> _acceptOrder(
    FoodOrderModel order,
  ) async {
    final TextEditingController controller =
        TextEditingController(text: '25');

    final int? minutes = await showDialog<int>(
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
                'Enter the estimated food preparation time.',
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
    if (!partner.canAccessPartnerDashboard) {
      return _buildAccessDenied();
    }

    if (restaurantId.isEmpty) {
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
                child:
                    CircularProgressIndicator(
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
                _visibleOrders(orders);

            return Column(
              children: <Widget>[
                _buildSummary(orders),
                _buildSearchField(),
                _buildFilters(orders),
                Expanded(
                  child: visibleOrders.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: yellow,
                          onRefresh: () async {
                            setState(() {});
                          },
                          child:
                              ListView.separated(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(
                              16,
                              8,
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
                              final FoodOrderModel
                                  order =
                                  visibleOrders[index];

                              return _PartnerOrderCard(
                                order: order,
                                isUpdating:
                                    _isUpdating,
                                onOpenDetails: () =>
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
                                            _startPreparing(
                                              order,
                                            )
                                        : null,
                                onMarkReady:
                                    order.status ==
                                            FoodOrderStatus
                                                .preparing
                                        ? () =>
                                            _markReady(
                                              order,
                                            )
                                        : null,
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummary(
    List<FoodOrderModel> orders,
  ) {
    final int newOrders = _count(
      orders,
      _PartnerOrderFilter.newOrders,
    );

    final int preparing = _count(
      orders,
      _PartnerOrderFilter.preparing,
    );

    final int ready = _count(
      orders,
      _PartnerOrderFilter.ready,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        10,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius:
            BorderRadius.circular(21),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 29,
            backgroundColor: Colors.black,
            child: Icon(
              Icons.receipt_long_outlined,
              color: yellow,
              size: 31,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Restaurant Orders',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$newOrders new • $preparing preparing • $ready ready',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${orders.length}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (String value) {
          setState(() {
            _searchText = value;
          });
        },
        decoration: InputDecoration(
          hintText:
              'Search order, customer, rider or address',
          prefixIcon: const Icon(
            Icons.search,
            color: yellow,
          ),
          suffixIcon: _searchText.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchText = '';
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(
    List<FoodOrderModel> orders,
  ) {
    const List<
            MapEntry<_PartnerOrderFilter, String>>
        filters =
        <MapEntry<_PartnerOrderFilter, String>>[
      MapEntry(
        _PartnerOrderFilter.all,
        'All',
      ),
      MapEntry(
        _PartnerOrderFilter.newOrders,
        'New',
      ),
      MapEntry(
        _PartnerOrderFilter.preparing,
        'Preparing',
      ),
      MapEntry(
        _PartnerOrderFilter.ready,
        'Ready',
      ),
      MapEntry(
        _PartnerOrderFilter.activeDelivery,
        'Delivery',
      ),
      MapEntry(
        _PartnerOrderFilter.delivered,
        'Delivered',
      ),
      MapEntry(
        _PartnerOrderFilter.cancelled,
        'Cancelled',
      ),
    ];

    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (
          BuildContext context,
          int index,
        ) =>
            const SizedBox(width: 8),
        itemBuilder: (
          BuildContext context,
          int index,
        ) {
          final MapEntry<
                  _PartnerOrderFilter, String>
              item = filters[index];

          final bool selected =
              _selectedFilter == item.key;

          return ChoiceChip(
            label: Text(
              '${item.value} (${_count(orders, item.key)})',
            ),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedFilter = item.key;
              });
            },
            selectedColor: yellow,
            backgroundColor: cardColor,
            checkmarkColor: Colors.black,
            labelStyle: TextStyle(
              color: selected
                  ? Colors.black
                  : Colors.white,
              fontWeight: FontWeight.bold,
            ),
            side: BorderSide.none,
          );
        },
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
              size: 74,
            ),
            SizedBox(height: 15),
            Text(
              'No matching orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'New and active restaurant orders will appear here.',
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
              'Unable to load restaurant orders',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check Firestore connection, rules and indexes.',
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

  Widget _buildAccessDenied() {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Restaurant Orders',
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            'Admin approval is required before accessing restaurant orders.',
            textAlign: TextAlign.center,
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
        title: const Text(
          'Restaurant Orders',
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            'Approved restaurant record is not connected yet.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _PartnerOrderCard extends StatelessWidget {
  const _PartnerOrderCard({
    required this.order,
    required this.isUpdating,
    required this.onOpenDetails,
    required this.onAccept,
    required this.onReject,
    required this.onStartPreparing,
    required this.onMarkReady,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodOrderModel order;
  final bool isUpdating;
  final VoidCallback onOpenDetails;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onStartPreparing;
  final VoidCallback? onMarkReady;

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
        _statusColor(order.status);

    return Material(
      color: cardColor,
      borderRadius:
          BorderRadius.circular(19),
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius:
            BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor:
                        statusColor.withValues(
                      alpha: 0.14,
                    ),
                    child: Icon(
                      _statusIcon(order.status),
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Order #${_shortId(order.orderId)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${order.items.length} item(s) • ${order.paymentMethod.name}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
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
                          statusColor.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusText(order.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                order.deliveryAddress.fullAddress,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Text(
                    'Rs. ${order.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: yellow,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed:
                        isUpdating
                            ? null
                            : onOpenDetails,
                    child: const Text(
                      'Details',
                      style: TextStyle(
                        color: yellow,
                      ),
                    ),
                  ),
                ],
              ),
              if (onAccept != null ||
                  onReject != null ||
                  onStartPreparing != null ||
                  onMarkReady != null) ...<Widget>[
                const Divider(
                  color: Colors.white12,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    if (onReject != null)
                      OutlinedButton.icon(
                        onPressed: isUpdating
                            ? null
                            : onReject,
                        icon: const Icon(
                          Icons.close,
                        ),
                        label:
                            const Text('Reject'),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              Colors.redAccent,
                          side: const BorderSide(
                            color:
                                Colors.redAccent,
                          ),
                        ),
                      ),
                    if (onAccept != null)
                      ElevatedButton.icon(
                        onPressed: isUpdating
                            ? null
                            : onAccept,
                        icon: const Icon(
                          Icons.check,
                        ),
                        label:
                            const Text('Accept'),
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor: yellow,
                          foregroundColor:
                              Colors.black,
                        ),
                      ),
                    if (onStartPreparing != null)
                      ElevatedButton.icon(
                        onPressed: isUpdating
                            ? null
                            : onStartPreparing,
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
                    if (onMarkReady != null)
                      ElevatedButton.icon(
                        onPressed: isUpdating
                            ? null
                            : onMarkReady,
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
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _shortId(String value) {
    if (value.length <= 8) {
      return value;
    }

    return value.substring(0, 8);
  }

  static String _statusText(
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
        return Icons.notifications_active_outlined;
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
