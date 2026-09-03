// lib/food/rider/screens/food_delivery_earnings_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Food Delivery Rider Earnings Screen
//
// Connected with:
// - FoodDeliveryRiderModel
// - FoodDeliveryRiderService
// - FoodOrderModel
//
// Real features:
// - Live rider wallet and earnings
// - Delivered-order income calculation
// - Commission calculation
// - Cash outstanding commission
// - Total commission paid
// - Today / Week / Month / All filters
// - Delivery-wise earning history
//
// Online withdrawal/payment execution remains bypassed.
// =============================================================

import 'package:flutter/material.dart';

import '../../models/food_order_model.dart';
import '../models/food_delivery_rider_model.dart';
import '../services/food_delivery_rider_service.dart';

enum _EarningsPeriod {
  today,
  week,
  month,
  all,
}

class FoodDeliveryEarningsScreen extends StatefulWidget {
  const FoodDeliveryEarningsScreen({
    required this.rider,
    super.key,
  });

  final FoodDeliveryRiderModel rider;

  @override
  State<FoodDeliveryEarningsScreen> createState() =>
      _FoodDeliveryEarningsScreenState();
}

class _FoodDeliveryEarningsScreenState
    extends State<FoodDeliveryEarningsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodDeliveryRiderService _riderService =
      FoodDeliveryRiderService();

  _EarningsPeriod _selectedPeriod =
      _EarningsPeriod.today;

  FoodDeliveryRiderModel get initialRider =>
      widget.rider;

  List<FoodOrderModel> _filterOrders(
    List<FoodOrderModel> orders,
  ) {
    final DateTime now = DateTime.now();

    return orders.where(
      (FoodOrderModel order) {
        if (order.status != FoodOrderStatus.delivered) {
          return false;
        }

        final DateTime value = order.updatedAt;

        switch (_selectedPeriod) {
          case _EarningsPeriod.today:
            return value.year == now.year &&
                value.month == now.month &&
                value.day == now.day;

          case _EarningsPeriod.week:
            final DateTime start =
                now.subtract(const Duration(days: 7));

            return value.isAfter(start) ||
                value.isAtSameMomentAs(start);

          case _EarningsPeriod.month:
            return value.year == now.year &&
                value.month == now.month;

          case _EarningsPeriod.all:
            return true;
        }
      },
    ).toList();
  }

  double _grossEarning(
    FoodOrderModel order,
  ) {
    return order.deliveryFee > 0
        ? order.deliveryFee
        : 80;
  }

  double _commission({
    required FoodOrderModel order,
    required FoodDeliveryRiderModel rider,
  }) {
    return _grossEarning(order) *
        (rider.commissionPercentage / 100);
  }

  double _netEarning({
    required FoodOrderModel order,
    required FoodDeliveryRiderModel rider,
  }) {
    return _grossEarning(order) -
        _commission(
          order: order,
          rider: rider,
        );
  }

  double _sumGross(
    List<FoodOrderModel> orders,
  ) {
    return orders.fold<double>(
      0,
      (
        double total,
        FoodOrderModel order,
      ) =>
          total + _grossEarning(order),
    );
  }

  double _sumCommission({
    required List<FoodOrderModel> orders,
    required FoodDeliveryRiderModel rider,
  }) {
    return orders.fold<double>(
      0,
      (
        double total,
        FoodOrderModel order,
      ) =>
          total +
          _commission(
            order: order,
            rider: rider,
          ),
    );
  }

  double _sumNet({
    required List<FoodOrderModel> orders,
    required FoodDeliveryRiderModel rider,
  }) {
    return orders.fold<double>(
      0,
      (
        double total,
        FoodOrderModel order,
      ) =>
          total +
          _netEarning(
            order: order,
            rider: rider,
          ),
    );
  }

  bool _isCashOrder(
    FoodOrderModel order,
  ) {
    return order.paymentMethod.name
        .toLowerCase()
        .contains('cash');
  }

  void _openWallet(
    FoodDeliveryRiderModel rider,
  ) {
    Navigator.pushNamed(
      context,
      '/food_rider_wallet',
      arguments: rider,
    );
  }

  void _openDeliveryDetails(
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
          'Rider Earnings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Wallet',
            onPressed: () =>
                _openWallet(initialRider),
            icon: const Icon(
              Icons.account_balance_wallet_outlined,
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
          if (riderSnapshot.hasError) {
            return _buildErrorState();
          }

          final FoodDeliveryRiderModel rider =
              riderSnapshot.data ?? initialRider;

          return StreamBuilder<List<FoodOrderModel>>(
            stream:
                _riderService.watchDeliveryHistory(
              rider.riderId,
            ),
            builder: (
              BuildContext context,
              AsyncSnapshot<List<FoodOrderModel>>
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

              if (orderSnapshot.hasError) {
                return _buildErrorState();
              }

              final List<FoodOrderModel> orders =
                  _filterOrders(
                orderSnapshot.data ??
                    const <FoodOrderModel>[],
              );

              final double gross =
                  _sumGross(orders);

              final double commission =
                  _sumCommission(
                orders: orders,
                rider: rider,
              );

              final double net =
                  _sumNet(
                orders: orders,
                rider: rider,
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
                    _buildWalletHeader(rider),
                    const SizedBox(height: 16),
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),
                    _buildEarningsSummary(
                      orders: orders,
                      rider: rider,
                      gross: gross,
                      commission: commission,
                      net: net,
                    ),
                    const SizedBox(height: 18),
                    _buildCommissionCard(rider),
                    const SizedBox(height: 22),
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text(
                            'Delivery Earnings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${orders.length}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (orders.isEmpty)
                      _buildEmptyState()
                    else
                      ...orders.map(
                        (FoodOrderModel order) =>
                            Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: _EarningDeliveryCard(
                            order: order,
                            grossEarning:
                                _grossEarning(order),
                            commission:
                                _commission(
                              order: order,
                              rider: rider,
                            ),
                            netEarning:
                                _netEarning(
                              order: order,
                              rider: rider,
                            ),
                            isCashOrder:
                                _isCashOrder(order),
                            onTap: () =>
                                _openDeliveryDetails(
                              order,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWalletHeader(
    FoodDeliveryRiderModel rider,
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
            radius: 31,
            backgroundColor: Colors.black,
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: yellow,
              size: 33,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Wallet Balance',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${rider.walletBalance.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lifetime earnings: Rs. ${rider.totalEarnings.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Commission paid: Rs. ${rider.totalCommissionPaid.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Open wallet',
            onPressed: () =>
                _openWallet(rider),
            icon: const Icon(
              Icons.chevron_right,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final List<_PeriodItem> periods =
        <_PeriodItem>[
      const _PeriodItem(
        period: _EarningsPeriod.today,
        label: 'Today',
      ),
      const _PeriodItem(
        period: _EarningsPeriod.week,
        label: '7 Days',
      ),
      const _PeriodItem(
        period: _EarningsPeriod.month,
        label: 'Month',
      ),
      const _PeriodItem(
        period: _EarningsPeriod.all,
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
          final _PeriodItem item =
              periods[index];

          final bool selected =
              _selectedPeriod == item.period;

          return ChoiceChip(
            label: Text(item.label),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedPeriod =
                    item.period;
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

  Widget _buildEarningsSummary({
    required List<FoodOrderModel> orders,
    required FoodDeliveryRiderModel rider,
    required double gross,
    required double commission,
    required double net,
  }) {
    final List<_EarningStat> stats =
        <_EarningStat>[
      _EarningStat(
        title: 'Deliveries',
        value: '${orders.length}',
        icon: Icons.delivery_dining,
      ),
      _EarningStat(
        title: 'Gross',
        value: 'Rs. ${gross.toStringAsFixed(0)}',
        icon: Icons.payments_outlined,
      ),
      _EarningStat(
        title: 'Commission',
        value:
            'Rs. ${commission.toStringAsFixed(0)}',
        icon: Icons.percent,
      ),
      _EarningStat(
        title: 'Net',
        value: 'Rs. ${net.toStringAsFixed(0)}',
        icon: Icons.trending_up,
      ),
      _EarningStat(
        title: 'Commission Paid',
        value:
            'Rs. ${rider.totalCommissionPaid.toStringAsFixed(0)}',
        icon: Icons.verified_outlined,
      ),
      _EarningStat(
        title: 'Outstanding',
        value:
            'Rs. ${rider.outstandingCommission.toStringAsFixed(0)}',
        icon: Icons.warning_amber_outlined,
      ),
    ];

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
        childAspectRatio: 1.30,
      ),
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        final _EarningStat stat =
            stats[index];

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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                stat.title,
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

  Widget _buildCommissionCard(
    FoodDeliveryRiderModel rider,
  ) {
    final bool hasOutstanding =
        rider.outstandingCommission > 0;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: hasOutstanding
              ? Colors.orangeAccent.withValues(
                  alpha: 0.65,
                )
              : Colors.white10,
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor:
                (hasOutstanding
                        ? Colors.orangeAccent
                        : Colors.greenAccent)
                    .withValues(alpha: 0.14),
            child: Icon(
              hasOutstanding
                  ? Icons.warning_amber_outlined
                  : Icons.check_circle_outline,
              color: hasOutstanding
                  ? Colors.orangeAccent
                  : Colors.greenAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  hasOutstanding
                      ? 'Outstanding Commission'
                      : 'Commission Clear',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasOutstanding
                      ? 'Rs. ${rider.outstandingCommission.toStringAsFixed(0)} is due from cash deliveries.'
                      : 'No cash-delivery commission is outstanding.',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total commission paid: Rs. ${rider.totalCommissionPaid.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (hasOutstanding)
            TextButton(
              onPressed: () =>
                  _openWallet(rider),
              child: const Text(
                'Settle',
                style: TextStyle(
                  color: yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
      ),
      child: const Column(
        children: <Widget>[
          Icon(
            Icons.payments_outlined,
            color: yellow,
            size: 64,
          ),
          SizedBox(height: 14),
          Text(
            'No earnings found',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Completed delivery earnings for this period will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              height: 1.4,
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
              'Unable to load earnings',
              style: TextStyle(
                fontSize: 21,
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

class _EarningDeliveryCard extends StatelessWidget {
  const _EarningDeliveryCard({
    required this.order,
    required this.grossEarning,
    required this.commission,
    required this.netEarning,
    required this.isCashOrder,
    required this.onTap,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodOrderModel order;
  final double grossEarning;
  final double commission;
  final double netEarning;
  final bool isCashOrder;
  final VoidCallback onTap;

  String get _shortId {
    if (order.orderId.length <= 8) {
      return order.orderId;
    }

    return order.orderId.substring(0, 8);
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
                  const CircleAvatar(
                    backgroundColor:
                        Color(0x33FFD60A),
                    child: Icon(
                      Icons.delivery_dining,
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
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (isCashOrder
                                  ? Colors.orangeAccent
                                  : Colors.greenAccent)
                              .withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCashOrder
                          ? 'CASH'
                          : 'ONLINE',
                      style: TextStyle(
                        color: isCashOrder
                            ? Colors.orangeAccent
                            : Colors.greenAccent,
                        fontSize: 9,
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
              const SizedBox(height: 13),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _amountColumn(
                      label: 'Gross',
                      value: grossEarning,
                    ),
                  ),
                  Expanded(
                    child: _amountColumn(
                      label: 'Commission',
                      value: commission,
                    ),
                  ),
                  Expanded(
                    child: _amountColumn(
                      label: 'Net',
                      value: netEarning,
                      highlight: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountColumn({
    required String label,
    required double value,
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Rs. ${value.toStringAsFixed(0)}',
          style: TextStyle(
            color: highlight
                ? yellow
                : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PeriodItem {
  const _PeriodItem({
    required this.period,
    required this.label,
  });

  final _EarningsPeriod period;
  final String label;
}

class _EarningStat {
  const _EarningStat({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
}
