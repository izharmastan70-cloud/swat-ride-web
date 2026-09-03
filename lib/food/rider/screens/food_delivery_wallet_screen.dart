// lib/food/rider/screens/food_delivery_wallet_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Food Delivery Rider Wallet Screen
//
// Features:
// - Live wallet balance
// - Available withdrawal amount
// - Outstanding cash-order commission
// - Total commission paid
// - Settlement history with status
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/food_delivery_rider_model.dart';
import '../services/food_delivery_rider_service.dart';

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

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;
  final FoodDeliveryRiderService _riderService =
      FoodDeliveryRiderService();

  FoodDeliveryRiderModel get initialRider => widget.rider;

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchSettlements(
    String riderId,
  ) {
    return _firestore
        .collection('food_rider_settlements')
        .where('riderId', isEqualTo: riderId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Food Rider Wallet',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<FoodDeliveryRiderModel?>(
        stream: _riderService.watchRiderById(initialRider.riderId),
        initialData: initialRider,
        builder: (
          BuildContext context,
          AsyncSnapshot<FoodDeliveryRiderModel?> snapshot,
        ) {
          final FoodDeliveryRiderModel rider =
              snapshot.data ?? initialRider;

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load Food rider wallet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            children: <Widget>[
              _header(rider),
              const SizedBox(height: 16),
              _stats(rider),
              const SizedBox(height: 16),
              _commissionNotice(rider),
              const SizedBox(height: 20),
              const Text(
                'Settlement History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _history(rider),
            ],
          );
        },
      ),
    );
  }

  double _availableWithdrawAmount(
    FoodDeliveryRiderModel rider,
  ) {
    return (rider.walletBalance -
            rider.outstandingCommission)
        .clamp(0, double.infinity)
        .toDouble();
  }

  Widget _header(FoodDeliveryRiderModel rider) {
    final double availableWithdraw =
        _availableWithdrawAmount(rider);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.account_balance_wallet, color: Colors.black),
              SizedBox(width: 10),
              Text(
                'Available Wallet Balance',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Rs. ${rider.walletBalance.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Available to withdraw: Rs. ${availableWithdraw.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Available withdrawal excludes outstanding cash-order commission.',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stats(FoodDeliveryRiderModel rider) {
    final double availableWithdraw =
        _availableWithdrawAmount(rider);

    final List<_WalletStat> values = <_WalletStat>[
      _WalletStat(
        'Lifetime Earnings',
        'Rs. ${rider.totalEarnings.toStringAsFixed(0)}',
        Icons.trending_up,
      ),
      _WalletStat(
        'Available Withdraw',
        'Rs. ${availableWithdraw.toStringAsFixed(0)}',
        Icons.account_balance_outlined,
      ),
      _WalletStat(
        'Outstanding Commission',
        'Rs. ${rider.outstandingCommission.toStringAsFixed(0)}',
        Icons.warning_amber_outlined,
      ),
      _WalletStat(
        'Commission Paid',
        'Rs. ${rider.totalCommissionPaid.toStringAsFixed(0)}',
        Icons.verified_outlined,
      ),
      _WalletStat(
        'Commission Rate',
        '${rider.commissionPercentage.toStringAsFixed(0)}%',
        Icons.percent,
      ),
      _WalletStat(
        'Completed Deliveries',
        '${rider.completedDeliveries}',
        Icons.task_alt,
      ),
    ];

    return GridView.builder(
      itemCount: values.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.20,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _WalletStat value = values[index];
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Icon(value.icon, color: yellow),
              Text(
                value.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value.title,
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

  Widget _commissionNotice(FoodDeliveryRiderModel rider) {
    final bool pending = rider.outstandingCommission > 0;
    final Color color =
        pending ? Colors.orangeAccent : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(alpha: 0.45),
        ),
      ),
      child: Text(
        pending
            ? 'Cash-order commission of Rs. '
                '${rider.outstandingCommission.toStringAsFixed(0)} '
                'is pending. Available withdrawal is reduced until settlement. '
                'Total paid commission: Rs. '
                '${rider.totalCommissionPaid.toStringAsFixed(0)}.'
            : 'No outstanding Food commission is pending. '
                'Total commission paid: Rs. '
                '${rider.totalCommissionPaid.toStringAsFixed(0)}.',
        style: TextStyle(
          color: color,
          fontSize: 12,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _history(FoodDeliveryRiderModel rider) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _watchSettlements(rider.riderId),
      builder: (
        BuildContext context,
        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
            snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: yellow),
            ),
          );
        }

        if (snapshot.hasError) {
          return _message('Unable to load settlement history.');
        }

        final List<QueryDocumentSnapshot<Map<String, dynamic>>>
            documents = snapshot.data?.docs.toList() ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        documents.sort(
          (
            QueryDocumentSnapshot<Map<String, dynamic>> first,
            QueryDocumentSnapshot<Map<String, dynamic>> second,
          ) =>
              _date(second.data()['createdAt'])
                  .compareTo(_date(first.data()['createdAt'])),
        );

        if (documents.isEmpty) {
          return _message('No Food rider settlements recorded yet.');
        }

        return Column(
          children: documents.map(
            (
              QueryDocumentSnapshot<Map<String, dynamic>>
                  document,
            ) {
              final Map<String, dynamic> data = document.data();
              final double amount = _number(data['amount']);
              final DateTime date = _date(data['createdAt']);
              final String status =
                  data['status']?.toString().trim().toLowerCase() ??
                      'paid';

              final bool isPaid =
                  status == 'paid' ||
                      status == 'completed' ||
                      status == 'settled';

              final bool isRejected =
                  status == 'rejected';

              final Color statusColor = isPaid
                  ? Colors.greenAccent
                  : isRejected
                      ? Colors.redAccent
                      : Colors.orangeAccent;

              final String statusText = isPaid
                  ? 'Paid'
                  : isRejected
                      ? 'Rejected'
                      : 'Pending';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.payments_outlined, color: yellow),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Rs. ${amount.toStringAsFixed(0)} • $statusText',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day.toString().padLeft(2, '0')}-'
                            '${date.month.toString().padLeft(2, '0')}-'
                            '${date.year}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isPaid
                          ? Icons.check_circle
                          : isRejected
                              ? Icons.cancel
                              : Icons.schedule,
                      color: statusColor,
                    ),
                  ],
                ),
              );
            },
          ).toList(),
        );
      },
    );
  }

  Widget _message(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  static double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _date(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    try {
      final dynamic converted = value.toDate();
      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {}
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _WalletStat {
  const _WalletStat(this.title, this.value, this.icon);

  final String title;
  final String value;
  final IconData icon;
}
