// lib/food/restaurant_partner/screens/menu_preview_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Partner Menu Preview Screen
//
// Connected with:
// - RestaurantPartnerModel
// - RestaurantMenuCategoryModel
// - RestaurantFoodItemModel
// - FoodCategoryService
// - FoodItemService
//
// Purpose:
// Restaurant Partner can preview the same digital menu structure
// customers will see.
//
// Firebase Storage image upload remains bypassed, so local image
// paths are displayed as file names/placeholders.
// =============================================================

import 'package:flutter/material.dart';

import '../models/food_category_model.dart';
import '../models/food_item_model.dart';
import '../models/restaurant_partner_model.dart';
import '../services/food_category_service.dart';
import '../services/food_item_service.dart';

class MenuPreviewScreen extends StatefulWidget {
  const MenuPreviewScreen({
    required this.partner,
    super.key,
  });

  final RestaurantPartnerModel partner;

  @override
  State<MenuPreviewScreen> createState() =>
      _MenuPreviewScreenState();
}

class _MenuPreviewScreenState
    extends State<MenuPreviewScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodCategoryService _categoryService =
      FoodCategoryService();

  final FoodItemService _foodItemService =
      FoodItemService();

  String _selectedCategoryId = 'all';

  RestaurantPartnerModel get partner => widget.partner;

  String get restaurantId => partner.restaurantId;

  List<RestaurantFoodItemModel> _filterItems(
    List<RestaurantFoodItemModel> items,
  ) {
    return items.where(
      (RestaurantFoodItemModel item) {
        final bool categoryMatches =
            _selectedCategoryId == 'all' ||
            item.categoryId == _selectedCategoryId;

        return categoryMatches;
      },
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (restaurantId.trim().isEmpty) {
      return _buildMissingRestaurant();
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Menu Preview',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<
            List<RestaurantMenuCategoryModel>>(
          stream:
              _categoryService.watchOwnerCategories(
            restaurantId,
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
                  _foodItemService.watchOwnerFoodItems(
                restaurantId,
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
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: _buildRestaurantHeader(),
                    ),
                    SliverToBoxAdapter(
                      child: _buildCategorySelector(
                        categories,
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
                          16,
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
                            return _PreviewFoodCard(
                              item: items[index],
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
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        12,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 31,
            backgroundColor: Colors.black,
            child: Icon(
              Icons.restaurant,
              color: yellow,
              size: 33,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  partner.restaurantName.trim().isEmpty
                      ? 'Restaurant Menu'
                      : partner.restaurantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${partner.area}, ${partner.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Minimum order Rs. ${partner.minimumOrderAmount.toStringAsFixed(0)}'
                  ' • Delivery Rs. ${partner.deliveryFee.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(
    List<RestaurantMenuCategoryModel> categories,
  ) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
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
        color: selected
            ? Colors.black
            : Colors.white,
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
            Icons.restaurant_menu,
            color: yellow,
            size: 72,
          ),
          SizedBox(height: 16),
          Text(
            'No menu items available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add food items from Menu Management to preview them here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              height: 1.4,
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
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.cloud_off,
              color: Colors.redAccent,
              size: 70,
            ),
            SizedBox(height: 16),
            Text(
              'Unable to load menu preview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Check Firebase connection and Firestore rules.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingRestaurant() {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Menu Preview',
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            'Approved restaurant ID is missing.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewFoodCard extends StatelessWidget {
  const _PreviewFoodCard({
    required this.item,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final RestaurantFoodItemModel item;

  String get _imageName {
    final String path =
        item.mainLocalImagePath.trim();

    if (path.isEmpty) {
      return 'No image';
    }

    return path
        .replaceAll('\\', '/')
        .split('/')
        .last;
  }

  @override
  Widget build(BuildContext context) {
    final bool unavailable =
        !item.isAvailable || item.isOutOfStock;

    return Opacity(
      opacity: unavailable ? 0.58 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: Colors.white10,
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: const Color(0xFF262626),
                borderRadius:
                    BorderRadius.circular(15),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.fastfood,
                    color: yellow,
                    size: 34,
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 5,
                    ),
                    child: Text(
                      _imageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
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
                          Icons.local_fire_department,
                          color: Colors.orangeAccent,
                          size: 19,
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.shortDescription.trim().isEmpty
                        ? item.description
                        : item.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                          fontWeight: FontWeight.bold,
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
                                TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      _tag(
                        Icons.schedule,
                        '${item.preparationTimeMinutes} min',
                      ),
                      if (item.hasVariants)
                        _tag(
                          Icons.tune,
                          '${item.variants.length} variants',
                        ),
                      if (item.hasAddOns)
                        _tag(
                          Icons.add_box_outlined,
                          '${item.addOns.length} extras',
                        ),
                      if (unavailable)
                        _tag(
                          Icons.block,
                          'Unavailable',
                          isWarning: true,
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

  Widget _tag(
    IconData icon,
    String text, {
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isWarning
            ? Colors.red.withValues(alpha: 0.12)
            : const Color(0xFF262626),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 12,
            color:
                isWarning ? Colors.redAccent : yellow,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: isWarning
                  ? Colors.redAccent
                  : Colors.grey,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
