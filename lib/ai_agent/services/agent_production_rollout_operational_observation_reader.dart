import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../super_admin/services/super_admin_access_service.dart';
import '../constants/agent_audit_constants.dart';
import '../constants/agent_crash_constants.dart';
import '../constants/agent_owner_attention_constants.dart';
import '../models/agent_audit_log.dart';
import '../models/agent_crash_event.dart';
import '../models/agent_owner_attention_inbox_record.dart';
import '../models/agent_production_rollout_operational_observation_models.dart';

class AgentProductionRolloutOperationalObservationReader {
  factory AgentProductionRolloutOperationalObservationReader({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    SuperAdminAccessService? accessService,
  }) {
    final FirebaseAuth resolvedAuth = auth ?? FirebaseAuth.instance;
    final FirebaseFirestore resolvedFirestore =
        firestore ?? FirebaseFirestore.instance;

    return AgentProductionRolloutOperationalObservationReader._(
      resolvedAuth,
      resolvedFirestore,
      accessService ??
          SuperAdminAccessService(
            auth: resolvedAuth,
            firestore: resolvedFirestore,
          ),
    );
  }

  AgentProductionRolloutOperationalObservationReader._(
    this._auth,
    this._firestore,
    this._accessService,
  );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SuperAdminAccessService _accessService;

  static const int auditReadLimit = 300;
  static const int crashReadLimit = 200;
  static const int ownerAttentionReadLimit = 100;

  Future<AgentProductionRolloutOperationalObservation> read({
    required String currentAdminId,
  }) async {
    await _requireVerifiedSuperAdmin(currentAdminId);

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
        'Operational observation requires clean MONITOR_ONLY rollout state.',
      );
    }

    final DateTime? activatedAtUtc = _timestampUtc(rollout['activatedAt']);

    final QuerySnapshot<Map<String, dynamic>> auditSnapshot = await _firestore
        .collection('agent_audit_logs')
        .orderBy('createdAt', descending: true)
        .limit(auditReadLimit)
        .get();

    final List<AgentAuditLog> auditLogs = auditSnapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              AgentAuditLog.fromSnapshot(doc),
        )
        .where(
          (AgentAuditLog log) =>
              activatedAtUtc == null ||
              !log.createdAt.toUtc().isBefore(activatedAtUtc),
        )
        .toList(growable: false);

    final QuerySnapshot<Map<String, dynamic>> crashSnapshot = await _firestore
        .collection('agent_crash_events')
        .orderBy('lastSeenAt', descending: true)
        .limit(crashReadLimit)
        .get();

    final List<AgentCrashEvent> crashes = crashSnapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              AgentCrashEvent.fromSnapshot(doc),
        )
        .where(
          (AgentCrashEvent event) =>
              activatedAtUtc == null ||
              !event.lastSeenAt.toUtc().isBefore(activatedAtUtc),
        )
        .toList(growable: false);

    final QuerySnapshot<Map<String, dynamic>> attentionSnapshot =
        await _firestore
            .collection('agent_owner_attention_inbox')
            .orderBy('createdAtUtc', descending: true)
            .limit(ownerAttentionReadLimit)
            .get();

    final List<AgentOwnerAttentionInboxRecord> attention = attentionSnapshot
        .docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              AgentOwnerAttentionInboxRecord.fromMap(doc.data()),
        )
        .where(
          (AgentOwnerAttentionInboxRecord record) =>
              activatedAtUtc == null ||
              !record.event.createdAtUtc.isBefore(activatedAtUtc),
        )
        .toList(growable: false);

    final int highAudit = auditLogs
        .where((AgentAuditLog log) => log.severity == AgentAuditSeverity.high)
        .length;

    final int criticalAudit = auditLogs
        .where(
          (AgentAuditLog log) => log.severity == AgentAuditSeverity.critical,
        )
        .length;

    final int knownRecoveryControlAudit = auditLogs
        .where(_isKnownRecoveryControlAudit)
        .length;

    final int unclassifiedCriticalAudit = auditLogs
        .where(
          (AgentAuditLog log) =>
              log.severity == AgentAuditSeverity.critical &&
              !_isKnownRecoveryControlAudit(log),
        )
        .length;

    final int failureAudit = auditLogs.where(_isFailureAudit).length;
    final int securityAudit = auditLogs.where(_isSecurityAudit).length;

    final List<AgentCrashEvent> openCrashes = crashes
        .where(
          (AgentCrashEvent event) =>
              event.status == AgentCrashStatus.open ||
              event.status == AgentCrashStatus.classified ||
              event.status == AgentCrashStatus.handedToCodeAgent,
        )
        .toList(growable: false);

    final int highCrash = openCrashes
        .where(
          (AgentCrashEvent event) => event.severity == AgentCrashSeverity.high,
        )
        .length;

    final int criticalCrash = openCrashes
        .where(
          (AgentCrashEvent event) =>
              event.severity == AgentCrashSeverity.critical,
        )
        .length;

    final int repeatedCrash = openCrashes
        .where((AgentCrashEvent event) => event.occurrenceCount >= 3)
        .length;

    final List<AgentOwnerAttentionInboxRecord> unresolvedAttention = attention
        .where(
          (AgentOwnerAttentionInboxRecord record) =>
              record.event.status != AgentOwnerAttentionStatus.resolved &&
              record.event.status != AgentOwnerAttentionStatus.dismissed,
        )
        .toList(growable: false);

    final int criticalAttention = unresolvedAttention
        .where(
          (AgentOwnerAttentionInboxRecord record) =>
              record.event.priority == AgentOwnerAttentionPriority.critical,
        )
        .length;

    final int emergencyAttention = unresolvedAttention
        .where(
          (AgentOwnerAttentionInboxRecord record) =>
              record.event.priority == AgentOwnerAttentionPriority.emergency,
        )
        .length;

    final int securityAttention = unresolvedAttention
        .where(
          (AgentOwnerAttentionInboxRecord record) =>
              record.event.category ==
              AgentOwnerAttentionCategory.securityAlert,
        )
        .length;

    final int crashAttention = unresolvedAttention
        .where(
          (AgentOwnerAttentionInboxRecord record) =>
              record.event.category ==
              AgentOwnerAttentionCategory.criticalCrash,
        )
        .length;

    final int fraudAttention = unresolvedAttention
        .where(
          (AgentOwnerAttentionInboxRecord record) =>
              record.event.category == AgentOwnerAttentionCategory.fraudFinding,
        )
        .length;

    final int emergencyCaseAttention = unresolvedAttention
        .where(
          (AgentOwnerAttentionInboxRecord record) =>
              record.event.category ==
              AgentOwnerAttentionCategory.emergencyCase,
        )
        .length;

    final List<String> failures = <String>[];

    if (unclassifiedCriticalAudit > 0) {
      failures.add('UNCLASSIFIED_CRITICAL_AUDIT_EVENT_DETECTED');
    }
    if (criticalCrash > 0) {
      failures.add('CRITICAL_OPEN_CRASH_DETECTED');
    }
    if (emergencyAttention > 0) {
      failures.add('EMERGENCY_OWNER_ATTENTION_DETECTED');
    }
    if (securityAttention > 0) {
      failures.add('SECURITY_OWNER_ATTENTION_DETECTED');
    }
    if (fraudAttention > 0) {
      failures.add('FRAUD_OWNER_ATTENTION_DETECTED');
    }
    if (emergencyCaseAttention > 0) {
      failures.add('EMERGENCY_CASE_OWNER_ATTENTION_DETECTED');
    }

    return AgentProductionRolloutOperationalObservation(
      observedAtUtc: DateTime.now().toUtc(),
      rolloutActivatedAtUtc: activatedAtUtc,
      auditEventsObserved: auditLogs.length,
      highAuditEvents: highAudit,
      criticalAuditEvents: criticalAudit,
      knownRecoveryControlAuditEvents: knownRecoveryControlAudit,
      unclassifiedCriticalAuditEvents: unclassifiedCriticalAudit,
      failureAuditEvents: failureAudit,
      securityAuditSignals: securityAudit,
      openCrashEvents: openCrashes.length,
      highCrashEvents: highCrash,
      criticalCrashEvents: criticalCrash,
      repeatedCrashEvents: repeatedCrash,
      ownerAttentionObserved: attention.length,
      unresolvedOwnerAttention: unresolvedAttention.length,
      criticalOwnerAttention: criticalAttention,
      emergencyOwnerAttention: emergencyAttention,
      securityOwnerAttention: securityAttention,
      crashOwnerAttention: crashAttention,
      fraudOwnerAttention: fraudAttention,
      emergencyCaseOwnerAttention: emergencyCaseAttention,
      dedicatedSecurityIncidentStoreAvailable: false,
      failureCodes: List<String>.unmodifiable(failures),
    );
  }

  Future<void> _requireVerifiedSuperAdmin(String currentAdminId) async {
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

    if (user.uid != currentAdminId.trim() ||
        !access.isAllowed ||
        !access.isSuperAdmin ||
        access.isTestingBypass ||
        role != 'super_admin') {
      throw StateError(
        'Operational observation requires verified Firebase super_admin.',
      );
    }
  }

  bool _isKnownRecoveryControlAudit(AgentAuditLog log) {
    final String module = log.module.trim().toLowerCase();
    final String actionId = log.actionId.trim().toLowerCase();
    final String result = log.result.trim().toUpperCase();
    final String actorType = log.actorType.trim().toUpperCase();
    final String reason = log.reason.trim();

    final bool knownEmergencyActivation =
        module == 'ai_core' &&
        actionId == 'ai.emergency.activate' &&
        result == 'READ_ONLY_LOCK' &&
        actorType == 'ADMIN' &&
        reason == 'Manual Emergency Stop from AI Master Control.';

    final bool knownControlledRecoveryRelease =
        module == 'ai_core' &&
        actionId == 'ai.emergency.release' &&
        result == 'RELEASED' &&
        actorType == 'ADMIN' &&
        reason ==
            'Phase66 Step1G controlled MONITOR_ONLY recovery after clean immutable activation-artifact precheck.';

    return knownEmergencyActivation || knownControlledRecoveryRelease;
  }

  bool _isFailureAudit(AgentAuditLog log) {
    final String eventType = log.eventType.trim().toUpperCase();
    final String result = log.result.trim().toUpperCase();

    return eventType == AgentAuditEventType.taskFailed ||
        eventType == AgentAuditEventType.providerRequestFailed ||
        result.contains('FAIL') ||
        result.contains('BLOCKED');
  }

  bool _isSecurityAudit(AgentAuditLog log) {
    final String module = log.module.trim().toLowerCase();
    final String actionId = log.actionId.trim().toLowerCase();
    final String reason = log.reason.trim().toLowerCase();

    return module.contains('security') ||
        module.contains('guardian') ||
        module.contains('incident') ||
        actionId.contains('security') ||
        actionId.contains('guardian') ||
        actionId.contains('incident') ||
        reason.contains('security incident') ||
        reason.contains('unauthorized') ||
        reason.contains('prompt injection');
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

  bool get writesFirestore => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get enablesProviders => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
  bool get dedicatedSecurityIncidentPersistenceAssumed => false;
}
