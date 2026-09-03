import '../constants/agent_version_lifecycle_constants.dart';
import '../constants/agent_versioning_constants.dart';
import '../models/agent_version_evaluation_binding.dart';
import '../models/agent_version_lifecycle_transition.dart';
import '../models/agent_version_record.dart';

class AgentVersionLifecycleTransitionPolicy {
  const AgentVersionLifecycleTransitionPolicy();

  AgentVersionLifecycleTransitionDecision evaluate({
    required AgentVersionRecord version,
    required AgentVersionLifecycleTransitionRequest request,
    AgentVersionEvaluationBinding? evidence,
  }) {
    try {
      version.validate();
      request.validate();
      evidence?.validate();
    } catch (_) {
      return _decision(
        request: request,
        status: AgentVersionTransitionDecisionStatus.blockedInvalidInput,
        reason: AgentVersionTransitionReason.invalidInput,
      );
    }

    if (request.versionId != version.versionId ||
        request.fromStatus != version.status) {
      return _decision(
        request: request,
        status: AgentVersionTransitionDecisionStatus.blockedIllegalTransition,
        reason: AgentVersionTransitionReason.illegalTransition,
      );
    }

    if (request.fromStatus == AgentVersionLifecycleStatus.proposed &&
        request.toStatus == AgentVersionLifecycleStatus.offlineEvaluated) {
      return _evaluateOfflinePromotion(
        version: version,
        request: request,
        evidence: evidence,
      );
    }

    if (request.fromStatus == AgentVersionLifecycleStatus.offlineEvaluated &&
        request.toStatus == AgentVersionLifecycleStatus.testReady) {
      return _evaluateTestReadyPromotion(
        version: version,
        request: request,
        evidence: evidence,
      );
    }

    if (request.toStatus == AgentVersionLifecycleStatus.limitedRolloutReady ||
        request.toStatus == AgentVersionLifecycleStatus.monitored ||
        request.toStatus == AgentVersionLifecycleStatus.fullRolloutEligible ||
        request.toStatus == AgentVersionLifecycleStatus.rollbackEligible ||
        request.toStatus == AgentVersionLifecycleStatus.retired) {
      return _decision(
        request: request,
        status: AgentVersionTransitionDecisionStatus.blockedLaterPhase,
        reason: AgentVersionTransitionReason.laterPhaseRequired,
      );
    }

    return _decision(
      request: request,
      status: AgentVersionTransitionDecisionStatus.blockedIllegalTransition,
      reason: AgentVersionTransitionReason.illegalTransition,
    );
  }

  AgentVersionLifecycleTransitionDecision _evaluateOfflinePromotion({
    required AgentVersionRecord version,
    required AgentVersionLifecycleTransitionRequest request,
    required AgentVersionEvaluationBinding? evidence,
  }) {
    if (evidence == null) {
      return _decision(
        request: request,
        status: AgentVersionTransitionDecisionStatus.blockedEvidenceMissing,
        reason: AgentVersionTransitionReason.evidenceMissing,
      );
    }

    if (!_evidenceMatches(version, evidence)) {
      return _decision(
        request: request,
        status: AgentVersionTransitionDecisionStatus.blockedEvidenceMismatch,
        reason: AgentVersionTransitionReason.evidenceMismatch,
      );
    }

    final String? failureReason = _evaluationFailureReason(evidence);

    if (failureReason != null) {
      return _decision(
        request: request,
        status: AgentVersionTransitionDecisionStatus.blockedEvaluationFailure,
        reason: failureReason,
      );
    }

    return _decision(
      request: request,
      status: AgentVersionTransitionDecisionStatus.allowed,
      reason: AgentVersionTransitionReason.offlineEvaluationPassed,
    );
  }

  AgentVersionLifecycleTransitionDecision _evaluateTestReadyPromotion({
    required AgentVersionRecord version,
    required AgentVersionLifecycleTransitionRequest request,
    required AgentVersionEvaluationBinding? evidence,
  }) {
    if (evidence == null) {
      return _decision(
        request: request,
        status: AgentVersionTransitionDecisionStatus.blockedEvidenceMissing,
        reason: AgentVersionTransitionReason.evidenceMissing,
      );
    }

    if (!_evidenceMatches(version, evidence)) {
      return _decision(
        request: request,
        status: AgentVersionTransitionDecisionStatus.blockedEvidenceMismatch,
        reason: AgentVersionTransitionReason.evidenceMismatch,
      );
    }

    final String? failureReason = _evaluationFailureReason(evidence);

    if (failureReason != null) {
      return _decision(
        request: request,
        status: AgentVersionTransitionDecisionStatus.blockedEvaluationFailure,
        reason: failureReason,
      );
    }

    if (!request.humanApprovalGranted) {
      return _decision(
        request: request,
        status: AgentVersionTransitionDecisionStatus.blockedHumanApproval,
        reason: AgentVersionTransitionReason.humanApprovalMissing,
      );
    }

    if (version.changeRisk == AgentVersionChangeRisk.high &&
        !request.securityReviewPassed) {
      return _decision(
        request: request,
        status: AgentVersionTransitionDecisionStatus.blockedSecurityReview,
        reason: AgentVersionTransitionReason.securityReviewMissing,
      );
    }

    return _decision(
      request: request,
      status: AgentVersionTransitionDecisionStatus.allowed,
      reason: AgentVersionTransitionReason.testReadinessApproved,
    );
  }

  bool _evidenceMatches(
    AgentVersionRecord version,
    AgentVersionEvaluationBinding evidence,
  ) {
    return evidence.versionId == version.versionId &&
        evidence.agentId == version.agentId &&
        evidence.artifactFingerprintSha256 == version.artifactFingerprintSha256;
  }

  String? _evaluationFailureReason(AgentVersionEvaluationBinding evidence) {
    if (evidence.criticalFailureCount > 0) {
      return AgentVersionTransitionReason.criticalFailure;
    }

    if (evidence.safetyViolationCount > 0) {
      return AgentVersionTransitionReason.safetyViolation;
    }

    if (evidence.blockedCount > 0) {
      return AgentVersionTransitionReason.blockedCases;
    }

    if (evidence.failClosed) {
      return AgentVersionTransitionReason.runFailClosed;
    }

    if (!evidence.thresholdPassed || !evidence.minimumScoresPassed) {
      return AgentVersionTransitionReason.thresholdFailed;
    }

    if (!evidence.eligibleForHumanReview) {
      return AgentVersionTransitionReason.humanReviewNotEligible;
    }

    return null;
  }

  AgentVersionLifecycleTransitionDecision _decision({
    required AgentVersionLifecycleTransitionRequest request,
    required String status,
    required String reason,
  }) {
    return AgentVersionLifecycleTransitionDecision(
      status: status,
      versionId: request.versionId,
      fromStatus: request.fromStatus,
      toStatus: request.toStatus,
      reasonCode: reason,
    );
  }

  bool get mutatesVersionRecord => false;
  bool get persistsTransition => false;
  bool get callsProvider => false;
  bool get trainsModel => false;
  bool get mutatesPrompt => false;
  bool get deploysVersion => false;
  bool get activatesProduction => false;
  bool get performsRollback => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get mutatesSecurity => false;
  bool get writesBusinessData => false;
}
