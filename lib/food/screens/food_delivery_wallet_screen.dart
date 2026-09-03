// lib/food/screens/food_delivery_wallet_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Food Delivery Rider Wallet Screen
//
// Connected with:
// - FoodDeliveryRiderModel
// - FoodDeliveryRiderService
// - FoodOrderModel
//
// Real features:
// - Live wallet balance
// - Lifetime earnings
// - Outstanding cash-order commission
// - Cash / online delivery summary
// - Commission settlement
// - Delivery-wise wallet activity
//
// Online withdrawal and payment gateway execution remain bypassed.
// Firestore wallet values and settlement logic remain real.
// =============================================================

import 'package:flutter/material.dart';

import '../models/food_order_model.dart';
import '../rider/models/food_delivery_rider_model.dart';
import '../rider/services/food_delivery_rider_service.dart';

enum _WalletFilter {
  all,
  cash,
  online,
}

class FoodDeliveryWalletScreen extends StatefulWidget {
  const FoodDeliveryWalletScreen({
    required this.rider,
    super.key,
  });

  final FoodDeliveryRiderModel rider;

  @override
  State<FoodDeliveryWalletScreen> createState() =>
      _FoodDeliveryWalletScreenState();
}

class _FoodDeliveryWalletScreenState
    extends State<FoodDeliveryWalletScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodDeliveryRiderService _riderService =
      FoodDeliveryRiderService();

  _WalletFilter _selectedFilter = _WalletFilter.all;
  bool _isUpdating = false;

  FoodDeliveryRiderModel get initialRider =>
      widget.rider;

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

  bool _isCashOrder(
    FoodOrderModel order,
  ) {
    return order.paymentMethod.name
        .toLowerCase()
        .contains('cash');
  }

  List<FoodOrderModel> _filterOrders(
    List<FoodOrderModel> orders,
  ) {
    final List<FoodOrderModel> delivered =
        orders.where(
      (FoodOrderModel order) =>
          order.status == FoodOrderStatus.delivered,
    ).toList();

    switch (_selectedFilter) {
      case _WalletFilter.all:
        return delivered;

      case _WalletFilter.cash:
        return delivered
            .where(_isCashOrder)
            .toList();

      case _WalletFilter.online:
        return delivered
            .where(
              (FoodOrderModel order) =>
                  !_isCashOrder(order),
            )
            .toList();
    }
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

  double _cashNetTotal({
    required List<FoodOrderModel> orders,
    required FoodDeliveryRiderModel rider,
  }) {
    return orders
        .where(_isCashOrder)
        .fold<double>(
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

  double _onlineNetTotal({
    required List<FoodOrderModel> orders,
    required FoodDeliveryRiderModel rider,
  }) {
    return orders
        .where(
          (FoodOrderModel order) =>
              !_isCashOrder(order),
        )
        .fold<double>(
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

  Future<void> _settleCommission(
    FoodDeliveryRiderModel rider,
  ) async {
    if (_isUpdating) {
      return;
    }

    if (rider.outstandingCommission <= 0) {
      _showMessage(
        'No outstanding commission to settle.',
      );
      return;
    }

    final TextEditingController controller =
        TextEditingController(
      text: rider.outstandingCommission
          .toStringAsFixed(0),
    );

    final double? amount =
        await showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Settle Commission',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Outstanding: Rs. ${rider.outstandingCommission.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Settlement amount',
                  hintText: '0',
                  filled: true,
                  fillColor: const Color(0xFF252525),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Online payment execution is bypassed for now. This action records the settlement in Firestore.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  height: 1.4,
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
                final double? value =
                    double.tryParse(
                  controller.text.trim(),
                );

                if (value == null ||
                    value <= 0 ||
                    value >
                        rider
                            .outstandingCommission) {
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
              child: const Text('Settle'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (amount == null) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _riderService
          .settleOutstandingCommission(
        riderId: rider.riderId,
        amount: amount,
      );

      _showMessage(
        'Commission settlement recorded successfully.',
      );
    } on FoodDeliveryRiderServiceException
        catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(
        'Unable to settle commission: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _requestWithdrawal(
    FoodDeliveryRiderModel rider,
  ) async {
    if (rider.walletBalance <= 0) {
      _showMessage(
        'Wallet balance is not available for withdrawal.',
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Withdrawal Request',
          ),
          content: Text(
            'Available wallet balance:\n'
            'Rs. ${rider.walletBalance.toStringAsFixed(0)}\n\n'
            'Automatic withdrawal is temporarily bypassed. '
            'A real payout gateway can be connected later.',
            style: const TextStyle(
              color: Colors.grey,
              height: 1.45,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
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
          'Food Rider Wallet',
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

              final List<FoodOrderModel> allOrders =
                  orderSnapshot.data ??
                      const <FoodOrderModel>[];

              final List<FoodOrderModel>
                  visibleOrders =
                  _filterOrders(allOrders);

              final double cashNet =
                  _cashNetTotal(
                orders: allOrders,
                rider: rider,
              );

              final double onlineNet =
                  _onlineNetTotal(
                orders: allOrders,
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
                    _buildWalletActions(rider),
                    const SizedBox(height: 16),
                    _buildBalanceSummary(
                      rider: rider,
                      cashNet: cashNet,
                      onlineNet: onlineNet,
                    ),
                    const SizedBox(height: 16),
                    _buildCommissionCard(rider),
                    const SizedBox(height: 18),
                    _buildFilterChips(),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text(
                            'Wallet Activity',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${visibleOrders.length}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (visibleOrders.isEmpty)
                      _buildEmptyState()
                    else
                      ...visibleOrders.map(
                        (FoodOrderModel order) =>
                            Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: _WalletActivityCard(
                            order: order,
                            gross:
                                _grossEarning(order),
                            commission:
                                _commission(
                              order: order,
                              rider: rider,
                            ),
                            net:
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
            radius: 32,
            backgroundColor: Colors.black,
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: yellow,
              size: 34,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Available Balance',
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
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lifetime net earnings: Rs. ${rider.totalEarnings.toStringAsFixed(0)}',
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

  Widget _buildWalletActions(
    FoodDeliveryRiderModel rider,
  ) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isUpdating
                  ? null
                  : () =>
                      _requestWithdrawal(rider),
              icon: const Icon(
                Icons.outbox_outlined,
              ),
              label: const Text(
                'Withdraw',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cardColor,
                foregroundColor: yellow,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isUpdating
                  ? null
                  : () =>
                      _settleCommission(rider),
              icon: _isUpdating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.receipt_long_outlined,
                    ),
              label: const Text(
                'Settle Due',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceSummary({
    required FoodDeliveryRiderModel rider,
    required double cashNet,
    required double onlineNet,
  }) {
    final List<_WalletStat> stats =
        <_WalletStat>[
      _WalletStat(
        title: 'Cash Net',
        value:
            'Rs. ${cashNet.toStringAsFixed(0)}',
        icon: Icons.payments_outlined,
      ),
      _WalletStat(
        title: 'Online Net',
        value:
            'Rs. ${onlineNet.toStringAsFixed(0)}',
        icon: Icons.account_balance_outlined,
      ),
      _WalletStat(
        title: 'Commission Due',
        value:
            'Rs. ${rider.outstandingCommission.toStringAsFixed(0)}',
        icon: Icons.percent,
      ),
      _WalletStat(
        title: 'Completed',
        value: '${rider.completedDeliveries}',
        icon: Icons.task_alt,
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
        childAspectRatio: 1.35,
      ),
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        final _WalletStat stat =
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
    final bool hasDue =
        rider.outstandingCommission > 0;

    final Color color = hasDue
        ? Colors.orangeAccent
        : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: color.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor:
                color.withValues(alpha: 0.14),
            child: Icon(
              hasDue
                  ? Icons.warning_amber_outlined
                  : Icons.check_circle_outline,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  hasDue
                      ? 'Commission payment due'
                      : 'Commission account clear',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasDue
                      ? 'Rs. ${rider.outstandingCommission.toStringAsFixed(0)} is pending from cash deliveries.'
                      : 'There is no outstanding cash-delivery commission.',
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

  Widget _buildFilterChips() {
    final List<_WalletFilterItem> items =
        <_WalletFilterItem>[
      const _WalletFilterItem(
        filter: _WalletFilter.all,
        label: 'All',
      ),
      const _WalletFilterItem(
        filter: _WalletFilter.cash,
        label: 'Cash',
      ),
      const _WalletFilterItem(
        filter: _WalletFilter.online,
        label: 'Online',
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
          final _WalletFilterItem item =
              items[index];

          final bool selected =
              _selectedFilter == item.filter;

          return ChoiceChip(
            label: Text(item.label),
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
            Icons.account_balance_wallet_outlined,
            color: yellow,
            size: 64,
          ),
          SizedBox(height: 14),
          Text(
            'No wallet activity',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Completed delivery earnings will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
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
              'Unable to load wallet',
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

class _WalletActivityCard extends StatelessWidget {
  const _WalletActivityCard({
    required this.order,
    required this.gross,
    required this.commission,
    required this.net,
    required this.isCashOrder,
    required this.onTap,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodOrderModel order;
  final double gross;
  final double commission;
  final double net;
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
    final Color paymentColor = isCashOrder
        ? Colors.orangeAccent
        : Colors.greenAccent;

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
                        paymentColor.withValues(
                      alpha: 0.14,
                    ),
                    child: Icon(
                      isCashOrder
                          ? Icons.payments_outlined
                          : Icons
                              .account_balance_outlined,
                      color: paymentColor,
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
                          paymentColor.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCashOrder
                          ? 'CASH'
                          : 'ONLINE',
                      style: TextStyle(
                        color: paymentColor,
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
                    child: _amount(
                      label: 'Gross',
                      value: gross,
                    ),
                  ),
                  Expanded(
                    child: _amount(
                      label: 'Commission',
                      value: commission,
                    ),
                  ),
                  Expanded(
                    child: _amount(
                      label: 'Net',
                      value: net,
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

  Widget _amount({
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

class _WalletStat {
  const _WalletStat({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
}

class _WalletFilterItem {
  const _WalletFilterItem({
    required this.filter,
    required this.label,
  });

  final _WalletFilter filter;
  final String label;
}
