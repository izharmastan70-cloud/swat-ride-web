import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HotelAdminSettingsScreen extends StatefulWidget {
  const HotelAdminSettingsScreen({
    super.key,
    required this.hotelId,
  });

  final String hotelId;

  @override
  State<HotelAdminSettingsScreen> createState() =>
      _HotelAdminSettingsScreenState();
}

class _HotelAdminSettingsScreenState
    extends State<HotelAdminSettingsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkBackground = Color(0xFF0D0D0D);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _hotelNameController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _phoneController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _mapLocationController =
      TextEditingController();

  final TextEditingController _taxController =
      TextEditingController();

  final TextEditingController _serviceChargeController =
      TextEditingController();

  final TextEditingController
      _advanceBookingDaysController =
      TextEditingController();

  final TextEditingController
      _freeCancellationHoursController =
      TextEditingController();

  final TextEditingController
      _cancellationFeeController =
      TextEditingController();

  final TextEditingController
      _lateCheckoutHourlyRateController =
      TextEditingController();

  TimeOfDay _checkInTime =
      const TimeOfDay(hour: 14, minute: 0);

  TimeOfDay _checkOutTime =
      const TimeOfDay(hour: 12, minute: 0);

  bool _autoConfirmBooking = false;
  bool _walkInBookingEnabled = true;
  bool _weekendPricingEnabled = false;
  bool _seasonalPricingEnabled = false;

  bool _bookingAlerts = true;
  bool _paymentAlerts = true;
  bool _housekeepingAlerts = true;
  bool _staffAlerts = true;
  bool _checkoutReminderEnabled = true;

  bool _twoFactorFutureReady = false;
  bool _isLoading = true;
  bool _isSaving = false;

  DocumentReference<Map<String, dynamic>>
      get _settingsReference => _firestore
          .collection('hotel_settings')
          .doc(widget.hotelId);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _hotelNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _mapLocationController.dispose();
    _taxController.dispose();
    _serviceChargeController.dispose();
    _advanceBookingDaysController.dispose();
    _freeCancellationHoursController.dispose();
    _cancellationFeeController.dispose();
    _lateCheckoutHourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>>
          settingsSnapshot =
          await _settingsReference.get();

      Map<String, dynamic> data =
          settingsSnapshot.data() ??
              <String, dynamic>{};

      if (data.isEmpty) {
        final QuerySnapshot<Map<String, dynamic>>
            hotelSnapshot = await _firestore
                .collection('hotels')
                .where(
                  'hotelId',
                  isEqualTo: widget.hotelId,
                )
                .limit(1)
                .get();

        if (hotelSnapshot.docs.isNotEmpty) {
          data = hotelSnapshot.docs.first.data();
        }
      }

      _hotelNameController.text =
          data['hotelName']?.toString() ??
              data['name']?.toString() ??
              '';

      _descriptionController.text =
          data['description']?.toString() ?? '';

      _addressController.text =
          data['address']?.toString() ??
              data['location']?.toString() ??
              '';

      _phoneController.text =
          data['phone']?.toString() ??
              data['phoneNumber']?.toString() ??
              '';

      _emailController.text =
          data['email']?.toString() ?? '';

      _mapLocationController.text =
          data['mapLocation']?.toString() ??
              data['googleMapsLocation']
                  ?.toString() ??
              '';

      _taxController.text =
          _readNumber(
            data['taxPercentage'],
          ).toStringAsFixed(1);

      _serviceChargeController.text =
          _readNumber(
            data['serviceChargePercentage'],
          ).toStringAsFixed(1);

      _advanceBookingDaysController.text =
          _readInt(
            data['advanceBookingDays'],
            fallback: 180,
          ).toString();

      _freeCancellationHoursController.text =
          _readInt(
            data['freeCancellationHours'],
            fallback: 24,
          ).toString();

      _cancellationFeeController.text =
          _readNumber(
            data['cancellationFeePercentage'],
          ).toStringAsFixed(1);

      _lateCheckoutHourlyRateController.text =
          _readNumber(
            data['lateCheckoutHourlyRate'],
          ).toStringAsFixed(0);

      _checkInTime = TimeOfDay(
        hour: _readInt(
          data['checkInHour'],
          fallback: 14,
        ).clamp(0, 23),
        minute: _readInt(
          data['checkInMinute'],
        ).clamp(0, 59),
      );

      _checkOutTime = TimeOfDay(
        hour: _readInt(
          data['checkOutHour'],
          fallback: 12,
        ).clamp(0, 23),
        minute: _readInt(
          data['checkOutMinute'],
        ).clamp(0, 59),
      );

      _autoConfirmBooking =
          data['autoConfirmBooking'] == true;

      _walkInBookingEnabled =
          data['walkInBookingEnabled'] != false;

      _weekendPricingEnabled =
          data['weekendPricingEnabled'] == true;

      _seasonalPricingEnabled =
          data['seasonalPricingEnabled'] == true;

      _bookingAlerts =
          data['bookingAlerts'] != false;

      _paymentAlerts =
          data['paymentAlerts'] != false;

      _housekeepingAlerts =
          data['housekeepingAlerts'] != false;

      _staffAlerts =
          data['staffAlerts'] != false;

      _checkoutReminderEnabled =
          data['checkoutReminderEnabled'] != false;

      _twoFactorFutureReady =
          data['twoFactorFutureReady'] == true;
    } catch (error) {
      _showMessage(
        'Unable to load hotel settings: $error',
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
          'Hotel Admin Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: yellow,
              ),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    30,
                  ),
                  children: [
                    _sectionCard(
                      title: 'Hotel Profile',
                      icon:
                          Icons.apartment_outlined,
                      child: Column(
                        children: [
                          _field(
                            controller:
                                _hotelNameController,
                            label: 'Hotel Name',
                            icon:
                                Icons.hotel_outlined,
                            validator: _required,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller:
                                _descriptionController,
                            label:
                                'Hotel Description',
                            icon:
                                Icons.description_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller:
                                _addressController,
                            label: 'Address',
                            icon:
                                Icons.location_on_outlined,
                            validator: _required,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller:
                                _mapLocationController,
                            label:
                                'Google Maps Location / Coordinates',
                            icon:
                                Icons.map_outlined,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller:
                                _phoneController,
                            label: 'Phone Number',
                            icon:
                                Icons.phone_outlined,
                            keyboardType:
                                TextInputType.phone,
                            validator:
                                _phoneValidator,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller:
                                _emailController,
                            label: 'Email',
                            icon:
                                Icons.email_outlined,
                            keyboardType:
                                TextInputType
                                    .emailAddress,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _sectionCard(
                      title: 'Check-in & Check-out',
                      icon: Icons.schedule_outlined,
                      child: Column(
                        children: [
                          _timeTile(
                            title: 'Check-in Time',
                            value: _checkInTime,
                            onTap: () async {
                              final TimeOfDay? value =
                                  await showTimePicker(
                                context: context,
                                initialTime:
                                    _checkInTime,
                              );

                              if (value != null &&
                                  mounted) {
                                setState(() {
                                  _checkInTime =
                                      value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          _timeTile(
                            title: 'Check-out Time',
                            value: _checkOutTime,
                            onTap: () async {
                              final TimeOfDay? value =
                                  await showTimePicker(
                                context: context,
                                initialTime:
                                    _checkOutTime,
                              );

                              if (value != null &&
                                  mounted) {
                                setState(() {
                                  _checkOutTime =
                                      value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller:
                                _lateCheckoutHourlyRateController,
                            label:
                                'Late Check-out Hourly Rate',
                            icon:
                                Icons.more_time_outlined,
                            keyboardType:
                                TextInputType.number,
                            validator:
                                _numberValidator,
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            value:
                                _checkoutReminderEnabled,
                            onChanged: (value) {
                              setState(() {
                                _checkoutReminderEnabled =
                                    value;
                              });
                            },
                            activeThumbColor: yellow,
                            contentPadding:
                                EdgeInsets.zero,
                            title: const Text(
                              'Polite Guest Check-out Reminder',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text(
                              'Show a respectful reminder before checkout.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _sectionCard(
                      title: 'Booking Settings',
                      icon:
                          Icons.book_online_outlined,
                      child: Column(
                        children: [
                          _field(
                            controller:
                                _advanceBookingDaysController,
                            label:
                                'Advance Booking Limit (days)',
                            icon:
                                Icons.calendar_month_outlined,
                            keyboardType:
                                TextInputType.number,
                            validator:
                                _numberValidator,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller:
                                _freeCancellationHoursController,
                            label:
                                'Free Cancellation Hours',
                            icon:
                                Icons.timer_outlined,
                            keyboardType:
                                TextInputType.number,
                            validator:
                                _numberValidator,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller:
                                _cancellationFeeController,
                            label:
                                'Cancellation Fee %',
                            icon:
                                Icons.percent_outlined,
                            keyboardType:
                                TextInputType.number,
                            validator:
                                _percentageValidator,
                          ),
                          SwitchListTile(
                            value:
                                _autoConfirmBooking,
                            onChanged: (value) {
                              setState(() {
                                _autoConfirmBooking =
                                    value;
                              });
                            },
                            activeThumbColor: yellow,
                            contentPadding:
                                EdgeInsets.zero,
                            title: const Text(
                              'Auto-confirm Bookings',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SwitchListTile(
                            value:
                                _walkInBookingEnabled,
                            onChanged: (value) {
                              setState(() {
                                _walkInBookingEnabled =
                                    value;
                              });
                            },
                            activeThumbColor: yellow,
                            contentPadding:
                                EdgeInsets.zero,
                            title: const Text(
                              'Enable Walk-in Booking',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _sectionCard(
                      title: 'Pricing Settings',
                      icon:
                          Icons.payments_outlined,
                      child: Column(
                        children: [
                          _field(
                            controller:
                                _taxController,
                            label: 'Tax %',
                            icon:
                                Icons.percent_outlined,
                            keyboardType:
                                TextInputType.number,
                            validator:
                                _percentageValidator,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller:
                                _serviceChargeController,
                            label:
                                'Service Charge %',
                            icon:
                                Icons.receipt_long_outlined,
                            keyboardType:
                                TextInputType.number,
                            validator:
                                _percentageValidator,
                          ),
                          SwitchListTile(
                            value:
                                _weekendPricingEnabled,
                            onChanged: (value) {
                              setState(() {
                                _weekendPricingEnabled =
                                    value;
                              });
                            },
                            activeThumbColor: yellow,
                            contentPadding:
                                EdgeInsets.zero,
                            title: const Text(
                              'Weekend Pricing',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SwitchListTile(
                            value:
                                _seasonalPricingEnabled,
                            onChanged: (value) {
                              setState(() {
                                _seasonalPricingEnabled =
                                    value;
                              });
                            },
                            activeThumbColor: yellow,
                            contentPadding:
                                EdgeInsets.zero,
                            title: const Text(
                              'Seasonal Pricing',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Text(
                            'Room prices remain managed from Room Management. These switches only enable hotel pricing policies.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _sectionCard(
                      title: 'Notifications',
                      icon: Icons
                          .notifications_active_outlined,
                      child: Column(
                        children: [
                          _notificationSwitch(
                            title: 'Booking Alerts',
                            value: _bookingAlerts,
                            onChanged: (value) {
                              setState(() {
                                _bookingAlerts =
                                    value;
                              });
                            },
                          ),
                          _notificationSwitch(
                            title: 'Payment Alerts',
                            value: _paymentAlerts,
                            onChanged: (value) {
                              setState(() {
                                _paymentAlerts =
                                    value;
                              });
                            },
                          ),
                          _notificationSwitch(
                            title:
                                'Housekeeping Alerts',
                            value:
                                _housekeepingAlerts,
                            onChanged: (value) {
                              setState(() {
                                _housekeepingAlerts =
                                    value;
                              });
                            },
                          ),
                          _notificationSwitch(
                            title: 'Staff Alerts',
                            value: _staffAlerts,
                            onChanged: (value) {
                              setState(() {
                                _staffAlerts =
                                    value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _sectionCard(
                      title: 'Security',
                      icon:
                          Icons.security_outlined,
                      child: Column(
                        children: [
                          SwitchListTile(
                            value:
                                _twoFactorFutureReady,
                            onChanged: (value) {
                              setState(() {
                                _twoFactorFutureReady =
                                    value;
                              });
                            },
                            activeThumbColor: yellow,
                            contentPadding:
                                EdgeInsets.zero,
                            title: const Text(
                              'Two-factor Authentication',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            subtitle: const Text(
                              'Future-ready setting. Real 2FA will be connected in the authentication phase.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          ListTile(
                            contentPadding:
                                EdgeInsets.zero,
                            leading: const Icon(
                              Icons.password_outlined,
                              color: yellow,
                            ),
                            title: const Text(
                              'Change Password',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            subtitle: const Text(
                              'Will use the authenticated hotel owner account.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              _showMessage(
                                'Password change will be connected with hotel owner authentication.',
                              );
                            },
                          ),
                          ListTile(
                            contentPadding:
                                EdgeInsets.zero,
                            leading: const Icon(
                              Icons.devices_outlined,
                              color: yellow,
                            ),
                            title: const Text(
                              'Login Devices',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            subtitle: const Text(
                              'Device management is prepared for the security phase.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              _showMessage(
                                'Login device management is future-ready.',
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : _saveSettings,
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
                              : 'Save Hotel Settings',
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor: yellow,
                          foregroundColor:
                              Colors.black,
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _noticeCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState?.validate() !=
        true) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final Map<String, dynamic> settings =
          <String, dynamic>{
        'hotelId': widget.hotelId,
        'hotelName':
            _hotelNameController.text.trim(),
        'description':
            _descriptionController.text.trim(),
        'address':
            _addressController.text.trim(),
        'mapLocation':
            _mapLocationController.text.trim(),
        'phone':
            _phoneController.text.trim(),
        'email':
            _emailController.text.trim(),
        'checkInHour': _checkInTime.hour,
        'checkInMinute': _checkInTime.minute,
        'checkOutHour': _checkOutTime.hour,
        'checkOutMinute':
            _checkOutTime.minute,
        'lateCheckoutHourlyRate':
            _readNumber(
          _lateCheckoutHourlyRateController
              .text,
        ),
        'advanceBookingDays': _readInt(
          _advanceBookingDaysController.text,
          fallback: 180,
        ),
        'freeCancellationHours': _readInt(
          _freeCancellationHoursController
              .text,
          fallback: 24,
        ),
        'cancellationFeePercentage':
            _readNumber(
          _cancellationFeeController.text,
        ),
        'taxPercentage': _readNumber(
          _taxController.text,
        ),
        'serviceChargePercentage':
            _readNumber(
          _serviceChargeController.text,
        ),
        'autoConfirmBooking':
            _autoConfirmBooking,
        'walkInBookingEnabled':
            _walkInBookingEnabled,
        'weekendPricingEnabled':
            _weekendPricingEnabled,
        'seasonalPricingEnabled':
            _seasonalPricingEnabled,
        'bookingAlerts': _bookingAlerts,
        'paymentAlerts': _paymentAlerts,
        'housekeepingAlerts':
            _housekeepingAlerts,
        'staffAlerts': _staffAlerts,
        'checkoutReminderEnabled':
            _checkoutReminderEnabled,
        'checkoutReminderMinutesBefore':
            30,
        'checkoutReminderMessage':
            'Before leaving, please take a quick moment to check your personal belongings. If you need any assistance, our hotel team will be happy to help. Thank you for staying with us, and have a safe journey.',
        'twoFactorFutureReady':
            _twoFactorFutureReady,
        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      await _settingsReference.set(
        settings,
        SetOptions(merge: true),
      );

      await _firestore
          .collection('hotels')
          .doc(widget.hotelId)
          .set(
        <String, dynamic>{
          'name':
              _hotelNameController.text.trim(),
          'hotelName':
              _hotelNameController.text.trim(),
          'description':
              _descriptionController.text.trim(),
          'address':
              _addressController.text.trim(),
          'location':
              _addressController.text.trim(),
          'phone':
              _phoneController.text.trim(),
          'email':
              _emailController.text.trim(),
          'checkInHour': _checkInTime.hour,
          'checkInMinute':
              _checkInTime.minute,
          'checkOutHour': _checkOutTime.hour,
          'checkOutMinute':
              _checkOutTime.minute,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _showMessage(
        'Hotel settings saved successfully.',
      );
    } catch (error) {
      _showMessage(
        'Unable to save hotel settings: $error',
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

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: yellow,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.grey,
        ),
        prefixIcon: Icon(
          icon,
          color: yellow,
        ),
        filled: true,
        fillColor: darkBackground,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _timeTile({
    required String title,
    required TimeOfDay value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: darkBackground,
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.schedule,
              color: yellow,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            Text(
              value.format(context),
              style: const TextStyle(
                color: yellow,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool>
        onChanged,
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
        ),
      ),
    );
  }

  Widget _noticeCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: yellow.withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: yellow,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Settings are saved to Firestore. SWAT RIDE Super Admin will retain control over platform commission, payment gateways and global safety rules.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(
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
    if (value == null ||
        value.trim().length < 10) {
      return 'Enter a valid phone number.';
    }

    return null;
  }

  String? _numberValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Required';
    }

    if (double.tryParse(value.trim()) ==
        null) {
      return 'Enter a valid number.';
    }

    return null;
  }

  String? _percentageValidator(
    String? value,
  ) {
    final String? error =
        _numberValidator(value);

    if (error != null) {
      return error;
    }

    final double number =
        double.parse(value!.trim());

    if (number < 0 || number > 100) {
      return 'Enter value from 0 to 100.';
    }

    return null;
  }

  int _readInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  double _readNumber(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
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
