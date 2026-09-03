import '../constants/agent_owner_attention_sla_constants.dart';

class AgentOwnerAttentionSlaAssessment {
  AgentOwnerAttentionSlaAssessment({
    required this.attentionId,
    required this.sourceReferenceSha256,
    required this.eventCreatedAtUtc,
    required this.reviewVersion,
    required this.state,
    required this.age,
    required this.threshold,
    required this.notificationEligible,
    required this.notificationReason,
  }) {
    validate();
  }

  final String attentionId;

  /// Safe immutable source binding only. Raw source identifiers are excluded.
  final String sourceReferenceSha256;

  /// Binds the assessment to the exact immutable inbox event snapshot.
  final DateTime eventCreatedAtUtc;

  /// Prevents an assessment from being reused after Owner review changed.
  final int reviewVersion;

  final String state;
  final Duration age;
  final Duration threshold;

  final bool notificationEligible;
  final String? notificationReason;

  bool get stale =>
      state == AgentOwnerAttentionSlaState.stale ||
      state == AgentOwnerAttentionSlaState.immediateEscalation;

  bool get terminal => state == AgentOwnerAttentionSlaState.terminal;

  bool get exactSnapshotBinding => true;
  bool get rawSourceIdentifierStored => false;

  bool get assessmentOnly => true;
  bool get inboxMutated => false;
  bool get sourceRecordMutated => false;
  bool get notificationSent => false;
  bool get approvalConsumed => false;
  bool get permissionGranted => false;
  bool get businessActionExecuted => false;

  void validate() {
    final shaPattern = RegExp(r'^[A-Fa-f0-9]{64}$');

    if (attentionId.trim().isEmpty ||
        !shaPattern.hasMatch(sourceReferenceSha256) ||
        !eventCreatedAtUtc.isUtc ||
        reviewVersion < 0 ||
        !AgentOwnerAttentionSlaState.values.contains(state) ||
        age.isNegative ||
        threshold.isNegative ||
        (notificationEligible &&
            (notificationReason == null ||
                !AgentOwnerAttentionNotificationReason.values.contains(
                  notificationReason,
                ))) ||
        (!notificationEligible && notificationReason != null)) {
      throw const FormatException('Invalid Owner Attention SLA assessment.');
    }
  }
}
