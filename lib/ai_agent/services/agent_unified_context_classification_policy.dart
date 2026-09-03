import '../constants/agent_omnichannel_constants.dart';
import '../constants/agent_unified_context_constants.dart';
import '../models/agent_unified_context_classification_decision.dart';
import '../models/agent_unified_context_item.dart';

class AgentUnifiedContextClassificationPolicy {
  const AgentUnifiedContextClassificationPolicy();

  static const Set<String> _ownerPrivateAllowedRoles = <String>{
    'owner_whatsapp_agent',
    'voice_super_admin_agent',
  };

  AgentUnifiedContextClassificationDecision evaluate({
    required AgentUnifiedContextItem item,
    required String requestingSubjectRef,
    required String requestingRoleId,
    required String requestingChannel,
    required String requestedPurpose,
    required DateTime now,
  }) {
    try {
      item.validateStructure();
    } on AgentUnifiedContextItemException {
      return _blocked(
        item: item,
        requestingSubjectRef: requestingSubjectRef,
        requestingRoleId: requestingRoleId,
        requestingChannel: requestingChannel,
        requestedPurpose: requestedPurpose,
        reasonCode: AgentUnifiedContextReason.invalidStructure,
      );
    }

    if (!AgentOmnichannelChannel.values.contains(requestingChannel) ||
        !AgentUnifiedContextPurpose.values.contains(requestedPurpose)) {
      return _blocked(
        item: item,
        requestingSubjectRef: requestingSubjectRef,
        requestingRoleId: requestingRoleId,
        requestingChannel: requestingChannel,
        requestedPurpose: requestedPurpose,
        reasonCode: AgentUnifiedContextReason.invalidStructure,
      );
    }

    if (item.containsRawSecret) {
      return _blocked(
        item: item,
        requestingSubjectRef: requestingSubjectRef,
        requestingRoleId: requestingRoleId,
        requestingChannel: requestingChannel,
        requestedPurpose: requestedPurpose,
        reasonCode: AgentUnifiedContextReason.rawSecretBlocked,
      );
    }

    if (item.containsPaymentCredential) {
      return _blocked(
        item: item,
        requestingSubjectRef: requestingSubjectRef,
        requestingRoleId: requestingRoleId,
        requestingChannel: requestingChannel,
        requestedPurpose: requestedPurpose,
        reasonCode: AgentUnifiedContextReason.paymentCredentialBlocked,
      );
    }

    if (item.containsAuthToken) {
      return _blocked(
        item: item,
        requestingSubjectRef: requestingSubjectRef,
        requestingRoleId: requestingRoleId,
        requestingChannel: requestingChannel,
        requestedPurpose: requestedPurpose,
        reasonCode: AgentUnifiedContextReason.authTokenBlocked,
      );
    }

    if (item.containsRawMessageHistory) {
      return _blocked(
        item: item,
        requestingSubjectRef: requestingSubjectRef,
        requestingRoleId: requestingRoleId,
        requestingChannel: requestingChannel,
        requestedPurpose: requestedPurpose,
        reasonCode: AgentUnifiedContextReason.rawHistoryBlocked,
      );
    }

    if (!now.isBefore(item.expiresAt)) {
      return _blocked(
        item: item,
        requestingSubjectRef: requestingSubjectRef,
        requestingRoleId: requestingRoleId,
        requestingChannel: requestingChannel,
        requestedPurpose: requestedPurpose,
        reasonCode: AgentUnifiedContextReason.expiredBlocked,
      );
    }

    if (item.subjectRef != requestingSubjectRef) {
      return _blocked(
        item: item,
        requestingSubjectRef: requestingSubjectRef,
        requestingRoleId: requestingRoleId,
        requestingChannel: requestingChannel,
        requestedPurpose: requestedPurpose,
        reasonCode: AgentUnifiedContextReason.subjectMismatchBlocked,
      );
    }

    if (item.purpose != requestedPurpose) {
      return _blocked(
        item: item,
        requestingSubjectRef: requestingSubjectRef,
        requestingRoleId: requestingRoleId,
        requestingChannel: requestingChannel,
        requestedPurpose: requestedPurpose,
        reasonCode: AgentUnifiedContextReason.purposeMismatchBlocked,
      );
    }

    if (item.sensitivity == AgentUnifiedContextSensitivity.restrictedData) {
      return _blocked(
        item: item,
        requestingSubjectRef: requestingSubjectRef,
        requestingRoleId: requestingRoleId,
        requestingChannel: requestingChannel,
        requestedPurpose: requestedPurpose,
        reasonCode: AgentUnifiedContextReason.restrictedSensitivityBlocked,
      );
    }

    if (item.containsOwnerAdminPrivateData &&
        (!_ownerPrivateAllowedRoles.contains(requestingRoleId) ||
            _isCustomerFacingChannel(requestingChannel))) {
      return _blocked(
        item: item,
        requestingSubjectRef: requestingSubjectRef,
        requestingRoleId: requestingRoleId,
        requestingChannel: requestingChannel,
        requestedPurpose: requestedPurpose,
        reasonCode: AgentUnifiedContextReason.ownerPrivateLeakBlocked,
      );
    }

    if (!_sourceTrustMatchesType(item)) {
      return _blocked(
        item: item,
        requestingSubjectRef: requestingSubjectRef,
        requestingRoleId: requestingRoleId,
        requestingChannel: requestingChannel,
        requestedPurpose: requestedPurpose,
        reasonCode: AgentUnifiedContextReason.sourceTrustMismatchBlocked,
      );
    }

    return AgentUnifiedContextClassificationDecision(
      status: AgentUnifiedContextDecisionStatus.allowed,
      reasonCode: AgentUnifiedContextReason.allowed,
      contextId: item.contextId,
      requestedPurpose: requestedPurpose,
      requestingSubjectRef: requestingSubjectRef,
      requestingRoleId: requestingRoleId,
      requestingChannel: requestingChannel,
    );
  }

  bool _sourceTrustMatchesType(AgentUnifiedContextItem item) {
    switch (item.sourceType) {
      case AgentUnifiedContextSourceType.domainServiceRead:
        return item.sourceTrust ==
            AgentUnifiedContextSourceTrust.verifiedSystem;

      case AgentUnifiedContextSourceType.verifiedChannelIdentity:
        return item.identityBound &&
            item.sourceTrust ==
                AgentUnifiedContextSourceTrust.verifiedIdentityBound;

      case AgentUnifiedContextSourceType.userStatement:
        return item.sourceTrust == AgentUnifiedContextSourceTrust.userAsserted;

      case AgentUnifiedContextSourceType.agentDerivedSummary:
        return item.generatedByAgent &&
            item.sourceTrust == AgentUnifiedContextSourceTrust.derivedSummary;

      case AgentUnifiedContextSourceType.emergencyTriageSignal:
        return item.sourceTrust ==
                AgentUnifiedContextSourceTrust.userAsserted ||
            item.sourceTrust ==
                AgentUnifiedContextSourceTrust.verifiedIdentityBound;

      case AgentUnifiedContextSourceType.externalProviderMetadata:
        return item.sourceTrust ==
            AgentUnifiedContextSourceTrust.untrustedExternal;

      default:
        return false;
    }
  }

  bool _isCustomerFacingChannel(String channel) {
    return channel == AgentOmnichannelChannel.appChat ||
        channel == AgentOmnichannelChannel.customerWhatsApp ||
        channel == AgentOmnichannelChannel.email ||
        channel == AgentOmnichannelChannel.phoneCall;
  }

  AgentUnifiedContextClassificationDecision _blocked({
    required AgentUnifiedContextItem item,
    required String requestingSubjectRef,
    required String requestingRoleId,
    required String requestingChannel,
    required String requestedPurpose,
    required String reasonCode,
  }) {
    return AgentUnifiedContextClassificationDecision(
      status: AgentUnifiedContextDecisionStatus.blocked,
      reasonCode: reasonCode,
      contextId: item.contextId,
      requestedPurpose: requestedPurpose,
      requestingSubjectRef: requestingSubjectRef,
      requestingRoleId: requestingRoleId,
      requestingChannel: requestingChannel,
    );
  }

  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsContext => false;
  bool get loadsFullConversationHistory => false;
  bool get implementsRetentionControlCenter => false;
}
