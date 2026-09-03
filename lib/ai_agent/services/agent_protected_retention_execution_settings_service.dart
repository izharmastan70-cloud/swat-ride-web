import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/agent_protected_retention_execution_settings.dart';
import 'agent_protected_retention_execution_control.dart';

/// Firestore persistence boundary for Owner/Super Admin
/// protected-retention execution settings.
///
/// Scope:
/// - one global settings document only;
/// - no protected business record reads/deletes;
/// - no batch delete;
/// - no collection purge;
/// - mandatory safety guards are validated before save.
class AgentProtectedRetentionExecutionSettingsService {
  static const String collectionName =
      'agent_protected_retention_execution_settings';

  static const String globalDocumentId = 'global';

  final FirebaseFirestore firestore;

  const AgentProtectedRetentionExecutionSettingsService({
    required this.firestore,
  });

  DocumentReference<Map<String, dynamic>> get _globalRef =>
      firestore.collection(collectionName).doc(globalDocumentId);

  Future<AgentProtectedRetentionExecutionSettings> getSettings({
    required String ownerId,
  }) async {
    final String safeOwnerId = ownerId.trim();

    if (safeOwnerId.isEmpty) {
      throw ArgumentError('Owner/Super Admin ID is required.');
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _globalRef
        .get();

    final Map<String, dynamic>? data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return AgentProtectedRetentionExecutionSettings.safeDefaults(
        ownerId: safeOwnerId,
      );
    }

    final AgentProtectedRetentionExecutionSettings settings =
        AgentProtectedRetentionExecutionSettings.fromMap(
          data,
          fallbackOwnerId: safeOwnerId,
        );

    final AgentProtectedRetentionExecutionControlDecision decision =
        AgentProtectedRetentionExecutionControl.evaluate(settings);

    // Stored settings may be OFF, which is valid.
    // The only persistence-blocking state here is an attempt to
    // weaken mandatory guards.
    if (decision.decisionCode == 'MANDATORY_SAFETY_GUARD_DISABLED') {
      return AgentProtectedRetentionExecutionSettings.safeDefaults(
        ownerId: safeOwnerId,
      );
    }

    return settings;
  }

  Future<void> saveSettings({
    required AgentProtectedRetentionExecutionSettings settings,
  }) async {
    final AgentProtectedRetentionExecutionControlDecision decision =
        AgentProtectedRetentionExecutionControl.evaluate(settings);

    if (settings.updatedBy.trim().isEmpty) {
      throw ArgumentError('Owner/Super Admin identity is required.');
    }

    if (decision.decisionCode == 'MANDATORY_SAFETY_GUARD_DISABLED') {
      throw StateError(
        'Protected execution mandatory safety guards cannot be disabled.',
      );
    }

    final Map<String, dynamic> payload = settings.toMap();

    payload['updatedAt'] = FieldValue.serverTimestamp();

    payload['schemaVersion'] = 1;

    await _globalRef.set(payload, SetOptions(merge: true));
  }
}
