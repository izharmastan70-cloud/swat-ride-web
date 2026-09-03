// lib/food/restaurant_partner/screens/add_food_item_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Add / Edit Restaurant Food Item Screen
//
// Connected with:
// - RestaurantPartnerModel
// - RestaurantMenuCategoryModel
// - RestaurantFoodItemModel
// - FoodCategoryService
// - FoodItemService
// - FoodVariantAddonEditor
//
// Firebase Storage image upload remains bypassed.
// Temporary local image paths are used.
// =============================================================

import 'package:flutter/material.dart';

import '../models/food_category_model.dart';
import '../models/food_item_model.dart';
import '../models/restaurant_partner_model.dart';
import '../services/food_category_service.dart';
import '../services/food_item_service.dart';
import '../widgets/food_variant_addon_editor.dart';

class AddFoodItemScreen extends StatefulWidget {
  const AddFoodItemScreen({required this.partner, this.item, super.key});

  final RestaurantPartnerModel partner;
  final RestaurantFoodItemModel? item;

  bool get isEditing => item != null;

  @override
  State<AddFoodItemScreen> createState() => _AddFoodItemScreenState();
}

class _AddFoodItemScreenState extends State<AddFoodItemScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FoodCategoryService _categoryService = FoodCategoryService();

  final FoodItemService _foodItemService = FoodItemService();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _shortDescriptionController =
      TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _originalPriceController =
      TextEditingController();

  final TextEditingController _discountedPriceController =
      TextEditingController();

  final TextEditingController _preparationTimeController =
      TextEditingController(text: '20');

  final TextEditingController _servingSizeController = TextEditingController();

  final TextEditingController _weightController = TextEditingController();

  final TextEditingController _ingredientsController = TextEditingController();

  final TextEditingController _allergensController = TextEditingController();

  final TextEditingController _tagsController = TextEditingController();

  final TextEditingController _dailyStockController = TextEditingController(
    text: '0',
  );

  final TextEditingController _remainingStockController = TextEditingController(
    text: '0',
  );

  final TextEditingController _sortOrderController = TextEditingController(
    text: '0',
  );

  String _selectedCategoryId = '';
  RestaurantFoodType _foodType = RestaurantFoodType.other;
  String _spiceLevel = 'none';

  String _mainLocalImagePath = '';
  final List<String> _localImagePaths = <String>[];

  final List<RestaurantFoodVariantModel> _variants =
      <RestaurantFoodVariantModel>[];

  final List<RestaurantFoodAddOnModel> _addOns = <RestaurantFoodAddOnModel>[];

  bool _hasDiscount = false;
  bool _trackStock = false;
  bool _isAvailable = true;
  bool _isVisible = true;
  bool _isFeatured = false;
  bool _isPopular = false;
  bool _isRecommended = false;
  bool _promoEligible = true;
  bool _isSaving = false;

  RestaurantPartnerModel get partner => widget.partner;

  @override
  void initState() {
    super.initState();

    final RestaurantFoodItemModel? item = widget.item;

    if (item == null) {
      return;
    }

    _nameController.text = item.name;
    _shortDescriptionController.text = item.shortDescription;
    _descriptionController.text = item.description;
    _originalPriceController.text = item.originalPrice.toStringAsFixed(0);
    _discountedPriceController.text = item.discountedPrice.toStringAsFixed(0);
    _preparationTimeController.text = item.preparationTimeMinutes.toString();
    _servingSizeController.text = item.servingSize;
    _weightController.text = item.weightText;
    _ingredientsController.text = item.ingredients.join(', ');
    _allergensController.text = item.allergens.join(', ');
    _tagsController.text = item.tags.join(', ');
    _dailyStockController.text = item.dailyStockQuantity < 0
        ? '0'
        : item.dailyStockQuantity.toString();
    _remainingStockController.text = item.remainingStockQuantity < 0
        ? '0'
        : item.remainingStockQuantity.toString();
    _sortOrderController.text = item.sortOrder.toString();

    _selectedCategoryId = item.categoryId;
    _foodType = item.foodType;
    _spiceLevel = item.spiceLevel;
    _mainLocalImagePath = item.mainLocalImagePath;

    _localImagePaths.addAll(item.localImagePaths);

    _variants.addAll(item.variants);
    _addOns.addAll(item.addOns);

    _hasDiscount = item.hasDiscount;
    _trackStock = item.trackStock;
    _isAvailable = item.isAvailable;
    _isVisible = item.isVisible;
    _isFeatured = item.isFeatured;
    _isPopular = item.isPopular;
    _isRecommended = item.isRecommended;
    _promoEligible = item.promoEligible;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _preparationTimeController.dispose();
    _servingSizeController.dispose();
    _weightController.dispose();
    _ingredientsController.dispose();
    _allergensController.dispose();
    _tagsController.dispose();
    _dailyStockController.dispose();
    _remainingStockController.dispose();
    _sortOrderController.dispose();
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

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $field';
    }

    return null;
  }

  String? _positiveNumber(
    String? value,
    String field, {
    bool allowZero = true,
  }) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Please enter $field';
    }

    final double? number = double.tryParse(text);

    if (number == null) {
      return 'Enter a valid number';
    }

    if (allowZero) {
      if (number < 0) {
        return '$field cannot be negative';
      }
    } else if (number <= 0) {
      return '$field must be greater than zero';
    }

    return null;
  }

  Future<String?> _requestLocalPath({
    required String title,
    required String hint,
  }) async {
    final TextEditingController controller = TextEditingController();

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Local image path',
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFF252525),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
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
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Use Path'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  List<String> _commaSeparatedValues(String raw) {
    return raw
        .split(',')
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  double _doubleValue(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  int _intValue(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  double _discountPercentage({
    required double originalPrice,
    required double discountedPrice,
  }) {
    if (!_hasDiscount ||
        originalPrice <= 0 ||
        discountedPrice <= 0 ||
        discountedPrice >= originalPrice) {
      return 0;
    }

    return ((originalPrice - discountedPrice) / originalPrice) * 100;
  }

  bool _validateCustomRequirements() {
    if (_selectedCategoryId.trim().isEmpty) {
      _showMessage('Please select a food category.');
      return false;
    }

    final double originalPrice = _doubleValue(_originalPriceController);

    final double discountedPrice = _doubleValue(_discountedPriceController);

    if (_hasDiscount &&
        (discountedPrice <= 0 || discountedPrice >= originalPrice)) {
      _showMessage('Discounted price must be lower than the original price.');
      return false;
    }

    if (_trackStock) {
      final int daily = _intValue(_dailyStockController);
      final int remaining = _intValue(_remainingStockController);

      if (daily < 0 || remaining < 0) {
        _showMessage('Stock quantities cannot be negative.');
        return false;
      }
    }

    return true;
  }

  Future<void> _saveFoodItem() async {
    if (_isSaving) {
      return;
    }

    final bool formValid = _formKey.currentState?.validate() ?? false;

    if (!formValid || !_validateCustomRequirements()) {
      return;
    }

    if (partner.restaurantId.trim().isEmpty) {
      _showMessage('Approved restaurant ID is missing.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final DateTime now = DateTime.now();
      final RestaurantFoodItemModel? existing = widget.item;

      final double originalPrice = _doubleValue(_originalPriceController);

      final double discountedPrice = _doubleValue(_discountedPriceController);

      final bool validDiscount =
          _hasDiscount &&
          discountedPrice > 0 &&
          discountedPrice < originalPrice;

      final RestaurantFoodItemModel item = RestaurantFoodItemModel(
        id: existing?.id ?? '',
        restaurantId: partner.restaurantId,
        partnerId: partner.partnerId,
        categoryId: _selectedCategoryId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        shortDescription: _shortDescriptionController.text.trim(),
        foodType: _foodType,
        spiceLevel: _spiceLevel,
        ingredients: _commaSeparatedValues(_ingredientsController.text),
        allergens: _commaSeparatedValues(_allergensController.text),
        tags: _commaSeparatedValues(_tagsController.text),
        mainImageUrl: existing?.mainImageUrl ?? '',
        mainLocalImagePath: _mainLocalImagePath,
        imageUrls: existing?.imageUrls ?? const <String>[],
        localImagePaths: List<String>.unmodifiable(_localImagePaths),
        originalPrice: originalPrice,
        discountedPrice: validDiscount ? discountedPrice : 0,
        discountPercentage: _discountPercentage(
          originalPrice: originalPrice,
          discountedPrice: discountedPrice,
        ),
        hasDiscount: validDiscount,
        variants: List<RestaurantFoodVariantModel>.unmodifiable(_variants),
        addOns: List<RestaurantFoodAddOnModel>.unmodifiable(_addOns),
        servingSize: _servingSizeController.text.trim(),
        weightText: _weightController.text.trim(),
        preparationTimeMinutes: _intValue(_preparationTimeController),
        trackStock: _trackStock,
        dailyStockQuantity: _trackStock ? _intValue(_dailyStockController) : -1,
        remainingStockQuantity: _trackStock
            ? _intValue(_remainingStockController)
            : -1,
        status: RestaurantFoodItemStatus.pendingApproval,
        isAvailable: _isAvailable,
        isVisible: _isVisible,
        isFeatured: _isFeatured,
        isPopular: _isPopular,
        isRecommended: _isRecommended,
        approvedByAdmin: existing?.approvedByAdmin ?? false,
        rejectionReason: '',
        promoEligible: _promoEligible,
        promoCodeIds: existing?.promoCodeIds ?? const <String>[],
        rating: existing?.rating ?? 0,
        totalReviews: existing?.totalReviews ?? 0,
        totalLikes: existing?.totalLikes ?? 0,
        totalOrders: existing?.totalOrders ?? 0,
        sortOrder: _intValue(_sortOrderController),
        createdBy: partner.userId,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.isEditing) {
        await _foodItemService.updateFoodItem(item);
      } else {
        await _foodItemService.createFoodItem(item);
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        widget.isEditing
            ? 'Food item updated successfully.'
            : 'Food item created successfully.',
      );

      Navigator.pop(context, true);
    } on FoodItemServiceException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Unable to save food item: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: Text(
          widget.isEditing ? 'Edit Food Item' : 'Add Food Item',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<RestaurantMenuCategoryModel>>(
          stream: _categoryService.watchOwnerCategories(partner.restaurantId),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<RestaurantMenuCategoryModel>> snapshot,
              ) {
                final List<RestaurantMenuCategoryModel> categories =
                    snapshot.data ?? const <RestaurantMenuCategoryModel>[];

                return Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                    children: <Widget>[
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildBasicInformation(categories),
                      const SizedBox(height: 16),
                      _buildPricingCard(),
                      const SizedBox(height: 16),
                      _buildFoodDetailsCard(),
                      const SizedBox(height: 16),
                      _buildImagesCard(),
                      const SizedBox(height: 16),
                      FoodVariantAddonEditor(
                        variants: _variants,
                        addOns: _addOns,
                        onVariantsChanged:
                            (List<RestaurantFoodVariantModel> values) {
                              setState(() {
                                _variants
                                  ..clear()
                                  ..addAll(values);
                              });
                            },
                        onAddOnsChanged:
                            (List<RestaurantFoodAddOnModel> values) {
                              setState(() {
                                _addOns
                                  ..clear()
                                  ..addAll(values);
                              });
                            },
                      ),
                      const SizedBox(height: 16),
                      _buildStockCard(),
                      const SizedBox(height: 16),
                      _buildVisibilityCard(),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveFoodItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: yellow,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  widget.isEditing
                                      ? 'Update Food Item'
                                      : 'Create Food Item',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.fastfood, color: Colors.black, size: 48),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.isEditing ? 'Update Food Item' : 'Create Food Item',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Add complete food details for customers.',
                  style: TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInformation(List<RestaurantMenuCategoryModel> categories) {
    return _sectionCard(
      title: 'Basic Information',
      icon: Icons.info_outline,
      children: <Widget>[
        TextFormField(
          controller: _nameController,
          validator: (String? value) => _required(value, 'food item name'),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: _inputDecoration(
            label: 'Food item name',
            hint: 'Example: Zinger Burger',
            icon: Icons.fastfood_outlined,
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue:
              categories.any(
                (RestaurantMenuCategoryModel category) =>
                    category.id == _selectedCategoryId,
              )
              ? _selectedCategoryId
              : null,
          validator: (String? value) => value == null || value.trim().isEmpty
              ? 'Please select category'
              : null,
          dropdownColor: const Color(0xFF252525),
          decoration: _inputDecoration(
            label: 'Food category',
            hint: 'Select category',
            icon: Icons.category_outlined,
          ),
          items: categories
              .map(
                (RestaurantMenuCategoryModel category) =>
                    DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.name),
                    ),
              )
              .toList(),
          onChanged: (String? value) {
            setState(() {
              _selectedCategoryId = value ?? '';
            });
          },
        ),
        if (categories.isEmpty) ...<Widget>[
          const SizedBox(height: 8),
          const Text(
            'Create at least one category before adding a food item.',
            style: TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
        const SizedBox(height: 14),
        TextFormField(
          controller: _shortDescriptionController,
          decoration: _inputDecoration(
            label: 'Short description',
            hint: 'A short line shown on food cards',
            icon: Icons.short_text,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _descriptionController,
          minLines: 3,
          maxLines: 5,
          validator: (String? value) => _required(value, 'food description'),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: _inputDecoration(
            label: 'Full description',
            hint: 'Describe ingredients, taste and serving',
            icon: Icons.description_outlined,
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<RestaurantFoodType>(
          initialValue: _foodType,
          dropdownColor: const Color(0xFF252525),
          decoration: _inputDecoration(
            label: 'Food type',
            hint: 'Select food type',
            icon: Icons.eco_outlined,
          ),
          items: RestaurantFoodType.values
              .map(
                (RestaurantFoodType type) =>
                    DropdownMenuItem<RestaurantFoodType>(
                      value: type,
                      child: Text(type.value.replaceAll('_', ' ')),
                    ),
              )
              .toList(),
          onChanged: (RestaurantFoodType? value) {
            if (value == null) {
              return;
            }

            setState(() {
              _foodType = value;
            });
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _spiceLevel,
          dropdownColor: const Color(0xFF252525),
          decoration: _inputDecoration(
            label: 'Spice level',
            hint: 'Select spice level',
            icon: Icons.local_fire_department_outlined,
          ),
          items: const <String>['none', 'mild', 'medium', 'hot', 'extra_hot']
              .map(
                (String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.replaceAll('_', ' ')),
                ),
              )
              .toList(),
          onChanged: (String? value) {
            setState(() {
              _spiceLevel = value ?? 'none';
            });
          },
        ),
      ],
    );
  }

  Widget _buildPricingCard() {
    return _sectionCard(
      title: 'Pricing',
      icon: Icons.payments_outlined,
      children: <Widget>[
        TextFormField(
          controller: _originalPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (String? value) =>
              _positiveNumber(value, 'original price', allowZero: false),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: _inputDecoration(
            label: 'Original price (Rs.)',
            hint: '0',
            icon: Icons.sell_outlined,
          ),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _hasDiscount,
          onChanged: (bool value) {
            setState(() {
              _hasDiscount = value;
            });
          },
          activeThumbColor: yellow,
          title: const Text(
            'Add discount',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Show a reduced price to customers',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),
        if (_hasDiscount) ...<Widget>[
          const SizedBox(height: 10),
          TextFormField(
            controller: _discountedPriceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (String? value) =>
                _positiveNumber(value, 'discounted price', allowZero: false),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _inputDecoration(
              label: 'Discounted price (Rs.)',
              hint: '0',
              icon: Icons.discount_outlined,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFoodDetailsCard() {
    return _sectionCard(
      title: 'Food Details',
      icon: Icons.list_alt_outlined,
      children: <Widget>[
        TextFormField(
          controller: _preparationTimeController,
          keyboardType: TextInputType.number,
          validator: (String? value) =>
              _positiveNumber(value, 'preparation time'),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: _inputDecoration(
            label: 'Preparation time (minutes)',
            hint: '20',
            icon: Icons.schedule,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _servingSizeController,
          decoration: _inputDecoration(
            label: 'Serving size',
            hint: 'Example: Serves 1',
            icon: Icons.people_outline,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _weightController,
          decoration: _inputDecoration(
            label: 'Weight / quantity',
            hint: 'Example: 500g',
            icon: Icons.scale_outlined,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _ingredientsController,
          minLines: 2,
          maxLines: 3,
          decoration: _inputDecoration(
            label: 'Ingredients',
            hint: 'Chicken, cheese, bread, sauce',
            icon: Icons.restaurant_outlined,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _allergensController,
          minLines: 2,
          maxLines: 3,
          decoration: _inputDecoration(
            label: 'Allergens',
            hint: 'Milk, egg, gluten',
            icon: Icons.warning_amber_outlined,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _tagsController,
          decoration: _inputDecoration(
            label: 'Search tags',
            hint: 'Burger, spicy, chicken',
            icon: Icons.tag,
          ),
        ),
      ],
    );
  }

  Widget _buildImagesCard() {
    return _sectionCard(
      title: 'Food Images',
      icon: Icons.photo_library_outlined,
      children: <Widget>[
        _imagePathTile(
          title: 'Main food image',
          path: _mainLocalImagePath,
          onTap: () async {
            final String? result = await _requestLocalPath(
              title: 'Main Food Image',
              hint: r'C:\images\zinger.jpg',
            );

            if (result == null || !mounted) {
              return;
            }

            setState(() {
              _mainLocalImagePath = result;
            });
          },
          onClear: () {
            setState(() {
              _mainLocalImagePath = '';
            });
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Additional images',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final String? result = await _requestLocalPath(
                  title: 'Additional Food Image',
                  hint: r'C:\images\food_2.jpg',
                );

                if (result == null || !mounted) {
                  return;
                }

                setState(() {
                  _localImagePaths.add(result);
                });
              },
              icon: const Icon(
                Icons.add_photo_alternate_outlined,
                color: yellow,
              ),
              label: const Text(
                'Add',
                style: TextStyle(color: yellow, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_localImagePaths.isEmpty)
          const Text(
            'No additional images selected.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          )
        else
          ...List<Widget>.generate(_localImagePaths.length, (int index) {
            final String path = _localImagePaths[index];

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.image_outlined, color: yellow),
              title: Text(
                _fileName(path),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                onPressed: () {
                  setState(() {
                    _localImagePaths.removeAt(index);
                  });
                },
                icon: const Icon(Icons.close, color: Colors.redAccent),
              ),
            );
          }),
        const SizedBox(height: 10),
        const Text(
          'Firebase Storage upload is temporarily bypassed. Local image paths are saved for now.',
          style: TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildStockCard() {
    return _sectionCard(
      title: 'Stock Management',
      icon: Icons.inventory_2_outlined,
      children: <Widget>[
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _trackStock,
          onChanged: (bool value) {
            setState(() {
              _trackStock = value;
            });
          },
          activeThumbColor: yellow,
          title: const Text(
            'Track daily stock',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Automatically mark the item unavailable when stock reaches zero',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),
        if (_trackStock) ...<Widget>[
          const SizedBox(height: 12),
          TextFormField(
            controller: _dailyStockController,
            keyboardType: TextInputType.number,
            validator: (String? value) => _positiveNumber(value, 'daily stock'),
            decoration: _inputDecoration(
              label: 'Daily stock quantity',
              hint: '0',
              icon: Icons.inventory_outlined,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _remainingStockController,
            keyboardType: TextInputType.number,
            validator: (String? value) =>
                _positiveNumber(value, 'remaining stock'),
            decoration: _inputDecoration(
              label: 'Remaining stock quantity',
              hint: '0',
              icon: Icons.numbers,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVisibilityCard() {
    return _sectionCard(
      title: 'Visibility & Promotion',
      icon: Icons.tune,
      children: <Widget>[
        _switchTile(
          title: 'Available',
          subtitle: 'Customers can order this item',
          value: _isAvailable,
          onChanged: (bool value) {
            setState(() {
              _isAvailable = value;
            });
          },
        ),
        _switchTile(
          title: 'Visible',
          subtitle: 'Show this item in the digital menu',
          value: _isVisible,
          onChanged: (bool value) {
            setState(() {
              _isVisible = value;
            });
          },
        ),
        _switchTile(
          title: 'Featured',
          subtitle: 'Give this item higher priority',
          value: _isFeatured,
          onChanged: (bool value) {
            setState(() {
              _isFeatured = value;
            });
          },
        ),
        _switchTile(
          title: 'Popular',
          subtitle: 'Mark this item as popular',
          value: _isPopular,
          onChanged: (bool value) {
            setState(() {
              _isPopular = value;
            });
          },
        ),
        _switchTile(
          title: 'Recommended',
          subtitle: 'Recommend this item to customers',
          value: _isRecommended,
          onChanged: (bool value) {
            setState(() {
              _isRecommended = value;
            });
          },
        ),
        _switchTile(
          title: 'Promo Eligible',
          subtitle: 'Allow promo codes on this item',
          value: _promoEligible,
          onChanged: (bool value) {
            setState(() {
              _promoEligible = value;
            });
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _sortOrderController,
          keyboardType: TextInputType.number,
          validator: (String? value) => _positiveNumber(value, 'sort order'),
          decoration: _inputDecoration(
            label: 'Sort order',
            hint: '0',
            icon: Icons.sort,
          ),
        ),
      ],
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      activeThumbColor: yellow,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      ),
    );
  }

  Widget _imagePathTile({
    required String title,
    required String path,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final bool hasImage = path.trim().isNotEmpty;

    return Material(
      color: const Color(0xFF252525),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: yellow.withValues(alpha: 0.12),
                child: Icon(
                  hasImage ? Icons.check : Icons.add_photo_alternate_outlined,
                  color: hasImage ? Colors.greenAccent : yellow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasImage ? _fileName(path) : 'No image selected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasImage ? Colors.greenAccent : Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasImage)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                )
              else
                const Icon(Icons.chevron_right, color: yellow),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: yellow),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: yellow),
      filled: true,
      fillColor: const Color(0xFF252525),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: yellow),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  String _fileName(String path) {
    final String normalized = path.replaceAll('\\', '/');

    return normalized.split('/').last;
  }
}
