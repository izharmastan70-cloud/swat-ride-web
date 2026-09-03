import 'package:flutter/material.dart';

import '../../models/hotel_service_control_model.dart';
import '../../services/hotel_service_control_service.dart';

class SuperAdminHotelServiceControlScreen
    extends StatefulWidget {
  const SuperAdminHotelServiceControlScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<SuperAdminHotelServiceControlScreen> createState() =>
      _SuperAdminHotelServiceControlScreenState();
}

class _SuperAdminHotelServiceControlScreenState
    extends State<SuperAdminHotelServiceControlScreen> {
  static const Color _yellow = Color(0xFFFFD60A);
  static const Color _background = Color(0xFF0D0D0D);
  static const Color _card = Color(0xFF1A1A1A);

  final HotelServiceControlService _service =
      HotelServiceControlService();

  final TextEditingController _messageController =
      TextEditingController();

  bool _serviceEnabled = true;
  bool _acceptNewBookings = true;
  bool _acceptPartnerApplications = true;
  bool _maintenanceMode = false;
  bool _isLoading = true;
  bool _isSaving = false;

  HotelServiceOverride _override =
      HotelServiceOverride.none;

  DateTime? _updatedAt;
  String _updatedBy = '';

  @override
  void initState() {
    super.initState();
    _loadControl();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadControl() async {
    try {
      final HotelServiceControlModel control =
          await _service.getControl();

      if (!mounted) {
        return;
      }

      setState(() {
        _serviceEnabled = control.serviceEnabled;
        _acceptNewBookings = control.acceptNewBookings;
        _acceptPartnerApplications =
            control.acceptPartnerApplications;
        _maintenanceMode = control.maintenanceMode;
        _messageController.text =
            control.maintenanceMessage;
        _override = control.superAdminOverride;
        _updatedAt = control.updatedAt;
        _updatedBy = control.updatedBy;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to load Hotel service control: $error',
        isError: true,
      );
    }
  }

  Future<void> _saveControl() async {
    if (_isSaving) {
      return;
    }

    final String adminId = widget.adminId.trim();
    final String message = _messageController.text.trim();

    if (adminId.isEmpty) {
      _showMessage(
        'Verified Super Admin ID is required.',
        isError: true,
      );
      return;
    }

    if ((!_serviceEnabled || _maintenanceMode) &&
        message.isEmpty) {
      _showMessage(
        'Maintenance/unavailable message is required.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.updateOperationalControl(
        serviceEnabled: _serviceEnabled,
        acceptNewBookings: _acceptNewBookings,
        acceptPartnerApplications:
            _acceptPartnerApplications,
        maintenanceMode: _maintenanceMode,
        maintenanceMessage: message,
        updatedBy: adminId,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Global Hotel service control updated.',
      );

      await _loadControl();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to update Hotel service control: $error',
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

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
        content: Text(message),
      ),
    );
  }

  String get _effectiveStatus {
    switch (_override) {
      case HotelServiceOverride.forceEnabled:
        return 'FORCE ENABLED';
      case HotelServiceOverride.forceDisabled:
        return 'FORCE DISABLED';
      case HotelServiceOverride.none:
        if (_maintenanceMode) {
          return 'MAINTENANCE';
        }

        return _serviceEnabled ? 'AVAILABLE' : 'DISABLED';
    }
  }

  Color get _statusColor {
    if (_override == HotelServiceOverride.forceDisabled ||
        (!_serviceEnabled &&
            _override == HotelServiceOverride.none)) {
      return Colors.redAccent;
    }

    if (_maintenanceMode &&
        _override == HotelServiceOverride.none) {
      return Colors.orangeAccent;
    }

    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        title: const Text(
          'Global Hotel Service Control',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reload',
            onPressed: _isLoading ? null : _loadControl,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _yellow,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                32,
              ),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _statusColor.withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.hotel_outlined,
                        color: _statusColor,
                        size: 34,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Effective platform status',
                              style: TextStyle(
                                color: Colors.white60,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _effectiveStatus,
                              style: TextStyle(
                                color: _statusColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _controlCard(
                  child: Column(
                    children: <Widget>[
                      _switchTile(
                        title: 'Hotel Service',
                        subtitle:
                            'Master availability for Hotel services.',
                        value: _serviceEnabled,
                        onChanged: (bool value) {
                          setState(() {
                            _serviceEnabled = value;
                          });
                        },
                      ),
                      const Divider(color: Colors.white12),
                      _switchTile(
                        title: 'Accept New Bookings',
                        subtitle:
                            'Existing bookings remain unchanged.',
                        value: _acceptNewBookings,
                        onChanged: (bool value) {
                          setState(() {
                            _acceptNewBookings = value;
                          });
                        },
                      ),
                      const Divider(color: Colors.white12),
                      _switchTile(
                        title: 'Hotel Partner Applications',
                        subtitle:
                            'Allow new Hotel Partner applications.',
                        value: _acceptPartnerApplications,
                        onChanged: (bool value) {
                          setState(() {
                            _acceptPartnerApplications =
                                value;
                          });
                        },
                      ),
                      const Divider(color: Colors.white12),
                      _switchTile(
                        title: 'Maintenance Mode',
                        subtitle:
                            'Show a graceful maintenance state.',
                        value: _maintenanceMode,
                        onChanged: (bool value) {
                          setState(() {
                            _maintenanceMode = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _controlCard(
                  child: TextField(
                    controller: _messageController,
                    maxLines: 3,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          'Maintenance / unavailable message',
                      labelStyle: const TextStyle(
                        color: Colors.white60,
                      ),
                      hintText:
                          'Hotel service is temporarily unavailable.',
                      hintStyle: const TextStyle(
                        color: Colors.white30,
                      ),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _controlCard(
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.shield_outlined,
                        color: _yellow,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Turning off Hotel service or new bookings does not cancel, delete or hide existing confirmed/active bookings.',
                          style: TextStyle(
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_updatedBy.isNotEmpty ||
                    _updatedAt != null) ...<Widget>[
                  const SizedBox(height: 14),
                  Text(
                    'Last updated by: ${_updatedBy.isEmpty ? 'Unknown' : _updatedBy}'
                    '${_updatedAt == null ? '' : '\nUpdated at: ${_updatedAt!.toLocal()}'}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed:
                        _isSaving ? null : _saveControl,
                    style: FilledButton.styleFrom(
                      backgroundColor: _yellow,
                      foregroundColor: Colors.black,
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : 'Save Global Control',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _controlCard({
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: child,
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: _isSaving ? null : onChanged,
      activeThumbColor: _yellow,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
      ),
    );
  }
}
