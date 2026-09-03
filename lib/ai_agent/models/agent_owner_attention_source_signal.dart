import '../constants/agent_owner_attention_constants.dart';
import '../constants/agent_owner_attention_source_signal_constants.dart';

class AgentOwnerAttentionSourceSignal {
  AgentOwnerAttentionSourceSignal({
    required this.sourceType,
    required this.sourceKind,
    required this.sourceEventId,
    required this.sourceReferenceSha256,
    required this.safeTitle,
    required this.safeSummary,
    required this.reasonCodes,
    required this.redactionVerified,
    required this.minimumNecessaryVerified,
    required this.occurredAtUtc,
  }) {
    validate();
  }

  final String sourceType;
  final String sourceKind;
  final String sourceEventId;
  final String sourceReferenceSha256;

  final String safeTitle;
  final String safeSummary;
  final List<String> reasonCodes;

  final bool redactionVerified;
  final bool minimumNecessaryVerified;

  final DateTime occurredAtUtc;

  bool get metadataOnly => true;
  bool get rawBodyIncluded => false;
  bool get rawTranscriptIncluded => false;
  bool get rawRecordingIncluded => false;
  bool get secretIncluded => false;
  bool get tokenIncluded => false;
  bool get paymentCredentialIncluded => false;
  bool get businessActionIncluded => false;

  void validate() {
    final safeIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');
    final shaPattern = RegExp(r'^[A-Fa-f0-9]{64}$');

    final validEventId =
        sourceEventId.isNotEmpty &&
        sourceEventId == sourceEventId.trim() &&
        sourceEventId.length <= AgentOwnerAttentionLimits.opaqueIdMaxLength &&
        safeIdPattern.hasMatch(sourceEventId);

    if (!AgentOwnerAttentionSourceType.values.contains(sourceType) ||
        !AgentOwnerAttentionSourceKind.values.contains(sourceKind) ||
        !validEventId ||
        !shaPattern.hasMatch(sourceReferenceSha256) ||
        safeTitle.trim().isEmpty ||
        safeSummary.trim().isEmpty ||
        reasonCodes.isEmpty ||
        !redactionVerified ||
        !minimumNecessaryVerified ||
        !occurredAtUtc.isUtc) {
      throw const FormatException('Invalid Owner Attention source signal.');
    }
  }
}
