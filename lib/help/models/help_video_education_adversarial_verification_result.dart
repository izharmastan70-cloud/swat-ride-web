import '../constants/help_video_education_adversarial_constants.dart';
import 'help_video_education_privacy_safe_telemetry_event.dart';

class HelpVideoEducationAdversarialVerificationResult {
  HelpVideoEducationAdversarialVerificationResult({
    required this.status,
    required this.tutorialId,
    required this.failureIsolated,
    required this.telemetryEvent,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String tutorialId;
  final bool failureIsolated;
  final HelpVideoEducationPrivacySafeTelemetryEvent? telemetryEvent;
  final List<String> reasonCodes;

  bool get canSurface =>
      status == HelpVideoEducationAdversarialStatus.safeToSurface;

  bool get verificationOnly => true;
  bool get opensExternalUrl => false;
  bool get invokesProvider => false;
  bool get retriesProvider => false;
  bool get mutatesAnalyticsStore => false;
  bool get generatesContent => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get writesBusinessData => false;
  bool get persistsResult => false;

  void validateStructure() {
    if (!HelpVideoEducationAdversarialStatus.values.contains(status)) {
      throw const HelpVideoEducationAdversarialVerificationException(
        'Adversarial verification status is invalid.',
      );
    }

    if (tutorialId.trim().isEmpty || tutorialId.length > 180) {
      throw const HelpVideoEducationAdversarialVerificationException(
        'Adversarial tutorial ID is invalid.',
      );
    }

    if (reasonCodes.isEmpty || reasonCodes.length > 10) {
      throw const HelpVideoEducationAdversarialVerificationException(
        'Adversarial reason codes are invalid.',
      );
    }

    for (final String reason in reasonCodes) {
      if (!HelpVideoEducationAdversarialReason.values.contains(reason)) {
        throw const HelpVideoEducationAdversarialVerificationException(
          'Adversarial reason code is invalid.',
        );
      }
    }

    telemetryEvent?.validateStructure();

    if (status ==
            HelpVideoEducationAdversarialStatus.failClosedDependencyFailure &&
        !failureIsolated) {
      throw const HelpVideoEducationAdversarialVerificationException(
        'Dependency failure must be isolated.',
      );
    }
  }
}

class HelpVideoEducationAdversarialVerificationException implements Exception {
  const HelpVideoEducationAdversarialVerificationException(this.message);

  final String message;

  @override
  String toString() =>
      'HelpVideoEducationAdversarialVerificationException: $message';
}
