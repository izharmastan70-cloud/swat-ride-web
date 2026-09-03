// lib/food/restaurant_partner/screens/menu_management_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Partner Menu Management Screen
//
// Connected with:
// - RestaurantPartnerModel
// - RestaurantMenuCategoryModel
// - RestaurantFoodItemModel
// - FoodCategoryService
// - FoodItemService
//
// Features:
// - Live categories
// - Live food items
// - Search
// - Category filter
// - Availability toggle
// - Edit/delete actions
// - Add category / add food item navigation
//
// Firebase Storage image upload remains bypassed.
// =============================================================

import 'package:flutter/material.dart';

import '../models/food_category_model.dart';
import '../models/food_item_model.dart';
import '../models/restaurant_partner_model.dart';
import '../services/food_category_service.dart';
import '../services/food_item_service.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({required this.partner, super.key});

  final RestaurantPartnerModel partner;

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodCategoryService _categoryService = FoodCategoryService();

  final FoodItemService _foodItemService = FoodItemService();

  final TextEditingController _searchController = TextEditingController();

  String _selectedCategoryId = 'all';
  String _searchText = '';
  bool _isUpdating = false;

  RestaurantPartnerModel get partner => widget.partner;

  String get restaurantId => partner.restaurantId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openAddCategory() {
    Navigator.pushNamed(
      context,
      '/food_partner_add_category',
      arguments: partner,
    );
  }

  void _openAddFoodItem() {
    Navigator.pushNamed(
      context,
      '/food_partner_add_menu_item',
      arguments: partner,
    );
  }

  void _openEditFoodItem(RestaurantFoodItemModel item) {
    Navigator.pushNamed(
      context,
      '/food_partner_edit_menu_item',
      arguments: <String, dynamic>{'partner': partner, 'item': item},
    );
  }

  List<RestaurantFoodItemModel> _filterItems(
    List<RestaurantFoodItemModel> items,
  ) {
    final String query = _searchText.trim().toLowerCase();

    return items.where((RestaurantFoodItemModel item) {
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
        ...item.tags,
        ...item.ingredients,
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  Future<void> _toggleAvailability(
    RestaurantFoodItemModel item,
    bool value,
  ) async {
    if (_isUpdating) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _foodItemService.setAvailability(
        restaurantId: restaurantId,
        foodItemId: item.id,
        isAvailable: value,
      );

      _showMessage(
        value
            ? '${item.name} is now available.'
            : '${item.name} is now unavailable.',
      );
    } on FoodItemServiceException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Unable to update item: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _deleteFoodItem(RestaurantFoodItemModel item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Delete food item?'),
          content: Text(
            '${item.name} will be permanently removed from the restaurant menu.',
            style: const TextStyle(color: Colors.grey, height: 1.4),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _foodItemService.deleteFoodItem(
        restaurantId: restaurantId,
        foodItemId: item.id,
      );

      _showMessage('${item.name} deleted.');
    } on FoodItemServiceException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Unable to delete food item: $error');
    }
  }

  Future<void> _deleteCategory(RestaurantMenuCategoryModel category) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Delete category?'),
          content: Text(
            category.totalItems > 0
                ? 'This category still contains ${category.totalItems} food item(s). Move or delete them first.'
                : '${category.name} will be permanently removed.',
            style: const TextStyle(color: Colors.grey, height: 1.4),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            if (category.totalItems == 0)
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _categoryService.deleteCategory(
        restaurantId: restaurantId,
        categoryId: category.id,
      );

      if (_selectedCategoryId == category.id) {
        setState(() {
          _selectedCategoryId = 'all';
        });
      }

      _showMessage('${category.name} deleted.');
    } on FoodCategoryServiceException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Unable to delete category: $error');
    }
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
          'Menu Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            color: cardColor,
            onSelected: (String value) {
              if (value == 'category') {
                _openAddCategory();
              } else if (value == 'item') {
                _openAddFoodItem();
              }
            },
            itemBuilder: (BuildContext context) {
              return const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'category',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.create_new_folder_outlined, color: yellow),
                      SizedBox(width: 10),
                      Text('Add Category'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'item',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.add_circle_outline, color: yellow),
                      SizedBox(width: 10),
                      Text('Add Food Item'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddFoodItem,
        backgroundColor: yellow,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Food',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<RestaurantMenuCategoryModel>>(
          stream: _categoryService.watchOwnerCategories(restaurantId),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<RestaurantMenuCategoryModel>>
                categorySnapshot,
              ) {
                final List<RestaurantMenuCategoryModel> categories =
                    categorySnapshot.data ??
                    const <RestaurantMenuCategoryModel>[];

                return StreamBuilder<List<RestaurantFoodItemModel>>(
                  stream: _foodItemService.watchOwnerFoodItems(restaurantId),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<List<RestaurantFoodItemModel>>
                        itemSnapshot,
                      ) {
                        final List<RestaurantFoodItemModel> allItems =
                            itemSnapshot.data ??
                            const <RestaurantFoodItemModel>[];

                        final List<RestaurantFoodItemModel> visibleItems =
                            _filterItems(allItems);

                        if (categorySnapshot.hasError ||
                            itemSnapshot.hasError) {
                          return _buildErrorState();
                        }

                        return RefreshIndicator(
                          color: yellow,
                          onRefresh: () async {
                            setState(() {});
                          },
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: <Widget>[
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      _buildSummaryCard(
                                        categoryCount: categories.length,
                                        itemCount: allItems.length,
                                        availableCount: allItems
                                            .where(
                                              (RestaurantFoodItemModel item) =>
                                                  item.isAvailable,
                                            )
                                            .length,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildSearchField(),
                                      const SizedBox(height: 18),
                                      _buildCategorySection(categories),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: <Widget>[
                                          const Expanded(
                                            child: Text(
                                              'Food Items',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${visibleItems.length}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),
                              ),
                              if ((categorySnapshot.connectionState ==
                                          ConnectionState.waiting ||
                                      itemSnapshot.connectionState ==
                                          ConnectionState.waiting) &&
                                  !categorySnapshot.hasData &&
                                  !itemSnapshot.hasData)
                                const SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: yellow,
                                    ),
                                  ),
                                )
                              else if (visibleItems.isEmpty)
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: _buildEmptyItems(),
                                )
                              else
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    100,
                                  ),
                                  sliver: SliverList.separated(
                                    itemCount: visibleItems.length,
                                    separatorBuilder:
                                        (BuildContext context, int index) =>
                                            const SizedBox(height: 12),
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                          final RestaurantFoodItemModel item =
                                              visibleItems[index];

                                          return _FoodItemManagementCard(
                                            item: item,
                                            isUpdating: _isUpdating,
                                            onAvailabilityChanged:
                                                (bool value) =>
                                                    _toggleAvailability(
                                                      item,
                                                      value,
                                                    ),
                                            onEdit: () =>
                                                _openEditFoodItem(item),
                                            onDelete: () =>
                                                _deleteFoodItem(item),
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
      ),
    );
  }

  Widget _buildSummaryCard({
    required int categoryCount,
    required int itemCount,
    required int availableCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.restaurant_menu, color: Colors.black, size: 46),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Digital Menu',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$categoryCount categories â€¢ '
                  '$itemCount items â€¢ '
                  '$availableCount available',
                  style: const TextStyle(color: Colors.black87, fontSize: 12),
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
        hintText: 'Search food item',
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
    );
  }

  Widget _buildCategorySection(List<RestaurantMenuCategoryModel> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Categories',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: _openAddCategory,
              icon: const Icon(Icons.add, color: yellow),
              label: const Text(
                'Add',
                style: TextStyle(color: yellow, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return _CategoryChipCard(
                  title: 'All',
                  itemCount: categories.fold<int>(
                    0,
                    (int total, RestaurantMenuCategoryModel category) =>
                        total + category.totalItems,
                  ),
                  selected: _selectedCategoryId == 'all',
                  icon: Icons.grid_view_rounded,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = 'all';
                    });
                  },
                  onLongPress: null,
                );
              }

              final RestaurantMenuCategoryModel category =
                  categories[index - 1];

              return _CategoryChipCard(
                title: category.name,
                itemCount: category.totalItems,
                selected: _selectedCategoryId == category.id,
                icon: Icons.folder_outlined,
                onTap: () {
                  setState(() {
                    _selectedCategoryId = category.id;
                  });
                },
                onLongPress: () => _deleteCategory(category),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyItems() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.fastfood_outlined, color: yellow, size: 72),
          const SizedBox(height: 16),
          const Text(
            'No food items found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _searchText.isNotEmpty || _selectedCategoryId != 'all'
                ? 'Try another search or category.'
                : 'Add your first food item to start building the restaurant menu.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openAddFoodItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: Colors.black,
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Add Food Item',
              style: TextStyle(fontWeight: FontWeight.bold),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.cloud_off, color: Colors.redAccent, size: 70),
            const SizedBox(height: 16),
            const Text(
              'Unable to load menu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget _buildMissingRestaurant() {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text('Menu Management'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            'Approved restaurant ID is missing. '
            'Please wait for admin approval or contact support.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
        ),
      ),
    );
  }
}

class _CategoryChipCard extends StatelessWidget {
  const _CategoryChipCard({
    required this.title,
    required this.itemCount,
    required this.selected,
    required this.icon,
    required this.onTap,
    required this.onLongPress,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final String title;
  final int itemCount;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? yellow : cardColor,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: 95,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: selected ? Colors.black : yellow),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$itemCount item(s)',
                style: TextStyle(
                  color: selected ? Colors.black87 : Colors.grey,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodItemManagementCard extends StatelessWidget {
  const _FoodItemManagementCard({
    required this.item,
    required this.isUpdating,
    required this.onAvailabilityChanged,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final RestaurantFoodItemModel item;
  final bool isUpdating;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color get _statusColor {
    switch (item.status) {
      case RestaurantFoodItemStatus.active:
        return Colors.greenAccent;
      case RestaurantFoodItemStatus.outOfStock:
        return Colors.orangeAccent;
      case RestaurantFoodItemStatus.rejected:
        return Colors.redAccent;
      case RestaurantFoodItemStatus.pendingApproval:
        return Colors.lightBlueAccent;
      case RestaurantFoodItemStatus.hidden:
      case RestaurantFoodItemStatus.draft:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFF262626),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.fastfood, color: yellow, size: 36),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      color: cardColor,
                      onSelected: (String value) {
                        if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return const <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.edit_outlined, color: yellow),
                                SizedBox(width: 10),
                                Text('Edit'),
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
                const SizedBox(height: 3),
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
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Text(
                      item.priceText,
                      style: const TextStyle(
                        color: yellow,
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
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.status.value.replaceAll('_', ' '),
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.stockText,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Switch(
                      value: item.isAvailable,
                      onChanged: isUpdating ? null : onAvailabilityChanged,
                      activeThumbColor: yellow,
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
}
