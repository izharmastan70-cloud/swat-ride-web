import '../constants/agent_unified_context_constants.dart';

class AgentUnifiedContextClassificationDecision {
  AgentUnifiedContextClassificationDecision({
    required this.status,
    required this.reasonCode,
    required this.contextId,
    required this.requestedPurpose,
    required this.requestingSubjectRef,
    required this.requestingRoleId,
    required this.requestingChannel,
  });

  final String status;
  final String reasonCode;
  final String contextId;
  final String requestedPurpose;
  final String requestingSubjectRef;
  final String requestingRoleId;
  final String requestingChannel;

  bool get allowed => status == AgentUnifiedContextDecisionStatus.allowed;

  bool get blocked => status == AgentUnifiedContextDecisionStatus.blocked;

  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsDecision => false;

  Map<String, dynamic> toSafeMap() {
    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'reasonCode': reasonCode,
      'contextId': contextId,
      'requestedPurpose': requestedPurpose,
      'requestingSubjectRef': requestingSubjectRef,
      'requestingRoleId': requestingRoleId,
      'requestingChannel': requestingChannel,
      'allowed': allowed,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'invokesProvider': false,
      'invokesTargetAgent': false,
      'writesBusinessData': false,
      'persistsDecision': false,
    });
  }
}
