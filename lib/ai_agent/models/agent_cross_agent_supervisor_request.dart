import '../constants/agent_cross_agent_supervisor_contract_constants.dart';
import 'agent_cross_agent_supervisor_security_snapshot.dart';

class AgentCrossAgentSupervisorRequest {
  const AgentCrossAgentSupervisorRequest({
    required this.requestId,
    required this.taskId,
    required this.sourceAgentId,
    required this.targetAgentId,
    required this.actionId,
    required this.securitySnapshot,
  });

  final String requestId;
  final String taskId;
  final String sourceAgentId;
  final String targetAgentId;
  final String actionId;

  final AgentCrossAgentSupervisorSecuritySnapshot securitySnapshot;

  bool get containsRawUserMessage => false;
  bool get containsRawConversation => false;
  bool get containsRawProviderResponse => false;
  bool get containsPrivatePayload => false;

  bool get asksSupervisorToAuthorizeExecution => false;
  bool get asksSupervisorToGrantPermission => false;
  bool get asksSupervisorToCreateApproval => false;

  void validateStructure() {
    final List<String> values = <String>[
      requestId,
      taskId,
      sourceAgentId,
      targetAgentId,
      actionId,
    ];

    final bool invalid = values.any((String value) {
      final String trimmed = value.trim();

      return trimmed.isEmpty ||
          trimmed.length >
              AgentCrossAgentSupervisorContractLimits.opaqueIdMaxLength ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
    });

    if (invalid) {
      throw const FormatException('Invalid Cross-Agent Supervisor request.');
    }

    securitySnapshot.validateStructure();
  }
}
