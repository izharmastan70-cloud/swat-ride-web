// lib/food/screens/food_home_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Customer Food Home Screen
//
// This screen:
// - Loads approved restaurants from real Firestore
// - Provides real local search and category filters
// - Opens a restaurant preview page
// - Keeps paid map SDK and Firebase Storage bypassed
// - Touches only the Food module
// =============================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/food_order_model.dart';
import '../models/restaurant_model.dart';
import '../services/food_cart_service.dart';
import '../services/restaurant_service.dart';

class FoodHomeScreen extends StatefulWidget {
  const FoodHomeScreen({super.key});

  @override
  State<FoodHomeScreen> createState() =>
      _FoodHomeScreenState();
}

class _FoodHomeScreenState
    extends State<FoodHomeScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final RestaurantService _restaurantService =
      RestaurantService();

  final FoodCartService _cartService =
      FoodCartService.instance;

  final TextEditingController _searchController =
      TextEditingController();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<
          Map<String, dynamic>>>?
      _favouritesSubscription;

  final Set<String> _favouriteRestaurantIds =
      <String>{};

  String _selectedCategory = 'All';
  String _searchText = '';
  bool _showFavouritesOnly = false;

  static const List<_FoodCategoryOption> _categories =
      <_FoodCategoryOption>[
    _FoodCategoryOption(
      name: 'All',
      icon: Icons.grid_view_rounded,
    ),
    _FoodCategoryOption(
      name: 'Burgers',
      icon: Icons.lunch_dining,
    ),
    _FoodCategoryOption(
      name: 'Pizza',
      icon: Icons.local_pizza,
    ),
    _FoodCategoryOption(
      name: 'BBQ',
      icon: Icons.outdoor_grill,
    ),
    _FoodCategoryOption(
      name: 'Biryani',
      icon: Icons.rice_bowl,
    ),
    _FoodCategoryOption(
      name: 'Fast Food',
      icon: Icons.fastfood,
    ),
    _FoodCategoryOption(
      name: 'Drinks',
      icon: Icons.local_drink,
    ),
    _FoodCategoryOption(
      name: 'Bakery',
      icon: Icons.bakery_dining,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _watchFavourites();
  }

  @override
  void dispose() {
    _favouritesSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String get _customerId =>
      _auth.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>>
      get _favouritesRef => _firestore
          .collection('users')
          .doc(_customerId)
          .collection('food_favourites');

  void _watchFavourites() {
    if (_customerId.isEmpty) {
      return;
    }

    _favouritesSubscription =
        _favouritesRef.snapshots().listen(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        if (!mounted) {
          return;
        }

        setState(() {
          _favouriteRestaurantIds
            ..clear()
            ..addAll(
              snapshot.docs.map(
                (
                  QueryDocumentSnapshot<
                          Map<String, dynamic>>
                      document,
                ) =>
                    document.id,
              ),
            );
        });
      },
    );
  }

  Future<void> _toggleFavourite(
    RestaurantModel restaurant,
  ) async {
    if (_customerId.isEmpty) {
      _showMessage(
        'Please log in to save favourite restaurants.',
      );
      return;
    }

    final DocumentReference<Map<String, dynamic>>
        document =
        _favouritesRef.doc(restaurant.id);

    final bool isFavourite =
        _favouriteRestaurantIds.contains(
      restaurant.id,
    );

    try {
      if (isFavourite) {
        await document.delete();
        _showMessage(
          '${restaurant.name} removed from favourites.',
        );
      } else {
        await document.set(
          <String, dynamic>{
            'restaurantId': restaurant.id,
            'restaurantName': restaurant.name,
            'coverImageUrl':
                restaurant.coverImageUrl,
            'city': restaurant.city,
            'area': restaurant.area,
            'createdAt':
                FieldValue.serverTimestamp(),
          },
        );

        _showMessage(
          '${restaurant.name} added to favourites.',
        );
      }
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ??
            'Unable to update favourites.',
      );
    }
  }

  Future<void> _recordRecentRestaurant(
    RestaurantModel restaurant,
  ) async {
    if (_customerId.isEmpty) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(_customerId)
          .collection(
            'food_recent_restaurants',
          )
          .doc(restaurant.id)
          .set(
        <String, dynamic>{
          'restaurantId': restaurant.id,
          'restaurantName': restaurant.name,
          'coverImageUrl':
              restaurant.coverImageUrl,
          'visitedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Recent history must never block opening a restaurant.
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

  Future<void> _showOrderHistory() async {
    if (_customerId.isEmpty) {
      _showMessage(
        'Please log in to view food order history.',
      );
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot = await _firestore
              .collection('food_orders')
              .where(
                'customerId',
                isEqualTo: _customerId,
              )
              .get();

      final List<FoodOrderModel> orders =
          snapshot.docs.map(
        (
          QueryDocumentSnapshot<
                  Map<String, dynamic>>
              document,
        ) {
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(
            document.data(),
          );
          data['orderId'] = document.id;
          return FoodOrderModel.fromMap(data);
        },
      ).toList()
        ..sort(
          (
            FoodOrderModel first,
            FoodOrderModel second,
          ) =>
              second.createdAt.compareTo(
            first.createdAt,
          ),
        );

      if (!mounted) {
        return;
      }

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: cardColor,
        builder: (
          BuildContext sheetContext,
        ) {
          return SafeArea(
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height *
                      0.72,
              child: orders.isEmpty
                  ? const Center(
                      child: Text(
                        'No food order history yet.',
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.all(16),
                      itemCount: orders.length,
                      separatorBuilder: (
                        BuildContext context,
                        int index,
                      ) =>
                          const SizedBox(height: 10),
                      itemBuilder: (
                        BuildContext context,
                        int index,
                      ) {
                        final FoodOrderModel order =
                            orders[index];

                        return Card(
                          color: const Color(
                            0xFF252525,
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.receipt_long,
                              color: yellow,
                            ),
                            title: Text(
                              order.restaurantName
                                      .trim()
                                      .isEmpty
                                  ? 'Food Order'
                                  : order.restaurantName,
                            ),
                            subtitle: Text(
                              '${order.status.name} • '
                              'Rs. ${order.grandTotal.toStringAsFixed(0)}',
                            ),
                            trailing:
                                const Icon(
                              Icons.chevron_right,
                            ),
                            onTap: () {
                              Navigator.pop(
                                sheetContext,
                              );
                              Navigator.pushNamed(
                                context,
                                '/food_order_tracking',
                                arguments:
                                    order.orderId,
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          );
        },
      );
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ??
            'Unable to load order history.',
      );
    } catch (error) {
      _showMessage(
        'Unable to load order history: $error',
      );
    }
  }

  Future<void> _showCustomerNotifications() async {
    if (_customerId.isEmpty) {
      _showMessage(
        'Please log in to view notifications.',
      );
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot = await _firestore
              .collection(
                'food_customer_notifications',
              )
              .where(
                'customerId',
                isEqualTo: _customerId,
              )
              .get();

      final List<
              QueryDocumentSnapshot<
                  Map<String, dynamic>>>
          documents = snapshot.docs.toList()
            ..sort(
              (
                QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    first,
                QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    second,
              ) {
                final dynamic firstValue =
                    first.data()['createdAt'];
                final dynamic secondValue =
                    second.data()['createdAt'];

                DateTime firstDate =
                    DateTime.fromMillisecondsSinceEpoch(
                  0,
                );
                DateTime secondDate =
                    DateTime.fromMillisecondsSinceEpoch(
                  0,
                );

                try {
                  firstDate =
                      firstValue.toDate()
                          as DateTime;
                } catch (_) {}

                try {
                  secondDate =
                      secondValue.toDate()
                          as DateTime;
                } catch (_) {}

                return secondDate.compareTo(
                  firstDate,
                );
              },
            );

      if (!mounted) {
        return;
      }

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: cardColor,
        builder: (
          BuildContext sheetContext,
        ) {
          return SafeArea(
            child: SizedBox(
              height:
                  MediaQuery.of(context).size.height *
                      0.65,
              child: documents.isEmpty
                  ? const Center(
                      child: Text(
                        'No food notifications yet.',
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.all(16),
                      itemCount:
                          documents.length,
                      separatorBuilder: (
                        BuildContext context,
                        int index,
                      ) =>
                          const Divider(
                        color: Colors.white12,
                      ),
                      itemBuilder: (
                        BuildContext context,
                        int index,
                      ) {
                        final Map<String, dynamic>
                            data =
                            documents[index]
                                .data();

                        return ListTile(
                          leading: Icon(
                            data['isRead'] == true
                                ? Icons
                                    .notifications_outlined
                                : Icons
                                    .notifications_active,
                            color: yellow,
                          ),
                          title: Text(
                            data['title']
                                    ?.toString() ??
                                'Food Update',
                          ),
                          subtitle: Text(
                            data['message']
                                    ?.toString() ??
                                '',
                          ),
                        );
                      },
                    ),
            ),
          );
        },
      );
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ??
            'Unable to load notifications.',
      );
    }
  }

  Future<void> _reorderLast(
    List<RestaurantModel> restaurants,
  ) async {
    if (_customerId.isEmpty) {
      _showMessage(
        'Please log in to reorder.',
      );
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot = await _firestore
              .collection('food_orders')
              .where(
                'customerId',
                isEqualTo: _customerId,
              )
              .get();

      final List<FoodOrderModel> orders =
          snapshot.docs.map(
        (
          QueryDocumentSnapshot<
                  Map<String, dynamic>>
              document,
        ) {
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(
            document.data(),
          );
          data['orderId'] = document.id;
          return FoodOrderModel.fromMap(data);
        },
      ).where(
        (FoodOrderModel order) =>
            order.status ==
            FoodOrderStatus.delivered,
      ).toList()
        ..sort(
          (
            FoodOrderModel first,
            FoodOrderModel second,
          ) =>
              second.createdAt.compareTo(
            first.createdAt,
          ),
        );

      if (orders.isEmpty) {
        _showMessage(
          'No delivered food order is available to reorder.',
        );
        return;
      }

      final FoodOrderModel lastOrder =
          orders.first;

      RestaurantModel? restaurant;

      for (final RestaurantModel item
          in restaurants) {
        if (item.id ==
            lastOrder.restaurantId) {
          restaurant = item;
          break;
        }
      }

      if (restaurant == null) {
        _showMessage(
          'The restaurant from your last order is currently unavailable.',
        );
        return;
      }

      _showMessage(
        'Opening ${restaurant.name}. Add the same items again from its current menu.',
      );
      _openRestaurant(restaurant);
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ??
            'Unable to load your last order.',
      );
    }
  }

  List<RestaurantModel> _filterRestaurants(
    List<RestaurantModel> restaurants,
  ) {
    final String query = _searchText.trim().toLowerCase();
    final String category =
        _selectedCategory.trim().toLowerCase();

    return restaurants.where((RestaurantModel restaurant) {
      if (_showFavouritesOnly &&
          !_favouriteRestaurantIds.contains(
            restaurant.id,
          )) {
        return false;
      }

      final bool matchesCategory =
          category == 'all' ||
          restaurant.categories.any(
            (String item) =>
                item.trim().toLowerCase() == category,
          ) ||
          restaurant.foodTypes.any(
            (String item) =>
                item.trim().toLowerCase() == category,
          );

      if (!matchesCategory) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final String searchable = <String>[
        restaurant.name,
        restaurant.description,
        restaurant.address,
        restaurant.area,
        restaurant.city,
        ...restaurant.categories,
        ...restaurant.foodTypes,
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  Future<void> _openRestaurant(
    RestaurantModel restaurant,
  ) async {
    await _recordRecentRestaurant(
      restaurant,
    );

    if (!mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            FoodRestaurantPreviewScreen(
          restaurant: restaurant,
        ),
      ),
    );
  }

  void _openCart() {
    final int quantity = _cartService.totalQuantity;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            quantity == 0
                ? 'Your food cart is empty.'
                : '$quantity item(s) are currently in your cart.',
          ),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        title: const Text(
          'Food Delivery',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Order History',
            onPressed: _showOrderHistory,
            icon: const Icon(
              Icons.history,
            ),
          ),
          IconButton(
            tooltip: 'Food Notifications',
            onPressed:
                _showCustomerNotifications,
            icon: const Icon(
              Icons.notifications_outlined,
            ),
          ),
          StreamBuilder<List<dynamic>>(
            stream: _cartService.cartStream
                .map<List<dynamic>>(
              (List<dynamic> items) => items,
            ),
            builder: (
              BuildContext context,
              AsyncSnapshot<List<dynamic>> snapshot,
            ) {
              final int count =
                  _cartService.totalQuantity;

              return Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  IconButton(
                    onPressed: _openCart,
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: 6,
                      right: 5,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        decoration: const BoxDecoration(
                          color: yellow,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<RestaurantModel>>(
          stream: _restaurantService
              .watchApprovedRestaurants(),
          builder: (
            BuildContext context,
            AsyncSnapshot<List<RestaurantModel>> snapshot,
          ) {
            final List<RestaurantModel> restaurants =
                _filterRestaurants(
              snapshot.data ?? const <RestaurantModel>[],
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
                        10,
                        16,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildDeliveryLocation(),
                          const SizedBox(height: 16),
                          _buildSearchField(),
                          const SizedBox(height: 20),
                          _buildOfferBanner(),
                          const SizedBox(height: 16),
                          _buildQuickActions(
                            restaurants,
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'What would you like?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCategories(),
                          const SizedBox(height: 24),
                          Row(
                            children: <Widget>[
                              const Expanded(
                                child: Text(
                                  'Restaurants near you',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '${restaurants.length}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      !snapshot.hasData)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: yellow,
                        ),
                      ),
                    )
                  else if (snapshot.hasError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildErrorState(
                        snapshot.error.toString(),
                      ),
                    )
                  else if (restaurants.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
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
                        itemCount: restaurants.length,
                        separatorBuilder: (
                          BuildContext context,
                          int index,
                        ) =>
                            const SizedBox(height: 14),
                        itemBuilder: (
                          BuildContext context,
                          int index,
                        ) {
                          final RestaurantModel restaurant =
                              restaurants[index];

                          return _RestaurantCard(
                            restaurant: restaurant,
                            isFavourite:
                                _favouriteRestaurantIds
                                    .contains(
                              restaurant.id,
                            ),
                            onFavourite: () =>
                                _toggleFavourite(
                              restaurant,
                            ),
                            onTap: () =>
                                _openRestaurant(
                              restaurant,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    List<RestaurantModel> restaurants,
  ) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _QuickActionButton(
            icon: _showFavouritesOnly
                ? Icons.favorite
                : Icons.favorite_border,
            title: _showFavouritesOnly
                ? 'All Restaurants'
                : 'Favourites',
            onTap: () {
              setState(() {
                _showFavouritesOnly =
                    !_showFavouritesOnly;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.replay,
            title: 'Re-order',
            onTap: () {
              _reorderLast(restaurants);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.receipt_long_outlined,
            title: 'History',
            onTap: _showOrderHistory,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryLocation() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: Color(0x22FFD60A),
            child: Icon(
              Icons.location_on,
              color: yellow,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Delivering to',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Current location in Swat',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (String value) {
        setState(() {
          _searchText = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search restaurant or food',
        prefixIcon: const Icon(
          Icons.search,
          color: yellow,
        ),
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
    );
  }

  Widget _buildOfferBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Food from your favourite\nlocal restaurants',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Quick ordering • Live status',
                  style: TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.delivery_dining,
            color: Colors.black,
            size: 64,
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (
          BuildContext context,
          int index,
        ) =>
            const SizedBox(width: 10),
        itemBuilder: (
          BuildContext context,
          int index,
        ) {
          final _FoodCategoryOption category =
              _categories[index];

          final bool selected =
              _selectedCategory == category.name;

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _selectedCategory = category.name;
              });
            },
            child: Container(
              width: 82,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: selected ? yellow : cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    category.icon,
                    color: selected
                        ? Colors.black
                        : yellow,
                    size: 28,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Colors.black
                          : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.restaurant_menu,
            color: yellow,
            size: 70,
          ),
          const SizedBox(height: 16),
          const Text(
            'No restaurants found',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchText.isEmpty &&
                    _selectedCategory == 'All'
                ? 'Approved restaurants will appear here.'
                : 'Try another search or category.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.cloud_off,
            color: Colors.redAccent,
            size: 65,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load restaurants',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check Firestore connection and rules, then try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Text(
            error,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 13,
          ),
          child: Column(
            children: <Widget>[
              Icon(
                icon,
                color: yellow,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// RESTAURANT CARD
// =============================================================

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({
    required this.restaurant,
    required this.isFavourite,
    required this.onFavourite,
    required this.onTap,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final RestaurantModel restaurant;
  final bool isFavourite;
  final VoidCallback onFavourite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 145,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _RestaurantImage(
                    imageUrl:
                        restaurant.coverImageUrl,
                    icon: Icons.restaurant,
                  ),
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: restaurant.canReceiveOrders
                            ? Colors.green
                            : Colors.black87,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        restaurant.openStatusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Material(
                      color: Colors.black87,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: isFavourite
                            ? 'Remove favourite'
                            : 'Add favourite',
                        onPressed: onFavourite,
                        icon: Icon(
                          isFavourite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFavourite
                              ? Colors.redAccent
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (restaurant.hasDiscount)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: yellow,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          restaurant.discountText,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          restaurant.name,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.star,
                        color: yellow,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.ratingText,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    restaurant.categoriesText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.schedule,
                        color: Colors.grey,
                        size: 17,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        restaurant.deliveryTimeText,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.delivery_dining,
                        color: Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          restaurant.deliveryFeeText,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: yellow,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// TEMPORARY CONNECTED RESTAURANT PREVIEW
//
// This is a real navigable page using RestaurantModel.
// In the next step it will be moved into its own file and
// connected with the live MenuService.
// =============================================================

class FoodRestaurantPreviewScreen
    extends StatelessWidget {
  const FoodRestaurantPreviewScreen({
    required this.restaurant,
    super.key,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final RestaurantModel restaurant;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: Text(
          restaurant.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: <Widget>[
          SizedBox(
            height: 220,
            width: double.infinity,
            child: _RestaurantImage(
              imageUrl: restaurant.coverImageUrl,
              icon: Icons.restaurant,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  restaurant.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  restaurant.categoriesText,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: <Widget>[
                      _RestaurantInfoRow(
                        icon: Icons.schedule,
                        label: 'Delivery time',
                        value:
                            restaurant.deliveryTimeText,
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _RestaurantInfoRow(
                        icon: Icons.delivery_dining,
                        label: 'Delivery fee',
                        value:
                            restaurant.deliveryFeeText,
                      ),
                      const Divider(
                        color: Colors.white12,
                      ),
                      _RestaurantInfoRow(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Minimum order',
                        value:
                            restaurant.minimumOrderText,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: <Widget>[
                      Icon(
                        Icons.restaurant_menu,
                        color: yellow,
                        size: 45,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Digital menu connection is next',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'The next file will load this restaurant’s real Firestore menu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantInfoRow extends StatelessWidget {
  const _RestaurantInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  static const Color yellow = Color(0xFFFFD60A);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(
          icon,
          color: yellow,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _RestaurantImage extends StatelessWidget {
  const _RestaurantImage({
    required this.imageUrl,
    required this.icon,
  });

  static const Color yellow = Color(0xFFFFD60A);

  final String imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Container(
        color: const Color(0xFF262626),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: yellow,
          size: 70,
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (
        BuildContext context,
        Object error,
        StackTrace? stackTrace,
      ) {
        return Container(
          color: const Color(0xFF262626),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: yellow,
            size: 70,
          ),
        );
      },
      loadingBuilder: (
        BuildContext context,
        Widget child,
        ImageChunkEvent? loadingProgress,
      ) {
        if (loadingProgress == null) {
          return child;
        }

        return const ColoredBox(
          color: Color(0xFF262626),
          child: Center(
            child: CircularProgressIndicator(
              color: yellow,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }
}

class _FoodCategoryOption {
  const _FoodCategoryOption({
    required this.name,
    required this.icon,
  });

  final String name;
  final IconData icon;
}
