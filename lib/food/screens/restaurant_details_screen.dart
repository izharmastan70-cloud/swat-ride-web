// lib/food/screens/restaurant_details_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Customer Restaurant Details & Digital Menu Screen
//
// Connected with:
// - RestaurantModel
// - RestaurantMenuCategoryModel
// - RestaurantFoodItemModel
// - FoodCategoryService
// - FoodItemService
//
// Real features:
// - Restaurant information
// - Live customer-visible categories
// - Live approved food items
// - Search and category filtering
// - Food item details bottom sheet
// - Add-to-cart route preparation
//
// Firebase Storage images remain bypassed.
// =============================================================

import 'package:flutter/material.dart';

import '../models/restaurant_model.dart';
import '../restaurant_partner/models/food_category_model.dart';
import '../restaurant_partner/models/food_item_model.dart';
import '../restaurant_partner/services/food_category_service.dart';
import '../restaurant_partner/services/food_item_service.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  const RestaurantDetailsScreen({
    required this.restaurant,
    super.key,
  });

  final RestaurantModel restaurant;

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState
    extends State<RestaurantDetailsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodCategoryService _categoryService =
      FoodCategoryService();

  final FoodItemService _foodItemService =
      FoodItemService();

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedCategoryId = 'all';
  String _searchText = '';

  RestaurantModel get restaurant => widget.restaurant;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _restaurantOpen {
    return restaurant.isOpen &&
        restaurant.isActive &&
        !restaurant.isTemporarilyClosed &&
        !restaurant.isSuspended;
  }

  List<RestaurantFoodItemModel> _filterItems(
    List<RestaurantFoodItemModel> items,
  ) {
    final String query =
        _searchText.trim().toLowerCase();

    return items.where(
      (RestaurantFoodItemModel item) {
        final bool categoryMatches =
            _selectedCategoryId == 'all' ||
            item.categoryId == _selectedCategoryId;

        if (!categoryMatches) {
          return false;
        }

        if (query.isEmpty) {
          return true;
        }

        final String searchable = <String>[
          item.name,
          item.description,
          item.shortDescription,
          item.spiceLevel,
          ...item.ingredients,
          ...item.tags,
        ].join(' ').toLowerCase();

        return searchable.contains(query);
      },
    ).toList();
  }

  void _openCart() {
    Navigator.pushNamed(
      context,
      '/food_cart',
    );
  }

  void _showFoodItem(
    RestaurantFoodItemModel item,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return _FoodItemDetailsSheet(
          restaurant: restaurant,
          item: item,
          restaurantOpen: _restaurantOpen,
          onAddToCart: () {
            Navigator.pop(sheetContext);

            Navigator.pushNamed(
              context,
              '/food_item_details',
              arguments: <String, dynamic>{
                'restaurant': restaurant,
                'item': item,
              },
            );
          },
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
        title: Text(
          restaurant.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Cart',
            onPressed: _openCart,
            icon: const Icon(
              Icons.shopping_cart_outlined,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<
            List<RestaurantMenuCategoryModel>>(
          stream:
              _categoryService.watchCustomerCategories(
            restaurant.id,
          ),
          builder: (
            BuildContext context,
            AsyncSnapshot<
                    List<RestaurantMenuCategoryModel>>
                categorySnapshot,
          ) {
            final List<RestaurantMenuCategoryModel>
                categories =
                categorySnapshot.data ??
                    const <
                        RestaurantMenuCategoryModel>[];

            return StreamBuilder<
                List<RestaurantFoodItemModel>>(
              stream:
                  _foodItemService.watchCustomerFoodItems(
                restaurant.id,
              ),
              builder: (
                BuildContext context,
                AsyncSnapshot<
                        List<RestaurantFoodItemModel>>
                    itemSnapshot,
              ) {
                if (categorySnapshot.hasError ||
                    itemSnapshot.hasError) {
                  return _buildErrorState();
                }

                final List<RestaurantFoodItemModel>
                    items =
                    _filterItems(
                  itemSnapshot.data ??
                      const <
                          RestaurantFoodItemModel>[],
                );

                return CustomScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: _buildRestaurantHeader(),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          0,
                        ),
                        child: Column(
                          children: <Widget>[
                            _buildSearchField(),
                            const SizedBox(height: 14),
                            _buildCategorySelector(
                              categories,
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: <Widget>[
                                const Expanded(
                                  child: Text(
                                    'Menu',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${items.length} item(s)',
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
                    if ((categorySnapshot
                                    .connectionState ==
                                ConnectionState.waiting ||
                            itemSnapshot.connectionState ==
                                ConnectionState.waiting) &&
                        !categorySnapshot.hasData &&
                        !itemSnapshot.hasData)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child:
                              CircularProgressIndicator(
                            color: yellow,
                          ),
                        ),
                      )
                    else if (items.isEmpty)
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
                          itemCount: items.length,
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
                            final RestaurantFoodItemModel
                                item =
                                items[index];

                            return _CustomerFoodItemCard(
                              item: item,
                              restaurantOpen:
                                  _restaurantOpen,
                              onTap: () =>
                                  _showFoodItem(item),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildRestaurantHeader() {
    return Column(
      children: <Widget>[
        Container(
          height: 190,
          width: double.infinity,
          color: const Color(0xFF272727),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const Center(
                child: Icon(
                  Icons.restaurant,
                  color: yellow,
                  size: 70,
                ),
              ),
              Positioned(
                left: 16,
                top: 14,
                child: _statusBadge(
                  _restaurantOpen
                      ? 'OPEN'
                      : 'CLOSED',
                  _restaurantOpen
                      ? Colors.greenAccent
                      : Colors.redAccent,
                ),
              ),
              if (restaurant.discountPercentage > 0)
                Positioned(
                  right: 16,
                  top: 14,
                  child: _statusBadge(
                    '${restaurant.discountPercentage.toStringAsFixed(0)}% OFF',
                    yellow,
                  ),
                ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(22),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.star,
                    color: yellow,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    restaurant.rating
                        .toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                restaurant.description.trim().isEmpty
                    ? restaurant.categories.join(' • ')
                    : restaurant.description,
                style: const TextStyle(
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 12,
                runSpacing: 9,
                children: <Widget>[
                  _infoTag(
                    Icons.schedule,
                    '${restaurant.minimumDeliveryTimeMinutes}-${restaurant.maximumDeliveryTimeMinutes} min',
                  ),
                  _infoTag(
                    Icons.delivery_dining,
                    restaurant.deliveryFee <= 0
                        ? 'Free delivery'
                        : 'Delivery Rs. ${restaurant.deliveryFee.toStringAsFixed(0)}',
                  ),
                  _infoTag(
                    Icons.shopping_bag_outlined,
                    'Min Rs. ${restaurant.minimumOrderAmount.toStringAsFixed(0)}',
                  ),
                  _infoTag(
                    Icons.location_on_outlined,
                    '${restaurant.area}, ${restaurant.city}',
                  ),
                ],
              ),
              if (restaurant.isTemporarilyClosed) ...<Widget>[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Text(
                    restaurant
                            .temporaryClosingReason
                            .trim()
                            .isEmpty
                        ? 'Restaurant is temporarily closed.'
                        : restaurant
                            .temporaryClosingReason,
                    style: const TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
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
        hintText: 'Search food item',
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

  Widget _buildCategorySelector(
    List<RestaurantMenuCategoryModel> categories,
  ) {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (
          BuildContext context,
          int index,
        ) =>
            const SizedBox(width: 8),
        itemBuilder: (
          BuildContext context,
          int index,
        ) {
          if (index == 0) {
            return _categoryChip(
              id: 'all',
              title: 'All',
            );
          }

          final RestaurantMenuCategoryModel category =
              categories[index - 1];

          return _categoryChip(
            id: category.id,
            title: category.name,
          );
        },
      ),
    );
  }

  Widget _categoryChip({
    required String id,
    required String title,
  }) {
    final bool selected =
        _selectedCategoryId == id;

    return ChoiceChip(
      label: Text(title),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedCategoryId = id;
        });
      },
      selectedColor: yellow,
      backgroundColor: cardColor,
      checkmarkColor: Colors.black,
      labelStyle: TextStyle(
        color:
            selected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
      ),
      side: BorderSide.none,
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.fastfood_outlined,
            color: yellow,
            size: 76,
          ),
          SizedBox(height: 16),
          Text(
            'No food items found',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try another search or category.',
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Text(
          'Unable to load the restaurant menu. Check Firestore connection and security rules.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
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

  Widget _infoTag(
    IconData icon,
    String text,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          color: yellow,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _CustomerFoodItemCard extends StatelessWidget {
  const _CustomerFoodItemCard({
    required this.item,
    required this.restaurantOpen,
    required this.onTap,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final RestaurantFoodItemModel item;
  final bool restaurantOpen;
  final VoidCallback onTap;

  bool get _available {
    return restaurantOpen &&
        item.canShowToCustomer;
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _available ? 1 : 0.6,
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFF272727),
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.fastfood,
                    color: yellow,
                    size: 38,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          if (item.isPopular)
                            const Icon(
                              Icons
                                  .local_fire_department,
                              color:
                                  Colors.orangeAccent,
                              size: 19,
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.shortDescription
                                .trim()
                                .isEmpty
                            ? item.description
                            : item.shortDescription,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: <Widget>[
                          Text(
                            item.priceText,
                            style: const TextStyle(
                              color: yellow,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          if (item.hasDiscount) ...<Widget>[
                            const SizedBox(width: 7),
                            Text(
                              item.originalPriceText,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                decoration:
                                    TextDecoration
                                        .lineThrough,
                              ),
                            ),
                          ],
                          const Spacer(),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                _available
                                    ? yellow
                                    : Colors.grey,
                            child: Icon(
                              _available
                                  ? Icons.add
                                  : Icons.block,
                              color: Colors.black,
                              size: 19,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          _smallTag(
                            Icons.schedule,
                            '${item.preparationTimeMinutes} min',
                          ),
                          if (item.hasVariants)
                            _smallTag(
                              Icons.tune,
                              '${item.variants.length} options',
                            ),
                          if (!_available)
                            _smallTag(
                              Icons.block,
                              'Unavailable',
                              warning: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _smallTag(
    IconData icon,
    String text, {
    bool warning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: warning
            ? Colors.red.withValues(alpha: 0.12)
            : const Color(0xFF272727),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            color: warning
                ? Colors.redAccent
                : yellow,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: warning
                  ? Colors.redAccent
                  : Colors.grey,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodItemDetailsSheet extends StatelessWidget {
  const _FoodItemDetailsSheet({
    required this.restaurant,
    required this.item,
    required this.restaurantOpen,
    required this.onAddToCart,
  });

  static const Color yellow = Color(0xFFFFD60A);

  final RestaurantModel restaurant;
  final RestaurantFoodItemModel item;
  final bool restaurantOpen;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final bool available =
        restaurantOpen &&
        item.canShowToCustomer;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom:
              MediaQuery.of(context).viewInsets.bottom +
                  18,
        ),
        child: SingleChildScrollView(
          child: Column(
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
              Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF272727),
                  borderRadius:
                      BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.fastfood,
                  color: yellow,
                  size: 64,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                item.description,
                style: const TextStyle(
                  color: Colors.grey,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                item.priceText,
                style: const TextStyle(
                  color: yellow,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.hasDiscount)
                Text(
                  item.originalPriceText,
                  style: const TextStyle(
                    color: Colors.grey,
                    decoration:
                        TextDecoration.lineThrough,
                  ),
                ),
              if (item.ingredients.isNotEmpty) ...<Widget>[
                const SizedBox(height: 18),
                const Text(
                  'Ingredients',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  item.ingredients.join(', '),
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
              if (item.allergens.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                const Text(
                  'Allergens',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  item.allergens.join(', '),
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed:
                      available ? onAddToCart : null,
                  icon: const Icon(
                    Icons.add_shopping_cart,
                  ),
                  label: Text(
                    available
                        ? 'Choose Options & Add to Cart'
                        : 'Currently Unavailable',
                    style: const TextStyle(
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
            ],
          ),
        ),
      ),
    );
  }
}
