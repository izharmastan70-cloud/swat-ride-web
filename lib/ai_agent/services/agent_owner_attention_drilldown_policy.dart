import '../constants/agent_owner_attention_constants.dart';
import '../models/agent_owner_attention_drilldown_descriptor.dart';
import '../models/agent_owner_attention_inbox_record.dart';

class AgentOwnerAttentionDrilldownPolicy {
  const AgentOwnerAttentionDrilldownPolicy();

  AgentOwnerAttentionDrilldownDescriptor descriptorFor(
    AgentOwnerAttentionInboxRecord record,
  ) {
    record.validate();

    switch (record.event.source.sourceType) {
      case AgentOwnerAttentionSourceType.feedback:
        return _descriptor(
          label: 'Feedback / Complaint',
          routeKey: 'feedback_admin_review',
        );

      case AgentOwnerAttentionSourceType.payment:
        return _descriptor(
          label: 'Payment / Financial Review',
          routeKey: 'payment_admin_review',
        );

      case AgentOwnerAttentionSourceType.call:
        return _descriptor(label: 'Call Review', routeKey: 'call_admin_review');

      case AgentOwnerAttentionSourceType.security:
        return _descriptor(
          label: 'Security Review',
          routeKey: 'security_admin_review',
        );

      case AgentOwnerAttentionSourceType.crossAgentSupervisor:
        return _descriptor(
          label: 'Cross-Agent Supervisor',
          routeKey: 'cross_agent_supervisor_review',
        );

      case AgentOwnerAttentionSourceType.approval:
        return _descriptor(
          label: 'Approval Inbox',
          routeKey: 'approval_review',
        );

      case AgentOwnerAttentionSourceType.crash:
        return _descriptor(label: 'Crash Monitor', routeKey: 'crash_review');

      case AgentOwnerAttentionSourceType.fraud:
        return _descriptor(
          label: 'Fraud / Risk Review',
          routeKey: 'fraud_review',
        );

      case AgentOwnerAttentionSourceType.emergency:
        return _descriptor(
          label: 'Emergency / Safety Review',
          routeKey: 'emergency_review',
        );

      case AgentOwnerAttentionSourceType.emailAttention:
        return _descriptor(
          label: 'Email Admin Review',
          routeKey: 'email_admin_review',
        );

      default:
        throw const FormatException(
          'Unknown Owner Attention drill-down source.',
        );
    }
  }

  AgentOwnerAttentionDrilldownDescriptor _descriptor({
    required String label,
    required String routeKey,
  }) {
    return AgentOwnerAttentionDrilldownDescriptor(
      sourceLabel: label,
      routeKey: routeKey,
      reviewInstruction:
          'Open the source-specific admin workflow for consequential action. '
          'This Owner Attention Inbox does not execute the source action.',
    );
  }

  bool get descriptorOnly => true;
  bool get navigatesAutomatically => false;
  bool get sourceActionExecutionAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get businessWriteAllowed => false;
}
