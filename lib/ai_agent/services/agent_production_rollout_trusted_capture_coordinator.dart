import '../constants/agent_production_rollout_activation_constants.dart';
import '../models/agent_production_rollout_activation_models.dart';
import 'agent_production_rollout_control_state_binding_service.dart';
import 'agent_production_rollout_live_snapshot_reader.dart';

class AgentProductionRolloutCaptureDecision {
  const AgentProductionRolloutCaptureDecision({
    required this.status,
    required this.reasonCode,
    required this.capture,
  });

  final String status;
  final String reasonCode;
  final AgentProductionRolloutTrustedCapture? capture;

  bool get captured => capture != null;
  bool get writesFirestore => false;
  bool get activatesRollout => false;
}

class AgentProductionRolloutTrustedCaptureCoordinator {
  const AgentProductionRolloutTrustedCaptureCoordinator({
    required this.reader,
    this.controlStateBindingService =
        const AgentProductionRolloutControlStateBindingService(),
  });

  final AgentProductionRolloutLiveSnapshotReader reader;
  final AgentProductionRolloutControlStateBindingService
  controlStateBindingService;

  Future<AgentProductionRolloutCaptureDecision> capture({
    required AgentProductionRolloutTrustedOwnerContext trustedContext,
    required DateTime capturedAtUtc,
    required String phase65SafetyEvidenceSha256,
    required String phase62VersionEvidenceSha256,
  }) async {
    trustedContext.validate();

    final DateTime now = capturedAtUtc.toUtc();
    final Duration contextAge = now.difference(trustedContext.issuedAtUtc);

    if (!trustedContext.authorityVerified ||
        !AgentProductionRolloutTrustedActorRole.allowed.contains(
          trustedContext.actorRole,
        )) {
      return const AgentProductionRolloutCaptureDecision(
        status: AgentProductionRolloutCaptureStatus.blockedUntrustedActor,
        reasonCode: 'trusted_owner_or_super_admin_authority_required',
        capture: null,
      );
    }

    if (!trustedContext.freshReauthenticationVerified) {
      return const AgentProductionRolloutCaptureDecision(
        status: AgentProductionRolloutCaptureStatus.blockedReauthentication,
        reasonCode: 'fresh_reauthentication_required',
        capture: null,
      );
    }

    if (contextAge <
        -AgentProductionRolloutActivationLimits.trustedContextFutureSkew) {
      return const AgentProductionRolloutCaptureDecision(
        status: AgentProductionRolloutCaptureStatus.blockedFutureTrustedContext,
        reasonCode: 'trusted_context_future_skew_exceeded',
        capture: null,
      );
    }

    if (contextAge >
        AgentProductionRolloutActivationLimits.trustedContextMaxAge) {
      return const AgentProductionRolloutCaptureDecision(
        status: AgentProductionRolloutCaptureStatus.blockedStaleTrustedContext,
        reasonCode: 'trusted_context_is_stale',
        capture: null,
      );
    }

    try {
      final snapshot = await reader.read(
        capturedAtUtc: now,
        phase65SafetyEvidenceSha256: phase65SafetyEvidenceSha256,
        phase62VersionEvidenceSha256: phase62VersionEvidenceSha256,
      );

      final String controlStateFingerprint = controlStateBindingService.bind(
        snapshot,
      );

      final AgentProductionRolloutTrustedCapture capture =
          AgentProductionRolloutTrustedCapture(
            snapshot: snapshot,
            controlStateFingerprintSha256: controlStateFingerprint,
            actorReferenceSha256: trustedContext.actorReferenceSha256
                .toLowerCase(),
            capturedAtUtc: now,
          );

      return AgentProductionRolloutCaptureDecision(
        status: AgentProductionRolloutCaptureStatus.captured,
        reasonCode: 'trusted_live_snapshot_captured_and_control_state_bound',
        capture: capture,
      );
    } on Object {
      return const AgentProductionRolloutCaptureDecision(
        status: AgentProductionRolloutCaptureStatus.blockedLiveRead,
        reasonCode: 'live_snapshot_read_or_binding_failed_closed',
        capture: null,
      );
    }
  }

  bool get captureOnly => true;
  bool get storesRawOwnerIdentity => false;
  bool get storesRawSessionToken => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get writesFirestore => false;
  bool get activatesRollout => false;
}
