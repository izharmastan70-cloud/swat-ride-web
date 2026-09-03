// lib/food/screens/checkout_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Customer Checkout Screen
//
// Connected with:
// - FoodCartService
// - FoodOrderService
// - DeliveryAddressModel
// - FoodOrderModel
//
// Real Firestore order creation is enabled.
// Paid online payment gateways are temporarily bypassed.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/delivery_address_model.dart';
import '../models/food_order_model.dart';
import '../services/food_cart_service.dart';
import '../services/food_order_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);

  final FoodCartService _cartService = FoodCartService.instance;

  final FoodOrderService _orderService = FoodOrderService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _receiverNameController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _houseController = TextEditingController();

  final TextEditingController _streetController = TextEditingController();

  final TextEditingController _areaController = TextEditingController();

  final TextEditingController _cityController = TextEditingController(
    text: 'Swat',
  );

  final TextEditingController _landmarkController = TextEditingController();

  final TextEditingController _instructionsController = TextEditingController();

  AddressType _addressType = AddressType.home;

  FoodPaymentMethod _paymentMethod = FoodPaymentMethod.cash;

  bool _isSubmitting = false;
  bool _isLoadingRestaurantConfig = true;

  double _restaurantDeliveryFee = 100;
  double _minimumOrderAmount = 0;

  bool _acceptsCash = true;
  bool _acceptsWallet = true;
  bool _acceptsJazzCash = true;
  bool _acceptsEasypaisa = true;

  bool _restaurantExists = true;
  bool _restaurantApproved = true;
  bool _restaurantActive = true;
  bool _restaurantOpen = true;

  // Paid map SDK is bypassed for now.
  // These coordinates can later come from the real map picker.
  final double _latitude = 0;
  final double _longitude = 0;

  double get _deliveryFee => _restaurantDeliveryFee;

  double get _serviceFee => 0;

  double get _discount => 0;

  double get _grandTotal =>
      _cartService.subtotal + _deliveryFee + _serviceFee - _discount;

  @override
  void initState() {
    super.initState();
    _loadRestaurantCheckoutConfig();
  }

  Future<void> _loadRestaurantCheckoutConfig() async {
    final String restaurantId = _cartService.restaurantId.trim();

    if (restaurantId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingRestaurantConfig = false;
        });
      }
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('food_restaurants')
          .doc(restaurantId)
          .get();

      final Map<String, dynamic> data =
          snapshot.data() ?? const <String, dynamic>{};

      if (!mounted) {
        return;
      }

      setState(() {
        _restaurantDeliveryFee = _doubleValue(
          data['deliveryFee'],
          fallback: 100,
        );
        _minimumOrderAmount = _doubleValue(data['minimumOrderAmount']);

        _acceptsCash = data['acceptsCash'] != false;
        _acceptsWallet = data['acceptsWallet'] != false;
        _acceptsJazzCash = data['acceptsJazzCash'] != false;
        _acceptsEasypaisa = data['acceptsEasypaisa'] != false;

        _restaurantExists = snapshot.exists;
        _restaurantApproved = data['isApproved'] != false;
        _restaurantActive = data['isActive'] != false;
        _restaurantOpen = data['isOpen'] != false;

        _isLoadingRestaurantConfig = false;
      });

      if (!_isPaymentMethodEnabled(_paymentMethod)) {
        setState(() {
          _paymentMethod = _firstEnabledPaymentMethod();
        });
      }
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingRestaurantConfig = false;
      });

      _showMessage(
        error.message ?? 'Unable to load restaurant checkout settings.',
      );
    }
  }

  static double _doubleValue(dynamic value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  bool _isPaymentMethodEnabled(FoodPaymentMethod method) {
    switch (method) {
      case FoodPaymentMethod.cash:
        return _acceptsCash;
      case FoodPaymentMethod.wallet:
        return _acceptsWallet;
      case FoodPaymentMethod.jazzCash:
        return _acceptsJazzCash;
      case FoodPaymentMethod.easypaisa:
        return _acceptsEasypaisa;
      case FoodPaymentMethod.card:
        return false;
    }
  }

  bool get _hasAnyEnabledPaymentMethod =>
      _acceptsCash || _acceptsWallet || _acceptsJazzCash || _acceptsEasypaisa;

  FoodPaymentMethod _firstEnabledPaymentMethod() {
    if (_acceptsCash) {
      return FoodPaymentMethod.cash;
    }

    if (_acceptsWallet) {
      return FoodPaymentMethod.wallet;
    }

    if (_acceptsJazzCash) {
      return FoodPaymentMethod.jazzCash;
    }

    if (_acceptsEasypaisa) {
      return FoodPaymentMethod.easypaisa;
    }

    return FoodPaymentMethod.cash;
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _landmarkController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  String? _phoneValidator(String? value) {
    final String? requiredError = _requiredValidator(value, 'phone number');

    if (requiredError != null) {
      return requiredError;
    }

    final String digits = value!.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 10 || digits.length > 13) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  String? _requiredValidator(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $field';
    }

    return null;
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _placeOrder() async {
    final FoodCartValidation validation = _cartService.validateForCheckout();

    if (!validation.isValid) {
      _showMessage(validation.message);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showMessage('Please log in before placing a food order.');
        return;
      }

      final String customerId = user.uid;

      if (!_restaurantExists) {
        _showMessage('This restaurant is no longer available.');
        return;
      }

      if (!_restaurantApproved || !_restaurantActive) {
        _showMessage('This restaurant is not available for orders.');
        return;
      }

      if (!_restaurantOpen) {
        _showMessage('This restaurant is currently closed.');
        return;
      }

      if (!_hasAnyEnabledPaymentMethod) {
        _showMessage(
          'No payment method is currently enabled for this restaurant.',
        );
        return;
      }

      if (_cartService.subtotal < _minimumOrderAmount) {
        _showMessage(
          'Minimum order is Rs. '
          '${_minimumOrderAmount.toStringAsFixed(0)}.',
        );
        return;
      }

      if (!_isPaymentMethodEnabled(_paymentMethod)) {
        _showMessage(
          'Selected payment method is not available for this restaurant.',
        );
        return;
      }

      final DateTime now = DateTime.now();

      final DeliveryAddressModel address = DeliveryAddressModel(
        id: '',
        userId: customerId,
        addressType: _addressType,
        receiverName: _receiverNameController.text.trim(),
        receiverPhone: _phoneController.text.trim(),
        houseNo: _houseController.text.trim(),
        street: _streetController.text.trim(),
        area: _areaController.text.trim(),
        city: _cityController.text.trim(),
        landmark: _landmarkController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        isDefault: false,
        deliveryInstructions: _instructionsController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      final String orderId = await _orderService.createOrder(
        customerId: customerId,
        restaurantId: _cartService.restaurantId,
        restaurantName: _cartService.restaurantName,
        items: _cartService.items,
        deliveryAddress: address,
        paymentMethod: _paymentMethod,
        deliveryFee: _deliveryFee,
        discount: _discount,
        serviceFee: _serviceFee,
      );

      final DateTime cancellationDeadline = now.add(const Duration(minutes: 5));

      await _firestore
          .collection('food_orders')
          .doc(orderId)
          .set(<String, dynamic>{
            'cancellationAllowedUntil': cancellationDeadline.toIso8601String(),
            'customerCanCancel': true,
            'paymentGatewayBypassed': _paymentMethod != FoodPaymentMethod.cash,
            'paymentStatus': _paymentMethod == FoodPaymentMethod.cash
                ? 'cash_pending'
                : 'testing_bypass',
            'checkoutSource': 'customer_food_checkout',
            'updatedAt': now.toIso8601String(),
          }, SetOptions(merge: true));

      await _createOrderNotifications(
        orderId: orderId,
        customerId: customerId,
        restaurantId: _cartService.restaurantId,
        restaurantName: _cartService.restaurantName,
      );

      await _createInitialOrderEvent(orderId: orderId, customerId: customerId);

      _cartService.clearCart();

      if (!mounted) {
        return;
      }

      Navigator.pushReplacementNamed(
        context,
        '/food_order_tracking',
        arguments: orderId,
      );
    } on FoodOrderServiceException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Unable to place order: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _createOrderNotifications({
    required String orderId,
    required String customerId,
    required String restaurantId,
    required String restaurantName,
  }) async {
    final WriteBatch batch = _firestore.batch();

    final DocumentReference<Map<String, dynamic>> customerNotification =
        _firestore.collection('food_customer_notifications').doc();

    batch.set(customerNotification, <String, dynamic>{
      'customerId': customerId,
      'orderId': orderId,
      'title': 'Order Placed',
      'message':
          'Your order from $restaurantName has been placed successfully.',
      'type': 'order_placed',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    QuerySnapshot<Map<String, dynamic>> partnerSnapshot = await _firestore
        .collection('food_restaurant_partners')
        .where('restaurantId', isEqualTo: restaurantId)
        .limit(1)
        .get();

    if (partnerSnapshot.docs.isEmpty) {
      partnerSnapshot = await _firestore
          .collection('restaurant_partners')
          .where('restaurantId', isEqualTo: restaurantId)
          .limit(1)
          .get();
    }

    if (partnerSnapshot.docs.isNotEmpty) {
      final Map<String, dynamic> partnerData = partnerSnapshot.docs.first
          .data();

      final String partnerId =
          partnerData['partnerId']?.toString().trim().isNotEmpty == true
          ? partnerData['partnerId'].toString()
          : partnerSnapshot.docs.first.id;

      final DocumentReference<Map<String, dynamic>> partnerNotification =
          _firestore.collection('food_partner_notifications').doc();

      batch.set(partnerNotification, <String, dynamic>{
        'partnerId': partnerId,
        'restaurantId': restaurantId,
        'orderId': orderId,
        'title': 'New Food Order',
        'message': 'A new order has been received.',
        'type': 'order',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final DocumentReference<Map<String, dynamic>> adminNotification = _firestore
        .collection('food_admin_notifications')
        .doc();

    batch.set(adminNotification, <String, dynamic>{
      'orderId': orderId,
      'restaurantId': restaurantId,
      'customerId': customerId,
      'title': 'New Food Order',
      'message': 'A new order was placed at $restaurantName.',
      'type': 'new_order',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> _createInitialOrderEvent({
    required String orderId,
    required String customerId,
  }) async {
    final DocumentReference<Map<String, dynamic>> eventDocument = _firestore
        .collection('food_orders')
        .doc(orderId)
        .collection('status_events')
        .doc();

    await eventDocument.set(<String, dynamic>{
      'eventId': eventDocument.id,
      'orderId': orderId,
      'status': FoodOrderStatus.pending.name,
      'title': 'Order placed',
      'message': 'Customer placed the food order.',
      'actorId': customerId,
      'actorRole': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            children: <Widget>[
              _buildRestaurantSummary(),
              if (!_restaurantApproved ||
                  !_restaurantActive ||
                  !_restaurantOpen ||
                  !_hasAnyEnabledPaymentMethod) ...<Widget>[
                const SizedBox(height: 12),
                _buildRestaurantAvailabilityWarning(),
              ],
              const SizedBox(height: 18),
              _buildSectionTitle('Delivery address'),
              const SizedBox(height: 10),
              _buildAddressTypeSelector(),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _receiverNameController,
                label: 'Receiver name',
                icon: Icons.person_outline,
                validator: (String? value) =>
                    _requiredValidator(value, 'receiver name'),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _phoneValidator,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _houseController,
                label: 'House / shop number',
                icon: Icons.home_outlined,
                validator: (String? value) =>
                    _requiredValidator(value, 'house or shop number'),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _streetController,
                label: 'Street',
                icon: Icons.route_outlined,
                validator: (String? value) =>
                    _requiredValidator(value, 'street'),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _areaController,
                label: 'Area',
                icon: Icons.location_city_outlined,
                validator: (String? value) => _requiredValidator(value, 'area'),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _cityController,
                label: 'City',
                icon: Icons.apartment_outlined,
                validator: (String? value) => _requiredValidator(value, 'city'),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _landmarkController,
                label: 'Nearby landmark',
                icon: Icons.place_outlined,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _instructionsController,
                label: 'Delivery instructions',
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              _buildMapBypassCard(),
              const SizedBox(height: 22),
              _buildSectionTitle('Payment method'),
              const SizedBox(height: 10),
              _buildPaymentMethods(),
              const SizedBox(height: 22),
              _buildSectionTitle('Order summary'),
              const SizedBox(height: 10),
              _buildOrderSummary(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _isLoadingRestaurantConfig
                      ? null
                      : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'Place Order â€¢ Rs. ${_grandTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildRestaurantSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0x22FFD60A),
            child: Icon(Icons.restaurant, color: yellow),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Ordering from',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  _cartService.restaurantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_cartService.totalQuantity} item(s)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantAvailabilityWarning() {
    String message = 'This restaurant is currently unavailable.';

    if (!_restaurantApproved || !_restaurantActive) {
      message = 'This restaurant is not approved or active.';
    } else if (!_restaurantOpen) {
      message = 'This restaurant is currently closed.';
    } else if (!_hasAnyEnabledPaymentMethod) {
      message = 'No payment method is enabled for this restaurant.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orangeAccent),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline, color: Colors.orangeAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.orangeAccent, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAddressTypeSelector() {
    return SegmentedButton<AddressType>(
      segments: const <ButtonSegment<AddressType>>[
        ButtonSegment<AddressType>(
          value: AddressType.home,
          label: Text('Home'),
          icon: Icon(Icons.home_outlined),
        ),
        ButtonSegment<AddressType>(
          value: AddressType.office,
          label: Text('Office'),
          icon: Icon(Icons.business_outlined),
        ),
        ButtonSegment<AddressType>(
          value: AddressType.other,
          label: Text('Other'),
          icon: Icon(Icons.place_outlined),
        ),
      ],
      selected: <AddressType>{_addressType},
      onSelectionChanged: (Set<AddressType> selection) {
        setState(() {
          _addressType = selection.first;
        });
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return yellow;
          }

          return cardColor;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black;
          }

          return Colors.white;
        }),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: yellow),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildMapBypassCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.map_outlined, color: yellow),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Paid map display is temporarily bypassed. '
              'The address and coordinate fields remain ready '
              'for real map connection after billing is enabled.',
              style: TextStyle(color: Colors.grey, height: 1.4, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return RadioGroup<FoodPaymentMethod>(
      groupValue: _paymentMethod,
      onChanged: (FoodPaymentMethod? value) {
        if (value == null) {
          return;
        }

        setState(() {
          _paymentMethod = value;
        });
      },
      child: Column(
        children: <Widget>[
          _buildPaymentTile(
            method: FoodPaymentMethod.cash,
            title: 'Cash on Delivery',
            subtitle: _acceptsCash
                ? 'Pay the rider in cash'
                : 'Disabled by restaurant/admin',
            icon: Icons.payments_outlined,
            enabled: _acceptsCash,
          ),
          const SizedBox(height: 9),
          _buildPaymentTile(
            method: FoodPaymentMethod.wallet,
            title: 'SWAT RIDE Wallet',
            subtitle: _acceptsWallet
                ? 'Gateway billing temporarily bypassed'
                : 'Disabled by restaurant/admin',
            icon: Icons.account_balance_wallet_outlined,
            enabled: _acceptsWallet,
          ),
          const SizedBox(height: 9),
          _buildPaymentTile(
            method: FoodPaymentMethod.jazzCash,
            title: 'JazzCash',
            subtitle: _acceptsJazzCash
                ? 'Gateway billing temporarily bypassed'
                : 'Disabled by restaurant/admin',
            icon: Icons.phone_android,
            enabled: _acceptsJazzCash,
          ),
          const SizedBox(height: 9),
          _buildPaymentTile(
            method: FoodPaymentMethod.easypaisa,
            title: 'Easypaisa',
            subtitle: _acceptsEasypaisa
                ? 'Gateway billing temporarily bypassed'
                : 'Disabled by restaurant/admin',
            icon: Icons.mobile_friendly,
            enabled: _acceptsEasypaisa,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile({
    required FoodPaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
  }) {
    return RadioListTile<FoodPaymentMethod>(
      value: method,
      enabled: enabled,
      activeColor: yellow,
      tileColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      secondary: Icon(icon, color: yellow),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: <Widget>[
          _summaryRow('Items subtotal', _cartService.subtotal),
          const SizedBox(height: 10),
          _summaryRow('Delivery fee', _deliveryFee),
          if (_minimumOrderAmount > 0) ...<Widget>[
            const SizedBox(height: 10),
            _summaryTextRow(
              'Minimum order',
              'Rs. ${_minimumOrderAmount.toStringAsFixed(0)}',
            ),
          ],
          const SizedBox(height: 10),
          _summaryRow('Service fee', _serviceFee),
          if (_discount > 0) ...<Widget>[
            const SizedBox(height: 10),
            _summaryRow('Discount', -_discount),
          ],
          const Divider(color: Colors.white12, height: 26),
          _summaryRow('Total', _grandTotal, isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryTextRow(String label, String value) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _summaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.grey,
              fontSize: isTotal ? 17 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          'Rs. ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: isTotal ? yellow : Colors.white,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
