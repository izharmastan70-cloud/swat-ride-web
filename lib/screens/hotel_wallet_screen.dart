import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HotelWalletScreen extends StatefulWidget {
  const HotelWalletScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelWalletScreen> createState() =>
      _HotelWalletScreenState();
}

class _HotelWalletScreenState
    extends State<HotelWalletScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  String _selectedFilter = 'all';
  bool _isWorking = false;

  CollectionReference<Map<String, dynamic>>
      get _transactionCollection => _firestore
          .collection('hotel_wallet_transactions');

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
          'Hotel Wallet',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _transactionCollection
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
                snapshot,
          ) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: yellow,
                ),
              );
            }

            if (snapshot.hasError) {
              return _messageState(
                icon: Icons.error_outline,
                title: 'Unable to Load Wallet',
                message: snapshot.error.toString(),
              );
            }

            final List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>
                documents = snapshot.data?.docs ??
                    <QueryDocumentSnapshot<
                        Map<String, dynamic>>>[];

            documents.sort(
              (a, b) => _readDateTime(
                b.data()['createdAt'],
              ).compareTo(
                _readDateTime(
                  a.data()['createdAt'],
                ),
              ),
            );

            final _WalletSummary summary =
                _calculateSummary(documents);

            final List<
                    QueryDocumentSnapshot<
                        Map<String, dynamic>>>
                filtered =
                _filterTransactions(documents);

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                28,
              ),
              children: [
                _balanceCard(summary),

                const SizedBox(height: 16),

                _quickActions(),

                const SizedBox(height: 18),

                _summaryGrid(summary),

                const SizedBox(height: 18),

                _billingNotice(),

                const SizedBox(height: 20),

                const Text(
                  'Wallet Activity',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                _filterChips(),

                const SizedBox(height: 14),

                if (filtered.isEmpty)
                  _messageState(
                    icon:
                        Icons.receipt_long_outlined,
                    title:
                        'No Wallet Transactions',
                    message:
                        'Booking earnings, commission deductions and payout records will appear here.',
                  )
                else
                  ...filtered.map(
                    _transactionCard,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _balanceCard(
    _WalletSummary summary,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: yellow.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: yellow,
              ),
              SizedBox(width: 9),
              Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Rs. ${summary.availableBalance.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            summary.availableBalance > 0
                ? 'Available for payout request'
                : 'No payout balance available',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isWorking
                ? null
                : _requestPayout,
            style: ElevatedButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(
                vertical: 14,
              ),
            ),
            icon: const Icon(
              Icons.account_balance_outlined,
            ),
            label: const Text(
              'Request Payout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isWorking
                ? null
                : _showSettlementInfo,
            style: OutlinedButton.styleFrom(
              foregroundColor: yellow,
              side: const BorderSide(
                color: yellow,
              ),
              padding:
                  const EdgeInsets.symmetric(
                vertical: 14,
              ),
            ),
            icon: const Icon(
              Icons.info_outline,
            ),
            label: const Text(
              'Settlement Info',
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryGrid(
    _WalletSummary summary,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _summaryCard(
          icon: Icons.payments_outlined,
          title: 'Gross Earnings',
          value:
              'Rs. ${summary.grossEarnings.toStringAsFixed(0)}',
        ),
        _summaryCard(
          icon: Icons.percent,
          title: 'Commission',
          value:
              'Rs. ${summary.commissionDeducted.toStringAsFixed(0)}',
        ),
        _summaryCard(
          icon: Icons.schedule,
          title: 'Pending',
          value:
              'Rs. ${summary.pendingAmount.toStringAsFixed(0)}',
        ),
        _summaryCard(
          icon: Icons.done_all,
          title: 'Paid Out',
          value:
              'Rs. ${summary.paidOut.toStringAsFixed(0)}',
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: yellow,
            size: 25,
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
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

  Widget _billingNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: yellow,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Wallet records and payout requests use Firestore. Real bank, JazzCash or Easypaisa settlement will be activated after payment and billing integration.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    const List<String> filters =
        <String>[
      'all',
      'earning',
      'commission',
      'payout',
      'pending',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map(
          (String filter) {
            final bool selected =
                _selectedFilter == filter;

            return Padding(
              padding:
                  const EdgeInsets.only(
                right: 8,
              ),
              child: ChoiceChip(
                selected: selected,
                label: Text(
                  _filterLabel(filter),
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
                    _selectedFilter =
                        filter;
                  });
                },
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _transactionCard(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    final String type =
        data['type']?.toString() ??
            'earning';

    final String title =
        data['title']?.toString() ??
            _defaultTitle(type);

    final String description =
        data['description']?.toString() ??
            '';

    final String status =
        data['status']?.toString() ??
            'completed';

    final double amount =
        _readNumber(data['amount']);

    final DateTime createdAt =
        _readDateTime(
      data['createdAt'],
    );

    final bool isDebit =
        type == 'commission' ||
            type == 'payout' ||
            type == 'adjustment_debit';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 11,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _transactionColor(type)
                  .withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              _transactionIcon(type),
              color:
                  _transactionColor(type),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight
                                  .bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '${isDebit ? '-' : '+'} Rs. ${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isDebit
                            ? Colors.redAccent
                            : Colors.green,
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (description
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style:
                        const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Row(
                  children: [
                    _statusBadge(status),
                    const Spacer(),
                    Text(
                      _formatDateTime(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    final Color color =
        status == 'completed'
            ? Colors.green
            : status == 'pending'
                ? Colors.orange
                : status == 'rejected'
                    ? Colors.red
                    : Colors.blueGrey;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.14,
        ),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _requestPayout() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in first.',
        isError: true,
      );
      return;
    }

    final TextEditingController
        amountController =
        TextEditingController();

    final TextEditingController
        accountController =
        TextEditingController();

    String method = 'bank';

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              backgroundColor: darkCard,
              title: const Text(
                'Request Payout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    TextField(
                      controller:
                          amountController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      style:
                          const TextStyle(
                        color: Colors.white,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Amount',
                        prefixText:
                            'Rs. ',
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    DropdownButtonFormField<
                        String>(
                      initialValue: method,
                      dropdownColor:
                          darkCard,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Payout method',
                      ),
                      items:
                          const <DropdownMenuItem<
                              String>>[
                        DropdownMenuItem(
                          value: 'bank',
                          child: Text(
                            'Bank Account',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'jazzcash',
                          child: Text(
                            'JazzCash',
                          ),
                        ),
                        DropdownMenuItem(
                          value:
                              'easypaisa',
                          child: Text(
                            'Easypaisa',
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(
                          () {
                            method = value;
                          },
                        );
                      },
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller:
                          accountController,
                      style:
                          const TextStyle(
                        color: Colors.white,
                      ),
                      decoration:
                          InputDecoration(
                        labelText:
                            method == 'bank'
                                ? 'Account / IBAN'
                                : 'Mobile number',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child:
                      const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      true,
                    );
                  },
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        yellow,
                    foregroundColor:
                        Colors.black,
                  ),
                  child:
                      const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      amountController.dispose();
      accountController.dispose();
      return;
    }

    final double? amount =
        double.tryParse(
      amountController.text.trim(),
    );

    final String account =
        accountController.text.trim();

    amountController.dispose();
    accountController.dispose();

    if (amount == null || amount <= 0) {
      _showMessage(
        'Enter a valid payout amount.',
        isError: true,
      );
      return;
    }

    if (account.isEmpty) {
      _showMessage(
        'Enter payout account details.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isWorking = true;
    });

    try {
      await _firestore
          .collection(
            'hotel_payout_requests',
          )
          .add(
        <String, dynamic>{
          'hotelId': widget.hotelId,
          'requestedBy': user.uid,
          'amount': amount,
          'method': method,
          'accountDetails': account,
          'status': 'pending',
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      await _transactionCollection.add(
        <String, dynamic>{
          'hotelId': widget.hotelId,
          'type': 'payout',
          'title': 'Payout Request',
          'description':
              'Requested through ${_methodLabel(method)}',
          'amount': amount,
          'status': 'pending',
          'createdBy': user.uid,
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      _showMessage(
        'Payout request submitted.',
      );
    } catch (error) {
      _showMessage(
        'Unable to submit payout request: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  void _showSettlementInfo() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Settlement Information',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Hotel earnings, commission deductions and payout requests are recorded in Firestore. Final bank or mobile-wallet settlement will be processed after payment integration is enabled.',
            style: TextStyle(
              color: Colors.grey,
              height: 1.45,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor:
                    Colors.black,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  List<QueryDocumentSnapshot<
          Map<String, dynamic>>>
      _filterTransactions(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        documents,
  ) {
    if (_selectedFilter == 'all') {
      return documents;
    }

    return documents.where(
      (document) {
        final Map<String, dynamic> data =
            document.data();

        final String type =
            data['type']?.toString() ??
                '';

        final String status =
            data['status']?.toString() ??
                '';

        if (_selectedFilter == 'pending') {
          return status == 'pending';
        }

        return type == _selectedFilter;
      },
    ).toList();
  }

  _WalletSummary _calculateSummary(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        documents,
  ) {
    double grossEarnings = 0;
    double commissionDeducted = 0;
    double pendingAmount = 0;
    double paidOut = 0;
    double availableBalance = 0;

    for (final document in documents) {
      final Map<String, dynamic> data =
          document.data();

      final String type =
          data['type']?.toString() ??
              'earning';

      final String status =
          data['status']?.toString() ??
              'completed';

      final double amount =
          _readNumber(data['amount']);

      if (type == 'earning') {
        grossEarnings += amount;

        if (status == 'completed') {
          availableBalance += amount;
        } else if (status == 'pending') {
          pendingAmount += amount;
        }
      } else if (type == 'commission') {
        commissionDeducted += amount;

        if (status == 'completed') {
          availableBalance -= amount;
        }
      } else if (type == 'payout') {
        if (status == 'completed') {
          paidOut += amount;
          availableBalance -= amount;
        } else if (status == 'pending') {
          pendingAmount += amount;
        }
      } else if (type ==
          'adjustment_credit') {
        if (status == 'completed') {
          availableBalance += amount;
        }
      } else if (type ==
          'adjustment_debit') {
        if (status == 'completed') {
          availableBalance -= amount;
        }
      }
    }

    if (availableBalance < 0) {
      availableBalance = 0;
    }

    return _WalletSummary(
      availableBalance:
          availableBalance,
      grossEarnings: grossEarnings,
      commissionDeducted:
          commissionDeducted,
      pendingAmount: pendingAmount,
      paidOut: paidOut,
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
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
            size: 46,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(
    String filter,
  ) {
    switch (filter) {
      case 'earning':
        return 'Earnings';
      case 'commission':
        return 'Commission';
      case 'payout':
        return 'Payouts';
      case 'pending':
        return 'Pending';
      default:
        return 'All';
    }
  }

  String _defaultTitle(
    String type,
  ) {
    switch (type) {
      case 'commission':
        return 'Commission Deduction';
      case 'payout':
        return 'Payout';
      case 'adjustment_credit':
        return 'Wallet Credit';
      case 'adjustment_debit':
        return 'Wallet Debit';
      default:
        return 'Hotel Earning';
    }
  }

  IconData _transactionIcon(
    String type,
  ) {
    switch (type) {
      case 'commission':
        return Icons.percent;
      case 'payout':
        return Icons.account_balance_outlined;
      case 'adjustment_credit':
        return Icons.add_circle_outline;
      case 'adjustment_debit':
        return Icons.remove_circle_outline;
      default:
        return Icons.payments_outlined;
    }
  }

  Color _transactionColor(
    String type,
  ) {
    switch (type) {
      case 'commission':
        return Colors.orange;
      case 'payout':
        return Colors.blue;
      case 'adjustment_debit':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  String _statusLabel(
    String status,
  ) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _methodLabel(
    String method,
  ) {
    switch (method) {
      case 'jazzcash':
        return 'JazzCash';
      case 'easypaisa':
        return 'Easypaisa';
      default:
        return 'Bank Account';
    }
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
          DateTime.fromMillisecondsSinceEpoch(
            0,
          );
    }

    return DateTime.fromMillisecondsSinceEpoch(
      0,
    );
  }

  String _formatDateTime(
    DateTime date,
  ) {
    if (date.millisecondsSinceEpoch == 0) {
      return '';
    }

    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    final String hour =
        date.hour.toString().padLeft(2, '0');

    final String minute =
        date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} $hour:$minute';
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : darkCard,
        ),
      );
  }
}

class _WalletSummary {
  const _WalletSummary({
    required this.availableBalance,
    required this.grossEarnings,
    required this.commissionDeducted,
    required this.pendingAmount,
    required this.paidOut,
  });

  final double availableBalance;
  final double grossEarnings;
  final double commissionDeducted;
  final double pendingAmount;
  final double paidOut;
}
