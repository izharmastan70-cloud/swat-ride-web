// lib/food/restaurant_partner/widgets/partner_address_form.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Restaurant Partner Address Form
//
// Paid map rendering is temporarily bypassed.
// Latitude and longitude fields remain available for later
// connection with a real map picker.
// =============================================================

import 'package:flutter/material.dart';

class PartnerAddressForm extends StatelessWidget {
  const PartnerAddressForm({
    required this.countryController,
    required this.provinceController,
    required this.cityController,
    required this.areaController,
    required this.addressController,
    required this.landmarkController,
    required this.latitudeController,
    required this.longitudeController,
    super.key,
  });

  static const Color yellow = Color(0xFFFFD60A);
  static const Color cardColor = Color(0xFF1A1A1A);

  final TextEditingController countryController;
  final TextEditingController provinceController;
  final TextEditingController cityController;
  final TextEditingController areaController;
  final TextEditingController addressController;
  final TextEditingController landmarkController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;

  String? _required(
    String? value,
    String field,
  ) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $field';
    }

    return null;
  }

  String? _coordinateValidator(
    String? value,
    String field,
  ) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    if (double.tryParse(text) == null) {
      return 'Enter a valid $field';
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
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor:
                    Color(0x22FFD60A),
                child: Icon(
                  Icons.location_on_outlined,
                  color: yellow,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Restaurant Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Enter the complete delivery location',
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
            controller: countryController,
            label: 'Country',
            icon: Icons.public,
            validator: (String? value) =>
                _required(value, 'country'),
          ),
          const SizedBox(height: 14),
          _field(
            controller: provinceController,
            label: 'Province',
            icon: Icons.map_outlined,
            validator: (String? value) =>
                _required(value, 'province'),
          ),
          const SizedBox(height: 14),
          _field(
            controller: cityController,
            label: 'City',
            icon: Icons.location_city_outlined,
            validator: (String? value) =>
                _required(value, 'city'),
          ),
          const SizedBox(height: 14),
          _field(
            controller: areaController,
            label: 'Area',
            hint: 'Example: Mingora',
            icon: Icons.place_outlined,
            validator: (String? value) =>
                _required(value, 'area'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: addressController,
            minLines: 2,
            maxLines: 4,
            validator: (String? value) =>
                _required(
              value,
              'complete address',
            ),
            autovalidateMode:
                AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              labelText: 'Complete address',
              hintText:
                  'Street, building, shop number',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding:
                    EdgeInsets.only(bottom: 42),
                child: Icon(
                  Icons.home_work_outlined,
                  color: yellow,
                ),
              ),
              filled: true,
              fillColor:
                  const Color(0xFF252525),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
                borderSide:
                    const BorderSide(
                  color: yellow,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _field(
            controller: landmarkController,
            label: 'Nearby landmark',
            hint: 'Optional',
            icon: Icons.flag_outlined,
            validator: (_) => null,
          ),
          const SizedBox(height: 18),
          const Text(
            'Location coordinates',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'These fields are ready for real map integration.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _field(
                  controller:
                      latitudeController,
                  label: 'Latitude',
                  icon:
                      Icons.my_location_outlined,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (String? value) =>
                      _coordinateValidator(
                    value,
                    'latitude',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  controller:
                      longitudeController,
                  label: 'Longitude',
                  icon:
                      Icons.explore_outlined,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (String? value) =>
                      _coordinateValidator(
                    value,
                    'longitude',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: const Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.map_outlined,
                  color: yellow,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Paid map display is temporarily bypassed because billing is disabled. '
                    'The address and coordinate fields remain part of the real restaurant data.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
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
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
          borderRadius:
              BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
          borderSide:
              const BorderSide(
            color: yellow,
          ),
        ),
      ),
    );
  }
}
