abstract final class AgentSecurityIncidentPersistenceSchemaDesignConstants {
  static const String designStatus =
      'SCHEMA_DESIGN_READY_NOT_IMPLEMENTED_NOT_PRODUCTION_ACTIVE';

  static const String proposedCollectionId = 'agent_security_incidents';

  static const Set<String> requiredCreateFields = <String>{
    'incidentId',
    'source',
    'sourceReferenceId',
    'pseudonymousSubjectRef',
    'status',
    'severity',
    'evidenceConfidence',
    'createdAt',
    'updatedAt',
    'evidenceReferenceCodes',
  };

  static const Set<String> immutableAfterCreateFields = <String>{
    'incidentId',
    'source',
    'sourceReferenceId',
    'pseudonymousSubjectRef',
    'createdAt',
  };

  static const Set<String> controlledLifecycleFields = <String>{
    'status',
    'severity',
    'evidenceConfidence',
    'updatedAt',
    'assignedResponderRef',
    'acknowledgedAt',
    'triagedAt',
    'resolvedAt',
    'closedAt',
    'evidenceReferenceCodes',
  };

  static const Set<String> forbiddenPersistedFields = <String>{
    'rawPayload',
    'rawConversation',
    'rawEmailBody',
    'rawWhatsAppMessage',
    'rawCallTranscript',
    'rawVoiceRecording',
    'rawStackTrace',
    'password',
    'authToken',
    'sessionToken',
    'apiKey',
    'secretKey',
    'paymentCardNumber',
    'cvv',
    'bankCredential',
    'childName',
    'childPhone',
    'childExactAddress',
    'preciseMedicalPayload',
  };

  static const Set<String> allowedTrustedMutationActorRoles = <String>{
    'OWNER',
    'SUPER_ADMIN',
  };

  static const Set<String> requiredSensitiveMutationChecks = <String>{
    'freshTrustedIdentity',
    'permissionEngine',
    'approvalEngineWhenSensitive',
    'runtimeGate',
    'idempotencyKey',
    'exactIncidentBinding',
    'immutableAudit',
    'phase63ProtectedRetention',
  };

  static const Set<String> protectedEvidenceRetentionRules = <String>{
    'noGenericAutoDelete',
    'noCollectionPurge',
    'noBatchDelete',
    'retentionReviewSignalOnly',
    'explicitProtectedEvidenceAuthorityRequired',
  };
}
