import '../constants/agent_guardian_security_constants.dart';
import '../constants/agent_omnichannel_constants.dart';

/// Transient, privacy-minimized Guardian observation.
///
/// This does NOT replace AgentSecurityFinding, does NOT create an incident,
/// and carries no raw prompt/message/credential payload.
class AgentGuardianSecurityEvent {
  AgentGuardianSecurityEvent({
    required this.eventId,
    required this.category,
    required this.evidenceTrust,
    required this.sourceComponent,
    required this.occurredAt,
    required this.observedAt,
    Set<String> evidenceCodes = const <String>{},
    this.pseudonymousSubjectRef,
    this.sourceChannel,
    this.agentRoleId,
    this.targetActionId,
    this.highImpactActionTargeted = false,
    this.repeatedWithinWindow = false,
    this.activeExploitEvidence = false,
    this.existingAuthoritativeGateBlocked = false,
    this.containsRawPrompt = false,
    this.containsRawMessageHistory = false,
    this.containsRawSecret = false,
    this.containsPaymentCredential = false,
    this.containsAuthToken = false,
    this.containsOwnerPrivatePayload = false,
    this.containsCustomerPrivatePayload = false,
  }) : evidenceCodes = Set<String>.unmodifiable(evidenceCodes);

  final String eventId;
  final String category;
  final String evidenceTrust;
  final String sourceComponent;
  final DateTime occurredAt;
  final DateTime observedAt;

  final Set<String> evidenceCodes;

  final String? pseudonymousSubjectRef;
  final String? sourceChannel;
  final String? agentRoleId;
  final String? targetActionId;

  final bool highImpactActionTargeted;
  final bool repeatedWithinWindow;
  final bool activeExploitEvidence;

  /// Evidence that an existing authoritative gate already denied/blocked.
  /// Guardian does not become the enforcing authority because of this flag.
  final bool existingAuthoritativeGateBlocked;

  /// Guardian events must never embed these payload classes.
  final bool containsRawPrompt;
  final bool containsRawMessageHistory;
  final bool containsRawSecret;
  final bool containsPaymentCredential;
  final bool containsAuthToken;
  final bool containsOwnerPrivatePayload;
  final bool containsCustomerPrivatePayload;

  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get executesBlock => false;
  bool get createsIncident => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get invokesRuntimeGate => false;
  bool get writesBusinessData => false;
  bool get persistsEvent => false;

  void validateStructure() {
    final RegExp safeIdPattern = RegExp(r'^[A-Za-z0-9._:-]{1,120}$');

    if (!safeIdPattern.hasMatch(eventId) ||
        !safeIdPattern.hasMatch(sourceComponent)) {
      throw const AgentGuardianSecurityEventException(
        'Guardian event id/source component is invalid.',
      );
    }

    if (!AgentGuardianRiskCategory.values.contains(category)) {
      throw const AgentGuardianSecurityEventException(
        'Guardian risk category is invalid.',
      );
    }

    if (!AgentGuardianEvidenceTrust.values.contains(evidenceTrust)) {
      throw const AgentGuardianSecurityEventException(
        'Guardian evidence trust is invalid.',
      );
    }

    if (sourceChannel != null &&
        !AgentOmnichannelChannel.values.contains(sourceChannel)) {
      throw const AgentGuardianSecurityEventException(
        'Guardian source channel is invalid.',
      );
    }

    for (final String? value in <String?>[
      pseudonymousSubjectRef,
      agentRoleId,
      targetActionId,
    ]) {
      if (value != null && !safeIdPattern.hasMatch(value)) {
        throw const AgentGuardianSecurityEventException(
          'Guardian scoped identifier is invalid.',
        );
      }
    }

    if (evidenceCodes.isEmpty || evidenceCodes.length > 8) {
      throw const AgentGuardianSecurityEventException(
        'Guardian event requires 1 to 8 evidence codes.',
      );
    }

    for (final String code in evidenceCodes) {
      if (!safeIdPattern.hasMatch(code)) {
        throw const AgentGuardianSecurityEventException(
          'Guardian evidence code is invalid.',
        );
      }
    }

    final DateTime normalizedOccurred = occurredAt.toUtc();
    final DateTime normalizedObserved = observedAt.toUtc();

    if (normalizedOccurred.isAfter(
      normalizedObserved.add(const Duration(minutes: 5)),
    )) {
      throw const AgentGuardianSecurityEventException(
        'Guardian event occurredAt is too far in the future.',
      );
    }

    if (containsRawPrompt ||
        containsRawMessageHistory ||
        containsRawSecret ||
        containsPaymentCredential ||
        containsAuthToken ||
        containsOwnerPrivatePayload ||
        containsCustomerPrivatePayload) {
      throw const AgentGuardianSecurityEventException(
        'Guardian event contains prohibited raw/private payload.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'eventId': eventId,
      'category': category,
      'evidenceTrust': evidenceTrust,
      'sourceComponent': sourceComponent,
      'occurredAt': occurredAt.toUtc().toIso8601String(),
      'observedAt': observedAt.toUtc().toIso8601String(),
      'evidenceCodes': List<String>.unmodifiable(
        evidenceCodes.toList()..sort(),
      ),
      'pseudonymousSubjectRef': pseudonymousSubjectRef,
      'sourceChannel': sourceChannel,
      'agentRoleId': agentRoleId,
      'targetActionId': targetActionId,
      'highImpactActionTargeted': highImpactActionTargeted,
      'repeatedWithinWindow': repeatedWithinWindow,
      'activeExploitEvidence': activeExploitEvidence,
      'existingAuthoritativeGateBlocked': existingAuthoritativeGateBlocked,
      'rawPromptIncluded': false,
      'rawMessageHistoryIncluded': false,
      'rawSecretIncluded': false,
      'paymentCredentialIncluded': false,
      'authTokenIncluded': false,
      'ownerPrivatePayloadIncluded': false,
      'customerPrivatePayloadIncluded': false,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'executesBlock': false,
      'createsIncident': false,
      'invokesProvider': false,
      'invokesTargetAgent': false,
      'invokesRuntimeGate': false,
      'writesBusinessData': false,
      'persistsEvent': false,
    });
  }
}

class AgentGuardianSecurityEventException implements Exception {
  const AgentGuardianSecurityEventException(this.message);

  final String message;

  @override
  String toString() => 'AgentGuardianSecurityEventException: $message';
}
