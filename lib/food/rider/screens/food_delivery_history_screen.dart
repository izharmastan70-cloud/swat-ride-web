// lib/food/rider/screens/food_delivery_history_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Food Delivery Rider History Screen
//
// Connected with:
// - FoodDeliveryRiderModel
// - FoodDeliveryRiderService
// - FoodOrderModel
//
// Real features:
// - Live Firestore delivery history
// - Delivered / Cancelled filters
// - Earnings summary
// - Order details navigation
// - Date, address, status and payment information
//
// Existing non-Food modules remain untouched.
// =============================================================

import 'package:flutter/material.dart';

import '../../models/food_order_model.dart';
import '../models/food_delivery_rider_model.dart';
import '../services/food_delivery_rider_service.dart';

enum _DeliveryHistoryFilter {
  all,
  delivered,
  cancelled,
}

class FoodDeliveryHistoryScreen extends StatefulWidget {
  const FoodDeliveryHistoryScreen({
    required this.rider,
    super.key,
  });

  final FoodDeliveryRiderModel rider;

  @override
  State<FoodDeliveryHistoryScreen> createState() =>
      _FoodDeliveryHistoryScreenState();
}

class _FoodDeliveryHistoryScreenState
    extends State<FoodDeliveryHistoryScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodDeliveryRiderService _riderService =
      FoodDeliveryRiderService();

  _DeliveryHistoryFilter _selectedFilter =
      _DeliveryHistoryFilter.all;

  FoodDeliveryRiderModel get rider => widget.rider;

  List<FoodOrderModel> _filterOrders(
    List<FoodOrderModel> orders,
  ) {
    switch (_selectedFilter) {
      case _DeliveryHistoryFilter.all:
        return orders;

      case _DeliveryHistoryFilter.delivered:
        return orders
            .where(
              (FoodOrderModel order) =>
                  order.status ==
                  FoodOrderStatus.delivered,
            )
            .toList();

      case _DeliveryHistoryFilter.cancelled:
        return orders
            .where(
              (FoodOrderModel order) =>
                  order.status ==
                  FoodOrderStatus.cancelled,
            )
            .toList();
    }
  }

  int _countForFilter(
    List<FoodOrderModel> orders,
    _DeliveryHistoryFilter filter,
  ) {
    switch (filter) {
      case _DeliveryHistoryFilter.all:
        return orders.length;

      case _DeliveryHistoryFilter.delivered:
        return orders
            .where(
              (FoodOrderModel order) =>
                  order.status ==
                  FoodOrderStatus.delivered,
            )
            .length;

      case _DeliveryHistoryFilter.cancelled:
        return orders
            .where(
              (FoodOrderModel order) =>
                  order.status ==
                  FoodOrderStatus.cancelled,
            )
            .length;
    }
  }

  double _estimatedEarning(
    FoodOrderModel order,
  ) {
    final double gross =
        order.deliveryFee > 0
            ? order.deliveryFee
            : 80;

    final double commission =
        gross *
            (rider.commissionPercentage / 100);

    return gross - commission;
  }

  double _totalDeliveredEarnings(
    List<FoodOrderModel> orders,
  ) {
    return orders
        .where(
          (FoodOrderModel order) =>
              order.status ==
              FoodOrderStatus.delivered,
        )
        .fold<double>(
          0,
          (
            double total,
            FoodOrderModel order,
          ) =>
              total + _estimatedEarning(order),
        );
  }

  void _openOrderDetails(
    FoodOrderModel order,
  ) {
    Navigator.pushNamed(
      context,
      '/food_rider_order_details',
      arguments: order,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Delivery History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child:
            StreamBuilder<List<FoodOrderModel>>(
          stream:
              _riderService.watchDeliveryHistory(
            rider.riderId,
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

            final List<FoodOrderModel> allOrders =
                snapshot.data ??
                    const <FoodOrderModel>[];

            final List<FoodOrderModel>
                visibleOrders =
                _filterOrders(allOrders);

            return Column(
              children: <Widget>[
                _buildSummaryCard(allOrders),
                _buildFilters(allOrders),
                Expanded(
                  child: visibleOrders.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: yellow,
                          onRefresh: () async {
                            setState(() {});
                          },
                          child: ListView.separated(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(
                              16,
                              12,
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

                              return _DeliveryHistoryCard(
                                order: order,
                                estimatedNetEarning:
                                    _estimatedEarning(
                                  order,
                                ),
                                onTap: () =>
                                    _openOrderDetails(
                                  order,
                                ),
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

  Widget _buildSummaryCard(
    List<FoodOrderModel> orders,
  ) {
    final int delivered =
        _countForFilter(
      orders,
      _DeliveryHistoryFilter.delivered,
    );

    final int cancelled =
        _countForFilter(
      orders,
      _DeliveryHistoryFilter.cancelled,
    );

    final double totalEarnings =
        _totalDeliveredEarnings(orders);

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
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 29,
            backgroundColor: Colors.black,
            child: Icon(
              Icons.history,
              color: yellow,
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
                  'Delivery Summary',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$delivered delivered • $cancelled cancelled',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Estimated net earnings: Rs. ${totalEarnings.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.black87,
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

  Widget _buildFilters(
    List<FoodOrderModel> orders,
  ) {
    final List<_HistoryFilterItem> filters =
        <_HistoryFilterItem>[
      const _HistoryFilterItem(
        filter: _DeliveryHistoryFilter.all,
        label: 'All',
      ),
      const _HistoryFilterItem(
        filter:
            _DeliveryHistoryFilter.delivered,
        label: 'Delivered',
      ),
      const _HistoryFilterItem(
        filter:
            _DeliveryHistoryFilter.cancelled,
        label: 'Cancelled',
      ),
    ];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 7,
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
          final _HistoryFilterItem item =
              filters[index];

          final bool selected =
              _selectedFilter == item.filter;

          final int count = _countForFilter(
            orders,
            item.filter,
          );

          return ChoiceChip(
            label: Text(
              '${item.label} ($count)',
            ),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedFilter = item.filter;
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
              Icons.delivery_dining,
              color: yellow,
              size: 76,
            ),
            SizedBox(height: 16),
            Text(
              'No delivery history',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Completed and cancelled deliveries will appear here.',
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
            const SizedBox(height: 16),
            const Text(
              'Unable to load delivery history',
              textAlign: TextAlign.center,
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
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
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
}

class _DeliveryHistoryCard extends StatelessWidget {
  const _DeliveryHistoryCard({
    required this.order,
    required this.estimatedNetEarning,
    required this.onTap,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodOrderModel order;
  final double estimatedNetEarning;
  final VoidCallback onTap;

  String get _shortId {
    if (order.orderId.length <= 8) {
      return order.orderId;
    }

    return order.orderId.substring(0, 8);
  }

  Color get _statusColor {
    return order.status ==
            FoodOrderStatus.delivered
        ? Colors.greenAccent
        : Colors.redAccent;
  }

  String get _statusText {
    return order.status ==
            FoodOrderStatus.delivered
        ? 'Delivered'
        : 'Cancelled';
  }

  String get _dateText {
    final DateTime value = order.updatedAt;

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
                  CircleAvatar(
                    backgroundColor:
                        _statusColor.withValues(
                      alpha: 0.14,
                    ),
                    child: Icon(
                      order.status ==
                              FoodOrderStatus.delivered
                          ? Icons.task_alt
                          : Icons.cancel_outlined,
                      color: _statusColor,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Order #$_shortId',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _dateText,
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
              const SizedBox(height: 13),
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
                  _infoTag(
                    Icons.fastfood_outlined,
                    '${order.items.length} item(s)',
                  ),
                  const SizedBox(width: 8),
                  _infoTag(
                    Icons.payment,
                    order.paymentMethod.name,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: <Widget>[
                  Text(
                    'Order Rs. ${order.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  if (order.status ==
                      FoodOrderStatus.delivered)
                    Text(
                      'Net Rs. ${estimatedNetEarning.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: yellow,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _infoTag(
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF272727),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            color: yellow,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryFilterItem {
  const _HistoryFilterItem({
    required this.filter,
    required this.label,
  });

  final _DeliveryHistoryFilter filter;
  final String label;
}
