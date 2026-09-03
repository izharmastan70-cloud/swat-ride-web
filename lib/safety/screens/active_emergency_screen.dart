// SWAT RIDE - ACTIVE UNIVERSAL EMERGENCY SCREEN
//
// Shared active emergency screen for:
// - Ride customer and driver
// - Student parent, guardian and driver
// - Food customer, delivery rider and restaurant partner
// - Cargo / Parcel customer and driver
// - Hotel guest, owner and staff
// - Tour customer, guide and tourism driver
// - Admin and safety agent
//
// This screen listens to one central safety incident.
// It shows live status, incident timeline and emergency actions.
//
// Real phone calls, notifications, maps and trusted-contact delivery
// will be connected during later integration phases.

import 'package:flutter/material.dart';

import '../models/safety_models.dart';
import '../services/universal_safety_service.dart';
import '../widgets/safety_widgets.dart';

class ActiveEmergencyScreen extends StatefulWidget {
  const ActiveEmergencyScreen({
    super.key,
    required this.incidentId,
    required this.currentUserId,
    required this.currentUserRole,
    this.safetyService,
    this.onCallEmergencyService,
    this.onCallTrustedContact,
    this.onContactSafetySupport,
    this.onOpenLiveLocation,
    this.onIncidentResolved,
  });

  final String incidentId;
  final String currentUserId;
  final SafetyUserRole currentUserRole;

  final UniversalSafetyService? safetyService;

  final VoidCallback? onCallEmergencyService;
  final VoidCallback? onCallTrustedContact;
  final VoidCallback? onContactSafetySupport;
  final ValueChanged<SafetyIncidentModel>? onOpenLiveLocation;
  final ValueChanged<SafetyIncidentModel>? onIncidentResolved;

  @override
  State<ActiveEmergencyScreen> createState() =>
      _ActiveEmergencyScreenState();
}

class _ActiveEmergencyScreenState
    extends State<ActiveEmergencyScreen> {
  late final UniversalSafetyService _safetyService;

  bool _isMarkingSafe = false;
  bool _isRecordingCall = false;
  bool _isRecordingTrustedContact = false;

  @override
  void initState() {
    super.initState();

    _safetyService =
        widget.safetyService ?? UniversalSafetyService();
  }

  bool _canUserMarkSafe(SafetyIncidentModel incident) {
    if (!incident.isActive) {
      return false;
    }

    return widget.currentUserId.trim().isNotEmpty &&
        widget.currentUserId ==
            incident.context.initiatedByUserId;
  }


  Future<void> _markUserSafe(
    SafetyIncidentModel incident,
  ) async {
    if (_isMarkingSafe || !_canUserMarkSafe(incident)) {
      return;
    }

    final String? reason =
        await _showSafeReasonSheet();

    if (reason == null ||
        reason.trim().isEmpty ||
        !mounted) {
      return;
    }

    setState(() {
      _isMarkingSafe = true;
    });

    try {
      await _safetyService.markUserSafe(
        incidentId: incident.incidentId,
        userId: widget.currentUserId,
        userRole: widget.currentUserRole,
        reason: reason.trim(),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Your safety status has been updated.',
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
        'Unable to update your safety status.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingSafe = false;
        });
      }
    }
  }

  Future<String?> _showSafeReasonSheet() {
    String? selectedReason;

    const List<String> reasons = <String>[
      'Accidental SOS activation',
      'Situation is now resolved',
      'Emergency service has arrived',
      'Family or trusted person has arrived',
      'I have moved to a safe location',
      'Other',
    ];

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        final ThemeData theme =
            Theme.of(bottomSheetContext);

        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setSheetState,
          ) {
            return Container(
              padding: const EdgeInsets.fromLTRB(
                18,
                10,
                18,
                22,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SafetySectionTitle(
                    title: 'Are you safe now?',
                    subtitle:
                        'Choose why immediate assistance is '
                        'no longer required.',
                  ),
                  const SizedBox(height: 14),
                  ...reasons.map(
                    (String reason) {
                      final bool selected =
                          selectedReason == reason;

                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: selected
                              ? theme.colorScheme.primary
                                  .withValues(alpha: 0.10)
                              : theme.colorScheme.surface,
                          borderRadius:
                              BorderRadius.circular(15),
                          child: InkWell(
                            onTap: () {
                              setSheetState(() {
                                selectedReason = reason;
                              });
                            },
                            borderRadius:
                                BorderRadius.circular(15),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(15),
                                border: Border.all(
                                  color: selected
                                      ? theme
                                          .colorScheme.primary
                                      : theme.colorScheme
                                          .outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      reason,
                                      style: theme
                                          .textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    selected
                                        ? Icons.check_circle
                                        : Icons
                                            .radio_button_unchecked,
                                    color: selected
                                        ? theme
                                            .colorScheme.primary
                                        : theme.colorScheme
                                            .onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selectedReason == null
                          ? null
                          : () {
                              Navigator.of(context).pop(
                                selectedReason,
                              );
                            },
                      style: FilledButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Confirm I Am Safe',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _recordEmergencyCall(
    SafetyIncidentModel incident,
  ) async {
    if (_isRecordingCall) {
      return;
    }

    if (widget.onCallEmergencyService != null) {
      widget.onCallEmergencyService!.call();
    }

    setState(() {
      _isRecordingCall = true;
    });

    try {
      await _safetyService.markEmergencyServiceCalled(
        incidentId: incident.incidentId,
        performedByUserId: widget.currentUserId,
        performedByRole: widget.currentUserRole,
        emergencyServiceType: 'generalEmergency',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Emergency contact action recorded.',
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
        'Unable to record emergency contact action.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRecordingCall = false;
        });
      }
    }
  }

  Future<void> _recordTrustedContactAlert(
    SafetyIncidentModel incident,
  ) async {
    if (_isRecordingTrustedContact) {
      return;
    }

    if (widget.onCallTrustedContact != null) {
      widget.onCallTrustedContact!.call();
    }

    setState(() {
      _isRecordingTrustedContact = true;
    });

    try {
      await _safetyService.markTrustedContactsAlerted(
        incidentId: incident.incidentId,
        performedByUserId: widget.currentUserId,
        performedByRole: widget.currentUserRole,
        alertedContactCount: 1,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Trusted-contact action recorded.',
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
        'Unable to record trusted-contact action.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRecordingTrustedContact = false;
        });
      }
    }
  }

  void _openSafetySupport() {
    if (widget.onContactSafetySupport != null) {
      widget.onContactSafetySupport!.call();
      return;
    }

    _showMessage(
      'SWAT RIDE Safety Support will be connected '
      'during admin integration.',
    );
  }

  void _openLiveLocation(
    SafetyIncidentModel incident,
  ) {
    if (widget.onOpenLiveLocation != null) {
      widget.onOpenLiveLocation!.call(incident);
      return;
    }

    if (incident.currentLocation == null) {
      _showMessage(
        'Current emergency location is unavailable.',
      );
      return;
    }

    final SafetyLocation location =
        incident.currentLocation!;

    _showMessage(
      'Location: '
      '${location.latitude.toStringAsFixed(6)}, '
      '${location.longitude.toStringAsFixed(6)}',
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
    return StreamBuilder<SafetyIncidentModel?>(
      stream: _safetyService.watchIncident(
        widget.incidentId,
      ),
      builder: (
        BuildContext context,
        AsyncSnapshot<SafetyIncidentModel?> snapshot,
      ) {
        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Emergency Assistance'),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorScreen(
            context,
            'Unable to load the emergency incident.',
          );
        }

        final SafetyIncidentModel? incident =
            snapshot.data;

        if (incident == null) {
          return _buildErrorScreen(
            context,
            'This emergency incident could not be found.',
          );
        }

        if (!incident.isActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onIncidentResolved?.call(incident);
          });
        }

        return _buildIncidentScreen(
          context,
          incident,
        );
      },
    );
  }

  Widget _buildIncidentScreen(
    BuildContext context,
    SafetyIncidentModel incident,
  ) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Emergency Assistance'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            28,
          ),
          children: <Widget>[
            _buildEmergencyHeader(
              context,
              incident,
            ),
            const SizedBox(height: 14),
            SafetyStatusBanner(
              status: incident.status,
              message: _statusMessage(incident),
            ),
            const SizedBox(height: 14),
            SafetyReferenceCard(
              contextData: incident.context,
            ),
            const SizedBox(height: 16),
            _buildEmergencySummary(
              context,
              incident,
            ),
            const SizedBox(height: 20),
            const SafetySectionTitle(
              title: 'Emergency actions',
              subtitle:
                  'Use the options below while assistance '
                  'is active.',
            ),
            const SizedBox(height: 10),
            SafetyActionTile(
              title: 'Call emergency service',
              subtitle:
                  incident.emergencyServiceCalled
                      ? 'Emergency contact already recorded'
                      : 'Contact local emergency assistance',
              icon: Icons.local_police_outlined,
              isDestructive: true,
              enabled: incident.isActive &&
                  !_isRecordingCall,
              trailing: _isRecordingCall
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : null,
              onTap: () {
                _recordEmergencyCall(incident);
              },
            ),
            const SizedBox(height: 9),
            SafetyActionTile(
              title: 'Alert trusted contact',
              subtitle:
                  incident.trustedContactsAlerted
                      ? 'Trusted-contact alert recorded'
                      : 'Contact family or someone you trust',
              icon: Icons.people_alt_outlined,
              enabled: incident.isActive &&
                  !_isRecordingTrustedContact,
              trailing: _isRecordingTrustedContact
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : null,
              onTap: () {
                _recordTrustedContactAlert(incident);
              },
            ),
            const SizedBox(height: 9),
            SafetyActionTile(
              title: 'Open emergency location',
              subtitle: incident.currentLocation == null
                  ? 'No emergency location available'
                  : 'View the latest recorded location',
              icon: Icons.share_location_outlined,
              enabled:
                  incident.currentLocation != null,
              onTap: () {
                _openLiveLocation(incident);
              },
            ),
            const SizedBox(height: 9),
            SafetyActionTile(
              title: 'Contact SWAT RIDE Safety',
              subtitle:
                  'Get help from the safety support team',
              icon: Icons.support_agent_outlined,
              enabled: incident.isActive,
              onTap: _openSafetySupport,
            ),
            if (_canUserMarkSafe(incident)) ...<Widget>[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isMarkingSafe
                      ? null
                      : () {
                          _markUserSafe(incident);
                        },
                  icon: _isMarkingSafe
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline,
                        ),
                  label: const Text(
                    'I Am Safe Now',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            const SafetySectionTitle(
              title: 'Incident timeline',
              subtitle:
                  'Updates from the user and safety team.',
            ),
            const SizedBox(height: 10),
            _buildTimeline(incident),
            const SizedBox(height: 18),
            _buildIncidentNotice(
              context,
              incident,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyHeader(
    BuildContext context,
    SafetyIncidentModel incident,
  ) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.error
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.error
              .withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: theme.colorScheme.error
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              incident.isActive
                  ? Icons.emergency_share_outlined
                  : Icons.task_alt_outlined,
              size: 38,
              color: incident.isActive
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            incident.isActive
                ? 'Emergency Assistance Active'
                : 'Emergency Incident Finished',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            incident.isTestIncident
                ? 'Testing mode is active. This is recorded '
                    'as a test incident.'
                : 'Keep your phone available while the '
                    'safety team handles this incident.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySummary(
    BuildContext context,
    SafetyIncidentModel incident,
  ) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: <Widget>[
          _summaryRow(
            context,
            'Incident ID',
            incident.incidentId,
          ),
          const Divider(height: 20),
          _summaryRow(
            context,
            'Emergency',
            emergencyCategoryLabel(
              incident.category,
            ),
          ),
          const Divider(height: 20),
          _summaryRow(
            context,
            'Severity',
            _severityLabel(incident.severity),
          ),
          const Divider(height: 20),
          _summaryRow(
            context,
            'Created',
            _formatDateTime(incident.createdAt),
          ),
          if (incident.currentLocation != null) ...<Widget>[
            const Divider(height: 20),
            _summaryRow(
              context,
              'Location',
              _locationLabel(
                incident.currentLocation!,
              ),
            ),
          ],
          if (incident.description.trim().isNotEmpty)
            ...<Widget>[
              const Divider(height: 20),
              _summaryRow(
                context,
                'Details',
                incident.description.trim(),
              ),
            ],
        ],
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value,
  ) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(
    SafetyIncidentModel incident,
  ) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _safetyService.watchIncidentEvents(
        incident.incidentId,
      ),
      builder: (
        BuildContext context,
        AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
      ) {
        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Text(
            'Incident timeline is temporarily unavailable.',
          );
        }

        final List<Map<String, dynamic>> events =
            snapshot.data ?? <Map<String, dynamic>>[];

        if (events.isEmpty) {
          return const Text(
            'No incident updates are available yet.',
          );
        }

        return Column(
          children: List<Widget>.generate(
            events.length,
            (int index) {
              final Map<String, dynamic> event =
                  events[index];

              return _buildTimelineItem(
                context,
                event,
                isLast: index == events.length - 1,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    Map<String, dynamic> event, {
    required bool isLast,
  }) {
    final ThemeData theme = Theme.of(context);

    final String eventType =
        event['eventType']?.toString() ?? '';

    final String message =
        event['message']?.toString() ?? '';

    final DateTime? createdAt =
        _dateFromDynamic(event['createdAt']);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary
                    .withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                _timelineIcon(eventType),
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 45,
                color: theme.colorScheme.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(bottom: 17),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _timelineTitle(eventType),
                  style:
                      theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (message.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style:
                        theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (createdAt != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(createdAt),
                    style:
                        theme.textTheme.labelSmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentNotice(
    BuildContext context,
    SafetyIncidentModel incident,
  ) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 21,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              incident.isActive
                  ? 'Do not close the app during a genuine '
                      'emergency. Keep your phone charged and '
                      'available for calls.'
                  : 'This incident is no longer active. Its '
                      'history remains available for safety '
                      'review and reporting.',
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

  Widget _buildErrorScreen(
    BuildContext context,
    String message,
  ) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Assistance'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline,
                size: 62,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 15),
              Text(
                'Unable to open incident',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
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

  String _statusMessage(
    SafetyIncidentModel incident,
  ) {
    switch (incident.status) {
      case SafetyIncidentStatus.created:
        return 'Your emergency alert has been recorded.';

      case SafetyIncidentStatus.alertSent:
        return 'Safety alerts are being sent.';

      case SafetyIncidentStatus.acknowledged:
        return 'The safety team has seen this incident.';

      case SafetyIncidentStatus.agentAssigned:
        return 'A safety agent is handling this incident.';

      case SafetyIncidentStatus.contactingUser:
        return 'The safety team is trying to contact you.';

      case SafetyIncidentStatus.emergencyServiceContacted:
        return 'Emergency-service contact has been recorded.';

      case SafetyIncidentStatus.responding:
        return 'Emergency response is currently active.';

      case SafetyIncidentStatus.userMarkedSafe:
        return 'The user reported that immediate danger is over.';

      case SafetyIncidentStatus.underInvestigation:
        return 'The incident is under safety review.';

      case SafetyIncidentStatus.resolved:
        return 'This incident has been resolved.';

      case SafetyIncidentStatus.falseAlarm:
        return 'This incident was marked as a false alarm.';

      case SafetyIncidentStatus.closed:
        return 'This safety incident is closed.';
    }
  }

  String _severityLabel(SafetySeverity severity) {
    switch (severity) {
      case SafetySeverity.low:
        return 'Low';

      case SafetySeverity.medium:
        return 'Medium';

      case SafetySeverity.high:
        return 'High';

      case SafetySeverity.critical:
        return 'Critical';
    }
  }

  String _locationLabel(SafetyLocation location) {
    if (location.address.trim().isNotEmpty) {
      return location.address.trim();
    }

    if (location.placeName.trim().isNotEmpty) {
      return location.placeName.trim();
    }

    return '${location.latitude.toStringAsFixed(6)}, '
        '${location.longitude.toStringAsFixed(6)}';
  }

  String _formatDateTime(DateTime value) {
    final DateTime local = value.toLocal();

    final String day =
        local.day.toString().padLeft(2, '0');

    final String month =
        local.month.toString().padLeft(2, '0');

    final String hour =
        local.hour.toString().padLeft(2, '0');

    final String minute =
        local.minute.toString().padLeft(2, '0');

    return '$day/$month/${local.year} $hour:$minute';
  }

  DateTime? _dateFromDynamic(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    try {
      final dynamic converted = value.toDate();

      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Unsupported date type.
    }

    return null;
  }

  IconData _timelineIcon(String eventType) {
    switch (eventType) {
      case 'incidentCreated':
        return Icons.warning_amber_rounded;

      case 'incidentAcknowledged':
        return Icons.verified_outlined;

      case 'safetyAgentAssigned':
        return Icons.support_agent_outlined;

      case 'locationUpdated':
        return Icons.location_on_outlined;

      case 'userMarkedSafe':
        return Icons.check_circle_outline;

      case 'emergencyServiceCalled':
        return Icons.local_police_outlined;

      case 'trustedContactsAlerted':
        return Icons.people_alt_outlined;

      case 'incidentResolved':
        return Icons.task_alt_outlined;

      case 'incidentMarkedFalseAlarm':
        return Icons.info_outline;

      case 'adminNoteAdded':
        return Icons.note_alt_outlined;

      default:
        return Icons.history;
    }
  }

  String _timelineTitle(String eventType) {
    switch (eventType) {
      case 'incidentCreated':
        return 'Emergency created';

      case 'incidentAcknowledged':
        return 'Safety team acknowledged';

      case 'safetyAgentAssigned':
        return 'Safety agent assigned';

      case 'locationUpdated':
        return 'Location updated';

      case 'userMarkedSafe':
        return 'User marked safe';

      case 'emergencyServiceCalled':
        return 'Emergency service contacted';

      case 'trustedContactsAlerted':
        return 'Trusted contacts alerted';

      case 'incidentResolved':
        return 'Incident resolved';

      case 'incidentMarkedFalseAlarm':
        return 'False alarm recorded';

      case 'adminNoteAdded':
        return 'Safety note added';

      case 'statusUpdated':
        return 'Incident status updated';

      default:
        return 'Incident update';
    }
  }
}