// lib/food/screens/restaurant_list_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Customer Restaurant List Screen
//
// Real features:
// - Live restaurants from Firestore
// - Search
// - Category filters
// - Open/closed state
// - Popular/featured/discount badges
// - Restaurant details navigation
//
// Firebase Storage images remain bypassed, so image placeholders
// are shown when no public image URL is available.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/restaurant_model.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({
    super.key,
  });

  @override
  State<RestaurantListScreen> createState() =>
      _RestaurantListScreenState();
}

class _RestaurantListScreenState
    extends State<RestaurantListScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _searchController =
      TextEditingController();

  String _searchText = '';
  String _selectedCategory = 'All';

  static const List<String> _categories = <String>[
    'All',
    'Fast Food',
    'Burgers',
    'Pizza',
    'BBQ',
    'Biryani',
    'Pakistani',
    'Chinese',
    'Bakery',
    'Desserts',
    'Drinks',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<RestaurantModel>> _watchRestaurants() {
    return _firestore
        .collection('food_restaurants')
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        final List<RestaurantModel> restaurants =
            snapshot.docs.map(
          (
            QueryDocumentSnapshot<Map<String, dynamic>>
                document,
          ) {
            final Map<String, dynamic> data =
                Map<String, dynamic>.from(
              document.data(),
            );

            data['id'] = document.id;

            return RestaurantModel.fromMap(data);
          },
        ).where(
          (RestaurantModel restaurant) {
            return restaurant.isApproved &&
                restaurant.isActive &&
                !restaurant.isSuspended;
          },
        ).toList();

        restaurants.sort(
          (
            RestaurantModel first,
            RestaurantModel second,
          ) {
            if (first.isFeatured != second.isFeatured) {
              return first.isFeatured ? -1 : 1;
            }

            if (first.isPopular != second.isPopular) {
              return first.isPopular ? -1 : 1;
            }

            return second.rating.compareTo(first.rating);
          },
        );

        return restaurants;
      },
    );
  }

  List<RestaurantModel> _filterRestaurants(
    List<RestaurantModel> restaurants,
  ) {
    final String query =
        _searchText.trim().toLowerCase();

    return restaurants.where(
      (RestaurantModel restaurant) {
        final bool categoryMatches =
            _selectedCategory == 'All' ||
            restaurant.categories.any(
              (String category) =>
                  category.toLowerCase() ==
                  _selectedCategory.toLowerCase(),
            ) ||
            restaurant.foodTypes.any(
              (String type) =>
                  type.toLowerCase() ==
                  _selectedCategory.toLowerCase(),
            );

        if (!categoryMatches) {
          return false;
        }

        if (query.isEmpty) {
          return true;
        }

        final String searchable = <String>[
          restaurant.name,
          restaurant.description,
          restaurant.city,
          restaurant.area,
          ...restaurant.categories,
          ...restaurant.foodTypes,
        ].join(' ').toLowerCase();

        return searchable.contains(query);
      },
    ).toList();
  }

  void _openRestaurant(
    RestaurantModel restaurant,
  ) {
    Navigator.pushNamed(
      context,
      '/food_restaurant_details',
      arguments: restaurant,
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
            tooltip: 'Cart',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/food_cart',
              );
            },
            icon: const Icon(
              Icons.shopping_cart_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<RestaurantModel>>(
          stream: _watchRestaurants(),
          builder: (
            BuildContext context,
            AsyncSnapshot<List<RestaurantModel>>
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

            final List<RestaurantModel> restaurants =
                _filterRestaurants(
              snapshot.data ??
                  const <RestaurantModel>[],
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
                        12,
                        16,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildHeroCard(),
                          const SizedBox(height: 16),
                          _buildSearchField(),
                          const SizedBox(height: 14),
                          _buildCategoryFilters(),
                          const SizedBox(height: 20),
                          Row(
                            children: <Widget>[
                              const Expanded(
                                child: Text(
                                  'Restaurants',
                                  style: TextStyle(
                                    fontSize: 21,
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
                  if (restaurants.isEmpty)
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
                            const SizedBox(
                          height: 14,
                        ),
                        itemBuilder: (
                          BuildContext context,
                          int index,
                        ) {
                          final RestaurantModel
                              restaurant =
                              restaurants[index];

                          return _RestaurantCustomerCard(
                            restaurant: restaurant,
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

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: <Widget>[
          Icon(
            Icons.delivery_dining,
            color: Colors.black,
            size: 52,
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Order food easily',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Browse nearby restaurants, select dishes and track delivery live.',
                  style: TextStyle(
                    color: Colors.black87,
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
      controller: _searchController,
      onChanged: (String value) {
        setState(() {
          _searchText = value;
        });
      },
      decoration: InputDecoration(
        hintText:
            'Search restaurant or food type',
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

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (
          BuildContext context,
          int index,
        ) =>
            const SizedBox(width: 8),
        itemBuilder: (
          BuildContext context,
          int index,
        ) {
          final String category =
              _categories[index];

          final bool selected =
              category == _selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedCategory = category;
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
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.storefront_outlined,
            color: yellow,
            size: 76,
          ),
          const SizedBox(height: 16),
          const Text(
            'No restaurants found',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchText.isNotEmpty ||
                    _selectedCategory != 'All'
                ? 'Try another search or category.'
                : 'Approved restaurants will appear here.',
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
              'Unable to load restaurants',
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
}

class _RestaurantCustomerCard
    extends StatelessWidget {
  const _RestaurantCustomerCard({
    required this.restaurant,
    required this.onTap,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final RestaurantModel restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool open =
        restaurant.isOpen &&
        !restaurant.isTemporarilyClosed;

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
            Container(
              height: 145,
              width: double.infinity,
              color: const Color(0xFF272727),
              alignment: Alignment.center,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const Center(
                    child: Icon(
                      Icons.restaurant,
                      color: yellow,
                      size: 56,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _badge(
                      open ? 'OPEN' : 'CLOSED',
                      open
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                  ),
                  if (restaurant.discountPercentage >
                      0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _badge(
                        '${restaurant.discountPercentage.toStringAsFixed(0)}% OFF',
                        yellow,
                      ),
                    ),
                  if (restaurant.isFeatured)
                    const Positioned(
                      bottom: 10,
                      right: 10,
                      child: Icon(
                        Icons.verified,
                        color: yellow,
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
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star,
                        color: yellow,
                        size: 18,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        restaurant.rating
                            .toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    restaurant.description.trim().isEmpty
                        ? restaurant.categories.join(' • ')
                        : restaurant.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 7,
                    children: <Widget>[
                      _infoTag(
                        Icons.schedule,
                        '${restaurant.minimumDeliveryTimeMinutes}-${restaurant.maximumDeliveryTimeMinutes} min',
                      ),
                      _infoTag(
                        Icons.delivery_dining,
                        restaurant.deliveryFee <= 0
                            ? 'Free delivery'
                            : 'Rs. ${restaurant.deliveryFee.toStringAsFixed(0)}',
                      ),
                      _infoTag(
                        Icons.location_on_outlined,
                        '${restaurant.area}, ${restaurant.city}',
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

  static Widget _badge(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Widget _infoTag(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          color: yellow,
          size: 15,
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
    );
  }
}
