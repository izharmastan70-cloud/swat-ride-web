// lib/food/admin/screens/food_analytics_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Admin Food Analytics Screen
//
// Connected with:
// - Cloud Firestore
// - FoodOrderModel
// - RestaurantPartnerModel
// - FoodDeliveryRiderModel
//
// Real features:
// - Today / 7 Days / Month / All filters
// - Revenue trend
// - Order trend
// - Peak ordering hours
// - Payment method breakdown
// - Order status analytics
// - Restaurant performance
// - Rider performance
// - Cancellation rate
// - Average order value
//
// No extra chart package is required.
// Charts are built with standard Flutter widgets.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/food_order_model.dart';
import '../../restaurant_partner/models/restaurant_partner_model.dart';
import '../../rider/models/food_delivery_rider_model.dart';

enum _FoodAnalyticsPeriod {
  today,
  week,
  month,
  all,
}

class FoodAnalyticsScreen extends StatefulWidget {
  const FoodAnalyticsScreen({
    super.key,
  });

  @override
  State<FoodAnalyticsScreen> createState() =>
      _FoodAnalyticsScreenState();
}

class _FoodAnalyticsScreenState
    extends State<FoodAnalyticsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  _FoodAnalyticsPeriod _selectedPeriod =
      _FoodAnalyticsPeriod.week;

  Stream<List<FoodOrderModel>> _watchOrders() {
    return _firestore
        .collection('food_orders')
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        final List<FoodOrderModel> orders =
            snapshot.docs.map(
          (
            QueryDocumentSnapshot<Map<String, dynamic>>
                document,
          ) {
            final Map<String, dynamic> data =
                Map<String, dynamic>.from(
              document.data(),
            );

            data['orderId'] = document.id;

            return FoodOrderModel.fromMap(data);
          },
        ).toList();

        orders.sort(
          (
            FoodOrderModel first,
            FoodOrderModel second,
          ) =>
              first.createdAt.compareTo(
            second.createdAt,
          ),
        );

        return orders;
      },
    );
  }

  Stream<List<RestaurantPartnerModel>>
      _watchRestaurants() {
    return _firestore
        .collection('restaurant_partners')
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        return snapshot.docs.map(
          (
            QueryDocumentSnapshot<Map<String, dynamic>>
                document,
          ) {
            final Map<String, dynamic> data =
                Map<String, dynamic>.from(
              document.data(),
            );

            data['partnerId'] = document.id;

            return RestaurantPartnerModel.fromMap(
              data,
            );
          },
        ).toList();
      },
    );
  }

  Stream<List<FoodDeliveryRiderModel>>
      _watchRiders() {
    return _firestore
        .collection('food_delivery_riders')
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        return snapshot.docs.map(
          (
            QueryDocumentSnapshot<Map<String, dynamic>>
                document,
          ) {
            final Map<String, dynamic> data =
                Map<String, dynamic>.from(
              document.data(),
            );

            data['riderId'] = document.id;

            return FoodDeliveryRiderModel.fromMap(
              data,
            );
          },
        ).toList();
      },
    );
  }

  List<FoodOrderModel> _filterOrders(
    List<FoodOrderModel> orders,
  ) {
    final DateTime now = DateTime.now();

    return orders.where(
      (FoodOrderModel order) {
        final DateTime value = order.createdAt;

        switch (_selectedPeriod) {
          case _FoodAnalyticsPeriod.today:
            return value.year == now.year &&
                value.month == now.month &&
                value.day == now.day;

          case _FoodAnalyticsPeriod.week:
            final DateTime start =
                now.subtract(
              const Duration(days: 7),
            );

            return value.isAfter(start) ||
                value.isAtSameMomentAs(start);

          case _FoodAnalyticsPeriod.month:
            return value.year == now.year &&
                value.month == now.month;

          case _FoodAnalyticsPeriod.all:
            return true;
        }
      },
    ).toList();
  }

  bool _isDelivered(
    FoodOrderModel order,
  ) {
    return order.status ==
        FoodOrderStatus.delivered;
  }

  bool _isCancelled(
    FoodOrderModel order,
  ) {
    return order.status ==
        FoodOrderStatus.cancelled;
  }

  bool _isActive(
    FoodOrderModel order,
  ) {
    return order.status ==
            FoodOrderStatus.pending ||
        order.status ==
            FoodOrderStatus.accepted ||
        order.status ==
            FoodOrderStatus.preparing ||
        order.status ==
            FoodOrderStatus.readyForPickup ||
        order.status ==
            FoodOrderStatus.pickedUp ||
        order.status ==
            FoodOrderStatus.onTheWay;
  }

  double _deliveredRevenue(
    List<FoodOrderModel> orders,
  ) {
    return orders
        .where(_isDelivered)
        .fold<double>(
          0,
          (
            double total,
            FoodOrderModel order,
          ) =>
              total + order.grandTotal,
        );
  }

  double _averageOrderValue(
    List<FoodOrderModel> orders,
  ) {
    final List<FoodOrderModel> delivered =
        orders.where(_isDelivered).toList();

    if (delivered.isEmpty) {
      return 0;
    }

    return _deliveredRevenue(delivered) /
        delivered.length;
  }

  double _cancellationRate(
    List<FoodOrderModel> orders,
  ) {
    if (orders.isEmpty) {
      return 0;
    }

    final int cancelled =
        orders.where(_isCancelled).length;

    return (cancelled / orders.length) * 100;
  }

  List<_TrendPoint> _buildDailyTrend(
    List<FoodOrderModel> orders,
  ) {
    final Map<String, _TrendPoint> grouped =
        <String, _TrendPoint>{};

    for (final FoodOrderModel order in orders) {
      final DateTime date = order.createdAt;

      final String key =
          '${date.year}-${date.month}-${date.day}';

      final String label =
          '${date.day}/${date.month}';

      final _TrendPoint current =
          grouped[key] ??
              _TrendPoint(
                label: label,
                orderCount: 0,
                revenue: 0,
                sortDate: DateTime(
                  date.year,
                  date.month,
                  date.day,
                ),
              );

      grouped[key] = current.copyWith(
        orderCount:
            current.orderCount + 1,
        revenue: current.revenue +
            (_isDelivered(order)
                ? order.grandTotal
                : 0),
      );
    }

    final List<_TrendPoint> values =
        grouped.values.toList();

    values.sort(
      (
        _TrendPoint first,
        _TrendPoint second,
      ) =>
          first.sortDate.compareTo(
        second.sortDate,
      ),
    );

    if (values.length > 14) {
      return values.sublist(
        values.length - 14,
      );
    }

    return values;
  }

  List<_HourPoint> _buildPeakHours(
    List<FoodOrderModel> orders,
  ) {
    final List<int> counts =
        List<int>.filled(24, 0);

    for (final FoodOrderModel order in orders) {
      counts[order.createdAt.hour]++;
    }

    final List<_HourPoint> result =
        <_HourPoint>[];

    for (int hour = 0; hour < 24; hour++) {
      result.add(
        _HourPoint(
          hour: hour,
          orderCount: counts[hour],
        ),
      );
    }

    return result;
  }

  Map<String, int> _paymentBreakdown(
    List<FoodOrderModel> orders,
  ) {
    final Map<String, int> result =
        <String, int>{};

    for (final FoodOrderModel order in orders) {
      final String key =
          order.paymentMethod.name;

      result[key] =
          (result[key] ?? 0) + 1;
    }

    return result;
  }

  List<_RestaurantAnalytics>
      _restaurantAnalytics(
    List<FoodOrderModel> orders,
    List<RestaurantPartnerModel> restaurants,
  ) {
    final Map<String, _RestaurantAnalytics>
        result =
        <String, _RestaurantAnalytics>{};

    for (final RestaurantPartnerModel restaurant
        in restaurants) {
      result[restaurant.restaurantId] =
          _RestaurantAnalytics(
        restaurantId: restaurant.restaurantId,
        name: restaurant.restaurantName,
        orders: 0,
        delivered: 0,
        cancelled: 0,
        revenue: 0,
        rating: restaurant.rating,
      );
    }

    for (final FoodOrderModel order in orders) {
      final _RestaurantAnalytics? current =
          result[order.restaurantId];

      if (current == null) {
        continue;
      }

      result[order.restaurantId] =
          current.copyWith(
        orders: current.orders + 1,
        delivered: current.delivered +
            (_isDelivered(order) ? 1 : 0),
        cancelled: current.cancelled +
            (_isCancelled(order) ? 1 : 0),
        revenue: current.revenue +
            (_isDelivered(order)
                ? order.grandTotal
                : 0),
      );
    }

    final List<_RestaurantAnalytics> values =
        result.values.toList();

    values.sort(
      (
        _RestaurantAnalytics first,
        _RestaurantAnalytics second,
      ) =>
          second.revenue.compareTo(
        first.revenue,
      ),
    );

    return values;
  }

  List<_RiderAnalytics> _riderAnalytics(
    List<FoodOrderModel> orders,
    List<FoodDeliveryRiderModel> riders,
  ) {
    final Map<String, _RiderAnalytics> result =
        <String, _RiderAnalytics>{};

    for (final FoodDeliveryRiderModel rider
        in riders) {
      result[rider.riderId] =
          _RiderAnalytics(
        riderId: rider.riderId,
        name: rider.fullName,
        assigned: 0,
        delivered: 0,
        cancelled: 0,
        deliveryFees: 0,
        rating: rider.rating,
      );
    }

    for (final FoodOrderModel order in orders) {
      if (order.riderId.trim().isEmpty) {
        continue;
      }

      final _RiderAnalytics? current =
          result[order.riderId];

      if (current == null) {
        continue;
      }

      result[order.riderId] =
          current.copyWith(
        assigned: current.assigned + 1,
        delivered: current.delivered +
            (_isDelivered(order) ? 1 : 0),
        cancelled: current.cancelled +
            (_isCancelled(order) ? 1 : 0),
        deliveryFees:
            current.deliveryFees +
                (_isDelivered(order)
                    ? order.deliveryFee
                    : 0),
      );
    }

    final List<_RiderAnalytics> values =
        result.values.toList();

    values.sort(
      (
        _RiderAnalytics first,
        _RiderAnalytics second,
      ) =>
          second.delivered.compareTo(
        first.delivered,
      ),
    );

    return values;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Food Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<
            List<FoodOrderModel>>(
          stream: _watchOrders(),
          builder: (
            BuildContext context,
            AsyncSnapshot<List<FoodOrderModel>>
                orderSnapshot,
          ) {
            return StreamBuilder<
                List<RestaurantPartnerModel>>(
              stream: _watchRestaurants(),
              builder: (
                BuildContext context,
                AsyncSnapshot<
                        List<RestaurantPartnerModel>>
                    restaurantSnapshot,
              ) {
                return StreamBuilder<
                    List<FoodDeliveryRiderModel>>(
                  stream: _watchRiders(),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<
                            List<FoodDeliveryRiderModel>>
                        riderSnapshot,
                  ) {
                    if ((orderSnapshot
                                    .connectionState ==
                                ConnectionState.waiting ||
                            restaurantSnapshot
                                    .connectionState ==
                                ConnectionState.waiting ||
                            riderSnapshot
                                    .connectionState ==
                                ConnectionState.waiting) &&
                        !orderSnapshot.hasData &&
                        !restaurantSnapshot.hasData &&
                        !riderSnapshot.hasData) {
                      return const Center(
                        child:
                            CircularProgressIndicator(
                          color: yellow,
                        ),
                      );
                    }

                    if (orderSnapshot.hasError ||
                        restaurantSnapshot.hasError ||
                        riderSnapshot.hasError) {
                      return _buildErrorState();
                    }

                    final List<FoodOrderModel> orders =
                        _filterOrders(
                      orderSnapshot.data ??
                          const <FoodOrderModel>[],
                    );

                    final List<
                            RestaurantPartnerModel>
                        restaurants =
                        restaurantSnapshot.data ??
                            const <
                                RestaurantPartnerModel>[];

                    final List<
                            FoodDeliveryRiderModel>
                        riders =
                        riderSnapshot.data ??
                            const <
                                FoodDeliveryRiderModel>[];

                    final List<_TrendPoint> trend =
                        _buildDailyTrend(orders);

                    final List<_HourPoint> peakHours =
                        _buildPeakHours(orders);

                    final List<
                            _RestaurantAnalytics>
                        restaurantAnalytics =
                        _restaurantAnalytics(
                      orders,
                      restaurants,
                    );

                    final List<_RiderAnalytics>
                        riderAnalytics =
                        _riderAnalytics(
                      orders,
                      riders,
                    );

                    return RefreshIndicator(
                      color: yellow,
                      onRefresh: () async {
                        setState(() {});
                      },
                      child: ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          14,
                          16,
                          30,
                        ),
                        children: <Widget>[
                          _buildHeader(orders),
                          const SizedBox(height: 16),
                          _buildPeriodSelector(),
                          const SizedBox(height: 16),
                          _buildKpiGrid(orders),
                          const SizedBox(height: 20),
                          _buildTrendCard(trend),
                          const SizedBox(height: 16),
                          _buildPeakHoursCard(
                            peakHours,
                          ),
                          const SizedBox(height: 16),
                          _buildStatusBreakdown(
                            orders,
                          ),
                          const SizedBox(height: 16),
                          _buildPaymentBreakdown(
                            _paymentBreakdown(
                              orders,
                            ),
                            orders.length,
                          ),
                          const SizedBox(height: 22),
                          _buildRestaurantSection(
                            restaurantAnalytics,
                          ),
                          const SizedBox(height: 22),
                          _buildRiderSection(
                            riderAnalytics,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    List<FoodOrderModel> orders,
  ) {
    final double revenue =
        _deliveredRevenue(orders);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.black,
            child: Icon(
              Icons.insights_outlined,
              color: yellow,
              size: 35,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Food Analytics Overview',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${orders.length} orders • '
                  'Rs. ${revenue.toStringAsFixed(0)} revenue',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final List<_AnalyticsPeriodItem> items =
        <_AnalyticsPeriodItem>[
      const _AnalyticsPeriodItem(
        period: _FoodAnalyticsPeriod.today,
        label: 'Today',
      ),
      const _AnalyticsPeriodItem(
        period: _FoodAnalyticsPeriod.week,
        label: '7 Days',
      ),
      const _AnalyticsPeriodItem(
        period: _FoodAnalyticsPeriod.month,
        label: 'Month',
      ),
      const _AnalyticsPeriodItem(
        period: _FoodAnalyticsPeriod.all,
        label: 'All',
      ),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (
          BuildContext context,
          int index,
        ) =>
            const SizedBox(width: 8),
        itemBuilder: (
          BuildContext context,
          int index,
        ) {
          final _AnalyticsPeriodItem item =
              items[index];

          final bool selected =
              _selectedPeriod == item.period;

          return ChoiceChip(
            label: Text(item.label),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedPeriod = item.period;
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

  Widget _buildKpiGrid(
    List<FoodOrderModel> orders,
  ) {
    final List<_AnalyticsKpi> items =
        <_AnalyticsKpi>[
      _AnalyticsKpi(
        title: 'Revenue',
        value:
            'Rs. ${_deliveredRevenue(orders).toStringAsFixed(0)}',
        icon: Icons.payments_outlined,
      ),
      _AnalyticsKpi(
        title: 'Average Order',
        value:
            'Rs. ${_averageOrderValue(orders).toStringAsFixed(0)}',
        icon: Icons.receipt_long_outlined,
      ),
      _AnalyticsKpi(
        title: 'Delivered',
        value:
            '${orders.where(_isDelivered).length}',
        icon: Icons.task_alt,
      ),
      _AnalyticsKpi(
        title: 'Cancellation',
        value:
            '${_cancellationRate(orders).toStringAsFixed(1)}%',
        icon: Icons.cancel_outlined,
      ),
      _AnalyticsKpi(
        title: 'Active Orders',
        value:
            '${orders.where(_isActive).length}',
        icon: Icons.route,
      ),
      _AnalyticsKpi(
        title: 'Customers',
        value:
            '${orders.map((FoodOrderModel order) => order.customerId).where((String id) => id.trim().isNotEmpty).toSet().length}',
        icon: Icons.people_outline,
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        final _AnalyticsKpi item =
            items[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: Colors.white10,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Icon(
                item.icon,
                color: yellow,
                size: 27,
              ),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrendCard(
    List<_TrendPoint> trend,
  ) {
    final double maxRevenue = trend.fold<double>(
      0,
      (
        double current,
        _TrendPoint point,
      ) =>
          point.revenue > current
              ? point.revenue
              : current,
    );

    return _sectionCard(
      title: 'Daily Revenue Trend',
      icon: Icons.show_chart,
      child: trend.isEmpty
          ? _emptyText(
              'No revenue data for this period.',
            )
          : SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: trend.length,
                separatorBuilder: (
                  BuildContext context,
                  int index,
                ) =>
                    const SizedBox(width: 12),
                itemBuilder: (
                  BuildContext context,
                  int index,
                ) {
                  final _TrendPoint point =
                      trend[index];

                  final double ratio =
                      maxRevenue <= 0
                          ? 0
                          : point.revenue /
                              maxRevenue;

                  return SizedBox(
                    width: 54,
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.end,
                      children: <Widget>[
                        Text(
                          'Rs.${point.revenue.toStringAsFixed(0)}',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Align(
                            alignment:
                                Alignment.bottomCenter,
                            child: Container(
                              width: 28,
                              height:
                                  145 *
                                      ratio.clamp(
                                        0.04,
                                        1,
                                      ),
                              decoration:
                                  BoxDecoration(
                                color: yellow,
                                borderRadius:
                                    BorderRadius.circular(
                                  8,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          point.label,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${point.orderCount}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildPeakHoursCard(
    List<_HourPoint> hours,
  ) {
    final int maxCount = hours.fold<int>(
      0,
      (
        int current,
        _HourPoint point,
      ) =>
          point.orderCount > current
              ? point.orderCount
              : current,
    );

    final List<_HourPoint> visible =
        hours
            .where(
              (_HourPoint point) =>
                  point.orderCount > 0,
            )
            .toList();

    visible.sort(
      (
        _HourPoint first,
        _HourPoint second,
      ) =>
          second.orderCount.compareTo(
        first.orderCount,
      ),
    );

    return _sectionCard(
      title: 'Peak Ordering Hours',
      icon: Icons.schedule,
      child: visible.isEmpty
          ? _emptyText(
              'No peak-hour data available.',
            )
          : Column(
              children: visible
                  .take(8)
                  .map(
                    (_HourPoint point) =>
                        Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: _progressRow(
                        label:
                            '${point.hour.toString().padLeft(2, '0')}:00',
                        value:
                            point.orderCount,
                        total: maxCount,
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildStatusBreakdown(
    List<FoodOrderModel> orders,
  ) {
    final List<_BreakdownItem> items =
        <_BreakdownItem>[
      _BreakdownItem(
        label: 'Delivered',
        value:
            orders.where(_isDelivered).length,
        icon: Icons.task_alt,
      ),
      _BreakdownItem(
        label: 'Active',
        value:
            orders.where(_isActive).length,
        icon: Icons.route,
      ),
      _BreakdownItem(
        label: 'Cancelled',
        value:
            orders.where(_isCancelled).length,
        icon: Icons.cancel_outlined,
      ),
    ];

    return _sectionCard(
      title: 'Order Status Breakdown',
      icon: Icons.pie_chart_outline,
      child: Column(
        children: items.map(
          (_BreakdownItem item) {
            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              child: _progressRow(
                label: item.label,
                value: item.value,
                total: orders.length,
                icon: item.icon,
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildPaymentBreakdown(
    Map<String, int> paymentData,
    int total,
  ) {
    final List<MapEntry<String, int>> entries =
        paymentData.entries.toList();

    entries.sort(
      (
        MapEntry<String, int> first,
        MapEntry<String, int> second,
      ) =>
          second.value.compareTo(
        first.value,
      ),
    );

    return _sectionCard(
      title: 'Payment Methods',
      icon: Icons.payment,
      child: entries.isEmpty
          ? _emptyText(
              'No payment data available.',
            )
          : Column(
              children: entries.map(
                (
                  MapEntry<String, int> entry,
                ) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: _progressRow(
                      label: entry.key,
                      value: entry.value,
                      total: total,
                    ),
                  );
                },
              ).toList(),
            ),
    );
  }

  Widget _buildRestaurantSection(
    List<_RestaurantAnalytics> items,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Restaurant Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _emptyCard(
            icon: Icons.storefront_outlined,
            message:
                'No restaurant analytics available.',
          )
        else
          ...items.take(5).map(
            (_RestaurantAnalytics item) =>
                Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              child: _AnalyticsEntityCard(
                title: item.name,
                subtitle:
                    '${item.delivered} delivered • '
                    '${item.cancelled} cancelled',
                value:
                    'Rs. ${item.revenue.toStringAsFixed(0)}',
                secondary:
                    '${item.orders} orders',
                rating: item.rating,
                icon: Icons.storefront_outlined,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRiderSection(
    List<_RiderAnalytics> items,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Rider Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _emptyCard(
            icon: Icons.delivery_dining,
            message:
                'No rider analytics available.',
          )
        else
          ...items.take(5).map(
            (_RiderAnalytics item) =>
                Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              child: _AnalyticsEntityCard(
                title: item.name,
                subtitle:
                    '${item.delivered} delivered • '
                    '${item.cancelled} cancelled',
                value:
                    'Rs. ${item.deliveryFees.toStringAsFixed(0)}',
                secondary:
                    '${item.assigned} assigned',
                rating: item.rating,
                icon: Icons.delivery_dining,
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
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
          child,
        ],
      ),
    );
  }

  Widget _progressRow({
    required String label,
    required int value,
    required int total,
    IconData? icon,
  }) {
    final double ratio =
        total <= 0 ? 0 : value / total;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(
                icon,
                color: yellow,
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(label),
            ),
            Text(
              '$value',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: ratio.clamp(0, 1),
          minHeight: 7,
          backgroundColor:
              const Color(0xFF2A2A2A),
          valueColor:
              const AlwaysStoppedAnimation<Color>(
            yellow,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
      ],
    );
  }

  Widget _emptyText(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 20,
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            color: yellow,
            size: 54,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
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
            const SizedBox(height: 16),
            const Text(
              'Unable to load Food analytics',
              style: TextStyle(
                fontSize: 21,
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

class _AnalyticsEntityCard extends StatelessWidget {
  const _AnalyticsEntityCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.secondary,
    required this.rating,
    required this.icon,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final String title;
  final String subtitle;
  final String value;
  final String secondary;
  final double rating;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor:
                yellow.withValues(alpha: 0.12),
            child: Icon(
              icon,
              color: yellow,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.star,
                      color: yellow,
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      secondary,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: yellow,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsPeriodItem {
  const _AnalyticsPeriodItem({
    required this.period,
    required this.label,
  });

  final _FoodAnalyticsPeriod period;
  final String label;
}

class _AnalyticsKpi {
  const _AnalyticsKpi({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
}

class _TrendPoint {
  const _TrendPoint({
    required this.label,
    required this.orderCount,
    required this.revenue,
    required this.sortDate,
  });

  final String label;
  final int orderCount;
  final double revenue;
  final DateTime sortDate;

  _TrendPoint copyWith({
    int? orderCount,
    double? revenue,
  }) {
    return _TrendPoint(
      label: label,
      orderCount:
          orderCount ?? this.orderCount,
      revenue: revenue ?? this.revenue,
      sortDate: sortDate,
    );
  }
}

class _HourPoint {
  const _HourPoint({
    required this.hour,
    required this.orderCount,
  });

  final int hour;
  final int orderCount;
}

class _BreakdownItem {
  const _BreakdownItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;
}

class _RestaurantAnalytics {
  const _RestaurantAnalytics({
    required this.restaurantId,
    required this.name,
    required this.orders,
    required this.delivered,
    required this.cancelled,
    required this.revenue,
    required this.rating,
  });

  final String restaurantId;
  final String name;
  final int orders;
  final int delivered;
  final int cancelled;
  final double revenue;
  final double rating;

  _RestaurantAnalytics copyWith({
    int? orders,
    int? delivered,
    int? cancelled,
    double? revenue,
  }) {
    return _RestaurantAnalytics(
      restaurantId: restaurantId,
      name: name,
      orders: orders ?? this.orders,
      delivered:
          delivered ?? this.delivered,
      cancelled:
          cancelled ?? this.cancelled,
      revenue: revenue ?? this.revenue,
      rating: rating,
    );
  }
}

class _RiderAnalytics {
  const _RiderAnalytics({
    required this.riderId,
    required this.name,
    required this.assigned,
    required this.delivered,
    required this.cancelled,
    required this.deliveryFees,
    required this.rating,
  });

  final String riderId;
  final String name;
  final int assigned;
  final int delivered;
  final int cancelled;
  final double deliveryFees;
  final double rating;

  _RiderAnalytics copyWith({
    int? assigned,
    int? delivered,
    int? cancelled,
    double? deliveryFees,
  }) {
    return _RiderAnalytics(
      riderId: riderId,
      name: name,
      assigned:
          assigned ?? this.assigned,
      delivered:
          delivered ?? this.delivered,
      cancelled:
          cancelled ?? this.cancelled,
      deliveryFees:
          deliveryFees ??
              this.deliveryFees,
      rating: rating,
    );
  }
}
