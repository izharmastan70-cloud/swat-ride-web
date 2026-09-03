// lib/food/rider/screens/food_delivery_rider_registration_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Food Delivery Rider Registration Screen
//
// Features:
// - Personal information
// - Date of birth typing + date picker
// - Address
// - Delivery vehicle: Motorcycle, Rickshaw, Car, Other
// - Camera / Gallery image picker
// - Image preview and remove
// - CNIC front/back
// - Driving license front/back
// - Vehicle registration
// - Vehicle photo
// - Rider photo
// - Firestore application submission
//
// Firebase Storage is temporarily bypassed.
// Real Storage upload code is preserved in comments for later.
// =============================================================

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/food_service_control_service.dart';
import '../models/food_delivery_rider_model.dart';
import '../services/food_delivery_rider_service.dart';
import 'food_delivery_rider_status_screen.dart';

class FoodDeliveryRiderRegistrationScreen
    extends StatefulWidget {
  const FoodDeliveryRiderRegistrationScreen({
    super.key,
  });

  @override
  State<FoodDeliveryRiderRegistrationScreen>
      createState() =>
          _FoodDeliveryRiderRegistrationScreenState();
}

class _FoodDeliveryRiderRegistrationScreenState
    extends State<FoodDeliveryRiderRegistrationScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color fieldColor = Color(0xFF252525);

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final FoodDeliveryRiderService _riderService =
      FoodDeliveryRiderService();

  final FoodServiceControlService _serviceControlService =
      FoodServiceControlService();

  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _fullNameController =
      TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController();
  final TextEditingController _emailController =
      TextEditingController();
  final TextEditingController _cnicController =
      TextEditingController();
  final TextEditingController _dateOfBirthController =
      TextEditingController();

  final TextEditingController _countryController =
      TextEditingController(text: 'Pakistan');
  final TextEditingController _provinceController =
      TextEditingController(
    text: 'Khyber Pakhtunkhwa',
  );
  final TextEditingController _cityController =
      TextEditingController(text: 'Swat');
  final TextEditingController _areaController =
      TextEditingController();
  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _vehicleMakeController =
      TextEditingController();
  final TextEditingController _vehicleModelController =
      TextEditingController();
  final TextEditingController _vehicleColorController =
      TextEditingController();
  final TextEditingController
      _registrationNumberController =
      TextEditingController();

  FoodDeliveryVehicleType _vehicleType =
      FoodDeliveryVehicleType.motorcycle;

  DateTime? _dateOfBirth;

  File? _riderPhoto;
  File? _cnicFrontImage;
  File? _cnicBackImage;
  File? _drivingLicenseFrontImage;
  File? _drivingLicenseBackImage;
  File? _vehicleRegistrationImage;
  File? _vehiclePhotoImage;

  bool _acceptedDeclaration = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cnicController.dispose();
    _dateOfBirthController.dispose();
    _countryController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleColorController.dispose();
    _registrationNumberController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  String? _required(
    String? value,
    String field,
  ) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $field';
    }

    return null;
  }

  String? _phoneValidator(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Please enter phone number';
    }

    if (text.length < 10) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    if (!text.contains('@') || !text.contains('.')) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _cnicValidator(String? value) {
    final String text = value
            ?.replaceAll('-', '')
            .replaceAll(' ', '')
            .trim() ??
        '';

    if (text.isEmpty) {
      return 'Please enter CNIC number';
    }

    if (text.length != 13 ||
        int.tryParse(text) == null) {
      return 'Enter a valid 13-digit CNIC';
    }

    return null;
  }

  String? _dateOfBirthValidator(String? value) {
    final DateTime? parsed =
        _parseDateOfBirth(value);

    if (parsed == null) {
      return 'Enter date as DD/MM/YYYY';
    }

    final DateTime today = DateTime.now();
    final DateTime minimumAdultDate = DateTime(
      today.year - 18,
      today.month,
      today.day,
    );

    if (parsed.isAfter(minimumAdultDate)) {
      return 'Rider must be at least 18 years old';
    }

    if (parsed.year < 1950) {
      return 'Enter a valid date of birth';
    }

    return null;
  }

  DateTime? _parseDateOfBirth(String? value) {
    final String text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final List<String> parts =
        text.split('/');

    if (parts.length != 3) {
      return null;
    }

    final int? day = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? year = int.tryParse(parts[2]);

    if (day == null ||
        month == null ||
        year == null) {
      return null;
    }

    try {
      final DateTime date =
          DateTime(year, month, day);

      if (date.day != day ||
          date.month != month ||
          date.year != year) {
        return null;
      }

      return date;
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime now = DateTime.now();

    final DateTime initialDate =
        _dateOfBirth ??
            DateTime(
              now.year - 20,
              now.month,
              now.day,
            );

    final DateTime? selected =
        await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime(
        now.year - 18,
        now.month,
        now.day,
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _dateOfBirth = selected;
      _dateOfBirthController.text =
          _dateText(selected);
    });
  }

  void _showImageSourceDialog({
    required String title,
    required ValueChanged<File> onSelected,
  }) {
    if (_isSubmitting) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardColor,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: yellow,
                ),
                title: const Text(
                  'Take photo with camera',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(
                    source: ImageSource.camera,
                    onSelected: onSelected,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: yellow,
                ),
                title: const Text(
                  'Choose from gallery',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickImage(
                    source: ImageSource.gallery,
                    onSelected: onSelected,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage({
    required ImageSource source,
    required ValueChanged<File> onSelected,
  }) async {
    try {
      final XFile? pickedFile =
          await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null || !mounted) {
        return;
      }

      setState(() {
        onSelected(File(pickedFile.path));
      });
    } catch (error) {
      _showMessage(
        'Unable to select image: $error',
      );
    }
  }

  bool _validateDocuments() {
    if (_riderPhoto == null) {
      _showMessage('Rider photo is required.');
      return false;
    }

    if (_cnicFrontImage == null ||
        _cnicBackImage == null) {
      _showMessage(
        'CNIC front and back images are required.',
      );
      return false;
    }

    if (_drivingLicenseFrontImage == null ||
        _drivingLicenseBackImage == null) {
      _showMessage(
        'Driving license front and back images are required.',
      );
      return false;
    }

    if (_vehicleRegistrationImage == null) {
      _showMessage(
        'Vehicle registration image is required.',
      );
      return false;
    }

    if (_vehiclePhotoImage == null) {
      _showMessage(
        'Vehicle photo is required.',
      );
      return false;
    }

    if (!_acceptedDeclaration) {
      _showMessage(
        'Please accept the application declaration.',
      );
      return false;
    }

    return true;
  }

  Future<void> _submitApplication() async {
    if (_isSubmitting) {
      return;
    }

    final bool formValid =
        _formKey.currentState?.validate() ?? false;

    if (!formValid || !_validateDocuments()) {
      return;
    }

    _dateOfBirth = _parseDateOfBirth(
      _dateOfBirthController.text,
    );

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in before submitting the rider application.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _serviceControlService
          .assertRiderApplicationsEnabled();

      final DateTime now = DateTime.now();

      // =======================================================
      // FIREBASE STORAGE REAL UPLOAD - ENABLE AFTER BILLING
      // =======================================================
      //
      // final String riderPhotoUrl =
      //     await _uploadToFirebaseStorage(_riderPhoto!);
      // final String cnicFrontUrl =
      //     await _uploadToFirebaseStorage(_cnicFrontImage!);
      // final String cnicBackUrl =
      //     await _uploadToFirebaseStorage(_cnicBackImage!);
      // final String licenseFrontUrl =
      //     await _uploadToFirebaseStorage(
      //       _drivingLicenseFrontImage!,
      //     );
      // final String licenseBackUrl =
      //     await _uploadToFirebaseStorage(
      //       _drivingLicenseBackImage!,
      //     );
      // final String vehicleRegistrationUrl =
      //     await _uploadToFirebaseStorage(
      //       _vehicleRegistrationImage!,
      //     );
      // final String vehiclePhotoUrl =
      //     await _uploadToFirebaseStorage(
      //       _vehiclePhotoImage!,
      //     );
      //
      // Temporary bypass below stores local paths.

      final FoodDeliveryRiderModel rider =
          FoodDeliveryRiderModel(
        riderId: '',
        userId: user.uid,
        fullName:
            _fullNameController.text.trim(),
        phoneNumber:
            _phoneController.text.trim(),
        email: _emailController.text.trim(),
        cnicNumber:
            _cnicController.text.trim(),
        dateOfBirth: _dateOfBirth,
        country:
            _countryController.text.trim(),
        province:
            _provinceController.text.trim(),
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        completeAddress:
            _addressController.text.trim(),
        vehicleType: _vehicleType,
        vehicleMake:
            _vehicleMakeController.text.trim(),
        vehicleModel:
            _vehicleModelController.text.trim(),
        vehicleColor:
            _vehicleColorController.text.trim(),
        registrationNumber:
            _registrationNumberController.text.trim(),
        profileImageUrl: '',
        profileLocalImagePath:
            _riderPhoto!.path,
        cnicFrontUrl: '',
        cnicFrontLocalPath:
            _cnicFrontImage!.path,
        cnicBackUrl: '',
        cnicBackLocalPath:
            _cnicBackImage!.path,
        drivingLicenseFrontUrl: '',
        drivingLicenseFrontLocalPath:
            _drivingLicenseFrontImage!.path,
        drivingLicenseBackUrl: '',
        drivingLicenseBackLocalPath:
            _drivingLicenseBackImage!.path,
        vehicleRegistrationUrl: '',
        vehicleRegistrationLocalPath:
            _vehicleRegistrationImage!.path,
        vehiclePhotoUrl: '',
        vehiclePhotoLocalPath:
            _vehiclePhotoImage!.path,
        status:
            FoodDeliveryRiderStatus.pending,
        isApproved: false,
        isRejected: false,
        isSuspended: false,
        isActive: false,
        rejectionReason: '',
        suspensionReason: '',
        approvedAt: null,
        isOnline: false,
        isAvailable: false,
        isOnDelivery: false,
        currentOrderId: '',
        currentLatitude: 0,
        currentLongitude: 0,
        currentHeading: 0,
        currentSpeed: 0,
        lastLocationUpdate: null,
        commissionPercentage: 0,
        walletBalance: 0,
        outstandingCommission: 0,
        totalCommissionPaid: 0,
        totalEarnings: 0,
        rating: 0,
        totalRatings: 0,
        totalDeliveries: 0,
        completedDeliveries: 0,
        cancelledDeliveries: 0,
        rejectedRequests: 0,
        createdAt: now,
        updatedAt: now,
      );

      final String riderId =
          await _riderService.submitApplication(
        rider,
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (
          BuildContext dialogContext,
        ) {
          return AlertDialog(
            backgroundColor: cardColor,
            title: const Row(
              children: <Widget>[
                Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Application Submitted',
                  ),
                ),
              ],
            ),
            content: Text(
              'Your Food Delivery Rider application has been submitted successfully.\n\n'
              'Rider Application ID:\n$riderId\n\n'
              'You will receive an update after admin review.',
              style: const TextStyle(
                color: Colors.grey,
                height: 1.45,
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute<void>(
                      builder: (
                        BuildContext context,
                      ) =>
                          const FoodDeliveryRiderStatusScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: yellow,
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'View Application Status',
                ),
              ),
            ],
          );
        },
      );
    } on FoodServiceControlException catch (error) {
      _showMessage(error.message);
    } on FoodDeliveryRiderServiceException
        catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(
        'Unable to submit rider application: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Food Delivery Rider',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              30,
            ),
            children: <Widget>[
              _buildHeader(),
              const SizedBox(height: 16),
              _buildPersonalInformation(),
              const SizedBox(height: 16),
              _buildAddressSection(),
              const SizedBox(height: 16),
              _buildVehicleSection(),
              const SizedBox(height: 16),
              _buildDocumentsSection(),
              const SizedBox(height: 16),
              _buildDeclaration(),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Rider Application',
                          style: TextStyle(
                            fontSize: 16,
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: yellow,
        borderRadius: BorderRadius.circular(21),
      ),
      child: const Row(
        children: <Widget>[
          Icon(
            Icons.delivery_dining,
            color: Colors.black,
            size: 52,
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Deliver Food with SWAT RIDE',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Submit your rider details and wait for admin approval.',
                  style: TextStyle(
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return _sectionCard(
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: <Widget>[
        _field(
          controller: _fullNameController,
          label: 'Full name',
          hint: 'Enter your full name',
          icon: Icons.person_outline,
          validator: (String? value) =>
              _required(value, 'full name'),
        ),
        const SizedBox(height: 14),
        _field(
          controller: _phoneController,
          label: 'Phone number',
          hint: '03XXXXXXXXX',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: _phoneValidator,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _emailController,
          label: 'Email',
          hint: 'Optional email address',
          icon: Icons.email_outlined,
          keyboardType:
              TextInputType.emailAddress,
          validator: _emailValidator,
        ),
        const SizedBox(height: 14),
        _field(
          controller: _cnicController,
          label: 'CNIC number',
          hint: '13-digit CNIC',
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          validator: _cnicValidator,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _dateOfBirthController,
          keyboardType: TextInputType.datetime,
          validator: _dateOfBirthValidator,
          autovalidateMode:
              AutovalidateMode.onUserInteraction,
          decoration: _inputDecoration(
            label: 'Date of birth',
            hint: 'DD/MM/YYYY',
            icon: Icons.cake_outlined,
          ).copyWith(
            suffixIcon: IconButton(
              onPressed: _selectDateOfBirth,
              icon: const Icon(
                Icons.calendar_month_outlined,
                color: yellow,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return _sectionCard(
      title: 'Address',
      icon: Icons.location_on_outlined,
      children: <Widget>[
        _field(
          controller: _countryController,
          label: 'Country',
          hint: 'Pakistan',
          icon: Icons.public,
          validator: (String? value) =>
              _required(value, 'country'),
        ),
        const SizedBox(height: 14),
        _field(
          controller: _provinceController,
          label: 'Province',
          hint: 'Khyber Pakhtunkhwa',
          icon: Icons.map_outlined,
          validator: (String? value) =>
              _required(value, 'province'),
        ),
        const SizedBox(height: 14),
        _field(
          controller: _cityController,
          label: 'City',
          hint: 'Swat',
          icon: Icons.location_city,
          validator: (String? value) =>
              _required(value, 'city'),
        ),
        const SizedBox(height: 14),
        _field(
          controller: _areaController,
          label: 'Area',
          hint: 'Mingora, Saidu Sharif',
          icon: Icons.place_outlined,
          validator: (String? value) =>
              _required(value, 'area'),
        ),
        const SizedBox(height: 14),
        _field(
          controller: _addressController,
          label: 'Complete address',
          hint: 'Street, house and landmark',
          icon: Icons.home_outlined,
          minLines: 2,
          maxLines: 4,
          validator: (String? value) =>
              _required(
            value,
            'complete address',
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSection() {
    return _sectionCard(
      title: 'Delivery Vehicle',
      icon: Icons.two_wheeler,
      children: <Widget>[
        DropdownButtonFormField<
            FoodDeliveryVehicleType>(
          initialValue: _vehicleType,
          dropdownColor: fieldColor,
          decoration: _inputDecoration(
            label: 'Vehicle type',
            hint: 'Select vehicle',
            icon: Icons.delivery_dining,
          ),
          items: FoodDeliveryVehicleType.values
              .map(
                (
                  FoodDeliveryVehicleType type,
                ) =>
                    DropdownMenuItem<
                        FoodDeliveryVehicleType>(
                  value: type,
                  child: Text(type.displayName),
                ),
              )
              .toList(),
          onChanged: _isSubmitting
              ? null
              : (
                  FoodDeliveryVehicleType? value,
                ) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _vehicleType = value;
                  });
                },
        ),
        const SizedBox(height: 14),
        _field(
          controller: _vehicleMakeController,
          label: 'Vehicle company',
          hint: 'Honda, Suzuki',
          icon: Icons.factory_outlined,
          validator: (String? value) =>
              _required(
            value,
            'vehicle company',
          ),
        ),
        const SizedBox(height: 14),
        _field(
          controller: _vehicleModelController,
          label: 'Vehicle model',
          hint: 'CD 70, Rickshaw, Alto',
          icon: Icons.model_training,
          validator: (String? value) =>
              _required(
            value,
            'vehicle model',
          ),
        ),
        const SizedBox(height: 14),
        _field(
          controller: _vehicleColorController,
          label: 'Vehicle color',
          hint: 'Black',
          icon: Icons.palette_outlined,
          validator: (String? value) =>
              _required(
            value,
            'vehicle color',
          ),
        ),
        const SizedBox(height: 14),
        _field(
          controller:
              _registrationNumberController,
          label: 'Registration number',
          hint: 'Vehicle plate number',
          icon:
              Icons.confirmation_number_outlined,
          validator: (String? value) =>
              _required(
            value,
            'registration number',
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return _sectionCard(
      title: 'Required Documents & Photos',
      icon: Icons.folder_copy_outlined,
      children: <Widget>[
        _documentCard(
          title: 'Rider Photo',
          icon: Icons.person_outline,
          image: _riderPhoto,
          onPick: () => _showImageSourceDialog(
            title: 'Rider Photo',
            onSelected: (File file) {
              _riderPhoto = file;
            },
          ),
          onRemove: () {
            setState(() {
              _riderPhoto = null;
            });
          },
        ),
        const SizedBox(height: 12),
        _documentCard(
          title: 'CNIC Front',
          icon: Icons.badge_outlined,
          image: _cnicFrontImage,
          onPick: () => _showImageSourceDialog(
            title: 'CNIC Front',
            onSelected: (File file) {
              _cnicFrontImage = file;
            },
          ),
          onRemove: () {
            setState(() {
              _cnicFrontImage = null;
            });
          },
        ),
        const SizedBox(height: 12),
        _documentCard(
          title: 'CNIC Back',
          icon: Icons.badge_outlined,
          image: _cnicBackImage,
          onPick: () => _showImageSourceDialog(
            title: 'CNIC Back',
            onSelected: (File file) {
              _cnicBackImage = file;
            },
          ),
          onRemove: () {
            setState(() {
              _cnicBackImage = null;
            });
          },
        ),
        const SizedBox(height: 12),
        _documentCard(
          title: 'Driving License Front',
          icon: Icons.drive_eta_outlined,
          image: _drivingLicenseFrontImage,
          onPick: () => _showImageSourceDialog(
            title: 'Driving License Front',
            onSelected: (File file) {
              _drivingLicenseFrontImage = file;
            },
          ),
          onRemove: () {
            setState(() {
              _drivingLicenseFrontImage = null;
            });
          },
        ),
        const SizedBox(height: 12),
        _documentCard(
          title: 'Driving License Back',
          icon: Icons.drive_eta_outlined,
          image: _drivingLicenseBackImage,
          onPick: () => _showImageSourceDialog(
            title: 'Driving License Back',
            onSelected: (File file) {
              _drivingLicenseBackImage = file;
            },
          ),
          onRemove: () {
            setState(() {
              _drivingLicenseBackImage = null;
            });
          },
        ),
        const SizedBox(height: 12),
        _documentCard(
          title: 'Vehicle Registration',
          icon: Icons.description_outlined,
          image: _vehicleRegistrationImage,
          onPick: () => _showImageSourceDialog(
            title: 'Vehicle Registration',
            onSelected: (File file) {
              _vehicleRegistrationImage = file;
            },
          ),
          onRemove: () {
            setState(() {
              _vehicleRegistrationImage = null;
            });
          },
        ),
        const SizedBox(height: 12),
        _documentCard(
          title: 'Vehicle Photo',
          icon: Icons.directions_car_outlined,
          image: _vehiclePhotoImage,
          onPick: () => _showImageSourceDialog(
            title: 'Vehicle Photo',
            onSelected: (File file) {
              _vehiclePhotoImage = file;
            },
          ),
          onRemove: () {
            setState(() {
              _vehiclePhotoImage = null;
            });
          },
        ),
        const SizedBox(height: 14),
        const Text(
          'Firebase Storage upload is temporarily bypassed. '
          'Selected local image paths are saved until billing is enabled.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _documentCard({
    required String title,
    required IconData icon,
    required File? image,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: image == null
              ? Colors.white10
              : Colors.greenAccent.withValues(
                  alpha: 0.6,
                ),
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor:
                    yellow.withValues(alpha: 0.12),
                child: Icon(
                  icon,
                  color: yellow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$title *',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (image != null)
                IconButton(
                  onPressed:
                      _isSubmitting ? null : onRemove,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
            ],
          ),
          if (image != null) ...<Widget>[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                image,
                width: double.infinity,
                height: 170,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  _isSubmitting ? null : onPick,
              icon: Icon(
                image == null
                    ? Icons.upload_file_outlined
                    : Icons.change_circle_outlined,
              ),
              label: Text(
                image == null
                    ? 'Add $title'
                    : 'Change $title',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: yellow,
                side: const BorderSide(
                  color: yellow,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclaration() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: CheckboxListTile(
        value: _acceptedDeclaration,
        onChanged: _isSubmitting
            ? null
            : (bool? value) {
                setState(() {
                  _acceptedDeclaration =
                      value ?? false;
                });
              },
        activeColor: yellow,
        controlAffinity:
            ListTileControlAffinity.leading,
        title: const Text(
          'Application declaration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'I confirm that my information and documents are correct and can be reviewed by the SWAT RIDE admin.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
          Row(
            children: <Widget>[
              Icon(
                icon,
                color: yellow,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
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
    TextInputType keyboardType =
        TextInputType.text,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      enabled: !_isSubmitting,
      validator: validator,
      autovalidateMode:
          AutovalidateMode.onUserInteraction,
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: yellow,
      ),
      filled: true,
      fillColor: fieldColor,
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
    );
  }

  String _dateText(DateTime date) {
    final String day =
        date.day.toString().padLeft(2, '0');
    final String month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

