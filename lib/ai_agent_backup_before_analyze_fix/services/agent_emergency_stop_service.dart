import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_audit_constants.dart';
import '../models/agent_master_settings.dart';
import 'agent_audit_service.dart';

// =========================================================
// AI AGENT — EMERGENCY STOP SERVICE
// =========================================================
//
// Emergency Stop behavior:
// - forces emergencyReadOnly = true
// - disables Paid Code AI
// - disables Call Agent write/automation master switch
// - preserves normal SWAT RIDE app functionality
//
// It does NOT touch Ride/Food/Hotel/etc. because connectors are not built yet.
//
// Releasing Emergency Stop is a separate explicit owner/admin action.
// It does NOT automatically re-enable Paid Code AI or Call Agent.

class AgentEmergencyStopService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AgentAuditService _auditService = AgentAuditService();

  static const String _collectionPath = 'agent_settings';

  DocumentReference<Map<String, dynamic>> get _document =>
      _firestore
          .collection(_collectionPath)
          .doc(AgentMasterSettings.documentId);

  Future<void> activate({
    required String actorId,
    required String reason,
  }) async {
    final String safeReason = reason.trim().isEmpty
        ? 'Emergency Stop activated by owner/admin.'
        : reason.trim();

    await _document.set(
      <String, dynamic>{
        'emergencyReadOnly': true,
        'paidCodeAiEnabled': false,
        'callAgentEnabled': false,
        'emergencyActivatedAt': FieldValue.serverTimestamp(),
        'emergencyActivatedBy': actorId,
        'emergencyReason': safeReason,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await _auditService.append(
      eventType: AgentAuditEventType.systemEvent,
      severity: AgentAuditSeverity.critical,
      actorType: AgentAuditActorType.admin,
      actorId: actorId,
      module: 'ai_core',
      actionId: 'ai.emergency.activate',
      result: 'READ_ONLY_LOCK',
      reason: safeReason,
    );
  }

  Future<void> release({
    required String actorId,
    required String reason,
  }) async {
    final String safeReason = reason.trim().isEmpty
        ? 'Emergency Stop released by owner/admin.'
        : reason.trim();

    await _document.set(
      <String, dynamic>{
        'emergencyReadOnly': false,
        'emergencyActivatedAt': null,
        'emergencyActivatedBy': actorId,
        'emergencyReason': safeReason,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await _auditService.append(
      eventType: AgentAuditEventType.systemEvent,
      severity: AgentAuditSeverity.high,
      actorType: AgentAuditActorType.admin,
      actorId: actorId,
      module: 'ai_core',
      actionId: 'ai.emergency.release',
      result: 'RELEASED',
      reason: safeReason,
      metadata: const <String, dynamic>{
        'paidCodeAiAutoReenabled': false,
        'callAgentAutoReenabled': false,
      },
    );
  }
}
