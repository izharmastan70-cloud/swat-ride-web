class AgentGuardianRiskDecisionStatus {
  AgentGuardianRiskDecisionStatus._();

  static const String classified = 'CLASSIFIED';
  static const String blockedInvalidEvent = 'BLOCKED_INVALID_EVENT';
}

class AgentGuardianRiskDecision {
  AgentGuardianRiskDecision({
    required this.status,
    required this.eventId,
    required this.category,
    required this.severity,
    required this.evidenceConfidence,
    required this.recommendedDisposition,
    required List<String> reasonCodes,
    required this.existingAuthoritativeGateBlocked,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String eventId;
  final String category;
  final String severity;
  final String evidenceConfidence;
  final String recommendedDisposition;
  final List<String> reasonCodes;
  final bool existingAuthoritativeGateBlocked;

  bool get classified => status == AgentGuardianRiskDecisionStatus.classified;

  bool get invalidEvent =>
      status == AgentGuardianRiskDecisionStatus.blockedInvalidEvent;

  /// Recommendation only. Existing central security controls remain final.
  bool get recommendationOnly => true;
  bool get guardianIsFinalEnforcer => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get executesBlock => false;
  bool get executesEscalation => false;
  bool get createsIncident => false;
  bool get mutatesSecurityControls => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get invokesRuntimeGate => false;
  bool get writesBusinessData => false;
  bool get persistsDecision => false;

  Map<String, dynamic> toSafeMap() {
    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'eventId': eventId,
      'category': category,
      'severity': severity,
      'evidenceConfidence': evidenceConfidence,
      'recommendedDisposition': recommendedDisposition,
      'reasonCodes': List<String>.unmodifiable(reasonCodes),
      'existingAuthoritativeGateBlocked': existingAuthoritativeGateBlocked,
      'recommendationOnly': true,
      'guardianIsFinalEnforcer': false,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'executesBlock': false,
      'executesEscalation': false,
      'createsIncident': false,
      'mutatesSecurityControls': false,
      'invokesProvider': false,
      'invokesTargetAgent': false,
      'invokesRuntimeGate': false,
      'writesBusinessData': false,
      'persistsDecision': false,
    });
  }
}
