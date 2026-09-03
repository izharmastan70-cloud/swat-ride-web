import 'package:flutter/material.dart';

import '../models/agent_cargo_assessment.dart';
import '../services/agent_cargo_agent.dart';

// =========================================================
// AI AGENT — CARGO FOUNDATION SCREEN
// =========================================================
//
// Standalone Phase 19 demo/visibility screen.
// No real Cargo booking is read or written.

class AgentCargoFoundationScreen extends StatefulWidget {
  const AgentCargoFoundationScreen({super.key});

  @override
  State<AgentCargoFoundationScreen> createState() =>
      _AgentCargoFoundationScreenState();
}

class _AgentCargoFoundationScreenState
    extends State<AgentCargoFoundationScreen> {
  final TextEditingController _controller = TextEditingController();
  final AgentCargoAgent _agent = const AgentCargoAgent();

  AgentCargoAssessment? _assessment;
  String _response = '';

  void _assess() {
    final AgentCargoAssessment assessment =
        _agent.assess(_controller.text);

    setState(() {
      _assessment = assessment;
      _response = _agent.safeResponseFor(assessment);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Cargo Agent Foundation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            'Cargo Agent is OFF/disabled until the real Cargo module is complete.',
            style: TextStyle(color: Colors.orangeAccent),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Test a cargo support/request message...',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _assess,
            child: const Text('ASSESS'),
          ),
          if (_assessment != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              'Intent: ${_assessment!.intent}\n'
              'Risk: ${_assessment!.risk}\n'
              'Human review: ${_assessment!.requiresHumanReview}\n'
              'Approval for action: ${_assessment!.requiresApprovalForAction}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Text(
              _response,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }
}
