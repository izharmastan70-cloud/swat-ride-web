// lib/food/rider/screens/food_delivery_available_orders_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Food Delivery Rider Available Orders Screen
//
// Connected with:
// - FoodDeliveryRiderModel
// - FoodDeliveryRiderService
// - FoodOrderModel
//
// Real features:
// - Live Firestore available orders
// - Rider availability validation
// - Order summary
// - Delivery address
// - Estimated rider earning
// - Accept / reject request
// - Order details navigation
//
// Paid map rendering remains temporarily bypassed.
// =============================================================

import 'package:flutter/material.dart';

import '../../models/food_order_model.dart';
import '../../services/food_service_control_service.dart';
import '../models/food_delivery_rider_model.dart';
import '../services/food_delivery_rider_service.dart';

class FoodDeliveryAvailableOrdersScreen
    extends StatefulWidget {
  const FoodDeliveryAvailableOrdersScreen({
    required this.rider,
    super.key,
  });

  final FoodDeliveryRiderModel rider;

  @override
  State<FoodDeliveryAvailableOrdersScreen>
      createState() =>
          _FoodDeliveryAvailableOrdersScreenState();
}

class _FoodDeliveryAvailableOrdersScreenState
    extends State<FoodDeliveryAvailableOrdersScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodDeliveryRiderService _riderService =
      FoodDeliveryRiderService();

  final FoodServiceControlService _serviceControlService =
      FoodServiceControlService();

  String _searchText = '';
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

  List<FoodOrderModel> _filterOrders(
    List<FoodOrderModel> orders,
  ) {
    final String query =
        _searchText.trim().toLowerCase();

    if (query.isEmpty) {
      return orders;
    }

    return orders.where(
      (FoodOrderModel order) {
        final String searchable = <String>[
          order.orderId,
          order.restaurantId,
          order.deliveryAddress.fullAddress,
          order.status.name,
        ].join(' ').toLowerCase();

        return searchable.contains(query);
      },
    ).toList();
  }

  Future<void> _acceptOrder({
    required FoodDeliveryRiderModel rider,
    required FoodOrderModel order,
  }) async {
    if (_isUpdating) {
      return;
    }

    if (!rider.canReceiveOrders) {
      _showMessage(
        'Go online and enable availability before accepting an order.',
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Accept Delivery?',
          ),
          content: Text(
            'Order #${_shortId(order.orderId)} will be assigned to you.\n\n'
            'Delivery address:\n${order.deliveryAddress.fullAddress}',
            style: const TextStyle(
              color: Colors.grey,
              height: 1.45,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Accept Order'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      // Master Food control blocks only new rider work.
      // Existing active deliveries continue normally.
      await _serviceControlService.assertCanCreateNewOrder();

      await _riderService.acceptOrder(
        riderId: rider.riderId,
        orderId: order.orderId,
      );

      final FoodOrderModel? updatedOrder =
          await _riderService.getOrderById(
        order.orderId,
      );

      if (updatedOrder == null) {
        throw const FoodDeliveryRiderServiceException(
          message:
              'Order was assigned, but the updated order could not be loaded.',
        );
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        'Food order accepted successfully.',
      );

      Navigator.pushReplacementNamed(
        context,
        '/food_rider_active_delivery',
        arguments: <String, dynamic>{
          'rider': rider,
          'order': updatedOrder,
        },
      );
    } on FoodServiceControlException catch (error) {
      _showMessage(error.message);
    } on FoodDeliveryRiderServiceException
        catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(
        'Unable to accept food order: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _rejectRequest({
    required FoodDeliveryRiderModel rider,
    required FoodOrderModel order,
  }) async {
    if (_isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _riderService.rejectOrderRequest(
        riderId: rider.riderId,
        orderId: order.orderId,
      );

      _showMessage(
        'Order request skipped.',
      );
    } on FoodDeliveryRiderServiceException
        catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(
        'Unable to skip order request: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _openOrderDetails(
    FoodOrderModel order,
  ) {
    Navigator.pushNamed(
      context,
      '/food_rider_order_details',
      arguments: order,
    );
  }

  double _estimatedRiderEarning(
    FoodOrderModel order,
  ) {
    final double base =
        order.deliveryFee > 0
            ? order.deliveryFee
            : 80;

    return base < 50 ? 50 : base;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Available Food Orders',
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

          if (!rider.canAccessRiderDashboard) {
            return _buildAccessDenied();
          }

          return StreamBuilder<List<FoodOrderModel>>(
            stream:
                _riderService.watchAvailableOrders(),
            builder: (
              BuildContext context,
              AsyncSnapshot<List<FoodOrderModel>>
                  orderSnapshot,
            ) {
              if (orderSnapshot.connectionState ==
                      ConnectionState.waiting &&
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

              return RefreshIndicator(
                color: yellow,
                onRefresh: () async {
                  setState(() {});
                },
                child: CustomScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          14,
                          16,
                          0,
                        ),
                        child: Column(
                          children: <Widget>[
                            _buildRiderStatusCard(rider),
                            const SizedBox(height: 14),
                            _buildSearchField(),
                            const SizedBox(height: 16),
                            Row(
                              children: <Widget>[
                                const Expanded(
                                  child: Text(
                                    'Pickup Requests',
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
                          ],
                        ),
                      ),
                    ),
                    if (orders.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(rider),
                      )
                    else
                      SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          30,
                        ),
                        sliver: SliverList.separated(
                          itemCount: orders.length,
                          separatorBuilder: (
                            BuildContext context,
                            int index,
                          ) =>
                              const SizedBox(
                            height: 12,
                          ),
                          itemBuilder: (
                            BuildContext context,
                            int index,
                          ) {
                            final FoodOrderModel order =
                                orders[index];

                            return _AvailableOrderCard(
                              order: order,
                              estimatedEarning:
                                  _estimatedRiderEarning(
                                order,
                              ),
                              isUpdating:
                                  _isUpdating,
                              onTap: () =>
                                  _openOrderDetails(
                                order,
                              ),
                              onAccept: () =>
                                  _acceptOrder(
                                rider: rider,
                                order: order,
                              ),
                              onReject: () =>
                                  _rejectRequest(
                                rider: rider,
                                order: order,
                              ),
                            );
                          },
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

  Widget _buildRiderStatusCard(
    FoodDeliveryRiderModel rider,
  ) {
    final Color statusColor =
        rider.canReceiveOrders
            ? Colors.greenAccent
            : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: statusColor.withValues(
            alpha: 0.55,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor:
                statusColor.withValues(
              alpha: 0.14,
            ),
            child: Icon(
              rider.canReceiveOrders
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  rider.canReceiveOrders
                      ? 'Ready for orders'
                      : 'Not ready for orders',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rider.canReceiveOrders
                      ? 'You can accept one available delivery request.'
                      : 'Go online and enable availability from the dashboard.',
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

  Widget _buildSearchField() {
    return TextField(
      onChanged: (String value) {
        setState(() {
          _searchText = value;
        });
      },
      decoration: InputDecoration(
        hintText:
            'Search order or delivery area',
        prefixIcon: const Icon(
          Icons.search,
          color: yellow,
        ),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    FoodDeliveryRiderModel rider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.receipt_long_outlined,
            color: yellow,
            size: 76,
          ),
          const SizedBox(height: 16),
          const Text(
            'No available orders',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rider.canReceiveOrders
                ? 'New restaurant pickup requests will appear here automatically.'
                : 'Enable rider availability to accept new food orders.',
            textAlign: TextAlign.center,
            style: const TextStyle(
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
              'Unable to load available orders',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check Firestore connection, rules and required indexes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                height: 1.4,
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

  Widget _buildAccessDenied() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.lock_outline,
              color: Colors.redAccent,
              size: 72,
            ),
            SizedBox(height: 16),
            Text(
              'Rider access unavailable',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Admin approval and an active rider account are required.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortId(String value) {
    if (value.length <= 8) {
      return value;
    }

    return value.substring(0, 8);
  }
}

class _AvailableOrderCard extends StatelessWidget {
  const _AvailableOrderCard({
    required this.order,
    required this.estimatedEarning,
    required this.isUpdating,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodOrderModel order;
  final double estimatedEarning;
  final bool isUpdating;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  String get _shortOrderId {
    if (order.orderId.length <= 8) {
      return order.orderId;
    }

    return order.orderId.substring(0, 8);
  }

  String get _createdText {
    final DateTime value = order.createdAt;

    final String hour =
        value.hour.toString().padLeft(2, '0');

    final String minute =
        value.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
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
                      Icons.restaurant,
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
                          'Order #$_shortOrderId',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${order.items.length} item(s) â€¢ $_createdText',
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
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Colors.green.withValues(
                        alpha: 0.13,
                      ),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Earn Rs. ${estimatedEarning.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Deliver to',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                order.deliveryAddress.fullAddress,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: <Widget>[
                  _infoTag(
                    Icons.payments_outlined,
                    'Order Rs. ${order.grandTotal.toStringAsFixed(0)}',
                  ),
                  _infoTag(
                    Icons.delivery_dining,
                    'Fee Rs. ${order.deliveryFee.toStringAsFixed(0)}',
                  ),
                  _infoTag(
                    Icons.payment,
                    order.paymentMethod.name,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          isUpdating ? null : onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Colors.redAccent,
                        side: const BorderSide(
                          color: Colors.redAccent,
                        ),
                      ),
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          isUpdating ? null : onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: yellow,
                        foregroundColor: Colors.black,
                      ),
                      child: isUpdating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
                              'Accept',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
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

  static Widget _infoTag(
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF272727),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            color: yellow,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}


