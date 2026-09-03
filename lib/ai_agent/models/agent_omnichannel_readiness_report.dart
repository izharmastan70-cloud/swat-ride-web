class AgentOmnichannelReadinessStatus {
  AgentOmnichannelReadinessStatus._();

  static const String foundationReadyNotProductionActive =
      'FOUNDATION_READY_NOT_PRODUCTION_ACTIVE';

  static const String blocked = 'BLOCKED';

  static const Set<String> values = <String>{
    foundationReadyNotProductionActive,
    blocked,
  };
}

class AgentOmnichannelReadinessReport {
  AgentOmnichannelReadinessReport({
    required this.status,
    required this.phase51FoundationComplete,
    required this.sevenChannelContractPresent,
    required this.identityPrivacyBoundaryPresent,
    required this.normalizationGatewayPresent,
    required this.failClosedRoutingPresent,
    required this.replayProtectionPresent,
    required this.channelControlsPresent,
    required this.failureIsolationPresent,
    required this.privacyMinimizedAuditPresent,
    required this.phase52SharedContextAbsent,
    required this.providerExecutionAbsent,
    required this.runtimeBusinessWriteAbsent,
    required this.productionPersistentSettingsBackendWired,
    required this.adminToggleUiWired,
    required this.liveProviderActivationWired,
    required this.auditPersistenceBackendWired,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;

  final bool phase51FoundationComplete;
  final bool sevenChannelContractPresent;
  final bool identityPrivacyBoundaryPresent;
  final bool normalizationGatewayPresent;
  final bool failClosedRoutingPresent;
  final bool replayProtectionPresent;
  final bool channelControlsPresent;
  final bool failureIsolationPresent;
  final bool privacyMinimizedAuditPresent;

  final bool phase52SharedContextAbsent;
  final bool providerExecutionAbsent;
  final bool runtimeBusinessWriteAbsent;

  /// These remain false in Phase 51. They are explicit production gaps,
  /// not hidden failures.
  final bool productionPersistentSettingsBackendWired;
  final bool adminToggleUiWired;
  final bool liveProviderActivationWired;
  final bool auditPersistenceBackendWired;

  final List<String> reasonCodes;

  bool get productionActive => false;
  bool get productionReady => false;
  bool get phase52Implemented => false;
  bool get grantsAuthority => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;

  void validate() {
    if (!AgentOmnichannelReadinessStatus.values.contains(status) ||
        reasonCodes.isEmpty) {
      throw const AgentOmnichannelReadinessException(
        'Omnichannel readiness report is structurally invalid.',
      );
    }

    if (status ==
            AgentOmnichannelReadinessStatus
                .foundationReadyNotProductionActive &&
        (!phase51FoundationComplete ||
            !sevenChannelContractPresent ||
            !identityPrivacyBoundaryPresent ||
            !normalizationGatewayPresent ||
            !failClosedRoutingPresent ||
            !replayProtectionPresent ||
            !channelControlsPresent ||
            !failureIsolationPresent ||
            !privacyMinimizedAuditPresent ||
            !phase52SharedContextAbsent ||
            !providerExecutionAbsent ||
            !runtimeBusinessWriteAbsent)) {
      throw const AgentOmnichannelReadinessException(
        'Foundation-ready status requires all Phase 51 safety gates.',
      );
    }

    if (productionPersistentSettingsBackendWired ||
        adminToggleUiWired ||
        liveProviderActivationWired ||
        auditPersistenceBackendWired) {
      throw const AgentOmnichannelReadinessException(
        'Phase 51 closeout must not falsely claim production activation.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'phase51FoundationComplete': phase51FoundationComplete,
      'sevenChannelContractPresent': sevenChannelContractPresent,
      'identityPrivacyBoundaryPresent': identityPrivacyBoundaryPresent,
      'normalizationGatewayPresent': normalizationGatewayPresent,
      'failClosedRoutingPresent': failClosedRoutingPresent,
      'replayProtectionPresent': replayProtectionPresent,
      'channelControlsPresent': channelControlsPresent,
      'failureIsolationPresent': failureIsolationPresent,
      'privacyMinimizedAuditPresent': privacyMinimizedAuditPresent,
      'phase52SharedContextAbsent': phase52SharedContextAbsent,
      'providerExecutionAbsent': providerExecutionAbsent,
      'runtimeBusinessWriteAbsent': runtimeBusinessWriteAbsent,
      'productionPersistentSettingsBackendWired':
          productionPersistentSettingsBackendWired,
      'adminToggleUiWired': adminToggleUiWired,
      'liveProviderActivationWired': liveProviderActivationWired,
      'auditPersistenceBackendWired': auditPersistenceBackendWired,
      'productionActive': false,
      'productionReady': false,
      'phase52Implemented': false,
      'grantsAuthority': false,
      'invokesProvider': false,
      'writesBusinessData': false,
      'reasonCodes': List<String>.unmodifiable(reasonCodes),
    });
  }
}

class AgentOmnichannelReadinessException implements Exception {
  const AgentOmnichannelReadinessException(this.message);

  final String message;

  @override
  String toString() => 'AgentOmnichannelReadinessException: $message';
}
