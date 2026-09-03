import 'agent_production_rollout_activation_models.dart';

class AgentProductionRolloutStep1GPreparedReview {
  const AgentProductionRolloutStep1GPreparedReview({
    required this.trustedContext,
    required this.capture,
    required this.preparedAtUtc,
    required this.accessSourceLabel,
  });

  final AgentProductionRolloutTrustedOwnerContext trustedContext;
  final AgentProductionRolloutTrustedCapture capture;
  final DateTime preparedAtUtc;
  final String accessSourceLabel;

  String get actorReferenceSha256 => trustedContext.actorReferenceSha256;

  String get snapshotFingerprintSha256 =>
      capture.snapshot.snapshotFingerprintSha256;

  String get controlStateFingerprintSha256 =>
      capture.controlStateFingerprintSha256;

  int get roleCount => capture.snapshot.roleCount;

  bool get writesFirestore => false;
  bool get grantsPermission => false;
  bool get activatesProduction => false;
  bool get containsRawOwnerUid => false;
  bool get containsRawIdToken => false;
}

class AgentProductionRolloutStep1GActivationOutcome {
  const AgentProductionRolloutStep1GActivationOutcome({
    required this.activated,
    required this.postActivationVerified,
    required this.status,
    required this.reasonCode,
    required this.activationId,
    required this.armingTokenIdSha256,
    required this.guardRevision,
  });

  final bool activated;
  final bool postActivationVerified;
  final String status;
  final String reasonCode;
  final String activationId;
  final String armingTokenIdSha256;
  final int guardRevision;

  bool get monitorOnlyProductionActive => activated && postActivationVerified;

  bool get autoTrafficEnabled => false;
  bool get businessWriteTrafficEnabled => false;
  bool get paidAiEnabled => false;
  bool get externalChannelsEnabled => false;
  bool get automaticRollbackPerformed => false;
}
