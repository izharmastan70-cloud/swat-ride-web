import '../constants/agent_omnichannel_constants.dart';
import '../constants/agent_unified_context_constants.dart';
import '../models/agent_unified_context_conflict_resolution_result.dart';
import '../models/agent_unified_context_item.dart';
import '../models/agent_unified_context_projection_request.dart';
import '../models/agent_unified_context_prompt_projection.dart';

class AgentUnifiedContextPromptProjectionService {
  const AgentUnifiedContextPromptProjectionService();

  static const int _maxSingleFactCharacters = 400;

  static const Map<String, String> _channelByRole = <String, String>{
    'support_agent': AgentOmnichannelChannel.appChat,
    'customer_whatsapp_agent': AgentOmnichannelChannel.customerWhatsApp,
    'owner_whatsapp_agent': AgentOmnichannelChannel.ownerWhatsApp,
    'emergency_whatsapp_agent': AgentOmnichannelChannel.emergencyWhatsApp,
    'email_agent': AgentOmnichannelChannel.email,
    'call_agent': AgentOmnichannelChannel.phoneCall,
    'voice_super_admin_agent': AgentOmnichannelChannel.ownerVoice,
  };

  static const Map<String, Set<String>> _purposesByRole = <String, Set<String>>{
    'support_agent': <String>{
      AgentUnifiedContextPurpose.generalSupport,
      AgentUnifiedContextPurpose.bookingAssistance,
      AgentUnifiedContextPurpose.statusRead,
    },
    'customer_whatsapp_agent': <String>{
      AgentUnifiedContextPurpose.generalSupport,
      AgentUnifiedContextPurpose.bookingAssistance,
      AgentUnifiedContextPurpose.statusRead,
    },
    'owner_whatsapp_agent': <String>{
      AgentUnifiedContextPurpose.ownerOperations,
      AgentUnifiedContextPurpose.statusRead,
    },
    'emergency_whatsapp_agent': <String>{
      AgentUnifiedContextPurpose.safetyTriage,
    },
    'email_agent': <String>{
      AgentUnifiedContextPurpose.generalSupport,
      AgentUnifiedContextPurpose.statusRead,
    },
    'call_agent': <String>{
      AgentUnifiedContextPurpose.generalSupport,
      AgentUnifiedContextPurpose.bookingAssistance,
      AgentUnifiedContextPurpose.statusRead,
    },
    'voice_super_admin_agent': <String>{
      AgentUnifiedContextPurpose.ownerOperations,
      AgentUnifiedContextPurpose.statusRead,
    },
  };

  static const Map<String, Set<String>> _allowedDataKindsByPurpose =
      <String, Set<String>>{
        AgentUnifiedContextPurpose.generalSupport: <String>{
          AgentUnifiedContextDataKind.preference,
          AgentUnifiedContextDataKind.conversationSummary,
        },
        AgentUnifiedContextPurpose.bookingAssistance: <String>{
          AgentUnifiedContextDataKind.preference,
          AgentUnifiedContextDataKind.bookingFact,
          AgentUnifiedContextDataKind.identityAttribute,
        },
        AgentUnifiedContextPurpose.statusRead: <String>{
          AgentUnifiedContextDataKind.statusFact,
        },
        AgentUnifiedContextPurpose.safetyTriage: <String>{
          AgentUnifiedContextDataKind.safetyNeed,
          AgentUnifiedContextDataKind.identityAttribute,
        },
        AgentUnifiedContextPurpose.ownerOperations: <String>{
          AgentUnifiedContextDataKind.ownerOperationalFact,
          AgentUnifiedContextDataKind.statusFact,
        },
      };

  AgentUnifiedContextPromptProjection project({
    required AgentUnifiedContextProjectionRequest request,
    required AgentUnifiedContextConflictResolutionResult resolution,
    required Map<String, String> conflictKeyByContextId,
  }) {
    try {
      request.validateStructure();
    } on AgentUnifiedContextProjectionRequestException {
      return _blocked(
        request: request,
        reasonCode: AgentUnifiedContextPromptProjectionReason.invalidRequest,
      );
    }

    if (!resolution.ready) {
      return _blocked(
        request: request,
        reasonCode:
            AgentUnifiedContextPromptProjectionReason.sourceResolutionNotReady,
      );
    }

    if (resolution.requestingSubjectRef != request.requestingSubjectRef) {
      return _blocked(
        request: request,
        reasonCode: AgentUnifiedContextPromptProjectionReason.subjectMismatch,
      );
    }

    if (resolution.requestedPurpose != request.requestedPurpose) {
      return _blocked(
        request: request,
        reasonCode: AgentUnifiedContextPromptProjectionReason.purposeMismatch,
      );
    }

    final String? expectedChannel = _channelByRole[request.requestingRoleId];

    if (expectedChannel == null ||
        expectedChannel != request.requestingChannel) {
      return _blocked(
        request: request,
        reasonCode:
            AgentUnifiedContextPromptProjectionReason.roleChannelMismatch,
      );
    }

    final Set<String>? allowedPurposes =
        _purposesByRole[request.requestingRoleId];

    if (allowedPurposes == null ||
        !allowedPurposes.contains(request.requestedPurpose)) {
      return _blocked(
        request: request,
        reasonCode:
            AgentUnifiedContextPromptProjectionReason.purposeNotAllowedForRole,
      );
    }

    final Map<String, AgentUnifiedContextItem> itemByConflictKey =
        <String, AgentUnifiedContextItem>{};

    for (final AgentUnifiedContextItem item in resolution.selectedItems) {
      final String? key = conflictKeyByContextId[item.contextId];

      if (key == null || key.trim().isEmpty) {
        return _blocked(
          request: request,
          reasonCode:
              AgentUnifiedContextPromptProjectionReason.missingConflictKey,
        );
      }

      if (itemByConflictKey.containsKey(key)) {
        return _blocked(
          request: request,
          reasonCode:
              AgentUnifiedContextPromptProjectionReason.duplicateConflictKey,
        );
      }

      itemByConflictKey[key] = item;
    }

    final List<String> orderedRequiredKeys =
        request.requiredSemanticKeys.toList()..sort();

    final List<AgentUnifiedContextProjectedFact> projected =
        <AgentUnifiedContextProjectedFact>[];

    final Map<String, String> omissions = <String, String>{};

    final Set<String> unresolvedRequired = <String>{};

    int totalProjectedCharacters = 0;

    for (final String key in orderedRequiredKeys) {
      if (resolution.unresolvedConflictKeys.contains(key)) {
        unresolvedRequired.add(key);
        omissions[key] =
            AgentUnifiedContextPromptProjectionReason.unresolvedConflict;
        continue;
      }

      final AgentUnifiedContextItem? item = itemByConflictKey[key];

      if (item == null) {
        omissions[key] =
            AgentUnifiedContextPromptProjectionReason.requiredKeyUnavailable;
        continue;
      }

      if (!_isDataKindNecessary(
        purpose: request.requestedPurpose,
        dataKind: item.dataKind,
      )) {
        omissions[key] =
            AgentUnifiedContextPromptProjectionReason.dataKindNotNecessary;
        continue;
      }

      if (!_isSensitivityNecessary(
        purpose: request.requestedPurpose,
        sensitivity: item.sensitivity,
      )) {
        omissions[key] =
            AgentUnifiedContextPromptProjectionReason.sensitivityNotNecessary;
        continue;
      }

      if (item.containsOwnerAdminPrivateData &&
          !_isOwnerPrivateProjectionAllowed(
            roleId: request.requestingRoleId,
            channel: request.requestingChannel,
          )) {
        omissions[key] =
            AgentUnifiedContextPromptProjectionReason.ownerPrivateLeakBlocked;
        continue;
      }

      final String normalizedValue = _normalizeSanitizedValue(
        item.sanitizedValue,
      );

      if (normalizedValue.isEmpty ||
          normalizedValue.length > _maxSingleFactCharacters) {
        omissions[key] =
            AgentUnifiedContextPromptProjectionReason.oversizedFactOmitted;
        continue;
      }

      if (projected.length >= request.maxFacts) {
        omissions[key] =
            AgentUnifiedContextPromptProjectionReason.factBudgetExceeded;
        continue;
      }

      final AgentUnifiedContextProjectedFact fact =
          AgentUnifiedContextProjectedFact(
            semanticKey: key,
            sanitizedValue: normalizedValue,
            sourceTrust: item.sourceTrust,
            sensitivity: item.sensitivity,
            dataKind: item.dataKind,
            disclosureLabel: _disclosureLabel(item.sourceTrust),
          );

      final int nextCharacterCount =
          totalProjectedCharacters + fact.renderDataLine().length;

      if (nextCharacterCount > request.maxProjectedCharacters) {
        omissions[key] =
            AgentUnifiedContextPromptProjectionReason.characterBudgetExceeded;
        continue;
      }

      projected.add(fact);
      totalProjectedCharacters = nextCharacterCount;
    }

    final bool hasOmissions = omissions.isNotEmpty;

    return AgentUnifiedContextPromptProjection(
      status: hasOmissions
          ? AgentUnifiedContextPromptProjectionStatus.readyWithOmissions
          : AgentUnifiedContextPromptProjectionStatus.ready,
      reasonCode: AgentUnifiedContextPromptProjectionReason.ready,
      requestId: request.requestId,
      requestingSubjectRef: request.requestingSubjectRef,
      requestedPurpose: request.requestedPurpose,
      projectedFacts: projected,
      omissionReasonBySemanticKey: omissions,
      unresolvedRequiredKeys: unresolvedRequired,
    );
  }

  bool _isDataKindNecessary({
    required String purpose,
    required String dataKind,
  }) {
    return _allowedDataKindsByPurpose[purpose]?.contains(dataKind) ?? false;
  }

  bool _isSensitivityNecessary({
    required String purpose,
    required String sensitivity,
  }) {
    if (sensitivity == AgentUnifiedContextSensitivity.restrictedData) {
      return false;
    }

    if (purpose == AgentUnifiedContextPurpose.safetyTriage ||
        purpose == AgentUnifiedContextPurpose.ownerOperations) {
      return sensitivity == AgentUnifiedContextSensitivity.publicData ||
          sensitivity == AgentUnifiedContextSensitivity.internalData ||
          sensitivity == AgentUnifiedContextSensitivity.personalData ||
          sensitivity == AgentUnifiedContextSensitivity.sensitiveData;
    }

    return sensitivity == AgentUnifiedContextSensitivity.publicData ||
        sensitivity == AgentUnifiedContextSensitivity.personalData;
  }

  bool _isOwnerPrivateProjectionAllowed({
    required String roleId,
    required String channel,
  }) {
    return (roleId == 'owner_whatsapp_agent' &&
            channel == AgentOmnichannelChannel.ownerWhatsApp) ||
        (roleId == 'voice_super_admin_agent' &&
            channel == AgentOmnichannelChannel.ownerVoice);
  }

  String _normalizeSanitizedValue(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _disclosureLabel(String sourceTrust) {
    switch (sourceTrust) {
      case AgentUnifiedContextSourceTrust.verifiedSystem:
        return AgentUnifiedContextDisclosureLabel.verifiedSystem;
      case AgentUnifiedContextSourceTrust.verifiedIdentityBound:
        return AgentUnifiedContextDisclosureLabel.verifiedIdentity;
      case AgentUnifiedContextSourceTrust.userAsserted:
        return AgentUnifiedContextDisclosureLabel.userAsserted;
      case AgentUnifiedContextSourceTrust.derivedSummary:
        return AgentUnifiedContextDisclosureLabel.derivedSummary;
      case AgentUnifiedContextSourceTrust.untrustedExternal:
        return AgentUnifiedContextDisclosureLabel.untrustedExternal;
      default:
        return AgentUnifiedContextDisclosureLabel.untrustedExternal;
    }
  }

  AgentUnifiedContextPromptProjection _blocked({
    required AgentUnifiedContextProjectionRequest request,
    required String reasonCode,
  }) {
    return AgentUnifiedContextPromptProjection(
      status: AgentUnifiedContextPromptProjectionStatus.blocked,
      reasonCode: reasonCode,
      requestId: request.requestId,
      requestingSubjectRef: request.requestingSubjectRef,
      requestedPurpose: request.requestedPurpose,
      projectedFacts: const <AgentUnifiedContextProjectedFact>[],
      omissionReasonBySemanticKey: const <String, String>{},
      unresolvedRequiredKeys: const <String>{},
    );
  }

  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get invokesRuntimeGate => false;
  bool get writesBusinessData => false;
  bool get persistsContext => false;
  bool get persistsProjection => false;
  bool get loadsFullConversationHistory => false;
  bool get loadsAllAvailableContext => false;
  bool get bypassesMinimumNecessaryDisclosure => false;
  bool get treatsContextAsInstructions => false;
}
