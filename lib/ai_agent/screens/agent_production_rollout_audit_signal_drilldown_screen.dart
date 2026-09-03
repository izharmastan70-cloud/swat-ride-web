import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../super_admin/services/super_admin_access_service.dart';
import '../models/agent_audit_log.dart';

class AgentProductionRolloutAuditSignalDrilldownScreen extends StatefulWidget {
  const AgentProductionRolloutAuditSignalDrilldownScreen({
    super.key,
    required this.currentAdminId,
  });

  final String currentAdminId;

  @override
  State<AgentProductionRolloutAuditSignalDrilldownScreen> createState() =>
      _AgentProductionRolloutAuditSignalDrilldownScreenState();
}

class _AgentProductionRolloutAuditSignalDrilldownScreenState
    extends State<AgentProductionRolloutAuditSignalDrilldownScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final SuperAdminAccessService _accessService = SuperAdminAccessService(
    auth: _auth,
    firestore: _firestore,
  );

  bool _working = false;
  String _message = 'Read the post-activation HIGH/CRITICAL audit records.';
  List<AgentAuditLog> _events = const <AgentAuditLog>[];

  Future<void> _run() async {
    if (_working) return;

    setState(() {
      _working = true;
      _message = 'Reading post-activation HIGH/CRITICAL audit records...';
      _events = const <AgentAuditLog>[];
    });

    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        throw StateError('Firebase Super Admin sign-in required.');
      }

      final access = await _accessService.checkCurrentAccess(
        forceRefreshToken: true,
      );

      final IdTokenResult token = await user.getIdTokenResult(true);
      final Map<String, dynamic> claims = token.claims ?? <String, dynamic>{};

      final String role = claims['role']?.toString().trim().toLowerCase() ?? '';

      if (user.uid != widget.currentAdminId.trim() ||
          !access.isAllowed ||
          !access.isSuperAdmin ||
          access.isTestingBypass ||
          role != 'super_admin') {
        throw StateError(
          'Audit drilldown requires verified Firebase super_admin.',
        );
      }

      final DocumentSnapshot<Map<String, dynamic>> rolloutSnapshot =
          await _firestore
              .collection('agent_settings')
              .doc('production_rollout')
              .get();

      final Map<String, dynamic> rollout =
          rolloutSnapshot.data() ?? <String, dynamic>{};

      if (!rolloutSnapshot.exists ||
          rollout['stage'] != 'MONITOR_ONLY' ||
          _intValue(rollout['autoTrafficPercent']) != 0 ||
          _intValue(rollout['businessWriteTrafficPercent']) != 0 ||
          rollout['externalChannelsEnabled'] != false) {
        throw StateError(
          'Audit drilldown requires clean MONITOR_ONLY rollout.',
        );
      }

      final DateTime? activatedAtUtc = _timestampUtc(rollout['activatedAt']);

      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('agent_audit_logs')
          .orderBy('createdAt', descending: true)
          .limit(300)
          .get();

      final List<AgentAuditLog> events = snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                AgentAuditLog.fromSnapshot(doc),
          )
          .where(
            (AgentAuditLog event) =>
                (activatedAtUtc == null ||
                    !event.createdAt.toUtc().isBefore(activatedAtUtc)) &&
                (event.severity == 'HIGH' || event.severity == 'CRITICAL'),
          )
          .toList(growable: false);

      if (!mounted) return;

      setState(() {
        _events = events;
        _message = events.isEmpty
            ? 'No post-activation HIGH/CRITICAL audit records found.'
            : '${events.length} post-activation HIGH/CRITICAL audit record(s) found. '
                  'Review exact actionId/result before clearing the signal.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _message = 'Audit drilldown blocked safely: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Signal Drilldown')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'READ-ONLY. Shows only bounded post-activation HIGH/CRITICAL '
                'audit metadata needed to classify the Step 1H-B signal. '
                'No Firestore write, status transition, approval consumption, '
                'provider execution, mode change or rollout change.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _working ? null : _run,
            icon: const Icon(Icons.manage_search_outlined),
            label: const Text('RUN AUDIT SIGNAL DRILLDOWN'),
          ),
          if (_working) ...<Widget>[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_message),
            ),
          ),
          for (final AgentAuditLog event in _events) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              color: event.severity == 'CRITICAL'
                  ? const Color(0xFF4A1010)
                  : const Color(0xFF4A3A10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _row('Severity', event.severity),
                    _row('Created UTC', event.createdAt.toUtc().toString()),
                    _row('Event type', event.eventType),
                    _row('Module', event.module),
                    _row('Action ID', event.actionId),
                    _row('Result', event.result),
                    _row('Actor type', event.actorType),
                    _row('Role ID', event.roleId),
                    _row('Related approval', _short(event.relatedApprovalId)),
                    _row('Reason', _safeReason(event.reason)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Do not clear or advance rollout from this screen. '
                'If the records are only the known Emergency Stop activation '
                'and controlled recovery release, classify them separately '
                'from new runtime/security incidents after review.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  int _intValue(dynamic value) => value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? -1;

  DateTime? _timestampUtc(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toUtc();
    }

    return null;
  }

  String _short(String value) {
    final String clean = value.trim();

    if (clean.isEmpty || clean.length <= 20) return clean;
    return '${clean.substring(0, 10)}...${clean.substring(clean.length - 8)}';
  }

  String _safeReason(String value) {
    final String clean = value.trim();

    if (clean.isEmpty) return '-';
    if (clean.length <= 180) return clean;
    return '${clean.substring(0, 180)}...';
  }

  bool get writesFirestore => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
