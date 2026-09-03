import '../constants/agent_action_ids.dart';
import '../models/agent_read_only_payload.dart';
import '../models/agent_tool_request.dart';
import 'agent_read_only_connector.dart';

// =========================================================
// AI AGENT — STUDENT READ-ONLY CONNECTOR STUB
// =========================================================
//
// Intentionally NOT registered in AgentReadOnlyConnectorRegistry.
// Future connector must enforce parent/guardian/admin authorization
// and expose only privacy-minimized data.

class AgentStudentConnectorStub implements AgentReadOnlyConnector {
  @override
  String get connectorId => 'connector.student.stub';

  @override
  String get module => 'student';

  @override
  Set<String> get supportedActionIds => const <String>{
        AgentActionId.readStudentRide,
        AgentActionId.readStudentAttendance,
        AgentActionId.readStudentSafety,
      };

  @override
  bool supports(String actionId) =>
      supportedActionIds.contains(actionId);

  @override
  Future<AgentReadOnlyPayload> executeReadOnly(
    AgentToolRequest request,
  ) {
    throw StateError(
      'Student Ride connector is not connected. Complete and safety-audit the real Student module first.',
    );
  }
}
