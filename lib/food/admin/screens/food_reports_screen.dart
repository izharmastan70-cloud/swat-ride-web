// lib/food/admin/screens/food_reports_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Admin Food Reports Screen
//
// Connected with:
// - Cloud Firestore
// - food_orders
// - food_restaurant_partners
// - food_delivery_riders
// - food_partner_settlements
// - food_rider_settlements
//
// Real features:
// - Today / 7 Days / Month / All filters
// - Order, revenue and commission summaries
// - Restaurant gross/net earnings
// - Restaurant and rider commission
// - Rider paid/outstanding commission
// - Partner/rider settlement summaries
// - Restaurant and rider performance
// - Payment-method breakdown
// - Live Firestore updates
//
// PDF export remains bypassed.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../restaurant_partner/models/restaurant_partner_model.dart';
import '../../rider/models/food_delivery_rider_model.dart';

enum _FoodReportPeriod {
  today,
  week,
  month,
  all,
}

class FoodReportsScreen extends StatefulWidget {
  const FoodReportsScreen({
    super.key,
  });

  @override
  State<FoodReportsScreen> createState() =>
      _FoodReportsScreenState();
}

class _FoodReportsScreenState
    extends State<FoodReportsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  static const String ordersCollection =
      'food_orders';

  static const String restaurantsCollection =
      'food_restaurant_partners';

  static const String ridersCollection =
      'food_delivery_riders';

  static const String partnerSettlementsCollection =
      'food_partner_settlements';

  static const String riderSettlementsCollection =
      'food_rider_settlements';

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  _FoodReportPeriod _selectedPeriod =
      _FoodReportPeriod.today;

  Stream<List<_FoodReportOrder>> _watchOrders() {
    return _firestore
        .collection(ordersCollection)
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        final List<_FoodReportOrder> orders =
            snapshot.docs
                .map(_FoodReportOrder.fromDocument)
                .toList();

        orders.sort(
          (
            _FoodReportOrder first,
            _FoodReportOrder second,
          ) =>
              second.createdAt.compareTo(
            first.createdAt,
          ),
        );

        return orders;
      },
    );
  }

  Stream<List<RestaurantPartnerModel>>
      _watchRestaurants() {
    return _firestore
        .collection(restaurantsCollection)
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        final List<RestaurantPartnerModel>
            restaurants = snapshot.docs.map(
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

        return restaurants;
      },
    );
  }

  Stream<List<FoodDeliveryRiderModel>>
      _watchRiders() {
    return _firestore
        .collection(ridersCollection)
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        final List<FoodDeliveryRiderModel> riders =
            snapshot.docs.map(
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

        return riders;
      },
    );
  }

  Stream<List<_FoodSettlement>>
      _watchPartnerSettlements() {
    return _firestore
        .collection(partnerSettlementsCollection)
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) =>
          snapshot.docs
              .map(_FoodSettlement.fromDocument)
              .toList(),
    );
  }

  Stream<List<_FoodSettlement>>
      _watchRiderSettlements() {
    return _firestore
        .collection(riderSettlementsCollection)
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) =>
          snapshot.docs
              .map(_FoodSettlement.fromDocument)
              .toList(),
    );
  }

  List<_FoodReportOrder> _filterOrders(
    List<_FoodReportOrder> orders,
  ) {
    final DateTime now = DateTime.now();

    return orders.where(
      (_FoodReportOrder order) {
        final DateTime value = order.createdAt;

        switch (_selectedPeriod) {
          case _FoodReportPeriod.today:
            return value.year == now.year &&
                value.month == now.month &&
                value.day == now.day;

          case _FoodReportPeriod.week:
            final DateTime start =
                now.subtract(
              const Duration(days: 7),
            );

            return !value.isBefore(start);

          case _FoodReportPeriod.month:
            return value.year == now.year &&
                value.month == now.month;

          case _FoodReportPeriod.all:
            return true;
        }
      },
    ).toList();
  }

  List<_FoodSettlement> _filterSettlements(
    List<_FoodSettlement> settlements,
  ) {
    if (_selectedPeriod ==
        _FoodReportPeriod.all) {
      return settlements;
    }

    final DateTime now = DateTime.now();

    return settlements.where(
      (_FoodSettlement settlement) {
        final DateTime value =
            settlement.createdAt;

        switch (_selectedPeriod) {
          case _FoodReportPeriod.today:
            return value.year == now.year &&
                value.month == now.month &&
                value.day == now.day;

          case _FoodReportPeriod.week:
            final DateTime start =
                now.subtract(
              const Duration(days: 7),
            );

            return !value.isBefore(start);

          case _FoodReportPeriod.month:
            return value.year == now.year &&
                value.month == now.month;

          case _FoodReportPeriod.all:
            return true;
        }
      },
    ).toList();
  }

  _FoodReportSummary _buildSummary({
    required List<_FoodReportOrder> orders,
    required List<RestaurantPartnerModel>
        restaurants,
    required List<FoodDeliveryRiderModel> riders,
    required List<_FoodSettlement>
        partnerSettlements,
    required List<_FoodSettlement>
        riderSettlements,
  }) {
    final Map<String, double>
        restaurantRates = <String, double>{
      for (final RestaurantPartnerModel restaurant
          in restaurants)
        restaurant.restaurantId:
            restaurant.commissionPercentage,
    };

    final Map<String, double> riderRates =
        <String, double>{
      for (final FoodDeliveryRiderModel rider
          in riders)
        rider.riderId:
            rider.commissionPercentage,
    };

    int active = 0;
    int delivered = 0;
    int cancelled = 0;
    int cashOrders = 0;
    int onlineOrders = 0;

    double customerRevenue = 0;
    double itemSales = 0;
    double serviceFees = 0;
    double deliveryFees = 0;
    double restaurantCommission = 0;
    double restaurantNetEarnings = 0;
    double riderGrossEarnings = 0;
    double riderCommission = 0;
    double riderNetEarnings = 0;

    for (final _FoodReportOrder order
        in orders) {
      if (order.isActive) {
        active += 1;
      }

      if (order.isCancelled) {
        cancelled += 1;
        continue;
      }

      if (!order.isDelivered) {
        continue;
      }

      delivered += 1;

      if (order.isCash) {
        cashOrders += 1;
      } else {
        onlineOrders += 1;
      }

      customerRevenue += order.grandTotal;
      itemSales += order.itemsTotal;
      serviceFees += order.serviceFee;
      deliveryFees += order.deliveryFee;

      final double restaurantRate =
          order.restaurantCommissionPercentage >
                  0
              ? order
                  .restaurantCommissionPercentage
              : restaurantRates[
                      order.restaurantId] ??
                  0;

      final double orderRestaurantCommission =
          order.restaurantCommissionAmount > 0
              ? order.restaurantCommissionAmount
              : order.restaurantGrossAmount *
                  (restaurantRate / 100);

      final double orderRestaurantNet =
          order.restaurantNetEarning > 0
              ? order.restaurantNetEarning
              : (order.restaurantGrossAmount -
                      orderRestaurantCommission)
                  .clamp(
                    0,
                    double.infinity,
                  )
                  .toDouble();

      restaurantCommission +=
          orderRestaurantCommission;

      restaurantNetEarnings +=
          orderRestaurantNet;

      final double riderGross =
          order.riderGrossEarning > 0
              ? order.riderGrossEarning
              : order.deliveryFee;

      final double riderRate =
          order.riderCommissionPercentage > 0
              ? order.riderCommissionPercentage
              : riderRates[order.riderId] ?? 0;

      final double orderRiderCommission =
          order.riderCommissionAmount > 0
              ? order.riderCommissionAmount
              : riderGross * (riderRate / 100);

      final double orderRiderNet =
          order.riderNetEarning > 0
              ? order.riderNetEarning
              : (riderGross -
                      orderRiderCommission)
                  .clamp(
                    0,
                    double.infinity,
                  )
                  .toDouble();

      riderGrossEarnings += riderGross;
      riderCommission += orderRiderCommission;
      riderNetEarnings += orderRiderNet;
    }

    final double partnerPending =
        partnerSettlements
            .where(
              (_FoodSettlement value) =>
                  value.isPending,
            )
            .fold<double>(
              0,
              (
                double total,
                _FoodSettlement value,
              ) =>
                  total + value.amount,
            );

    final double partnerPaid =
        partnerSettlements
            .where(
              (_FoodSettlement value) =>
                  value.isPaid,
            )
            .fold<double>(
              0,
              (
                double total,
                _FoodSettlement value,
              ) =>
                  total + value.amount,
            );

    final double partnerRejected =
        partnerSettlements
            .where(
              (_FoodSettlement value) =>
                  value.isRejected,
            )
            .fold<double>(
              0,
              (
                double total,
                _FoodSettlement value,
              ) =>
                  total + value.amount,
            );

    final double riderSettlementPending =
        riderSettlements
            .where(
              (_FoodSettlement value) =>
                  value.isPending,
            )
            .fold<double>(
              0,
              (
                double total,
                _FoodSettlement value,
              ) =>
                  total + value.amount,
            );

    final double riderSettlementPaid =
        riderSettlements
            .where(
              (_FoodSettlement value) =>
                  value.isPaid,
            )
            .fold<double>(
              0,
              (
                double total,
                _FoodSettlement value,
              ) =>
                  total + value.amount,
            );

    final double modelOutstandingCommission =
        riders.fold<double>(
      0,
      (
        double total,
        FoodDeliveryRiderModel rider,
      ) =>
          total + rider.outstandingCommission,
    );

    final double modelCommissionPaid =
        riders.fold<double>(
      0,
      (
        double total,
        FoodDeliveryRiderModel rider,
      ) =>
          total + rider.totalCommissionPaid,
    );

    final double averageOrderValue =
        delivered <= 0
            ? 0
            : customerRevenue / delivered;

    final double successRate =
        (delivered + cancelled) <= 0
            ? 0
            : (delivered /
                    (delivered + cancelled)) *
                100;

    final double cancellationRate =
        orders.isEmpty
            ? 0
            : (cancelled / orders.length) *
                100;

    final double adminGross =
        serviceFees +
            restaurantCommission +
            riderCommission;

    return _FoodReportSummary(
      totalOrders: orders.length,
      activeOrders: active,
      deliveredOrders: delivered,
      cancelledOrders: cancelled,
      cashOrders: cashOrders,
      onlineOrders: onlineOrders,
      customerRevenue: customerRevenue,
      itemSales: itemSales,
      serviceFees: serviceFees,
      deliveryFees: deliveryFees,
      restaurantCommission:
          restaurantCommission,
      restaurantNetEarnings:
          restaurantNetEarnings,
      riderGrossEarnings:
          riderGrossEarnings,
      riderCommission: riderCommission,
      riderNetEarnings: riderNetEarnings,
      riderOutstandingCommission:
          modelOutstandingCommission,
      riderCommissionPaid:
          modelCommissionPaid,
      partnerSettlementPending:
          partnerPending,
      partnerSettlementPaid: partnerPaid,
      partnerSettlementRejected:
          partnerRejected,
      riderSettlementPending:
          riderSettlementPending,
      riderSettlementPaid:
          riderSettlementPaid,
      adminGross: adminGross,
      averageOrderValue:
          averageOrderValue,
      successRate: successRate,
      cancellationRate:
          cancellationRate,
    );
  }

  List<_RestaurantPerformance>
      _restaurantPerformance({
    required List<_FoodReportOrder> orders,
    required List<RestaurantPartnerModel>
        restaurants,
  }) {
    final Map<String, _RestaurantPerformance>
        result =
        <String, _RestaurantPerformance>{};

    final Map<String, RestaurantPartnerModel>
        restaurantById =
        <String, RestaurantPartnerModel>{
      for (final RestaurantPartnerModel restaurant
          in restaurants)
        restaurant.restaurantId:
            restaurant,
    };

    for (final RestaurantPartnerModel restaurant
        in restaurants) {
      if (restaurant.restaurantId
          .trim()
          .isEmpty) {
        continue;
      }

      result[restaurant.restaurantId] =
          _RestaurantPerformance(
        restaurantId: restaurant.restaurantId,
        restaurantName:
            restaurant.restaurantName,
        deliveredOrders: 0,
        cancelledOrders: 0,
        grossSales: 0,
        commission: 0,
        netEarnings: 0,
        rating: restaurant.rating,
      );
    }

    for (final _FoodReportOrder order
        in orders) {
      if (order.restaurantId
          .trim()
          .isEmpty) {
        continue;
      }

      final RestaurantPartnerModel?
          partner =
          restaurantById[order.restaurantId];

      final _RestaurantPerformance current =
          result[order.restaurantId] ??
              _RestaurantPerformance(
                restaurantId:
                    order.restaurantId,
                restaurantName:
                    order.restaurantName
                            .trim()
                            .isEmpty
                        ? 'Restaurant'
                        : order.restaurantName,
                deliveredOrders: 0,
                cancelledOrders: 0,
                grossSales: 0,
                commission: 0,
                netEarnings: 0,
                rating: partner?.rating ?? 0,
              );

      if (order.isCancelled) {
        result[order.restaurantId] =
            current.copyWith(
          cancelledOrders:
              current.cancelledOrders + 1,
        );

        continue;
      }

      if (!order.isDelivered) {
        result[order.restaurantId] =
            current;
        continue;
      }

      final double rate =
          order.restaurantCommissionPercentage >
                  0
              ? order
                  .restaurantCommissionPercentage
              : partner?.commissionPercentage ??
                  0;

      final double commission =
          order.restaurantCommissionAmount > 0
              ? order.restaurantCommissionAmount
              : order.restaurantGrossAmount *
                  (rate / 100);

      final double net =
          order.restaurantNetEarning > 0
              ? order.restaurantNetEarning
              : (order.restaurantGrossAmount -
                      commission)
                  .clamp(
                    0,
                    double.infinity,
                  )
                  .toDouble();

      result[order.restaurantId] =
          current.copyWith(
        deliveredOrders:
            current.deliveredOrders + 1,
        grossSales:
            current.grossSales +
                order.restaurantGrossAmount,
        commission:
            current.commission + commission,
        netEarnings:
            current.netEarnings + net,
      );
    }

    final List<_RestaurantPerformance> values =
        result.values.toList();

    values.sort(
      (
        _RestaurantPerformance first,
        _RestaurantPerformance second,
      ) =>
          second.netEarnings.compareTo(
        first.netEarnings,
      ),
    );

    return values;
  }

  List<_RiderPerformance> _riderPerformance({
    required List<_FoodReportOrder> orders,
    required List<FoodDeliveryRiderModel> riders,
  }) {
    final Map<String, _RiderPerformance> result =
        <String, _RiderPerformance>{};

    final Map<String, FoodDeliveryRiderModel>
        riderById =
        <String, FoodDeliveryRiderModel>{
      for (final FoodDeliveryRiderModel rider
          in riders)
        rider.riderId: rider,
    };

    for (final FoodDeliveryRiderModel rider
        in riders) {
      result[rider.riderId] =
          _RiderPerformance(
        riderId: rider.riderId,
        riderName: rider.fullName,
        completedDeliveries: 0,
        cancelledDeliveries: 0,
        grossEarnings: 0,
        commission: 0,
        netEarnings: 0,
        outstandingCommission:
            rider.outstandingCommission,
        commissionPaid:
            rider.totalCommissionPaid,
        rating: rider.rating,
      );
    }

    for (final _FoodReportOrder order
        in orders) {
      if (order.riderId.trim().isEmpty) {
        continue;
      }

      final FoodDeliveryRiderModel? rider =
          riderById[order.riderId];

      final _RiderPerformance current =
          result[order.riderId] ??
              _RiderPerformance(
                riderId: order.riderId,
                riderName: 'Food Rider',
                completedDeliveries: 0,
                cancelledDeliveries: 0,
                grossEarnings: 0,
                commission: 0,
                netEarnings: 0,
                outstandingCommission:
                    rider?.outstandingCommission ??
                        0,
                commissionPaid:
                    rider?.totalCommissionPaid ??
                        0,
                rating: rider?.rating ?? 0,
              );

      if (order.isCancelled) {
        result[order.riderId] =
            current.copyWith(
          cancelledDeliveries:
              current.cancelledDeliveries + 1,
        );

        continue;
      }

      if (!order.isDelivered) {
        result[order.riderId] = current;
        continue;
      }

      final double gross =
          order.riderGrossEarning > 0
              ? order.riderGrossEarning
              : order.deliveryFee;

      final double rate =
          order.riderCommissionPercentage > 0
              ? order.riderCommissionPercentage
              : rider?.commissionPercentage ??
                  0;

      final double commission =
          order.riderCommissionAmount > 0
              ? order.riderCommissionAmount
              : gross * (rate / 100);

      final double net =
          order.riderNetEarning > 0
              ? order.riderNetEarning
              : (gross - commission)
                  .clamp(
                    0,
                    double.infinity,
                  )
                  .toDouble();

      result[order.riderId] =
          current.copyWith(
        completedDeliveries:
            current.completedDeliveries + 1,
        grossEarnings:
            current.grossEarnings + gross,
        commission:
            current.commission + commission,
        netEarnings:
            current.netEarnings + net,
      );
    }

    final List<_RiderPerformance> values =
        result.values.toList();

    values.sort(
      (
        _RiderPerformance first,
        _RiderPerformance second,
      ) =>
          second.completedDeliveries
              .compareTo(
        first.completedDeliveries,
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
          'Food Reports',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Export report',
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'PDF export remains bypassed.',
                    ),
                  ),
                );
            },
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child:
            StreamBuilder<List<_FoodReportOrder>>(
          stream: _watchOrders(),
          builder: (
            BuildContext context,
            AsyncSnapshot<List<_FoodReportOrder>>
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
                    return StreamBuilder<
                        List<_FoodSettlement>>(
                      stream:
                          _watchPartnerSettlements(),
                      builder: (
                        BuildContext context,
                        AsyncSnapshot<
                                List<_FoodSettlement>>
                            partnerSettlementSnapshot,
                      ) {
                        return StreamBuilder<
                            List<_FoodSettlement>>(
                          stream:
                              _watchRiderSettlements(),
                          builder: (
                            BuildContext context,
                            AsyncSnapshot<
                                    List<_FoodSettlement>>
                                riderSettlementSnapshot,
                          ) {
                            final bool waiting =
                                orderSnapshot.connectionState ==
                                        ConnectionState
                                            .waiting ||
                                    restaurantSnapshot
                                            .connectionState ==
                                        ConnectionState
                                            .waiting ||
                                    riderSnapshot.connectionState ==
                                        ConnectionState
                                            .waiting ||
                                    partnerSettlementSnapshot
                                            .connectionState ==
                                        ConnectionState
                                            .waiting ||
                                    riderSettlementSnapshot
                                            .connectionState ==
                                        ConnectionState
                                            .waiting;

                            final bool hasAnyData =
                                orderSnapshot.hasData ||
                                    restaurantSnapshot
                                        .hasData ||
                                    riderSnapshot.hasData ||
                                    partnerSettlementSnapshot
                                        .hasData ||
                                    riderSettlementSnapshot
                                        .hasData;

                            if (waiting &&
                                !hasAnyData) {
                              return const Center(
                                child:
                                    CircularProgressIndicator(
                                  color: yellow,
                                ),
                              );
                            }

                            if (orderSnapshot.hasError ||
                                restaurantSnapshot
                                    .hasError ||
                                riderSnapshot.hasError ||
                                partnerSettlementSnapshot
                                    .hasError ||
                                riderSettlementSnapshot
                                    .hasError) {
                              return _buildErrorState();
                            }

                            final List<_FoodReportOrder>
                                filteredOrders =
                                _filterOrders(
                              orderSnapshot.data ??
                                  const <
                                      _FoodReportOrder>[],
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

                            final List<_FoodSettlement>
                                partnerSettlements =
                                _filterSettlements(
                              partnerSettlementSnapshot
                                      .data ??
                                  const <
                                      _FoodSettlement>[],
                            );

                            final List<_FoodSettlement>
                                riderSettlements =
                                _filterSettlements(
                              riderSettlementSnapshot
                                      .data ??
                                  const <
                                      _FoodSettlement>[],
                            );

                            final _FoodReportSummary
                                summary =
                                _buildSummary(
                              orders: filteredOrders,
                              restaurants: restaurants,
                              riders: riders,
                              partnerSettlements:
                                  partnerSettlements,
                              riderSettlements:
                                  riderSettlements,
                            );

                            final List<
                                    _RestaurantPerformance>
                                restaurantPerformance =
                                _restaurantPerformance(
                              orders: filteredOrders,
                              restaurants: restaurants,
                            );

                            final List<
                                    _RiderPerformance>
                                riderPerformance =
                                _riderPerformance(
                              orders: filteredOrders,
                              riders: riders,
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
                                  _buildHeader(summary),
                                  const SizedBox(
                                      height: 16),
                                  _buildPeriodSelector(),
                                  const SizedBox(
                                      height: 16),
                                  _buildOrderSummary(
                                    summary,
                                  ),
                                  const SizedBox(
                                      height: 16),
                                  _buildRevenueSummary(
                                    summary,
                                  ),
                                  const SizedBox(
                                      height: 16),
                                  _buildSettlementSummary(
                                    summary,
                                  ),
                                  const SizedBox(
                                      height: 16),
                                  _buildPaymentBreakdown(
                                    summary,
                                  ),
                                  const SizedBox(
                                      height: 22),
                                  _buildRestaurantSection(
                                    restaurantPerformance,
                                  ),
                                  const SizedBox(
                                      height: 22),
                                  _buildRiderSection(
                                    riderPerformance,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
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
    _FoodReportSummary summary,
  ) {
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
              Icons.analytics_outlined,
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
                  'Food Performance Report',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${summary.totalOrders} orders • '
                  'Rs. ${summary.customerRevenue.toStringAsFixed(0)} customer revenue',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Admin gross: Rs. ${summary.adminGross.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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
    final List<_ReportPeriodItem> periods =
        <_ReportPeriodItem>[
      const _ReportPeriodItem(
        period: _FoodReportPeriod.today,
        label: 'Today',
      ),
      const _ReportPeriodItem(
        period: _FoodReportPeriod.week,
        label: '7 Days',
      ),
      const _ReportPeriodItem(
        period: _FoodReportPeriod.month,
        label: 'Month',
      ),
      const _ReportPeriodItem(
        period: _FoodReportPeriod.all,
        label: 'All',
      ),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        separatorBuilder: (
          BuildContext context,
          int index,
        ) =>
            const SizedBox(width: 8),
        itemBuilder: (
          BuildContext context,
          int index,
        ) {
          final _ReportPeriodItem item =
              periods[index];

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

  Widget _buildOrderSummary(
    _FoodReportSummary summary,
  ) {
    return _statsGrid(
      <_ReportStat>[
        _ReportStat(
          title: 'Total Orders',
          value: '${summary.totalOrders}',
          icon: Icons.receipt_long_outlined,
        ),
        _ReportStat(
          title: 'Active',
          value: '${summary.activeOrders}',
          icon: Icons.route,
        ),
        _ReportStat(
          title: 'Delivered',
          value: '${summary.deliveredOrders}',
          icon: Icons.task_alt,
        ),
        _ReportStat(
          title: 'Cancelled',
          value: '${summary.cancelledOrders}',
          icon: Icons.cancel_outlined,
        ),
        _ReportStat(
          title: 'Success Rate',
          value:
              '${summary.successRate.toStringAsFixed(1)}%',
          icon: Icons.trending_up,
        ),
        _ReportStat(
          title: 'Cancel Rate',
          value:
              '${summary.cancellationRate.toStringAsFixed(1)}%',
          icon: Icons.trending_down,
        ),
      ],
    );
  }

  Widget _buildRevenueSummary(
    _FoodReportSummary summary,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Revenue & Commission',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _statsGrid(
          <_ReportStat>[
            _ReportStat(
              title: 'Customer Revenue',
              value:
                  'Rs. ${summary.customerRevenue.toStringAsFixed(0)}',
              icon: Icons.payments_outlined,
            ),
            _ReportStat(
              title: 'Average Order',
              value:
                  'Rs. ${summary.averageOrderValue.toStringAsFixed(0)}',
              icon: Icons.receipt_outlined,
            ),
            _ReportStat(
              title: 'Restaurant Net',
              value:
                  'Rs. ${summary.restaurantNetEarnings.toStringAsFixed(0)}',
              icon: Icons.storefront_outlined,
            ),
            _ReportStat(
              title: 'Restaurant Commission',
              value:
                  'Rs. ${summary.restaurantCommission.toStringAsFixed(0)}',
              icon: Icons.percent,
            ),
            _ReportStat(
              title: 'Rider Net',
              value:
                  'Rs. ${summary.riderNetEarnings.toStringAsFixed(0)}',
              icon: Icons.delivery_dining,
            ),
            _ReportStat(
              title: 'Rider Commission',
              value:
                  'Rs. ${summary.riderCommission.toStringAsFixed(0)}',
              icon: Icons.percent,
            ),
            _ReportStat(
              title: 'Service Fees',
              value:
                  'Rs. ${summary.serviceFees.toStringAsFixed(0)}',
              icon: Icons.receipt_long_outlined,
            ),
            _ReportStat(
              title: 'Admin Gross',
              value:
                  'Rs. ${summary.adminGross.toStringAsFixed(0)}',
              icon: Icons.account_balance_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettlementSummary(
    _FoodReportSummary summary,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Settlements & Commission Wallets',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _statsGrid(
          <_ReportStat>[
            _ReportStat(
              title: 'Partner Pending',
              value:
                  'Rs. ${summary.partnerSettlementPending.toStringAsFixed(0)}',
              icon: Icons.schedule,
            ),
            _ReportStat(
              title: 'Partner Paid',
              value:
                  'Rs. ${summary.partnerSettlementPaid.toStringAsFixed(0)}',
              icon: Icons.check_circle_outline,
            ),
            _ReportStat(
              title: 'Partner Rejected',
              value:
                  'Rs. ${summary.partnerSettlementRejected.toStringAsFixed(0)}',
              icon: Icons.cancel_outlined,
            ),
            _ReportStat(
              title: 'Rider Settlement Pending',
              value:
                  'Rs. ${summary.riderSettlementPending.toStringAsFixed(0)}',
              icon: Icons.schedule,
            ),
            _ReportStat(
              title: 'Rider Settlement Paid',
              value:
                  'Rs. ${summary.riderSettlementPaid.toStringAsFixed(0)}',
              icon: Icons.task_alt,
            ),
            _ReportStat(
              title: 'Rider Commission Paid',
              value:
                  'Rs. ${summary.riderCommissionPaid.toStringAsFixed(0)}',
              icon: Icons.verified_outlined,
            ),
            _ReportStat(
              title: 'Rider Outstanding',
              value:
                  'Rs. ${summary.riderOutstandingCommission.toStringAsFixed(0)}',
              icon: Icons.warning_amber_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentBreakdown(
    _FoodReportSummary summary,
  ) {
    final int total =
        summary.cashOrders +
            summary.onlineOrders;

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
          const Row(
            children: <Widget>[
              Icon(
                Icons.payment,
                color: yellow,
              ),
              SizedBox(width: 10),
              Text(
                'Delivered Payment Breakdown',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _progressRow(
            label: 'Cash Orders',
            value: summary.cashOrders,
            total: total,
            icon: Icons.payments_outlined,
          ),
          const SizedBox(height: 14),
          _progressRow(
            label: 'Online Orders',
            value: summary.onlineOrders,
            total: total,
            icon: Icons.account_balance_outlined,
          ),
        ],
      ),
    );
  }

  Widget _progressRow({
    required String label,
    required int value,
    required int total,
    required IconData icon,
  }) {
    final double ratio =
        total <= 0 ? 0 : value / total;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              icon,
              color: yellow,
              size: 19,
            ),
            const SizedBox(width: 9),
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
          value: ratio.clamp(0, 1).toDouble(),
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

  Widget _buildRestaurantSection(
    List<_RestaurantPerformance> items,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Top Restaurants',
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
                'No restaurant performance data found.',
          )
        else
          ...items.take(5).map(
            (_RestaurantPerformance item) =>
                Padding(
              padding:
                  const EdgeInsets.only(bottom: 10),
              child: _PerformanceCard(
                title: item.restaurantName,
                subtitle:
                    '${item.deliveredOrders} delivered • '
                    '${item.cancelledOrders} cancelled\n'
                    'Commission Rs. ${item.commission.toStringAsFixed(0)}',
                value:
                    'Net Rs. ${item.netEarnings.toStringAsFixed(0)}',
                rating: item.rating,
                icon: Icons.storefront_outlined,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRiderSection(
    List<_RiderPerformance> items,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Top Food Riders',
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
                'No rider performance data found.',
          )
        else
          ...items.take(5).map(
            (_RiderPerformance item) =>
                Padding(
              padding:
                  const EdgeInsets.only(bottom: 10),
              child: _PerformanceCard(
                title: item.riderName,
                subtitle:
                    '${item.completedDeliveries} completed • '
                    '${item.cancelledDeliveries} cancelled\n'
                    'Due Rs. ${item.outstandingCommission.toStringAsFixed(0)} • '
                    'Paid Rs. ${item.commissionPaid.toStringAsFixed(0)}',
                value:
                    'Net Rs. ${item.netEarnings.toStringAsFixed(0)}',
                rating: item.rating,
                icon: Icons.delivery_dining,
              ),
            ),
          ),
      ],
    );
  }

  Widget _statsGrid(
    List<_ReportStat> stats,
  ) {
    return GridView.builder(
      itemCount: stats.length,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        final _ReportStat stat = stats[index];

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
                stat.icon,
                color: yellow,
                size: 27,
              ),
              Text(
                stat.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                stat.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
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
              'Unable to load Food reports',
              textAlign: TextAlign.center,
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

class _FoodReportOrder {
  const _FoodReportOrder({
    required this.orderId,
    required this.restaurantId,
    required this.restaurantName,
    required this.riderId,
    required this.status,
    required this.paymentMethod,
    required this.itemsTotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.discount,
    required this.grandTotal,
    required this.restaurantCommissionPercentage,
    required this.restaurantCommissionAmount,
    required this.restaurantNetEarning,
    required this.riderGrossEarning,
    required this.riderCommissionPercentage,
    required this.riderCommissionAmount,
    required this.riderNetEarning,
    required this.createdAt,
  });

  final String orderId;
  final String restaurantId;
  final String restaurantName;
  final String riderId;
  final String status;
  final String paymentMethod;

  final double itemsTotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double grandTotal;

  final double
      restaurantCommissionPercentage;

  final double restaurantCommissionAmount;
  final double restaurantNetEarning;

  final double riderGrossEarning;
  final double riderCommissionPercentage;
  final double riderCommissionAmount;
  final double riderNetEarning;

  final DateTime createdAt;

  bool get isDelivered =>
      status.toLowerCase() == 'delivered';

  bool get isCancelled =>
      status.toLowerCase() == 'cancelled';

  bool get isCash =>
      paymentMethod.toLowerCase().contains(
            'cash',
          );

  bool get isActive {
    final String value =
        status.toLowerCase();

    return value == 'pending' ||
        value == 'accepted' ||
        value == 'preparing' ||
        value == 'readyforpickup' ||
        value == 'ready_for_pickup' ||
        value == 'pickedup' ||
        value == 'picked_up' ||
        value == 'ontheway' ||
        value == 'on_the_way';
  }

  double get restaurantGrossAmount {
    return (itemsTotal - discount)
        .clamp(
          0,
          double.infinity,
        )
        .toDouble();
  }

  factory _FoodReportOrder.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    final double itemsTotal =
        _FoodReportParser.doubleValue(
      data['itemsTotal'],
    );

    final double deliveryFee =
        _FoodReportParser.doubleValue(
      data['deliveryFee'],
    );

    final double serviceFee =
        _FoodReportParser.doubleValue(
      data['serviceFee'],
    );

    final double discount =
        _FoodReportParser.doubleValue(
      data['discount'],
    );

    final double savedGrandTotal =
        _FoodReportParser.doubleValue(
      data['grandTotal'],
    );

    final double calculatedGrandTotal =
        (itemsTotal +
                deliveryFee +
                serviceFee -
                discount)
            .clamp(
              0,
              double.infinity,
            )
            .toDouble();

    return _FoodReportOrder(
      orderId: document.id,
      restaurantId:
          _FoodReportParser.stringValue(
        data['restaurantId'],
      ),
      restaurantName:
          _FoodReportParser.stringValue(
        data['restaurantName'],
      ),
      riderId:
          _FoodReportParser.stringValue(
        data['riderId'],
      ),
      status:
          _FoodReportParser.stringValue(
        data['status'],
        fallback: 'pending',
      ),
      paymentMethod:
          _FoodReportParser.stringValue(
        data['paymentMethod'],
        fallback: 'cash',
      ),
      itemsTotal: itemsTotal,
      deliveryFee: deliveryFee,
      serviceFee: serviceFee,
      discount: discount,
      grandTotal: savedGrandTotal > 0
          ? savedGrandTotal
          : calculatedGrandTotal,
      restaurantCommissionPercentage:
          _FoodReportParser.doubleValue(
        data[
                'restaurantCommissionPercentage'] ??
            data['commissionPercentage'],
      ),
      restaurantCommissionAmount:
          _FoodReportParser.doubleValue(
        data['restaurantCommissionAmount'] ??
            data['restaurantCommission'],
      ),
      restaurantNetEarning:
          _FoodReportParser.doubleValue(
        data['restaurantNetEarning'] ??
            data['restaurantEarning'] ??
            data['restaurantNetAmount'],
      ),
      riderGrossEarning:
          _FoodReportParser.doubleValue(
        data['riderGrossEarning'] ??
            data['riderEarning'],
      ),
      riderCommissionPercentage:
          _FoodReportParser.doubleValue(
        data['riderCommissionPercentage'],
      ),
      riderCommissionAmount:
          _FoodReportParser.doubleValue(
        data['riderCommissionAmount'] ??
            data['riderCommission'],
      ),
      riderNetEarning:
          _FoodReportParser.doubleValue(
        data['riderNetEarning'] ??
            data['riderNetAmount'],
      ),
      createdAt:
          _FoodReportParser.dateTimeValue(
        data['createdAt'],
      ) ??
              DateTime.now(),
    );
  }
}

class _FoodSettlement {
  const _FoodSettlement({
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final double amount;
  final String status;
  final DateTime createdAt;

  bool get isPending {
    final String value =
        status.toLowerCase();

    return value == 'pending' ||
        value == 'requested' ||
        value == 'processing' ||
        value == 'approved';
  }

  bool get isPaid {
    final String value =
        status.toLowerCase();

    return value == 'paid' ||
        value == 'completed' ||
        value == 'settled';
  }

  bool get isRejected =>
      status.toLowerCase() == 'rejected';

  factory _FoodSettlement.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    return _FoodSettlement(
      amount:
          _FoodReportParser.doubleValue(
        data['amount'] ??
            data['settlementAmount'] ??
            data['netAmount'],
      ),
      status:
          _FoodReportParser.stringValue(
        data['status'],
        fallback: 'pending',
      ),
      createdAt:
          _FoodReportParser.dateTimeValue(
        data['createdAt'] ??
            data['requestedAt'] ??
            data['paidAt'],
      ) ??
              DateTime.now(),
    );
  }
}

class _FoodReportSummary {
  const _FoodReportSummary({
    required this.totalOrders,
    required this.activeOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.cashOrders,
    required this.onlineOrders,
    required this.customerRevenue,
    required this.itemSales,
    required this.serviceFees,
    required this.deliveryFees,
    required this.restaurantCommission,
    required this.restaurantNetEarnings,
    required this.riderGrossEarnings,
    required this.riderCommission,
    required this.riderNetEarnings,
    required this.riderOutstandingCommission,
    required this.riderCommissionPaid,
    required this.partnerSettlementPending,
    required this.partnerSettlementPaid,
    required this.partnerSettlementRejected,
    required this.riderSettlementPending,
    required this.riderSettlementPaid,
    required this.adminGross,
    required this.averageOrderValue,
    required this.successRate,
    required this.cancellationRate,
  });

  final int totalOrders;
  final int activeOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int cashOrders;
  final int onlineOrders;

  final double customerRevenue;
  final double itemSales;
  final double serviceFees;
  final double deliveryFees;

  final double restaurantCommission;
  final double restaurantNetEarnings;

  final double riderGrossEarnings;
  final double riderCommission;
  final double riderNetEarnings;

  final double riderOutstandingCommission;
  final double riderCommissionPaid;

  final double partnerSettlementPending;
  final double partnerSettlementPaid;
  final double partnerSettlementRejected;

  final double riderSettlementPending;
  final double riderSettlementPaid;

  final double adminGross;
  final double averageOrderValue;
  final double successRate;
  final double cancellationRate;
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.rating,
    required this.icon,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final String title;
  final String subtitle;
  final String value;
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
                    fontSize: 10,
                    height: 1.35,
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
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: yellow,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportPeriodItem {
  const _ReportPeriodItem({
    required this.period,
    required this.label,
  });

  final _FoodReportPeriod period;
  final String label;
}

class _ReportStat {
  const _ReportStat({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
}

class _RestaurantPerformance {
  const _RestaurantPerformance({
    required this.restaurantId,
    required this.restaurantName,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.grossSales,
    required this.commission,
    required this.netEarnings,
    required this.rating,
  });

  final String restaurantId;
  final String restaurantName;
  final int deliveredOrders;
  final int cancelledOrders;
  final double grossSales;
  final double commission;
  final double netEarnings;
  final double rating;

  _RestaurantPerformance copyWith({
    int? deliveredOrders,
    int? cancelledOrders,
    double? grossSales,
    double? commission,
    double? netEarnings,
  }) {
    return _RestaurantPerformance(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      deliveredOrders:
          deliveredOrders ??
              this.deliveredOrders,
      cancelledOrders:
          cancelledOrders ??
              this.cancelledOrders,
      grossSales:
          grossSales ?? this.grossSales,
      commission:
          commission ?? this.commission,
      netEarnings:
          netEarnings ?? this.netEarnings,
      rating: rating,
    );
  }
}

class _RiderPerformance {
  const _RiderPerformance({
    required this.riderId,
    required this.riderName,
    required this.completedDeliveries,
    required this.cancelledDeliveries,
    required this.grossEarnings,
    required this.commission,
    required this.netEarnings,
    required this.outstandingCommission,
    required this.commissionPaid,
    required this.rating,
  });

  final String riderId;
  final String riderName;
  final int completedDeliveries;
  final int cancelledDeliveries;
  final double grossEarnings;
  final double commission;
  final double netEarnings;
  final double outstandingCommission;
  final double commissionPaid;
  final double rating;

  _RiderPerformance copyWith({
    int? completedDeliveries,
    int? cancelledDeliveries,
    double? grossEarnings,
    double? commission,
    double? netEarnings,
  }) {
    return _RiderPerformance(
      riderId: riderId,
      riderName: riderName,
      completedDeliveries:
          completedDeliveries ??
              this.completedDeliveries,
      cancelledDeliveries:
          cancelledDeliveries ??
              this.cancelledDeliveries,
      grossEarnings:
          grossEarnings ??
              this.grossEarnings,
      commission:
          commission ?? this.commission,
      netEarnings:
          netEarnings ??
              this.netEarnings,
      outstandingCommission:
          outstandingCommission,
      commissionPaid: commissionPaid,
      rating: rating,
    );
  }
}

class _FoodReportParser {
  const _FoodReportParser._();

  static String stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    final String parsed =
        value?.toString().trim() ?? '';

    return parsed.isEmpty ? fallback : parsed;
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
      // Safe fallback for strings and null values.
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}
