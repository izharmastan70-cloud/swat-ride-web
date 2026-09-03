import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/hotel_partner_application.dart';
import '../services/hotel_partner_application_service.dart';

class HotelPartnerRegistrationScreen extends StatefulWidget {
  const HotelPartnerRegistrationScreen({super.key});

  @override
  State<HotelPartnerRegistrationScreen> createState() =>
      _HotelPartnerRegistrationScreenState();
}

class _HotelPartnerRegistrationScreenState
    extends State<HotelPartnerRegistrationScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final HotelPartnerApplicationService _service =
      HotelPartnerApplicationService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerPhoneController = TextEditingController();
  final TextEditingController _ownerCnicController = TextEditingController();
  final TextEditingController _ownerEmailController = TextEditingController();
  final TextEditingController _hotelNameController = TextEditingController();
  final TextEditingController _hotelPhoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _totalRoomsController = TextEditingController();
  final TextEditingController _minimumPriceController = TextEditingController();

  final List<String> _selectedFacilities = <String>[];
  // Primary Hotel Type (single selection)
final List<String> _hotelTypes = const <String>[
  'Hotel',
  'Resort',
  'Guest House',
  'Hostel',
  'Apartment Hotel',
  'Boutique Hotel',
];

// Hotel Categories (multiple selection)
final List<String> _hotelCategories = const <String>[
  'Family Friendly',
  'Luxury',
  'Budget',
  'Business',
  'Tour Groups',
  'Students',
  'Couples',
  'Foreign Tourists',
  'Women Friendly',
  'Wheelchair Accessible',
  'Pet Friendly',
];

final List<String> _selectedHotelCategories = <String>[];

String _selectedHotelType = 'Hotel';
  final List<String> _availableFacilities = const <String>[
    'WiFi',
    'Parking',
    'Restaurant',
    'Breakfast',
    'Family Rooms',
    'Air Conditioning',
    'Heater',
    'Laundry',
    'Generator',
    'Prayer Area',
    'Tour Desk',
    'Airport Pickup',
  ];

  String _checkInTime = '02:00 PM';
  String _checkOutTime = '12:00 PM';
  String _applicationId = '';
  bool _agreeToTerms = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerCnicController.dispose();
    _ownerEmailController.dispose();
    _hotelNameController.dispose();
    _hotelPhoneController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _totalRoomsController.dispose();
    _minimumPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Hotel Partner Registration',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _sectionTitle(Icons.person, 'Owner Details'),
                const SizedBox(height: 12),
                _textField(
                  controller: _ownerNameController,
                  label: 'Owner full name',
                  icon: Icons.person_outline,
                  validator: _requiredValidator,
                ),
                _textField(
                  controller: _ownerPhoneController,
                  label: 'Owner phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: _phoneValidator,
                ),
                _textField(
                  controller: _ownerCnicController,
                  label: 'Owner CNIC',
                  hint: '12345-1234567-1',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  validator: _cnicValidator,
                ),
                _textField(
                  controller: _ownerEmailController,
                  label: 'Owner email (optional)',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _optionalEmailValidator,
                ),
                const SizedBox(height: 10),
                _sectionTitle(Icons.business, 'Hotel Details'),
                const SizedBox(height: 12),
                _textField(
                  controller: _hotelNameController,
                  label: 'Hotel name',
                  icon: Icons.hotel_outlined,
                  validator: _requiredValidator,
                ),
                _textField(
                  controller: _hotelPhoneController,
                  label: 'Hotel contact number',
                  icon: Icons.call_outlined,
                  keyboardType: TextInputType.phone,
                  validator: _phoneValidator,
                ),
                _hotelTypeDropdown(),
                const SizedBox(height: 10),
_sectionTitle(
  Icons.category_outlined,
  'Hotel Categories',
),
const SizedBox(height: 12),
_hotelCategoriesCard(),
                _textField(
                  controller: _descriptionController,
                  label: 'Hotel description',
                  icon: Icons.description_outlined,
                  maxLines: 4,
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 10),
                _sectionTitle(Icons.location_on, 'Location'),
                const SizedBox(height: 12),
                _textField(
                  controller: _locationController,
                  label: 'Area / City',
                  hint: 'Mingora, Kalam, Bahrain...',
                  icon: Icons.place_outlined,
                  validator: _requiredValidator,
                ),
                _textField(
                  controller: _addressController,
                  label: 'Complete hotel address',
                  icon: Icons.map_outlined,
                  maxLines: 3,
                  validator: _requiredValidator,
                ),
                _testingLocationCard(),
                const SizedBox(height: 22),
                _sectionTitle(Icons.meeting_room, 'Rooms & Pricing'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _textField(
                        controller: _totalRoomsController,
                        label: 'Total rooms',
                        icon: Icons.meeting_room_outlined,
                        keyboardType: TextInputType.number,
                        validator: _positiveIntegerValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _textField(
                        controller: _minimumPriceController,
                        label: 'Starting price',
                        icon: Icons.payments_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _nonNegativePriceValidator,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _timeCard(
                        title: 'Check-in',
                        value: _checkInTime,
                        onTap: () => _selectTime(isCheckIn: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _timeCard(
                        title: 'Check-out',
                        value: _checkOutTime,
                        onTap: () => _selectTime(isCheckIn: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _sectionTitle(Icons.check_circle_outline, 'Facilities'),
                const SizedBox(height: 12),
                _facilitiesCard(),
                const SizedBox(height: 22),
                _sectionTitle(Icons.image_outlined, 'Images & Documents'),
                const SizedBox(height: 12),
                _uploadPlaceholder(
                  icon: Icons.add_photo_alternate_outlined,
                  title: 'Hotel Images',
                  subtitle:
                      'Image selection will be enabled after Firebase Storage billing is available.',
                ),
                const SizedBox(height: 12),
                _uploadPlaceholder(
                  icon: Icons.file_present_outlined,
                  title: 'Owner CNIC / Hotel Documents',
                  subtitle:
                      'Document upload UI is reserved; actual Storage upload is currently bypassed.',
                ),
                const SizedBox(height: 22),
                CheckboxListTile(
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreeToTerms = value ?? false;
                    });
                  },
                  activeColor: yellow,
                  checkColor: Colors.black,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'I confirm that the hotel information is correct and I agree to the SWAT RIDE Hotel Partner terms.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _saveDraft,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Draft'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: yellow,
                          side: const BorderSide(color: yellow),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submitApplication,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: const Text('Submit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: yellow,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your customer account will remain active. After admin approval, Hotel Partner Dashboard will be added to your menu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: yellow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: yellow.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: yellow, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Register Your Hotel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Submit your hotel details for SWAT RIDE admin approval. You can continue using the app as a normal customer.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: yellow, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.grey),
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: yellow),
          filled: true,
          fillColor: darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: yellow),
          ),
        ),
      ),
    );
  }

Widget _hotelCategoriesCard() {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: _hotelCategories.map((category) {
      final bool selected =
          _selectedHotelCategories.contains(category);

      return FilterChip(
        label: Text(category),
        selected: selected,
        onSelected: (value) {
          setState(() {
            if (value) {
              _selectedHotelCategories.add(category);
            } else {
              _selectedHotelCategories.remove(category);
            }
          });
        },
      );
    }).toList(),
  );
}

Widget _hotelTypeDropdown() {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: darkCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.05),
      ),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedHotelType,
        isExpanded: true,
        dropdownColor: darkCard,
        icon: const Icon(Icons.keyboard_arrow_down, color: yellow),
        items: _hotelTypes
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Row(
                  children: [
                    const Icon(Icons.category_outlined, color: yellow),
                    const SizedBox(width: 12),
                    Text(item,
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _selectedHotelType = value;
          });
        },
      ),
    ),
  );
}

Widget _testingLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.gps_fixed, color: yellow),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Map pin and live coordinates will be connected in the GPS phase. Address entry is active now.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeCard({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: darkCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.schedule, color: yellow, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _facilitiesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _availableFacilities.map((facility) {
          final bool selected = _selectedFacilities.contains(facility);
          return FilterChip(
            selected: selected,
            label: Text(facility),
            selectedColor: yellow.withValues(alpha: 0.25),
            checkmarkColor: yellow,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.grey,
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.04),
            side: BorderSide(
              color: selected
                  ? yellow
                  : Colors.white.withValues(alpha: 0.06),
            ),
            onSelected: (value) {
              setState(() {
                if (value) {
                  _selectedFacilities.add(facility);
                } else {
                  _selectedFacilities.remove(facility);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _uploadPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: yellow, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_clock_outlined, color: Colors.grey),
        ],
      ),
    );
  }

  Future<void> _selectTime({required bool isCheckIn}) async {
    final TimeOfDay initial = isCheckIn
        ? const TimeOfDay(hour: 14, minute: 0)
        : const TimeOfDay(hour: 12, minute: 0);

    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (!mounted || selected == null) return;

    final String formatted = selected.format(context);
    setState(() {
      if (isCheckIn) {
        _checkInTime = formatted;
      } else {
        _checkOutTime = formatted;
      }
    });
  }

  Future<void> _saveDraft() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage(
        'Please log in before saving the application.',
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final HotelPartnerApplication application = _buildApplication(
        userId: user.uid,
        status: 'draft',
      );

      final String id = await _service.saveDraft(application);
      if (!mounted) return;

      setState(() => _applicationId = id);
      _showMessage('Draft saved successfully.');
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitApplication() async {
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      _showMessage('Please correct the highlighted fields.', isError: true);
      return;
    }

    if (!_agreeToTerms) {
      _showMessage('Please accept the Hotel Partner terms.', isError: true);
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please log in before submitting.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final HotelPartnerApplication application = _buildApplication(
        userId: user.uid,
        status: 'submitted',
      );

      final String id = await _service.submitApplication(application);
      if (!mounted) return;

      setState(() => _applicationId = id);
      await _showSubmittedDialog();
    } catch (error) {
      _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  HotelPartnerApplication _buildApplication({
    required String userId,
    required String status,
  }) {
    return HotelPartnerApplication(
      id: _applicationId,
      applicantUserId: userId,
      ownerName: _ownerNameController.text.trim(),
      ownerPhone: _ownerPhoneController.text.trim(),
      ownerCnic: _ownerCnicController.text.trim(),
      ownerEmail: _ownerEmailController.text.trim(),
      hotelName: _hotelNameController.text.trim(),
      hotelPhone: _hotelPhoneController.text.trim(),
      location: _locationController.text.trim(),
      address: _addressController.text.trim(),
      hotelType: _selectedHotelType,
hotelCategories: List<String>.from(_selectedHotelCategories),
category: _selectedHotelType,
      description: _descriptionController.text.trim(),
      facilities: List<String>.from(_selectedFacilities),
      totalRooms: int.tryParse(_totalRoomsController.text.trim()) ?? 0,
      minimumRoomPrice:
          double.tryParse(_minimumPriceController.text.trim()) ?? 0,
      checkInTime: _checkInTime,
      checkOutTime: _checkOutTime,
      applicationStatus: status,
      isCustomerAccessEnabled: true,
      createdAt: null,
      updatedAt: null,
      imageUrls: const <String>[],
      documentUrls: const <String>[],
    );
  }

  Future<void> _showSubmittedDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: darkCard,
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: yellow),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Application Submitted',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Your application is now waiting for SWAT RIDE admin review. You will receive a notification for approval, rejection, or requested changes.',
            style: TextStyle(color: Colors.grey, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: yellow,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final String clean = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (clean.length < 10 || clean.length > 13) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  String? _cnicValidator(String? value) {
    final String clean = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (clean.length != 13) {
      return 'Enter a valid 13-digit CNIC.';
    }
    return null;
  }

  String? _optionalEmailValidator(String? value) {
    final String email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _positiveIntegerValidator(String? value) {
    final int? number = int.tryParse(value?.trim() ?? '');
    if (number == null || number <= 0) {
      return 'Enter a valid number.';
    }
    return null;
  }

  String? _nonNegativePriceValidator(String? value) {
    final double? price = double.tryParse(value?.trim() ?? '');
    if (price == null || price < 0) {
      return 'Enter a valid price.';
    }
    return null;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : darkCard,
        ),
      );
  }
}
