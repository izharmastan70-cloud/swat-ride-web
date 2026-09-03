import '../constants/agent_content_generation_contract_constants.dart';

class AgentContentGenerationRequest {
  AgentContentGenerationRequest({
    required this.requestId,
    required this.draftType,
    required this.platform,
    required this.module,
    required this.feature,
    required this.audience,
    required this.language,
    required this.purpose,
    required this.brief,
    required List<String> sourceReferenceIds,
    required this.requestedMaxOutputChars,
    required this.reviewChannel,
    required this.createdAt,
  }) : sourceReferenceIds = List<String>.unmodifiable(sourceReferenceIds);

  final String requestId;
  final String draftType;
  final String platform;
  final String module;
  final String feature;
  final String audience;
  final String language;
  final String purpose;
  final String brief;
  final List<String> sourceReferenceIds;
  final int requestedMaxOutputChars;
  final String reviewChannel;
  final DateTime createdAt;

  bool get draftOnly => true;
  bool get rawPromptIsAuthority => false;
  bool get sourceReferencesAreAuthority => false;
  bool get publishesContent => false;
  bool get schedulesContent => false;
  bool get sendsEmail => false;
  bool get sendsWhatsApp => false;
  bool get postsSocialMedia => false;
  bool get executesBusinessAction => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get writesBusinessData => false;
  bool get invokesProvider => false;
  bool get persistsRequest => false;

  void validateStructure() {
    if (!_safeRequired(requestId, AgentContentContractLimits.requestIdMax)) {
      throw const AgentContentGenerationRequestException(
        'Content request ID is invalid.',
      );
    }
    if (!AgentContentDraftType.values.contains(draftType)) {
      throw const AgentContentGenerationRequestException(
        'Content draft type is unsupported.',
      );
    }
    if (!AgentContentPlatform.values.contains(platform)) {
      throw const AgentContentGenerationRequestException(
        'Content platform is unsupported.',
      );
    }
    if (!_safeRequired(module, AgentContentContractLimits.moduleMax)) {
      throw const AgentContentGenerationRequestException(
        'Content module is invalid.',
      );
    }
    if (!_safeOptional(feature, AgentContentContractLimits.featureMax)) {
      throw const AgentContentGenerationRequestException(
        'Content feature is invalid.',
      );
    }
    if (!AgentContentAudience.values.contains(audience)) {
      throw const AgentContentGenerationRequestException(
        'Content audience is unsupported.',
      );
    }
    if (!AgentContentLanguage.values.contains(language)) {
      throw const AgentContentGenerationRequestException(
        'Content language is unsupported.',
      );
    }
    if (!_safeRequired(purpose, AgentContentContractLimits.purposeMax)) {
      throw const AgentContentGenerationRequestException(
        'Content purpose is invalid.',
      );
    }
    if (!_safeRequired(brief, AgentContentContractLimits.briefMax)) {
      throw const AgentContentGenerationRequestException(
        'Content brief is invalid.',
      );
    }
    if (sourceReferenceIds.length >
        AgentContentContractLimits.sourceReferenceMax) {
      throw const AgentContentGenerationRequestException(
        'Too many source references.',
      );
    }
    for (final String sourceId in sourceReferenceIds) {
      if (!_safeReference(sourceId)) {
        throw const AgentContentGenerationRequestException(
          'Content source reference is invalid.',
        );
      }
    }
    if (requestedMaxOutputChars <= 0 ||
        requestedMaxOutputChars >
            AgentContentContractLimits.requestedMaxOutputChars) {
      throw const AgentContentGenerationRequestException(
        'Requested content output size is invalid.',
      );
    }
    if (!AgentContentReviewChannel.values.contains(reviewChannel)) {
      throw const AgentContentGenerationRequestException(
        'Content review channel is unsupported.',
      );
    }
  }

  bool _safeRequired(String value, int maxLength) {
    final String trimmed = value.trim();
    return trimmed.isNotEmpty &&
        trimmed.length <= maxLength &&
        !RegExp(r'[\u0000-\u001F]').hasMatch(trimmed);
  }

  bool _safeOptional(String value, int maxLength) {
    final String trimmed = value.trim();
    return trimmed.length <= maxLength &&
        !RegExp(r'[\u0000-\u001F]').hasMatch(trimmed);
  }

  bool _safeReference(String value) {
    final String trimmed = value.trim();
    return trimmed.isNotEmpty &&
        trimmed.length <= AgentContentContractLimits.sourceReferenceLengthMax &&
        RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
  }
}

class AgentContentGenerationRequestException implements Exception {
  const AgentContentGenerationRequestException(this.message);
  final String message;

  @override
  String toString() => 'AgentContentGenerationRequestException: $message';
}
