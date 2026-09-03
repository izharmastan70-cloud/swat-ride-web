import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/student_ride_driver_application_model.dart';
import '../../services/student_ride_driver_application_service.dart';

class StudentRideDriverRegistrationScreen extends StatefulWidget {
  const StudentRideDriverRegistrationScreen({super.key});

  @override
  State<StudentRideDriverRegistrationScreen> createState() =>
      _StudentRideDriverRegistrationScreenState();
}

class _StudentRideDriverRegistrationScreenState
    extends State<StudentRideDriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = StudentRideDriverApplicationService();

  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _cnic = TextEditingController();
  final _dateOfBirth = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController(text: 'Swat');
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _normalDriverId = TextEditingController();
  final _licenseNumber = TextEditingController();
  final _vehicleMake = TextEditingController();
  final _vehicleModel = TextEditingController();
  final _vehicleColor = TextEditingController();
  final _vehicleRegistration = TextEditingController();
  final _vehicleYear = TextEditingController();
  final _seatingCapacity = TextEditingController();
  final _experienceYears = TextEditingController(text: '0');
  final _attendantName = TextEditingController();
  final _attendantPhone = TextEditingController();
  final _attendantCnic = TextEditingController();
  final _accountTitle = TextEditingController();
  final _accountNumber = TextEditingController();
  final _bankName = TextEditingController();

  String _vehicleType = 'car';
  String _settlementMethod = 'bank';
  bool _hasExperience = false;
  bool _hasFirstAid = false;
  bool _childSafetyAccepted = false;
  bool _backgroundConsentAccepted = false;
  bool _hasAttendant = false;
  bool _morningAvailable = true;
  bool _afternoonAvailable = true;
  bool _submitting = false;

  final Map<String, String> _documents = <String, String>{};

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _fullName,
      _phone,
      _cnic,
      _dateOfBirth,
      _address,
      _city,
      _emergencyName,
      _emergencyPhone,
      _normalDriverId,
      _licenseNumber,
      _vehicleMake,
      _vehicleModel,
      _vehicleColor,
      _vehicleRegistration,
      _vehicleYear,
      _seatingCapacity,
      _experienceYears,
      _attendantName,
      _attendantPhone,
      _attendantCnic,
      _accountTitle,
      _accountNumber,
      _bankName,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required field';
    return null;
  }

  String? _phoneValidator(String? value) {
    final clean = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (clean.length < 10 || clean.length > 13) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _cnicValidator(String? value) {
    final clean = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (clean.length != 13) return 'CNIC must contain 13 digits';
    return null;
  }

  String? _positiveInt(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 1) return 'Enter a valid number';
    return null;
  }

  void _attachTestingDocument(String key) {
    setState(() {
      _documents[key] =
          'testing://student_ride_driver/${FirebaseAuth.instance.currentUser?.uid ?? 'pending'}/$key';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Testing document attached. Real Firebase Storage upload remains pending.',
        ),
      ),
    );
  }

  bool get _allDocumentsAttached => <String>[
        'profilePhoto',
        'cnicFront',
        'cnicBack',
        'licenseFront',
        'licenseBack',
        'policeVerification',
        'vehicleFront',
        'vehicleBack',
        'vehicleRegistration',
        'fitnessCertificate',
        'insuranceDocument',
      ].every(_documents.containsKey);

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please login before submitting the application.');
      return;
    }
    if (!_morningAvailable && !_afternoonAvailable) {
      _showMessage('Select morning or afternoon availability.');
      return;
    }
    if (!_childSafetyAccepted || !_backgroundConsentAccepted) {
      _showMessage('Safety declaration and background consent are required.');
      return;
    }
    if (!_allDocumentsAttached) {
      _showMessage('Attach all required documents before submission.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final application = StudentRideDriverApplicationModel(
        id: user.uid,
        userId: user.uid,
        existingNormalDriverId: _normalDriverId.text.trim(),
        status: StudentRideDriverApplicationStatus.submitted,
        fullName: _fullName.text.trim(),
        phoneNumber: _phone.text.trim(),
        cnicNumber: _cnic.text.trim(),
        dateOfBirth: _dateOfBirth.text.trim(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        emergencyContactName: _emergencyName.text.trim(),
        emergencyContactPhone: _emergencyPhone.text.trim(),
        profilePhotoUrl: _documents['profilePhoto']!,
        cnicFrontUrl: _documents['cnicFront']!,
        cnicBackUrl: _documents['cnicBack']!,
        drivingLicenseNumber: _licenseNumber.text.trim(),
        drivingLicenseFrontUrl: _documents['licenseFront']!,
        drivingLicenseBackUrl: _documents['licenseBack']!,
        policeVerificationUrl: _documents['policeVerification']!,
        vehicleType: _vehicleType,
        vehicleMake: _vehicleMake.text.trim(),
        vehicleModel: _vehicleModel.text.trim(),
        vehicleColor: _vehicleColor.text.trim(),
        vehicleRegistrationNumber: _vehicleRegistration.text.trim(),
        vehicleModelYear: int.parse(_vehicleYear.text.trim()),
        seatingCapacity: int.parse(_seatingCapacity.text.trim()),
        vehicleFrontPhotoUrl: _documents['vehicleFront']!,
        vehicleBackPhotoUrl: _documents['vehicleBack']!,
        vehicleRegistrationDocumentUrl: _documents['vehicleRegistration']!,
        vehicleFitnessCertificateUrl: _documents['fitnessCertificate']!,
        vehicleInsuranceDocumentUrl: _documents['insuranceDocument']!,
        schoolTransportExperienceYears:
            int.tryParse(_experienceYears.text.trim()) ?? 0,
        hasSchoolTransportExperience: _hasExperience,
        hasFirstAidTraining: _hasFirstAid,
        childSafetyDeclarationAccepted: _childSafetyAccepted,
        backgroundCheckConsentAccepted: _backgroundConsentAccepted,
        hasAttendant: _hasAttendant,
        attendantName: _hasAttendant ? _attendantName.text.trim() : '',
        attendantPhone: _hasAttendant ? _attendantPhone.text.trim() : '',
        attendantCnicNumber: _hasAttendant ? _attendantCnic.text.trim() : '',
        morningAvailable: _morningAvailable,
        afternoonAvailable: _afternoonAvailable,
        preferredSchoolIds: const <String>[],
        preferredRouteIds: const <String>[],
        settlementMethod: _settlementMethod,
        accountTitle: _accountTitle.text.trim(),
        accountNumber: _accountNumber.text.trim(),
        bankName: _bankName.text.trim(),
        rejectionReason: '',
        adminNotes: '',
        reviewedBy: '',
        submittedAt: null,
        reviewedAt: null,
        createdAt: null,
        updatedAt: null,
      );

      final applicationId = await _service.submitApplication(application);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Application submitted'),
          content: Text(
            'Your Student Ride Driver application has been sent for admin approval.\n\nApplication ID: $applicationId',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Ride Driver Registration')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _notice(),
            _section('Personal information'),
            _field(_fullName, 'Full name'),
            _field(_phone, 'Phone number', validator: _phoneValidator),
            _field(_cnic, 'CNIC number', validator: _cnicValidator),
            _field(_dateOfBirth, 'Date of birth (YYYY-MM-DD)'),
            _field(_address, 'Home address', maxLines: 2),
            _field(_city, 'City'),
            _field(_emergencyName, 'Emergency contact name'),
            _field(
              _emergencyPhone,
              'Emergency contact phone',
              validator: _phoneValidator,
            ),
            _field(
              _normalDriverId,
              'Existing normal Driver ID (optional)',
              required: false,
            ),
            _section('Driving and vehicle'),
            _field(_licenseNumber, 'Driving licence number'),
            DropdownButtonFormField<String>(
              initialValue: _vehicleType,
              decoration: const InputDecoration(labelText: 'Vehicle type'),
              items: const [
                DropdownMenuItem(value: 'car', child: Text('Car')),
                DropdownMenuItem(value: 'van', child: Text('Van')),
                DropdownMenuItem(value: 'coaster', child: Text('Coaster')),
              ],
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _vehicleType = value ?? 'car'),
            ),
            const SizedBox(height: 12),
            _field(_vehicleMake, 'Vehicle make'),
            _field(_vehicleModel, 'Vehicle model'),
            _field(_vehicleColor, 'Vehicle color'),
            _field(_vehicleRegistration, 'Vehicle registration number'),
            _field(_vehicleYear, 'Vehicle model year', validator: _positiveInt),
            _field(
              _seatingCapacity,
              'Student seating capacity',
              validator: _positiveInt,
            ),
            _section('Student transport checks'),
            SwitchListTile(
              value: _hasExperience,
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _hasExperience = value),
              title: const Text('School transport experience'),
            ),
            if (_hasExperience)
              _field(
                _experienceYears,
                'Experience years',
                validator: _positiveInt,
              ),
            SwitchListTile(
              value: _hasFirstAid,
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _hasFirstAid = value),
              title: const Text('First-aid training completed'),
            ),
            SwitchListTile(
              value: _hasAttendant,
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _hasAttendant = value),
              title: const Text('Vehicle has an attendant'),
            ),
            if (_hasAttendant) ...[
              _field(_attendantName, 'Attendant name'),
              _field(
                _attendantPhone,
                'Attendant phone',
                validator: _phoneValidator,
              ),
              _field(
                _attendantCnic,
                'Attendant CNIC',
                validator: _cnicValidator,
              ),
            ],
            _section('Shift availability'),
            CheckboxListTile(
              value: _morningAvailable,
              onChanged: _submitting
                  ? null
                  : (value) =>
                      setState(() => _morningAvailable = value ?? false),
              title: const Text('Morning school pickup'),
            ),
            CheckboxListTile(
              value: _afternoonAvailable,
              onChanged: _submitting
                  ? null
                  : (value) =>
                      setState(() => _afternoonAvailable = value ?? false),
              title: const Text('Afternoon school return'),
            ),
            _section('Required documents'),
            ...<MapEntry<String, String>>[
              const MapEntry('profilePhoto', 'Profile photo'),
              const MapEntry('cnicFront', 'CNIC front'),
              const MapEntry('cnicBack', 'CNIC back'),
              const MapEntry('licenseFront', 'Driving licence front'),
              const MapEntry('licenseBack', 'Driving licence back'),
              const MapEntry('policeVerification', 'Police verification'),
              const MapEntry('vehicleFront', 'Vehicle front photo'),
              const MapEntry('vehicleBack', 'Vehicle back photo'),
              const MapEntry(
                'vehicleRegistration',
                'Vehicle registration document',
              ),
              const MapEntry('fitnessCertificate', 'Fitness certificate'),
              const MapEntry('insuranceDocument', 'Insurance document'),
            ].map(_documentTile),
            _section('Settlement account'),
            DropdownButtonFormField<String>(
              initialValue: _settlementMethod,
              decoration: const InputDecoration(labelText: 'Settlement method'),
              items: const [
                DropdownMenuItem(value: 'bank', child: Text('Bank account')),
                DropdownMenuItem(value: 'easypaisa', child: Text('Easypaisa')),
                DropdownMenuItem(value: 'jazzcash', child: Text('JazzCash')),
              ],
              onChanged: _submitting
                  ? null
                  : (value) =>
                      setState(() => _settlementMethod = value ?? 'bank'),
            ),
            const SizedBox(height: 12),
            _field(_accountTitle, 'Account title'),
            _field(_accountNumber, 'Account / mobile number'),
            _field(
              _bankName,
              'Bank name',
              required: _settlementMethod == 'bank',
            ),
            _section('Declarations'),
            CheckboxListTile(
              value: _childSafetyAccepted,
              onChanged: _submitting
                  ? null
                  : (value) =>
                      setState(() => _childSafetyAccepted = value ?? false),
              title: const Text(
                'I accept the child-safety and authorized-handover rules.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              value: _backgroundConsentAccepted,
              onChanged: _submitting
                  ? null
                  : (value) => setState(
                      () => _backgroundConsentAccepted = value ?? false,
                    ),
              title: const Text(
                'I consent to police, identity and background verification.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _submitting ? 'Submitting...' : 'Submit for Admin Approval',
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _notice() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Student Ride drivers require separate admin approval even when they already work as a normal Ride driver.',
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    bool required = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: !_submitting,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: validator ?? (required ? _required : null),
      ),
    );
  }

  Widget _documentTile(MapEntry<String, String> document) {
    final attached = _documents.containsKey(document.key);
    return Card(
      child: ListTile(
        leading: Icon(
          attached ? Icons.check_circle : Icons.upload_file,
          color: attached ? Colors.green : null,
        ),
        title: Text(document.value),
        subtitle: Text(
          attached ? 'Attached for testing' : 'Required document',
        ),
        trailing: TextButton(
          onPressed:
              _submitting ? null : () => _attachTestingDocument(document.key),
          child: Text(attached ? 'Replace' : 'Attach'),
        ),
      ),
    );
  }
}
