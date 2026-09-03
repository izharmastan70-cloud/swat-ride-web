// lib/food/restaurant_partner/widgets/partner_restaurant_information_form.dart

import 'package:flutter/material.dart';

class PartnerRestaurantInformationForm extends StatefulWidget {
  const PartnerRestaurantInformationForm({
    required this.restaurantNameController,
    required this.restaurantTypeController,
    required this.descriptionController,
    required this.selectedCategories,
    required this.onCategoriesChanged,
    super.key,
  });

  final TextEditingController restaurantNameController;
  final TextEditingController restaurantTypeController;
  final TextEditingController descriptionController;
  final Set<String> selectedCategories;
  final ValueChanged<Set<String>> onCategoriesChanged;

  @override
  State<PartnerRestaurantInformationForm> createState() =>
      _PartnerRestaurantInformationFormState();
}

class _PartnerRestaurantInformationFormState
    extends State<PartnerRestaurantInformationForm> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  static const List<String> availableCategories = <String>[
    'Fast Food',
    'Burgers',
    'Pizza',
    'BBQ',
    'Biryani',
    'Pakistani',
    'Chinese',
    'Traditional',
    'Bakery',
    'Desserts',
    'Drinks',
    'Cafe',
    'Seafood',
    'Breakfast',
    'Healthy Food',
  ];

  final TextEditingController _customCategoryController =
      TextEditingController();

  @override
  void dispose() {
    _customCategoryController.dispose();
    super.dispose();
  }

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $field';
    }
    return null;
  }

  void _toggleCategory(String category) {
    final Set<String> updated =
        Set<String>.from(widget.selectedCategories);

    if (updated.contains(category)) {
      updated.remove(category);
    } else {
      updated.add(category);
    }

    widget.onCategoriesChanged(updated);
  }

  void _addCustomCategory() {
    final String category = _customCategoryController.text.trim();
    if (category.isEmpty) return;

    final Set<String> updated =
        Set<String>.from(widget.selectedCategories);

    final bool exists = updated.any(
      (String item) => item.toLowerCase() == category.toLowerCase(),
    );

    if (!exists) {
      updated.add(category);
      widget.onCategoriesChanged(updated);
    }

    _customCategoryController.clear();
    FocusScope.of(context).unfocus();
  }

  bool _isDefaultCategory(String category) {
    return availableCategories.any(
      (String item) => item.toLowerCase() == category.toLowerCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> customCategories = widget.selectedCategories
        .where((String category) => !_isDefaultCategory(category))
        .toList()
      ..sort();

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
          const Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: Color(0x22FFD60A),
                child: Icon(Icons.restaurant_outlined, color: yellow),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Restaurant Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tell customers about your restaurant',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _field(
            controller: widget.restaurantNameController,
            label: 'Restaurant name',
            icon: Icons.storefront_outlined,
            validator: (String? value) =>
                _required(value, 'restaurant name'),
          ),
          const SizedBox(height: 14),
          _field(
            controller: widget.restaurantTypeController,
            label: 'Restaurant type',
            hint: 'Example: Family restaurant, Cafe, Fast food',
            icon: Icons.category_outlined,
            validator: (String? value) =>
                _required(value, 'restaurant type'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: widget.descriptionController,
            minLines: 3,
            maxLines: 5,
            validator: (String? value) =>
                _required(value, 'restaurant description'),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              labelText: 'Restaurant description',
              hintText: 'Describe your food, special dishes and service',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 70),
                child: Icon(Icons.description_outlined, color: yellow),
              ),
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
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Food categories',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            'Select broad restaurant categories. Chicken Karahi, Pizza Deal and Burger are menu items, which you add later in Menu Management.',
            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableCategories.map((String category) {
              final bool selected =
                  widget.selectedCategories.contains(category);
              return FilterChip(
                label: Text(category),
                selected: selected,
                onSelected: (_) => _toggleCategory(category),
                selectedColor: yellow,
                backgroundColor: const Color(0xFF252525),
                checkmarkColor: Colors.black,
                labelStyle: TextStyle(
                  color: selected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add your own category',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _customCategoryController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addCustomCategory(),
                  decoration: InputDecoration(
                    hintText: 'Example: Chapli Kabab, Afghan Food',
                    prefixIcon: const Icon(
                      Icons.add_business_outlined,
                      color: yellow,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF252525),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _addCustomCategory,
                style: IconButton.styleFrom(
                  backgroundColor: yellow,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (customCategories.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: customCategories.map((String category) {
                return InputChip(
                  label: Text(category),
                  selected: true,
                  selectedColor: yellow,
                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  deleteIconColor: Colors.black,
                  onDeleted: () {
                    final Set<String> updated =
                        Set<String>.from(widget.selectedCategories)
                          ..remove(category);
                    widget.onCategoriesChanged(updated);
                  },
                );
              }).toList(),
            ),
          ],
          if (widget.selectedCategories.isEmpty) ...<Widget>[
            const SizedBox(height: 10),
            const Text(
              'Select or add at least one food category.',
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
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
      ),
    );
  }
}
