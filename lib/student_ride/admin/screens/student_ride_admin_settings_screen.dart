import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/student_ride_settings_model.dart';
import '../../services/student_ride_settings_service.dart';

class StudentRideAdminSettingsScreen extends StatefulWidget {
  const StudentRideAdminSettingsScreen({super.key});

  @override
  State<StudentRideAdminSettingsScreen> createState() =>
      _StudentRideAdminSettingsScreenState();
}

class _StudentRideAdminSettingsScreenState
    extends State<StudentRideAdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = StudentRideSettingsService();

  bool _initialized = false;
  bool _saving = false;

  bool _moduleEnabled = true;
  bool _morningServiceEnabled = true;
  bool _afternoonServiceEnabled = true;
  bool _oneWayPackageEnabled = true;
  bool _twoWayPackageEnabled = true;
  bool _dailyBookingEnabled = false;
  bool _monthlyPackageEnabled = true;
  bool _routeBasedPricingEnabled = true;
  bool _siblingDiscountEnabled = false;
  bool _doorToDoorEnabled = true;
  bool _waitlistEnabled = true;
  bool _absenceReportingEnabled = true;
  bool _temporaryRouteChangeEnabled = false;

  bool _cashEnabled = true;
  bool _walletEnabled = false;
  bool _easypaisaEnabled = false;
  bool _jazzCashEnabled = false;
  bool _cardPaymentEnabled = false;

  StudentRideBillingMode _billingMode = StudentRideBillingMode.monthly;
  StudentRideCommissionType _commissionType =
      StudentRideCommissionType.percentage;

  final _monthlyBasePrice = TextEditingController();
  final _dailyBasePrice = TextEditingController();
  final _routeBasePrice = TextEditingController();
  final _perKmPrice = TextEditingController();
  final _morningMultiplier = TextEditingController();
  final _afternoonMultiplier = TextEditingController();
  final _twoWayMultiplier = TextEditingController();
  final _doorToDoorCharge = TextEditingController();
  final _registrationFee = TextEditingController();
  final _siblingDiscount = TextEditingController();
  final _commissionValue = TextEditingController();
  final _paymentDueDay = TextEditingController();
  final _paymentGraceDays = TextEditingController();
  final _renewalReminderDays = TextEditingController();
  final _absenceCutoffMinutes = TextEditingController();
  final _routeChangeCutoffHours = TextEditingController();
  final _maximumStudents = TextEditingController();
  final _disabledMessage = TextEditingController();
  final _currencyCode = TextEditingController();

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _monthlyBasePrice,
      _dailyBasePrice,
      _routeBasePrice,
      _perKmPrice,
      _morningMultiplier,
      _afternoonMultiplier,
      _twoWayMultiplier,
      _doorToDoorCharge,
      _registrationFee,
      _siblingDiscount,
      _commissionValue,
      _paymentDueDay,
      _paymentGraceDays,
      _renewalReminderDays,
      _absenceCutoffMinutes,
      _routeChangeCutoffHours,
      _maximumStudents,
      _disabledMessage,
      _currencyCode,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _load(StudentRideSettingsModel settings) {
    if (_initialized) return;
    _initialized = true;

    _moduleEnabled = settings.moduleEnabled;
    _morningServiceEnabled = settings.morningServiceEnabled;
    _afternoonServiceEnabled = settings.afternoonServiceEnabled;
    _oneWayPackageEnabled = settings.oneWayPackageEnabled;
    _twoWayPackageEnabled = settings.twoWayPackageEnabled;
    _dailyBookingEnabled = settings.dailyBookingEnabled;
    _monthlyPackageEnabled = settings.monthlyPackageEnabled;
    _routeBasedPricingEnabled = settings.routeBasedPricingEnabled;
    _siblingDiscountEnabled = settings.siblingDiscountEnabled;
    _doorToDoorEnabled = settings.doorToDoorEnabled;
    _waitlistEnabled = settings.waitlistEnabled;
    _absenceReportingEnabled = settings.absenceReportingEnabled;
    _temporaryRouteChangeEnabled = settings.temporaryRouteChangeEnabled;
    _cashEnabled = settings.cashEnabled;
    _walletEnabled = settings.walletEnabled;
    _easypaisaEnabled = settings.easypaisaEnabled;
    _jazzCashEnabled = settings.jazzCashEnabled;
    _cardPaymentEnabled = settings.cardPaymentEnabled;
    _billingMode = settings.defaultBillingMode;
    _commissionType = settings.commissionType;

    _setDouble(_monthlyBasePrice, settings.monthlyBasePrice);
    _setDouble(_dailyBasePrice, settings.dailyBasePrice);
    _setDouble(_routeBasePrice, settings.routeBasePrice);
    _setDouble(_perKmPrice, settings.perKmPrice);
    _setDouble(_morningMultiplier, settings.morningOnlyMultiplier);
    _setDouble(_afternoonMultiplier, settings.afternoonOnlyMultiplier);
    _setDouble(_twoWayMultiplier, settings.twoWayMultiplier);
    _setDouble(_doorToDoorCharge, settings.doorToDoorCharge);
    _setDouble(_registrationFee, settings.registrationFee);
    _setDouble(_siblingDiscount, settings.siblingDiscountPercent);
    _setDouble(_commissionValue, settings.commissionValue);
    _paymentDueDay.text = settings.paymentDueDay.toString();
    _paymentGraceDays.text = settings.paymentGraceDays.toString();
    _renewalReminderDays.text = settings.renewalReminderDays.toString();
    _absenceCutoffMinutes.text = settings.absenceCutoffMinutes.toString();
    _routeChangeCutoffHours.text = settings.routeChangeCutoffHours.toString();
    _maximumStudents.text = settings.maximumStudentsPerVehicle.toString();
    _disabledMessage.text = settings.disabledMessage;
    _currencyCode.text = settings.currencyCode;
  }

  void _setDouble(TextEditingController controller, double value) {
    controller.text = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  }

  String? _nonNegativeNumber(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) return 'Enter zero or a positive number';
    return null;
  }

  String? _positiveNumber(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return 'Enter a number greater than zero';
    return null;
  }

  String? _positiveInt(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 1) return 'Enter a whole number of 1 or more';
    return null;
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    final adminId = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (adminId.isEmpty) {
      _message('Admin must be logged in before saving settings.');
      return;
    }
    if (!_cashEnabled &&
        !_walletEnabled &&
        !_easypaisaEnabled &&
        !_jazzCashEnabled &&
        !_cardPaymentEnabled) {
      _message('Enable at least one payment method.');
      return;
    }

    final commission = double.parse(_commissionValue.text.trim());
    final siblingDiscount = double.parse(_siblingDiscount.text.trim());
    final paymentDueDay = int.parse(_paymentDueDay.text.trim());

    if (_commissionType == StudentRideCommissionType.percentage &&
        commission > 100) {
      _message('Percentage commission cannot exceed 100%.');
      return;
    }
    if (siblingDiscount > 100) {
      _message('Sibling discount cannot exceed 100%.');
      return;
    }
    if (paymentDueDay < 1 || paymentDueDay > 28) {
      _message('Payment due day must be between 1 and 28.');
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.updateFields(
        adminId: adminId,
        fields: <String, dynamic>{
          'moduleEnabled': _moduleEnabled,
          'morningServiceEnabled': _morningServiceEnabled,
          'afternoonServiceEnabled': _afternoonServiceEnabled,
          'oneWayPackageEnabled': _oneWayPackageEnabled,
          'twoWayPackageEnabled': _twoWayPackageEnabled,
          'dailyBookingEnabled': _dailyBookingEnabled,
          'monthlyPackageEnabled': _monthlyPackageEnabled,
          'routeBasedPricingEnabled': _routeBasedPricingEnabled,
          'siblingDiscountEnabled': _siblingDiscountEnabled,
          'doorToDoorEnabled': _doorToDoorEnabled,
          'waitlistEnabled': _waitlistEnabled,
          'absenceReportingEnabled': _absenceReportingEnabled,
          'temporaryRouteChangeEnabled': _temporaryRouteChangeEnabled,
          'cashEnabled': _cashEnabled,
          'walletEnabled': _walletEnabled,
          'easypaisaEnabled': _easypaisaEnabled,
          'jazzCashEnabled': _jazzCashEnabled,
          'cardPaymentEnabled': _cardPaymentEnabled,
          'defaultBillingMode': _billingMode.name,
          'monthlyBasePrice': double.parse(_monthlyBasePrice.text.trim()),
          'dailyBasePrice': double.parse(_dailyBasePrice.text.trim()),
          'routeBasePrice': double.parse(_routeBasePrice.text.trim()),
          'perKmPrice': double.parse(_perKmPrice.text.trim()),
          'morningOnlyMultiplier':
              double.parse(_morningMultiplier.text.trim()),
          'afternoonOnlyMultiplier':
              double.parse(_afternoonMultiplier.text.trim()),
          'twoWayMultiplier': double.parse(_twoWayMultiplier.text.trim()),
          'doorToDoorCharge': double.parse(_doorToDoorCharge.text.trim()),
          'registrationFee': double.parse(_registrationFee.text.trim()),
          'siblingDiscountPercent': siblingDiscount,
          'commissionType': _commissionType.name,
          'commissionValue': commission,
          'paymentDueDay': paymentDueDay,
          'paymentGraceDays': int.parse(_paymentGraceDays.text.trim()),
          'renewalReminderDays': int.parse(_renewalReminderDays.text.trim()),
          'absenceCutoffMinutes': int.parse(_absenceCutoffMinutes.text.trim()),
          'routeChangeCutoffHours':
              int.parse(_routeChangeCutoffHours.text.trim()),
          'maximumStudentsPerVehicle':
              int.parse(_maximumStudents.text.trim()),
          'disabledMessage': _disabledMessage.text.trim(),
          'currencyCode': _currencyCode.text.trim().toUpperCase(),
        },
      );
      if (mounted) _message('Student Ride settings saved successfully.');
    } catch (error) {
      if (mounted) _message(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Ride Settings')),
      body: StreamBuilder<StudentRideSettingsModel>(
        stream: _service.watchSettings(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return Center(child: Text('Unable to load settings: ${snapshot.error}'));
            }
            return const Center(child: CircularProgressIndicator());
          }

          _load(snapshot.data!);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section('Module control'),
                _toggle(
                  'Student Ride enabled',
                  'Turn the complete Student Ride module on or off remotely.',
                  _moduleEnabled,
                  (value) => _moduleEnabled = value,
                ),
                _textField(
                  _disabledMessage,
                  'Message shown when module is disabled',
                  maxLines: 2,
                ),
                _section('Service options'),
                _toggle('Morning service', null, _morningServiceEnabled,
                    (value) => _morningServiceEnabled = value),
                _toggle('Afternoon service', null, _afternoonServiceEnabled,
                    (value) => _afternoonServiceEnabled = value),
                _toggle('One-way packages', null, _oneWayPackageEnabled,
                    (value) => _oneWayPackageEnabled = value),
                _toggle('Two-way packages', null, _twoWayPackageEnabled,
                    (value) => _twoWayPackageEnabled = value),
                _toggle('Monthly packages', null, _monthlyPackageEnabled,
                    (value) => _monthlyPackageEnabled = value),
                _toggle('Daily booking', null, _dailyBookingEnabled,
                    (value) => _dailyBookingEnabled = value),
                _toggle('Route-based pricing', null, _routeBasedPricingEnabled,
                    (value) => _routeBasedPricingEnabled = value),
                _toggle('Door-to-door service', null, _doorToDoorEnabled,
                    (value) => _doorToDoorEnabled = value),
                _toggle('Sibling discount', null, _siblingDiscountEnabled,
                    (value) => _siblingDiscountEnabled = value),
                _toggle('Waiting list', null, _waitlistEnabled,
                    (value) => _waitlistEnabled = value),
                _toggle('Absence reporting', null, _absenceReportingEnabled,
                    (value) => _absenceReportingEnabled = value),
                _toggle(
                  'Temporary route changes',
                  null,
                  _temporaryRouteChangeEnabled,
                  (value) => _temporaryRouteChangeEnabled = value,
                ),
                _section('Payment methods'),
                _toggle('Cash', null, _cashEnabled,
                    (value) => _cashEnabled = value),
                _toggle('SWAT RIDE Wallet', null, _walletEnabled,
                    (value) => _walletEnabled = value),
                _toggle('Easypaisa', null, _easypaisaEnabled,
                    (value) => _easypaisaEnabled = value),
                _toggle('JazzCash', null, _jazzCashEnabled,
                    (value) => _jazzCashEnabled = value),
                _toggle('Bank cards', null, _cardPaymentEnabled,
                    (value) => _cardPaymentEnabled = value),
                _section('Pricing'),
                DropdownButtonFormField<StudentRideBillingMode>(
                  initialValue: _billingMode,
                  decoration: const InputDecoration(
                    labelText: 'Default billing mode',
                  ),
                  items: StudentRideBillingMode.values
                      .map(
                        (mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(_billingModeLabel(mode)),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) => setState(
                            () => _billingMode =
                                value ?? StudentRideBillingMode.monthly,
                          ),
                ),
                const SizedBox(height: 12),
                _numberField(_monthlyBasePrice, 'Monthly base price'),
                _numberField(_dailyBasePrice, 'Daily base price'),
                _numberField(_routeBasePrice, 'Route base price'),
                _numberField(_perKmPrice, 'Per-kilometre price'),
                _numberField(
                  _morningMultiplier,
                  'Morning-only multiplier',
                  validator: _positiveNumber,
                ),
                _numberField(
                  _afternoonMultiplier,
                  'Afternoon-only multiplier',
                  validator: _positiveNumber,
                ),
                _numberField(
                  _twoWayMultiplier,
                  'Two-way multiplier',
                  validator: _positiveNumber,
                ),
                _numberField(_doorToDoorCharge, 'Door-to-door charge'),
                _numberField(_registrationFee, 'One-time registration fee'),
                _numberField(_siblingDiscount, 'Sibling discount percentage'),
                _textField(_currencyCode, 'Currency code'),
                _section('Commission'),
                DropdownButtonFormField<StudentRideCommissionType>(
                  initialValue: _commissionType,
                  decoration: const InputDecoration(labelText: 'Commission type'),
                  items: StudentRideCommissionType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type == StudentRideCommissionType.percentage
                                ? 'Percentage'
                                : 'Fixed amount',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (value) => setState(
                            () => _commissionType = value ??
                                StudentRideCommissionType.percentage,
                          ),
                ),
                const SizedBox(height: 12),
                _numberField(_commissionValue, 'Commission value'),
                _section('Billing and operational rules'),
                _intField(_paymentDueDay, 'Monthly payment due day'),
                _intField(_paymentGraceDays, 'Payment grace days', allowZero: true),
                _intField(
                  _renewalReminderDays,
                  'Renewal reminder days',
                  allowZero: true,
                ),
                _intField(
                  _absenceCutoffMinutes,
                  'Absence reporting cutoff (minutes)',
                  allowZero: true,
                ),
                _intField(
                  _routeChangeCutoffHours,
                  'Route change cutoff (hours)',
                  allowZero: true,
                ),
                _intField(
                  _maximumStudents,
                  'Maximum students per vehicle',
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving...' : 'Save Remote Settings'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }

  Widget _toggle(
    String title,
    String? subtitle,
    bool value,
    ValueChanged<bool> assign,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value,
      onChanged: _saving
          ? null
          : (newValue) => setState(() => assign(newValue)),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'This field is required'
            : null,
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        validator: validator ?? _nonNegativeNumber,
      ),
    );
  }

  Widget _intField(
    TextEditingController controller,
    String label, {
    bool allowZero = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: allowZero
            ? (value) {
                final parsed = int.tryParse(value?.trim() ?? '');
                return parsed == null || parsed < 0
                    ? 'Enter zero or a positive whole number'
                    : null;
              }
            : _positiveInt,
      ),
    );
  }

  String _billingModeLabel(StudentRideBillingMode mode) {
    switch (mode) {
      case StudentRideBillingMode.monthly:
        return 'Monthly';
      case StudentRideBillingMode.daily:
        return 'Daily';
      case StudentRideBillingMode.routeBased:
        return 'Route based';
    }
  }
}
