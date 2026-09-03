// lib/food/screens/cart_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Customer Food Cart Screen
//
// Connected with:
// - CartItemModel
// - FoodCartService
// - CheckoutScreen route
//
// Features:
// - Live cart updates
// - One restaurant per cart
// - Increase/decrease quantity
// - Remove item
// - Special instructions
// - Clear cart
// - Checkout validation
//
// Existing non-Food modules remain untouched.
// =============================================================

import 'package:flutter/material.dart';

import '../models/cart_item_model.dart';
import '../services/food_cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() =>
      _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodCartService _cartService =
      FoodCartService.instance;

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

  void _handleResult(
    FoodCartResult result,
  ) {
    if (!result.isSuccess) {
      _showMessage(result.message);
    }
  }

  Future<void> _clearCart() async {
    if (_cartService.isEmpty) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Clear cart?'),
          content: const Text(
            'All food items will be removed from your cart.',
            style: TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Cart'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    _cartService.clearCart();
    _showMessage('Cart cleared.');
  }

  Future<void> _editInstructions(
    CartItemModel item,
  ) async {
    final TextEditingController controller =
        TextEditingController(
      text: item.specialInstructions,
    );

    final String? instructions =
        await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Special Instructions',
          ),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText:
                  'Example: No mayonnaise, less spicy',
              filled: true,
              fillColor: const Color(0xFF252525),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (instructions == null) {
      return;
    }

    final FoodCartResult result =
        _cartService.updateSpecialInstructions(
      cartItemId: item.cartItemId,
      instructions: instructions,
    );

    _handleResult(result);
  }

  void _proceedToCheckout() {
    final FoodCartValidation validation =
        _cartService.validateForCheckout();

    if (!validation.isValid) {
      _showMessage(validation.message);
      return;
    }

    Navigator.pushNamed(
      context,
      '/food_checkout',
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
          'My Food Cart',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          StreamBuilder<List<CartItemModel>>(
            stream: _cartService.cartStream,
            initialData: _cartService.items,
            builder: (
              BuildContext context,
              AsyncSnapshot<List<CartItemModel>>
                  snapshot,
            ) {
              final bool hasItems =
                  _cartService.isNotEmpty;

              return IconButton(
                tooltip: 'Clear cart',
                onPressed:
                    hasItems ? _clearCart : null,
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<CartItemModel>>(
          stream: _cartService.cartStream,
          initialData: _cartService.items,
          builder: (
            BuildContext context,
            AsyncSnapshot<List<CartItemModel>>
                snapshot,
          ) {
            final List<CartItemModel> items =
                snapshot.data ??
                    _cartService.items;

            if (items.isEmpty) {
              return _buildEmptyCart();
            }

            return Column(
              children: <Widget>[
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      20,
                    ),
                    children: <Widget>[
                      _buildRestaurantCard(),
                      const SizedBox(height: 16),
                      ...items.map(
                        (CartItemModel item) =>
                            Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: _CartItemCard(
                            item: item,
                            onIncrease: () {
                              final FoodCartResult result =
                                  _cartService
                                      .increaseQuantity(
                                item.cartItemId,
                              );

                              _handleResult(result);
                            },
                            onDecrease: () {
                              final FoodCartResult result =
                                  _cartService
                                      .decreaseQuantity(
                                item.cartItemId,
                              );

                              _handleResult(result);
                            },
                            onRemove: () {
                              final FoodCartResult result =
                                  _cartService.removeItem(
                                item.cartItemId,
                              );

                              _handleResult(result);
                            },
                            onEditInstructions: () =>
                                _editInstructions(
                              item,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildBottomSummary(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRestaurantCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.black,
            child: Icon(
              Icons.restaurant,
              color: yellow,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Ordering from',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _cartService.restaurantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Only one restaurant is allowed per cart.',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        18,
        18,
      ),
      decoration: const BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black45,
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          _summaryRow(
            label:
                'Items (${_cartService.totalQuantity})',
            value:
                'Rs. ${_cartService.subtotal.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          const _SummaryNote(
            text:
                'Delivery fee and final total will be shown on checkout.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _proceedToCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
              child: Text(
                'Proceed to Checkout • Rs. ${_cartService.subtotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
  }) {
    return Row(
      children: <Widget>[
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.shopping_cart_outlined,
              color: yellow,
              size: 82,
            ),
            const SizedBox(height: 18),
            const Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add food from a restaurant to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
              ),
              icon: const Icon(
                Icons.restaurant_menu,
              ),
              label: const Text(
                'Browse Food',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onEditInstructions,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final CartItemModel item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final VoidCallback onEditInstructions;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.isAvailable ? 1 : 0.58,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: item.isAvailable
                ? Colors.white10
                : Colors.redAccent,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF272727),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.fastfood,
                    color: yellow,
                    size: 32,
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
                              item.menuItemName,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: onRemove,
                            icon: const Icon(
                              Icons.delete_outline,
                              color:
                                  Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Rs. ${item.unitTotal.toStringAsFixed(0)} each',
                        style: const TextStyle(
                          color: yellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!item.isAvailable) ...<Widget>[
                        const SizedBox(height: 5),
                        const Text(
                          'Currently unavailable',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (item.specialInstructions
                .trim()
                .isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFF272727),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Text(
                  'Note: ${item.specialInstructions}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                TextButton.icon(
                  onPressed: onEditInstructions,
                  icon: const Icon(
                    Icons.edit_note,
                    color: yellow,
                  ),
                  label: const Text(
                    'Instructions',
                    style: TextStyle(
                      color: yellow,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onDecrease,
                  icon: const Icon(
                    Icons.remove_circle_outline,
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 34,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      item.isAvailable
                          ? onIncrease
                          : null,
                  icon: const Icon(
                    Icons.add_circle,
                    color: yellow,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: yellow,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryNote extends StatelessWidget {
  const _SummaryNote({
    required this.text,
  });

  static const Color yellow = Color(0xFFFFD60A);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(
          Icons.info_outline,
          color: yellow,
          size: 17,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
