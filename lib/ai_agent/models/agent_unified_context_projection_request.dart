import '../constants/agent_omnichannel_constants.dart';
import '../constants/agent_unified_context_constants.dart';

class AgentUnifiedContextProjectionRequest {
  AgentUnifiedContextProjectionRequest({
    required this.requestId,
    required this.requestingSubjectRef,
    required this.requestingRoleId,
    required this.requestingChannel,
    required this.requestedPurpose,
    required Set<String> requiredSemanticKeys,
    required this.requestedAt,
    this.maxFacts = 4,
    this.maxProjectedCharacters = 1200,
  }) : requiredSemanticKeys = Set<String>.unmodifiable(requiredSemanticKeys);

  final String requestId;
  final String requestingSubjectRef;
  final String requestingRoleId;
  final String requestingChannel;
  final String requestedPurpose;
  final Set<String> requiredSemanticKeys;
  final DateTime requestedAt;

  /// Phase 52 prompt projection is intentionally small.
  final int maxFacts;
  final int maxProjectedCharacters;

  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get invokesRuntimeGate => false;
  bool get writesBusinessData => false;
  bool get persistsRequest => false;
  bool get requestsFullConversationHistory => false;
  bool get requestsAllAvailableContext => false;

  void validateStructure() {
    if (requestId.trim().isEmpty ||
        requestingSubjectRef.trim().isEmpty ||
        requestingRoleId.trim().isEmpty) {
      throw const AgentUnifiedContextProjectionRequestException(
        'Projection identifiers are required.',
      );
    }

    if (!AgentOmnichannelChannel.values.contains(requestingChannel) ||
        !AgentUnifiedContextPurpose.values.contains(requestedPurpose)) {
      throw const AgentUnifiedContextProjectionRequestException(
        'Projection channel or purpose is invalid.',
      );
    }

    if (requiredSemanticKeys.isEmpty || requiredSemanticKeys.length > 6) {
      throw const AgentUnifiedContextProjectionRequestException(
        'Projection requires between 1 and 6 explicit semantic keys.',
      );
    }

    final RegExp safeKeyPattern = RegExp(r'^[A-Za-z0-9._:-]{1,100}$');

    if (requiredSemanticKeys.any(
      (String key) => !safeKeyPattern.hasMatch(key),
    )) {
      throw const AgentUnifiedContextProjectionRequestException(
        'Projection semantic key is invalid.',
      );
    }

    if (maxFacts < 1 ||
        maxFacts > 4 ||
        maxProjectedCharacters < 1 ||
        maxProjectedCharacters > 1200) {
      throw const AgentUnifiedContextProjectionRequestException(
        'Projection budget is outside the safe boundary.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'requestId': requestId,
      'requestingSubjectRef': requestingSubjectRef,
      'requestingRoleId': requestingRoleId,
      'requestingChannel': requestingChannel,
      'requestedPurpose': requestedPurpose,
      'requiredSemanticKeys': List<String>.unmodifiable(
        requiredSemanticKeys.toList()..sort(),
      ),
      'requestedAt': requestedAt.toUtc().toIso8601String(),
      'maxFacts': maxFacts,
      'maxProjectedCharacters': maxProjectedCharacters,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'invokesProvider': false,
      'invokesTargetAgent': false,
      'invokesRuntimeGate': false,
      'writesBusinessData': false,
      'persistsRequest': false,
      'requestsFullConversationHistory': false,
      'requestsAllAvailableContext': false,
    });
  }
}

class AgentUnifiedContextProjectionRequestException implements Exception {
  const AgentUnifiedContextProjectionRequestException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentUnifiedContextProjectionRequestException: $message';
}
