import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../driver/screens/driver_application_status_screen.dart';
import '../services/driver_registration_service.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  // =========================================================
  // FORM
  // =========================================================

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController nameController = TextEditingController();

  final TextEditingController phoneController = TextEditingController();

  final TextEditingController cnicController = TextEditingController();

  final TextEditingController vehicleNumberController = TextEditingController();

  final TextEditingController chassisNumberController = TextEditingController();

  final TextEditingController authorizedDriverIdController = TextEditingController();

  final TextEditingController addressController = TextEditingController();

  // =========================================================
  // FIREBASE
  // =========================================================

  final FirebaseStorage _storage = FirebaseStorage.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final DriverRegistrationService _registrationService =
      DriverRegistrationService();

  // TESTING BYPASS:
  // Keep this false while Firebase Storage billing/setup is paused.
  // Change to true when Storage is enabled; the real upload code below
  // will then run without needing to replace this screen.
  static const bool _useFirebaseStorage = false;

  // =========================================================
  // IMAGE PICKER
  // =========================================================

  final ImagePicker _imagePicker = ImagePicker();

  // =========================================================
  // LOCAL IMAGES
  // =========================================================

  File? cnicFrontImage;
  File? cnicBackImage;

  File? drivingLicenseFrontImage;
  File? drivingLicenseBackImage;

  File? vehicleRegistrationImage;

  File? vehiclePhotoImage;

  File? driverPhotoImage;

  // =========================================================
  // VEHICLE TYPE
  // =========================================================

  String selectedVehicle = 'bike';

  bool _ownerWillDrive = true;

  final List<Map<String, String>> vehicleTypes = [
    {'id': 'bike', 'name': 'Bike'},
    {'id': 'rickshaw', 'name': 'Rickshaw'},
    {'id': 'mehran', 'name': 'Suzuki Mehran'},
    {'id': 'alto', 'name': 'Suzuki Alto'},
    {'id': 'cultus', 'name': 'Suzuki Cultus'},
    {'id': 'wagon_r', 'name': 'Suzuki Wagon R'},
    {'id': 'aqua', 'name': 'Toyota Aqua'},
    {'id': 'vitz', 'name': 'Toyota Vitz'},
    {'id': 'corolla', 'name': 'Toyota Corolla'},
    {'id': 'city', 'name': 'Honda City'},
    {'id': 'corolla_fielder', 'name': 'Corolla Fielder'},
    {'id': 'prius', 'name': 'Toyota Prius'},
    {'id': 'vitara', 'name': 'Suzuki Vitara'},
    {'id': 'fortuner', 'name': 'Toyota Fortuner'},
    {'id': 'land_cruiser', 'name': 'Toyota Land Cruiser'},
    {'id': 'prado', 'name': 'Toyota Prado'},
    {'id': 'hiace', 'name': 'Toyota Hiace'},
    {'id': 'other_vehicle', 'name': 'Other Vehicle (Admin mapping required)'},
  ];

  // =========================================================
  // SUBMIT STATE
  // =========================================================

  bool _isSubmitting = false;

  double _uploadProgress = 0.0;

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    cnicController.dispose();
    vehicleNumberController.dispose();
    chassisNumberController.dispose();
    authorizedDriverIdController.dispose();
    addressController.dispose();

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earn as Driver'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =====================================================
                // TITLE
                // =====================================================
                const Text(
                  'Become a SWAT RIDE Driver',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  'Register your vehicle and start earning with SWAT RIDE.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),

                const SizedBox(height: 25),

                // =====================================================
                // FULL NAME
                // =====================================================
                _buildTextField(
                  controller: nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                ),

                const SizedBox(height: 16),

                // =====================================================
                // PHONE
                // =====================================================
                _buildTextField(
                  controller: phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 16),

                // =====================================================
                // CNIC
                // =====================================================
                _buildTextField(
                  controller: cnicController,
                  label: 'CNIC Number',
                  icon: Icons.badge,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // =====================================================
                // VEHICLE TYPE
                // =====================================================
                DropdownButtonFormField<String>(
                  initialValue: selectedVehicle,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Type',
                    prefixIcon: Icon(Icons.directions_car),
                    border: OutlineInputBorder(),
                  ),
                  items: vehicleTypes.map((vehicle) {
                    return DropdownMenuItem<String>(
                      value: vehicle['id'],
                      child: Text(vehicle['name']!),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              selectedVehicle = value;
                            });
                          }
                        },
                ),

                const SizedBox(height: 16),

                // =====================================================
                // VEHICLE NUMBER
                // =====================================================
                _buildTextField(
                  controller: vehicleNumberController,
                  label: 'Vehicle Number',
                  icon: Icons.confirmation_number,
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  controller: chassisNumberController,
                  label: 'Chassis Number',
                  icon: Icons.numbers,
                ),

                const SizedBox(height: 16),

                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('I am the authorized driver'),
                  subtitle: const Text(
                    'Turn off when the vehicle owner authorizes another driver.',
                  ),
                  value: _ownerWillDrive,
                  onChanged: _isSubmitting
                      ? null
                      : (bool value) => setState(() => _ownerWillDrive = value),
                ),

                if (!_ownerWillDrive) ...[
                  _buildTextField(
                    controller: authorizedDriverIdController,
                    label: 'Authorized Driver User ID',
                    icon: Icons.person_pin_circle_outlined,
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),

                // =====================================================
                // ADDRESS
                // =====================================================
                _buildTextField(
                  controller: addressController,
                  label: 'Address',
                  icon: Icons.location_on,
                  maxLines: 3,
                ),

                const SizedBox(height: 30),

                // =====================================================
                // DOCUMENT TITLE
                // =====================================================
                const Text(
                  'Required Documents & Photos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(
                  'Upload clear photos of all required documents.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),

                const SizedBox(height: 15),

                // =====================================================
                // CNIC FRONT
                // =====================================================
                _documentCard(
                  icon: Icons.badge,
                  title: 'CNIC Front Side',
                  image: cnicFrontImage,
                  onUpload: () {
                    _showImageSourceDialog(documentType: 'CNIC Front Side');
                  },
                  onRemove: () {
                    setState(() {
                      cnicFrontImage = null;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // =====================================================
                // CNIC BACK
                // =====================================================
                _documentCard(
                  icon: Icons.badge,
                  title: 'CNIC Back Side',
                  image: cnicBackImage,
                  onUpload: () {
                    _showImageSourceDialog(documentType: 'CNIC Back Side');
                  },
                  onRemove: () {
                    setState(() {
                      cnicBackImage = null;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // =====================================================
                // LICENSE FRONT
                // =====================================================
                _documentCard(
                  icon: Icons.drive_eta,
                  title: 'Driving License Front Side',
                  image: drivingLicenseFrontImage,
                  onUpload: () {
                    _showImageSourceDialog(
                      documentType: 'Driving License Front Side',
                    );
                  },
                  onRemove: () {
                    setState(() {
                      drivingLicenseFrontImage = null;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // =====================================================
                // LICENSE BACK
                // =====================================================
                _documentCard(
                  icon: Icons.drive_eta,
                  title: 'Driving License Back Side',
                  image: drivingLicenseBackImage,
                  onUpload: () {
                    _showImageSourceDialog(
                      documentType: 'Driving License Back Side',
                    );
                  },
                  onRemove: () {
                    setState(() {
                      drivingLicenseBackImage = null;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // =====================================================
                // VEHICLE REGISTRATION
                // =====================================================
                _documentCard(
                  icon: Icons.directions_car,
                  title: 'Vehicle Registration',
                  image: vehicleRegistrationImage,
                  onUpload: () {
                    _showImageSourceDialog(
                      documentType: 'Vehicle Registration',
                    );
                  },
                  onRemove: () {
                    setState(() {
                      vehicleRegistrationImage = null;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // =====================================================
                // VEHICLE PHOTO
                // =====================================================
                _documentCard(
                  icon: Icons.camera_alt,
                  title: 'Vehicle Photo',
                  image: vehiclePhotoImage,
                  onUpload: () {
                    _showImageSourceDialog(documentType: 'Vehicle Photo');
                  },
                  onRemove: () {
                    setState(() {
                      vehiclePhotoImage = null;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // =====================================================
                // DRIVER PHOTO
                // =====================================================
                _documentCard(
                  icon: Icons.person,
                  title: 'Driver Photo',
                  image: driverPhotoImage,
                  onUpload: () {
                    _showImageSourceDialog(documentType: 'Driver Photo');
                  },
                  onRemove: () {
                    setState(() {
                      driverPhotoImage = null;
                    });
                  },
                ),

                const SizedBox(height: 30),

                // =====================================================
                // UPLOAD PROGRESS
                // =====================================================
                if (_isSubmitting) ...[
                  const Text(
                    'Uploading application...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  LinearProgressIndicator(value: _uploadProgress),

                  const SizedBox(height: 8),

                  Text('${(_uploadProgress * 100).toStringAsFixed(0)}%'),

                  const SizedBox(height: 20),
                ],

                // =====================================================
                // SUBMIT BUTTON
                // =====================================================
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD60A),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Submit Driver Application',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // TEXT FIELD
  // =========================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: !_isSubmitting,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  // =========================================================
  // DOCUMENT CARD
  // =========================================================

  Widget _documentCard({
    required IconData icon,
    required String title,
    required File? image,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
  }) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFFFD60A)),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                if (image != null)
                  IconButton(
                    onPressed: _isSubmitting ? null : onRemove,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  image,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),

            if (image != null) const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : onUpload,
                icon: Icon(
                  image == null ? Icons.upload_file : Icons.change_circle,
                ),
                label: Text(image == null ? 'Upload $title' : 'Change $title'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // IMAGE SOURCE DIALOG
  // =========================================================

  void _showImageSourceDialog({required String documentType}) {
    if (_isSubmitting) {
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo with Camera'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);

                  _pickImage(
                    source: ImageSource.camera,
                    documentType: documentType,
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);

                  _pickImage(
                    source: ImageSource.gallery,
                    documentType: documentType,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // PICK IMAGE
  // =========================================================

  Future<void> _pickImage({
    required ImageSource source,
    required String documentType,
  }) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (pickedFile == null) {
        return;
      }

      final File selectedImage = File(pickedFile.path);

      if (!mounted) {
        return;
      }

      setState(() {
        if (documentType == 'CNIC Front Side') {
          cnicFrontImage = selectedImage;
        } else if (documentType == 'CNIC Back Side') {
          cnicBackImage = selectedImage;
        } else if (documentType == 'Driving License Front Side') {
          drivingLicenseFrontImage = selectedImage;
        } else if (documentType == 'Driving License Back Side') {
          drivingLicenseBackImage = selectedImage;
        } else if (documentType == 'Vehicle Registration') {
          vehicleRegistrationImage = selectedImage;
        } else if (documentType == 'Vehicle Photo') {
          vehiclePhotoImage = selectedImage;
        } else if (documentType == 'Driver Photo') {
          driverPhotoImage = selectedImage;
        }
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError('Unable to select image: $e');
    }
  }

  // =========================================================
  // REQUIRED DOCUMENT VALIDATION
  // =========================================================

  bool _validateDocuments() {
    if (cnicFrontImage == null ||
        cnicBackImage == null ||
        drivingLicenseFrontImage == null ||
        drivingLicenseBackImage == null ||
        vehicleRegistrationImage == null ||
        vehiclePhotoImage == null ||
        driverPhotoImage == null) {
      _showError('Please upload all required documents and photos.');

      return false;
    }

    return true;
  }

  // =========================================================
  // UPLOAD IMAGE TO FIREBASE STORAGE
  // =========================================================

  Future<String> _uploadImage({
    required File file,
    required String applicationId,
    required String fileName,
  }) async {
    if (!_useFirebaseStorage) {
      // Safe non-public reference for testing. The local device path is not
      // written to Firestore and no Firebase Storage request is made.
      return 'testing://driver_applications'
          '/$applicationId'
          '/$fileName.jpg';
    }

    // REAL FIREBASE STORAGE CODE (kept ready for billing activation).

    final Reference storageReference = _storage.ref().child(
      'driver_applications'
      '/$applicationId'
      '/$fileName.jpg',
    );

    final UploadTask uploadTask = storageReference.putFile(file);

    final TaskSnapshot snapshot = await uploadTask;

    return await snapshot.ref.getDownloadURL();
  }

  // =========================================================
  // SUBMIT APPLICATION
  // =========================================================

  Future<void> _submitApplication() async {
    // Duplicate submit protection
    if (_isSubmitting) {
      return;
    }

    // Form validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Documents validation
    if (!_validateDocuments()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });

    try {
      final User? applicant = FirebaseAuth.instance.currentUser;
      if (applicant == null) {
        throw Exception('Please login before submitting a driver application.');
      }

      final String authorizedDriverId = _ownerWillDrive
          ? applicant.uid
          : authorizedDriverIdController.text.trim();
      if (authorizedDriverId.isEmpty) {
        throw Exception('Enter the authorized driver user ID.');
      }

      await _registrationService.ensureVehicleIdentityAvailable(
        vehicleOwnerId: applicant.uid,
        vehicleNumber: vehicleNumberController.text,
        chassisNumber: chassisNumberController.text,
        cnicNumber: cnicController.text,
      );

      // =======================================================
      // UNIQUE APPLICATION ID
      // =======================================================

      final DocumentReference applicationReference = _firestore
          .collection('driver_applications')
          .doc();

      final String applicationId = applicationReference.id;

      // =======================================================
      // UPLOAD CNIC FRONT
      // =======================================================

      setState(() {
        _uploadProgress = 0.05;
      });

      final String cnicFrontUrl = await _uploadImage(
        file: cnicFrontImage!,
        applicationId: applicationId,
        fileName: 'cnic_front',
      );

      // =======================================================
      // UPLOAD CNIC BACK
      // =======================================================

      setState(() {
        _uploadProgress = 0.15;
      });

      final String cnicBackUrl = await _uploadImage(
        file: cnicBackImage!,
        applicationId: applicationId,
        fileName: 'cnic_back',
      );

      // =======================================================
      // UPLOAD LICENSE FRONT
      // =======================================================

      setState(() {
        _uploadProgress = 0.25;
      });

      final String licenseFrontUrl = await _uploadImage(
        file: drivingLicenseFrontImage!,
        applicationId: applicationId,
        fileName: 'driving_license_front',
      );

      // =======================================================
      // UPLOAD LICENSE BACK
      // =======================================================

      setState(() {
        _uploadProgress = 0.35;
      });

      final String licenseBackUrl = await _uploadImage(
        file: drivingLicenseBackImage!,
        applicationId: applicationId,
        fileName: 'driving_license_back',
      );

      // =======================================================
      // VEHICLE REGISTRATION
      // =======================================================

      setState(() {
        _uploadProgress = 0.50;
      });

      final String vehicleRegistrationUrl = await _uploadImage(
        file: vehicleRegistrationImage!,
        applicationId: applicationId,
        fileName: 'vehicle_registration',
      );

      // =======================================================
      // VEHICLE PHOTO
      // =======================================================

      setState(() {
        _uploadProgress = 0.65;
      });

      final String vehiclePhotoUrl = await _uploadImage(
        file: vehiclePhotoImage!,
        applicationId: applicationId,
        fileName: 'vehicle_photo',
      );

      // =======================================================
      // DRIVER PHOTO
      // =======================================================

      setState(() {
        _uploadProgress = 0.80;
      });

      final String driverPhotoUrl = await _uploadImage(
        file: driverPhotoImage!,
        applicationId: applicationId,
        fileName: 'driver_photo',
      );

      // =======================================================
      // SAVE COMPLETE APPLICATION
      // FIRESTORE
      // =======================================================

      setState(() {
        _uploadProgress = 0.90;
      });

      await applicationReference.set({
        'applicationId': applicationId,

        'applicationType': 'driver_registration',

        // Firebase Auth UID permanently links the application to the
        // driver account created after real Admin/testing approval.
        'userId': applicant.uid,

        'vehicleOwnerId': applicant.uid,

        'authorizedDriverId': authorizedDriverId,

        'driverId': null,

        'name': nameController.text.trim(),

        'fullName': nameController.text.trim(),

        'phone': phoneController.text.trim(),

        'phoneNumber': phoneController.text.trim(),

        'cnic': cnicController.text.trim(),

        'cnicNumber': cnicController.text.trim(),

        'vehicleType': selectedVehicle,

        'vehicleNumber': vehicleNumberController.text.trim(),

        'vehicleNumberNormalized': DriverRegistrationService.normalizeVehicleIdentity(
          vehicleNumberController.text,
        ),

        'chassisNumber': chassisNumberController.text.trim(),

        'chassisNumberNormalized': DriverRegistrationService.normalizeVehicleIdentity(
          chassisNumberController.text,
        ),

        'cnicNumberNormalized': DriverRegistrationService.normalizeVehicleIdentity(
          cnicController.text,
        ),

        'address': addressController.text.trim(),

        // =====================================================
        // DOCUMENT URLS
        // =====================================================
        'documents': {
          'cnicFront': cnicFrontUrl,

          'cnicBack': cnicBackUrl,

          'drivingLicenseFront': licenseFrontUrl,

          'drivingLicenseBack': licenseBackUrl,

          'vehicleRegistration': vehicleRegistrationUrl,

          'vehiclePhoto': vehiclePhotoUrl,

          'driverPhoto': driverPhotoUrl,
        },

        // =====================================================
        // APPLICATION STATUS
        // =====================================================
        'status': 'pending',

        'reviewTimeline': <String, dynamic>{
          'vehicleStatus': 'pending',
          'documentsStatus': 'pending',
          'primaryImageStatus': 'pending',
          'submittedAt': FieldValue.serverTimestamp(),
          'estimatedReviewWindowHours': 48,
        },

        'photoReview': <String, dynamic>{
          'primaryImageKey': 'driverPhoto',
          'primaryImageStatus': 'pending',
          'reviewedBy': null,
          'reviewedAt': null,
        },

        'storageUploadMode': _useFirebaseStorage
            ? 'firebase_storage'
            : 'testing_bypass',

        'createdAt': FieldValue.serverTimestamp(),

        'updatedAt': FieldValue.serverTimestamp(),

        // Future Admin Panel
        'adminReviewed': false,

        'adminReview': {
          'reviewed': false,
          'reviewedBy': null,
          'reviewedAt': null,
          'rejectionReason': null,
        },

        'driverAccount': {
          'created': false,
          'driverId': null,
          'approvedAt': null,
        },

        'rejectionReason': null,

        'approvedAt': null,

        'rejectedAt': null,
      });

      setState(() {
        _uploadProgress = 1.0;
      });

      if (!mounted) {
        return;
      }

      // =======================================================
      // SUCCESS
      // =======================================================

      await _showSuccessDialog(applicationId);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError('Driver application failed. Please try again.\n$e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // =========================================================
  // SUCCESS DIALOG
  // =========================================================

  Future<void> _showSuccessDialog(String applicationId) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Application Submitted'),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),

              const SizedBox(height: 15),

              const Text(
                'Your driver application has been submitted successfully.',
              ),

              const SizedBox(height: 15),

              const Text(
                'Application ID:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 5),

              SelectableText(applicationId),

              const SizedBox(height: 15),

              const Text(
                'Status: Pending',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                _clearForm();

                if (!mounted) {
                  return;
                }

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverApplicationStatusScreen(
                      applicationId: applicationId,
                    ),
                  ),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // CLEAR FORM AFTER SUCCESS
  // =========================================================

  void _clearForm() {
    nameController.clear();
    phoneController.clear();
    cnicController.clear();
    vehicleNumberController.clear();
    chassisNumberController.clear();
    authorizedDriverIdController.clear();
    addressController.clear();

    setState(() {
      selectedVehicle = 'bike';
      _ownerWillDrive = true;

      cnicFrontImage = null;

      cnicBackImage = null;

      drivingLicenseFrontImage = null;

      drivingLicenseBackImage = null;

      vehicleRegistrationImage = null;

      vehiclePhotoImage = null;

      driverPhotoImage = null;

      _uploadProgress = 0.0;
    });
  }

  // =========================================================
  // ERROR MESSAGE
  // =========================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(message)),
    );
  }
}
