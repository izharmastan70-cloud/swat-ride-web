import 'package:flutter/material.dart';

import '../models/agent_student_assessment.dart';
import '../services/agent_student_agent.dart';

// =========================================================
// AI AGENT — STUDENT FOUNDATION SCREEN
// =========================================================

class AgentStudentFoundationScreen extends StatefulWidget {
  const AgentStudentFoundationScreen({super.key});

  @override
  State<AgentStudentFoundationScreen> createState() =>
      _AgentStudentFoundationScreenState();
}

class _AgentStudentFoundationScreenState
    extends State<AgentStudentFoundationScreen> {
  final TextEditingController _controller = TextEditingController();
  final AgentStudentAgent _agent = const AgentStudentAgent();

  AgentStudentAssessment? _assessment;
  String _response = '';

  void _assess() {
    final AgentStudentAssessment assessment =
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
        title: const Text('Student Ride Agent Foundation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            'Student Agent is OFF/disabled until Student Ride + safety testing is complete.',
            style: TextStyle(color: Colors.orangeAccent),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Test a Student Ride support/safety message...',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _assess,
            child: const Text('ASSESS SAFELY'),
          ),
          if (_assessment != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              'Intent: ${_assessment!.intent}\n'
              'Risk: ${_assessment!.risk}\n'
              'Human: ${_assessment!.requiresHuman}\n'
              'Safety escalation: ${_assessment!.requiresSafetyEscalation}\n'
              'Write approval: ${_assessment!.requiresApprovalForWrite}',
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
