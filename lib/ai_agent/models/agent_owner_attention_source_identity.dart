import '../constants/agent_owner_attention_constants.dart';

class AgentOwnerAttentionSourceIdentity {
  AgentOwnerAttentionSourceIdentity({
    required this.sourceType,
    required this.sourceEventId,
    required this.sourceReferenceSha256,
  }) {
    validate();
  }

  final String sourceType;
  final String sourceEventId;

  /// Hash only. Raw customer/payment/incident identifiers are not required.
  final String sourceReferenceSha256;

  String get dedupeKey => '$sourceType:$sourceEventId:$sourceReferenceSha256';

  bool get rawSourcePayloadStored => false;
  bool get rawCustomerIdStored => false;
  bool get rawPaymentIdStored => false;

  void validate() {
    final safeIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');
    final shaPattern = RegExp(r'^[A-Fa-f0-9]{64}$');

    final validId =
        sourceEventId.isNotEmpty &&
        sourceEventId == sourceEventId.trim() &&
        sourceEventId.length <= AgentOwnerAttentionLimits.opaqueIdMaxLength &&
        safeIdPattern.hasMatch(sourceEventId);

    if (!AgentOwnerAttentionSourceType.values.contains(sourceType) ||
        !validId ||
        !shaPattern.hasMatch(sourceReferenceSha256)) {
      throw const FormatException('Invalid Owner Attention source identity.');
    }
  }
}
