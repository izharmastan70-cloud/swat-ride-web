import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_audit_constants.dart';
import '../models/agent_website_deployment_activation_settings.dart';
import 'agent_audit_service.dart';

/// Firestore-backed policy state for controlled website deployment activation.
///
/// IMPORTANT:
/// This service stores and audits activation policy only.
///
/// It does NOT:
/// - execute Git;
/// - push to GitHub;
/// - execute Vercel;
/// - read deployment secrets;
/// - execute shell/process commands.
///
/// Real deployment authority remains a separate later boundary.
class AgentWebsiteDeploymentActivationSettingsService {
  static const String _collectionPath = 'agent_settings';

  final FirebaseFirestore _firestore;
  final AgentAuditService _auditService;

  AgentWebsiteDeploymentActivationSettingsService({
    FirebaseFirestore? firestore,
    AgentAuditService? auditService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auditService = auditService ?? AgentAuditService();

  DocumentReference<Map<String, dynamic>> get _document => _firestore
      .collection(_collectionPath)
      .doc(AgentWebsiteDeploymentActivationSettings.documentId);

  Future<AgentWebsiteDeploymentActivationSettings> getSettings() async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _document
        .get();

    final Map<String, dynamic>? data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return AgentWebsiteDeploymentActivationSettings.safeDefaults();
    }

    return AgentWebsiteDeploymentActivationSettings.fromMap(data);
  }

  Stream<AgentWebsiteDeploymentActivationSettings> watchSettings() {
    return _document.snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      final Map<String, dynamic>? data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return AgentWebsiteDeploymentActivationSettings.safeDefaults();
      }

      return AgentWebsiteDeploymentActivationSettings.fromMap(data);
    });
  }

  Future<AgentWebsiteDeploymentActivationSettings> ensureSafeDefaults({
    required String actorId,
  }) async {
    final String safeActorId = _requireActor(actorId);

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _document
        .get();

    final Map<String, dynamic>? data = snapshot.data();

    if (snapshot.exists && data != null) {
      return AgentWebsiteDeploymentActivationSettings.fromMap(data);
    }

    final AgentWebsiteDeploymentActivationSettings defaults =
        AgentWebsiteDeploymentActivationSettings.safeDefaults();

    defaults.validate();

    await _document.set(defaults.toMap());

    await _audit(
      actorId: safeActorId,
      actionId: 'ai.website_deployment.activation.bootstrap',
      result: 'SAFE_DEFAULTS_CREATED',
      reason: 'Created fail-closed website deployment activation settings.',
    );

    return defaults;
  }

  Future<AgentWebsiteDeploymentActivationSettings> setDeploymentEnabled({
    required bool enabled,
    required String actorId,
    required String reason,
  }) async {
    final String safeActorId = _requireActor(actorId);
    final String safeReason = _requireReason(reason);

    final AgentWebsiteDeploymentActivationSettings current =
        await getSettings();

    final AgentWebsiteDeploymentActivationSettings next = enabled
        ? current.copyWith(
            deploymentEnabled: true,
            reason: safeReason,
            updatedBy: safeActorId,
            updatedAt: DateTime.now(),
          )
        : current.copyWith(
            deploymentEnabled: false,
            gitConnectedProviderEnabled: false,
            livePushActivationApproved: false,
            liveDeploymentActivationApproved: false,
            reason: safeReason,
            updatedBy: safeActorId,
            updatedAt: DateTime.now(),
          );

    await _saveAndAudit(
      settings: next,
      actorId: safeActorId,
      actionId: 'ai.website_deployment.activation.master',
      result: enabled ? 'ON' : 'OFF',
      reason: safeReason,
    );

    return next;
  }

  Future<AgentWebsiteDeploymentActivationSettings>
  setGitConnectedProviderEnabled({
    required bool enabled,
    required String actorId,
    required String reason,
  }) async {
    final String safeActorId = _requireActor(actorId);
    final String safeReason = _requireReason(reason);

    final AgentWebsiteDeploymentActivationSettings current =
        await getSettings();

    if (enabled && !current.deploymentEnabled) {
      throw const AgentWebsiteDeploymentActivationSettingsServiceException(
        'Website deployment master must be ON before enabling Git-connected provider.',
      );
    }

    final AgentWebsiteDeploymentActivationSettings next = enabled
        ? current.copyWith(
            gitConnectedProviderEnabled: true,
            reason: safeReason,
            updatedBy: safeActorId,
            updatedAt: DateTime.now(),
          )
        : current.copyWith(
            gitConnectedProviderEnabled: false,
            livePushActivationApproved: false,
            liveDeploymentActivationApproved: false,
            reason: safeReason,
            updatedBy: safeActorId,
            updatedAt: DateTime.now(),
          );

    await _saveAndAudit(
      settings: next,
      actorId: safeActorId,
      actionId: 'ai.website_deployment.activation.git_provider',
      result: enabled ? 'ON' : 'OFF',
      reason: safeReason,
    );

    return next;
  }

  Future<AgentWebsiteDeploymentActivationSettings> setLiveActivationApproved({
    required bool approved,
    required String actorId,
    required String reason,
  }) async {
    final String safeActorId = _requireActor(actorId);
    final String safeReason = _requireReason(reason);

    final AgentWebsiteDeploymentActivationSettings current =
        await getSettings();

    if (approved) {
      if (!current.deploymentEnabled) {
        throw const AgentWebsiteDeploymentActivationSettingsServiceException(
          'Website deployment master must be ON before live activation approval.',
        );
      }

      if (!current.gitConnectedProviderEnabled) {
        throw const AgentWebsiteDeploymentActivationSettingsServiceException(
          'Git-connected provider must be ON before live activation approval.',
        );
      }

      if (current.emergencyBlocked) {
        throw const AgentWebsiteDeploymentActivationSettingsServiceException(
          'Live activation cannot be approved while emergency block is active.',
        );
      }
    }

    final AgentWebsiteDeploymentActivationSettings next = current.copyWith(
      livePushActivationApproved: approved,
      liveDeploymentActivationApproved: approved,
      reason: safeReason,
      updatedBy: safeActorId,
      updatedAt: DateTime.now(),
    );

    await _saveAndAudit(
      settings: next,
      actorId: safeActorId,
      actionId: 'ai.website_deployment.activation.live_authority_intent',
      result: approved ? 'APPROVED' : 'REVOKED',
      reason: safeReason,
    );

    return next;
  }

  Future<AgentWebsiteDeploymentActivationSettings> setEmergencyBlocked({
    required bool blocked,
    required String actorId,
    required String reason,
  }) async {
    final String safeActorId = _requireActor(actorId);
    final String safeReason = _requireReason(reason);

    final AgentWebsiteDeploymentActivationSettings current =
        await getSettings();

    final AgentWebsiteDeploymentActivationSettings next = blocked
        ? current.copyWith(
            emergencyBlocked: true,
            livePushActivationApproved: false,
            liveDeploymentActivationApproved: false,
            reason: safeReason,
            updatedBy: safeActorId,
            updatedAt: DateTime.now(),
          )
        : current.copyWith(
            emergencyBlocked: false,
            reason: safeReason,
            updatedBy: safeActorId,
            updatedAt: DateTime.now(),
          );

    await _saveAndAudit(
      settings: next,
      actorId: safeActorId,
      actionId: 'ai.website_deployment.activation.emergency_block',
      result: blocked ? 'BLOCKED' : 'RELEASED',
      reason: safeReason,
    );

    return next;
  }

  Future<void> _saveAndAudit({
    required AgentWebsiteDeploymentActivationSettings settings,
    required String actorId,
    required String actionId,
    required String result,
    required String reason,
  }) async {
    settings.validate();

    await _document.set(settings.toMap(), SetOptions(merge: true));

    await _audit(
      actorId: actorId,
      actionId: actionId,
      result: result,
      reason: reason,
    );
  }

  Future<void> _audit({
    required String actorId,
    required String actionId,
    required String result,
    required String reason,
  }) async {
    await _auditService.append(
      eventType: AgentAuditEventType.systemEvent,
      severity: AgentAuditSeverity.info,
      actorType: AgentAuditActorType.admin,
      actorId: actorId,
      module: 'website',
      actionId: actionId,
      result: result,
      reason: reason,
      metadata: const <String, dynamic>{
        'boundary': 'website_deployment_activation_settings',
        'executionAuthority': false,
      },
    );
  }

  String _requireActor(String actorId) {
    final String safe = actorId.trim();

    if (safe.isEmpty) {
      throw const AgentWebsiteDeploymentActivationSettingsServiceException(
        'actorId is required.',
      );
    }

    return safe;
  }

  String _requireReason(String reason) {
    final String safe = reason.trim();

    if (safe.isEmpty) {
      throw const AgentWebsiteDeploymentActivationSettingsServiceException(
        'A non-empty reason is required for deployment activation changes.',
      );
    }

    return safe;
  }
}

class AgentWebsiteDeploymentActivationSettingsServiceException
    implements Exception {
  final String message;

  const AgentWebsiteDeploymentActivationSettingsServiceException(this.message);

  @override
  String toString() =>
      'AgentWebsiteDeploymentActivationSettingsServiceException: $message';
}
