import '../constants/agent_omnichannel_constants.dart';
import '../constants/agent_unified_context_constants.dart';

class AgentUnifiedContextAssemblyRequest {
  AgentUnifiedContextAssemblyRequest({
    required this.requestId,
    required this.requestingSubjectRef,
    required this.requestingRoleId,
    required this.requestingChannel,
    required this.requestedPurpose,
    required this.requestedAt,
    this.maxItems = 6,
    this.maxSanitizedCharacters = 1800,
  });

  final String requestId;
  final String requestingSubjectRef;
  final String requestingRoleId;
  final String requestingChannel;
  final String requestedPurpose;
  final DateTime requestedAt;

  /// Hard prompt/context budget. Phase 52 assembly is intentionally bounded.
  final int maxItems;
  final int maxSanitizedCharacters;

  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsRequest => false;
  bool get requestsFullConversationHistory => false;

  void validateStructure() {
    if (requestId.trim().isEmpty ||
        requestingSubjectRef.trim().isEmpty ||
        requestingRoleId.trim().isEmpty) {
      throw const AgentUnifiedContextAssemblyRequestException(
        'Unified context assembly identifiers are required.',
      );
    }

    if (!AgentOmnichannelChannel.values.contains(requestingChannel) ||
        !AgentUnifiedContextPurpose.values.contains(requestedPurpose)) {
      throw const AgentUnifiedContextAssemblyRequestException(
        'Unified context assembly channel or purpose is invalid.',
      );
    }

    if (maxItems < 1 ||
        maxItems > 8 ||
        maxSanitizedCharacters < 1 ||
        maxSanitizedCharacters > 2400) {
      throw const AgentUnifiedContextAssemblyRequestException(
        'Unified context assembly budget is outside the safe boundary.',
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
      'requestedAt': requestedAt.toUtc().toIso8601String(),
      'maxItems': maxItems,
      'maxSanitizedCharacters': maxSanitizedCharacters,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'invokesProvider': false,
      'invokesTargetAgent': false,
      'writesBusinessData': false,
      'persistsRequest': false,
      'requestsFullConversationHistory': false,
    });
  }
}

class AgentUnifiedContextAssemblyRequestException implements Exception {
  const AgentUnifiedContextAssemblyRequestException(this.message);

  final String message;

  @override
  String toString() => 'AgentUnifiedContextAssemblyRequestException: $message';
}
