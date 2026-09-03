import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/help/constants/help_video_education_adversarial_constants.dart';
import 'package:swat_ride/help/constants/help_video_education_availability_constants.dart';
import 'package:swat_ride/help/models/help_video_education_adversarial_verification_result.dart';
import 'package:swat_ride/help/models/help_video_education_availability_decision.dart';
import 'package:swat_ride/help/models/help_video_education_privacy_safe_telemetry_event.dart';
import 'package:swat_ride/help/services/help_video_education_adversarial_verification_service.dart';

void main() {
  const HelpVideoEducationAdversarialVerificationService service =
      HelpVideoEducationAdversarialVerificationService();

  HelpVideoEducationAvailabilityDecision available({
    String tutorialId = 'ride_booking_urdu_v1',
    String status = HelpVideoEducationAvailabilityStatus.available,
  }) {
    return HelpVideoEducationAvailabilityDecision(
      status: status,
      tutorialId: tutorialId,
      maintenanceReviewRequired:
          status == HelpVideoEducationAvailabilityStatus.blockedOutdated,
      reasonCodes: status == HelpVideoEducationAvailabilityStatus.available
          ? const <String>[
              'existing_admin_control_reused',
              'existing_version_awareness_reused',
              'admin_enabled',
              'approval_verified',
              'recommendation_safety_verified',
              'version_current',
              'availability_policy_only',
              'non_authoritative_content',
            ]
          : const <String>[
              'existing_admin_control_reused',
              'admin_disabled',
              'availability_policy_only',
              'non_authoritative_content',
            ],
    );
  }

  HelpVideoEducationPrivacySafeTelemetryEvent telemetry({
    String tutorialId = 'ride_booking_urdu_v1',
    String eventType = HelpVideoEducationTelemetryEventType.surfaceAllowed,
    String module = 'ride',
    String feature = 'booking',
    String language = 'ur',
    String appVersion = '1.0.0',
    String videoVersion = 'v1',
    String reasonCode = 'surface_allowed',
  }) {
    return service.buildTelemetry(
      tutorialId: tutorialId,
      eventType: eventType,
      module: module,
      feature: feature,
      language: language,
      appVersion: appVersion,
      videoVersion: videoVersion,
      reasonCode: reasonCode,
      occurredAt: DateTime.utc(2026, 8, 19, 14),
    );
  }

  HelpVideoEducationAdversarialVerificationResult evaluate({
    HelpVideoEducationAvailabilityDecision? availability,
    bool safeUrlVerified = true,
    bool dependencyHealthy = true,
    HelpVideoEducationPrivacySafeTelemetryEvent? event,
  }) {
    return service.evaluate(
      tutorialId: 'ride_booking_urdu_v1',
      availabilityDecision: availability ?? available(),
      safeUrlVerifiedByExistingPolicy: safeUrlVerified,
      dependencyHealthy: dependencyHealthy,
      telemetryEvent: event ?? telemetry(),
    );
  }

  group('Phase 55 Step 1F adversarial/failure isolation', () {
    test('safe candidate remains SAFE_TO_SURFACE', () {
      final result = evaluate();
      expect(result.status, HelpVideoEducationAdversarialStatus.safeToSurface);
      expect(result.canSurface, isTrue);
      expect(result.failureIsolated, isTrue);
    });

    test('bad/malformed URL policy result blocks candidate', () {
      final result = evaluate(safeUrlVerified: false);
      expect(result.status, HelpVideoEducationAdversarialStatus.blockedBadLink);
      expect(result.canSurface, isFalse);
    });

    test('disabled Step 1E candidate is blocked', () {
      final result = evaluate(
        availability: available(
          status: HelpVideoEducationAvailabilityStatus.blockedDisabled,
        ),
      );
      expect(
        result.status,
        HelpVideoEducationAdversarialStatus.blockedUnsafeAvailability,
      );
    });

    test('dependency/provider failure fails closed and is isolated', () {
      final result = evaluate(dependencyHealthy: false);
      expect(
        result.status,
        HelpVideoEducationAdversarialStatus.failClosedDependencyFailure,
      );
      expect(result.failureIsolated, isTrue);
      expect(result.canSurface, isFalse);
    });

    test('invalid telemetry fails closed without escaping exception', () {
      final badEvent = HelpVideoEducationPrivacySafeTelemetryEvent(
        tutorialId: 'ride_booking_urdu_v1',
        eventType: 'NOT_A_REAL_EVENT',
        module: 'ride',
        feature: 'booking',
        language: 'ur',
        appVersion: '1.0.0',
        videoVersion: 'v1',
        reasonCode: 'bad',
        occurredAt: DateTime.utc(2026, 8, 19, 14),
      );

      final result = evaluate(event: badEvent);

      expect(
        result.status,
        HelpVideoEducationAdversarialStatus.blockedTelemetry,
      );
      expect(result.failureIsolated, isTrue);
    });

    test('safe telemetry map contains metadata only', () {
      final map = telemetry().toSafeMap();
      expect(map['metadataOnly'], isTrue);
      expect(map['containsRawMessage'], isFalse);
      expect(map['containsPhone'], isFalse);
      expect(map['containsEmail'], isFalse);
      expect(map['containsAuthToken'], isFalse);
      expect(map['containsPaymentSecret'], isFalse);
      expect(map['containsPreciseLocation'], isFalse);
      expect(map['containsVideoUrl'], isFalse);
      expect(map['grantsAuthority'], isFalse);
      expect(map['writesBusinessData'], isFalse);
      expect(map['persistsTelemetry'], isFalse);
    });

    test('raw message telemetry field is forbidden', () {
      expect(
        service.containsForbiddenPrivateField(<String, Object?>{
          'tutorialId': 'ride_booking_urdu_v1',
          'rawMessage': 'private',
        }),
        isTrue,
      );
    });

    test('phone telemetry field is forbidden', () {
      expect(
        service.containsForbiddenPrivateField(<String, Object?>{
          'tutorialId': 'ride_booking_urdu_v1',
          'phoneNumber': '+920000000000',
        }),
        isTrue,
      );
    });

    test('email telemetry field is forbidden', () {
      expect(
        service.containsForbiddenPrivateField(<String, Object?>{
          'tutorialId': 'ride_booking_urdu_v1',
          'email': 'private@example.invalid',
        }),
        isTrue,
      );
    });

    test('auth token telemetry field is forbidden', () {
      expect(
        service.containsForbiddenPrivateField(<String, Object?>{
          'tutorialId': 'ride_booking_urdu_v1',
          'authToken': 'secret',
        }),
        isTrue,
      );
    });

    test('payment secret telemetry field is forbidden', () {
      expect(
        service.containsForbiddenPrivateField(<String, Object?>{
          'tutorialId': 'ride_booking_urdu_v1',
          'cardNumber': '4111111111111111',
        }),
        isTrue,
      );
    });

    test('precise location telemetry field is forbidden', () {
      expect(
        service.containsForbiddenPrivateField(<String, Object?>{
          'tutorialId': 'ride_booking_urdu_v1',
          'latitude': 34.0,
        }),
        isTrue,
      );
    });

    test('video URL is not telemetry metadata', () {
      expect(
        service.containsForbiddenPrivateField(<String, Object?>{
          'tutorialId': 'ride_booking_urdu_v1',
          'videoUrl': 'https://example.invalid/video',
        }),
        isTrue,
      );
    });

    test('bounded metadata-only payload is accepted by privacy checker', () {
      expect(
        service.containsForbiddenPrivateField(<String, Object?>{
          'tutorialId': 'ride_booking_urdu_v1',
          'module': 'ride',
          'feature': 'booking',
          'language': 'ur',
          'eventType': 'SURFACE_ALLOWED',
        }),
        isFalse,
      );
    });

    test('verification result cannot execute providers or authority', () {
      final result = evaluate();
      expect(result.verificationOnly, isTrue);
      expect(result.opensExternalUrl, isFalse);
      expect(result.invokesProvider, isFalse);
      expect(result.retriesProvider, isFalse);
      expect(result.mutatesAnalyticsStore, isFalse);
      expect(result.generatesContent, isFalse);
      expect(result.grantsAuthority, isFalse);
      expect(result.grantsPermission, isFalse);
      expect(result.consumesApproval, isFalse);
      expect(result.marksRuntimeAllowed, isFalse);
      expect(result.writesBusinessData, isFalse);
      expect(result.persistsResult, isFalse);
    });

    test('service reuses existing foundations and isolates failures', () {
      expect(service.reusesExistingSafeUrlPolicy, isTrue);
      expect(service.reusesExistingPlaybackPolicy, isTrue);
      expect(service.reusesExistingAnalyticsFoundation, isTrue);
      expect(service.adversarialVerificationOnly, isTrue);
      expect(service.failureIsolationEnabled, isTrue);
      expect(service.rawPrivateTelemetryForbidden, isTrue);
    });

    test('service cannot execute provider/gates/business writes', () {
      expect(service.opensExternalUrl, isFalse);
      expect(service.invokesProvider, isFalse);
      expect(service.retriesProvider, isFalse);
      expect(service.generatesContent, isFalse);
      expect(service.grantsAuthority, isFalse);
      expect(service.grantsPermission, isFalse);
      expect(service.consumesApproval, isFalse);
      expect(service.marksRuntimeAllowed, isFalse);
      expect(service.invokesPermissionEngine, isFalse);
      expect(service.invokesApprovalEngine, isFalse);
      expect(service.invokesRuntimeGate, isFalse);
      expect(service.invokesEmergencyStop, isFalse);
      expect(service.writesBusinessData, isFalse);
      expect(service.persistsTelemetry, isFalse);
      expect(service.persistsVerification, isFalse);
    });

    test('Phase 56/57/63 boundaries remain separate', () {
      expect(service.implementsPhase56ContentGeneration, isFalse);
      expect(service.implementsPhase57KnowledgeLibrary, isFalse);
      expect(service.implementsPhase63PrivacyUi, isFalse);
    });

    test('locked adversarial scenario catalog contains 14 cases', () {
      expect(HelpVideoEducationAdversarialScenario.values.length, 14);
    });
  });
}
