import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HotelProfileManagementScreen extends StatefulWidget {
  const HotelProfileManagementScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelProfileManagementScreen> createState() =>
      _HotelProfileManagementScreenState();
}

class _HotelProfileManagementScreenState
    extends State<HotelProfileManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _locationController =
      TextEditingController();

  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _receptionPhoneController =
      TextEditingController();

  final TextEditingController _managerPhoneController =
      TextEditingController();

  final TextEditingController _emergencyPhoneController =
      TextEditingController();

  final TextEditingController _whatsAppController =
      TextEditingController();

  final TextEditingController _checkInTimeController =
      TextEditingController();

  final TextEditingController _checkOutTimeController =
      TextEditingController();

  final TextEditingController _cancellationPolicyController =
      TextEditingController();

  final List<String> _selectedFacilities =
      <String>[];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isActive = true;
  bool _acceptsFamilies = true;
  bool _acceptsGroups = true;
  bool _hasParking = false;
  bool _hasRestaurant = false;
  bool _hasGenerator = false;
  bool _hasHeating = false;
  bool _hasHotWater = false;
  bool _hasWiFi = false;

  final List<String> _availableFacilities =
      const <String>[
    'WiFi',
    'Parking',
    'Restaurant',
    'Room Service',
    'Generator',
    'Heating',
    'Hot Water',
    'Laundry',
    'Family Rooms',
    'Mountain View',
    'Airport Pickup',
    'Tour Desk',
  ];

  @override
  void initState() {
    super.initState();
    _loadHotel();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _receptionPhoneController.dispose();
    _managerPhoneController.dispose();
    _emergencyPhoneController.dispose();
    _whatsAppController.dispose();
    _checkInTimeController.dispose();
    _checkOutTimeController.dispose();
    _cancellationPolicyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Hotel Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: yellow,
                ),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    28,
                  ),
                  children: [
                    _statusCard(),

                    const SizedBox(height: 20),

                    _sectionTitle(
                      'Basic Information',
                    ),

                    _field(
                      controller:
                          _nameController,
                      label: 'Hotel name',
                      icon: Icons.hotel,
                      validator:
                          _requiredValidator,
                    ),

                    _field(
                      controller:
                          _descriptionController,
                      label: 'Hotel description',
                      icon:
                          Icons.description_outlined,
                      maxLines: 4,
                      validator:
                          _requiredValidator,
                    ),

                    _field(
                      controller:
                          _locationController,
                      label: 'City / Area',
                      icon:
                          Icons.location_city_outlined,
                      validator:
                          _requiredValidator,
                    ),

                    _field(
                      controller:
                          _addressController,
                      label: 'Full address',
                      icon:
                          Icons.location_on_outlined,
                      maxLines: 2,
                      validator:
                          _requiredValidator,
                    ),

                    const SizedBox(height: 8),

                    _sectionTitle(
                      'Hotel Contact Numbers',
                    ),

                    _field(
                      controller:
                          _receptionPhoneController,
                      label:
                          'Reception / Helpline number',
                      icon: Icons.support_agent,
                      keyboardType:
                          TextInputType.phone,
                      validator:
                          _phoneValidator,
                    ),

                    _field(
                      controller:
                          _managerPhoneController,
                      label:
                          'Manager number',
                      icon:
                          Icons.manage_accounts_outlined,
                      keyboardType:
                          TextInputType.phone,
                      validator:
                          _optionalPhoneValidator,
                    ),

                    _field(
                      controller:
                          _emergencyPhoneController,
                      label:
                          'Emergency number',
                      icon:
                          Icons.emergency_outlined,
                      keyboardType:
                          TextInputType.phone,
                      validator:
                          _optionalPhoneValidator,
                    ),

                    _field(
                      controller:
                          _whatsAppController,
                      label:
                          'WhatsApp number (optional)',
                      icon:
                          Icons.chat_outlined,
                      keyboardType:
                          TextInputType.phone,
                      validator:
                          _optionalPhoneValidator,
                    ),

                    const SizedBox(height: 8),

                    _sectionTitle(
                      'Guest Policy',
                    ),

                    _field(
                      controller:
                          _checkInTimeController,
                      label:
                          'Check-in time',
                      icon: Icons.login,
                      hint: 'Example: 2:00 PM',
                      validator:
                          _requiredValidator,
                    ),

                    _field(
                      controller:
                          _checkOutTimeController,
                      label:
                          'Check-out time',
                      icon: Icons.logout,
                      hint: 'Example: 12:00 PM',
                      validator:
                          _requiredValidator,
                    ),

                    _field(
                      controller:
                          _cancellationPolicyController,
                      label:
                          'Cancellation policy',
                      icon:
                          Icons.policy_outlined,
                      maxLines: 4,
                      validator:
                          _requiredValidator,
                    ),

                    _switchTile(
                      title:
                          'Accept Family Bookings',
                      subtitle:
                          'Allow families to book rooms.',
                      value: _acceptsFamilies,
                      onChanged: (value) {
                        setState(() {
                          _acceptsFamilies =
                              value;
                        });
                      },
                    ),

                    _switchTile(
                      title:
                          'Accept Group Bookings',
                      subtitle:
                          'Allow tour groups and sharing guests.',
                      value: _acceptsGroups,
                      onChanged: (value) {
                        setState(() {
                          _acceptsGroups =
                              value;
                        });
                      },
                    ),

                    const SizedBox(height: 8),

                    _sectionTitle(
                      'Facilities',
                    ),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _availableFacilities
                              .map(
                        (facility) {
                          final bool selected =
                              _selectedFacilities
                                  .contains(
                            facility,
                          );

                          return FilterChip(
                            selected: selected,
                            label:
                                Text(facility),
                            selectedColor:
                                yellow.withValues(
                              alpha: 0.25,
                            ),
                            checkmarkColor:
                                yellow,
                            onSelected: (value) {
                              setState(() {
                                if (value) {
                                  if (!_selectedFacilities
                                      .contains(
                                    facility,
                                  )) {
                                    _selectedFacilities
                                        .add(
                                      facility,
                                    );
                                  }
                                } else {
                                  _selectedFacilities
                                      .remove(
                                    facility,
                                  );
                                }

                                _syncFacilitySwitches();
                              });
                            },
                          );
                        },
                      ).toList(),
                    ),

                    const SizedBox(height: 16),

                    _facilitySwitches(),

                    const SizedBox(height: 16),

                    _storageNotice(),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child:
                          ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : _saveHotel,
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              yellow,
                          foregroundColor:
                              Colors.black,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 15,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Colors.black,
                                ),
                              )
                            : const Icon(
                                Icons.save_outlined,
                              ),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : 'Save Hotel Profile',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
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

  Widget _statusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isActive
              ? Colors.green.withValues(
                  alpha: 0.35,
                )
              : Colors.orange.withValues(
                  alpha: 0.35,
                ),
        ),
      ),
      child: SwitchListTile(
        value: _isActive,
        onChanged: (value) {
          setState(() {
            _isActive = value;
          });
        },
        activeThumbColor: yellow,
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Accept New Bookings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _isActive
              ? 'Hotel is visible and can receive new booking requests.'
              : 'Hotel remains registered, but new bookings are paused.',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: yellow,
          ),
          filled: true,
          fillColor: darkCard,
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: yellow,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _facilitySwitches() {
    return Column(
      children: [
        _switchTile(
          title: 'Parking',
          subtitle:
              'Hotel has guest parking.',
          value: _hasParking,
          onChanged: (value) {
            setState(() {
              _hasParking = value;
              _updateFacility(
                'Parking',
                value,
              );
            });
          },
        ),
        _switchTile(
          title: 'Restaurant',
          subtitle:
              'Restaurant or meal service available.',
          value: _hasRestaurant,
          onChanged: (value) {
            setState(() {
              _hasRestaurant = value;
              _updateFacility(
                'Restaurant',
                value,
              );
            });
          },
        ),
        _switchTile(
          title: 'Generator / Backup Power',
          subtitle:
              'Backup electricity is available.',
          value: _hasGenerator,
          onChanged: (value) {
            setState(() {
              _hasGenerator = value;
              _updateFacility(
                'Generator',
                value,
              );
            });
          },
        ),
        _switchTile(
          title: 'Heating',
          subtitle:
              'Room heating is available.',
          value: _hasHeating,
          onChanged: (value) {
            setState(() {
              _hasHeating = value;
              _updateFacility(
                'Heating',
                value,
              );
            });
          },
        ),
        _switchTile(
          title: 'Hot Water',
          subtitle:
              'Hot water is available.',
          value: _hasHotWater,
          onChanged: (value) {
            setState(() {
              _hasHotWater = value;
              _updateFacility(
                'Hot Water',
                value,
              );
            });
          },
        ),
        _switchTile(
          title: 'WiFi',
          subtitle:
              'Internet service is available.',
          value: _hasWiFi,
          onChanged: (value) {
            setState(() {
              _hasWiFi = value;
              _updateFacility(
                'WiFi',
                value,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _storageNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.08,
        ),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.image_outlined,
            color: yellow,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hotel logo, cover photo and gallery upload will be enabled after Firebase Storage billing is available. All other profile controls are active.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadHotel() async {
    try {
      final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot = await _firestore
              .collection('hotels')
              .doc(widget.hotelId)
              .get();

      final Map<String, dynamic> data =
          snapshot.data() ??
              <String, dynamic>{};

      _nameController.text =
          data['name']?.toString() ?? '';

      _descriptionController.text =
          data['description']?.toString() ??
              '';

      _locationController.text =
          data['location']?.toString() ?? '';

      _addressController.text =
          data['address']?.toString() ?? '';

      _receptionPhoneController.text =
          data['phoneNumber']?.toString() ??
              data['receptionPhone']
                  ?.toString() ??
              '';

      _managerPhoneController.text =
          data['managerPhone']?.toString() ??
              '';

      _emergencyPhoneController.text =
          data['emergencyPhone']?.toString() ??
              '';

      _whatsAppController.text =
          data['whatsAppNumber']
                  ?.toString() ??
              '';

      _checkInTimeController.text =
          data['checkInTime']?.toString() ??
              '2:00 PM';

      _checkOutTimeController.text =
          data['checkOutTime']?.toString() ??
              '12:00 PM';

      _cancellationPolicyController.text =
          data['cancellationPolicy']
                  ?.toString() ??
              'Cancellation rules are shown before booking confirmation.';

      _isActive =
          data['isActive'] != false;

      _acceptsFamilies =
          data['acceptsFamilies'] != false;

      _acceptsGroups =
          data['acceptsGroups'] != false;

      final dynamic facilitiesValue =
          data['facilities'];

      if (facilitiesValue is List) {
        _selectedFacilities
          ..clear()
          ..addAll(
            facilitiesValue
                .map(
                  (item) =>
                      item.toString(),
                )
                .where(
                  (item) =>
                      item.trim().isNotEmpty,
                ),
          );
      }

      _syncFacilitySwitches();
    } catch (error) {
      _showMessage(
        'Unable to load hotel profile: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveHotel() async {
    final bool valid =
        _formKey.currentState?.validate() ??
            false;

    if (!valid) {
      _showMessage(
        'Please correct the highlighted fields.',
        isError: true,
      );
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in first.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestore
          .collection('hotels')
          .doc(widget.hotelId)
          .set(
        {
          'name':
              _nameController.text.trim(),
          'description':
              _descriptionController.text
                  .trim(),
          'location':
              _locationController.text.trim(),
          'address':
              _addressController.text.trim(),
          'phoneNumber':
              _receptionPhoneController.text
                  .trim(),
          'receptionPhone':
              _receptionPhoneController.text
                  .trim(),
          'managerPhone':
              _managerPhoneController.text
                  .trim(),
          'emergencyPhone':
              _emergencyPhoneController.text
                  .trim(),
          'whatsAppNumber':
              _whatsAppController.text.trim(),
          'checkInTime':
              _checkInTimeController.text
                  .trim(),
          'checkOutTime':
              _checkOutTimeController.text
                  .trim(),
          'cancellationPolicy':
              _cancellationPolicyController
                  .text
                  .trim(),
          'acceptsFamilies':
              _acceptsFamilies,
          'acceptsGroups':
              _acceptsGroups,
          'facilities':
              List<String>.from(
            _selectedFacilities,
          ),
          'hasParking':
              _hasParking,
          'hasRestaurant':
              _hasRestaurant,
          'hasGenerator':
              _hasGenerator,
          'hasHeating':
              _hasHeating,
          'hasHotWater':
              _hasHotWater,
          'hasWiFi':
              _hasWiFi,
          'isActive':
              _isActive,
          'lastUpdatedBy':
              user.uid,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _showMessage(
        'Hotel profile updated successfully.',
      );
    } catch (error) {
      _showMessage(
        'Unable to save hotel profile: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _syncFacilitySwitches() {
    _hasParking =
        _selectedFacilities.contains(
      'Parking',
    );

    _hasRestaurant =
        _selectedFacilities.contains(
      'Restaurant',
    );

    _hasGenerator =
        _selectedFacilities.contains(
      'Generator',
    );

    _hasHeating =
        _selectedFacilities.contains(
      'Heating',
    );

    _hasHotWater =
        _selectedFacilities.contains(
      'Hot Water',
    );

    _hasWiFi =
        _selectedFacilities.contains(
      'WiFi',
    );
  }

  void _updateFacility(
    String facility,
    bool enabled,
  ) {
    if (enabled) {
      if (!_selectedFacilities.contains(
        facility,
      )) {
        _selectedFacilities.add(
          facility,
        );
      }
    } else {
      _selectedFacilities.remove(
        facility,
      );
    }
  }

  String? _requiredValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  String? _phoneValidator(
    String? value,
  ) {
    final String clean =
        value?.replaceAll(
              RegExp(r'\D'),
              '',
            ) ??
            '';

    if (clean.length < 10 ||
        clean.length > 13) {
      return 'Enter a valid phone number.';
    }

    return null;
  }

  String? _optionalPhoneValidator(
    String? value,
  ) {
    final String text =
        value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    return _phoneValidator(text);
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : darkCard,
        ),
      );
  }
}
