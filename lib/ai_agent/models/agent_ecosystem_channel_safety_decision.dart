import '../constants/agent_ecosystem_channel_safety_constants.dart';

class AgentEcosystemChannelSafetyDecision {
  AgentEcosystemChannelSafetyDecision({
    required this.status,
    required this.routeTo,
    required this.reasonCode,
    required this.trustedIdentityRequired,
    required this.verifiedEvidenceRequired,
    required this.controlChainRequired,
  }) {
    validate();
  }

  final String status;
  final String routeTo;
  final String reasonCode;

  final bool trustedIdentityRequired;
  final bool verifiedEvidenceRequired;
  final bool controlChainRequired;

  bool get mayExecuteBusinessAction => false;
  bool get mayConsumeApproval => false;
  bool get mayGrantPermission => false;
  bool get mayOverrideRuntimeGate => false;
  bool get mayCallProvider => false;
  bool get maySendMessage => false;
  bool get mayMutateSourceRecord => false;
  bool get grantsOwnerAuthority => false;
  bool get grantsAdminAuthority => false;

  void validate() {
    if (!AgentEcosystemSafetyDecisionStatus.values.contains(status) ||
        routeTo.trim().isEmpty ||
        reasonCode.trim().isEmpty) {
      throw const FormatException(
        'Invalid final ecosystem channel safety decision.',
      );
    }
  }
}
