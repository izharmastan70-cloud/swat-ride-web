import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/cargo_driver_application_model.dart';
import '../services/cargo_driver_application_service.dart';

class CargoDriverRegistrationScreen extends StatefulWidget {
  const CargoDriverRegistrationScreen({super.key});

  @override
  State<CargoDriverRegistrationScreen> createState() =>
      _CargoDriverRegistrationScreenState();
}

class _CargoDriverRegistrationScreenState
    extends State<CargoDriverRegistrationScreen> {
  static const Color _yellow = Color(0xFFFFD60A);
  static const Color _background = Color(0xFF0D0D0D);
  static const Color _card = Color(0xFF1A1A1A);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _cnicController = TextEditingController();

  final TextEditingController _vehicleNumberController =
      TextEditingController();

  final TextEditingController _addressController = TextEditingController();

  final CargoDriverApplicationService _service =
      CargoDriverApplicationService();

  String _vehicleType = CargoDriverApplicationModel.bike;

  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _vehicleNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('Become a Cargo Driver'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Cargo Driver Registration',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Register your cargo vehicle and submit your '
                'application for approval.',
                style: TextStyle(color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 24),

              _field(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 14),

              _field(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 14),

              _field(
                controller: _cnicController,
                label: 'CNIC Number',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 14),

              _vehicleSelector(),

              const SizedBox(height: 14),

              _field(
                controller: _vehicleNumberController,
                label: 'Vehicle Registration Number',
                icon: Icons.confirmation_number_outlined,
              ),

              const SizedBox(height: 14),

              _field(
                controller: _addressController,
                label: 'Address',
                icon: Icons.location_on_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 22),

              _documentInfo(),

              const SizedBox(height: 24),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _yellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Submit Application',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
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

  Widget _vehicleSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _vehicleType,
      decoration: InputDecoration(
        labelText: 'Cargo Vehicle Type',
        prefixIcon: const Icon(Icons.local_shipping_outlined),
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: CargoDriverApplicationModel.supportedVehicleTypes
          .map(
            (type) => DropdownMenuItem<String>(
              value: type,
              child: Text(_vehicleLabel(type)),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _vehicleType = value;
        });
      },
    );
  }

  Widget _documentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _yellow.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _yellow.withValues(alpha: 0.30)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.description_outlined, color: _yellow),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'CNIC photos, driving license, vehicle registration, '
              'driver photo and vehicle photo will be required for '
              'final verification. Document upload will be connected '
              'with the storage phase.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _message('Please login before submitting a Cargo Driver application.');
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await _service.submitApplication(
        userId: user.uid,
        fullName: _nameController.text,
        phone: _phoneController.text,
        cnicNumber: _cnicController.text,
        vehicleType: _vehicleType,
        vehicleNumber: _vehicleNumberController.text,
        address: _addressController.text,
      );

      if (!mounted) {
        return;
      }

      _message('Cargo Driver application submitted for admin approval.');

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _message('Could not submit application: $error');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _vehicleLabel(String type) {
    switch (type) {
      case CargoDriverApplicationModel.bike:
        return 'Bike';

      case CargoDriverApplicationModel.rickshaw:
        return 'Rickshaw';

      case CargoDriverApplicationModel.loaderRickshaw:
        return 'Loader Rickshaw';

      case CargoDriverApplicationModel.qingqiLoader:
        return 'Qingqi Loader';

      case CargoDriverApplicationModel.suzukiPickup:
        return 'Suzuki Pickup / Ravi';

      case CargoDriverApplicationModel.shehzore:
        return 'Shehzore';

      case CargoDriverApplicationModel.miniTruck:
        return 'Mini Truck';

      case CargoDriverApplicationModel.mediumTruck:
        return 'Medium Truck';

      case CargoDriverApplicationModel.largeTruck:
        return 'Large Truck';

      case CargoDriverApplicationModel.dumper:
        return 'Dumper';

      case CargoDriverApplicationModel.tractorTrolley:
        return 'Tractor Trolley';

      default:
        return type;
    }
  }
}
