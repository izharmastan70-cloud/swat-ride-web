// lib/food/restaurant_partner/screens/edit_food_item_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Edit Restaurant Food Item Screen
//
// This screen reuses AddFoodItemScreen in edit mode so the same
// validation, variants, add-ons, stock and Firestore update logic
// remains consistent.
// =============================================================

import 'package:flutter/material.dart';

import '../models/food_item_model.dart';
import '../models/restaurant_partner_model.dart';
import 'add_food_item_screen.dart';

class EditFoodItemScreen extends StatelessWidget {
  const EditFoodItemScreen({
    required this.partner,
    required this.item,
    super.key,
  });

  final RestaurantPartnerModel partner;
  final RestaurantFoodItemModel item;

  @override
  Widget build(BuildContext context) {
    return AddFoodItemScreen(
      partner: partner,
      item: item,
    );
  }
}
