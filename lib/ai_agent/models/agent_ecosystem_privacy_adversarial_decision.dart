import '../constants/agent_ecosystem_privacy_adversarial_constants.dart';

class AgentEcosystemPrivacyAdversarialDecision {
  AgentEcosystemPrivacyAdversarialDecision({
    required this.status,
    required this.routeTo,
    required this.reasonCode,
  }) {
    validate();
  }

  final String status;
  final String routeTo;
  final String reasonCode;

  bool get failClosed =>
      status != AgentEcosystemPrivacyDecisionStatus.safeProjectionEligible;

  bool get mayRevealSecret => false;
  bool get mayReturnRawCredential => false;
  bool get mayReturnRawToken => false;
  bool get mayReturnOtherCustomerData => false;
  bool get mayTrustSessionClaimAlone => false;
  bool get mayGrantOwnerOrAdminAuthority => false;
  bool get mayOverrideSystemInstruction => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayOverrideRuntimeGate => false;
  bool get mayReadFirestore => false;
  bool get mayWriteFirestore => false;
  bool get mayCallProvider => false;
  bool get maySendPrivateDataToProvider => false;
  bool get mayExecuteBusinessAction => false;
  bool get mayActivateProduction => false;

  void validate() {
    if (!AgentEcosystemPrivacyDecisionStatus.values.contains(status) ||
        routeTo.trim().isEmpty ||
        reasonCode.trim().isEmpty) {
      throw const FormatException(
        'Invalid ecosystem privacy adversarial decision.',
      );
    }
  }
}
