// lib/food/restaurant_partner/widgets/partner_owner_information_form.dart

import 'package:flutter/material.dart';

class PartnerOwnerInformationForm extends StatelessWidget {
  const PartnerOwnerInformationForm({
    required this.ownerNameController,
    required this.phoneController,
    required this.emailController,
    required this.cnicController,
    super.key,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final TextEditingController ownerNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController cnicController;

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $field';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final digits =
        (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 13) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return null;

    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateCnic(String? value) {
    final digits =
        (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 13) {
      return 'CNIC must contain 13 digits';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
                child: Icon(Icons.person_outline, color: yellow),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Owner Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Enter the restaurant owner details',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _field(
            controller: ownerNameController,
            label: 'Owner full name',
            icon: Icons.person,
            validator: (value) => _required(value, 'owner name'),
          ),
          const SizedBox(height: 14),
          _field(
            controller: phoneController,
            label: 'Phone number',
            hint: '03XX XXXXXXX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: _validatePhone,
          ),
          const SizedBox(height: 14),
          _field(
            controller: emailController,
            label: 'Email address',
            hint: 'Optional',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 14),
          _field(
            controller: cnicController,
            label: 'CNIC number',
            hint: 'XXXXX-XXXXXXX-X',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            validator: _validateCnic,
          ),
          const SizedBox(height: 12),
          const Text(
            'CNIC images will be added in the documents section. '
            'Firebase Storage upload is temporarily bypassed.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
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
    required IconData icon,
    required String? Function(String?) validator,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
