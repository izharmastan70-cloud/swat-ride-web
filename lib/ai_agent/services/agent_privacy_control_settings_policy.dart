import '../constants/agent_privacy_control_export_constants.dart';
import '../constants/agent_privacy_retention_classification_constants.dart';
import '../models/agent_privacy_control_settings.dart';
import '../models/agent_privacy_retention_override_request.dart';
import 'agent_privacy_retention_override_policy.dart';

class AgentPrivacyControlSettingsPolicy {
  const AgentPrivacyControlSettingsPolicy({
    this.overridePolicy = const AgentPrivacyRetentionOverridePolicy(),
  });

  final AgentPrivacyRetentionOverridePolicy overridePolicy;

  bool isFoundationSettingsValid({
    required AgentPrivacyControlSettings settings,
    required DateTime evaluatedAtUtc,
  }) {
    try {
      settings.validate();
    } catch (_) {
      return false;
    }

    if (!evaluatedAtUtc.isUtc) {
      return false;
    }

    if (settings.updatedAtUtc.isAfter(
      evaluatedAtUtc.add(
        AgentPrivacyControlSettingsLimits.maximumFutureClockSkew,
      ),
    )) {
      return false;
    }

    final role = settings.updatedByRole;

    if (role != AgentPrivacyControlRole.owner &&
        role != AgentPrivacyControlRole.superAdmin) {
      return false;
    }

    final checks = <AgentPrivacyRetentionOverrideRequest>[
      AgentPrivacyRetentionOverrideRequest(
        overrideId: 'preview:chat',
        channel: AgentPrivacyChannel.chat,
        requestedDays: settings.chatRetentionDays,
        requestedByRole: role,
        protectedEvidence: false,
        requestedAtUtc: settings.updatedAtUtc,
      ),
      AgentPrivacyRetentionOverrideRequest(
        overrideId: 'preview:transcript',
        channel: AgentPrivacyChannel.callTranscript,
        requestedDays: settings.callTranscriptRetentionDays,
        requestedByRole: role,
        protectedEvidence: false,
        requestedAtUtc: settings.updatedAtUtc,
      ),
      AgentPrivacyRetentionOverrideRequest(
        overrideId: 'preview:recording',
        channel: AgentPrivacyChannel.callRecording,
        requestedDays: settings.callRecordingRetentionDays,
        requestedByRole: role,
        protectedEvidence: false,
        requestedAtUtc: settings.updatedAtUtc,
      ),
      AgentPrivacyRetentionOverrideRequest(
        overrideId: 'preview:email',
        channel: AgentPrivacyChannel.email,
        requestedDays: settings.emailRetentionDays,
        requestedByRole: role,
        protectedEvidence: false,
        requestedAtUtc: settings.updatedAtUtc,
      ),
      AgentPrivacyRetentionOverrideRequest(
        overrideId: 'preview:whatsapp',
        channel: AgentPrivacyChannel.whatsappAi,
        requestedDays: settings.whatsappAiRetentionDays,
        requestedByRole: role,
        protectedEvidence: false,
        requestedAtUtc: settings.updatedAtUtc,
      ),
    ];

    for (final request in checks) {
      final decision = overridePolicy.evaluate(
        request: request,
        evaluatedAtUtc: evaluatedAtUtc,
      );

      if (!decision.eligibleForLaterSettingsReview) {
        return false;
      }
    }

    return true;
  }

  bool get previewOnly => true;
  bool get appliesProductionSettings => false;
  bool get writesFirestore => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get overridesRuntimeGate => false;
  bool get deletesData => false;
}
