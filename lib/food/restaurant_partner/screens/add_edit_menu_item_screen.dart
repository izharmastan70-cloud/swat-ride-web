// lib/food/restaurant_partner/screens/add_menu_item_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Compatibility screen for Add / Edit Menu Item
//
// The full production form already exists in:
// add_food_item_screen.dart
//
// This wrapper keeps routes/imports that use AddMenuItemScreen working
// without duplicating the full form code.
// =============================================================

import 'package:flutter/material.dart';

import '../models/food_item_model.dart';
import '../models/restaurant_partner_model.dart';
import 'add_food_item_screen.dart';

class AddMenuItemScreen extends StatelessWidget {
  const AddMenuItemScreen({
    required this.partner,
    this.item,
    super.key,
  });

  final RestaurantPartnerModel partner;
  final RestaurantFoodItemModel? item;

  @override
  Widget build(BuildContext context) {
    return AddFoodItemScreen(
      partner: partner,
      item: item,
    );
  }
}
