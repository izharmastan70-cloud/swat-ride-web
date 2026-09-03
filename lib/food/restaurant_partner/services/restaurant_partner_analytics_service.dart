// lib/food/restaurant_partner/services/restaurant_partner_analytics_service.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Partner Analytics Firestore Service
//
// Scope:
// - Live restaurant order analytics
// - Today / week / month / year / lifetime summaries
// - Gross sales, net earnings and admin commission
// - Active, delivered and cancelled order counts
// - Average order value
// - Cancellation and delivery success rates
// - Repeat customer count
// - Top-selling food items
// - Peak order hours
// - Settlement summary
// - Chart-ready daily revenue data
//
// Firestore collections:
// - food_orders
// - food_partner_settlements
//
// Notes:
// - Real Firestore reads are enabled.
// - Payment gateway handling is outside this service.
// - This service safely supports older order documents where
//   some newer commission/earning fields may be missing.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

enum RestaurantAnalyticsPeriod {
  today,
  yesterday,
  week,
  month,
  year,
  lifetime,
  custom,
}

class RestaurantPartnerAnalyticsService {
  RestaurantPartnerAnalyticsService({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String ordersCollection =
      'food_orders';

  static const String settlementsCollection =
      'food_partner_settlements';

  CollectionReference<Map<String, dynamic>>
      get _orders =>
          _firestore.collection(ordersCollection);

  CollectionReference<Map<String, dynamic>>
      get _settlements =>
          _firestore.collection(
            settlementsCollection,
          );

  // ===========================================================
  // LIVE WATCHERS
  // ===========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchOrders(
    String restaurantId,
  ) {
    _requireId(
      restaurantId,
      message: 'Restaurant ID is required.',
    );

    return _orders
        .where(
          'restaurantId',
          isEqualTo: restaurantId.trim(),
        )
        .snapshots();
  }

  Stream<List<RestaurantAnalyticsOrder>>
      watchParsedOrders(
    String restaurantId,
  ) {
    return watchOrders(restaurantId).map(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        final List<RestaurantAnalyticsOrder>
            orders = snapshot.docs
                .map(
                  (
                    QueryDocumentSnapshot<
                            Map<String, dynamic>>
                        document,
                  ) =>
                      RestaurantAnalyticsOrder
                          .fromDocument(document),
                )
                .toList();

        orders.sort(
          (
            RestaurantAnalyticsOrder first,
            RestaurantAnalyticsOrder second,
          ) =>
              second.createdAt.compareTo(
            first.createdAt,
          ),
        );

        return orders;
      },
    );
  }

  Stream<RestaurantAnalyticsSummary>
      watchDashboardSummary({
    required String restaurantId,
    RestaurantAnalyticsPeriod period =
        RestaurantAnalyticsPeriod.month,
    DateTime? customStart,
    DateTime? customEnd,
    double fallbackCommissionPercentage = 0,
  }) {
    return watchParsedOrders(restaurantId).map(
      (
        List<RestaurantAnalyticsOrder> orders,
      ) {
        final RestaurantAnalyticsDateRange range =
            RestaurantAnalyticsDateRange
                .fromPeriod(
          period: period,
          now: DateTime.now(),
          customStart: customStart,
          customEnd: customEnd,
        );

        return _buildSummary(
          orders: _filterOrdersByRange(
            orders,
            range,
          ),
          fallbackCommissionPercentage:
              fallbackCommissionPercentage,
          period: period,
          range: range,
        );
      },
    );
  }

  Stream<List<RestaurantSettlementAnalytics>>
      watchSettlements({
    required String partnerId,
  }) {
    _requireId(
      partnerId,
      message: 'Partner ID is required.',
    );

    return _settlements
        .where(
          'partnerId',
          isEqualTo: partnerId.trim(),
        )
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        final List<RestaurantSettlementAnalytics>
            settlements = snapshot.docs
                .map(
                  (
                    QueryDocumentSnapshot<
                            Map<String, dynamic>>
                        document,
                  ) =>
                      RestaurantSettlementAnalytics
                          .fromDocument(document),
                )
                .toList();

        settlements.sort(
          (
            RestaurantSettlementAnalytics first,
            RestaurantSettlementAnalytics second,
          ) =>
              second.createdAt.compareTo(
            first.createdAt,
          ),
        );

        return settlements;
      },
    );
  }

  // ===========================================================
  // BASIC COUNTS
  // ===========================================================

  Future<int> totalOrders(
    String restaurantId,
  ) async {
    final List<RestaurantAnalyticsOrder>
        orders =
        await _loadOrders(restaurantId);

    return orders.length;
  }

  Future<int> deliveredOrders(
    String restaurantId,
  ) async {
    final List<RestaurantAnalyticsOrder>
        orders =
        await _loadOrders(restaurantId);

    return orders
        .where(
          (
            RestaurantAnalyticsOrder order,
          ) =>
              order.isDelivered,
        )
        .length;
  }

  Future<int> cancelledOrders(
    String restaurantId,
  ) async {
    final List<RestaurantAnalyticsOrder>
        orders =
        await _loadOrders(restaurantId);

    return orders
        .where(
          (
            RestaurantAnalyticsOrder order,
          ) =>
              order.isCancelled,
        )
        .length;
  }

  Future<int> activeOrders(
    String restaurantId,
  ) async {
    final List<RestaurantAnalyticsOrder>
        orders =
        await _loadOrders(restaurantId);

    return orders
        .where(
          (
            RestaurantAnalyticsOrder order,
          ) =>
              order.isActive,
        )
        .length;
  }

  // ===========================================================
  // REVENUE / EARNINGS
  // ===========================================================

  Future<double> totalRevenue(
    String restaurantId, {
    double fallbackCommissionPercentage = 0,
  }) async {
    final RestaurantAnalyticsSummary summary =
        await dashboardSummary(
      restaurantId,
      period: RestaurantAnalyticsPeriod.lifetime,
      fallbackCommissionPercentage:
          fallbackCommissionPercentage,
    );

    return summary.grossRevenue;
  }

  Future<double> totalNetEarnings(
    String restaurantId, {
    double fallbackCommissionPercentage = 0,
  }) async {
    final RestaurantAnalyticsSummary summary =
        await dashboardSummary(
      restaurantId,
      period: RestaurantAnalyticsPeriod.lifetime,
      fallbackCommissionPercentage:
          fallbackCommissionPercentage,
    );

    return summary.netEarnings;
  }

  Future<double> totalAdminCommission(
    String restaurantId, {
    double fallbackCommissionPercentage = 0,
  }) async {
    final RestaurantAnalyticsSummary summary =
        await dashboardSummary(
      restaurantId,
      period: RestaurantAnalyticsPeriod.lifetime,
      fallbackCommissionPercentage:
          fallbackCommissionPercentage,
    );

    return summary.adminCommission;
  }

  Future<double> averageOrderValue(
    String restaurantId, {
    double fallbackCommissionPercentage = 0,
  }) async {
    final RestaurantAnalyticsSummary summary =
        await dashboardSummary(
      restaurantId,
      period: RestaurantAnalyticsPeriod.lifetime,
      fallbackCommissionPercentage:
          fallbackCommissionPercentage,
    );

    return summary.averageOrderValue;
  }

  // ===========================================================
  // DASHBOARD SUMMARY
  // ===========================================================

  Future<RestaurantAnalyticsSummary>
      dashboardSummary(
    String restaurantId, {
    RestaurantAnalyticsPeriod period =
        RestaurantAnalyticsPeriod.month,
    DateTime? customStart,
    DateTime? customEnd,
    double fallbackCommissionPercentage = 0,
  }) async {
    final List<RestaurantAnalyticsOrder>
        allOrders =
        await _loadOrders(restaurantId);

    final RestaurantAnalyticsDateRange range =
        RestaurantAnalyticsDateRange
            .fromPeriod(
      period: period,
      now: DateTime.now(),
      customStart: customStart,
      customEnd: customEnd,
    );

    return _buildSummary(
      orders: _filterOrdersByRange(
        allOrders,
        range,
      ),
      fallbackCommissionPercentage:
          fallbackCommissionPercentage,
      period: period,
      range: range,
    );
  }

  Future<Map<String, dynamic>>
      dashboardSummaryMap(
    String restaurantId, {
    RestaurantAnalyticsPeriod period =
        RestaurantAnalyticsPeriod.month,
    DateTime? customStart,
    DateTime? customEnd,
    double fallbackCommissionPercentage = 0,
  }) async {
    final RestaurantAnalyticsSummary summary =
        await dashboardSummary(
      restaurantId,
      period: period,
      customStart: customStart,
      customEnd: customEnd,
      fallbackCommissionPercentage:
          fallbackCommissionPercentage,
    );

    return summary.toMap();
  }

  // ===========================================================
  // SETTLEMENT ANALYTICS
  // ===========================================================

  Future<RestaurantSettlementSummary>
      settlementSummary({
    required String partnerId,
  }) async {
    _requireId(
      partnerId,
      message: 'Partner ID is required.',
    );

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot = await _settlements
              .where(
                'partnerId',
                isEqualTo: partnerId.trim(),
              )
              .get();

      final List<RestaurantSettlementAnalytics>
          settlements = snapshot.docs
              .map(
                (
                  QueryDocumentSnapshot<
                          Map<String, dynamic>>
                      document,
                ) =>
                    RestaurantSettlementAnalytics
                        .fromDocument(document),
              )
              .toList();

      double pending = 0;
      double paid = 0;
      double rejected = 0;

      for (final RestaurantSettlementAnalytics
          settlement in settlements) {
        if (settlement.isPending) {
          pending += settlement.amount;
        } else if (settlement.isPaid) {
          paid += settlement.amount;
        } else if (settlement.isRejected) {
          rejected += settlement.amount;
        }
      }

      return RestaurantSettlementSummary(
        totalRequests: settlements.length,
        pendingAmount: pending,
        paidAmount: paid,
        rejectedAmount: rejected,
      );
    } on FirebaseException catch (error) {
      throw RestaurantPartnerAnalyticsException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    }
  }

  // ===========================================================
  // TOP ITEMS
  // ===========================================================

  Future<List<RestaurantTopSellingItem>>
      topSellingItems(
    String restaurantId, {
    RestaurantAnalyticsPeriod period =
        RestaurantAnalyticsPeriod.month,
    DateTime? customStart,
    DateTime? customEnd,
    int limit = 10,
  }) async {
    final List<RestaurantAnalyticsOrder>
        allOrders =
        await _loadOrders(restaurantId);

    final RestaurantAnalyticsDateRange range =
        RestaurantAnalyticsDateRange
            .fromPeriod(
      period: period,
      now: DateTime.now(),
      customStart: customStart,
      customEnd: customEnd,
    );

    final List<RestaurantAnalyticsOrder>
        deliveredOrders =
        _filterOrdersByRange(
      allOrders,
      range,
    ).where(
      (
        RestaurantAnalyticsOrder order,
      ) =>
          order.isDelivered,
    ).toList();

    final Map<String, _MutableItemSummary>
        itemMap =
        <String, _MutableItemSummary>{};

    for (final RestaurantAnalyticsOrder order
        in deliveredOrders) {
      for (final RestaurantAnalyticsItem item
          in order.items) {
        final String key =
            item.itemId.isNotEmpty
                ? item.itemId
                : item.name.toLowerCase();

        if (key.isEmpty) {
          continue;
        }

        final _MutableItemSummary current =
            itemMap[key] ??
                _MutableItemSummary(
                  itemId: item.itemId,
                  name: item.name.isEmpty
                      ? 'Food item'
                      : item.name,
                );

        current.quantity += item.quantity;
        current.revenue += item.totalPrice;
        current.orderIds.add(order.orderId);

        itemMap[key] = current;
      }
    }

    final List<RestaurantTopSellingItem>
        results = itemMap.values
            .map(
              (
                _MutableItemSummary item,
              ) =>
                  RestaurantTopSellingItem(
                itemId: item.itemId,
                name: item.name,
                quantitySold: item.quantity,
                revenue: item.revenue,
                orderCount: item.orderIds.length,
              ),
            )
            .toList();

    results.sort(
      (
        RestaurantTopSellingItem first,
        RestaurantTopSellingItem second,
      ) {
        final int quantityComparison =
            second.quantitySold.compareTo(
          first.quantitySold,
        );

        if (quantityComparison != 0) {
          return quantityComparison;
        }

        return second.revenue.compareTo(
          first.revenue,
        );
      },
    );

    if (limit <= 0 ||
        results.length <= limit) {
      return results;
    }

    return results.take(limit).toList();
  }

  // ===========================================================
  // PEAK HOURS
  // ===========================================================

  Future<List<RestaurantPeakHour>>
      peakHours(
    String restaurantId, {
    RestaurantAnalyticsPeriod period =
        RestaurantAnalyticsPeriod.month,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final List<RestaurantAnalyticsOrder>
        allOrders =
        await _loadOrders(restaurantId);

    final RestaurantAnalyticsDateRange range =
        RestaurantAnalyticsDateRange
            .fromPeriod(
      period: period,
      now: DateTime.now(),
      customStart: customStart,
      customEnd: customEnd,
    );

    final List<RestaurantAnalyticsOrder>
        orders =
        _filterOrdersByRange(
      allOrders,
      range,
    );

    final Map<int, _MutablePeakHour>
        hourMap =
        <int, _MutablePeakHour>{};

    for (final RestaurantAnalyticsOrder order
        in orders) {
      final int hour = order.createdAt.hour;

      final _MutablePeakHour current =
          hourMap[hour] ??
              _MutablePeakHour(hour: hour);

      current.orderCount += 1;

      if (order.isDelivered) {
        current.deliveredOrders += 1;
        current.revenue +=
            order.restaurantGrossAmount;
      }

      hourMap[hour] = current;
    }

    final List<RestaurantPeakHour>
        results = hourMap.values
            .map(
              (
                _MutablePeakHour item,
              ) =>
                  RestaurantPeakHour(
                hour: item.hour,
                orderCount: item.orderCount,
                deliveredOrders:
                    item.deliveredOrders,
                revenue: item.revenue,
              ),
            )
            .toList();

    results.sort(
      (
        RestaurantPeakHour first,
        RestaurantPeakHour second,
      ) =>
          second.orderCount.compareTo(
        first.orderCount,
      ),
    );

    return results;
  }

  // ===========================================================
  // REPEAT CUSTOMERS
  // ===========================================================

  Future<int> repeatCustomers(
    String restaurantId, {
    RestaurantAnalyticsPeriod period =
        RestaurantAnalyticsPeriod.lifetime,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final List<RestaurantAnalyticsOrder>
        allOrders =
        await _loadOrders(restaurantId);

    final RestaurantAnalyticsDateRange range =
        RestaurantAnalyticsDateRange
            .fromPeriod(
      period: period,
      now: DateTime.now(),
      customStart: customStart,
      customEnd: customEnd,
    );

    final Map<String, int> customerOrders =
        <String, int>{};

    for (final RestaurantAnalyticsOrder order
        in _filterOrdersByRange(
      allOrders,
      range,
    )) {
      if (!order.isDelivered ||
          order.customerId.isEmpty) {
        continue;
      }

      customerOrders[order.customerId] =
          (customerOrders[order.customerId] ??
                  0) +
              1;
    }

    return customerOrders.values
        .where((int count) => count > 1)
        .length;
  }

  // ===========================================================
  // CHART DATA
  // ===========================================================

  Future<List<RestaurantDailyRevenue>>
      dailyRevenueChart(
    String restaurantId, {
    RestaurantAnalyticsPeriod period =
        RestaurantAnalyticsPeriod.month,
    DateTime? customStart,
    DateTime? customEnd,
    double fallbackCommissionPercentage = 0,
  }) async {
    final List<RestaurantAnalyticsOrder>
        allOrders =
        await _loadOrders(restaurantId);

    final RestaurantAnalyticsDateRange range =
        RestaurantAnalyticsDateRange
            .fromPeriod(
      period: period,
      now: DateTime.now(),
      customStart: customStart,
      customEnd: customEnd,
    );

    final Map<String, _MutableDailyRevenue>
        dailyMap =
        <String, _MutableDailyRevenue>{};

    for (final RestaurantAnalyticsOrder order
        in _filterOrdersByRange(
      allOrders,
      range,
    )) {
      final DateTime day = DateTime(
        order.createdAt.year,
        order.createdAt.month,
        order.createdAt.day,
      );

      final String key =
          day.toIso8601String();

      final _MutableDailyRevenue current =
          dailyMap[key] ??
              _MutableDailyRevenue(
                date: day,
              );

      current.totalOrders += 1;

      if (order.isDelivered) {
        current.deliveredOrders += 1;
        current.grossRevenue +=
            order.restaurantGrossAmount;

        final double commission =
            order.resolveCommissionAmount(
          fallbackCommissionPercentage:
              fallbackCommissionPercentage,
        );

        current.adminCommission += commission;
        current.netEarnings +=
            order.resolveNetEarning(
          fallbackCommissionPercentage:
              fallbackCommissionPercentage,
        );
      }

      if (order.isCancelled) {
        current.cancelledOrders += 1;
      }

      dailyMap[key] = current;
    }

    final List<RestaurantDailyRevenue>
        results = dailyMap.values
            .map(
              (
                _MutableDailyRevenue item,
              ) =>
                  RestaurantDailyRevenue(
                date: item.date,
                totalOrders: item.totalOrders,
                deliveredOrders:
                    item.deliveredOrders,
                cancelledOrders:
                    item.cancelledOrders,
                grossRevenue:
                    item.grossRevenue,
                adminCommission:
                    item.adminCommission,
                netEarnings:
                    item.netEarnings,
              ),
            )
            .toList();

    results.sort(
      (
        RestaurantDailyRevenue first,
        RestaurantDailyRevenue second,
      ) =>
          first.date.compareTo(second.date),
    );

    return results;
  }

  // ===========================================================
  // INTERNAL LOAD
  // ===========================================================

  Future<List<RestaurantAnalyticsOrder>>
      _loadOrders(
    String restaurantId,
  ) async {
    _requireId(
      restaurantId,
      message: 'Restaurant ID is required.',
    );

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot = await _orders
              .where(
                'restaurantId',
                isEqualTo:
                    restaurantId.trim(),
              )
              .get();

      final List<RestaurantAnalyticsOrder>
          orders = snapshot.docs
              .map(
                (
                  QueryDocumentSnapshot<
                          Map<String, dynamic>>
                      document,
                ) =>
                    RestaurantAnalyticsOrder
                        .fromDocument(document),
              )
              .toList();

      orders.sort(
        (
          RestaurantAnalyticsOrder first,
          RestaurantAnalyticsOrder second,
        ) =>
            second.createdAt.compareTo(
          first.createdAt,
        ),
      );

      return orders;
    } on FirebaseException catch (error) {
      throw RestaurantPartnerAnalyticsException(
        message: _firebaseMessage(error),
        code: error.code,
      );
    } catch (error) {
      throw RestaurantPartnerAnalyticsException(
        message:
            'Unable to load restaurant analytics: $error',
      );
    }
  }

  RestaurantAnalyticsSummary _buildSummary({
    required List<RestaurantAnalyticsOrder>
        orders,
    required double
        fallbackCommissionPercentage,
    required RestaurantAnalyticsPeriod period,
    required RestaurantAnalyticsDateRange range,
  }) {
    int activeOrders = 0;
    int deliveredOrders = 0;
    int cancelledOrders = 0;

    double grossRevenue = 0;
    double itemsRevenue = 0;
    double deliveryFees = 0;
    double serviceFees = 0;
    double discounts = 0;
    double adminCommission = 0;
    double netEarnings = 0;

    final Set<String> uniqueCustomers =
        <String>{};

    final Map<String, int> customerOrderCounts =
        <String, int>{};

    for (final RestaurantAnalyticsOrder order
        in orders) {
      if (order.customerId.isNotEmpty) {
        uniqueCustomers.add(
          order.customerId,
        );
      }

      if (order.isDelivered &&
          order.customerId.isNotEmpty) {
        customerOrderCounts[
            order.customerId] =
            (customerOrderCounts[
                        order.customerId] ??
                    0) +
                1;
      }

      if (order.isActive) {
        activeOrders += 1;
      }

      if (order.isCancelled) {
        cancelledOrders += 1;
        continue;
      }

      if (!order.isDelivered) {
        continue;
      }

      deliveredOrders += 1;
      grossRevenue +=
          order.restaurantGrossAmount;
      itemsRevenue += order.itemsTotal;
      deliveryFees += order.deliveryFee;
      serviceFees += order.serviceFee;
      discounts += order.discount;

      final double commission =
          order.resolveCommissionAmount(
        fallbackCommissionPercentage:
            fallbackCommissionPercentage,
      );

      adminCommission += commission;

      netEarnings +=
          order.resolveNetEarning(
        fallbackCommissionPercentage:
            fallbackCommissionPercentage,
      );
    }

    final int repeatCustomers =
        customerOrderCounts.values
            .where((int count) => count > 1)
            .length;

    final double averageOrderValue =
        deliveredOrders <= 0
            ? 0
            : grossRevenue /
                deliveredOrders;

    final double deliverySuccessRate =
        (deliveredOrders + cancelledOrders) <= 0
            ? 0
            : (deliveredOrders /
                    (deliveredOrders +
                        cancelledOrders)) *
                100;

    final double cancellationRate =
        orders.isEmpty
            ? 0
            : (cancelledOrders /
                    orders.length) *
                100;

    return RestaurantAnalyticsSummary(
      period: period,
      range: range,
      totalOrders: orders.length,
      activeOrders: activeOrders,
      deliveredOrders: deliveredOrders,
      cancelledOrders: cancelledOrders,
      uniqueCustomers: uniqueCustomers.length,
      repeatCustomers: repeatCustomers,
      grossRevenue: grossRevenue,
      itemsRevenue: itemsRevenue,
      deliveryFees: deliveryFees,
      serviceFees: serviceFees,
      discounts: discounts,
      adminCommission: adminCommission,
      netEarnings: netEarnings,
      averageOrderValue: averageOrderValue,
      deliverySuccessRate:
          deliverySuccessRate,
      cancellationRate: cancellationRate,
    );
  }

  static List<RestaurantAnalyticsOrder>
      _filterOrdersByRange(
    List<RestaurantAnalyticsOrder> orders,
    RestaurantAnalyticsDateRange range,
  ) {
    if (range.isLifetime) {
      return List<RestaurantAnalyticsOrder>.from(
        orders,
      );
    }

    return orders.where(
      (
        RestaurantAnalyticsOrder order,
      ) {
        final bool afterStart =
            range.start == null ||
                !order.createdAt.isBefore(
                  range.start!,
                );

        final bool beforeEnd =
            range.end == null ||
                order.createdAt.isBefore(
                  range.end!,
                );

        return afterStart && beforeEnd;
      },
    ).toList();
  }

  static void _requireId(
    String value, {
    required String message,
  }) {
    if (value.trim().isEmpty) {
      throw RestaurantPartnerAnalyticsException(
        message: message,
      );
    }
  }

  String _firebaseMessage(
    FirebaseException error,
  ) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to view restaurant analytics.';
      case 'unavailable':
        return 'Firebase is temporarily unavailable. Please try again.';
      case 'not-found':
        return 'Restaurant analytics data was not found.';
      case 'failed-precondition':
        return 'Firebase requires an index before this analytics query can run.';
      case 'aborted':
        return 'The analytics request was interrupted. Please try again.';
      default:
        return error.message ??
            'A Firebase error occurred (${error.code}).';
    }
  }
}

// =============================================================
// DATE RANGE
// =============================================================

class RestaurantAnalyticsDateRange {
  const RestaurantAnalyticsDateRange({
    required this.start,
    required this.end,
    required this.isLifetime,
  });

  final DateTime? start;
  final DateTime? end;
  final bool isLifetime;

  factory RestaurantAnalyticsDateRange.fromPeriod({
    required RestaurantAnalyticsPeriod period,
    required DateTime now,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    switch (period) {
      case RestaurantAnalyticsPeriod.today:
        final DateTime start = DateTime(
          now.year,
          now.month,
          now.day,
        );

        return RestaurantAnalyticsDateRange(
          start: start,
          end: start.add(
            const Duration(days: 1),
          ),
          isLifetime: false,
        );

      case RestaurantAnalyticsPeriod.yesterday:
        final DateTime today = DateTime(
          now.year,
          now.month,
          now.day,
        );

        final DateTime start =
            today.subtract(
          const Duration(days: 1),
        );

        return RestaurantAnalyticsDateRange(
          start: start,
          end: today,
          isLifetime: false,
        );

      case RestaurantAnalyticsPeriod.week:
        final DateTime today = DateTime(
          now.year,
          now.month,
          now.day,
        );

        final DateTime start =
            today.subtract(
          Duration(days: now.weekday - 1),
        );

        return RestaurantAnalyticsDateRange(
          start: start,
          end: start.add(
            const Duration(days: 7),
          ),
          isLifetime: false,
        );

      case RestaurantAnalyticsPeriod.month:
        final DateTime start = DateTime(
          now.year,
          now.month,
          1,
        );

        final DateTime end = DateTime(
          now.year,
          now.month + 1,
          1,
        );

        return RestaurantAnalyticsDateRange(
          start: start,
          end: end,
          isLifetime: false,
        );

      case RestaurantAnalyticsPeriod.year:
        final DateTime start = DateTime(
          now.year,
          1,
          1,
        );

        final DateTime end = DateTime(
          now.year + 1,
          1,
          1,
        );

        return RestaurantAnalyticsDateRange(
          start: start,
          end: end,
          isLifetime: false,
        );

      case RestaurantAnalyticsPeriod.lifetime:
        return const RestaurantAnalyticsDateRange(
          start: null,
          end: null,
          isLifetime: true,
        );

      case RestaurantAnalyticsPeriod.custom:
        if (customStart == null ||
            customEnd == null) {
          throw const RestaurantPartnerAnalyticsException(
            message:
                'Custom analytics start and end dates are required.',
          );
        }

        final DateTime start = DateTime(
          customStart.year,
          customStart.month,
          customStart.day,
        );

        final DateTime end = DateTime(
          customEnd.year,
          customEnd.month,
          customEnd.day,
        ).add(
          const Duration(days: 1),
        );

        if (!end.isAfter(start)) {
          throw const RestaurantPartnerAnalyticsException(
            message:
                'Custom analytics end date must be after start date.',
          );
        }

        return RestaurantAnalyticsDateRange(
          start: start,
          end: end,
          isLifetime: false,
        );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'start': start?.toIso8601String(),
      'end': end?.toIso8601String(),
      'isLifetime': isLifetime,
    };
  }
}

// =============================================================
// ORDER ANALYTICS MODEL
// =============================================================

class RestaurantAnalyticsOrder {
  const RestaurantAnalyticsOrder({
    required this.orderId,
    required this.customerId,
    required this.status,
    required this.items,
    required this.itemsTotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
    required this.grandTotal,
    required this.restaurantCommissionPercentage,
    required this.restaurantCommissionAmount,
    required this.restaurantNetEarning,
    required this.createdAt,
    required this.updatedAt,
  });

  final String orderId;
  final String customerId;
  final String status;
  final List<RestaurantAnalyticsItem> items;

  final double itemsTotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double grandTotal;

  final double
      restaurantCommissionPercentage;

  final double restaurantCommissionAmount;
  final double restaurantNetEarning;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isDelivered =>
      status.toLowerCase() == 'delivered';

  bool get isCancelled =>
      status.toLowerCase() == 'cancelled';

  bool get isActive {
    final String normalized =
        status.toLowerCase();

    return normalized == 'pending' ||
        normalized == 'accepted' ||
        normalized == 'preparing' ||
        normalized == 'readyforpickup' ||
        normalized == 'ready_for_pickup' ||
        normalized == 'pickedup' ||
        normalized == 'picked_up' ||
        normalized == 'ontheway' ||
        normalized == 'on_the_way';
  }

  double get restaurantGrossAmount {
    if (itemsTotal > 0) {
      return (itemsTotal - discount)
          .clamp(0, double.infinity);
    }

    return grandTotal;
  }

  double resolveCommissionAmount({
    required double
        fallbackCommissionPercentage,
  }) {
    if (restaurantCommissionAmount > 0) {
      return restaurantCommissionAmount;
    }

    final double rate =
        restaurantCommissionPercentage > 0
            ? restaurantCommissionPercentage
            : fallbackCommissionPercentage;

    final double safeRate =
        rate.clamp(0, 100).toDouble();

    return restaurantGrossAmount *
        (safeRate / 100);
  }

  double resolveNetEarning({
    required double
        fallbackCommissionPercentage,
  }) {
    if (restaurantNetEarning > 0) {
      return restaurantNetEarning;
    }

    return (restaurantGrossAmount -
            resolveCommissionAmount(
              fallbackCommissionPercentage:
                  fallbackCommissionPercentage,
            ))
        .clamp(0, double.infinity);
  }

  factory RestaurantAnalyticsOrder.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    final double itemsTotal =
        _AnalyticsParser.doubleValue(
      data['itemsTotal'],
    );

    final double deliveryFee =
        _AnalyticsParser.doubleValue(
      data['deliveryFee'],
    );

    final double serviceFee =
        _AnalyticsParser.doubleValue(
      data['serviceFee'],
    );

    final double discount =
        _AnalyticsParser.doubleValue(
      data['discount'],
    );

    final double savedGrandTotal =
        _AnalyticsParser.doubleValue(
      data['grandTotal'],
    );

    final double calculatedGrandTotal =
        (itemsTotal +
                deliveryFee +
                serviceFee -
                discount)
            .clamp(0, double.infinity);

    return RestaurantAnalyticsOrder(
      orderId: document.id,
      customerId:
          _AnalyticsParser.stringValue(
        data['customerId'],
      ),
      status:
          _AnalyticsParser.stringValue(
        data['status'],
        fallback: 'pending',
      ),
      items: _AnalyticsParser.mapList(
        data['items'],
      )
          .map(
            (
              Map<String, dynamic> item,
            ) =>
                RestaurantAnalyticsItem
                    .fromMap(item),
          )
          .toList(),
      itemsTotal: itemsTotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      discount: discount,
      grandTotal: savedGrandTotal > 0
          ? savedGrandTotal
          : calculatedGrandTotal,
      restaurantCommissionPercentage:
          _AnalyticsParser.doubleValue(
        data[
                'restaurantCommissionPercentage'] ??
            data['commissionPercentage'],
      ),
      restaurantCommissionAmount:
          _AnalyticsParser.doubleValue(
        data['restaurantCommissionAmount'] ??
            data['restaurantCommission'],
      ),
      restaurantNetEarning:
          _AnalyticsParser.doubleValue(
        data['restaurantNetEarning'] ??
            data['restaurantEarning'] ??
            data['restaurantNetAmount'],
      ),
      createdAt:
          _AnalyticsParser.dateTimeValue(
        data['createdAt'],
      ) ??
              DateTime.now(),
      updatedAt:
          _AnalyticsParser.dateTimeValue(
        data['updatedAt'],
      ) ??
              DateTime.now(),
    );
  }
}

// =============================================================
// ORDER ITEM ANALYTICS
// =============================================================

class RestaurantAnalyticsItem {
  const RestaurantAnalyticsItem({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.totalPrice,
  });

  final String itemId;
  final String name;
  final int quantity;
  final double totalPrice;

  factory RestaurantAnalyticsItem.fromMap(
    Map<String, dynamic> map,
  ) {
    final int quantity =
        _AnalyticsParser.intValue(
      map['quantity'],
      fallback: 1,
    );

    final double totalPrice =
        _AnalyticsParser.doubleValue(
      map['totalPrice'] ??
          map['total'] ??
          map['subtotal'],
    );

    return RestaurantAnalyticsItem(
      itemId:
          _AnalyticsParser.stringValue(
        map['itemId'] ??
            map['foodItemId'] ??
            map['menuItemId'],
      ),
      name:
          _AnalyticsParser.stringValue(
        map['name'] ??
            map['itemName'] ??
            map['foodName'],
        fallback: 'Food item',
      ),
      quantity: quantity < 1 ? 1 : quantity,
      totalPrice: totalPrice,
    );
  }
}

// =============================================================
// SUMMARY MODEL
// =============================================================

class RestaurantAnalyticsSummary {
  const RestaurantAnalyticsSummary({
    required this.period,
    required this.range,
    required this.totalOrders,
    required this.activeOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.uniqueCustomers,
    required this.repeatCustomers,
    required this.grossRevenue,
    required this.itemsRevenue,
    required this.deliveryFees,
    required this.serviceFees,
    required this.discounts,
    required this.adminCommission,
    required this.netEarnings,
    required this.averageOrderValue,
    required this.deliverySuccessRate,
    required this.cancellationRate,
  });

  final RestaurantAnalyticsPeriod period;
  final RestaurantAnalyticsDateRange range;

  final int totalOrders;
  final int activeOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int uniqueCustomers;
  final int repeatCustomers;

  final double grossRevenue;
  final double itemsRevenue;
  final double deliveryFees;
  final double serviceFees;
  final double discounts;
  final double adminCommission;
  final double netEarnings;
  final double averageOrderValue;
  final double deliverySuccessRate;
  final double cancellationRate;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'period': period.name,
      'range': range.toMap(),
      'totalOrders': totalOrders,
      'activeOrders': activeOrders,
      'deliveredOrders': deliveredOrders,
      'cancelledOrders': cancelledOrders,
      'uniqueCustomers': uniqueCustomers,
      'repeatCustomers': repeatCustomers,
      'grossRevenue': grossRevenue,
      'itemsRevenue': itemsRevenue,
      'deliveryFees': deliveryFees,
      'serviceFees': serviceFees,
      'discounts': discounts,
      'adminCommission': adminCommission,
      'netEarnings': netEarnings,
      'averageOrderValue': averageOrderValue,
      'deliverySuccessRate':
          deliverySuccessRate,
      'cancellationRate': cancellationRate,
    };
  }
}

// =============================================================
// SETTLEMENT MODELS
// =============================================================

class RestaurantSettlementAnalytics {
  const RestaurantSettlementAnalytics({
    required this.settlementId,
    required this.status,
    required this.amount,
    required this.createdAt,
  });

  final String settlementId;
  final String status;
  final double amount;
  final DateTime createdAt;

  bool get isPending {
    final String normalized =
        status.toLowerCase();

    return normalized == 'pending' ||
        normalized == 'processing' ||
        normalized == 'approved';
  }

  bool get isPaid {
    final String normalized =
        status.toLowerCase();

    return normalized == 'paid' ||
        normalized == 'completed' ||
        normalized == 'settled';
  }

  bool get isRejected =>
      status.toLowerCase() == 'rejected';

  factory RestaurantSettlementAnalytics
      .fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    return RestaurantSettlementAnalytics(
      settlementId: document.id,
      status:
          _AnalyticsParser.stringValue(
        data['status'],
        fallback: 'pending',
      ),
      amount:
          _AnalyticsParser.doubleValue(
        data['amount'],
      ),
      createdAt:
          _AnalyticsParser.dateTimeValue(
        data['createdAt'],
      ) ??
              DateTime.now(),
    );
  }
}

class RestaurantSettlementSummary {
  const RestaurantSettlementSummary({
    required this.totalRequests,
    required this.pendingAmount,
    required this.paidAmount,
    required this.rejectedAmount,
  });

  final int totalRequests;
  final double pendingAmount;
  final double paidAmount;
  final double rejectedAmount;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'totalRequests': totalRequests,
      'pendingAmount': pendingAmount,
      'paidAmount': paidAmount,
      'rejectedAmount': rejectedAmount,
    };
  }
}

// =============================================================
// TOP ITEM / PEAK HOUR / CHART MODELS
// =============================================================

class RestaurantTopSellingItem {
  const RestaurantTopSellingItem({
    required this.itemId,
    required this.name,
    required this.quantitySold,
    required this.revenue,
    required this.orderCount,
  });

  final String itemId;
  final String name;
  final int quantitySold;
  final double revenue;
  final int orderCount;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'itemId': itemId,
      'name': name,
      'quantitySold': quantitySold,
      'revenue': revenue,
      'orderCount': orderCount,
    };
  }
}

class RestaurantPeakHour {
  const RestaurantPeakHour({
    required this.hour,
    required this.orderCount,
    required this.deliveredOrders,
    required this.revenue,
  });

  final int hour;
  final int orderCount;
  final int deliveredOrders;
  final double revenue;

  String get label {
    final int displayHour =
        hour == 0
            ? 12
            : hour > 12
                ? hour - 12
                : hour;

    final String suffix =
        hour >= 12 ? 'PM' : 'AM';

    return '$displayHour:00 $suffix';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'hour': hour,
      'label': label,
      'orderCount': orderCount,
      'deliveredOrders': deliveredOrders,
      'revenue': revenue,
    };
  }
}

class RestaurantDailyRevenue {
  const RestaurantDailyRevenue({
    required this.date,
    required this.totalOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.grossRevenue,
    required this.adminCommission,
    required this.netEarnings,
  });

  final DateTime date;
  final int totalOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double grossRevenue;
  final double adminCommission;
  final double netEarnings;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'date': date.toIso8601String(),
      'totalOrders': totalOrders,
      'deliveredOrders': deliveredOrders,
      'cancelledOrders': cancelledOrders,
      'grossRevenue': grossRevenue,
      'adminCommission': adminCommission,
      'netEarnings': netEarnings,
    };
  }
}

// =============================================================
// INTERNAL MUTABLE AGGREGATORS
// =============================================================

class _MutableItemSummary {
  _MutableItemSummary({
    required this.itemId,
    required this.name,
  });

  final String itemId;
  final String name;

  int quantity = 0;
  double revenue = 0;
  final Set<String> orderIds = <String>{};
}

class _MutablePeakHour {
  _MutablePeakHour({
    required this.hour,
  });

  final int hour;

  int orderCount = 0;
  int deliveredOrders = 0;
  double revenue = 0;
}

class _MutableDailyRevenue {
  _MutableDailyRevenue({
    required this.date,
  });

  final DateTime date;

  int totalOrders = 0;
  int deliveredOrders = 0;
  int cancelledOrders = 0;

  double grossRevenue = 0;
  double adminCommission = 0;
  double netEarnings = 0;
}

// =============================================================
// SAFE PARSER
// =============================================================

class _AnalyticsParser {
  const _AnalyticsParser._();

  static String stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    final String parsed =
        value?.toString().trim() ?? '';

    return parsed.isEmpty ? fallback : parsed;
  }

  static int intValue(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  static double doubleValue(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  static DateTime? dateTimeValue(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    try {
      final dynamic converted =
          value.toDate();

      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Safe support for non-Timestamp values.
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  static List<Map<String, dynamic>> mapList(
    dynamic value,
  ) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map(
          (Map item) =>
              Map<String, dynamic>.from(item),
        )
        .toList();
  }
}

// =============================================================
// EXCEPTION
// =============================================================

class RestaurantPartnerAnalyticsException
    implements Exception {
  const RestaurantPartnerAnalyticsException({
    required this.message,
    this.code = '',
  });

  final String message;
  final String code;

  @override
  String toString() {
    if (code.trim().isEmpty) {
      return message;
    }

    return 'RestaurantPartnerAnalyticsException($code): $message';
  }
}
