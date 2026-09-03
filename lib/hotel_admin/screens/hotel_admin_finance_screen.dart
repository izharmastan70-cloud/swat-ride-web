import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HotelAdminFinanceScreen extends StatefulWidget {
  const HotelAdminFinanceScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelAdminFinanceScreen> createState() =>
      _HotelAdminFinanceScreenState();
}

class _HotelAdminFinanceScreenState
    extends State<HotelAdminFinanceScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String _selectedPeriod = 'month';

  DateTime get _now => DateTime.now();

  DateTime get _periodStart {
    switch (_selectedPeriod) {
      case 'today':
        return DateTime(
          _now.year,
          _now.month,
          _now.day,
        );
      case 'week':
        return DateTime(
          _now.year,
          _now.month,
          _now.day,
        ).subtract(
          Duration(
            days: _now.weekday - 1,
          ),
        );
      default:
        return DateTime(
          _now.year,
          _now.month,
          1,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Hotel Finance & Payments',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('hotel_bookings')
              .where(
                'hotelId',
                isEqualTo: widget.hotelId,
              )
              .snapshots(),
          builder: (
            context,
            AsyncSnapshot<
                    QuerySnapshot<
                        Map<String, dynamic>>>
                bookingSnapshot,
          ) {
            if (bookingSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: yellow,
                ),
              );
            }

            if (bookingSnapshot.hasError) {
              return _messageState(
                icon: Icons.error_outline,
                title:
                    'Unable to Load Finance Data',
                message:
                    bookingSnapshot.error.toString(),
              );
            }

            final bookings =
                bookingSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            final summary =
                _buildSummary(bookings);

            return RefreshIndicator(
              color: yellow,
              backgroundColor: darkCard,
              onRefresh: () async {
                await _firestore
                    .collection('hotel_bookings')
                    .where(
                      'hotelId',
                      isEqualTo:
                          widget.hotelId,
                    )
                    .get();
              },
              child: ListView(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  30,
                ),
                children: [
                  _periodSelector(),
                  const SizedBox(height: 16),
                  _financeOverview(summary),
                  const SizedBox(height: 18),
                  _commissionCard(summary),
                  const SizedBox(height: 18),
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _transactionsList(),
                  const SizedBox(height: 16),
                  _bypassNotice(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _periodSelector() {
    const periods = <String>[
      'today',
      'week',
      'month',
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        children: periods.map(
          (period) {
            final selected =
                _selectedPeriod == period;

            return Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                child: ChoiceChip(
                  selected: selected,
                  label: Text(
                    _periodLabel(period),
                  ),
                  selectedColor:
                      yellow.withValues(
                    alpha: 0.25,
                  ),
                  checkmarkColor: yellow,
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.grey,
                    fontWeight:
                        FontWeight.bold,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedPeriod =
                          period;
                    });
                  },
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  _FinanceSummary _buildSummary(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        bookings,
  ) {
    double grossRevenue = 0;
    double cashRevenue = 0;
    double onlineRevenue = 0;
    double pendingAmount = 0;
    double refundedAmount = 0;
    double adminCommission = 0;
    double hotelReceivable = 0;
    int completedBookings = 0;

    for (final booking in bookings) {
      final data = booking.data();

      final createdAt = _readDateTime(
        data['createdAt'],
      );

      if (createdAt.isBefore(_periodStart)) {
        continue;
      }

      final status =
          data['bookingStatus']?.toString() ??
              '';

      final paymentStatus =
          data['paymentStatus']?.toString() ??
              '';

      final paymentMethod =
          data['paymentMethod']?.toString() ??
              'Cash';

      final total =
          _readNumber(data['totalAmount']);

      final commission =
          _readNumber(
        data['adminCommissionAmount'],
      );

      final refund =
          _readNumber(
        data['refundAmount'],
      );

      if (status == 'completed' ||
          status == 'checked_out' ||
          status == 'confirmed' ||
          status == 'checked_in' ||
          status == 'active') {
        grossRevenue += total;
      }

      if (paymentMethod == 'Cash') {
        cashRevenue += total;
      } else {
        onlineRevenue += total;
      }

      if (paymentStatus == 'cash_pending' ||
          paymentStatus == 'pending' ||
          paymentStatus ==
              'testing_bypassed') {
        pendingAmount += total;
      }

      if (refund > 0) {
        refundedAmount += refund;
      }

      adminCommission += commission;

      if (status == 'completed' ||
          status == 'checked_out') {
        completedBookings++;
      }
    }

    hotelReceivable =
        grossRevenue - adminCommission - refundedAmount;

    if (hotelReceivable < 0) {
      hotelReceivable = 0;
    }

    return _FinanceSummary(
      grossRevenue: grossRevenue,
      cashRevenue: cashRevenue,
      onlineRevenue: onlineRevenue,
      pendingAmount: pendingAmount,
      refundedAmount: refundedAmount,
      adminCommission: adminCommission,
      hotelReceivable: hotelReceivable,
      completedBookings: completedBookings,
    );
  }

  Widget _financeOverview(
    _FinanceSummary summary,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _metricCard(
          title: 'Gross Revenue',
          value:
              'PKR ${_formatMoney(summary.grossRevenue)}',
          icon:
              Icons.account_balance_wallet_outlined,
          color: Colors.green,
        ),
        _metricCard(
          title: 'Cash',
          value:
              'PKR ${_formatMoney(summary.cashRevenue)}',
          icon: Icons.payments_outlined,
          color: Colors.blue,
        ),
        _metricCard(
          title: 'Online',
          value:
              'PKR ${_formatMoney(summary.onlineRevenue)}',
          icon:
              Icons.credit_card_outlined,
          color: Colors.purple,
        ),
        _metricCard(
          title: 'Pending',
          value:
              'PKR ${_formatMoney(summary.pendingAmount)}',
          icon:
              Icons.pending_actions_outlined,
          color: Colors.orange,
        ),
        _metricCard(
          title: 'Refunded',
          value:
              'PKR ${_formatMoney(summary.refundedAmount)}',
          icon:
              Icons.currency_exchange_outlined,
          color: Colors.redAccent,
        ),
        _metricCard(
          title: 'Completed',
          value:
              '${summary.completedBookings}',
          icon: Icons.task_alt,
          color: yellow,
        ),
      ],
    );
  }

  Widget _commissionCard(
    _FinanceSummary summary,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.percent_outlined,
                color: yellow,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Commission & Settlement Summary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _detailRow(
            'Gross Revenue',
            'PKR ${_formatMoney(summary.grossRevenue)}',
          ),
          _detailRow(
            'Admin Commission',
            'PKR ${_formatMoney(summary.adminCommission)}',
          ),
          _detailRow(
            'Refunds',
            'PKR ${_formatMoney(summary.refundedAmount)}',
          ),
          const Divider(
            color: Colors.white12,
          ),
          _detailRow(
            'Hotel Receivable',
            'PKR ${_formatMoney(summary.hotelReceivable)}',
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _transactionsList() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection(
            'hotel_wallet_transactions',
          )
          .where(
            'hotelId',
            isEqualTo: widget.hotelId,
          )
          .snapshots(),
      builder: (
        context,
        AsyncSnapshot<
                QuerySnapshot<Map<String, dynamic>>>
            snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: yellow,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _messageState(
            icon: Icons.error_outline,
            title:
                'Unable to Load Transactions',
            message:
                snapshot.error.toString(),
          );
        }

        final transactions =
            snapshot.data?.docs ??
                <QueryDocumentSnapshot<
                    Map<String, dynamic>>>[];

        transactions.sort(
          (a, b) => _readDateTime(
            b.data()['createdAt'],
          ).compareTo(
            _readDateTime(
              a.data()['createdAt'],
            ),
          ),
        );

        final filtered = transactions.where(
          (transaction) {
            final createdAt = _readDateTime(
              transaction
                  .data()['createdAt'],
            );

            return !createdAt
                .isBefore(_periodStart);
          },
        ).take(20).toList();

        if (filtered.isEmpty) {
          return _messageState(
            icon:
                Icons.receipt_long_outlined,
            title: 'No Transactions',
            message:
                'Finance transactions for this period will appear here.',
          );
        }

        return Column(
          children: filtered.map(
            (transaction) {
              final data =
                  transaction.data();

              final type =
                  data['type']?.toString() ??
                      'payment';

              final status =
                  data['status']?.toString() ??
                      'pending';

              final amount =
                  _readNumber(
                data['amount'],
              );

              final method =
                  data['paymentMethod']
                          ?.toString() ??
                      'Not set';

              final createdAt =
                  _readDateTime(
                data['createdAt'],
              );

              return Container(
                margin:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration:
                          BoxDecoration(
                        color: yellow
                            .withValues(
                          alpha: 0.11,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .account_balance_wallet_outlined,
                        color: yellow,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            _label(type),
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            '$method • ${_label(status)}',
                            style:
                                const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            _formatDate(
                              createdAt,
                            ),
                            style:
                                const TextStyle(
                              color: Colors.grey,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'PKR ${_formatMoney(amount)}',
                      style: const TextStyle(
                        color: yellow,
                        fontWeight:
                            FontWeight.bold,
                      ),
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

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String title,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: highlight
                    ? Colors.white
                    : Colors.grey,
                fontWeight: highlight
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color:
                  highlight ? yellow : Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bypassNotice() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: yellow,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Finance summaries and transaction records are active. Real JazzCash, Easypaisa, wallet transfers, refunds and automatic commission settlement remain bypassed until payment integration is enabled.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: yellow,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel(
    String period,
  ) {
    switch (period) {
      case 'today':
        return 'Today';
      case 'week':
        return 'This Week';
      default:
        return 'This Month';
    }
  }

  String _label(
    String value,
  ) {
    if (value.isEmpty) {
      return value;
    }

    final clean =
        value.replaceAll('_', ' ');

    return clean
        .split(' ')
        .map(
          (part) => part.isEmpty
              ? part
              : part[0].toUpperCase() +
                  part.substring(1),
        )
        .join(' ');
  }

  double _readNumber(
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

  DateTime _readDateTime(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(
    DateTime value,
  ) {
    if (value.millisecondsSinceEpoch == 0) {
      return 'Not available';
    }

    final day =
        value.day.toString().padLeft(2, '0');

    final month =
        value.month.toString().padLeft(2, '0');

    return '$day/$month/${value.year}';
  }

  String _formatMoney(
    double amount,
  ) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }
}

class _FinanceSummary {
  const _FinanceSummary({
    required this.grossRevenue,
    required this.cashRevenue,
    required this.onlineRevenue,
    required this.pendingAmount,
    required this.refundedAmount,
    required this.adminCommission,
    required this.hotelReceivable,
    required this.completedBookings,
  });

  final double grossRevenue;
  final double cashRevenue;
  final double onlineRevenue;
  final double pendingAmount;
  final double refundedAmount;
  final double adminCommission;
  final double hotelReceivable;
  final int completedBookings;
}
