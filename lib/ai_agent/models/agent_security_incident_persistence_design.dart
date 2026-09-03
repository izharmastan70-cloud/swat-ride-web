class AgentSecurityIncidentPersistenceDesign {
  const AgentSecurityIncidentPersistenceDesign({
    required this.status,
    required this.proposedCollectionId,
    required this.privacyClass,
    required this.immutableCreateFields,
    required this.lifecycleFields,
    required this.forbiddenRawPayloadKinds,
    required this.requiredAuthorityControls,
    required this.phase54FoundationPreserved,
    required this.phase63RetentionAuthoritative,
    required this.phase65SafetyAuthoritative,
    required this.phase66ImplementationAuthorityRequired,
    required this.protectedEvidence,
    required this.genericAutoDeleteAllowed,
    required this.directClientWriteAllowed,
    required this.directAgentWriteAllowed,
    required this.crossSubjectReadAllowed,
    required this.rawPayloadPersistenceAllowed,
    required this.liveRepositoryImplemented,
    required this.firestoreRulesImplemented,
    required this.productionPersistenceActive,
    required this.suggestOnlyAuthorized,
    required this.autoAuthorized,
  });

  final String status;
  final String proposedCollectionId;
  final String privacyClass;
  final Set<String> immutableCreateFields;
  final Set<String> lifecycleFields;
  final Set<String> forbiddenRawPayloadKinds;
  final Set<String> requiredAuthorityControls;

  final bool phase54FoundationPreserved;
  final bool phase63RetentionAuthoritative;
  final bool phase65SafetyAuthoritative;
  final bool phase66ImplementationAuthorityRequired;
  final bool protectedEvidence;
  final bool genericAutoDeleteAllowed;
  final bool directClientWriteAllowed;
  final bool directAgentWriteAllowed;
  final bool crossSubjectReadAllowed;
  final bool rawPayloadPersistenceAllowed;
  final bool liveRepositoryImplemented;
  final bool firestoreRulesImplemented;
  final bool productionPersistenceActive;
  final bool suggestOnlyAuthorized;
  final bool autoAuthorized;

  bool get createsFirestoreCollection => false;
  bool get writesFirestore => false;
  bool get readsLiveFirestore => false;
  bool get changesFirestoreRules => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get changesEmergencyStop => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
}
