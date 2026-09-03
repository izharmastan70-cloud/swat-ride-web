import '../constants/help_video_education_adversarial_constants.dart';
import '../models/help_video_education_adversarial_verification_result.dart';
import '../models/help_video_education_availability_decision.dart';
import '../models/help_video_education_privacy_safe_telemetry_event.dart';

class HelpVideoEducationAdversarialVerificationService {
  const HelpVideoEducationAdversarialVerificationService();

  HelpVideoEducationAdversarialVerificationResult evaluate({
    required String tutorialId,
    required HelpVideoEducationAvailabilityDecision availabilityDecision,
    required bool safeUrlVerifiedByExistingPolicy,
    required bool dependencyHealthy,
    required HelpVideoEducationPrivacySafeTelemetryEvent telemetryEvent,
  }) {
    try {
      availabilityDecision.validateStructure();
      telemetryEvent.validateStructure();

      if (availabilityDecision.tutorialId.trim() != tutorialId.trim() ||
          !availabilityDecision.canSurface) {
        return _result(
          status: HelpVideoEducationAdversarialStatus.blockedUnsafeAvailability,
          tutorialId: _safeId(tutorialId),
          failureIsolated: true,
          telemetryEvent: telemetryEvent,
          reasons: const <String>[
            HelpVideoEducationAdversarialReason.step1eAvailabilityRequired,
            HelpVideoEducationAdversarialReason.telemetryMetadataOnly,
            HelpVideoEducationAdversarialReason.rawPrivateDataForbidden,
            HelpVideoEducationAdversarialReason.noProviderExecution,
            HelpVideoEducationAdversarialReason.nonAuthoritativeContent,
          ],
        );
      }

      if (!safeUrlVerifiedByExistingPolicy) {
        return _result(
          status: HelpVideoEducationAdversarialStatus.blockedBadLink,
          tutorialId: tutorialId.trim(),
          failureIsolated: true,
          telemetryEvent: telemetryEvent,
          reasons: const <String>[
            HelpVideoEducationAdversarialReason.existingSafeUrlPolicyReused,
            HelpVideoEducationAdversarialReason.badLinkBlocked,
            HelpVideoEducationAdversarialReason.telemetryMetadataOnly,
            HelpVideoEducationAdversarialReason.noProviderExecution,
            HelpVideoEducationAdversarialReason.nonAuthoritativeContent,
          ],
        );
      }

      if (!dependencyHealthy) {
        return _result(
          status:
              HelpVideoEducationAdversarialStatus.failClosedDependencyFailure,
          tutorialId: tutorialId.trim(),
          failureIsolated: true,
          telemetryEvent: telemetryEvent,
          reasons: const <String>[
            HelpVideoEducationAdversarialReason.existingPlaybackPolicyReused,
            HelpVideoEducationAdversarialReason.dependencyFailureIsolated,
            HelpVideoEducationAdversarialReason.telemetryMetadataOnly,
            HelpVideoEducationAdversarialReason.noProviderExecution,
            HelpVideoEducationAdversarialReason.nonAuthoritativeContent,
          ],
        );
      }

      return _result(
        status: HelpVideoEducationAdversarialStatus.safeToSurface,
        tutorialId: tutorialId.trim(),
        failureIsolated: true,
        telemetryEvent: telemetryEvent,
        reasons: const <String>[
          HelpVideoEducationAdversarialReason.existingSafeUrlPolicyReused,
          HelpVideoEducationAdversarialReason.existingPlaybackPolicyReused,
          HelpVideoEducationAdversarialReason.existingAnalyticsFoundationReused,
          HelpVideoEducationAdversarialReason.safeUrlVerified,
          HelpVideoEducationAdversarialReason.telemetryValidationPassed,
          HelpVideoEducationAdversarialReason.telemetryMetadataOnly,
          HelpVideoEducationAdversarialReason.rawPrivateDataForbidden,
          HelpVideoEducationAdversarialReason.noProviderExecution,
          HelpVideoEducationAdversarialReason.nonAuthoritativeContent,
        ],
      );
    } catch (_) {
      final HelpVideoEducationPrivacySafeTelemetryEvent? safeTelemetry =
          _tryValidatedTelemetry(telemetryEvent);

      return _result(
        status: HelpVideoEducationAdversarialStatus.blockedTelemetry,
        tutorialId: _safeId(tutorialId),
        failureIsolated: true,
        telemetryEvent: safeTelemetry,
        reasons: const <String>[
          HelpVideoEducationAdversarialReason.telemetryValidationBlocked,
          HelpVideoEducationAdversarialReason.rawPrivateDataForbidden,
          HelpVideoEducationAdversarialReason.dependencyFailureIsolated,
          HelpVideoEducationAdversarialReason.noProviderExecution,
          HelpVideoEducationAdversarialReason.nonAuthoritativeContent,
        ],
      );
    }
  }

  HelpVideoEducationPrivacySafeTelemetryEvent buildTelemetry({
    required String tutorialId,
    required String eventType,
    required String module,
    required String feature,
    required String language,
    required String appVersion,
    required String videoVersion,
    required String reasonCode,
    required DateTime occurredAt,
  }) {
    final HelpVideoEducationPrivacySafeTelemetryEvent event =
        HelpVideoEducationPrivacySafeTelemetryEvent(
          tutorialId: tutorialId.trim(),
          eventType: eventType,
          module: module.trim(),
          feature: feature.trim(),
          language: language.trim(),
          appVersion: appVersion.trim(),
          videoVersion: videoVersion.trim(),
          reasonCode: reasonCode.trim(),
          occurredAt: occurredAt,
        );

    event.validateStructure();
    return event;
  }

  bool containsForbiddenPrivateField(Map<String, Object?> payload) {
    const Set<String> forbidden = <String>{
      'rawMessage',
      'message',
      'prompt',
      'conversation',
      'phone',
      'phoneNumber',
      'email',
      'authToken',
      'accessToken',
      'refreshToken',
      'password',
      'paymentToken',
      'cardNumber',
      'cvv',
      'pin',
      'preciseLocation',
      'latitude',
      'longitude',
      'videoUrl',
    };

    return payload.keys.any(forbidden.contains);
  }

  HelpVideoEducationAdversarialVerificationResult _result({
    required String status,
    required String tutorialId,
    required bool failureIsolated,
    required HelpVideoEducationPrivacySafeTelemetryEvent? telemetryEvent,
    required List<String> reasons,
  }) {
    final HelpVideoEducationAdversarialVerificationResult result =
        HelpVideoEducationAdversarialVerificationResult(
          status: status,
          tutorialId: tutorialId,
          failureIsolated: failureIsolated,
          telemetryEvent: telemetryEvent,
          reasonCodes: reasons,
        );

    result.validateStructure();
    return result;
  }

  HelpVideoEducationPrivacySafeTelemetryEvent? _tryValidatedTelemetry(
    HelpVideoEducationPrivacySafeTelemetryEvent event,
  ) {
    try {
      event.validateStructure();
      return event;
    } catch (_) {
      return null;
    }
  }

  String _safeId(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty) return 'invalid_tutorial';
    if (trimmed.length <= 180) return trimmed;
    return trimmed.substring(0, 180);
  }

  bool get reusesExistingSafeUrlPolicy => true;
  bool get reusesExistingPlaybackPolicy => true;
  bool get reusesExistingAnalyticsFoundation => true;
  bool get adversarialVerificationOnly => true;
  bool get failureIsolationEnabled => true;
  bool get rawPrivateTelemetryForbidden => true;
  bool get opensExternalUrl => false;
  bool get invokesProvider => false;
  bool get retriesProvider => false;
  bool get generatesContent => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get writesBusinessData => false;
  bool get persistsTelemetry => false;
  bool get persistsVerification => false;
  bool get implementsPhase56ContentGeneration => false;
  bool get implementsPhase57KnowledgeLibrary => false;
  bool get implementsPhase63PrivacyUi => false;
}
