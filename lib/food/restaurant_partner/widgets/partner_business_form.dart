// lib/food/restaurant_partner/widgets/partner_business_form.dart

import 'package:flutter/material.dart';

class PartnerBusinessForm extends StatelessWidget {
  const PartnerBusinessForm({
    required this.openingTimeController,
    required this.closingTimeController,
    required this.deliveryRadiusController,
    required this.minimumOrderController,
    required this.deliveryFeeController,
    super.key,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color card = Color(0xFF1A1A1A);

  final TextEditingController openingTimeController;
  final TextEditingController closingTimeController;
  final TextEditingController deliveryRadiusController;
  final TextEditingController minimumOrderController;
  final TextEditingController deliveryFeeController;

  String? _required(
    String? value,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }

    return null;
  }

  String? _positiveNumberValidator(
    String? value,
    String fieldName,
  ) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Please enter $fieldName';
    }

    final double? number = double.tryParse(text);

    if (number == null || number < 0) {
      return 'Enter a valid $fieldName';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Business Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),

          _field(
            controller: openingTimeController,
            label: 'Opening Time',
            hint: '09:00',
            icon: Icons.schedule,
            validator: (String? value) =>
                _required(value, 'opening time'),
          ),

          const SizedBox(height: 14),

          _field(
            controller: closingTimeController,
            label: 'Closing Time',
            hint: '23:00',
            icon: Icons.schedule_outlined,
            validator: (String? value) =>
                _required(value, 'closing time'),
          ),

          const SizedBox(height: 14),

          _field(
            controller: deliveryRadiusController,
            label: 'Delivery Radius (KM)',
            hint: '10',
            icon: Icons.route,
            validator: (String? value) =>
                _positiveNumberValidator(
              value,
              'delivery radius',
            ),
            keyboard: const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),

          const SizedBox(height: 14),

          _field(
            controller: minimumOrderController,
            label: 'Minimum Order (Rs)',
            hint: '0',
            icon: Icons.shopping_cart_outlined,
            validator: (String? value) =>
                _positiveNumberValidator(
              value,
              'minimum order',
            ),
            keyboard: const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),

          const SizedBox(height: 14),

          _field(
            controller: deliveryFeeController,
            label: 'Delivery Fee (Rs)',
            hint: '0',
            icon: Icons.delivery_dining,
            validator: (String? value) =>
                _positiveNumberValidator(
              value,
              'delivery fee',
            ),
            keyboard: const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'These values will be saved in Firestore and can later be changed by the restaurant partner.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      autovalidateMode:
          AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: yellow,
        ),
        filled: true,
        fillColor: const Color(0xFF252525),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: yellow,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}