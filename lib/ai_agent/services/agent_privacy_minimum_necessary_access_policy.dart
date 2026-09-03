import '../constants/agent_privacy_access_scope_constants.dart';
import '../constants/agent_privacy_retention_classification_constants.dart';
import '../models/agent_privacy_access_scope.dart';
import '../models/agent_privacy_data_access_decision.dart';
import '../models/agent_privacy_data_access_request.dart';
import 'agent_privacy_data_classification_policy.dart';

class AgentPrivacyMinimumNecessaryAccessPolicy {
  const AgentPrivacyMinimumNecessaryAccessPolicy({
    this.classificationPolicy = const AgentPrivacyDataClassificationPolicy(),
  });

  final AgentPrivacyDataClassificationPolicy classificationPolicy;

  AgentPrivacyDataAccessDecision evaluate({
    required AgentPrivacyAccessScope scope,
    required AgentPrivacyDataAccessRequest request,
    required DateTime evaluatedAtUtc,
  }) {
    try {
      scope.validate();
      request.validate();

      if (!evaluatedAtUtc.isUtc) {
        throw const FormatException('Evaluation time must be UTC.');
      }
    } catch (_) {
      return _blocked(
        request: request,
        status: AgentPrivacyDataAccessStatus.blockedInvalidInput,
        reason: 'invalid_privacy_access_input',
      );
    }

    if (scope.agentId != request.agentId) {
      return _blocked(
        request: request,
        status: AgentPrivacyDataAccessStatus.blockedAgentMismatch,
        reason: 'scope_agent_mismatch',
      );
    }

    if (request.requestedAtUtc.isAfter(
      evaluatedAtUtc.add(AgentPrivacyAccessScopeLimits.maximumFutureClockSkew),
    )) {
      return _blocked(
        request: request,
        status: AgentPrivacyDataAccessStatus.blockedInvalidInput,
        reason: 'request_clock_skew',
      );
    }

    if (!evaluatedAtUtc.isBefore(scope.validUntilUtc)) {
      return _blocked(
        request: request,
        status: AgentPrivacyDataAccessStatus.blockedExpired,
        reason: 'privacy_access_scope_expired',
      );
    }

    if (!scope.allowedDomains.contains(request.domain)) {
      return _blocked(
        request: request,
        status: AgentPrivacyDataAccessStatus.blockedDomain,
        reason: 'domain_not_in_privacy_scope',
      );
    }

    for (final String kind in request.requestedDataKinds) {
      if (!scope.allowedDataKinds.contains(kind)) {
        return _blocked(
          request: request,
          status: AgentPrivacyDataAccessStatus.blockedScope,
          reason: 'requested_data_kind_not_in_scope',
        );
      }

      final String requiredDomain = _requiredDomainFor(kind);

      if (requiredDomain != AgentPrivacyAccessDomain.general &&
          request.domain != requiredDomain) {
        return _blocked(
          request: request,
          status: AgentPrivacyDataAccessStatus.blockedDomain,
          reason: 'strict_data_kind_domain_mismatch',
        );
      }

      final classification = classificationPolicy.classify(kind);

      if (classification.restrictedCritical) {
        return _blocked(
          request: request,
          status: AgentPrivacyDataAccessStatus.blockedRestrictedCritical,
          reason: 'restricted_critical_raw_data_blocked',
        );
      }

      if (AgentPrivacySensitivityTier.rank(classification.sensitivityTier) >
          AgentPrivacySensitivityTier.rank(scope.maximumSensitivityTier)) {
        return _blocked(
          request: request,
          status: AgentPrivacyDataAccessStatus.blockedSensitivity,
          reason: 'requested_sensitivity_exceeds_scope_ceiling',
        );
      }

      if (classification.protectedEvidence &&
          !scope.protectedEvidenceProjectionAllowed) {
        return _blocked(
          request: request,
          status: AgentPrivacyDataAccessStatus.blockedScope,
          reason: 'protected_evidence_projection_not_allowed',
        );
      }
    }

    final bool requiresVerifiedProjection = request.requestedDataKinds.any((
      String kind,
    ) {
      final classification = classificationPolicy.classify(kind);

      return classification.strictlySensitive ||
          classification.protectedEvidence ||
          classification.accessMode ==
              AgentPrivacyAccessMode.verifiedProjectionOnly;
    });

    return AgentPrivacyDataAccessDecision(
      status: requiresVerifiedProjection
          ? AgentPrivacyDataAccessStatus.grantedVerifiedProjectionOnly
          : AgentPrivacyDataAccessStatus.grantedMinimumNecessary,
      requestId: request.requestId,
      agentId: request.agentId,
      domain: request.domain,
      projectionMode: requiresVerifiedProjection
          ? AgentPrivacyProjectionMode.verifiedProjectionOnly
          : AgentPrivacyProjectionMode.minimumNecessaryMetadata,
      allowedDataKinds: List<String>.unmodifiable(request.requestedDataKinds),
      reasonCode: requiresVerifiedProjection
          ? 'minimum_necessary_verified_projection_only'
          : 'minimum_necessary_metadata_only',
    );
  }

  String _requiredDomainFor(String dataKind) {
    switch (dataKind) {
      case AgentPrivacyDataKind.studentData:
        return AgentPrivacyAccessDomain.student;

      case AgentPrivacyDataKind.safetyEmergencyData:
        return AgentPrivacyAccessDomain.safety;

      case AgentPrivacyDataKind.financialData:
      case AgentPrivacyDataKind.financeEvidence:
        return AgentPrivacyAccessDomain.financial;

      default:
        return AgentPrivacyAccessDomain.general;
    }
  }

  AgentPrivacyDataAccessDecision _blocked({
    required AgentPrivacyDataAccessRequest request,
    required String status,
    required String reason,
  }) {
    return AgentPrivacyDataAccessDecision(
      status: status,
      requestId: request.requestId,
      agentId: request.agentId,
      domain: request.domain,
      projectionMode: AgentPrivacyProjectionMode.blocked,
      allowedDataKinds: const <String>[],
      reasonCode: reason,
    );
  }

  bool get privacyEligibilityOnly => true;
  bool get fetchesUserData => false;
  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get callsProvider => false;
  bool get grantsRuntimePermission => false;
  bool get consumesApproval => false;
  bool get overridesPermissionEngine => false;
  bool get overridesRuntimeGate => false;
  bool get writesBusinessData => false;
  bool get trainsModel => false;
  bool get deploysChange => false;
  bool get deletesData => false;
  bool get changesRetention => false;
}
