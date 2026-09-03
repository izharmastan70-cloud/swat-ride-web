// lib/food/rider/screens/food_delivery_notifications_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Food Delivery Rider Notifications Screen
//
// Firestore collection:
// food_rider_notifications/{notificationId}
//
// Expected fields:
// - notificationId
// - riderId
// - title
// - message
// - type
// - orderId
// - isRead
// - createdAt
//
// Real features:
// - Live Firestore notifications
// - All / Unread / Orders / Earnings / Admin filters
// - Mark one notification as read
// - Mark all notifications as read
// - Delete one notification
// - Clear all notifications
// - Open related order when orderId exists
//
// Existing non-Food modules remain untouched.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/food_delivery_rider_model.dart';

enum _FoodRiderNotificationFilter {
  all,
  unread,
  orders,
  earnings,
  admin,
}

class FoodDeliveryNotificationsScreen
    extends StatefulWidget {
  const FoodDeliveryNotificationsScreen({
    required this.rider,
    super.key,
  });

  final FoodDeliveryRiderModel rider;

  @override
  State<FoodDeliveryNotificationsScreen>
      createState() =>
          _FoodDeliveryNotificationsScreenState();
}

class _FoodDeliveryNotificationsScreenState
    extends State<FoodDeliveryNotificationsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  static const String collectionName =
      'food_rider_notifications';

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  _FoodRiderNotificationFilter _selectedFilter =
      _FoodRiderNotificationFilter.all;

  bool _isUpdating = false;

  FoodDeliveryRiderModel get rider => widget.rider;

  CollectionReference<Map<String, dynamic>>
      get _notificationsRef =>
          _firestore.collection(collectionName);

  Stream<List<_FoodRiderNotification>>
      _watchNotifications() {
    if (rider.riderId.trim().isEmpty) {
      return Stream<List<_FoodRiderNotification>>.value(
        const <_FoodRiderNotification>[],
      );
    }

    return _notificationsRef
        .where(
          'riderId',
          isEqualTo: rider.riderId,
        )
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        final List<_FoodRiderNotification>
            notifications = snapshot.docs.map(
          (
            QueryDocumentSnapshot<Map<String, dynamic>>
                document,
          ) {
            return _FoodRiderNotification.fromMap(
              id: document.id,
              map: document.data(),
            );
          },
        ).toList();

        notifications.sort(
          (
            _FoodRiderNotification first,
            _FoodRiderNotification second,
          ) =>
              second.createdAt.compareTo(
            first.createdAt,
          ),
        );

        return notifications;
      },
    );
  }

  List<_FoodRiderNotification> _filterNotifications(
    List<_FoodRiderNotification> notifications,
  ) {
    switch (_selectedFilter) {
      case _FoodRiderNotificationFilter.all:
        return notifications;

      case _FoodRiderNotificationFilter.unread:
        return notifications
            .where(
              (_FoodRiderNotification item) =>
                  !item.isRead,
            )
            .toList();

      case _FoodRiderNotificationFilter.orders:
        return notifications
            .where(
              (_FoodRiderNotification item) =>
                  item.type == 'order' ||
                  item.type == 'pickup' ||
                  item.type == 'delivery',
            )
            .toList();

      case _FoodRiderNotificationFilter.earnings:
        return notifications
            .where(
              (_FoodRiderNotification item) =>
                  item.type == 'earning' ||
                  item.type == 'wallet' ||
                  item.type == 'commission',
            )
            .toList();

      case _FoodRiderNotificationFilter.admin:
        return notifications
            .where(
              (_FoodRiderNotification item) =>
                  item.type == 'admin' ||
                  item.type == 'announcement' ||
                  item.type == 'approval',
            )
            .toList();
    }
  }

  int _countForFilter(
    List<_FoodRiderNotification> notifications,
    _FoodRiderNotificationFilter filter,
  ) {
    switch (filter) {
      case _FoodRiderNotificationFilter.all:
        return notifications.length;

      case _FoodRiderNotificationFilter.unread:
        return notifications
            .where(
              (_FoodRiderNotification item) =>
                  !item.isRead,
            )
            .length;

      case _FoodRiderNotificationFilter.orders:
        return notifications
            .where(
              (_FoodRiderNotification item) =>
                  item.type == 'order' ||
                  item.type == 'pickup' ||
                  item.type == 'delivery',
            )
            .length;

      case _FoodRiderNotificationFilter.earnings:
        return notifications
            .where(
              (_FoodRiderNotification item) =>
                  item.type == 'earning' ||
                  item.type == 'wallet' ||
                  item.type == 'commission',
            )
            .length;

      case _FoodRiderNotificationFilter.admin:
        return notifications
            .where(
              (_FoodRiderNotification item) =>
                  item.type == 'admin' ||
                  item.type == 'announcement' ||
                  item.type == 'approval',
            )
            .length;
    }
  }

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

  Future<void> _markAsRead(
    _FoodRiderNotification notification,
  ) async {
    if (notification.isRead) {
      _openNotification(notification);
      return;
    }

    try {
      await _notificationsRef
          .doc(notification.id)
          .set(
        <String, dynamic>{
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
          'updatedAt':
              DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );

      _openNotification(notification);
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ??
            'Unable to mark notification as read.',
      );
    } catch (error) {
      _showMessage(
        'Unable to update notification: $error',
      );
    }
  }

  Future<void> _markAllAsRead(
    List<_FoodRiderNotification> notifications,
  ) async {
    if (_isUpdating) {
      return;
    }

    final List<_FoodRiderNotification> unread =
        notifications
            .where(
              (_FoodRiderNotification item) =>
                  !item.isRead,
            )
            .toList();

    if (unread.isEmpty) {
      _showMessage(
        'All notifications are already read.',
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final WriteBatch batch =
          _firestore.batch();

      final String now =
          DateTime.now().toIso8601String();

      for (final _FoodRiderNotification item
          in unread) {
        batch.set(
          _notificationsRef.doc(item.id),
          <String, dynamic>{
            'isRead': true,
            'readAt': now,
            'updatedAt': now,
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      _showMessage(
        'All notifications marked as read.',
      );
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ??
            'Unable to update notifications.',
      );
    } catch (error) {
      _showMessage(
        'Unable to update notifications: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _deleteNotification(
    _FoodRiderNotification notification,
  ) async {
    try {
      await _notificationsRef
          .doc(notification.id)
          .delete();

      _showMessage(
        'Notification deleted.',
      );
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ??
            'Unable to delete notification.',
      );
    } catch (error) {
      _showMessage(
        'Unable to delete notification: $error',
      );
    }
  }

  Future<void> _clearAll(
    List<_FoodRiderNotification> notifications,
  ) async {
    if (_isUpdating || notifications.isEmpty) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Clear Notifications?',
          ),
          content: const Text(
            'All Food Rider notifications will be permanently deleted.',
            style: TextStyle(
              color: Colors.grey,
              height: 1.4,
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
                backgroundColor:
                    Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All'),
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
      final WriteBatch batch =
          _firestore.batch();

      for (final _FoodRiderNotification item
          in notifications) {
        batch.delete(
          _notificationsRef.doc(item.id),
        );
      }

      await batch.commit();

      _showMessage(
        'All notifications cleared.',
      );
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ??
            'Unable to clear notifications.',
      );
    } catch (error) {
      _showMessage(
        'Unable to clear notifications: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  void _openNotification(
    _FoodRiderNotification notification,
  ) {
    if (notification.orderId.trim().isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/food_rider_order_details',
        arguments: notification.orderId,
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor:
                          _notificationColor(
                        notification.type,
                      ).withValues(alpha: 0.14),
                      child: Icon(
                        _notificationIcon(
                          notification.type,
                        ),
                        color: _notificationColor(
                          notification.type,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  notification.message,
                  style: const TextStyle(
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _dateTimeText(
                    notification.createdAt,
                  ),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(sheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: yellow,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Food Rider Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<
            List<_FoodRiderNotification>>(
          stream: _watchNotifications(),
          builder: (
            BuildContext context,
            AsyncSnapshot<
                    List<_FoodRiderNotification>>
                snapshot,
          ) {
            if (snapshot.connectionState ==
                    ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: yellow,
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState(
                snapshot.error.toString(),
              );
            }

            final List<_FoodRiderNotification>
                allNotifications =
                snapshot.data ??
                    const <
                        _FoodRiderNotification>[];

            final List<_FoodRiderNotification>
                visibleNotifications =
                _filterNotifications(
              allNotifications,
            );

            return Column(
              children: <Widget>[
                _buildHeader(
                  allNotifications,
                ),
                _buildFilters(
                  allNotifications,
                ),
                Expanded(
                  child: visibleNotifications.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: yellow,
                          onRefresh: () async {
                            setState(() {});
                          },
                          child: ListView.separated(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(
                              16,
                              12,
                              16,
                              30,
                            ),
                            itemCount:
                                visibleNotifications
                                    .length,
                            separatorBuilder: (
                              BuildContext context,
                              int index,
                            ) =>
                                const SizedBox(
                              height: 10,
                            ),
                            itemBuilder: (
                              BuildContext context,
                              int index,
                            ) {
                              final _FoodRiderNotification
                                  notification =
                                  visibleNotifications[
                                      index];

                              return _NotificationCard(
                                notification:
                                    notification,
                                onTap: () =>
                                    _markAsRead(
                                  notification,
                                ),
                                onDelete: () =>
                                    _deleteNotification(
                                  notification,
                                ),
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

  Widget _buildHeader(
    List<_FoodRiderNotification> notifications,
  ) {
    final int unreadCount = notifications
        .where(
          (_FoodRiderNotification item) =>
              !item.isRead,
        )
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        8,
      ),
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
            child: Icon(
              Icons.notifications_active_outlined,
              color: yellow,
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Rider Alerts',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unreadCount unread • ${notifications.length} total',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: cardColor,
            enabled:
                notifications.isNotEmpty &&
                !_isUpdating,
            onSelected: (String value) {
              if (value == 'read_all') {
                _markAllAsRead(notifications);
              } else if (value == 'clear_all') {
                _clearAll(notifications);
              }
            },
            itemBuilder: (
              BuildContext context,
            ) {
              return const <
                  PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'read_all',
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.done_all,
                        color: yellow,
                      ),
                      SizedBox(width: 10),
                      Text('Mark all read'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'clear_all',
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.delete_sweep_outlined,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 10),
                      Text('Clear all'),
                    ],
                  ),
                ),
              ];
            },
            icon: _isUpdating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.more_vert,
                    color: Colors.black,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    List<_FoodRiderNotification> notifications,
  ) {
    final List<_NotificationFilterItem> filters =
        <_NotificationFilterItem>[
      const _NotificationFilterItem(
        filter:
            _FoodRiderNotificationFilter.all,
        label: 'All',
      ),
      const _NotificationFilterItem(
        filter:
            _FoodRiderNotificationFilter.unread,
        label: 'Unread',
      ),
      const _NotificationFilterItem(
        filter:
            _FoodRiderNotificationFilter.orders,
        label: 'Orders',
      ),
      const _NotificationFilterItem(
        filter:
            _FoodRiderNotificationFilter.earnings,
        label: 'Earnings',
      ),
      const _NotificationFilterItem(
        filter:
            _FoodRiderNotificationFilter.admin,
        label: 'Admin',
      ),
    ];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 7,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (
          BuildContext context,
          int index,
        ) =>
            const SizedBox(width: 8),
        itemBuilder: (
          BuildContext context,
          int index,
        ) {
          final _NotificationFilterItem item =
              filters[index];

          final bool selected =
              _selectedFilter == item.filter;

          final int count = _countForFilter(
            notifications,
            item.filter,
          );

          return ChoiceChip(
            label: Text(
              '${item.label} ($count)',
            ),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.notifications_none,
              color: yellow,
              size: 76,
            ),
            SizedBox(height: 16),
            Text(
              'No notifications found',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Food orders, earnings and admin alerts will appear here.',
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

  Widget _buildErrorState(String error) {
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
              'Unable to load notifications',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
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

  static IconData _notificationIcon(
    String type,
  ) {
    switch (type) {
      case 'order':
        return Icons.receipt_long_outlined;
      case 'pickup':
        return Icons.shopping_bag_outlined;
      case 'delivery':
        return Icons.delivery_dining;
      case 'earning':
      case 'wallet':
        return Icons.payments_outlined;
      case 'commission':
        return Icons.percent;
      case 'approval':
        return Icons.verified_outlined;
      case 'admin':
      case 'announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  static Color _notificationColor(
    String type,
  ) {
    switch (type) {
      case 'order':
      case 'pickup':
      case 'delivery':
        return Colors.lightBlueAccent;
      case 'earning':
      case 'wallet':
        return Colors.greenAccent;
      case 'commission':
        return Colors.orangeAccent;
      case 'approval':
        return Colors.greenAccent;
      case 'admin':
      case 'announcement':
        return yellow;
      default:
        return Colors.grey;
    }
  }

  static String _dateTimeText(
    DateTime value,
  ) {
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
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final _FoodRiderNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final Color color =
        _FoodDeliveryNotificationsScreenState
            ._notificationColor(
      notification.type,
    );

    final IconData icon =
        _FoodDeliveryNotificationsScreenState
            ._notificationIcon(
      notification.type,
    );

    return Material(
      color: notification.isRead
          ? cardColor
          : const Color(0xFF23200F),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor:
                        color.withValues(
                      alpha: 0.14,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                    ),
                  ),
                  if (!notification.isRead)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration:
                            const BoxDecoration(
                          color: yellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      notification.title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            notification.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.message,
                      maxLines: 3,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: <Widget>[
                        Text(
                          _FoodDeliveryNotificationsScreenState
                              ._dateTimeText(
                            notification.createdAt,
                          ),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                        if (notification.orderId
                            .trim()
                            .isNotEmpty) ...<Widget>[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.receipt_long_outlined,
                            color: yellow,
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _shortId(
                              notification.orderId,
                            ),
                            style: const TextStyle(
                              color: yellow,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: cardColor,
                onSelected: (String value) {
                  if (value == 'delete') {
                    onDelete();
                  } else if (value == 'open') {
                    onTap();
                  }
                },
                itemBuilder: (
                  BuildContext context,
                ) {
                  return const <
                      PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'open',
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.open_in_new,
                            color: yellow,
                          ),
                          SizedBox(width: 10),
                          Text('Open'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 10),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _shortId(String value) {
    if (value.length <= 8) {
      return value;
    }

    return value.substring(0, 8);
  }
}

class _FoodRiderNotification {
  const _FoodRiderNotification({
    required this.id,
    required this.riderId,
    required this.title,
    required this.message,
    required this.type,
    required this.orderId,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String riderId;
  final String title;
  final String message;
  final String type;
  final String orderId;
  final bool isRead;
  final DateTime createdAt;

  factory _FoodRiderNotification.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    return _FoodRiderNotification(
      id: id,
      riderId: _stringValue(
        map['riderId'],
      ),
      title: _stringValue(
        map['title'],
        fallback: 'Food Rider Notification',
      ),
      message: _stringValue(
        map['message'],
      ),
      type: _stringValue(
        map['type'],
        fallback: 'general',
      ).toLowerCase(),
      orderId: _stringValue(
        map['orderId'],
      ),
      isRead: _boolValue(
        map['isRead'],
      ),
      createdAt: _dateTimeValue(
            map['createdAt'],
          ) ??
          DateTime.now(),
    );
  }

  static String _stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    final String text =
        value?.toString().trim() ?? '';

    return text.isEmpty ? fallback : text;
  }

  static bool _boolValue(
    dynamic value,
  ) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text =
        value?.toString().trim().toLowerCase() ??
            '';

    return text == 'true' ||
        text == '1' ||
        text == 'yes';
  }

  static DateTime? _dateTimeValue(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    try {
      final dynamic converted =
          value.toDate();

      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Supports Firestore Timestamp without direct dependency.
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}

class _NotificationFilterItem {
  const _NotificationFilterItem({
    required this.filter,
    required this.label,
  });

  final _FoodRiderNotificationFilter filter;
  final String label;
}
