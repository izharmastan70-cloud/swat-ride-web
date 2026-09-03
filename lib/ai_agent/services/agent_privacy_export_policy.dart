import '../constants/agent_privacy_access_scope_constants.dart';
import '../constants/agent_privacy_control_export_constants.dart';
import '../constants/agent_privacy_retention_classification_constants.dart';
import '../models/agent_privacy_export_decision.dart';
import '../models/agent_privacy_export_request.dart';
import 'agent_privacy_data_classification_policy.dart';

class AgentPrivacyExportPolicy {
  const AgentPrivacyExportPolicy({
    this.classificationPolicy = const AgentPrivacyDataClassificationPolicy(),
  });

  final AgentPrivacyDataClassificationPolicy classificationPolicy;

  AgentPrivacyExportDecision evaluate({
    required AgentPrivacyExportRequest request,
    required bool dataExportMasterEnabled,
    required bool strictDomainExportEnabled,
    required DateTime evaluatedAtUtc,
  }) {
    try {
      request.validate();

      if (!evaluatedAtUtc.isUtc) {
        throw const FormatException('Export evaluation time must be UTC.');
      }
    } catch (_) {
      return _blocked(
        request: request,
        status: AgentPrivacyExportStatus.blockedInvalidInput,
        reason: 'invalid_export_request',
      );
    }

    if (request.requestedAtUtc.isAfter(
      evaluatedAtUtc.add(
        AgentPrivacyControlSettingsLimits.maximumFutureClockSkew,
      ),
    )) {
      return _blocked(
        request: request,
        status: AgentPrivacyExportStatus.blockedInvalidInput,
        reason: 'export_request_clock_skew',
      );
    }

    if (!dataExportMasterEnabled) {
      return _blocked(
        request: request,
        status: AgentPrivacyExportStatus.blockedRoleScope,
        reason: 'data_export_master_switch_off',
      );
    }

    if (request.requestedByRole == AgentPrivacyControlRole.user) {
      if (request.exportScope != AgentPrivacyExportScope.ownData ||
          request.requesterRef != request.subjectRef) {
        return _blocked(
          request: request,
          status: AgentPrivacyExportStatus.blockedRoleScope,
          reason: 'user_export_must_be_own_data',
        );
      }
    } else if (request.requestedByRole == AgentPrivacyControlRole.owner ||
        request.requestedByRole == AgentPrivacyControlRole.superAdmin) {
      if (request.exportScope != AgentPrivacyExportScope.authorizedScopedData) {
        return _blocked(
          request: request,
          status: AgentPrivacyExportStatus.blockedRoleScope,
          reason: 'owner_admin_export_requires_authorized_scope',
        );
      }
    } else {
      return _blocked(
        request: request,
        status: AgentPrivacyExportStatus.blockedRoleScope,
        reason: 'unsupported_export_role',
      );
    }

    for (final kind in request.requestedDataKinds) {
      final classification = classificationPolicy.classify(kind);

      if (classification.restrictedCritical) {
        return _blocked(
          request: request,
          status: AgentPrivacyExportStatus.blockedRestrictedCritical,
          reason: 'restricted_critical_data_not_exportable',
        );
      }

      if (classification.protectedEvidence) {
        return _blocked(
          request: request,
          status: AgentPrivacyExportStatus.blockedProtectedEvidence,
          reason: 'protected_evidence_not_generic_exportable',
        );
      }

      final requiredDomain = _requiredDomainFor(kind);

      if (requiredDomain != AgentPrivacyAccessDomain.general) {
        if (!strictDomainExportEnabled ||
            !request.strictDomainAuthorizationConfirmed ||
            request.domain != requiredDomain) {
          return _blocked(
            request: request,
            status: AgentPrivacyExportStatus.blockedStrictDomain,
            reason: 'strict_domain_export_authorization_required',
          );
        }
      } else if (request.domain != AgentPrivacyAccessDomain.general) {
        return _blocked(
          request: request,
          status: AgentPrivacyExportStatus.blockedUnscopedData,
          reason: 'general_data_requires_general_export_domain',
        );
      }

      if (classification.redactionRequired &&
          !request.redactedProjectionConfirmed) {
        return _blocked(
          request: request,
          status: AgentPrivacyExportStatus.blockedRedaction,
          reason: 'redacted_projection_required_for_export',
        );
      }
    }

    return AgentPrivacyExportDecision(
      status: AgentPrivacyExportStatus.eligibleForSafeExportPackage,
      exportId: request.exportId,
      format: request.format,
      allowedDataKinds: List<String>.unmodifiable(request.requestedDataKinds),
      reasonCode: 'eligible_for_safe_redacted_export_package',
    );
  }

  String _requiredDomainFor(String dataKind) {
    switch (dataKind) {
      case AgentPrivacyDataKind.studentData:
        return AgentPrivacyAccessDomain.student;

      case AgentPrivacyDataKind.safetyEmergencyData:
        return AgentPrivacyAccessDomain.safety;

      case AgentPrivacyDataKind.financialData:
        return AgentPrivacyAccessDomain.financial;

      default:
        return AgentPrivacyAccessDomain.general;
    }
  }

  AgentPrivacyExportDecision _blocked({
    required AgentPrivacyExportRequest request,
    required String status,
    required String reason,
  }) {
    return AgentPrivacyExportDecision(
      status: status,
      exportId: request.exportId,
      format: request.format,
      allowedDataKinds: const <String>[],
      reasonCode: reason,
    );
  }

  bool get eligibilityOnly => true;
  bool get fetchesUserData => false;
  bool get generatesFile => false;
  bool get deliversDownload => false;
  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get callsProvider => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get overridesRuntimeGate => false;
  bool get writesBusinessData => false;
  bool get deletesData => false;
}
