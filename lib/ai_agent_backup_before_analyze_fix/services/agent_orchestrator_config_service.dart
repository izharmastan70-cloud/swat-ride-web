import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_orchestrator_constants.dart';
import '../models/agent_orchestrator_config.dart';

// =========================================================
// AI AGENT — ORCHESTRATOR CONFIG SERVICE
// =========================================================
//
// Firestore:
// agent_settings/orchestrator
//
// No secrets/API keys stored here.

class AgentOrchestratorConfigService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _document =>
      _firestore
          .collection('agent_settings')
          .doc(AgentOrchestratorConfig.documentId);

  Future<AgentOrchestratorConfig> getConfig() async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _document.get();

    if (!snapshot.exists) {
      return AgentOrchestratorConfig.safeDefaults();
    }

    return AgentOrchestratorConfig.fromMap(
      snapshot.data() ?? <String, dynamic>{},
    );
  }

  Stream<AgentOrchestratorConfig> watchConfig() {
    return _document.snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> snapshot) {
        if (!snapshot.exists) {
          return AgentOrchestratorConfig.safeDefaults();
        }

        return AgentOrchestratorConfig.fromMap(
          snapshot.data() ?? <String, dynamic>{},
        );
      },
    );
  }

  Future<void> bootstrapSafeDefaults() async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _document.get();

    if (snapshot.exists) return;

    await _document.set(
      AgentOrchestratorConfig.safeDefaults().toMap(),
    );
  }

  Future<void> setEnabled(bool enabled) async {
    await _document.set(
      <String, dynamic>{
        'orchestratorType': AgentOrchestratorType.openClaw,
        'enabled': enabled,
        'readOnlyOnly': true,
        'status': enabled
            ? AgentOrchestratorStatus.configured
            : AgentOrchestratorStatus.disconnected,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
