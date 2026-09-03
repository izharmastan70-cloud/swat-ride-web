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

  final TextEditingController _itemController = TextEditingController();

  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _itemController.dispose();
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

              const Text(
                'Pickup & Delivery',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              _field(
                controller: _pickupController,
                label: 'Pickup Address',
                icon: Icons.my_location,
                maxLines: 2,
              ),

              const SizedBox(height: 14),

              _field(
                controller: _dropController,
                label: 'Drop Address',
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),

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

              const Text(
                'What are you sending?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              _field(
                controller: _itemController,
                label: 'Item / Cargo Details',
                icon: Icons.inventory_2_outlined,
                maxLines: 3,
              ),

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
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cargo details saved. Fare and payment are next.'),
      ),
    );
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
