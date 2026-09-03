import '../constants/agent_privacy_deletion_retention_constants.dart';
import '../models/agent_privacy_retention_override_decision.dart';
import '../models/agent_privacy_retention_override_request.dart';
import 'agent_channel_retention_policy_service.dart';

class AgentPrivacyRetentionOverridePolicy {
  const AgentPrivacyRetentionOverridePolicy({
    this.channelPolicyService = const AgentChannelRetentionPolicyService(),
  });

  final AgentChannelRetentionPolicyService channelPolicyService;

  AgentPrivacyRetentionOverrideDecision evaluate({
    required AgentPrivacyRetentionOverrideRequest request,
    required DateTime evaluatedAtUtc,
  }) {
    try {
      request.validate();

      if (!evaluatedAtUtc.isUtc) {
        throw const FormatException(
          'Retention override evaluation time must be UTC.',
        );
      }
    } catch (_) {
      return _decision(
        request: request,
        status: AgentPrivacyRetentionOverrideStatus.blockedInvalidInput,
        reason: 'invalid_retention_override_request',
      );
    }

    if (request.requestedAtUtc.isAfter(
      evaluatedAtUtc.add(AgentPrivacyDeletionLimits.maximumFutureClockSkew),
    )) {
      return _decision(
        request: request,
        status: AgentPrivacyRetentionOverrideStatus.blockedInvalidInput,
        reason: 'retention_override_clock_skew',
      );
    }

    if (!AgentPrivacyRetentionOverrideRole.values.contains(
      request.requestedByRole,
    )) {
      return _decision(
        request: request,
        status: AgentPrivacyRetentionOverrideStatus.blockedRole,
        reason: 'owner_or_super_admin_role_required',
      );
    }

    if (request.protectedEvidence) {
      return _decision(
        request: request,
        status: AgentPrivacyRetentionOverrideStatus.blockedProtectedEvidence,
        reason: 'channel_override_cannot_modify_protected_evidence',
      );
    }

    final channelPolicy = channelPolicyService.policyFor(request.channel);

    if (!channelPolicy.isOwnerRequestedDaysWithinFoundationBounds(
      request.requestedDays,
    )) {
      return _decision(
        request: request,
        status: AgentPrivacyRetentionOverrideStatus.blockedChannelCap,
        reason: 'requested_days_exceed_channel_foundation_cap',
      );
    }

    return _decision(
      request: request,
      status: AgentPrivacyRetentionOverrideStatus.eligibleFoundationOverride,
      reason: 'eligible_for_later_owner_settings_review_only',
    );
  }

  AgentPrivacyRetentionOverrideDecision _decision({
    required AgentPrivacyRetentionOverrideRequest request,
    required String status,
    required String reason,
  }) {
    return AgentPrivacyRetentionOverrideDecision(
      status: status,
      overrideId: request.overrideId,
      channel: request.channel,
      requestedDays: request.requestedDays,
      reasonCode: reason,
    );
  }

  bool get foundationEligibilityOnly => true;
  bool get appliesProductionSetting => false;
  bool get writesFirestore => false;
  bool get changesProtectedEvidenceRetention => false;
  bool get deletesData => false;
  bool get purgesData => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get overridesRuntimeGate => false;
  bool get writesBusinessData => false;
}
