import 'package:flutter/material.dart';

import '../services/super_admin_video_training_access_service.dart';

class SuperAdminVideoTrainingAccessScreen extends StatefulWidget {
  const SuperAdminVideoTrainingAccessScreen({super.key, required this.adminId});

  final String adminId;

  @override
  State<SuperAdminVideoTrainingAccessScreen> createState() =>
      _SuperAdminVideoTrainingAccessScreenState();
}

class _SuperAdminVideoTrainingAccessScreenState
    extends State<SuperAdminVideoTrainingAccessScreen> {
  final SuperAdminVideoTrainingAccessService _service =
      SuperAdminVideoTrainingAccessService();

  final TextEditingController _uidController = TextEditingController();

  final Set<String> _audiences = <String>{};

  bool _isActive = true;
  bool _busy = false;

  static const Map<String, String> _labels = <String, String>{
    'driver': 'Driver',
    'food_rider': 'Food Rider',
    'restaurant_partner': 'Restaurant Partner',
    'hotel_partner': 'Hotel Partner',
    'tourism_driver': 'Tourism Driver',
    'tour_guide': 'Tour Guide',
    'admin': 'Admin',
    'super_admin': 'Super Admin',
  };

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = _uidController.text.trim();

    if (uid.isEmpty) {
      _message('Enter Firebase user UID.');
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final data = await _service.getAccess(uid);

      if (!mounted) {
        return;
      }

      final raw = data?['allowedAudiences'];

      final loaded = raw is Iterable
          ? raw
                .map((item) => item.toString().trim().toLowerCase())
                .where(
                  SuperAdminVideoTrainingAccessService
                      .allowedAudiences
                      .contains,
                )
                .toSet()
          : <String>{};

      setState(() {
        _audiences
          ..clear()
          ..addAll(loaded);

        _isActive = data == null ? true : data['isActive'] == true;
      });

      _message(
        data == null
            ? 'No existing private training access found.'
            : 'Private training access loaded.',
      );
    } catch (error) {
      if (mounted) {
        _message('Could not load access: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final uid = _uidController.text.trim();

    if (uid.isEmpty) {
      _message('Enter Firebase user UID.');
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await _service.saveAccess(
        userId: uid,
        audiences: _audiences,
        isActive: _isActive,
        adminId: widget.adminId,
      );

      if (mounted) {
        _message('Private training access saved.');
      }
    } catch (error) {
      if (mounted) {
        _message('Could not save access: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Private Training Access')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            'Grant private SWAT RIDE training only to an '
            'already-authorized role account.',
          ),
          const SizedBox(height: 8),
          const Text(
            'This entitlement does not approve a Driver/Partner role '
            'and does not change operational permissions.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _uidController,
            decoration: const InputDecoration(
              labelText: 'Firebase user UID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.search),
            label: const Text('Load existing access'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Allowed private training audiences',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._labels.entries.map(
            (entry) => CheckboxListTile(
              value: _audiences.contains(entry.key),
              title: Text(entry.value),
              contentPadding: EdgeInsets.zero,
              onChanged: _busy
                  ? null
                  : (selected) {
                      setState(() {
                        if (selected == true) {
                          _audiences.add(entry.key);
                        } else {
                          _audiences.remove(entry.key);
                        }
                      });
                    },
            ),
          ),
          const Divider(),
          SwitchListTile(
            value: _isActive,
            title: const Text('Private training access active'),
            contentPadding: EdgeInsets.zero,
            onChanged: _busy
                ? null
                : (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_busy ? 'Saving...' : 'Save private training access'),
          ),
        ],
      ),
    );
  }
}
