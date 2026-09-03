import 'package:flutter/material.dart';

import '../constants/agent_call_constants.dart';
import '../models/agent_call_ride_booking_draft.dart';
import '../models/agent_call_session.dart';
import '../services/agent_call_agent.dart';

// =========================================================
// AI AGENT — CALL TEST SCREEN
// =========================================================
//
// Local/admin test UI only. No real phone call is placed.

class AgentCallTestScreen extends StatefulWidget {
  const AgentCallTestScreen({super.key});

  @override
  State<AgentCallTestScreen> createState() =>
      _AgentCallTestScreenState();
}

class _AgentCallTestScreenState extends State<AgentCallTestScreen> {
  final AgentCallAgent _agent = AgentCallAgent();

  AgentCallSession? _session;
  AgentCallRideBookingDraft? _draft;
  String _message = 'No test session started.';

  Future<void> _start() async {
    final AgentCallSession session =
        await _agent.startTestSession(
      callerName: 'Test Caller',
      callerPhone: '03001234567',
      intent: AgentCallIntent.rideBooking,
    );

    if (mounted) {
      setState(() {
        _session = session;
        _message = 'TEST call session started.';
      });
    }
  }

  void _prepareRideDraft() {
    final AgentCallRideBookingDraft draft =
        _agent.buildRideDraft(
      customerName: 'Test Caller',
      phone: '03001234567',
      pickup: 'Pickup Test Location',
      destination: 'Destination Test Location',
      vehicleType: 'car',
      customerConfirmed: false,
    );

    setState(() {
      _draft = draft;
      _message =
          'Ride draft prepared. Real ride has NOT been booked.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Call Agent — Test Mode'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ElevatedButton(
              onPressed: _start,
              child: const Text('START TEST SESSION'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _session == null ? null : _prepareRideDraft,
              child: const Text('PREPARE RIDE DRAFT'),
            ),
            const SizedBox(height: 16),
            Text(
              _message,
              style: const TextStyle(color: Colors.white70),
            ),
            if (_session != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'Session: ${_session!.sessionId}\n'
                'Phone: ${_session!.callerPhoneMasked}\n'
                'Mode: ${_session!.mode}\n'
                'Recording: ${_session!.recordingEnabled}',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
            if (_draft != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'Pickup: ${_draft!.pickup}\n'
                'Destination: ${_draft!.destination}\n'
                'Vehicle: ${_draft!.vehicleType}\n'
                'Confirmed: ${_draft!.customerConfirmed}',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
            const SizedBox(height: 18),
            const Text(
              'TEST MODE ONLY — no real number, no call recording, '
              'no real ride write, no telephony charges.',
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ],
        ),
      ),
    );
  }
}
