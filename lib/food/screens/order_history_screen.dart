// lib/food/screens/order_history_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Customer Food Order History Screen
//
// Connected with:
// - FirebaseAuth
// - Cloud Firestore
// - FoodOrderModel
//
// Firestore collection:
// food_orders
//
// Features:
// - Live customer order history
// - Active / Completed / Cancelled filters
// - Order totals and status
// - Order details navigation
// - Live tracking navigation for active orders
//
// Existing non-Food modules remain untouched.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../feedback/models/feedback_model.dart';
import '../../feedback/services/feedback_service.dart';

import '../models/food_order_model.dart';
import '../models/food_order_dispute_model.dart';
import '../services/food_order_dispute_service.dart';

enum _OrderHistoryFilter { all, active, completed, cancelled }

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FoodOrderDisputeService _disputeService = FoodOrderDisputeService();
  final FeedbackService _feedbackService = FeedbackService();

  final Map<String, Future<bool>> _restaurantReviewState =
      <String, Future<bool>>{};

  _OrderHistoryFilter _selectedFilter = _OrderHistoryFilter.all;

  String get _customerId {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Stream<List<FoodOrderModel>> _watchOrders() {
    if (_customerId.isEmpty) {
      return Stream<List<FoodOrderModel>>.value(const <FoodOrderModel>[]);
    }

    return _firestore
        .collection('food_orders')
        .where('customerId', isEqualTo: _customerId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<FoodOrderModel> orders = snapshot.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> document,
          ) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              document.data(),
            );

            data['orderId'] = document.id;

            return FoodOrderModel.fromMap(data);
          }).toList();

          orders.sort(
            (FoodOrderModel first, FoodOrderModel second) =>
                second.createdAt.compareTo(first.createdAt),
          );

          return orders;
        });
  }

  List<FoodOrderModel> _filterOrders(List<FoodOrderModel> orders) {
    switch (_selectedFilter) {
      case _OrderHistoryFilter.all:
        return orders;

      case _OrderHistoryFilter.active:
        return orders.where((FoodOrderModel order) {
          return order.status == FoodOrderStatus.pending ||
              order.status == FoodOrderStatus.accepted ||
              order.status == FoodOrderStatus.preparing ||
              order.status == FoodOrderStatus.readyForPickup ||
              order.status == FoodOrderStatus.pickedUp ||
              order.status == FoodOrderStatus.onTheWay;
        }).toList();

      case _OrderHistoryFilter.completed:
        return orders
            .where(
              (FoodOrderModel order) =>
                  order.status == FoodOrderStatus.delivered,
            )
            .toList();

      case _OrderHistoryFilter.cancelled:
        return orders
            .where(
              (FoodOrderModel order) =>
                  order.status == FoodOrderStatus.cancelled,
            )
            .toList();
    }
  }

  int _countForFilter(List<FoodOrderModel> orders, _OrderHistoryFilter filter) {
    switch (filter) {
      case _OrderHistoryFilter.all:
        return orders.length;

      case _OrderHistoryFilter.active:
        return orders.where((FoodOrderModel order) {
          return order.status == FoodOrderStatus.pending ||
              order.status == FoodOrderStatus.accepted ||
              order.status == FoodOrderStatus.preparing ||
              order.status == FoodOrderStatus.readyForPickup ||
              order.status == FoodOrderStatus.pickedUp ||
              order.status == FoodOrderStatus.onTheWay;
        }).length;

      case _OrderHistoryFilter.completed:
        return orders
            .where(
              (FoodOrderModel order) =>
                  order.status == FoodOrderStatus.delivered,
            )
            .length;

      case _OrderHistoryFilter.cancelled:
        return orders
            .where(
              (FoodOrderModel order) =>
                  order.status == FoodOrderStatus.cancelled,
            )
            .length;
    }
  }

  String _restaurantReviewCacheKey(FoodOrderModel order) {
    return '${_customerId.trim()}|${order.orderId}|${order.restaurantId.trim()}';
  }

  Future<bool> _hasRestaurantReview(FoodOrderModel order) {
    final String customerId = _customerId.trim();

    final String restaurantId = order.restaurantId.trim();

    if (customerId.isEmpty ||
        restaurantId.isEmpty ||
        order.status != FoodOrderStatus.delivered) {
      return Future<bool>.value(false);
    }

    final String cacheKey = _restaurantReviewCacheKey(order);

    return _restaurantReviewState.putIfAbsent(cacheKey, () async {
      try {
        return await _feedbackService.hasSubmittedFeedback(
          serviceType: FeedbackServiceType.food,
          sourceId: order.orderId,
          reviewerId: customerId,
          targetType: FeedbackTargetType.restaurant,
          targetId: restaurantId,
        );
      } catch (_) {
        return false;
      }
    });
  }

  Future<void> _openOrderDetails(FoodOrderModel order) async {
    await Navigator.pushNamed(
      context,
      '/food_customer_order_details',
      arguments: order,
    );

    _restaurantReviewState.remove(_restaurantReviewCacheKey(order));

    if (mounted) {
      setState(() {});
    }
  }

  void _openTracking(FoodOrderModel order) {
    Navigator.pushNamed(context, '/food_live_order_tracking', arguments: order);
  }

  bool _isActiveOrder(FoodOrderStatus status) {
    return status == FoodOrderStatus.pending ||
        status == FoodOrderStatus.accepted ||
        status == FoodOrderStatus.preparing ||
        status == FoodOrderStatus.readyForPickup ||
        status == FoodOrderStatus.pickedUp ||
        status == FoodOrderStatus.onTheWay;
  }

  bool _canReportIssue(FoodOrderStatus status) {
    return status == FoodOrderStatus.delivered ||
        status == FoodOrderStatus.cancelled;
  }

  Future<void> _showDisputeDialog(FoodOrderModel order) async {
    final String customerId = _customerId.trim();

    if (customerId.isEmpty) {
      _showDisputeMessage('Please log in before reporting an issue.');
      return;
    }

    final TextEditingController descriptionController = TextEditingController();

    final TextEditingController refundController = TextEditingController();

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('food_orders')
          .doc(order.orderId)
          .get();

      if (!mounted) {
        return;
      }

      final Map<String, dynamic>? data = snapshot.data();

      if (!snapshot.exists || data == null) {
        _showDisputeMessage('Food order details are unavailable.');
        return;
      }

      final String storedCustomerId =
          data['customerId']?.toString().trim() ?? '';

      if (storedCustomerId.isNotEmpty && storedCustomerId != customerId) {
        _showDisputeMessage('You cannot report an issue for this order.');
        return;
      }

      final String restaurantId = data['restaurantId']?.toString().trim() ?? '';

      final String riderId = data['riderId']?.toString().trim() ?? '';

      final double orderTotal = data['grandTotal'] is num
          ? (data['grandTotal'] as num).toDouble()
          : double.tryParse(data['grandTotal']?.toString() ?? '') ??
                order.grandTotal;

      if (orderTotal > 0) {
        refundController.text = orderTotal.toStringAsFixed(2);
      }

      FoodOrderDisputeReason selectedReason = FoodOrderDisputeReason.other;

      bool requestRefund = false;

      final bool? submit = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return AlertDialog(
                title: const Text('Report Food Order Issue'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      DropdownButtonFormField<FoodOrderDisputeReason>(
                        initialValue: selectedReason,
                        decoration: const InputDecoration(
                          labelText: 'Issue type',
                          border: OutlineInputBorder(),
                        ),
                        items: FoodOrderDisputeReason.values.map((
                          FoodOrderDisputeReason reason,
                        ) {
                          return DropdownMenuItem<FoodOrderDisputeReason>(
                            value: reason,
                            child: Text(reason.label),
                          );
                        }).toList(),
                        onChanged: (FoodOrderDisputeReason? value) {
                          if (value == null) {
                            return;
                          }

                          setDialogState(() {
                            selectedReason = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Describe the issue',
                          hintText: 'Tell us what went wrong',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Request refund'),
                        subtitle: const Text(
                          'Food Admin will review this request before any refund.',
                        ),
                        value: requestRefund,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            requestRefund = value ?? false;
                          });
                        },
                      ),
                      if (requestRefund)
                        TextField(
                          controller: refundController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Requested refund amount',
                            prefixText: 'Rs ',
                            helperText: orderTotal > 0
                                ? 'Maximum Rs ${orderTotal.toStringAsFixed(2)}'
                                : null,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final String description = descriptionController.text
                          .trim();

                      if (description.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Please describe the issue.'),
                          ),
                        );
                        return;
                      }

                      if (requestRefund) {
                        final double amount =
                            double.tryParse(refundController.text.trim()) ?? 0;

                        if (amount <= 0) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Enter a valid refund amount.'),
                            ),
                          );
                          return;
                        }

                        if (orderTotal > 0 && amount > orderTotal) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Refund cannot exceed Rs ${orderTotal.toStringAsFixed(2)}.',
                              ),
                            ),
                          );
                          return;
                        }
                      }

                      Navigator.pop(dialogContext, true);
                    },
                    child: const Text('Submit'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (submit != true || !mounted) {
        return;
      }

      final String description = descriptionController.text.trim();

      final double requestedRefundAmount = requestRefund
          ? double.tryParse(refundController.text.trim()) ?? 0
          : 0;

      await _disputeService.createDispute(
        orderId: order.orderId,
        customerId: customerId,
        restaurantId: restaurantId,
        riderId: riderId,
        raisedBy: FoodOrderDisputeRaisedBy.customer,
        raisedById: customerId,
        reason: selectedReason,
        description: description,
        refundRequested: requestRefund,
        requestedRefundAmount: requestedRefundAmount,
      );

      if (!mounted) {
        return;
      }

      _showDisputeMessage(
        'Issue submitted. Food Admin will review your dispute.',
      );
    } on StateError catch (error) {
      if (mounted) {
        _showDisputeMessage(error.message.toString());
      }
    } catch (error) {
      if (mounted) {
        _showDisputeMessage('Unable to submit issue: $error');
      }
    } finally {
      descriptionController.dispose();
      refundController.dispose();
    }
  }

  void _showDisputeMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: const Text(
          'Food Order History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<FoodOrderModel>>(
          stream: _watchOrders(),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<FoodOrderModel>> snapshot,
              ) {
                if (_customerId.isEmpty) {
                  return _buildLoginRequired();
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: yellow),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final List<FoodOrderModel> allOrders =
                    snapshot.data ?? const <FoodOrderModel>[];

                final List<FoodOrderModel> visibleOrders = _filterOrders(
                  allOrders,
                );

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
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  30,
                                ),
                                itemCount: visibleOrders.length,
                                separatorBuilder:
                                    (BuildContext context, int index) =>
                                        const SizedBox(height: 12),
                                itemBuilder: (BuildContext context, int index) {
                                  final FoodOrderModel order =
                                      visibleOrders[index];

                                  return _buildOrderHistoryCard(order);
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

  _OrderHistoryCard _createOrderHistoryCard(
    FoodOrderModel order, {
    VoidCallback? onRate,
  }) {
    return _OrderHistoryCard(
      order: order,
      onTap: () {
        _openOrderDetails(order);
      },
      onRate: onRate,
      onTrack: _isActiveOrder(order.status) ? () => _openTracking(order) : null,
      onReport: _canReportIssue(order.status)
          ? () => _showDisputeDialog(order)
          : null,
    );
  }

  Widget _buildOrderHistoryCard(FoodOrderModel order) {
    final bool shouldOfferRate =
        order.status == FoodOrderStatus.delivered &&
        order.ratingPromptDismissed &&
        order.restaurantId.trim().isNotEmpty &&
        _customerId.trim().isNotEmpty;

    if (!shouldOfferRate) {
      return _createOrderHistoryCard(order);
    }

    return FutureBuilder<bool>(
      future: _hasRestaurantReview(order),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        final bool waiting =
            snapshot.connectionState == ConnectionState.waiting;

        final bool alreadyReviewed = snapshot.data ?? false;

        return _createOrderHistoryCard(
          order,
          onRate: waiting || alreadyReviewed
              ? null
              : () {
                  _openOrderDetails(order);
                },
        );
      },
    );
  }

  Widget _buildSummaryCard(List<FoodOrderModel> orders) {
    final int completed = _countForFilter(
      orders,
      _OrderHistoryFilter.completed,
    );

    final int active = _countForFilter(orders, _OrderHistoryFilter.active);

    final double completedSpend = orders
        .where(
          (FoodOrderModel order) => order.status == FoodOrderStatus.delivered,
        )
        .fold<double>(
          0,
          (double total, FoodOrderModel order) => total + order.grandTotal,
        );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
            child: Icon(Icons.receipt_long_outlined, color: yellow, size: 31),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Your Food Orders',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$active active ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ $completed completed',
                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  'Completed spend: Rs. ${completedSpend.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.black87, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(List<FoodOrderModel> orders) {
    final List<_FilterItem> filters = <_FilterItem>[
      _FilterItem(filter: _OrderHistoryFilter.all, label: 'All'),
      _FilterItem(filter: _OrderHistoryFilter.active, label: 'Active'),
      _FilterItem(filter: _OrderHistoryFilter.completed, label: 'Completed'),
      _FilterItem(filter: _OrderHistoryFilter.cancelled, label: 'Cancelled'),
    ];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final _FilterItem item = filters[index];

          final bool selected = _selectedFilter == item.filter;

          final int count = _countForFilter(orders, item.filter);

          return ChoiceChip(
            label: Text('${item.label} ($count)'),
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
              color: selected ? Colors.black : Colors.white,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.receipt_long_outlined, color: yellow, size: 76),
            SizedBox(height: 16),
            Text(
              'No food orders found',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Orders matching this filter will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.login, color: yellow, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Login required',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please log in to view your food order history.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.cloud_off, color: Colors.redAccent, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Unable to load orders',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.4),
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

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({
    required this.order,
    required this.onTap,
    required this.onRate,
    required this.onTrack,
    required this.onReport,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodOrderModel order;
  final VoidCallback onTap;
  final VoidCallback? onRate;
  final VoidCallback? onTrack;
  final VoidCallback? onReport;

  String get _shortOrderId {
    if (order.orderId.length <= 8) {
      return order.orderId;
    }

    return order.orderId.substring(0, 8);
  }

  String get _statusText {
    switch (order.status) {
      case FoodOrderStatus.pending:
        return 'Pending';
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

  Color get _statusColor {
    switch (order.status) {
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

  String get _dateText {
    final DateTime value = order.createdAt;

    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year} ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ $hour:$minute';
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: _statusColor.withValues(alpha: 0.14),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: _statusColor,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Order #$_shortOrderId',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _statusText,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                '${order.items.length} item(s)',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 5),
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
                  Text(
                    'Rs. ${order.grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: yellow,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (onRate != null)
                    TextButton.icon(
                      onPressed: onRate,
                      icon: const Icon(Icons.star_rounded, color: yellow),
                      label: const Text(
                        'Rate',
                        style: TextStyle(
                          color: yellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (onRate != null && (onReport != null || onTrack != null))
                    const SizedBox(width: 4),
                  if (onReport != null)
                    TextButton.icon(
                      onPressed: onReport,
                      icon: const Icon(
                        Icons.report_problem_outlined,
                        color: Colors.orangeAccent,
                      ),
                      label: const Text(
                        'Report Issue',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (onReport != null && onTrack != null)
                    const SizedBox(width: 4),
                  if (onTrack != null)
                    TextButton.icon(
                      onPressed: onTrack,
                      icon: const Icon(Icons.route, color: yellow),
                      label: const Text(
                        'Track',
                        style: TextStyle(
                          color: yellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterItem {
  const _FilterItem({required this.filter, required this.label});

  final _OrderHistoryFilter filter;
  final String label;
}
