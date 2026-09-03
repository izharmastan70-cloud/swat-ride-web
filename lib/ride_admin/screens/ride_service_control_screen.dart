import 'package:flutter/material.dart';

import '../../models/ride_service_control_model.dart';
import '../../services/ride_service_control_service.dart';

class RideServiceControlScreen extends StatefulWidget {
  const RideServiceControlScreen({
    super.key,
    required this.adminId,
    required this.adminName,
  });

  final String adminId;
  final String adminName;

  @override
  State<RideServiceControlScreen> createState() =>
      _RideServiceControlScreenState();
}

class _RideServiceControlScreenState extends State<RideServiceControlScreen> {
  static const Color _background = Color(0xFF090909);
  static const Color _card = Color(0xFF191919);
  static const Color _yellow = Color(0xFFFFD400);

  final RideServiceControlService _service = RideServiceControlService();

  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
        title: const Text(
          'Normal Ride Service Control',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<RideServiceControlModel>(
          stream: _service.watchSettings(),
          initialData: RideServiceControlModel.defaults(),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<RideServiceControlModel> snapshot,
              ) {
                if (snapshot.hasError) {
                  return _errorState(snapshot.error);
                }

                final RideServiceControlModel settings =
                    snapshot.data ?? RideServiceControlModel.defaults();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  children: <Widget>[
                    _statusCard(settings),
                    const SizedBox(height: 14),
                    _adminControlCard(settings),
                    const SizedBox(height: 14),
                    _superAdminOverrideCard(settings),
                    const SizedBox(height: 14),
                    _safetyNotice(),
                  ],
                );
              },
        ),
      ),
    );
  }

  Widget _statusCard(RideServiceControlModel settings) {
    final bool enabled = settings.effectiveServiceEnabled;

    final Color statusColor = enabled ? Colors.greenAccent : Colors.redAccent;

    final String statusText;
    if (settings.superAdminOverride != null) {
      statusText = settings.superAdminOverride == true
          ? 'FORCED ON BY SUPER ADMIN'
          : 'FORCED OFF BY SUPER ADMIN';
    } else if (settings.maintenanceMode) {
      statusText = 'MAINTENANCE MODE';
    } else {
      statusText = settings.serviceEnabled ? 'SERVICE ON' : 'SERVICE OFF';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  enabled
                      ? Icons.check_circle_outline_rounded
                      : Icons.warning_amber_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Effective Normal Ride status',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (settings.effectiveReason.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              settings.effectiveReason,
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
          const SizedBox(height: 14),
          _infoRow(
            'Last updated by',
            settings.updatedBy.isEmpty
                ? 'Not recorded yet'
                : settings.updatedBy,
          ),
          _infoRow('Last updated', _formatDateTime(settings.updatedAt)),
        ],
      ),
    );
  }

  Widget _adminControlCard(RideServiceControlModel settings) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Ride Admin control',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Controls new Normal Ride availability. Existing active rides must continue normally.',
            style: TextStyle(color: Colors.white60, height: 1.4),
          ),
          const SizedBox(height: 16),
          _stateLine(
            icon: Icons.power_settings_new_rounded,
            title: 'Master service',
            value: settings.serviceEnabled ? 'Enabled' : 'Disabled',
            enabled: settings.serviceEnabled,
          ),
          const SizedBox(height: 10),
          _stateLine(
            icon: Icons.build_circle_outlined,
            title: 'Maintenance mode',
            value: settings.maintenanceMode ? 'Active' : 'Inactive',
            enabled: !settings.maintenanceMode,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : () => _editSettings(settings),
              style: FilledButton.styleFrom(
                backgroundColor: _yellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.tune_rounded),
              label: Text(
                _saving ? 'Saving...' : 'CHANGE SERVICE CONTROL',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _superAdminOverrideCard(RideServiceControlModel settings) {
    final bool overrideActive = settings.superAdminOverride != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: overrideActive
              ? Colors.deepOrangeAccent.withValues(alpha: 0.45)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.admin_panel_settings_outlined,
                color: Colors.deepOrangeAccent,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Super Admin override',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            overrideActive
                ? settings.superAdminOverride == true
                      ? 'Super Admin is currently forcing Normal Ride ON.'
                      : 'Super Admin is currently forcing Normal Ride OFF.'
                : 'No Super Admin override is currently active.',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          if (overrideActive &&
              settings.superAdminOverrideReason.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            _infoRow('Reason', settings.superAdminOverrideReason),
            _infoRow(
              'Override by',
              settings.superAdminOverrideBy.isEmpty
                  ? 'Super Admin'
                  : settings.superAdminOverrideBy,
            ),
            _infoRow(
              'Override time',
              _formatDateTime(settings.superAdminOverrideAt),
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            'Ride Admin cannot change this override from this screen.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _safetyNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.shield_outlined, color: Colors.lightBlueAccent),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Turning Normal Ride OFF or enabling maintenance will block only new Ride requests and new Driver acceptance. Active rides must not be terminated.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editSettings(RideServiceControlModel settings) async {
    bool serviceEnabled = settings.serviceEnabled;
    bool maintenanceMode = settings.maintenanceMode;

    final TextEditingController reasonController = TextEditingController(
      text: settings.reason,
    );

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            final bool reasonRequired = !serviceEnabled || maintenanceMode;

            return AlertDialog(
              backgroundColor: const Color(0xFF202020),
              title: const Text(
                'Normal Ride Service Control',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: _yellow,
                      title: const Text(
                        'Master Ride service',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        serviceEnabled
                            ? 'New Normal Ride requests allowed'
                            : 'New Normal Ride requests blocked',
                        style: const TextStyle(color: Colors.white60),
                      ),
                      value: serviceEnabled,
                      onChanged: (bool value) {
                        setDialogState(() {
                          serviceEnabled = value;
                        });
                      },
                    ),
                    const Divider(color: Colors.white12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: Colors.orangeAccent,
                      title: const Text(
                        'Maintenance mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: const Text(
                        'Temporarily block new Ride work while maintenance is active',
                        style: TextStyle(color: Colors.white60),
                      ),
                      value: maintenanceMode,
                      onChanged: (bool value) {
                        setDialogState(() {
                          maintenanceMode = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: reasonController,
                      minLines: 2,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: reasonRequired
                            ? 'Admin reason *'
                            : 'Admin reason (optional)',
                        labelStyle: const TextStyle(color: Colors.white60),
                        hintText: 'Example: Scheduled maintenance until 4 PM',
                        hintStyle: const TextStyle(color: Colors.white30),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: _yellow),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('CANCEL'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _yellow,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    if (reasonRequired &&
                        reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a reason before disabling the service or enabling maintenance.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text(
                    'SAVE',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) {
      reasonController.dispose();
      return;
    }

    final String reason = reasonController.text.trim();
    reasonController.dispose();

    if (!mounted) return;

    setState(() {
      _saving = true;
    });

    try {
      await _service.updateByRideAdmin(
        serviceEnabled: serviceEnabled,
        maintenanceMode: maintenanceMode,
        reason: reason,
        updatedBy: widget.adminId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Normal Ride service control updated.')),
        );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Unable to update service control: $error'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _stateLine({
    required IconData icon,
    required String title,
    required String value,
    required bool enabled,
  }) {
    final Color color = enabled ? Colors.greenAccent : Colors.redAccent;

    return Row(
      children: <Widget>[
        Icon(icon, color: color, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 112,
            child: Text(
              title,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_outlined,
              color: Colors.redAccent,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load Normal Ride service control.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Not recorded yet';
    }

    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/${value.year} $hour:$minute';
  }
}
