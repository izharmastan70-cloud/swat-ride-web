// lib/food/admin/screens/food_order_management_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Admin Food Order Management Screen
//
// Connected with:
// - Cloud Firestore
// - FoodOrderModel
//
// Real features:
// - Live Firestore food orders
// - Search by order/customer/restaurant/rider/address
// - All / Active / Delivered / Cancelled filters
// - Order details bottom sheet
// - Manual status updates
// - Rider assignment visibility
// - Payment and price summary
// - Admin cancellation with reason
//
// Existing non-Food modules remain untouched.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/food_order_model.dart';
import '../../services/food_order_service.dart';
import '../../rider/models/food_delivery_rider_model.dart';

enum _FoodOrderAdminFilter { all, active, delivered, cancelled }

class FoodOrderManagementScreen extends StatefulWidget {
  const FoodOrderManagementScreen({super.key});

  @override
  State<FoodOrderManagementScreen> createState() =>
      _FoodOrderManagementScreenState();
}

class _FoodOrderManagementScreenState extends State<FoodOrderManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  static const String collectionName = 'food_orders';
  static const String ridersCollectionName = 'food_delivery_riders';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FoodOrderService _orderService = FoodOrderService();

  final TextEditingController _searchController = TextEditingController();

  _FoodOrderAdminFilter _selectedFilter = _FoodOrderAdminFilter.all;

  String _searchText = '';
  bool _isUpdating = false;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection(collectionName);

  CollectionReference<Map<String, dynamic>> get _ridersRef =>
      _firestore.collection(ridersCollectionName);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<FoodOrderModel>> _watchOrders() {
    return _ordersRef.snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
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

  bool _isActiveStatus(FoodOrderStatus status) {
    return status == FoodOrderStatus.pending ||
        status == FoodOrderStatus.accepted ||
        status == FoodOrderStatus.preparing ||
        status == FoodOrderStatus.readyForPickup ||
        status == FoodOrderStatus.pickedUp ||
        status == FoodOrderStatus.onTheWay;
  }

  List<FoodOrderModel> _filterOrders(List<FoodOrderModel> orders) {
    final String query = _searchText.trim().toLowerCase();

    return orders.where((FoodOrderModel order) {
      final bool statusMatches;

      switch (_selectedFilter) {
        case _FoodOrderAdminFilter.all:
          statusMatches = true;
          break;
        case _FoodOrderAdminFilter.active:
          statusMatches = _isActiveStatus(order.status);
          break;
        case _FoodOrderAdminFilter.delivered:
          statusMatches = order.status == FoodOrderStatus.delivered;
          break;
        case _FoodOrderAdminFilter.cancelled:
          statusMatches = order.status == FoodOrderStatus.cancelled;
          break;
      }

      if (!statusMatches) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final String searchable = <String>[
        order.orderId,
        order.customerId,
        order.restaurantId,
        order.riderId,
        order.deliveryAddress.fullAddress,
        order.status.name,
        order.paymentMethod.name,
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  int _countForFilter(
    List<FoodOrderModel> orders,
    _FoodOrderAdminFilter filter,
  ) {
    switch (filter) {
      case _FoodOrderAdminFilter.all:
        return orders.length;
      case _FoodOrderAdminFilter.active:
        return orders
            .where((FoodOrderModel order) => _isActiveStatus(order.status))
            .length;
      case _FoodOrderAdminFilter.delivered:
        return orders
            .where(
              (FoodOrderModel order) =>
                  order.status == FoodOrderStatus.delivered,
            )
            .length;
      case _FoodOrderAdminFilter.cancelled:
        return orders
            .where(
              (FoodOrderModel order) =>
                  order.status == FoodOrderStatus.cancelled,
            )
            .length;
    }
  }

  double _deliveredRevenue(List<FoodOrderModel> orders) {
    return orders
        .where(
          (FoodOrderModel order) => order.status == FoodOrderStatus.delivered,
        )
        .fold<double>(
          0,
          (double total, FoodOrderModel order) => total + order.grandTotal,
        );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updateOrderStatus({
    required FoodOrderModel order,
    required FoodOrderStatus status,
    String reason = '',
  }) async {
    if (_isUpdating) {
      return;
    }

    if (order.status == FoodOrderStatus.delivered ||
        order.status == FoodOrderStatus.cancelled) {
      _showMessage('Completed or cancelled orders cannot be changed.');
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      switch (status) {
        case FoodOrderStatus.pending:
          throw const FoodOrderServiceException(
            message: 'An order cannot be moved back to Pending.',
          );

        case FoodOrderStatus.accepted:
          if (order.status != FoodOrderStatus.pending) {
            throw const FoodOrderServiceException(
              message: 'Only a pending order can be accepted.',
            );
          }

          await _orderService.acceptOrder(
            orderId: order.orderId,
            estimatedPreparationMinutes: 25,
          );
          break;

        case FoodOrderStatus.preparing:
          if (order.status != FoodOrderStatus.accepted) {
            throw const FoodOrderServiceException(
              message: 'Order must be accepted before preparation starts.',
            );
          }

          await _orderService.startPreparing(order.orderId);
          break;

        case FoodOrderStatus.readyForPickup:
          if (order.status != FoodOrderStatus.preparing) {
            throw const FoodOrderServiceException(
              message: 'Order must be preparing before it becomes ready.',
            );
          }

          await _orderService.markReadyForPickup(order.orderId);
          break;

        case FoodOrderStatus.pickedUp:
        case FoodOrderStatus.onTheWay:
          throw const FoodOrderServiceException(
            message:
                'Pickup and On The Way must be updated by the assigned rider.',
          );

        case FoodOrderStatus.delivered:
          throw const FoodOrderServiceException(
            message:
                'Delivery must be completed by the rider using the customer OTP. This protects rider and restaurant commission settlement.',
          );

        case FoodOrderStatus.cancelled:
          if (reason.trim().isEmpty) {
            throw const FoodOrderServiceException(
              message: 'Admin cancellation reason is required.',
            );
          }

          await _orderService.cancelOrder(
            orderId: order.orderId,
            cancelledBy: 'admin',
            reason: reason.trim(),
          );
          break;
      }

      _showMessage('Food order updated to ${_statusText(status)}.');
    } on FoodOrderServiceException catch (error) {
      _showMessage(error.message);
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'Unable to update Food order.');
    } catch (error) {
      _showMessage('Unable to update Food order: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _cancelOrder(FoodOrderModel order) async {
    if (order.status == FoodOrderStatus.delivered ||
        order.status == FoodOrderStatus.cancelled) {
      _showMessage('This order cannot be cancelled.');
      return;
    }

    final TextEditingController controller = TextEditingController();

    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Cancel Food Order'),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Cancellation reason',
              hintText: 'Enter why admin is cancelling this order',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () {
                final String value = controller.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext, value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Order'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason == null) {
      return;
    }

    await _updateOrderStatus(
      order: order,
      status: FoodOrderStatus.cancelled,
      reason: reason,
    );
  }

  Future<void> _showStatusUpdateDialog(FoodOrderModel order) async {
    FoodOrderStatus selectedStatus = order.status;

    final FoodOrderStatus? result = await showDialog<FoodOrderStatus>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder:
              (
                BuildContext context,
                void Function(void Function()) setDialogState,
              ) {
                return AlertDialog(
                  backgroundColor: cardColor,
                  title: const Text('Update Order Status'),
                  content: DropdownButtonFormField<FoodOrderStatus>(
                    initialValue: selectedStatus,
                    dropdownColor: const Color(0xFF252525),
                    decoration: const InputDecoration(
                      labelText: 'Order status',
                      border: OutlineInputBorder(),
                    ),
                    items: FoodOrderStatus.values
                        .map(
                          (FoodOrderStatus status) =>
                              DropdownMenuItem<FoodOrderStatus>(
                                value: status,
                                child: Text(_statusText(status)),
                              ),
                        )
                        .toList(),
                    onChanged: (FoodOrderStatus? value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, selectedStatus);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: yellow,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Update'),
                    ),
                  ],
                );
              },
        );
      },
    );

    if (result == null || result == order.status) {
      return;
    }

    if (result == FoodOrderStatus.cancelled) {
      await _cancelOrder(order);
      return;
    }

    await _updateOrderStatus(order: order, status: result);
  }

  Future<List<FoodDeliveryRiderModel>> _loadAssignableRiders() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _ridersRef
        .where('status', isEqualTo: FoodDeliveryRiderStatus.approved.value)
        .where('isApproved', isEqualTo: true)
        .where('isSuspended', isEqualTo: false)
        .get();

    final List<FoodDeliveryRiderModel> riders = snapshot.docs.map((
      QueryDocumentSnapshot<Map<String, dynamic>> document,
    ) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        document.data(),
      );

      data['riderId'] = document.id;

      return FoodDeliveryRiderModel.fromMap(data);
    }).toList();

    riders.sort((FoodDeliveryRiderModel first, FoodDeliveryRiderModel second) {
      if (first.isAvailable != second.isAvailable) {
        return first.isAvailable ? -1 : 1;
      }

      return second.rating.compareTo(first.rating);
    });

    return riders;
  }

  Future<void> _showRiderAssignmentDialog(FoodOrderModel order) async {
    if (_isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final List<FoodDeliveryRiderModel> riders = await _loadAssignableRiders();

      if (!mounted) {
        return;
      }

      if (riders.isEmpty) {
        _showMessage('No approved Food Delivery Rider is available.');
        return;
      }

      String selectedRiderId = order.riderId.trim();

      final String? result = await showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder:
                (
                  BuildContext context,
                  void Function(void Function()) setDialogState,
                ) {
                  return AlertDialog(
                    backgroundColor: cardColor,
                    title: Text(
                      order.riderId.trim().isEmpty
                          ? 'Assign Food Rider'
                          : 'Change Food Rider',
                    ),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedRiderId.isEmpty
                            ? null
                            : riders.any(
                                (FoodDeliveryRiderModel rider) =>
                                    rider.riderId == selectedRiderId,
                              )
                            ? selectedRiderId
                            : null,
                        dropdownColor: const Color(0xFF252525),
                        decoration: const InputDecoration(
                          labelText: 'Food Rider',
                          border: OutlineInputBorder(),
                        ),
                        items: riders.map((FoodDeliveryRiderModel rider) {
                          final String state = rider.isOnDelivery
                              ? 'On delivery'
                              : rider.isAvailable
                              ? 'Available'
                              : rider.isOnline
                              ? 'Busy'
                              : 'Offline';

                          return DropdownMenuItem<String>(
                            value: rider.riderId,
                            child: Text(
                              '${rider.fullName} â€¢ '
                              '${rider.vehicleType.displayName} â€¢ '
                              '$state',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setDialogState(() {
                            selectedRiderId = value ?? '';
                          });
                        },
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: selectedRiderId.isEmpty
                            ? null
                            : () {
                                Navigator.pop(dialogContext, selectedRiderId);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: yellow,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Save Assignment'),
                      ),
                    ],
                  );
                },
          );
        },
      );

      if (result == null || result.trim().isEmpty || result == order.riderId) {
        return;
      }

      await _assignRider(order: order, riderId: result);
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'Unable to load Food Riders.');
    } catch (error) {
      _showMessage('Unable to assign Food Rider: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _assignRider({
    required FoodOrderModel order,
    required String riderId,
  }) async {
    final DocumentReference<Map<String, dynamic>> orderDocument = _ordersRef
        .doc(order.orderId);

    final DocumentReference<Map<String, dynamic>> newRiderDocument = _ridersRef
        .doc(riderId);

    final String previousRiderId = order.riderId.trim();

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> newRiderSnapshot =
          await transaction.get(newRiderDocument);

      if (!newRiderSnapshot.exists || newRiderSnapshot.data() == null) {
        throw StateError('Selected Food Rider was not found.');
      }

      final Map<String, dynamic> riderData = Map<String, dynamic>.from(
        newRiderSnapshot.data()!,
      );

      riderData['riderId'] = newRiderSnapshot.id;

      final FoodDeliveryRiderModel newRider = FoodDeliveryRiderModel.fromMap(
        riderData,
      );

      if (!newRider.canAccessRiderDashboard) {
        throw StateError('Selected Food Rider is not approved or active.');
      }

      if (newRider.isOnDelivery && newRider.currentOrderId != order.orderId) {
        throw StateError('Selected Food Rider already has an active delivery.');
      }

      final DateTime now = DateTime.now();

      if (previousRiderId.isNotEmpty && previousRiderId != riderId) {
        transaction.set(_ridersRef.doc(previousRiderId), <String, dynamic>{
          'isOnDelivery': false,
          'isAvailable': true,
          'currentOrderId': '',
          'updatedAt': now.toIso8601String(),
        }, SetOptions(merge: true));
      }

      transaction.set(newRiderDocument, <String, dynamic>{
        'isAvailable': false,
        'isOnDelivery': true,
        'currentOrderId': order.orderId,
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));

      transaction.set(orderDocument, <String, dynamic>{
        'riderId': riderId,
        'riderAssignedByAdmin': true,
        'riderAssignedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    });

    _showMessage(
      previousRiderId.isEmpty
          ? 'Food Rider assigned successfully.'
          : 'Food Rider changed successfully.',
    );
  }

  Future<void> _removeAssignedRider(FoodOrderModel order) async {
    final String riderId = order.riderId.trim();

    if (riderId.isEmpty) {
      _showMessage('No Food Rider is assigned.');
      return;
    }

    if (order.status == FoodOrderStatus.pickedUp ||
        order.status == FoodOrderStatus.onTheWay ||
        order.status == FoodOrderStatus.delivered) {
      _showMessage('Rider cannot be removed after pickup.');
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final DateTime now = DateTime.now();
      final WriteBatch batch = _firestore.batch();

      batch.set(_ordersRef.doc(order.orderId), <String, dynamic>{
        'riderId': '',
        'riderRemovedByAdmin': true,
        'riderRemovedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));

      batch.set(_ridersRef.doc(riderId), <String, dynamic>{
        'isOnDelivery': false,
        'isAvailable': true,
        'currentOrderId': '',
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));

      await batch.commit();

      _showMessage('Assigned Food Rider removed.');
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'Unable to remove Food Rider.');
    } catch (error) {
      _showMessage('Unable to remove Food Rider: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _showOrderDetails(FoodOrderModel order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.88,
            minChildSize: 0.50,
            maxChildSize: 0.96,
            builder: (BuildContext context, ScrollController controller) {
              return ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildDetailHeader(order),
                  const SizedBox(height: 18),
                  _detailsCard(
                    title: 'Order Information',
                    children: <Widget>[
                      _InfoRow(label: 'Order ID', value: order.orderId),
                      const Divider(color: Colors.white12),
                      _InfoRow(label: 'Customer ID', value: order.customerId),
                      const Divider(color: Colors.white12),
                      _InfoRow(
                        label: 'Restaurant',
                        value: order.restaurantName,
                      ),
                      const Divider(color: Colors.white12),
                      _InfoRow(
                        label: 'Restaurant ID',
                        value: order.restaurantId,
                      ),
                      const Divider(color: Colors.white12),
                      _InfoRow(
                        label: 'Rider ID',
                        value: order.riderId.trim().isEmpty
                            ? 'Not assigned'
                            : order.riderId,
                      ),
                      const Divider(color: Colors.white12),
                      _InfoRow(
                        label: 'Created',
                        value: _dateTimeText(order.createdAt),
                      ),
                      const Divider(color: Colors.white12),
                      _InfoRow(
                        label: 'Updated',
                        value: _dateTimeText(order.updatedAt),
                      ),
                      const Divider(color: Colors.white12),
                      _InfoRow(label: 'Delivery OTP', value: order.customerOtp),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detailsCard(
                    title: 'Delivery Address',
                    children: <Widget>[
                      Text(
                        order.deliveryAddress.fullAddress,
                        style: const TextStyle(
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detailsCard(
                    title: 'Ordered Items',
                    children: <Widget>[
                      ...order.items.map((dynamic item) {
                        final String name = _readItemString(item, 'name');

                        final int quantity = _readItemInt(item, 'quantity');

                        final double total = _readItemDouble(
                          item,
                          'totalPrice',
                          fallbackKey: 'total',
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 9),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  name.isEmpty ? 'Food item' : name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                'x$quantity',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Rs. ${total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: yellow,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _detailsCard(
                    title: 'Order Timeline',
                    children: <Widget>[_buildOrderTimeline(order.status)],
                  ),
                  const SizedBox(height: 14),
                  _detailsCard(
                    title: 'Payment Summary',
                    children: <Widget>[
                      _InfoRow(
                        label: 'Items total',
                        value: 'Rs. ${order.itemsTotal.toStringAsFixed(0)}',
                      ),
                      const Divider(color: Colors.white12),
                      _InfoRow(
                        label: 'Delivery fee',
                        value: 'Rs. ${order.deliveryFee.toStringAsFixed(0)}',
                      ),
                      const Divider(color: Colors.white12),
                      _InfoRow(
                        label: 'Service fee',
                        value: 'Rs. ${order.serviceFee.toStringAsFixed(0)}',
                      ),
                      const Divider(color: Colors.white12),
                      _InfoRow(
                        label: 'Discount',
                        value: '- Rs. ${order.discount.toStringAsFixed(0)}',
                      ),
                      const Divider(color: Colors.white12),
                      _InfoRow(
                        label: 'Grand total',
                        value: 'Rs. ${order.grandTotal.toStringAsFixed(0)}',
                        highlight: true,
                      ),
                      const Divider(color: Colors.white12),
                      _InfoRow(
                        label: 'Payment method',
                        value: order.paymentMethod.name,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildDetailActions(order),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailHeader(FoodOrderModel order) {
    final Color color = _statusColor(order.status);

    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 31,
          backgroundColor: color.withValues(alpha: 0.14),
          child: Icon(_statusIcon(order.status), color: color, size: 32),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Order #${_shortId(order.orderId)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _statusText(order.status),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailActions(FoodOrderModel order) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed:
                _isUpdating ||
                    order.status == FoodOrderStatus.delivered ||
                    order.status == FoodOrderStatus.cancelled
                ? null
                : () {
                    Navigator.pop(context);
                    _showRiderAssignmentDialog(order);
                  },
            icon: Icon(
              order.riderId.trim().isEmpty
                  ? Icons.person_add_alt_1
                  : Icons.swap_horiz,
            ),
            label: Text(
              order.riderId.trim().isEmpty
                  ? 'Assign Food Rider'
                  : 'Change Food Rider',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              foregroundColor: Colors.black,
            ),
          ),
        ),
        if (order.riderId.trim().isNotEmpty &&
            order.status != FoodOrderStatus.pickedUp &&
            order.status != FoodOrderStatus.onTheWay &&
            order.status != FoodOrderStatus.delivered &&
            order.status != FoodOrderStatus.cancelled) ...<Widget>[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _isUpdating
                  ? null
                  : () {
                      Navigator.pop(context);
                      _removeAssignedRider(order);
                    },
              icon: const Icon(Icons.person_remove_outlined),
              label: const Text('Remove Assigned Rider'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orangeAccent,
                side: const BorderSide(color: Colors.orangeAccent),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isUpdating
                ? null
                : () {
                    Navigator.pop(context);
                    _showStatusUpdateDialog(order);
                  },
            icon: const Icon(Icons.edit_outlined),
            label: const Text(
              'Update Order Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: Colors.black,
            ),
          ),
        ),
        if (order.status != FoodOrderStatus.delivered &&
            order.status != FoodOrderStatus.cancelled) ...<Widget>[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _isUpdating
                  ? null
                  : () {
                      Navigator.pop(context);
                      _cancelOrder(order);
                    },
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Order'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Food Order Management',
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
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: yellow),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState();
                }

                final List<FoodOrderModel> allOrders =
                    snapshot.data ?? const <FoodOrderModel>[];

                final List<FoodOrderModel> visibleOrders = _filterOrders(
                  allOrders,
                );

                return Column(
                  children: <Widget>[
                    _buildSummary(allOrders),
                    _buildSearchField(),
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
                                  10,
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

                                  return _FoodOrderAdminCard(
                                    order: order,
                                    isUpdating: _isUpdating,
                                    onTap: () => _showOrderDetails(order),
                                    onUpdateStatus: () =>
                                        _showStatusUpdateDialog(order),
                                    onCancel:
                                        order.status ==
                                                FoodOrderStatus.delivered ||
                                            order.status ==
                                                FoodOrderStatus.cancelled
                                        ? null
                                        : () => _cancelOrder(order),
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

  Widget _buildSummary(List<FoodOrderModel> orders) {
    final int active = _countForFilter(orders, _FoodOrderAdminFilter.active);

    final int delivered = _countForFilter(
      orders,
      _FoodOrderAdminFilter.delivered,
    );

    final double revenue = _deliveredRevenue(orders);

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
                  'Food Orders',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$active active â€¢ $delivered delivered',
                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  'Delivered revenue: Rs. ${revenue.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.black87, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${orders.length}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (String value) {
          setState(() {
            _searchText = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search order, customer, restaurant or rider',
          prefixIcon: const Icon(Icons.search, color: yellow),
          suffixIcon: _searchText.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchText = '';
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(List<FoodOrderModel> orders) {
    final List<_OrderFilterItem> filters = <_OrderFilterItem>[
      const _OrderFilterItem(filter: _FoodOrderAdminFilter.all, label: 'All'),
      const _OrderFilterItem(
        filter: _FoodOrderAdminFilter.active,
        label: 'Active',
      ),
      const _OrderFilterItem(
        filter: _FoodOrderAdminFilter.delivered,
        label: 'Delivered',
      ),
      const _OrderFilterItem(
        filter: _FoodOrderAdminFilter.cancelled,
        label: 'Cancelled',
      ),
    ];

    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final _OrderFilterItem item = filters[index];

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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.cloud_off, color: Colors.redAccent, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Unable to load food orders',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check Firestore connection and security rules.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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

  Widget _detailsCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(color: yellow, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 13),
          ...children,
        ],
      ),
    );
  }

  Widget _buildOrderTimeline(FoodOrderStatus currentStatus) {
    final List<FoodOrderStatus> normalFlow = <FoodOrderStatus>[
      FoodOrderStatus.pending,
      FoodOrderStatus.accepted,
      FoodOrderStatus.preparing,
      FoodOrderStatus.readyForPickup,
      FoodOrderStatus.pickedUp,
      FoodOrderStatus.onTheWay,
      FoodOrderStatus.delivered,
    ];

    if (currentStatus == FoodOrderStatus.cancelled) {
      return Row(
        children: <Widget>[
          const Icon(Icons.cancel, color: Colors.redAccent),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Order Cancelled',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    final int currentIndex = normalFlow.indexOf(currentStatus);

    return Column(
      children: normalFlow.asMap().entries.map((
        MapEntry<int, FoodOrderStatus> entry,
      ) {
        final bool complete = entry.key <= currentIndex;
        final bool current = entry.key == currentIndex;
        final bool isLast = entry.key == normalFlow.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              children: <Widget>[
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: complete ? yellow : const Color(0xFF3A3A3A),
                    border: Border.all(
                      color: current ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    complete ? Icons.check : Icons.circle,
                    size: complete ? 16 : 7,
                    color: complete ? Colors.black : Colors.grey,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 28,
                    color: entry.key < currentIndex ? yellow : Colors.white12,
                  ),
              ],
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  _statusText(entry.value),
                  style: TextStyle(
                    color: complete ? Colors.white : Colors.grey,
                    fontWeight: current ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  static String _shortId(String value) {
    if (value.length <= 8) {
      return value;
    }

    return value.substring(0, 8);
  }

  static String _dateTimeText(DateTime value) {
    final String day = value.day.toString().padLeft(2, '0');

    final String month = value.month.toString().padLeft(2, '0');

    final String hour = value.hour.toString().padLeft(2, '0');

    final String minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year} â€¢ $hour:$minute';
  }

  static String _statusText(FoodOrderStatus status) {
    switch (status) {
      case FoodOrderStatus.pending:
        return 'Pending';
      case FoodOrderStatus.accepted:
        return 'Accepted';
      case FoodOrderStatus.preparing:
        return 'Preparing';
      case FoodOrderStatus.readyForPickup:
        return 'Ready for Pickup';
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

  static Color _statusColor(FoodOrderStatus status) {
    switch (status) {
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

  static IconData _statusIcon(FoodOrderStatus status) {
    switch (status) {
      case FoodOrderStatus.pending:
        return Icons.hourglass_top;
      case FoodOrderStatus.accepted:
        return Icons.check_circle_outline;
      case FoodOrderStatus.preparing:
        return Icons.soup_kitchen_outlined;
      case FoodOrderStatus.readyForPickup:
        return Icons.shopping_bag_outlined;
      case FoodOrderStatus.pickedUp:
        return Icons.delivery_dining;
      case FoodOrderStatus.onTheWay:
        return Icons.route;
      case FoodOrderStatus.delivered:
        return Icons.task_alt;
      case FoodOrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  static String _readItemString(dynamic source, String key) {
    if (source is Map) {
      return source[key]?.toString() ?? '';
    }

    try {
      final dynamic map = source.toMap();

      if (map is Map) {
        return map[key]?.toString() ?? '';
      }
    } catch (_) {
      // Safe fallback.
    }

    return '';
  }

  static int _readItemInt(dynamic source, String key) {
    return int.tryParse(_readItemString(source, key)) ?? 0;
  }

  static double _readItemDouble(
    dynamic source,
    String key, {
    String? fallbackKey,
  }) {
    String value = _readItemString(source, key);

    if (value.isEmpty && fallbackKey != null) {
      value = _readItemString(source, fallbackKey);
    }

    return double.tryParse(value) ?? 0;
  }
}

class _FoodOrderAdminCard extends StatelessWidget {
  const _FoodOrderAdminCard({
    required this.order,
    required this.isUpdating,
    required this.onTap,
    required this.onUpdateStatus,
    required this.onCancel,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodOrderModel order;
  final bool isUpdating;
  final VoidCallback onTap;
  final VoidCallback onUpdateStatus;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _FoodOrderManagementScreenState._statusColor(
      order.status,
    );

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
                    backgroundColor: statusColor.withValues(alpha: 0.14),
                    child: Icon(
                      _FoodOrderManagementScreenState._statusIcon(order.status),
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Order #${_FoodOrderManagementScreenState._shortId(order.orderId)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _FoodOrderManagementScreenState._dateTimeText(
                            order.createdAt,
                          ),
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
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _FoodOrderManagementScreenState._statusText(order.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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
              Wrap(
                spacing: 8,
                runSpacing: 7,
                children: <Widget>[
                  _tag(
                    Icons.fastfood_outlined,
                    '${order.items.length} item(s)',
                  ),
                  _tag(Icons.payment, order.paymentMethod.name),
                  _tag(
                    Icons.delivery_dining,
                    order.riderId.trim().isEmpty
                        ? 'No rider'
                        : 'Rider assigned',
                  ),
                ],
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
                  TextButton(
                    onPressed: isUpdating ? null : onUpdateStatus,
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        color: yellow,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onCancel != null)
                    IconButton(
                      tooltip: 'Cancel order',
                      onPressed: isUpdating ? null : onCancel,
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.redAccent,
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

  static Widget _tag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF272727),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: yellow, size: 13),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  static const Color yellow = Color(0xFFFFD60A);

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value.trim().isEmpty ? 'â€”' : value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: highlight ? yellow : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderFilterItem {
  const _OrderFilterItem({required this.filter, required this.label});

  final _FoodOrderAdminFilter filter;
  final String label;
}
