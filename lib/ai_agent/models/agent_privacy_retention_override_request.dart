import '../constants/agent_privacy_deletion_retention_constants.dart';
import '../constants/agent_privacy_retention_classification_constants.dart';

class AgentPrivacyRetentionOverrideRequest {
  AgentPrivacyRetentionOverrideRequest({
    required this.overrideId,
    required this.channel,
    required this.requestedDays,
    required this.requestedByRole,
    required this.protectedEvidence,
    required this.requestedAtUtc,
  }) {
    validate();
  }

  final String overrideId;
  final String channel;
  final int requestedDays;
  final String requestedByRole;
  final bool protectedEvidence;
  final DateTime requestedAtUtc;

  bool get metadataOnly => true;
  bool get productionApplied => false;
  bool get retentionWritePerformed => false;
  bool get deletionPerformed => false;

  void validate() {
    final RegExp safeIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');

    final bool validId =
        overrideId.isNotEmpty &&
        overrideId == overrideId.trim() &&
        overrideId.length <= AgentPrivacyDeletionLimits.opaqueIdMaxLength &&
        safeIdPattern.hasMatch(overrideId);

    if (!validId ||
        !AgentPrivacyChannel.values.contains(channel) ||
        requestedDays < 0 ||
        !requestedAtUtc.isUtc) {
      throw const FormatException(
        'Invalid Agent privacy retention override request.',
      );
    }
  }
}
