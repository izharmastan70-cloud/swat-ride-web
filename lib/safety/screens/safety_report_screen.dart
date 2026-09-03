// SWAT RIDE - UNIVERSAL SAFETY REPORT SCREEN
//
// Shared non-emergency safety reporting for:
// - Normal Ride customer and driver
// - Student Ride parent, guardian, driver and school staff
// - Food customer, delivery rider and restaurant partner
// - Cargo / Parcel customer and driver
// - Hotel guest, owner and staff
// - Tour customer, guide and tourism driver
//
// IMPORTANT:
// This screen is for safety concerns where immediate emergency help
// is not currently required.
//
// For immediate danger, the user should use Emergency SOS instead.
//
// Firebase Storage is currently deferred.
// Photo, audio and video evidence upload will be added later without
// changing this screen's core reporting architecture.

import 'package:flutter/material.dart';

import '../config/safety_config.dart';
import '../models/safety_models.dart';
import '../services/universal_safety_service.dart';
import '../widgets/safety_widgets.dart';

class SafetyReportScreen extends StatefulWidget {
  const SafetyReportScreen({
    super.key,
    required this.contextData,
    this.safetyService,
    this.initialCategory,
    this.onReportSubmitted,
    this.onOpenEmergencySos,
  });

  /// Ride, Food, Cargo, Student, Hotel or Tour details.
  final SafetyContext contextData;

  /// Optional service injection.
  final UniversalSafetyService? safetyService;

  /// Optional category selected before opening this screen.
  final SafetyEmergencyCategory? initialCategory;

  /// Called after a safety report is successfully submitted.
  final ValueChanged<String>? onReportSubmitted;

  /// Opens the immediate Emergency SOS flow when the user confirms
  /// that someone is currently in danger.
  final VoidCallback? onOpenEmergencySos;

  @override
  State<SafetyReportScreen> createState() =>
      _SafetyReportScreenState();
}

class _SafetyReportScreenState
    extends State<SafetyReportScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _descriptionController =
      TextEditingController();

  late final UniversalSafetyService _safetyService;

  UniversalSafetyConfig? _config;
  SafetyEmergencyCategory? _selectedCategory;

  bool _isLoadingConfig = true;
  bool _isSubmitting = false;

  bool _includeCurrentLocation = true;
  bool _allowSafetyTeamContact = true;
  bool _informationIsAccurate = false;

  String _configWarning = '';

  @override
  void initState() {
    super.initState();

    _safetyService =
        widget.safetyService ?? UniversalSafetyService();

    _selectedCategory = widget.initialCategory;

    _loadConfig();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final UniversalSafetyConfig config =
          await _safetyService.getSafetyConfig();

      if (!mounted) {
        return;
      }

      setState(() {
        _config = config;
        _isLoadingConfig = false;
        _configWarning = '';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _config = defaultUniversalSafetyConfig();
        _isLoadingConfig = false;
        _configWarning =
            'Online safety settings could not be loaded. '
            'Safe default settings are being used.';
      });
    }
  }

  UniversalSafetyConfig get _resolvedConfig {
    return _config ?? defaultUniversalSafetyConfig();
  }

  SafetyServiceSettings get _serviceSettings {
    return _resolvedConfig.settingsFor(
      widget.contextData.serviceType,
    );
  }

  List<SafetyEmergencyCategory> get _reportCategories {
    final List<SafetyEmergencyCategory> configured =
        _serviceSettings.availableCategories.isEmpty
            ? defaultSafetyServiceSettings(
                widget.contextData.serviceType,
              ).availableCategories
            : _serviceSettings.availableCategories;

    final List<SafetyEmergencyCategory> filtered =
        configured.where(
      (SafetyEmergencyCategory category) {
        return !_isImmediateEmergencyCategory(category);
      },
    ).toList();

    if (filtered.isEmpty) {
      return const <SafetyEmergencyCategory>[
        SafetyEmergencyCategory.harassment,
        SafetyEmergencyCategory.unsafeLocation,
        SafetyEmergencyCategory.unableToContact,
        SafetyEmergencyCategory.other,
      ];
    }

    return filtered;
  }

  bool _isImmediateEmergencyCategory(
    SafetyEmergencyCategory category,
  ) {
    switch (category) {
      case SafetyEmergencyCategory.immediateDanger:
      case SafetyEmergencyCategory.medicalEmergency:
      case SafetyEmergencyCategory.accident:
      case SafetyEmergencyCategory.physicalThreat:
      case SafetyEmergencyCategory.robbery:
      case SafetyEmergencyCategory.passengerThreat:
      case SafetyEmergencyCategory.suspectedKidnapping:
      case SafetyEmergencyCategory.childMissing:
      case SafetyEmergencyCategory.childMedicalEmergency:
      case SafetyEmergencyCategory.childLeftInVehicle:
      case SafetyEmergencyCategory.deliveryRiderAccident:
      case SafetyEmergencyCategory.cargoVehicleHijacking:
      case SafetyEmergencyCategory.fireOrSmoke:
      case SafetyEmergencyCategory.evacuationRequired:
      case SafetyEmergencyCategory.violentGuest:
      case SafetyEmergencyCategory.touristMissing:
      case SafetyEmergencyCategory.mountainEmergency:
      case SafetyEmergencyCategory.groupEmergency:
        return true;

      default:
        return false;
    }
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) {
      return;
    }

    final FormState? form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      _showMessage(
        'Select a safety issue category.',
        isError: true,
      );
      return;
    }

    if (!_informationIsAccurate) {
      _showMessage(
        'Confirm that the provided information is accurate.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final SafetyEmergencyCategory category =
          _selectedCategory!;

      final SafetyLocation? location =
          _includeCurrentLocation
              ? widget.contextData.currentLocation
              : null;

      final String reportId =
          await _safetyService.createIncident(
        context: widget.contextData,
        category: category,
        severity: _severityForReport(category),
        description:
            _descriptionController.text.trim(),
        currentLocation: location,
        lastKnownLocation: location,
        locationStatus: location == null
            ? SafetyLocationStatus.unavailable
            : SafetyLocationStatus.available,
        networkStatus: SafetyNetworkStatus.unknown,
        isSilentSos: false,
        isTestIncident:
            _resolvedConfig.features.testModeEnabled,
        metadata: <String, dynamic>{
          'submissionType': 'safetyReport',
          'isImmediateEmergency': false,
          'includeCurrentLocation':
              _includeCurrentLocation,
          'allowSafetyTeamContact':
              _allowSafetyTeamContact,
          'informationConfirmedAccurate':
              _informationIsAccurate,
          'sourcePage':
              widget.contextData.sourcePage.name,

          // Firebase Storage is deferred.
          'evidenceUploadEnabled': false,
          'evidenceReferences': <String>[],
        },
      );

      await _safetyService.updateIncidentStatus(
        incidentId: reportId,
        status:
            SafetyIncidentStatus.underInvestigation,
        performedByUserId:
            widget.contextData.initiatedByUserId,
        performedByRole:
            widget.contextData.initiatedByRole,
        message:
            'Non-emergency safety report submitted for review.',
        metadata: <String, dynamic>{
          'submissionType': 'safetyReport',
          'category': category.name,
        },
      );

      if (!mounted) {
        return;
      }

      widget.onReportSubmitted?.call(reportId);

      await _showSuccessDialog(
        reportId: reportId,
        category: category,
      );
    } on UniversalSafetyServiceException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
        isError: true,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to submit the safety report. '
        'Please check your connection and try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  SafetySeverity _severityForReport(
    SafetyEmergencyCategory category,
  ) {
    switch (category) {
      case SafetyEmergencyCategory.harassment:
      case SafetyEmergencyCategory.dangerousDriving:
      case SafetyEmergencyCategory.routeDeviation:
      case SafetyEmergencyCategory.driverMismatch:
      case SafetyEmergencyCategory.vehicleMismatch:
      case SafetyEmergencyCategory.unauthorizedGuardian:
      case SafetyEmergencyCategory.unauthorizedHandover:
      case SafetyEmergencyCategory.customerThreatToRider:
      case SafetyEmergencyCategory.riderThreatToCustomer:
      case SafetyEmergencyCategory.unsafeCashCollection:
      case SafetyEmergencyCategory.cargoTheftAttempt:
      case SafetyEmergencyCategory.unauthorizedRoomAccess:
      case SafetyEmergencyCategory.hotelStaffThreat:
      case SafetyEmergencyCategory.unsafeRoom:
      case SafetyEmergencyCategory.guestMissing:
      case SafetyEmergencyCategory.groupSeparated:
      case SafetyEmergencyCategory.unsafeWeather:
      case SafetyEmergencyCategory.unsafeRoad:
        return SafetySeverity.medium;

      default:
        return SafetySeverity.low;
    }
  }

  Future<void> _showImmediateDangerQuestion() async {
    final bool? immediateDanger =
        await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);

        return AlertDialog(
          icon: Icon(
            Icons.sos,
            size: 38,
            color: theme.colorScheme.error,
          ),
          title: const Text(
            'Is anyone in immediate danger?',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Use Emergency SOS when urgent help is needed. '
            'Use this report screen for concerns that can be '
            'reviewed by the SWAT RIDE safety team.',
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Continue Report',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    theme.colorScheme.error,
                foregroundColor:
                    theme.colorScheme.onError,
              ),
              child: const Text(
                'Open Emergency SOS',
              ),
            ),
          ],
        );
      },
    );

    if (immediateDanger != true || !mounted) {
      return;
    }

    if (widget.onOpenEmergencySos != null) {
      widget.onOpenEmergencySos!.call();
      return;
    }

    _showMessage(
      'Emergency SOS will open after this screen is '
      'connected to the selected module.',
    );
  }

  Future<void> _showSuccessDialog({
    required String reportId,
    required SafetyEmergencyCategory category,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);

        return AlertDialog(
          icon: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary
                  .withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.verified_outlined,
              size: 36,
              color: theme.colorScheme.primary,
            ),
          ),
          title: const Text(
            'Safety report submitted',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _resolvedConfig.features.testModeEnabled
                    ? 'Your report was safely recorded in '
                        'testing mode.'
                    : 'Your report has been sent to the '
                        'SWAT RIDE safety team for review.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: theme.colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: <Widget>[
                    _buildDialogInformationRow(
                      context,
                      label: 'Category',
                      value:
                          emergencyCategoryLabel(category),
                    ),
                    const SizedBox(height: 8),
                    _buildDialogInformationRow(
                      context,
                      label: 'Report ID',
                      value: reportId,
                    ),
                    const SizedBox(height: 8),
                    _buildDialogInformationRow(
                      context,
                      label: 'Status',
                      value: 'Under investigation',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsAlignment:
              MainAxisAlignment.center,
          actions: <Widget>[
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(this.context).pop(reportId);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogInformationRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$label:',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    final ThemeData theme = Theme.of(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isError ? theme.colorScheme.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (_isLoadingConfig) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Report Safety Issue'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_resolvedConfig.features
        .safetyReportsEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Report Safety Issue'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.report_off_outlined,
                  size: 64,
                  color: theme.disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Safety reports unavailable',
                  style:
                      theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Non-emergency safety reports are '
                  'currently disabled.',
                  textAlign: TextAlign.center,
                  style:
                      theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Report Safety Issue'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              10,
              16,
              30,
            ),
            children: <Widget>[
              _buildHeader(context),
              const SizedBox(height: 14),
              SafetyReferenceCard(
                contextData: widget.contextData,
              ),
              if (_configWarning.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                SafetyStatusBanner(
                  status:
                      SafetyIncidentStatus.alertSent,
                  message: _configWarning,
                  compact: true,
                ),
              ],
              const SizedBox(height: 18),
              _buildEmergencyNotice(context),
              const SizedBox(height: 20),
              const SafetySectionTitle(
                title: 'What happened?',
                subtitle:
                    'Choose the option that best describes '
                    'your safety concern.',
              ),
              const SizedBox(height: 11),
              _buildCategorySelector(context),
              const SizedBox(height: 20),
              const SafetySectionTitle(
                title: 'Report details',
                subtitle:
                    'Explain what happened so the safety '
                    'team can review it properly.',
              ),
              const SizedBox(height: 11),
              TextFormField(
                controller: _descriptionController,
                minLines: 5,
                maxLines: 9,
                maxLength: 1500,
                textCapitalization:
                    TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      'Describe what happened, where it '
                      'happened and who was involved...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                validator: (String? value) {
                  final String description =
                      value?.trim() ?? '';

                  if (description.isEmpty) {
                    return 'Enter details about the safety issue.';
                  }

                  if (description.length < 15) {
                    return 'Please provide a little more detail.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildEvidencePlaceholder(context),
              const SizedBox(height: 20),
              const SafetySectionTitle(
                title: 'Report preferences',
              ),
              const SizedBox(height: 7),
              SwitchListTile.adaptive(
                value: _includeCurrentLocation,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Include current location',
                ),
                subtitle: Text(
                  widget.contextData.currentLocation == null
                      ? 'No current location is available'
                      : 'Help the safety team identify '
                          'where the issue occurred',
                ),
                secondary: const Icon(
                  Icons.location_on_outlined,
                ),
                onChanged:
                    widget.contextData.currentLocation == null
                        ? null
                        : (bool value) {
                            setState(() {
                              _includeCurrentLocation = value;
                            });
                          },
              ),
              SwitchListTile.adaptive(
                value: _allowSafetyTeamContact,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Allow safety team contact',
                ),
                subtitle: const Text(
                  'The safety team may contact you '
                  'about this report',
                ),
                secondary: const Icon(
                  Icons.support_agent_outlined,
                ),
                onChanged: (bool value) {
                  setState(() {
                    _allowSafetyTeamContact = value;
                  });
                },
              ),
              const SizedBox(height: 5),
              CheckboxListTile(
                value: _informationIsAccurate,
                contentPadding: EdgeInsets.zero,
                controlAffinity:
                    ListTileControlAffinity.leading,
                title: const Text(
                  'I confirm this information is accurate',
                ),
                subtitle: const Text(
                  'False safety reports may affect '
                  'users and service providers.',
                ),
                onChanged: (bool? value) {
                  setState(() {
                    _informationIsAccurate =
                        value ?? false;
                  });
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      _isSubmitting ? null : _submitReport,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_outlined,
                        ),
                  label: Text(
                    _isSubmitting
                        ? 'Submitting...'
                        : 'Submit Safety Report',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(55),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildPrivacyNotice(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            theme.colorScheme.primary
                .withValues(alpha: 0.14),
            theme.colorScheme.primary
                .withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.report_problem_outlined,
              size: 30,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Tell us about a safety concern',
                  style:
                      theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your report will be connected to '
                  '${safetyServiceLabel(widget.contextData.serviceType)}.',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant,
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

  Widget _buildEmergencyNotice(
    BuildContext context,
  ) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.error
          .withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: _showImmediateDangerQuestion,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: theme.colorScheme.error
                  .withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.sos,
                size: 27,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Need urgent help?',
                      style:
                          theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Open Emergency SOS instead of '
                      'submitting a normal report.',
                      style:
                          theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(
    BuildContext context,
  ) {
    final List<SafetyEmergencyCategory> categories =
        _reportCategories;

    return Column(
      children: categories.map(
        (SafetyEmergencyCategory category) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: SafetyEmergencyCategoryTile(
              category: category,
              selected: _selectedCategory == category,
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildEvidencePlaceholder(
    BuildContext context,
  ) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.attach_file_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Evidence uploads',
                  style:
                      theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Photo, audio and video evidence uploads '
                  'will become available after Firebase '
                  'Storage is enabled. The report can still '
                  'be submitted now.',
                  style:
                      theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNotice(
    BuildContext context,
  ) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.privacy_tip_outlined,
            size: 21,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'The related booking, ride, order, driver, '
              'vehicle, hotel or tour details may be saved '
              'with this report for investigation.',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}