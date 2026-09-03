import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/ride_broadcast_service.dart';

class RideBroadcastManagementScreen extends StatefulWidget {
  const RideBroadcastManagementScreen({
    super.key,
    required this.adminId,
    required this.adminName,
  });
  final String adminId;
  final String adminName;
  @override
  State<RideBroadcastManagementScreen> createState() =>
      _RideBroadcastManagementScreenState();
}

class _RideBroadcastManagementScreenState
    extends State<RideBroadcastManagementScreen> {
  final RideBroadcastService _service = RideBroadcastService();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();
  final TextEditingController _target = TextEditingController();
  String _audience = 'both';
  bool _saving = false;
  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ride Notifications & Broadcast')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'New broadcast',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _audience,
                  decoration: const InputDecoration(labelText: 'Audience'),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'riders', child: Text('Riders')),
                    DropdownMenuItem(value: 'drivers', child: Text('Drivers')),
                    DropdownMenuItem(
                      value: 'both',
                      child: Text('Riders + Drivers'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _audience = v ?? 'both'),
                ),
                TextField(
                  controller: _title,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: _body,
                  maxLength: 1000,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Message'),
                ),
                TextField(
                  controller: _target,
                  decoration: const InputDecoration(
                    labelText: 'Optional deep-link / module target',
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(_saving ? 'SAVING...' : 'RECORD BROADCAST'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Real push delivery is intentionally provider-gated; this stores admin-approved history and scheduled-delivery metadata.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Send history',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _service.watchBroadcasts(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Text('Unable to load history: ${snap.error}');
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Text('No Ride broadcasts yet.');
            }
            return Column(
              children: docs.map((d) {
                final x = d.data();
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.campaign_outlined),
                    title: Text(x['title']?.toString() ?? ''),
                    subtitle: Text(
                      '${x['audience'] ?? 'both'} ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¢ ${x['status'] ?? 'recorded'}\n${x['body'] ?? ''}',
                    ),
                    isThreeLine: true,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    ),
  );

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _service.createBroadcast(
        audience: _audience,
        title: _title.text,
        body: _body.text,
        target: _target.text,
        createdBy: widget.adminId,
        createdByName: widget.adminName,
      );
      _title.clear();
      _body.clear();
      _target.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Broadcast recorded.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
