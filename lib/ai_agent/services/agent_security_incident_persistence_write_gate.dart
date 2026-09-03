import '../models/agent_security_incident_persistence_write_authorization.dart';

class AgentSecurityIncidentPersistenceWriteGate {
  const AgentSecurityIncidentPersistenceWriteGate();

  void requireAuthorized({
    required AgentSecurityIncidentPersistenceWriteAuthorization authorization,
    required String expectedOperation,
    required String expectedIncidentId,
    required DateTime nowUtc,
  }) {
    authorization.validate(
      expectedOperation: expectedOperation,
      expectedIncidentId: expectedIncidentId,
      nowUtc: nowUtc,
    );
  }

  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get createsApproval => false;
  bool get overridesRuntimeGate => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
