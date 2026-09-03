import '../constants/agent_support_constants.dart';
import '../models/agent_support_assessment.dart';
import '../models/agent_support_request.dart';
import 'agent_support_policy.dart';

class AgentCustomerWhatsAppSupportDecision {
  const AgentCustomerWhatsAppSupportDecision({
    required this.intent,
    required this.priority,
    required this.escalation,
    required this.reason,
    required this.humanHandoffRequired,
    required this.mayAutoResolve,
  });

  final String intent;
  final String priority;
  final String escalation;
  final String reason;
  final bool humanHandoffRequired;
  final bool mayAutoResolve;

  bool get createsDuplicateComplaintSystem => false;
  bool get grantsOwnerWhatsAppAuthority => false;
  bool get grantsEmergencyWhatsAppAuthority => false;
}

class AgentCustomerWhatsAppSupportEscalationBridge {
  const AgentCustomerWhatsAppSupportEscalationBridge({
    this.policy = const AgentSupportPolicy(),
  });

  final AgentSupportPolicy policy;

  bool get reusesExistingSupportPolicy => true;
  bool get createsTicketDirectly => false;
  bool get sendsWhatsAppDirectly => false;

  AgentCustomerWhatsAppSupportDecision assess({
    required String message,
    required String module,
    required String referenceId,
    required String userIdAlias,
  }) {
    final AgentSupportRequest request = AgentSupportRequest(
      requestId:
          'customer_whatsapp_support_${DateTime.now().microsecondsSinceEpoch}',
      userMessage: message,
      module: module,
      referenceId: referenceId,
      userIdAlias: userIdAlias,
      context: const <String, dynamic>{
        'channel': 'customer_whatsapp',
        'authority': 'none',
      },
      createdAt: DateTime.now(),
    );

    request.validate();

    final AgentSupportAssessment assessment = policy.assess(request);

    final bool handoff =
        assessment.escalation != AgentSupportEscalation.none ||
        !assessment.safeForAutomaticReply;

    return AgentCustomerWhatsAppSupportDecision(
      intent: assessment.intent,
      priority: assessment.priority,
      escalation: assessment.escalation,
      reason: assessment.reason,
      humanHandoffRequired: handoff,
      mayAutoResolve:
          assessment.safeForAutomaticReply &&
          !assessment.requiresBusinessData &&
          assessment.escalation == AgentSupportEscalation.none,
    );
  }
}
