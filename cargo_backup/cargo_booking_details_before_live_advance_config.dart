import 'package:flutter/material.dart';

import '../../models/vehicle_model.dart';

class CargoBookingDetailsScreen extends StatefulWidget {
  const CargoBookingDetailsScreen({
    super.key,
    required this.serviceType,
    required this.vehicle,
  });

  final String serviceType;
  final VehicleModel vehicle;

  @override
  State<CargoBookingDetailsScreen> createState() =>
      _CargoBookingDetailsScreenState();
}

class _CargoBookingDetailsScreenState extends State<CargoBookingDetailsScreen> {
  static const Color _yellow = Color(0xFFFFD60A);
  static const Color _background = Color(0xFF0D0D0D);
  static const Color _card = Color(0xFF1A1A1A);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _pickupController = TextEditingController();

  final TextEditingController _dropController = TextEditingController();

  final TextEditingController _receiverNameController = TextEditingController();

  final TextEditingController _receiverPhoneController =
      TextEditingController();

  final TextEditingController _shopController = TextEditingController();

  final TextEditingController _itemController = TextEditingController();

  final TextEditingController _expectedAmountController =
      TextEditingController();

  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _shopController.dispose();
    _itemController.dispose();
    _expectedAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: Text(_serviceTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _vehicleSummary(),

              const SizedBox(height: 24),

              Text(
                _locationHeading,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _field(
                controller: _pickupController,
                label: _pickupLabel,
                icon: _isBuyForMe ? Icons.store_outlined : Icons.my_location,
                maxLines: 2,
              ),

              const SizedBox(height: 14),

              _field(
                controller: _dropController,
                label: _dropLabel,
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),

              if (_needsShopDetails) ...[
                const SizedBox(height: 24),

                const Text(
                  'Shop / Pickup Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 14),

                _field(
                  controller: _shopController,
                  label: _shopFieldLabel,
                  icon: Icons.store_mall_directory_outlined,
                  maxLines: 2,
                ),
              ],

              const SizedBox(height: 24),

              const Text(
                'Receiver',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              _field(
                controller: _receiverNameController,
                label: 'Receiver Name',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 14),

              _field(
                controller: _receiverPhoneController,
                label: 'Receiver Phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              Text(
                _itemHeading,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              _field(
                controller: _itemController,
                label: _itemFieldLabel,
                icon: Icons.inventory_2_outlined,
                maxLines: 4,
              ),

              if (_isBuyForMe) ...[
                const SizedBox(height: 14),

                _field(
                  controller: _expectedAmountController,
                  label: 'Expected Item Amount (Rs.)',
                  icon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),

                const SizedBox(height: 14),

                _imageInfoCard(),

                const SizedBox(height: 14),

                _advanceInfoCard(),
              ],

              const SizedBox(height: 14),

              _field(
                controller: _noteController,
                label: 'Driver Instructions (Optional)',
                icon: Icons.notes_outlined,
                maxLines: 3,
                requiredField: false,
              ),

              const SizedBox(height: 20),

              _safetyNote(),

              const SizedBox(height: 24),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _continueBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _yellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _continueButtonLabel,
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

  Widget _vehicleSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                widget.vehicle.image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.grey,
                    size: 36,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.vehicle.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.vehicle.capacity,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: _yellow),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool requiredField = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (requiredField && (value == null || value.trim().isEmpty)) {
          return '$label is required';
        }

        if (controller == _expectedAmountController &&
            value != null &&
            value.trim().isNotEmpty) {
          final double? amount = double.tryParse(value.trim());

          if (amount == null || amount <= 0) {
            return 'Enter a valid expected amount';
          }
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _imageInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.add_photo_alternate_outlined, color: _yellow),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Optional item photo will be supported here. '
              'Image upload will be connected when the Cargo '
              'storage phase is enabled.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _advanceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _yellow.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _yellow.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.account_balance_wallet_outlined, color: _yellow),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Buy For Me requires advance payment before the '
              'driver purchases the items. The required advance '
              'percentage and available payment methods will come '
              'from Cargo Admin settings.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _safetyNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _yellow.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _yellow.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: _yellow),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Keep your booking inside SWAT RIDE. '
              'If a driver asks you to cancel the app booking '
              'and deal directly, you will be able to report it.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _continueBooking() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isBuyForMe) {
      final double expectedAmount =
          double.tryParse(_expectedAmountController.text.trim()) ?? 0;

      if (expectedAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the expected item amount.'),
          ),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isBuyForMe
              ? 'Buy For Me details saved. Advance and payment are next.'
              : _isPickupMyItem
              ? 'Pickup details saved. Fare and payment are next.'
              : 'Cargo details saved. Fare and payment are next.',
        ),
      ),
    );
  }

  bool get _isBuyForMe => widget.serviceType == 'buy_for_me';

  bool get _isPickupMyItem => widget.serviceType == 'pickup_my_item';

  bool get _needsShopDetails => _isBuyForMe || _isPickupMyItem;

  String get _locationHeading {
    if (_isBuyForMe) {
      return 'Shop & Delivery';
    }

    if (_isPickupMyItem) {
      return 'Pickup & Delivery';
    }

    return 'Pickup & Delivery';
  }

  String get _pickupLabel {
    if (_isBuyForMe) {
      return 'Shop / Market Pickup Address';
    }

    if (_isPickupMyItem) {
      return 'Item Pickup Address';
    }

    return 'Pickup Address';
  }

  String get _dropLabel {
    if (_isBuyForMe || _isPickupMyItem) {
      return 'Delivery Address';
    }

    return 'Drop Address';
  }

  String get _shopFieldLabel {
    if (_isBuyForMe) {
      return 'Shop / Market Name';
    }

    return 'Shop / Person Name';
  }

  String get _itemHeading {
    if (_isBuyForMe) {
      return 'What should the driver buy?';
    }

    if (_isPickupMyItem) {
      return 'What should the driver collect?';
    }

    return 'What are you sending?';
  }

  String get _itemFieldLabel {
    if (_isBuyForMe) {
      return 'Item List / Quantity / Brand';
    }

    if (_isPickupMyItem) {
      return 'Item Details / Pickup Instructions';
    }

    return 'Item / Cargo Details';
  }

  String get _continueButtonLabel {
    if (_isBuyForMe) {
      return 'Continue to Advance Payment';
    }

    return 'Continue to Fare & Payment';
  }

  String get _serviceTitle {
    switch (widget.serviceType) {
      case 'parcel':
        return 'Send Parcel';

      case 'goods':
        return 'Move Goods';

      case 'shifting':
        return 'House Shifting';

      case 'pickup_my_item':
        return 'Pickup My Item';

      case 'buy_for_me':
        return 'Buy For Me';

      default:
        return 'Cargo Booking';
    }
  }
}
