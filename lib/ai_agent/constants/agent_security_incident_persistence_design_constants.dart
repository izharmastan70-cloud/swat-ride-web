abstract final class AgentSecurityIncidentPersistenceDesignConstants {
  // Proposed collection identifier for design review only.
  // This constant does NOT create a Firestore collection and does NOT authorize
  // any runtime read/write path.
  static const String proposedCollectionId = 'agent_security_incidents';

  static const String designStatus =
      'DESIGN_READY_NOT_IMPLEMENTED_NOT_PRODUCTION_ACTIVE';

  static const String privacyClass = 'PROTECTED_SECURITY_EVIDENCE';

  static const Set<String> immutableCreateFields = <String>{
    'incidentId',
    'source',
    'sourceReferenceId',
    'pseudonymousSubjectRef',
    'createdAt',
  };

  static const Set<String> lifecycleFields = <String>{
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

  static const Set<String> forbiddenRawPayloadKinds = <String>{
    'rawConversation',
    'rawEmailBody',
    'rawWhatsAppMessage',
    'rawCallTranscript',
    'rawVoiceRecording',
    'rawStackTrace',
    'authToken',
    'sessionToken',
    'password',
    'secretKey',
    'paymentCardNumber',
    'cvv',
    'bankCredential',
    'childDirectIdentifier',
    'preciseMedicalPayload',
  };

  static const Set<String> requiredAuthorityControls = <String>{
    'trustedOwnerOrSuperAdminBoundary',
    'permissionEngine',
    'approvalEngineForSensitiveMutation',
    'runtimeGate',
    'immutableAudit',
    'phase63ProtectedRetention',
    'crossSubjectIsolation',
    'idempotentMutation',
  };
}
