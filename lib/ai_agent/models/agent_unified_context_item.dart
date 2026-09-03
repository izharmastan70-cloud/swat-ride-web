import '../constants/agent_omnichannel_constants.dart';
import '../constants/agent_unified_context_constants.dart';

class AgentUnifiedContextItem {
  AgentUnifiedContextItem({
    required this.contextId,
    required this.subjectRef,
    required this.sourceChannel,
    required this.sourceType,
    required this.sourceTrust,
    required this.sensitivity,
    required this.purpose,
    required this.dataKind,
    required this.sanitizedValue,
    required this.capturedAt,
    required this.expiresAt,
    required this.identityBound,
    required this.containsRawSecret,
    required this.containsPaymentCredential,
    required this.containsAuthToken,
    required this.containsRawMessageHistory,
    required this.containsOwnerAdminPrivateData,
    required this.generatedByAgent,
  });

  final String contextId;

  /// Pseudonymous subject identifier. Raw phone/email/user secrets do not belong
  /// in this contract.
  final String subjectRef;

  final String sourceChannel;
  final String sourceType;

  /// Provenance confidence only. This never grants action authority.
  final String sourceTrust;

  final String sensitivity;
  final String purpose;
  final String dataKind;

  /// Sanitized bounded fact/summary only, never an unrestricted transcript.
  final String sanitizedValue;

  final DateTime capturedAt;
  final DateTime expiresAt;

  final bool identityBound;
  final bool containsRawSecret;
  final bool containsPaymentCredential;
  final bool containsAuthToken;
  final bool containsRawMessageHistory;
  final bool containsOwnerAdminPrivateData;
  final bool generatedByAgent;

  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get invokesProvider => false;
  bool get invokesRuntimeGate => false;
  bool get writesBusinessData => false;
  bool get persistsItself => false;
  bool get containsFullConversationTranscript => containsRawMessageHistory;

  void validateStructure() {
    if (contextId.trim().isEmpty ||
        subjectRef.trim().isEmpty ||
        sanitizedValue.trim().isEmpty) {
      throw const AgentUnifiedContextItemException(
        'Unified context identifiers and sanitized value are required.',
      );
    }

    if (!AgentOmnichannelChannel.values.contains(sourceChannel) ||
        !AgentUnifiedContextSourceType.values.contains(sourceType) ||
        !AgentUnifiedContextSourceTrust.values.contains(sourceTrust) ||
        !AgentUnifiedContextSensitivity.values.contains(sensitivity) ||
        !AgentUnifiedContextPurpose.values.contains(purpose) ||
        !AgentUnifiedContextDataKind.values.contains(dataKind)) {
      throw const AgentUnifiedContextItemException(
        'Unified context classification value is invalid.',
      );
    }

    if (!expiresAt.isAfter(capturedAt)) {
      throw const AgentUnifiedContextItemException(
        'Unified context expiry must be after capture time.',
      );
    }
  }

  Map<String, dynamic> toSafeMetadataMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'contextId': contextId,
      'subjectRef': subjectRef,
      'sourceChannel': sourceChannel,
      'sourceType': sourceType,
      'sourceTrust': sourceTrust,
      'sensitivity': sensitivity,
      'purpose': purpose,
      'dataKind': dataKind,
      'capturedAt': capturedAt.toUtc().toIso8601String(),
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'identityBound': identityBound,
      'containsRawSecret': containsRawSecret,
      'containsPaymentCredential': containsPaymentCredential,
      'containsAuthToken': containsAuthToken,
      'containsRawMessageHistory': containsRawMessageHistory,
      'containsOwnerAdminPrivateData': containsOwnerAdminPrivateData,
      'generatedByAgent': generatedByAgent,
      'sanitizedValueIncluded': false,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'invokesProvider': false,
      'invokesRuntimeGate': false,
      'writesBusinessData': false,
      'persistsItself': false,
    });
  }
}

class AgentUnifiedContextItemException implements Exception {
  const AgentUnifiedContextItemException(this.message);

  final String message;

  @override
  String toString() => 'AgentUnifiedContextItemException: $message';
}
