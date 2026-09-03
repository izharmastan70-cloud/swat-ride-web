// lib/food/admin/screens/food_settings_screen.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Admin Food Settings Screen
//
// Firestore document:
// food_admin_settings/general_settings
//
// Real features:
// - Food module enable / disable
// - Default delivery fee
// - Service fee
// - Tax percentage
// - Default restaurant commission
// - Default rider commission
// - Minimum order amount
// - Free-delivery threshold
// - Auto-cancel timer
// - Rider assignment settings
// - Restaurant approval settings
// - Working hours
// - Customer / restaurant / rider notifications
// - Cash, wallet, JazzCash and Easypaisa controls
// - Save and reset settings
//
// Real payment gateways and paid map services remain bypassed.
// Existing non-Food modules remain untouched.
// =============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/food_service_control_model.dart';
import '../../services/food_service_control_service.dart';
import 'package:flutter/material.dart';

class FoodSettingsScreen extends StatefulWidget {
  const FoodSettingsScreen({
    super.key,
  });

  @override
  State<FoodSettingsScreen> createState() =>
      _FoodSettingsScreenState();
}

class _FoodSettingsScreenState
    extends State<FoodSettingsScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color background = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color fieldColor = Color(0xFF252525);

  static const String settingsCollection =
      'food_admin_settings';

  static const String settingsDocument =
      'general_settings';

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FoodServiceControlService
      _serviceControlService =
      FoodServiceControlService();

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _defaultDeliveryFeeController =
      TextEditingController();

  final TextEditingController _serviceFeeController =
      TextEditingController();

  final TextEditingController _taxPercentageController =
      TextEditingController();

  final TextEditingController
      _defaultRestaurantCommissionController =
      TextEditingController();

  final TextEditingController
      _defaultRiderCommissionController =
      TextEditingController();

  final TextEditingController _minimumOrderController =
      TextEditingController();

  final TextEditingController
      _freeDeliveryThresholdController =
      TextEditingController();

  final TextEditingController _autoCancelMinutesController =
      TextEditingController();

  final TextEditingController
      _riderSearchRadiusController =
      TextEditingController();

  final TextEditingController
      _maximumAssignmentAttemptsController =
      TextEditingController();

  final TextEditingController _openingTimeController =
      TextEditingController();

  final TextEditingController _closingTimeController =
      TextEditingController();

  final TextEditingController
      _maintenanceReasonController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasLoadedInitialValues = false;
  bool _foodModuleEnabled = true;
  bool _acceptNewOrders = true;
  bool _restaurantApplicationsEnabled = true;
  bool _riderApplicationsEnabled = true;

  String _superAdminOverrideMode =
      FoodServiceControlModel.overrideNone;
  bool _restaurantApprovalRequired = true;
  bool _riderApprovalRequired = true;
  bool _autoAssignRider = true;
  bool _allowManualRiderAssignment = true;
  bool _allowRestaurantSelfDelivery = false;
  bool _allowScheduledOrders = true;
  bool _allowOrderCancellation = true;
  bool _allowCashPayment = true;
  bool _allowWalletPayment = true;
  bool _allowJazzCashPayment = false;
  bool _allowEasypaisaPayment = false;
  bool _notifyCustomer = true;
  bool _notifyRestaurant = true;
  bool _notifyRider = true;
  bool _notifyAdmin = true;
  bool _acceptOrdersOutsideWorkingHours = false;
  bool _surgePricingEnabled = false;
  bool _maintenanceMode = false;

  Set<int> _openDays = <int>{
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  };

  DocumentReference<Map<String, dynamic>>
      get _settingsRef => _firestore
          .collection(settingsCollection)
          .doc(settingsDocument);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _defaultDeliveryFeeController.dispose();
    _serviceFeeController.dispose();
    _taxPercentageController.dispose();
    _defaultRestaurantCommissionController.dispose();
    _defaultRiderCommissionController.dispose();
    _minimumOrderController.dispose();
    _freeDeliveryThresholdController.dispose();
    _autoCancelMinutesController.dispose();
    _riderSearchRadiusController.dispose();
    _maximumAssignmentAttemptsController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    _maintenanceReasonController.dispose();
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

  Future<void> _loadSettings() async {
    if (_hasLoadedInitialValues) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await _settingsRef.get();

      final Map<String, dynamic> settingsData =
          snapshot.data() ??
              const <String, dynamic>{};

      final _FoodAdminSettings settings =
          snapshot.exists
              ? _FoodAdminSettings.fromMap(
                  settingsData,
                )
              : _FoodAdminSettings.defaults();

      final FoodServiceControlModel control =
          snapshot.exists
              ? FoodServiceControlModel.fromMap(
                  settingsData,
                )
              : FoodServiceControlModel.defaults();

      _applySettings(settings);

      _foodModuleEnabled =
          control.foodServiceEnabled;
      _acceptNewOrders =
          control.acceptNewOrders;
      _restaurantApplicationsEnabled =
          control.restaurantApplicationsEnabled;
      _riderApplicationsEnabled =
          control.riderApplicationsEnabled;
      _maintenanceMode =
          control.maintenanceMode;
      _maintenanceReasonController.text =
          control.maintenanceReason;
      _superAdminOverrideMode =
          control.superAdminOverrideMode;

      _hasLoadedInitialValues = true;
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ??
            'Unable to load Food settings.',
      );

      _applySettings(
        _FoodAdminSettings.defaults(),
      );
    } catch (error) {
      _showMessage(
        'Unable to load Food settings: $error',
      );

      _applySettings(
        _FoodAdminSettings.defaults(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applySettings(
    _FoodAdminSettings settings,
  ) {
    _defaultDeliveryFeeController.text =
        settings.defaultDeliveryFee
            .toStringAsFixed(0);

    _serviceFeeController.text =
        settings.serviceFee.toStringAsFixed(0);

    _taxPercentageController.text =
        settings.taxPercentage.toStringAsFixed(1);

    _defaultRestaurantCommissionController.text =
        settings.defaultRestaurantCommission
            .toStringAsFixed(1);

    _defaultRiderCommissionController.text =
        settings.defaultRiderCommission
            .toStringAsFixed(1);

    _minimumOrderController.text =
        settings.minimumOrderAmount
            .toStringAsFixed(0);

    _freeDeliveryThresholdController.text =
        settings.freeDeliveryThreshold
            .toStringAsFixed(0);

    _autoCancelMinutesController.text =
        '${settings.autoCancelMinutes}';

    _riderSearchRadiusController.text =
        settings.riderSearchRadiusKm
            .toStringAsFixed(1);

    _maximumAssignmentAttemptsController.text =
        '${settings.maximumAssignmentAttempts}';

    _openingTimeController.text =
        settings.openingTime;

    _closingTimeController.text =
        settings.closingTime;

    _foodModuleEnabled =
        settings.foodModuleEnabled;

    _restaurantApprovalRequired =
        settings.restaurantApprovalRequired;

    _riderApprovalRequired =
        settings.riderApprovalRequired;

    _autoAssignRider =
        settings.autoAssignRider;

    _allowManualRiderAssignment =
        settings.allowManualRiderAssignment;

    _allowRestaurantSelfDelivery =
        settings.allowRestaurantSelfDelivery;

    _allowScheduledOrders =
        settings.allowScheduledOrders;

    _allowOrderCancellation =
        settings.allowOrderCancellation;

    _allowCashPayment =
        settings.allowCashPayment;

    _allowWalletPayment =
        settings.allowWalletPayment;

    _allowJazzCashPayment =
        settings.allowJazzCashPayment;

    _allowEasypaisaPayment =
        settings.allowEasypaisaPayment;

    _notifyCustomer =
        settings.notifyCustomer;

    _notifyRestaurant =
        settings.notifyRestaurant;

    _notifyRider =
        settings.notifyRider;

    _notifyAdmin =
        settings.notifyAdmin;

    _acceptOrdersOutsideWorkingHours =
        settings.acceptOrdersOutsideWorkingHours;

    _surgePricingEnabled =
        settings.surgePricingEnabled;

    _maintenanceMode =
        settings.maintenanceMode;

    _openDays =
        Set<int>.from(settings.openDays);
  }

  Future<void> _saveSettings() async {
    if (_isSaving) {
      return;
    }

    final bool valid =
        _formKey.currentState?.validate() ?? false;

    if (!valid) {
      _showMessage(
        'Please correct the highlighted fields.',
      );
      return;
    }

    if (_openDays.isEmpty) {
      _showMessage(
        'Select at least one working day.',
      );
      return;
    }

    if (!_allowCashPayment &&
        !_allowWalletPayment &&
        !_allowJazzCashPayment &&
        !_allowEasypaisaPayment) {
      _showMessage(
        'Enable at least one payment method.',
      );
      return;
    }

    if ((!_foodModuleEnabled ||
            !_acceptNewOrders ||
            _maintenanceMode) &&
        _maintenanceReasonController.text
            .trim()
            .isEmpty) {
      _showMessage(
        'Enter a customer-facing reason before disabling Food service or new orders.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final DateTime now = DateTime.now();

      final User? currentUser =
          _auth.currentUser;

      String currentRole = 'admin';

      if (currentUser != null) {
        final IdTokenResult token =
            await currentUser.getIdTokenResult();

        final String claimRole =
            token.claims?['role']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        if (claimRole == 'super_admin') {
          currentRole = 'super_admin';
        }
      }

      final FoodServiceControlModel control =
          FoodServiceControlModel(
        foodServiceEnabled:
            _foodModuleEnabled,
        acceptNewOrders:
            _acceptNewOrders,
        restaurantApplicationsEnabled:
            _restaurantApplicationsEnabled,
        riderApplicationsEnabled:
            _riderApplicationsEnabled,
        maintenanceMode:
            _maintenanceMode,
        maintenanceReason:
            _maintenanceReasonController.text.trim(),
        superAdminOverrideMode:
            _superAdminOverrideMode,
        updatedBy:
            currentUser?.uid ??
                'testing-food-admin',
        updatedByRole: currentRole,
        updatedAt: now,
      );

      final _FoodAdminSettings settings =
          _FoodAdminSettings(
        foodModuleEnabled: _foodModuleEnabled,
        defaultDeliveryFee:
            _parseDouble(
          _defaultDeliveryFeeController,
        ),
        serviceFee:
            _parseDouble(_serviceFeeController),
        taxPercentage:
            _parseDouble(
          _taxPercentageController,
        ),
        defaultRestaurantCommission:
            _parseDouble(
          _defaultRestaurantCommissionController,
        ),
        defaultRiderCommission:
            _parseDouble(
          _defaultRiderCommissionController,
        ),
        minimumOrderAmount:
            _parseDouble(
          _minimumOrderController,
        ),
        freeDeliveryThreshold:
            _parseDouble(
          _freeDeliveryThresholdController,
        ),
        autoCancelMinutes:
            _parseInt(
          _autoCancelMinutesController,
        ),
        riderSearchRadiusKm:
            _parseDouble(
          _riderSearchRadiusController,
        ),
        maximumAssignmentAttempts:
            _parseInt(
          _maximumAssignmentAttemptsController,
        ),
        restaurantApprovalRequired:
            _restaurantApprovalRequired,
        riderApprovalRequired:
            _riderApprovalRequired,
        autoAssignRider:
            _autoAssignRider,
        allowManualRiderAssignment:
            _allowManualRiderAssignment,
        allowRestaurantSelfDelivery:
            _allowRestaurantSelfDelivery,
        allowScheduledOrders:
            _allowScheduledOrders,
        allowOrderCancellation:
            _allowOrderCancellation,
        allowCashPayment:
            _allowCashPayment,
        allowWalletPayment:
            _allowWalletPayment,
        allowJazzCashPayment:
            _allowJazzCashPayment,
        allowEasypaisaPayment:
            _allowEasypaisaPayment,
        notifyCustomer:
            _notifyCustomer,
        notifyRestaurant:
            _notifyRestaurant,
        notifyRider:
            _notifyRider,
        notifyAdmin:
            _notifyAdmin,
        openingTime:
            _openingTimeController.text.trim(),
        closingTime:
            _closingTimeController.text.trim(),
        openDays:
            _openDays.toList()..sort(),
        acceptOrdersOutsideWorkingHours:
            _acceptOrdersOutsideWorkingHours,
        surgePricingEnabled:
            _surgePricingEnabled,
        maintenanceMode:
            _maintenanceMode,
        createdAt: now,
        updatedAt: now,
      );

      await _settingsRef.set(
        settings.toMap(),
        SetOptions(merge: true),
      );

      await _serviceControlService.saveControl(
        control: control,
        updatedBy: control.updatedBy,
        updatedByRole: control.updatedByRole,
      );

      _showMessage(
        'Food settings saved successfully.',
      );
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ??
            'Unable to save Food settings.',
      );
    } catch (error) {
      _showMessage(
        'Unable to save Food settings: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _resetSettings() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: const Text(
            'Reset Food Settings?',
          ),
          content: const Text(
            'All Food Admin settings will return to the default configuration.',
            style: TextStyle(
              color: Colors.grey,
              height: 1.45,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final _FoodAdminSettings defaults =
          _FoodAdminSettings.defaults();

      await _settingsRef.set(
        defaults.toMap(),
      );

      _applySettings(defaults);

      if (mounted) {
        setState(() {});
      }

      _showMessage(
        'Food settings reset to defaults.',
      );
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ??
            'Unable to reset Food settings.',
      );
    } catch (error) {
      _showMessage(
        'Unable to reset Food settings: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  double _parseDouble(
    TextEditingController controller,
  ) {
    return double.tryParse(
          controller.text.trim(),
        ) ??
        0;
  }

  int _parseInt(
    TextEditingController controller,
  ) {
    return int.tryParse(
          controller.text.trim(),
        ) ??
        0;
  }

  Future<void> _pickTime(
    TextEditingController controller,
  ) async {
    final TimeOfDay initialTime =
        _parseTime(controller.text.trim()) ??
            TimeOfDay.now();

    final TimeOfDay? selected =
        await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selected == null) {
      return;
    }

    controller.text =
        '${selected.hour.toString().padLeft(2, '0')}:'
        '${selected.minute.toString().padLeft(2, '0')}';

    if (mounted) {
      setState(() {});
    }
  }

  TimeOfDay? _parseTime(String value) {
    final List<String> parts =
        value.split(':');

    if (parts.length != 2) {
      return null;
    }

    final int? hour =
        int.tryParse(parts[0]);

    final int? minute =
        int.tryParse(parts[1]);

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  String? _validateAmount(
    String? value, {
    double max = 1000000,
  }) {
    final double? parsed =
        double.tryParse(value?.trim() ?? '');

    if (parsed == null) {
      return 'Enter a valid number';
    }

    if (parsed < 0 || parsed > max) {
      return 'Enter value between 0 and $max';
    }

    return null;
  }

  String? _validatePercentage(
    String? value,
  ) {
    return _validateAmount(
      value,
      max: 100,
    );
  }

  String? _validatePositiveInteger(
    String? value, {
    int max = 100000,
  }) {
    final int? parsed =
        int.tryParse(value?.trim() ?? '');

    if (parsed == null) {
      return 'Enter a whole number';
    }

    if (parsed < 0 || parsed > max) {
      return 'Enter value between 0 and $max';
    }

    return null;
  }

  String? _validateTime(
    String? value,
  ) {
    if (_parseTime(
          value?.trim() ?? '',
        ) ==
        null) {
      return 'Use HH:mm format';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: const Text(
          'Food Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reset settings',
            onPressed:
                _isSaving ? null : _resetSettings,
            icon: const Icon(
              Icons.restart_alt,
            ),
          ),
        ],
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
                    14,
                    16,
                    110,
                  ),
                  children: <Widget>[
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildModuleControls(),
                    const SizedBox(height: 16),
                    _buildPricingSettings(),
                    const SizedBox(height: 16),
                    _buildCommissionSettings(),
                    const SizedBox(height: 16),
                    _buildOrderSettings(),
                    const SizedBox(height: 16),
                    _buildRiderAssignmentSettings(),
                    const SizedBox(height: 16),
                    _buildApprovalSettings(),
                    const SizedBox(height: 16),
                    _buildWorkingHoursSettings(),
                    const SizedBox(height: 16),
                    _buildPaymentSettings(),
                    const SizedBox(height: 16),
                    _buildNotificationSettings(),
                    const SizedBox(height: 16),
                    _buildAdvancedSettings(),
                    const SizedBox(height: 20),
                    _buildSaveButtons(),
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
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.black,
            child: Icon(
              Icons.settings_outlined,
              color: yellow,
              size: 35,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Food Module Configuration',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _maintenanceMode
                      ? 'Food module is currently in maintenance mode.'
                      : _foodModuleEnabled
                          ? 'Food delivery is enabled and available.'
                          : 'Food delivery is currently disabled.',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
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

  Widget _buildModuleControls() {
    final bool hasSuperAdminOverride =
        _superAdminOverrideMode !=
            FoodServiceControlModel.overrideNone;

    return _settingsCard(
      title: 'Global Food Service Control',
      icon: Icons.power_settings_new,
      children: <Widget>[
        if (hasSuperAdminOverride) ...<Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: yellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: yellow.withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              _superAdminOverrideMode ==
                      FoodServiceControlModel
                          .overrideForceEnabled
                  ? 'Super Admin override: Food service forced ON.'
                  : 'Super Admin override: Food service forced OFF.',
              style: const TextStyle(
                color: yellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        _settingsSwitch(
          title: 'Food Service ON/OFF',
          subtitle:
              'Master control for Food customers, restaurants and riders. Active orders continue normally.',
          value: _foodModuleEnabled,
          warning: !_foodModuleEnabled,
          onChanged: (bool value) {
            setState(() {
              _foodModuleEnabled = value;
            });
          },
        ),
        const Divider(color: Colors.white12),
        _settingsSwitch(
          title: 'Accept New Orders',
          subtitle:
              'Turn this off to stop only new orders. Existing active orders are not terminated.',
          value: _acceptNewOrders,
          warning: !_acceptNewOrders,
          onChanged: (bool value) {
            setState(() {
              _acceptNewOrders = value;
            });
          },
        ),
        const Divider(color: Colors.white12),
        _settingsSwitch(
          title: 'Restaurant Applications',
          subtitle:
              'Allow new Restaurant Partner applications.',
          value: _restaurantApplicationsEnabled,
          onChanged: (bool value) {
            setState(() {
              _restaurantApplicationsEnabled = value;
            });
          },
        ),
        const Divider(color: Colors.white12),
        _settingsSwitch(
          title: 'Food Rider Applications',
          subtitle:
              'Allow new Food Delivery Rider applications.',
          value: _riderApplicationsEnabled,
          onChanged: (bool value) {
            setState(() {
              _riderApplicationsEnabled = value;
            });
          },
        ),
        const Divider(color: Colors.white12),
        _settingsSwitch(
          title: 'Maintenance Mode',
          subtitle:
              'Temporarily block new orders and new applications without ending active orders.',
          value: _maintenanceMode,
          warning: true,
          onChanged: (bool value) {
            setState(() {
              _maintenanceMode = value;
            });
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _maintenanceReasonController,
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(
            color: Colors.white,
          ),
          decoration: InputDecoration(
            labelText: 'Customer-facing reason',
            hintText:
                'Example: Food service is temporarily unavailable for maintenance.',
            labelStyle: const TextStyle(
              color: Colors.white70,
            ),
            hintStyle: const TextStyle(
              color: Colors.white38,
            ),
            filled: true,
            fillColor: fieldColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (String? value) {
            if ((!_foodModuleEnabled ||
                    !_acceptNewOrders ||
                    _maintenanceMode) &&
                (value?.trim().isEmpty ?? true)) {
              return 'Reason is required while service or new orders are unavailable';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPricingSettings() {
    return _settingsCard(
      title: 'Pricing Settings',
      icon: Icons.payments_outlined,
      children: <Widget>[
        _numberInput(
          controller:
              _defaultDeliveryFeeController,
          label: 'Default delivery fee',
          suffix: 'Rs.',
          validator: _validateAmount,
        ),
        const SizedBox(height: 12),
        _numberInput(
          controller: _serviceFeeController,
          label: 'Customer service fee',
          suffix: 'Rs.',
          validator: _validateAmount,
        ),
        const SizedBox(height: 12),
        _numberInput(
          controller:
              _taxPercentageController,
          label: 'Tax / VAT percentage',
          suffix: '%',
          validator: _validatePercentage,
        ),
        const SizedBox(height: 12),
        _numberInput(
          controller:
              _minimumOrderController,
          label: 'Minimum order amount',
          suffix: 'Rs.',
          validator: _validateAmount,
        ),
        const SizedBox(height: 12),
        _numberInput(
          controller:
              _freeDeliveryThresholdController,
          label:
              'Free delivery threshold (0 = disabled)',
          suffix: 'Rs.',
          validator: _validateAmount,
        ),
      ],
    );
  }

  Widget _buildCommissionSettings() {
    return _settingsCard(
      title: 'Default Commissions',
      icon: Icons.percent,
      children: <Widget>[
        _numberInput(
          controller:
              _defaultRestaurantCommissionController,
          label:
              'Default restaurant commission',
          suffix: '%',
          validator: _validatePercentage,
        ),
        const SizedBox(height: 12),
        _numberInput(
          controller:
              _defaultRiderCommissionController,
          label: 'Default rider commission',
          suffix: '%',
          validator: _validatePercentage,
        ),
        const SizedBox(height: 10),
        const Text(
          'Individual restaurant and rider commission rates can still be changed from Commission Management.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSettings() {
    return _settingsCard(
      title: 'Order Settings',
      icon: Icons.receipt_long_outlined,
      children: <Widget>[
        _numberInput(
          controller:
              _autoCancelMinutesController,
          label:
              'Auto-cancel pending order after',
          suffix: 'minutes',
          integerOnly: true,
          validator: (
            String? value,
          ) =>
              _validatePositiveInteger(
            value,
            max: 1440,
          ),
        ),
        const SizedBox(height: 8),
        _settingsSwitch(
          title: 'Allow Scheduled Orders',
          subtitle:
              'Customers can place Food orders for a later time.',
          value: _allowScheduledOrders,
          onChanged: (bool value) {
            setState(() {
              _allowScheduledOrders = value;
            });
          },
        ),
        const Divider(color: Colors.white12),
        _settingsSwitch(
          title: 'Allow Customer Cancellation',
          subtitle:
              'Permit customers to cancel eligible Food orders.',
          value: _allowOrderCancellation,
          onChanged: (bool value) {
            setState(() {
              _allowOrderCancellation = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildRiderAssignmentSettings() {
    return _settingsCard(
      title: 'Rider Assignment',
      icon: Icons.delivery_dining,
      children: <Widget>[
        _numberInput(
          controller:
              _riderSearchRadiusController,
          label: 'Rider search radius',
          suffix: 'km',
          validator: (
            String? value,
          ) =>
              _validateAmount(
            value,
            max: 100,
          ),
        ),
        const SizedBox(height: 12),
        _numberInput(
          controller:
              _maximumAssignmentAttemptsController,
          label:
              'Maximum rider assignment attempts',
          suffix: 'attempts',
          integerOnly: true,
          validator: (
            String? value,
          ) =>
              _validatePositiveInteger(
            value,
            max: 100,
          ),
        ),
        const SizedBox(height: 8),
        _settingsSwitch(
          title: 'Automatic Rider Assignment',
          subtitle:
              'Automatically offer ready orders to available Food Riders.',
          value: _autoAssignRider,
          onChanged: (bool value) {
            setState(() {
              _autoAssignRider = value;
            });
          },
        ),
        const Divider(color: Colors.white12),
        _settingsSwitch(
          title: 'Allow Manual Assignment',
          subtitle:
              'Admin can manually assign a rider to an order.',
          value:
              _allowManualRiderAssignment,
          onChanged: (bool value) {
            setState(() {
              _allowManualRiderAssignment =
                  value;
            });
          },
        ),
        const Divider(color: Colors.white12),
        _settingsSwitch(
          title: 'Restaurant Self Delivery',
          subtitle:
              'Approved restaurants may use their own delivery staff.',
          value:
              _allowRestaurantSelfDelivery,
          onChanged: (bool value) {
            setState(() {
              _allowRestaurantSelfDelivery =
                  value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildApprovalSettings() {
    return _settingsCard(
      title: 'Approval Settings',
      icon: Icons.verified_user_outlined,
      children: <Widget>[
        _settingsSwitch(
          title: 'Restaurant Approval Required',
          subtitle:
              'Restaurant applications require admin approval before activation.',
          value:
              _restaurantApprovalRequired,
          onChanged: (bool value) {
            setState(() {
              _restaurantApprovalRequired =
                  value;
            });
          },
        ),
        const Divider(color: Colors.white12),
        _settingsSwitch(
          title: 'Food Rider Approval Required',
          subtitle:
              'Food Rider applications require admin approval before dashboard access.',
          value: _riderApprovalRequired,
          onChanged: (bool value) {
            setState(() {
              _riderApprovalRequired = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildWorkingHoursSettings() {
    return _settingsCard(
      title: 'Working Hours',
      icon: Icons.schedule,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _timeInput(
                controller:
                    _openingTimeController,
                label: 'Opening time',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _timeInput(
                controller:
                    _closingTimeController,
                label: 'Closing time',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Working Days',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List<Widget>.generate(
            7,
            (int index) {
              final int day = index + 1;
              final bool selected =
                  _openDays.contains(day);

              return FilterChip(
                label: Text(
                  _dayLabel(day),
                ),
                selected: selected,
                onSelected: (bool value) {
                  setState(() {
                    if (value) {
                      _openDays.add(day);
                    } else {
                      _openDays.remove(day);
                    }
                  });
                },
                selectedColor: yellow,
                backgroundColor: fieldColor,
                checkmarkColor: Colors.black,
                labelStyle: TextStyle(
                  color: selected
                      ? Colors.black
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide.none,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _settingsSwitch(
          title: 'Accept Orders Outside Hours',
          subtitle:
              'Allow customers to place orders even when Food service is closed.',
          value:
              _acceptOrdersOutsideWorkingHours,
          onChanged: (bool value) {
            setState(() {
              _acceptOrdersOutsideWorkingHours =
                  value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPaymentSettings() {
    return _settingsCard(
      title: 'Payment Methods',
      icon: Icons.payment,
      children: <Widget>[
        _settingsSwitch(
          title: 'Cash Payment',
          subtitle:
              'Allow cash payment on Food delivery.',
          value: _allowCashPayment,
          onChanged: (bool value) {
            setState(() {
              _allowCashPayment = value;
            });
          },
        ),
        const Divider(color: Colors.white12),
        _settingsSwitch(
          title: 'SWAT RIDE Wallet',
          subtitle:
              'Allow customers to pay from their in-app wallet.',
          value: _allowWalletPayment,
          onChanged: (bool value) {
            setState(() {
              _allowWalletPayment = value;
            });
          },
        ),
        const Divider(color: Colors.white12),
        _settingsSwitch(
          title: 'JazzCash',
          subtitle:
              'Payment execution remains bypassed until gateway integration.',
          value: _allowJazzCashPayment,
          onChanged: (bool value) {
            setState(() {
              _allowJazzCashPayment = value;
            });
          },
        ),
        const Divider(color: Colors.white12),
        _settingsSwitch(
          title: 'Easypaisa',
          subtitle:
              'Payment execution remains bypassed until gateway integration.',
          value: _allowEasypaisaPayment,
          onChanged: (bool value) {
            setState(() {
              _allowEasypaisaPayment = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return _settingsCard(
      title: 'Notification Settings',
      icon: Icons.notifications_outlined,
      children: <Widget>[
        _settingsSwitch(
          title: 'Customer Notifications',
          subtitle:
              'Order status, rider and delivery alerts.',
          value: _notifyCustomer,
          onChanged: (bool value) {
            setState(() {
              _notifyCustomer = value;
            });
          },
        ),
        const Divider(color: Colors.white12),
        _settingsSwitch(
          title: 'Restaurant Notifications',
          subtitle:
              'New order, cancellation and admin alerts.',
          value: _notifyRestaurant,
          onChanged: (bool value) {
            setState(() {
              _notifyRestaurant = value;
            });
          },
        ),
        const Divider(color: Colors.white12),
        _settingsSwitch(
          title: 'Rider Notifications',
          subtitle:
              'Pickup requests, delivery updates and earnings alerts.',
          value: _notifyRider,
          onChanged: (bool value) {
            setState(() {
              _notifyRider = value;
            });
          },
        ),
        const Divider(color: Colors.white12),
        _settingsSwitch(
          title: 'Admin Notifications',
          subtitle:
              'Pending approvals, incidents and system alerts.',
          value: _notifyAdmin,
          onChanged: (bool value) {
            setState(() {
              _notifyAdmin = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return _settingsCard(
      title: 'Advanced Controls',
      icon: Icons.tune,
      children: <Widget>[
        _settingsSwitch(
          title: 'Surge Pricing',
          subtitle:
              'Allow dynamic Food delivery pricing during high demand.',
          value: _surgePricingEnabled,
          onChanged: (bool value) {
            setState(() {
              _surgePricingEnabled = value;
            });
          },
        ),
        const SizedBox(height: 10),
        const Text(
          'Dynamic surge multipliers should be managed by the centralized pricing service. This switch only enables or disables Food surge pricing.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButtons() {
    return Column(
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed:
                _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.save_outlined,
                  ),
            label: Text(
              _isSaving
                  ? 'Saving Settings...'
                  : 'Save Food Settings',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: yellow,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed:
                _isSaving ? null : _resetSettings,
            icon: const Icon(
              Icons.restart_alt,
            ),
            label: const Text(
              'Reset to Defaults',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  Colors.redAccent,
              side: const BorderSide(
                color: Colors.redAccent,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _settingsCard({
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _settingsSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool warning = false,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeThumbColor:
          warning ? Colors.redAccent : yellow,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _numberInput({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required String? Function(String?) validator,
    bool integerOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType:
          TextInputType.numberWithOptions(
        decimal: !integerOnly,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
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
      ),
    );
  }

  Widget _timeInput({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      validator: _validateTime,
      readOnly: true,
      onTap: () => _pickTime(controller),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(
          Icons.schedule,
          color: yellow,
        ),
        filled: true,
        fillColor: fieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  String _dayLabel(int day) {
    switch (day) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '$day';
    }
  }
}

class _FoodAdminSettings {
  const _FoodAdminSettings({
    required this.foodModuleEnabled,
    required this.defaultDeliveryFee,
    required this.serviceFee,
    required this.taxPercentage,
    required this.defaultRestaurantCommission,
    required this.defaultRiderCommission,
    required this.minimumOrderAmount,
    required this.freeDeliveryThreshold,
    required this.autoCancelMinutes,
    required this.riderSearchRadiusKm,
    required this.maximumAssignmentAttempts,
    required this.restaurantApprovalRequired,
    required this.riderApprovalRequired,
    required this.autoAssignRider,
    required this.allowManualRiderAssignment,
    required this.allowRestaurantSelfDelivery,
    required this.allowScheduledOrders,
    required this.allowOrderCancellation,
    required this.allowCashPayment,
    required this.allowWalletPayment,
    required this.allowJazzCashPayment,
    required this.allowEasypaisaPayment,
    required this.notifyCustomer,
    required this.notifyRestaurant,
    required this.notifyRider,
    required this.notifyAdmin,
    required this.openingTime,
    required this.closingTime,
    required this.openDays,
    required this.acceptOrdersOutsideWorkingHours,
    required this.surgePricingEnabled,
    required this.maintenanceMode,
    required this.createdAt,
    required this.updatedAt,
  });

  final bool foodModuleEnabled;
  final double defaultDeliveryFee;
  final double serviceFee;
  final double taxPercentage;
  final double defaultRestaurantCommission;
  final double defaultRiderCommission;
  final double minimumOrderAmount;
  final double freeDeliveryThreshold;
  final int autoCancelMinutes;
  final double riderSearchRadiusKm;
  final int maximumAssignmentAttempts;
  final bool restaurantApprovalRequired;
  final bool riderApprovalRequired;
  final bool autoAssignRider;
  final bool allowManualRiderAssignment;
  final bool allowRestaurantSelfDelivery;
  final bool allowScheduledOrders;
  final bool allowOrderCancellation;
  final bool allowCashPayment;
  final bool allowWalletPayment;
  final bool allowJazzCashPayment;
  final bool allowEasypaisaPayment;
  final bool notifyCustomer;
  final bool notifyRestaurant;
  final bool notifyRider;
  final bool notifyAdmin;
  final String openingTime;
  final String closingTime;
  final List<int> openDays;
  final bool acceptOrdersOutsideWorkingHours;
  final bool surgePricingEnabled;
  final bool maintenanceMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory _FoodAdminSettings.defaults() {
    final DateTime now = DateTime.now();

    return _FoodAdminSettings(
      foodModuleEnabled: true,
      defaultDeliveryFee: 100,
      serviceFee: 20,
      taxPercentage: 0,
      defaultRestaurantCommission: 15,
      defaultRiderCommission: 10,
      minimumOrderAmount: 0,
      freeDeliveryThreshold: 0,
      autoCancelMinutes: 15,
      riderSearchRadiusKm: 10,
      maximumAssignmentAttempts: 5,
      restaurantApprovalRequired: true,
      riderApprovalRequired: true,
      autoAssignRider: true,
      allowManualRiderAssignment: true,
      allowRestaurantSelfDelivery: false,
      allowScheduledOrders: true,
      allowOrderCancellation: true,
      allowCashPayment: true,
      allowWalletPayment: true,
      allowJazzCashPayment: false,
      allowEasypaisaPayment: false,
      notifyCustomer: true,
      notifyRestaurant: true,
      notifyRider: true,
      notifyAdmin: true,
      openingTime: '09:00',
      closingTime: '23:00',
      openDays: const <int>[
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
        DateTime.sunday,
      ],
      acceptOrdersOutsideWorkingHours: false,
      surgePricingEnabled: false,
      maintenanceMode: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory _FoodAdminSettings.fromMap(
    Map<String, dynamic> map,
  ) {
    final _FoodAdminSettings defaults =
        _FoodAdminSettings.defaults();

    return _FoodAdminSettings(
      foodModuleEnabled: _boolValue(
        map['foodModuleEnabled'],
        fallback: defaults.foodModuleEnabled,
      ),
      defaultDeliveryFee: _doubleValue(
        map['defaultDeliveryFee'],
        fallback: defaults.defaultDeliveryFee,
      ),
      serviceFee: _doubleValue(
        map['serviceFee'],
        fallback: defaults.serviceFee,
      ),
      taxPercentage: _doubleValue(
        map['taxPercentage'],
        fallback: defaults.taxPercentage,
      ),
      defaultRestaurantCommission:
          _doubleValue(
        map['defaultRestaurantCommission'],
        fallback:
            defaults.defaultRestaurantCommission,
      ),
      defaultRiderCommission:
          _doubleValue(
        map['defaultRiderCommission'],
        fallback:
            defaults.defaultRiderCommission,
      ),
      minimumOrderAmount: _doubleValue(
        map['minimumOrderAmount'],
        fallback: defaults.minimumOrderAmount,
      ),
      freeDeliveryThreshold:
          _doubleValue(
        map['freeDeliveryThreshold'],
        fallback:
            defaults.freeDeliveryThreshold,
      ),
      autoCancelMinutes: _intValue(
        map['autoCancelMinutes'],
        fallback: defaults.autoCancelMinutes,
      ),
      riderSearchRadiusKm: _doubleValue(
        map['riderSearchRadiusKm'],
        fallback:
            defaults.riderSearchRadiusKm,
      ),
      maximumAssignmentAttempts:
          _intValue(
        map['maximumAssignmentAttempts'],
        fallback:
            defaults.maximumAssignmentAttempts,
      ),
      restaurantApprovalRequired:
          _boolValue(
        map['restaurantApprovalRequired'],
        fallback:
            defaults.restaurantApprovalRequired,
      ),
      riderApprovalRequired:
          _boolValue(
        map['riderApprovalRequired'],
        fallback:
            defaults.riderApprovalRequired,
      ),
      autoAssignRider: _boolValue(
        map['autoAssignRider'],
        fallback: defaults.autoAssignRider,
      ),
      allowManualRiderAssignment:
          _boolValue(
        map['allowManualRiderAssignment'],
        fallback:
            defaults.allowManualRiderAssignment,
      ),
      allowRestaurantSelfDelivery:
          _boolValue(
        map['allowRestaurantSelfDelivery'],
        fallback:
            defaults.allowRestaurantSelfDelivery,
      ),
      allowScheduledOrders: _boolValue(
        map['allowScheduledOrders'],
        fallback:
            defaults.allowScheduledOrders,
      ),
      allowOrderCancellation:
          _boolValue(
        map['allowOrderCancellation'],
        fallback:
            defaults.allowOrderCancellation,
      ),
      allowCashPayment: _boolValue(
        map['allowCashPayment'],
        fallback: defaults.allowCashPayment,
      ),
      allowWalletPayment: _boolValue(
        map['allowWalletPayment'],
        fallback: defaults.allowWalletPayment,
      ),
      allowJazzCashPayment: _boolValue(
        map['allowJazzCashPayment'],
        fallback:
            defaults.allowJazzCashPayment,
      ),
      allowEasypaisaPayment:
          _boolValue(
        map['allowEasypaisaPayment'],
        fallback:
            defaults.allowEasypaisaPayment,
      ),
      notifyCustomer: _boolValue(
        map['notifyCustomer'],
        fallback: defaults.notifyCustomer,
      ),
      notifyRestaurant: _boolValue(
        map['notifyRestaurant'],
        fallback: defaults.notifyRestaurant,
      ),
      notifyRider: _boolValue(
        map['notifyRider'],
        fallback: defaults.notifyRider,
      ),
      notifyAdmin: _boolValue(
        map['notifyAdmin'],
        fallback: defaults.notifyAdmin,
      ),
      openingTime: _stringValue(
        map['openingTime'],
        fallback: defaults.openingTime,
      ),
      closingTime: _stringValue(
        map['closingTime'],
        fallback: defaults.closingTime,
      ),
      openDays: _intListValue(
        map['openDays'],
        fallback: defaults.openDays,
      ),
      acceptOrdersOutsideWorkingHours:
          _boolValue(
        map['acceptOrdersOutsideWorkingHours'],
        fallback: defaults
            .acceptOrdersOutsideWorkingHours,
      ),
      surgePricingEnabled: _boolValue(
        map['surgePricingEnabled'],
        fallback:
            defaults.surgePricingEnabled,
      ),
      maintenanceMode: _boolValue(
        map['maintenanceMode'],
        fallback: defaults.maintenanceMode,
      ),
      createdAt: _dateTimeValue(
            map['createdAt'],
          ) ??
          defaults.createdAt,
      updatedAt: _dateTimeValue(
            map['updatedAt'],
          ) ??
          defaults.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'foodModuleEnabled': foodModuleEnabled,
      'defaultDeliveryFee':
          defaultDeliveryFee,
      'serviceFee': serviceFee,
      'taxPercentage': taxPercentage,
      'defaultRestaurantCommission':
          defaultRestaurantCommission,
      'defaultRiderCommission':
          defaultRiderCommission,
      'minimumOrderAmount':
          minimumOrderAmount,
      'freeDeliveryThreshold':
          freeDeliveryThreshold,
      'autoCancelMinutes':
          autoCancelMinutes,
      'riderSearchRadiusKm':
          riderSearchRadiusKm,
      'maximumAssignmentAttempts':
          maximumAssignmentAttempts,
      'restaurantApprovalRequired':
          restaurantApprovalRequired,
      'riderApprovalRequired':
          riderApprovalRequired,
      'autoAssignRider': autoAssignRider,
      'allowManualRiderAssignment':
          allowManualRiderAssignment,
      'allowRestaurantSelfDelivery':
          allowRestaurantSelfDelivery,
      'allowScheduledOrders':
          allowScheduledOrders,
      'allowOrderCancellation':
          allowOrderCancellation,
      'allowCashPayment':
          allowCashPayment,
      'allowWalletPayment':
          allowWalletPayment,
      'allowJazzCashPayment':
          allowJazzCashPayment,
      'allowEasypaisaPayment':
          allowEasypaisaPayment,
      'notifyCustomer': notifyCustomer,
      'notifyRestaurant': notifyRestaurant,
      'notifyRider': notifyRider,
      'notifyAdmin': notifyAdmin,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'openDays': openDays,
      'acceptOrdersOutsideWorkingHours':
          acceptOrdersOutsideWorkingHours,
      'surgePricingEnabled':
          surgePricingEnabled,
      'maintenanceMode': maintenanceMode,
      'createdAt':
          createdAt.toIso8601String(),
      'updatedAt':
          updatedAt.toIso8601String(),
    };
  }

  static String _stringValue(
    dynamic value, {
    required String fallback,
  }) {
    final String text =
        value?.toString().trim() ?? '';

    return text.isEmpty ? fallback : text;
  }

  static double _doubleValue(
    dynamic value, {
    required double fallback,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  static int _intValue(
    dynamic value, {
    required int fallback,
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

  static bool _boolValue(
    dynamic value, {
    required bool fallback,
  }) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text =
        value?.toString().trim().toLowerCase() ??
            '';

    if (text == 'true' ||
        text == '1' ||
        text == 'yes') {
      return true;
    }

    if (text == 'false' ||
        text == '0' ||
        text == 'no') {
      return false;
    }

    return fallback;
  }

  static List<int> _intListValue(
    dynamic value, {
    required List<int> fallback,
  }) {
    if (value is Iterable) {
      final List<int> result = value
          .map(
            (dynamic item) =>
                int.tryParse(
                  item.toString(),
                ),
          )
          .whereType<int>()
          .where(
            (int day) =>
                day >= DateTime.monday &&
                day <= DateTime.sunday,
          )
          .toSet()
          .toList()
        ..sort();

      if (result.isNotEmpty) {
        return result;
      }
    }

    return List<int>.from(fallback);
  }

  static DateTime? _dateTimeValue(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    try {
      final dynamic converted =
          value.toDate();

      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Supports Firestore Timestamp.
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}


