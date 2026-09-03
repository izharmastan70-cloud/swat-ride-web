import '../constants/agent_privacy_deletion_retention_constants.dart';
import '../models/agent_privacy_deletion_decision.dart';
import '../models/agent_privacy_deletion_request.dart';
import 'agent_privacy_data_classification_policy.dart';

class AgentPrivacyDeletionPolicy {
  const AgentPrivacyDeletionPolicy({
    this.classificationPolicy = const AgentPrivacyDataClassificationPolicy(),
  });

  final AgentPrivacyDataClassificationPolicy classificationPolicy;

  AgentPrivacyDeletionDecision evaluate({
    required AgentPrivacyDeletionRequest request,
    required DateTime evaluatedAtUtc,
  }) {
    try {
      request.validate();

      if (!evaluatedAtUtc.isUtc) {
        throw const FormatException('Deletion evaluation time must be UTC.');
      }
    } catch (_) {
      return _decision(
        request: request,
        status: AgentPrivacyDeletionStatus.blockedInvalidInput,
        reason: 'invalid_deletion_request',
      );
    }

    if (request.requestedAtUtc.isAfter(
      evaluatedAtUtc.add(AgentPrivacyDeletionLimits.maximumFutureClockSkew),
    )) {
      return _decision(
        request: request,
        status: AgentPrivacyDeletionStatus.blockedInvalidInput,
        reason: 'deletion_request_clock_skew',
      );
    }

    final classification = classificationPolicy.classify(request.dataKind);

    final bool classSaysProtected = AgentPrivacyDeletionRecordClass.isProtected(
      request.recordClass,
    );

    if (request.protectedEvidence != classSaysProtected) {
      return _decision(
        request: request,
        status: AgentPrivacyDeletionStatus.blockedMismatch,
        reason: 'protected_evidence_flag_mismatch',
      );
    }

    if (request.protectedEvidence ||
        classification.protectedEvidence ||
        classSaysProtected) {
      return _decision(
        request: request,
        status: AgentPrivacyDeletionStatus.blockedProtectedEvidence,
        reason: 'protected_evidence_requires_dedicated_flow',
      );
    }

    if (request.legalOrSecurityHold) {
      return _decision(
        request: request,
        status: AgentPrivacyDeletionStatus.blockedLegalOrSecurityHold,
        reason: 'legal_or_security_hold_active',
      );
    }

    if (classification.restrictedCritical) {
      return _decision(
        request: request,
        status: AgentPrivacyDeletionStatus.blockedRestrictedCritical,
        reason: 'restricted_critical_requires_dedicated_flow',
      );
    }

    if (!request.retentionExpiredByCanonicalEngine) {
      return _decision(
        request: request,
        status: AgentPrivacyDeletionStatus.blockedRetentionNotExpired,
        reason: 'canonical_retention_not_expired',
      );
    }

    if (request.recordClass !=
            AgentPrivacyDeletionRecordClass.transientContent &&
        request.recordClass !=
            AgentPrivacyDeletionRecordClass.operationalMetadata) {
      return _decision(
        request: request,
        status: AgentPrivacyDeletionStatus.blockedMismatch,
        reason: 'generic_deletion_record_class_not_supported',
      );
    }

    return _decision(
      request: request,
      status: AgentPrivacyDeletionStatus.eligibleTransientReview,
      reason: 'eligible_for_later_explicit_deletion_review_only',
    );
  }

  AgentPrivacyDeletionDecision _decision({
    required AgentPrivacyDeletionRequest request,
    required String status,
    required String reason,
  }) {
    return AgentPrivacyDeletionDecision(
      status: status,
      requestId: request.requestId,
      reasonCode: reason,
    );
  }

  bool get reliesOnCanonicalRetentionExpiry => true;
  bool get decisionOnly => true;
  bool get deletesData => false;
  bool get purgesData => false;
  bool get writesFirestore => false;
  bool get callsProvider => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get overridesRuntimeGate => false;
  bool get writesBusinessData => false;
  bool get changesRetention => false;
}
