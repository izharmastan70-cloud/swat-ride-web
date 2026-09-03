import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/location_model.dart';
import '../services/agent_seat_service.dart';
import '../services/phone_call_dispatch_service.dart';

/// One independent in-progress phone call being handled by this agent.
///
/// Each session owns its own controllers so Customer A's draft never leaks
/// into or gets overwritten by Customer B's draft, even when both are open
/// as separate tabs at the same time.
class _CallSession {
  _CallSession(this.id, this.label);

  final String id;
  final String label;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController(text: '+92');
  final TextEditingController pickup = TextEditingController();
  final TextEditingController pickupLat = TextEditingController();
  final TextEditingController pickupLng = TextEditingController();
  final TextEditingController destination = TextEditingController();
  final TextEditingController destinationLat = TextEditingController();
  final TextEditingController destinationLng = TextEditingController();
  final TextEditingController distance = TextEditingController();
  final TextEditingController minutes = TextEditingController();

  String? driverId;
  bool submitting = false;
  String? lastMessage;
  Color lastMessageColor = Colors.green;

  void dispose() {
    for (final TextEditingController controller in <TextEditingController>[
      name,
      phone,
      pickup,
      pickupLat,
      pickupLng,
      destination,
      destinationLat,
      destinationLng,
      distance,
      minutes,
    ]) {
      controller.dispose();
    }
  }
}

class PhoneCallDispatchScreen extends StatefulWidget {
  const PhoneCallDispatchScreen({super.key});

  @override
  State<PhoneCallDispatchScreen> createState() =>
      _PhoneCallDispatchScreenState();
}

class _PhoneCallDispatchScreenState extends State<PhoneCallDispatchScreen> {
  static const int _maxConcurrentCallsPerAgent = 6;

  final PhoneCallDispatchService _service = PhoneCallDispatchService();
  final AgentSeatService _seatService = AgentSeatService();

  final List<_CallSession> _sessions = <_CallSession>[];
  int _activeIndex = 0;
  int _sessionCounter = 0;
  bool _splitView = false;
  int _splitIndex = 1;

  String? _agentId;
  String? _seatError;
  bool _seatGranted = false;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    _joinSeat();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    final String? agentId = _agentId;
    if (agentId != null) {
      unawaited(_seatService.leaveSeat(agentId));
    }
    for (final _CallSession session in _sessions) {
      session.dispose();
    }
    super.dispose();
  }

  Future<void> _joinSeat() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _seatError = 'Sign in before dispatching phone-call rides.');
      return;
    }

    _agentId = user.uid;
    try {
      await _seatService.joinSeat(
        agentId: user.uid,
        agentName: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : (user.email ?? user.uid),
      );
      if (!mounted) return;
      setState(() {
        _seatGranted = true;
        _seatError = null;
        _sessions.add(_newSession());
      });
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        _seatService.sendHeartbeat(user.uid);
      });
    } on AgentSeatLimitException catch (error) {
      if (mounted) setState(() => _seatError = error.toString());
    } catch (error) {
      if (mounted) {
        setState(() => _seatError = 'Unable to join the dispatch desk: $error');
      }
    }
  }

  _CallSession _newSession() {
    final String label = 'Customer ${String.fromCharCode(65 + (_sessionCounter % 26))}';
    _sessionCounter += 1;
    return _CallSession('session_${DateTime.now().microsecondsSinceEpoch}', label);
  }

  void _addSession() {
    if (_sessions.length >= _maxConcurrentCallsPerAgent) {
      _showTopMessage(
        'You can handle up to $_maxConcurrentCallsPerAgent simultaneous calls.',
        Colors.orange,
      );
      return;
    }
    setState(() {
      _sessions.add(_newSession());
      _activeIndex = _sessions.length - 1;
    });
  }

  void _closeSession(int index) {
    if (_sessions.length <= 1) {
      _showTopMessage('Keep at least one call tab open.', Colors.orange);
      return;
    }
    final _CallSession removed = _sessions[index];
    setState(() {
      _sessions.removeAt(index);
      removed.dispose();
      if (_activeIndex >= _sessions.length) {
        _activeIndex = _sessions.length - 1;
      }
      if (_splitIndex >= _sessions.length) {
        _splitIndex = _sessions.length > 1 ? _sessions.length - 1 : 0;
      }
    });
  }

  Future<void> _dispatch(_CallSession session) async {
    if (!session.formKey.currentState!.validate() || session.driverId == null) {
      setState(() {
        session.lastMessage = 'Select an available driver.';
        session.lastMessageColor = Colors.orange;
      });
      return;
    }
    setState(() => session.submitting = true);
    try {
      final result = await _service.dispatch(
        callSessionId: session.id,
        idempotencyKey: '${session.id}_${DateTime.now().microsecondsSinceEpoch}',
        passengerName: session.name.text,
        passengerPhone: session.phone.text,
        driverId: session.driverId!,
        pickupLocation: _location(session.pickup, session.pickupLat, session.pickupLng),
        destinationLocation: _location(session.destination, session.destinationLat, session.destinationLng),
        distanceKm: double.parse(session.distance.text),
        estimatedMinutes: int.parse(session.minutes.text),
        paymentMethod: 'cash',
      );
      if (!mounted) return;
      setState(() {
        session.lastMessage =
            'Ride ${result.reused ? 'already booked' : 'assigned'}: ${result.rideId}. '
            'Passenger notification: ${result.notificationStatus}.';
        session.lastMessageColor =
            result.notificationStatus == 'ACCEPTED' ? Colors.green : Colors.orange;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          session.lastMessage = error.toString().replaceFirst('Bad state: ', '');
          session.lastMessageColor = Colors.red;
        });
      }
    } finally {
      if (mounted) setState(() => session.submitting = false);
    }
  }

  Future<void> _cancelRide(String rideId) async {
    final TextEditingController reason = TextEditingController();
    final String? value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel phone booking?'),
        content: TextField(
          controller: reason,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Cancellation reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep ride'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, reason.text.trim()),
            child: const Text('Cancel ride'),
          ),
        ],
      ),
    );
    reason.dispose();
    if (value == null || value.isEmpty) return;
    try {
      await _service.cancel(rideId: rideId, reason: value);
      if (mounted) _showTopMessage('Ride cancelled. The driver has been released.', Colors.green);
    } catch (error) {
      if (mounted) {
        _showTopMessage(error.toString().replaceFirst('Bad state: ', ''), Colors.red);
      }
    }
  }

  LocationModel _location(
    TextEditingController address,
    TextEditingController latitude,
    TextEditingController longitude,
  ) => LocationModel(
    address: address.text.trim(),
    placeName: address.text.trim(),
    latitude: double.parse(latitude.text),
    longitude: double.parse(longitude.text),
  );

  void _showTopMessage(String value, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(value), backgroundColor: color));
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
  String? _number(String? value) => double.tryParse(value ?? '') == null ? 'Enter a number' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Call Dispatch'),
        actions: <Widget>[
          StreamBuilder<int>(
            stream: _seatService.watchActiveSeatCount(),
            builder: (context, snapshot) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text('Agents online: ${snapshot.data ?? '-'}/${AgentSeatService.maxConcurrentAgents}'),
              ),
            ),
          ),
          if (_sessions.length > 1)
            IconButton(
              tooltip: 'Split view',
              onPressed: () => setState(() => _splitView = !_splitView),
              icon: Icon(_splitView ? Icons.vertical_split : Icons.tab_unselected),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_seatGranted) {
      if (_seatError != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_seatError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _joinSeat, child: const Text('Retry')),
              ],
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildTabBar(),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool canSplit = _splitView && _sessions.length > 1 && constraints.maxWidth >= 900;
              if (canSplit) {
                return Row(
                  children: [
                    Expanded(child: _buildSessionPane(_sessions[_activeIndex])),
                    const VerticalDivider(width: 1),
                    Expanded(child: _buildSplitPane()),
                  ],
                );
              }
              return _buildSessionPane(_sessions[_activeIndex]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSplitPane() {
    final int index = _splitIndex < _sessions.length ? _splitIndex : 0;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: DropdownButton<int>(
            value: index,
            isExpanded: true,
            items: List<DropdownMenuItem<int>>.generate(
              _sessions.length,
              (i) => DropdownMenuItem<int>(value: i, child: Text(_sessions[i].label)),
            ),
            onChanged: (value) => setState(() => _splitIndex = value ?? 0),
          ),
        ),
        Expanded(child: _buildSessionPane(_sessions[index])),
      ],
    );
  }

  Widget _buildTabBar() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: [
          for (int i = 0; i < _sessions.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InputChip(
                selected: i == _activeIndex,
                label: Text(_sessions[i].label),
                onPressed: () => setState(() => _activeIndex = i),
                onDeleted: () => _closeSession(i),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Add call'),
              onPressed: _addSession,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionPane(_CallSession session) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('drivers')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        final drivers = (snapshot.data?.docs ?? const [])
            .where((driver) =>
                driver.data()['isAvailable'] == true && driver.data()['isSuspended'] != true)
            .toList();
        return Form(
          key: session.formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                session.label,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _field(session.name, 'Passenger name'),
              _field(session.phone, 'Passenger phone in E.164 format'),
              _field(session.pickup, 'Pickup address'),
              _coordinates(session.pickupLat, session.pickupLng, 'Pickup'),
              _field(session.destination, 'Destination address'),
              _coordinates(session.destinationLat, session.destinationLng, 'Destination'),
              _field(session.distance, 'Distance in km', number: true),
              _field(session.minutes, 'Estimated minutes', number: true),
              DropdownButtonFormField<String>(
                initialValue: session.driverId,
                decoration: const InputDecoration(labelText: 'Available driver'),
                items: drivers.map((driver) {
                  final data = driver.data();
                  return DropdownMenuItem(
                    value: driver.id,
                    child: Text('${data['fullName'] ?? data['name'] ?? 'Driver'} - ${data['vehicleNumber'] ?? ''}'),
                  );
                }).toList(),
                onChanged: session.submitting
                    ? null
                    : (value) => setState(() => session.driverId = value),
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: session.submitting ? null : () => _dispatch(session),
                icon: session.submitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.local_taxi),
                label: const Text('Assign Driver & Notify Passenger'),
              ),
              if (session.lastMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: session.lastMessageColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: session.lastMessageColor),
                  ),
                  child: Text(session.lastMessage!),
                ),
              ],
              const SizedBox(height: 28),
              const Text('Active phone bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildActiveBookings(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveBookings() {
    final String? myAgentId = _agentId;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .where('bookingSource', isEqualTo: 'agent_phone_call')
          .snapshots(),
      builder: (context, ridesSnapshot) {
        final rides = (ridesSnapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
            .where((ride) {
          final status = ride.data()['status'];
          return status == 'driver_assigned' || status == 'driver_arriving' || status == 'driver_arrived';
        }).toList();
        if (rides.isEmpty) return const Text('No active phone-call bookings.');
        return Column(
          children: rides.map((ride) {
            final data = ride.data();
            final pickup = data['pickupLocation'] as Map<String, dynamic>?;
            final bool isMine = data['bookedByAdminId'] == myAgentId;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_in_talk_outlined),
              title: Text('${data['riderName'] ?? 'Passenger'} - ${data['driverName'] ?? 'Driver'}'),
              subtitle: Text(pickup?['address']?.toString() ?? 'Pickup unavailable'),
              trailing: isMine
                  ? IconButton(
                      tooltip: 'Cancel booking',
                      onPressed: () => _cancelRide(ride.id),
                      icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                    )
                  : const Tooltip(
                      message: 'Locked to the agent who booked this ride.',
                      child: Icon(Icons.lock_outline, color: Colors.grey),
                    ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _field(TextEditingController controller, String label, {bool number = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: number ? _number : _required,
    ),
  );

  Widget _coordinates(TextEditingController latitude, TextEditingController longitude, String label) => Row(
    children: [
      Expanded(child: _field(latitude, '$label latitude', number: true)),
      const SizedBox(width: 12),
      Expanded(child: _field(longitude, '$label longitude', number: true)),
    ],
  );
}