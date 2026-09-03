import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HotelPoliciesManagementScreen extends StatefulWidget {
  const HotelPoliciesManagementScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelPoliciesManagementScreen> createState() =>
      _HotelPoliciesManagementScreenState();
}

class _HotelPoliciesManagementScreenState
    extends State<HotelPoliciesManagementScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _checkInTimeController =
      TextEditingController();

  final TextEditingController _checkOutTimeController =
      TextEditingController();

  final TextEditingController _freeCancellationHoursController =
      TextEditingController();

  final TextEditingController _cancellationChargeController =
      TextEditingController();

  final TextEditingController _childAgeLimitController =
      TextEditingController();

  final TextEditingController _extraBedChargeController =
      TextEditingController();

  final TextEditingController _advancePaymentPercentController =
      TextEditingController();

  final TextEditingController _quietHoursController =
      TextEditingController();

  final TextEditingController _houseRulesController =
      TextEditingController();

  final TextEditingController _refundPolicyController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  bool _childrenAllowed = true;
  bool _extraBedAvailable = false;
  bool _petsAllowed = false;
  bool _smokingAllowed = false;
  bool _cnicRequired = true;
  bool _couplesAllowed = true;
  bool _localGuestsAllowed = true;
  bool _advancePaymentRequired = false;
  bool _refundableBooking = true;
  bool _earlyCheckInAllowed = false;
  bool _lateCheckOutAllowed = false;

  @override
  void initState() {
    super.initState();
    _loadPolicies();
  }

  @override
  void dispose() {
    _checkInTimeController.dispose();
    _checkOutTimeController.dispose();
    _freeCancellationHoursController.dispose();
    _cancellationChargeController.dispose();
    _childAgeLimitController.dispose();
    _extraBedChargeController.dispose();
    _advancePaymentPercentController.dispose();
    _quietHoursController.dispose();
    _houseRulesController.dispose();
    _refundPolicyController.dispose();
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
          'Hotel Policies',
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
                    _infoCard(),

                    const SizedBox(height: 20),

                    _sectionTitle(
                      title: 'Check-in & Check-out',
                      subtitle:
                          'These timings will be shown before booking.',
                    ),

                    const SizedBox(height: 12),

                    _textField(
                      controller: _checkInTimeController,
                      label: 'Check-in time',
                      hint: 'Example: 2:00 PM',
                      icon: Icons.login,
                      validator: _requiredValidator,
                    ),

                    _textField(
                      controller: _checkOutTimeController,
                      label: 'Check-out time',
                      hint: 'Example: 12:00 PM',
                      icon: Icons.logout,
                      validator: _requiredValidator,
                    ),

                    _switchCard(
                      title: 'Early Check-in Allowed',
                      subtitle:
                          'Guest can request arrival before normal check-in time.',
                      value: _earlyCheckInAllowed,
                      onChanged: (value) {
                        setState(() {
                          _earlyCheckInAllowed = value;
                        });
                      },
                    ),

                    _switchCard(
                      title: 'Late Check-out Allowed',
                      subtitle:
                          'Guest can request departure after normal check-out time.',
                      value: _lateCheckOutAllowed,
                      onChanged: (value) {
                        setState(() {
                          _lateCheckOutAllowed = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    _sectionTitle(
                      title: 'Cancellation & Refund',
                      subtitle:
                          'Set the free cancellation window and charges.',
                    ),

                    const SizedBox(height: 12),

                    _numberField(
                      controller:
                          _freeCancellationHoursController,
                      label: 'Free cancellation hours',
                      hint: 'Example: 24',
                      icon: Icons.schedule,
                      suffix: 'hours',
                      required: true,
                    ),

                    _numberField(
                      controller:
                          _cancellationChargeController,
                      label: 'Cancellation charge',
                      hint: 'Example: 25',
                      icon: Icons.percent,
                      suffix: '%',
                      required: true,
                    ),

                    _switchCard(
                      title: 'Refundable Booking',
                      subtitle:
                          'Enable refunds according to the policy below.',
                      value: _refundableBooking,
                      onChanged: (value) {
                        setState(() {
                          _refundableBooking = value;
                        });
                      },
                    ),

                    _textField(
                      controller: _refundPolicyController,
                      label: 'Refund policy',
                      hint:
                          'Explain refund timing, deductions and conditions.',
                      icon: Icons.currency_exchange_outlined,
                      maxLines: 4,
                      validator: _requiredValidator,
                    ),

                    const SizedBox(height: 20),

                    _sectionTitle(
                      title: 'Children & Extra Bed',
                      subtitle:
                          'Control child stay and extra bed charges.',
                    ),

                    const SizedBox(height: 12),

                    _switchCard(
                      title: 'Children Allowed',
                      subtitle:
                          'Allow bookings with children.',
                      value: _childrenAllowed,
                      onChanged: (value) {
                        setState(() {
                          _childrenAllowed = value;
                        });
                      },
                    ),

                    if (_childrenAllowed)
                      _numberField(
                        controller:
                            _childAgeLimitController,
                        label: 'Child age limit',
                        hint: 'Example: 12',
                        icon:
                            Icons.child_care_outlined,
                        suffix: 'years',
                        required: true,
                      ),

                    _switchCard(
                      title: 'Extra Bed Available',
                      subtitle:
                          'Allow an extra bed in supported rooms.',
                      value: _extraBedAvailable,
                      onChanged: (value) {
                        setState(() {
                          _extraBedAvailable = value;
                        });
                      },
                    ),

                    if (_extraBedAvailable)
                      _numberField(
                        controller:
                            _extraBedChargeController,
                        label: 'Extra bed charge',
                        hint: 'Example: 1500',
                        icon: Icons.bed_outlined,
                        suffix: 'Rs.',
                        required: true,
                      ),

                    const SizedBox(height: 20),

                    _sectionTitle(
                      title: 'Guest Rules',
                      subtitle:
                          'Define who can stay and required verification.',
                    ),

                    const SizedBox(height: 12),

                    _switchCard(
                      title: 'CNIC / ID Required',
                      subtitle:
                          'Guest must show valid identification at check-in.',
                      value: _cnicRequired,
                      onChanged: (value) {
                        setState(() {
                          _cnicRequired = value;
                        });
                      },
                    ),

                    _switchCard(
                      title: 'Couples Allowed',
                      subtitle:
                          'Allow couples according to hotel and local policy.',
                      value: _couplesAllowed,
                      onChanged: (value) {
                        setState(() {
                          _couplesAllowed = value;
                        });
                      },
                    ),

                    _switchCard(
                      title: 'Local Guests Allowed',
                      subtitle:
                          'Allow guests from the same city or area.',
                      value: _localGuestsAllowed,
                      onChanged: (value) {
                        setState(() {
                          _localGuestsAllowed = value;
                        });
                      },
                    ),

                    _switchCard(
                      title: 'Pets Allowed',
                      subtitle:
                          'Allow guests to bring pets.',
                      value: _petsAllowed,
                      onChanged: (value) {
                        setState(() {
                          _petsAllowed = value;
                        });
                      },
                    ),

                    _switchCard(
                      title: 'Smoking Allowed',
                      subtitle:
                          'Allow smoking only where hotel rules permit.',
                      value: _smokingAllowed,
                      onChanged: (value) {
                        setState(() {
                          _smokingAllowed = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    _sectionTitle(
                      title: 'Advance Payment',
                      subtitle:
                          'Payment processing remains bypassed until billing is enabled.',
                    ),

                    const SizedBox(height: 12),

                    _switchCard(
                      title: 'Advance Payment Required',
                      subtitle:
                          'Require a percentage before confirmation.',
                      value: _advancePaymentRequired,
                      onChanged: (value) {
                        setState(() {
                          _advancePaymentRequired = value;
                        });
                      },
                    ),

                    if (_advancePaymentRequired)
                      _numberField(
                        controller:
                            _advancePaymentPercentController,
                        label: 'Advance payment',
                        hint: 'Example: 20',
                        icon: Icons.payments_outlined,
                        suffix: '%',
                        required: true,
                      ),

                    const SizedBox(height: 20),

                    _sectionTitle(
                      title: 'House Rules',
                      subtitle:
                          'Show important rules before booking confirmation.',
                    ),

                    const SizedBox(height: 12),

                    _textField(
                      controller: _quietHoursController,
                      label: 'Quiet hours',
                      hint: 'Example: 10:00 PM - 7:00 AM',
                      icon: Icons.nights_stay_outlined,
                      validator: _requiredValidator,
                    ),

                    _textField(
                      controller: _houseRulesController,
                      label: 'House rules',
                      hint:
                          'Add cleanliness, visitors, damage and conduct rules.',
                      icon: Icons.rule_outlined,
                      maxLines: 6,
                      validator: _requiredValidator,
                    ),

                    const SizedBox(height: 18),

                    _billingNotice(),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isSaving ? null : _savePolicies,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: yellow,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(
                                Icons.save_outlined,
                              ),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : 'Save Hotel Policies',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
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

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.09,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.policy_outlined,
            color: yellow,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Saved policies will be shown to customers before booking. Keep rules clear, accurate and consistent with hotel operations.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: TextFormField(
        controller: controller,
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

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String suffix,
    required bool required,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType:
            const TextInputType.numberWithOptions(
          decimal: true,
        ),
        validator: (String? value) {
          final String text = value?.trim() ?? '';

          if (required && text.isEmpty) {
            return 'This field is required.';
          }

          if (text.isEmpty) {
            return null;
          }

          final double? number =
              double.tryParse(text);

          if (number == null) {
            return 'Enter a valid number.';
          }

          if (number < 0) {
            return 'Value cannot be negative.';
          }

          if (suffix == '%' && number > 100) {
            return 'Percentage cannot exceed 100.';
          }

          return null;
        },
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
          suffixText: suffix,
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

  Widget _switchCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: value
              ? yellow.withValues(
                  alpha: 0.25,
                )
              : Colors.white.withValues(
                  alpha: 0.05,
                ),
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: yellow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 2,
        ),
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
            fontSize: 10,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  Widget _billingNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: yellow,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Policy settings are active. Real online advance collection, automated cancellation deductions and refunds remain bypassed until billing integration is enabled.',
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

  Future<void> _loadPolicies() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection('hotels')
              .doc(widget.hotelId)
              .get();

      final Map<String, dynamic> data =
          snapshot.data() ?? <String, dynamic>{};

      final Map<String, dynamic> policies =
          data['policies'] is Map
              ? Map<String, dynamic>.from(
                  data['policies'] as Map,
                )
              : <String, dynamic>{};

      _checkInTimeController.text =
          policies['checkInTime']?.toString() ??
              data['checkInTime']?.toString() ??
              '2:00 PM';

      _checkOutTimeController.text =
          policies['checkOutTime']?.toString() ??
              data['checkOutTime']?.toString() ??
              '12:00 PM';

      _freeCancellationHoursController.text =
          _numberText(
        policies['freeCancellationHours'],
        fallback: '24',
      );

      _cancellationChargeController.text =
          _numberText(
        policies['cancellationChargePercent'],
        fallback: '0',
      );

      _childAgeLimitController.text =
          _numberText(
        policies['childAgeLimit'],
        fallback: '12',
      );

      _extraBedChargeController.text =
          _numberText(
        policies['extraBedCharge'],
      );

      _advancePaymentPercentController.text =
          _numberText(
        policies['advancePaymentPercent'],
      );

      _quietHoursController.text =
          policies['quietHours']?.toString() ??
              '10:00 PM - 7:00 AM';

      _houseRulesController.text =
          policies['houseRules']?.toString() ??
              '';

      _refundPolicyController.text =
          policies['refundPolicy']?.toString() ??
              data['cancellationPolicy']?.toString() ??
              '';

      _childrenAllowed =
          policies['childrenAllowed'] != false;

      _extraBedAvailable =
          policies['extraBedAvailable'] == true;

      _petsAllowed =
          policies['petsAllowed'] == true;

      _smokingAllowed =
          policies['smokingAllowed'] == true;

      _cnicRequired =
          policies['cnicRequired'] != false;

      _couplesAllowed =
          policies['couplesAllowed'] != false;

      _localGuestsAllowed =
          policies['localGuestsAllowed'] != false;

      _advancePaymentRequired =
          policies['advancePaymentRequired'] == true;

      _refundableBooking =
          policies['refundableBooking'] != false;

      _earlyCheckInAllowed =
          policies['earlyCheckInAllowed'] == true;

      _lateCheckOutAllowed =
          policies['lateCheckOutAllowed'] == true;
    } catch (error) {
      _showMessage(
        'Unable to load hotel policies: $error',
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

  Future<void> _savePolicies() async {
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
      final Map<String, dynamic> policies =
          <String, dynamic>{
        'checkInTime':
            _checkInTimeController.text.trim(),
        'checkOutTime':
            _checkOutTimeController.text.trim(),
        'freeCancellationHours':
            int.tryParse(
                  _freeCancellationHoursController.text
                      .trim(),
                ) ??
                0,
        'cancellationChargePercent':
            double.tryParse(
                  _cancellationChargeController.text
                      .trim(),
                ) ??
                0,
        'refundableBooking':
            _refundableBooking,
        'refundPolicy':
            _refundPolicyController.text.trim(),
        'childrenAllowed':
            _childrenAllowed,
        'childAgeLimit':
            _childrenAllowed
                ? int.tryParse(
                      _childAgeLimitController.text
                          .trim(),
                    ) ??
                    0
                : null,
        'extraBedAvailable':
            _extraBedAvailable,
        'extraBedCharge':
            _extraBedAvailable
                ? double.tryParse(
                    _extraBedChargeController.text
                        .trim(),
                  )
                : null,
        'petsAllowed':
            _petsAllowed,
        'smokingAllowed':
            _smokingAllowed,
        'cnicRequired':
            _cnicRequired,
        'couplesAllowed':
            _couplesAllowed,
        'localGuestsAllowed':
            _localGuestsAllowed,
        'advancePaymentRequired':
            _advancePaymentRequired,
        'advancePaymentPercent':
            _advancePaymentRequired
                ? double.tryParse(
                    _advancePaymentPercentController
                        .text
                        .trim(),
                  )
                : null,
        'earlyCheckInAllowed':
            _earlyCheckInAllowed,
        'lateCheckOutAllowed':
            _lateCheckOutAllowed,
        'quietHours':
            _quietHoursController.text.trim(),
        'houseRules':
            _houseRulesController.text.trim(),
        'updatedBy':
            user.uid,
        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('hotels')
          .doc(widget.hotelId)
          .set(
        <String, dynamic>{
          'policies': policies,
          'checkInTime':
              _checkInTimeController.text.trim(),
          'checkOutTime':
              _checkOutTimeController.text.trim(),
          'cancellationPolicy':
              _refundPolicyController.text.trim(),
          'lastUpdatedBy':
              user.uid,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _showMessage(
        'Hotel policies updated successfully.',
      );
    } catch (error) {
      _showMessage(
        'Unable to save hotel policies: $error',
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

  String _numberText(
    dynamic value, {
    String fallback = '',
  }) {
    if (value is num) {
      final double number = value.toDouble();

      return number == number.roundToDouble()
          ? number.toStringAsFixed(0)
          : number.toStringAsFixed(2);
    }

    final String text =
        value?.toString().trim() ?? '';

    return text.isEmpty ? fallback : text;
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
