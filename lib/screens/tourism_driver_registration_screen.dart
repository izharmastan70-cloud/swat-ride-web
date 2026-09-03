import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/tourism_driver_application.dart';
import '../services/tourism_driver_application_service.dart';

class TourismDriverRegistrationScreen
    extends StatefulWidget {
  const TourismDriverRegistrationScreen({
    super.key,
  });

  @override
  State<TourismDriverRegistrationScreen>
      createState() =>
          _TourismDriverRegistrationScreenState();
}

class _TourismDriverRegistrationScreenState
    extends State<TourismDriverRegistrationScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground =
      Color(0xFF0D0D0D);

  final _formKey = GlobalKey<FormState>();

  final _service =
      TourismDriverApplicationService();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _cnic = TextEditingController();
  final _license = TextEditingController();
  final _experience = TextEditingController();
  final _vehicleModel = TextEditingController();
  final _vehicleNumber = TextEditingController();
  final _seats = TextEditingController();
  final _luggage = TextEditingController();
  final _pricePerDay = TextEditingController();
  final _pricePerKm = TextEditingController();
  final _allowance = TextEditingController();
  final _emergencyContactName = TextEditingController();
  final _emergencyContactPhone = TextEditingController();
  final _vehicleModelYear = TextEditingController();
  final _tourismPermitNumber = TextEditingController();

  String _applicationId = '';
  String _vehicleType = 'Toyota Corolla';

  bool _hasAc = true;
  bool _mountainRoutes = false;
  bool _multiDay = true;
  bool _groupTours = true;
  bool _familyTours = true;
  bool _hotelPickup = true;
  bool _nightDriving = false;
  bool _airportPickup = false;
  bool _firstAidCertified = false;
  bool _guideCertified = false;
  bool _passportAvailable = false;
  bool _gpsTrackingReady = true;
  bool _policeCertificateAvailable = false;
  bool _agree = false;
  bool _saving = false;

  DateTime? _licenseExpiryDate;
  DateTime? _tourismPermitExpiryDate;

  final List<String> _languages = <String>[];
  final List<String> _routes = <String>[];

  final _availableLanguages = const [
    'Pashto',
    'Urdu',
    'English',
    'Punjabi',
  ];

  final _availableRoutes = const [
    'Mingora',
    'Malam Jabba',
    'Bahrain',
    'Kalam',
    'Mahodand Lake',
    'Ushu Forest',
    'Gabral Valley',
  ];

  final _vehicleTypes = const [
    'Toyota Corolla',
    'Corolla Fielder',
    'Suzuki Wagon R',
    'Toyota Hiace',
    'Grand Cabin',
    'Coaster',
    '4x4 Jeep',
    'Prado / Fortuner',
  ];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _cnic.dispose();
    _license.dispose();
    _experience.dispose();
    _vehicleModel.dispose();
    _vehicleNumber.dispose();
    _seats.dispose();
    _luggage.dispose();
    _pricePerDay.dispose();
    _pricePerKm.dispose();
    _allowance.dispose();
    _emergencyContactName.dispose();
    _emergencyContactPhone.dispose();
    _vehicleModelYear.dispose();
    _tourismPermitNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        title: const Text(
          'Tourism Driver Registration',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(),
              const SizedBox(height: 22),
              _title('Driver Details'),
              _field(
                _name,
                'Full name',
                Icons.person,
                validator: _required,
              ),
              _field(
                _phone,
                'Phone number',
                Icons.phone,
                keyboardType: TextInputType.phone,
                validator: _phoneValidator,
              ),
              _field(
                _cnic,
                'CNIC',
                Icons.badge,
                keyboardType: TextInputType.number,
                validator: _cnicValidator,
              ),
              _field(
                _license,
                'Driving license number',
                Icons.credit_card,
                validator: _required,
              ),
              _field(
                _experience,
                'Tourism driving experience (years)',
                Icons.timeline,
                keyboardType: TextInputType.number,
                validator: _positiveNumber,
              ),
              const SizedBox(height: 12),
              _title('Emergency Contact'),
              _field(
                _emergencyContactName,
                'Emergency contact name',
                Icons.contact_emergency_outlined,
                validator: _required,
              ),
              _field(
                _emergencyContactPhone,
                'Emergency contact phone',
                Icons.phone_in_talk_outlined,
                keyboardType: TextInputType.phone,
                validator: _phoneValidator,
              ),
              _dateTile(
                title: 'Driving license expiry date',
                date: _licenseExpiryDate,
                onTap: () => _pickDate(
                  current: _licenseExpiryDate,
                  onSelected: (date) {
                    setState(() {
                      _licenseExpiryDate = date;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              _title('Languages'),
              _chips(
                items: _availableLanguages,
                selected: _languages,
              ),
              const SizedBox(height: 22),
              _title('Tourism Vehicle'),
              _dropdown(),
              _field(
                _vehicleModel,
                'Vehicle model',
                Icons.directions_car,
                validator: _required,
              ),
              _field(
                _vehicleModelYear,
                'Vehicle model year',
                Icons.calendar_month_outlined,
                keyboardType: TextInputType.number,
                validator: _vehicleYearValidator,
              ),
              _field(
                _vehicleNumber,
                'Vehicle registration number',
                Icons.confirmation_number,
                validator: _required,
              ),
              _field(
                _seats,
                'Passenger seats',
                Icons.event_seat,
                keyboardType: TextInputType.number,
                validator: _positiveNumber,
              ),
              _field(
                _luggage,
                'Luggage capacity',
                Icons.luggage,
                hint: 'Example: 4 large bags',
                validator: _required,
              ),
              _switch(
                'Air conditioning',
                _hasAc,
                (value) => setState(() => _hasAc = value),
              ),
              const SizedBox(height: 22),
              _title('Tourism Permit & Safety'),
              _field(
                _tourismPermitNumber,
                'Tourism permit / registration number',
                Icons.verified_user_outlined,
                validator: _required,
              ),
              _dateTile(
                title: 'Tourism permit expiry date',
                date: _tourismPermitExpiryDate,
                onTap: () => _pickDate(
                  current: _tourismPermitExpiryDate,
                  onSelected: (date) {
                    setState(() {
                      _tourismPermitExpiryDate = date;
                    });
                  },
                ),
              ),
              _switch(
                'Police character certificate available',
                _policeCertificateAvailable,
                (value) => setState(
                  () => _policeCertificateAvailable = value,
                ),
              ),
              _switch(
                'First aid certified',
                _firstAidCertified,
                (value) => setState(
                  () => _firstAidCertified = value,
                ),
              ),
              _switch(
                'Tour guide certified',
                _guideCertified,
                (value) => setState(
                  () => _guideCertified = value,
                ),
              ),
              _switch(
                'Passport available',
                _passportAvailable,
                (value) => setState(
                  () => _passportAvailable = value,
                ),
              ),
              _switch(
                'GPS tracking ready',
                _gpsTrackingReady,
                (value) => setState(
                  () => _gpsTrackingReady = value,
                ),
              ),
              const SizedBox(height: 22),
              _title('Tour Services'),
              _switch(
                'Mountain routes',
                _mountainRoutes,
                (value) => setState(
                  () => _mountainRoutes = value,
                ),
              ),
              _switch(
                'Multi-day tours',
                _multiDay,
                (value) =>
                    setState(() => _multiDay = value),
              ),
              _switch(
                'Group tours',
                _groupTours,
                (value) => setState(
                  () => _groupTours = value,
                ),
              ),
              _switch(
                'Private family tours',
                _familyTours,
                (value) => setState(
                  () => _familyTours = value,
                ),
              ),
              _switch(
                'Hotel pickup',
                _hotelPickup,
                (value) => setState(
                  () => _hotelPickup = value,
                ),
              ),
              _switch(
                'Airport pickup',
                _airportPickup,
                (value) => setState(
                  () => _airportPickup = value,
                ),
              ),
              _switch(
                'Night driving',
                _nightDriving,
                (value) => setState(
                  () => _nightDriving = value,
                ),
              ),
              const SizedBox(height: 22),
              _title('Available Routes'),
              _chips(
                items: _availableRoutes,
                selected: _routes,
              ),
              const SizedBox(height: 22),
              _title('Pricing'),
              _field(
                _pricePerDay,
                'Price per day',
                Icons.payments,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _nonNegative,
              ),
              _field(
                _pricePerKm,
                'Price per KM',
                Icons.route,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _nonNegative,
              ),
              _field(
                _allowance,
                'Driver allowance per day',
                Icons.account_balance_wallet,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _nonNegative,
              ),
              const SizedBox(height: 16),
              _uploadPlaceholder(),
              CheckboxListTile(
                value: _agree,
                onChanged: (value) {
                  setState(() {
                    _agree = value ?? false;
                  });
                },
                activeColor: yellow,
                checkColor: Colors.black,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'I confirm that the information is correct and agree to the Tourism Driver terms.',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : _saveDraft,
                      child: const Text('Save Draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: yellow,
                        foregroundColor: Colors.black,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: yellow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Register separately for tourism jobs. Your normal customer access will remain active.',
        style: TextStyle(
          height: 1.4,
        ),
      ),
    );
  }

  Widget _title(String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
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
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _dropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _vehicleType,
          isExpanded: true,
          dropdownColor: darkCard,
          items: _vehicleTypes
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _vehicleType = value);
          },
        ),
      ),
    );
  }

  Widget _chips({
    required List<String> items,
    required List<String> selected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map(
        (item) {
          final active = selected.contains(item);

          return FilterChip(
            selected: active,
            label: Text(item),
            selectedColor:
                yellow.withValues(alpha: 0.25),
            checkmarkColor: yellow,
            onSelected: (value) {
              setState(() {
                if (value) {
                  selected.add(item);
                } else {
                  selected.remove(item);
                }
              });
            },
          );
        },
      ).toList(),
    );
  }

  Widget _switch(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: yellow,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
    );
  }

  Widget _dateTile({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(
          Icons.calendar_month_outlined,
          color: yellow,
        ),
        title: Text(title),
        subtitle: Text(
          date == null
              ? 'Tap to select'
              : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
      ),
    );
  }

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final DateTime now = DateTime.now();

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: current ??
          DateTime(
            now.year + 1,
            now.month,
            now.day,
          ),
      firstDate: now,
      lastDate: DateTime(now.year + 20),
    );

    if (selected != null) {
      onSelected(selected);
    }
  }

  Widget _uploadPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'CNIC, license, vehicle documents and photos will be uploaded after Firebase Storage billing is enabled.',
        style: TextStyle(
          color: Colors.grey,
          height: 1.4,
        ),
      ),
    );
  }

  Future<void> _saveDraft() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _message('Please log in first.', true);
      return;
    }

    setState(() => _saving = true);

    try {
      final id = await _service.saveDraft(
        _buildApplication(
          user.uid,
          'draft',
        ),
      );

      if (!mounted) return;

      setState(() => _applicationId = id);
      await _saveProfessionalDetails(
        applicationId: id,
      );
      _message('Draft saved successfully.', false);
    } catch (e) {
      _message(e.toString(), true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _submit() async {
    final valid =
        _formKey.currentState?.validate() ?? false;

    if (!valid) {
      _message(
        'Please correct the highlighted fields.',
        true,
      );
      return;
    }

    if (_languages.isEmpty) {
      _message(
        'Select at least one language.',
        true,
      );
      return;
    }

    if (_routes.isEmpty) {
      _message(
        'Select at least one available route.',
        true,
      );
      return;
    }

    if (_licenseExpiryDate == null) {
      _message(
        'Select the driving license expiry date.',
        true,
      );
      return;
    }

    if (_tourismPermitExpiryDate == null) {
      _message(
        'Select the tourism permit expiry date.',
        true,
      );
      return;
    }

    if (!_policeCertificateAvailable) {
      _message(
        'Police character certificate is required.',
        true,
      );
      return;
    }

    if (!_agree) {
      _message(
        'Please accept the terms.',
        true,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _message('Please log in first.', true);
      return;
    }

    setState(() => _saving = true);

    try {
      final id = await _service.submitApplication(
        _buildApplication(
          user.uid,
          'submitted',
        ),
      );

      if (!mounted) return;

      setState(() => _applicationId = id);
      await _saveProfessionalDetails(
        applicationId: id,
      );

  if (!mounted) {
    return;
  }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: darkCard,
          title: const Text(
            'Application Submitted',
          ),
          content: const Text(
            'Your tourism driver application is waiting for admin review.',
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
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      _message(e.toString(), true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _saveProfessionalDetails({
    required String applicationId,
  }) async {
    await FirebaseFirestore.instance
        .collection(
          TourismDriverApplicationService.collectionName,
        )
        .doc(applicationId)
        .set(
      <String, dynamic>{
        'emergencyContactName':
            _emergencyContactName.text.trim(),
        'emergencyContactPhone':
            _emergencyContactPhone.text.trim(),
        'vehicleModelYear':
            int.tryParse(_vehicleModelYear.text.trim()) ?? 0,
        'licenseExpiryDate': _licenseExpiryDate == null
            ? null
            : Timestamp.fromDate(_licenseExpiryDate!),
        'tourismPermitNumber':
            _tourismPermitNumber.text.trim(),
        'tourismPermitExpiryDate':
            _tourismPermitExpiryDate == null
                ? null
                : Timestamp.fromDate(
                    _tourismPermitExpiryDate!,
                  ),
        'policeCharacterCertificateAvailable':
            _policeCertificateAvailable,
        'firstAidCertified': _firstAidCertified,
        'guideCertified': _guideCertified,
        'passportAvailable': _passportAvailable,
        'gpsTrackingReady': _gpsTrackingReady,
        'supportsAirportPickup': _airportPickup,
        'supportsNightDriving': _nightDriving,
        'professionalDetailsUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  TourismDriverApplication _buildApplication(
    String userId,
    String status,
  ) {
    return TourismDriverApplication(
      id: _applicationId,
      userId: userId,
      fullName: _name.text.trim(),
      phoneNumber: _phone.text.trim(),
      cnic: _cnic.text.trim(),
      licenseNumber: _license.text.trim(),
      experienceYears:
          int.tryParse(_experience.text.trim()) ?? 0,
      languages: List<String>.from(_languages),
      vehicleType: _vehicleType,
      vehicleModel: _vehicleModel.text.trim(),
      vehicleNumber: _vehicleNumber.text.trim(),
      seats: int.tryParse(_seats.text.trim()) ?? 0,
      luggageCapacity: _luggage.text.trim(),
      hasAirConditioning: _hasAc,
      supportsMountainRoutes: _mountainRoutes,
      supportsMultiDayTours: _multiDay,
      supportsGroupTours: _groupTours,
      supportsFamilyTours: _familyTours,
      supportsHotelPickup: _hotelPickup,
      availableRoutes: List<String>.from(_routes),
      pricePerDay:
          double.tryParse(_pricePerDay.text.trim()) ??
              0,
      pricePerKm:
          double.tryParse(_pricePerKm.text.trim()) ??
              0,
      driverAllowancePerDay:
          double.tryParse(_allowance.text.trim()) ??
              0,
      applicationStatus: status,
      isCustomerAccessEnabled: true,
      createdAt: null,
      updatedAt: null,
      imageUrls: const <String>[],
      documentUrls: const <String>[],
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final clean =
        value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (clean.length < 10 || clean.length > 13) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  String? _cnicValidator(String? value) {
    final clean =
        value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (clean.length != 13) {
      return 'Enter a valid 13-digit CNIC.';
    }
    return null;
  }

  String? _positiveNumber(String? value) {
    final number =
        int.tryParse(value?.trim() ?? '');
    if (number == null || number < 0) {
      return 'Enter a valid number.';
    }
    return null;
  }

  String? _vehicleYearValidator(String? value) {
    final int? year = int.tryParse(value?.trim() ?? '');
    final int currentYear = DateTime.now().year;

    if (year == null ||
        year < 1980 ||
        year > currentYear + 1) {
      return 'Enter a valid vehicle model year.';
    }

    return null;
  }

  String? _nonNegative(String? value) {
    final number =
        double.tryParse(value?.trim() ?? '');
    if (number == null || number < 0) {
      return 'Enter a valid amount.';
    }
    return null;
  }

  void _message(
    String text,
    bool error,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor:
              error ? Colors.red : darkCard,
        ),
      );
  }
}
