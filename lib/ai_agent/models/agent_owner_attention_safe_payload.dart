import '../constants/agent_owner_attention_constants.dart';

class AgentOwnerAttentionSafePayload {
  AgentOwnerAttentionSafePayload({
    required this.safeTitle,
    required this.safeSummary,
    required this.reasonCodes,
    required this.redactionVerified,
    required this.minimumNecessaryVerified,
  }) {
    validate();
  }

  final String safeTitle;
  final String safeSummary;
  final List<String> reasonCodes;

  final bool redactionVerified;
  final bool minimumNecessaryVerified;

  bool get rawBodyIncluded => false;
  bool get rawTranscriptIncluded => false;
  bool get rawRecordingIncluded => false;
  bool get secretIncluded => false;
  bool get authTokenIncluded => false;
  bool get approvalTokenIncluded => false;
  bool get permissionTokenIncluded => false;
  bool get apiKeyIncluded => false;
  bool get paymentCredentialIncluded => false;
  bool get fullCardNumberIncluded => false;
  bool get cvvIncluded => false;

  void validate() {
    final blockedContent = RegExp(
      r'(password\s*[:=]|api.?key\s*[:=]|auth.?token\s*[:=]|approval.?token\s*[:=]|permission.?token\s*[:=]|cvv\s*[:=]|cvc\s*[:=]|card.?number\s*[:=])',
      caseSensitive: false,
    );

    final uniqueReasons = reasonCodes.toSet();

    if (safeTitle.trim().isEmpty ||
        safeTitle != safeTitle.trim() ||
        safeTitle.length > AgentOwnerAttentionLimits.safeTitleMaxLength ||
        safeSummary.trim().isEmpty ||
        safeSummary != safeSummary.trim() ||
        safeSummary.length > AgentOwnerAttentionLimits.safeSummaryMaxLength ||
        reasonCodes.isEmpty ||
        reasonCodes.length > AgentOwnerAttentionLimits.maxReasonCodes ||
        uniqueReasons.length != reasonCodes.length ||
        reasonCodes.any(
          (code) =>
              code.trim().isEmpty ||
              code != code.trim() ||
              code.length > AgentOwnerAttentionLimits.reasonCodeMaxLength,
        ) ||
        !redactionVerified ||
        !minimumNecessaryVerified ||
        blockedContent.hasMatch(safeTitle) ||
        blockedContent.hasMatch(safeSummary)) {
      throw const FormatException('Unsafe Owner Attention payload.');
    }
  }

  Map<String, Object?> toSafeMetadata() {
    validate();

    return <String, Object?>{
      'safeTitle': safeTitle,
      'safeSummary': safeSummary,
      'reasonCodes': List<String>.unmodifiable(reasonCodes),
      'redactionVerified': true,
      'minimumNecessaryVerified': true,
      'rawBodyIncluded': false,
      'rawTranscriptIncluded': false,
      'rawRecordingIncluded': false,
      'secretIncluded': false,
      'authTokenIncluded': false,
      'approvalTokenIncluded': false,
      'permissionTokenIncluded': false,
      'apiKeyIncluded': false,
      'paymentCredentialIncluded': false,
    };
  }
}
