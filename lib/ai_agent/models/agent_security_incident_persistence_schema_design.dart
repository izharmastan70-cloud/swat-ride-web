class AgentSecurityIncidentPersistenceSchemaDesign {
  const AgentSecurityIncidentPersistenceSchemaDesign({
    required this.status,
    required this.proposedCollectionId,
    required this.requiredCreateFields,
    required this.immutableAfterCreateFields,
    required this.controlledLifecycleFields,
    required this.forbiddenPersistedFields,
    required this.allowedTrustedMutationActorRoles,
    required this.requiredSensitiveMutationChecks,
    required this.protectedEvidenceRetentionRules,
    required this.createRequiresTrustedAuthority,
    required this.updateRequiresTrustedAuthority,
    required this.deleteAllowed,
    required this.genericAutoDeleteAllowed,
    required this.collectionPurgeAllowed,
    required this.batchDeleteAllowed,
    required this.crossSubjectReadAllowed,
    required this.rawPayloadPersistenceAllowed,
    required this.rulesImplemented,
    required this.repositoryImplemented,
    required this.productionActive,
  });

  final String status;
  final String proposedCollectionId;
  final Set<String> requiredCreateFields;
  final Set<String> immutableAfterCreateFields;
  final Set<String> controlledLifecycleFields;
  final Set<String> forbiddenPersistedFields;
  final Set<String> allowedTrustedMutationActorRoles;
  final Set<String> requiredSensitiveMutationChecks;
  final Set<String> protectedEvidenceRetentionRules;

  final bool createRequiresTrustedAuthority;
  final bool updateRequiresTrustedAuthority;
  final bool deleteAllowed;
  final bool genericAutoDeleteAllowed;
  final bool collectionPurgeAllowed;
  final bool batchDeleteAllowed;
  final bool crossSubjectReadAllowed;
  final bool rawPayloadPersistenceAllowed;
  final bool rulesImplemented;
  final bool repositoryImplemented;
  final bool productionActive;

  bool get createsCollection => false;
  bool get writesFirestore => false;
  bool get readsLiveFirestore => false;
  bool get changesFirestoreRules => false;
  bool get deploysFirestoreRules => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get changesEmergencyStop => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
