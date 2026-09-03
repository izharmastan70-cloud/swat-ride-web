import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/tour_guide_application.dart';
import '../services/tour_guide_application_service.dart';

class TourGuideRegistrationScreen
    extends StatefulWidget {
  const TourGuideRegistrationScreen({
    super.key,
  });

  @override
  State<TourGuideRegistrationScreen>
      createState() =>
          _TourGuideRegistrationScreenState();
}

class _TourGuideRegistrationScreenState
    extends State<TourGuideRegistrationScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground =
      Color(0xFF0D0D0D);

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TourGuideApplicationService _service =
      TourGuideApplicationService();

  final TextEditingController _name =
      TextEditingController();

  final TextEditingController _phone =
      TextEditingController();

  final TextEditingController _cnic =
      TextEditingController();

  final TextEditingController _email =
      TextEditingController();

  final TextEditingController _license =
      TextEditingController();

  final TextEditingController _experience =
      TextEditingController();

  final TextEditingController _dailyRate =
      TextEditingController();

  final TextEditingController _hourlyRate =
      TextEditingController();

  final TextEditingController _emergencyContactName =
      TextEditingController();

  final TextEditingController _emergencyContactPhone =
      TextEditingController();

  final TextEditingController _passportNumber =
      TextEditingController();

  final TextEditingController _firstAidCertificateNumber =
      TextEditingController();

  final TextEditingController _tourismRegistrationNumber =
      TextEditingController();

  String _applicationId = '';

  bool _firstAid = false;
  bool _multiDay = true;
  bool _familyTours = true;
  bool _groupTours = true;
  bool _airportPickup = false;
  bool _nightTours = false;
  bool _womenOnlyTours = false;
  bool _foreignTouristExperience = false;
  bool _gpsTrackingConsent = true;
  bool _policeCertificateAvailable = false;
  bool _medicalFitnessCertificateAvailable = false;
  bool _passportAvailable = false;
  bool _agree = false;
  bool _saving = false;

  DateTime? _licenseExpiryDate;
  DateTime? _tourismRegistrationExpiryDate;

  final Map<String, String> _languageLevels =
      <String, String>{};

  final List<String> _selectedLanguages =
      <String>[];

  final List<String> _selectedGuideTypes =
      <String>[];

  final List<String> _selectedDestinations =
      <String>[];

  final List<String> _selectedSkills =
      <String>[];

  final List<String> _availableLanguages =
      const <String>[
    'Pashto',
    'Urdu',
    'English',
    'Punjabi',
  ];

  final List<String> _availableGuideTypes =
      const <String>[
    'Family Guide',
    'Adventure Guide',
    'Cultural Guide',
    'Trekking Guide',
    'Photography Guide',
  ];

  final List<String> _availableDestinations =
      const <String>[
    'Mingora',
    'Fizagat',
    'Malam Jabba',
    'Bahrain',
    'Kalam',
    'Mahodand Lake',
    'Ushu Forest',
    'Matiltan',
    'Gabral Valley',
    'White Palace Marghazar',
  ];

  final List<String> _availableSkills =
      const <String>[
    'First Aid',
    'Photography',
    'Hiking',
    'Camping',
    'Local History',
    'Local Culture',
    'Route Planning',
    'Family Assistance',
  ];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _cnic.dispose();
    _email.dispose();
    _license.dispose();
    _experience.dispose();
    _dailyRate.dispose();
    _hourlyRate.dispose();
    _emergencyContactName.dispose();
    _emergencyContactPhone.dispose();
    _passportNumber.dispose();
    _firstAidCertificateNumber.dispose();
    _tourismRegistrationNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        title: const Text(
          'Tour Guide Registration',
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

              _sectionTitle('Personal Details'),

              _field(
                controller: _name,
                label: 'Full name',
                icon: Icons.person,
                validator: _required,
              ),

              _field(
                controller: _phone,
                label: 'Phone number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: _phoneValidator,
              ),

              _field(
                controller: _cnic,
                label: 'CNIC',
                icon: Icons.badge,
                keyboardType:
                    TextInputType.number,
                validator: _cnicValidator,
              ),

              _field(
                controller: _email,
                label: 'Email (optional)',
                icon: Icons.email,
                keyboardType:
                    TextInputType.emailAddress,
                validator:
                    _optionalEmailValidator,
              ),

              _field(
                controller: _license,
                label:
                    'Guide license / certificate (optional)',
                icon: Icons.card_membership,
              ),

              _field(
                controller: _experience,
                label: 'Experience (years)',
                icon: Icons.timeline,
                keyboardType:
                    TextInputType.number,
                validator:
                    _nonNegativeIntegerValidator,
              ),
              const SizedBox(height: 12),

              _sectionTitle('Emergency Contact'),

              _field(
                controller: _emergencyContactName,
                label: 'Emergency contact name',
                icon: Icons.contact_emergency_outlined,
                validator: _required,
              ),

              _field(
                controller: _emergencyContactPhone,
                label: 'Emergency contact phone',
                icon: Icons.phone_in_talk_outlined,
                keyboardType: TextInputType.phone,
                validator: _phoneValidator,
              ),

              const SizedBox(height: 12),

              _sectionTitle('License & Registration'),

              _dateTile(
                title: 'Guide license expiry date',
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

              _field(
                controller: _tourismRegistrationNumber,
                label: 'National tourism registration number',
                icon: Icons.verified_user_outlined,
                validator: _required,
              ),

              _dateTile(
                title: 'Tourism registration expiry date',
                date: _tourismRegistrationExpiryDate,
                onTap: () => _pickDate(
                  current: _tourismRegistrationExpiryDate,
                  onSelected: (date) {
                    setState(() {
                      _tourismRegistrationExpiryDate = date;
                    });
                  },
                ),
              ),

              _switch(
                title: 'Passport available',
                value: _passportAvailable,
                onChanged: (value) {
                  setState(() {
                    _passportAvailable = value;
                  });
                },
              ),

              if (_passportAvailable)
                _field(
                  controller: _passportNumber,
                  label: 'Passport number',
                  icon: Icons.badge_outlined,
                  validator: _required,
                ),

              _switch(
                title: 'Police character certificate available',
                value: _policeCertificateAvailable,
                onChanged: (value) {
                  setState(() {
                    _policeCertificateAvailable = value;
                  });
                },
              ),

              _switch(
                title: 'Medical fitness certificate available',
                value: _medicalFitnessCertificateAvailable,
                onChanged: (value) {
                  setState(() {
                    _medicalFitnessCertificateAvailable = value;
                  });
                },
              ),

              _field(
                controller: _firstAidCertificateNumber,
                label: 'CPR / First aid certificate number (optional)',
                icon: Icons.health_and_safety_outlined,
              ),

              const SizedBox(height: 12),

              _sectionTitle('Languages'),

              _languageSelector(),

              const SizedBox(height: 22),

              _sectionTitle('Guide Types'),

              _chips(
                items: _availableGuideTypes,
                selected: _selectedGuideTypes,
              ),

              const SizedBox(height: 22),

              _sectionTitle(
                'Destinations You Cover',
              ),

              _chips(
                items: _availableDestinations,
                selected:
                    _selectedDestinations,
              ),

              const SizedBox(height: 22),

              _sectionTitle('Skills'),

              _chips(
                items: _availableSkills,
                selected: _selectedSkills,
              ),

              const SizedBox(height: 22),

              _sectionTitle('Availability'),

              _switch(
                title: 'First Aid Training',
                value: _firstAid,
                onChanged: (value) {
                  setState(() {
                    _firstAid = value;
                  });

                  if (value &&
                      !_selectedSkills.contains(
                        'First Aid',
                      )) {
                    setState(() {
                      _selectedSkills.add(
                        'First Aid',
                      );
                    });
                  }
                },
              ),

              _switch(
                title: 'Available for Multi-day Tours',
                value: _multiDay,
                onChanged: (value) {
                  setState(() {
                    _multiDay = value;
                  });
                },
              ),

              _switch(
                title: 'Available for Family Tours',
                value: _familyTours,
                onChanged: (value) {
                  setState(() {
                    _familyTours = value;
                  });
                },
              ),

              _switch(
                title: 'Available for Group Tours',
                value: _groupTours,
                onChanged: (value) {
                  setState(() {
                    _groupTours = value;
                  });
                },
              ),
              _switch(
                title: 'Airport Pickup Assistance',
                value: _airportPickup,
                onChanged: (value) {
                  setState(() {
                    _airportPickup = value;
                  });
                },
              ),

              _switch(
                title: 'Available for Night Tours',
                value: _nightTours,
                onChanged: (value) {
                  setState(() {
                    _nightTours = value;
                  });
                },
              ),

              _switch(
                title: 'Available for Women-only Tours',
                value: _womenOnlyTours,
                onChanged: (value) {
                  setState(() {
                    _womenOnlyTours = value;
                  });
                },
              ),

              _switch(
                title: 'Experience with Foreign Tourists',
                value: _foreignTouristExperience,
                onChanged: (value) {
                  setState(() {
                    _foreignTouristExperience = value;
                  });
                },
              ),

              _switch(
                title: 'GPS Tracking Consent',
                value: _gpsTrackingConsent,
                onChanged: (value) {
                  setState(() {
                    _gpsTrackingConsent = value;
                  });
                },
              ),

              const SizedBox(height: 22),

              _sectionTitle('Pricing'),

              _field(
                controller: _dailyRate,
                label: 'Daily rate',
                icon: Icons.payments,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                validator:
                    _nonNegativePriceValidator,
              ),

              _field(
                controller: _hourlyRate,
                label: 'Hourly rate',
                icon: Icons.schedule,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                validator:
                    _nonNegativePriceValidator,
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
                  'I confirm that the information is correct and agree to the Tour Guide terms.',
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : _saveDraft,
                      child: const Text(
                        'Save Draft',
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: yellow,
                        foregroundColor:
                            Colors.black,
                      ),
                      child: _saving
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
        'Apply as a local Swat tour guide. Your normal customer access will remain active.',
        style: TextStyle(
          height: 1.4,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
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

  Widget _chips({
    required List<String> items,
    required List<String> selected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map(
        (item) {
          final bool active =
              selected.contains(item);

          return FilterChip(
            selected: active,
            label: Text(item),
            selectedColor:
                yellow.withValues(alpha: 0.25),
            checkmarkColor: yellow,
            onSelected: (value) {
              setState(() {
                if (value) {
                  if (!selected.contains(item)) {
                    selected.add(item);
                  }
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

  Widget _languageSelector() {
    const List<String> levels = <String>[
      'Basic',
      'Intermediate',
      'Fluent',
    ];

    return Column(
      children: _availableLanguages.map(
        (String language) {
          final bool selected =
              _selectedLanguages.contains(language);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? yellow.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                CheckboxListTile(
                  value: selected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        if (!_selectedLanguages.contains(language)) {
                          _selectedLanguages.add(language);
                        }

                        _languageLevels.putIfAbsent(
                          language,
                          () => 'Intermediate',
                        );
                      } else {
                        _selectedLanguages.remove(language);
                        _languageLevels.remove(language);
                      }
                    });
                  },
                  activeColor: yellow,
                  checkColor: Colors.black,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    language,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (selected)
                  DropdownButtonFormField<String>(
                    initialValue:
                        _languageLevels[language] ??
                            'Intermediate',
                    dropdownColor: darkCard,
                    decoration: const InputDecoration(
                      labelText: 'Language level',
                    ),
                    items: levels
                        .map(
                          (level) => DropdownMenuItem<String>(
                            value: level,
                            child: Text(level),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _languageLevels[language] = value;
                      });
                    },
                  ),
              ],
            ),
          );
        },
      ).toList(),
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
          style: const TextStyle(
            color: Colors.grey,
          ),
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

  Widget _switch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: yellow,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
    );
  }

  Widget _uploadPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'Guide photo, CNIC, passport, police certificate, medical fitness certificate and training documents will be uploaded after Firebase Storage billing is enabled.',
        style: TextStyle(
          color: Colors.grey,
          height: 1.4,
        ),
      ),
    );
  }

  Future<void> _saveDraft() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _message(
        'Please log in first.',
        true,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final String id =
          await _service.saveDraft(
        _buildApplication(
          userId: user.uid,
          status: 'draft',
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _applicationId = id;
      });

      await _saveProfessionalDetails(
        applicationId: id,
      );

      _message(
        'Draft saved successfully.',
        false,
      );
    } catch (error) {
      _message(
        error.toString(),
        true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    final bool valid =
        _formKey.currentState?.validate() ??
            false;

    if (!valid) {
      _message(
        'Please correct the highlighted fields.',
        true,
      );
      return;
    }

    if (_selectedLanguages.isEmpty) {
      _message(
        'Select at least one language.',
        true,
      );
      return;
    }

    if (_selectedGuideTypes.isEmpty) {
      _message(
        'Select at least one guide type.',
        true,
      );
      return;
    }

    if (_selectedDestinations.isEmpty) {
      _message(
        'Select at least one destination.',
        true,
      );
      return;
    }

    if (_licenseExpiryDate == null) {
      _message(
        'Select the guide license expiry date.',
        true,
      );
      return;
    }

    if (_tourismRegistrationExpiryDate == null) {
      _message(
        'Select the tourism registration expiry date.',
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

    if (!_medicalFitnessCertificateAvailable) {
      _message(
        'Medical fitness certificate is required.',
        true,
      );
      return;
    }

    if (!_gpsTrackingConsent) {
      _message(
        'GPS tracking consent is required for active tours.',
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

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _message(
        'Please log in first.',
        true,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final String id =
          await _service.submitApplication(
        _buildApplication(
          userId: user.uid,
          status: 'submitted',
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _applicationId = id;
      });

      await _saveProfessionalDetails(
        applicationId: id,
      );

  if (!mounted) {
    return;
  }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: darkCard,
            title: const Text(
              'Application Submitted',
            ),
            content: const Text(
              'Your tour guide application is waiting for admin review.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: yellow,
                  foregroundColor:
                      Colors.black,
                ),
                child: const Text('Done'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      _message(
        error.toString(),
        true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _saveProfessionalDetails({
    required String applicationId,
  }) async {
    await FirebaseFirestore.instance
        .collection(
          TourGuideApplicationService.collectionName,
        )
        .doc(applicationId)
        .set(
      <String, dynamic>{
        'emergencyContactName':
            _emergencyContactName.text.trim(),
        'emergencyContactPhone':
            _emergencyContactPhone.text.trim(),
        'licenseExpiryDate': _licenseExpiryDate == null
            ? null
            : Timestamp.fromDate(_licenseExpiryDate!),
        'passportAvailable': _passportAvailable,
        'passportNumber': _passportAvailable
            ? _passportNumber.text.trim()
            : '',
        'policeCharacterCertificateAvailable':
            _policeCertificateAvailable,
        'medicalFitnessCertificateAvailable':
            _medicalFitnessCertificateAvailable,
        'firstAidCertificateNumber':
            _firstAidCertificateNumber.text.trim(),
        'tourismRegistrationNumber':
            _tourismRegistrationNumber.text.trim(),
        'tourismRegistrationExpiryDate':
            _tourismRegistrationExpiryDate == null
                ? null
                : Timestamp.fromDate(
                    _tourismRegistrationExpiryDate!,
                  ),
        'languageLevels':
            Map<String, String>.from(_languageLevels),
        'availableForAirportPickup':
            _airportPickup,
        'availableForNightTours':
            _nightTours,
        'availableForWomenOnlyTours':
            _womenOnlyTours,
        'foreignTouristExperience':
            _foreignTouristExperience,
        'gpsTrackingConsent':
            _gpsTrackingConsent,
        'professionalDetailsUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  TourGuideApplication _buildApplication({
    required String userId,
    required String status,
  }) {
    return TourGuideApplication(
      id: _applicationId,
      userId: userId,
      fullName: _name.text.trim(),
      phoneNumber: _phone.text.trim(),
      cnic: _cnic.text.trim(),
      email: _email.text.trim(),
      licenseNumber: _license.text.trim(),
      experienceYears: int.tryParse(
            _experience.text.trim(),
          ) ??
          0,
      languages:
          List<String>.from(
        _selectedLanguages,
      ),
      guideTypes:
          List<String>.from(
        _selectedGuideTypes,
      ),
      destinations:
          List<String>.from(
        _selectedDestinations,
      ),
      skills:
          List<String>.from(
        _selectedSkills,
      ),
      dailyRate: double.tryParse(
            _dailyRate.text.trim(),
          ) ??
          0,
      hourlyRate: double.tryParse(
            _hourlyRate.text.trim(),
          ) ??
          0,
      hasFirstAidTraining: _firstAid,
      availableForMultiDayTours: _multiDay,
      availableForFamilyTours:
          _familyTours,
      availableForGroupTours: _groupTours,
      applicationStatus: status,
      isCustomerAccessEnabled: true,
      createdAt: null,
      updatedAt: null,
      imageUrls: const <String>[],
      documentUrls: const <String>[],
    );
  }

  String? _required(String? value) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  String? _phoneValidator(String? value) {
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

  String? _cnicValidator(String? value) {
    final String clean =
        value?.replaceAll(
              RegExp(r'\D'),
              '',
            ) ??
            '';

    if (clean.length != 13) {
      return 'Enter a valid 13-digit CNIC.';
    }

    return null;
  }

  String? _optionalEmailValidator(
    String? value,
  ) {
    final String email =
        value?.trim() ?? '';

    if (email.isEmpty) {
      return null;
    }

    if (!email.contains('@') ||
        !email.contains('.')) {
      return 'Enter a valid email.';
    }

    return null;
  }

  String? _nonNegativeIntegerValidator(
    String? value,
  ) {
    final int? number =
        int.tryParse(
      value?.trim() ?? '',
    );

    if (number == null || number < 0) {
      return 'Enter a valid number.';
    }

    return null;
  }

  String? _nonNegativePriceValidator(
    String? value,
  ) {
    final double? number =
        double.tryParse(
      value?.trim() ?? '',
    );

    if (number == null || number < 0) {
      return 'Enter a valid amount.';
    }

    return null;
  }

  void _message(
    String text,
    bool error,
  ) {
    if (!mounted) {
      return;
    }

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

