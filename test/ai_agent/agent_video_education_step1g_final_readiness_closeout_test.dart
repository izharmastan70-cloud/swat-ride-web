import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/help/constants/help_video_education_adversarial_constants.dart';
import 'package:swat_ride/help/constants/help_video_education_availability_constants.dart';
import 'package:swat_ride/help/constants/help_video_education_progress_constants.dart';
import 'package:swat_ride/help/constants/help_video_education_recommendation_constants.dart';
import 'package:swat_ride/help/models/help_video_education_availability_decision.dart';
import 'package:swat_ride/help/models/help_video_education_privacy_safe_telemetry_event.dart';
import 'package:swat_ride/help/models/help_video_education_recommendation_decision.dart';
import 'package:swat_ride/help/services/help_video_education_adversarial_verification_service.dart';
import 'package:swat_ride/help/services/help_video_education_availability_policy_service.dart';
import 'package:swat_ride/help/services/help_video_education_catalog_contract_service.dart';
import 'package:swat_ride/help/services/help_video_education_safe_recommendation_service.dart';
import 'package:swat_ride/help/services/help_video_learning_progress_contract_service.dart';

void main() {
  const HelpVideoEducationCatalogContractService catalog =
      HelpVideoEducationCatalogContractService();

  const HelpVideoEducationSafeRecommendationService recommendation =
      HelpVideoEducationSafeRecommendationService();

  const HelpVideoLearningProgressContractService progress =
      HelpVideoLearningProgressContractService();

  const HelpVideoEducationAvailabilityPolicyService availability =
      HelpVideoEducationAvailabilityPolicyService();

  const HelpVideoEducationAdversarialVerificationService adversarial =
      HelpVideoEducationAdversarialVerificationService();

  HelpVideoEducationRecommendationDecision safeRecommendation({
    String tutorialId = 'ride_booking_urdu_v1',
  }) {
    return HelpVideoEducationRecommendationDecision(
      status: HelpVideoEducationRecommendationStatus.recommended,
      tutorialId: tutorialId,
      normalizedAudience: 'customer',
      normalizedLanguage: 'ur',
      matchedModule: true,
      matchedFeature: true,
      intentMatchCount: 1,
      reasonCodes: const <String>[
        'existing_contextual_ranking_reused',
        'candidate_catalog_eligible',
        'audience_matched',
        'language_matched',
        'module_matched',
        'feature_matched',
        'intent_matched',
        'recommendation_only',
        'non_authoritative_content',
      ],
    );
  }

  HelpVideoEducationAvailabilityDecision safeAvailability({
    String tutorialId = 'ride_booking_urdu_v1',
  }) {
    return HelpVideoEducationAvailabilityDecision(
      status: HelpVideoEducationAvailabilityStatus.available,
      tutorialId: tutorialId,
      maintenanceReviewRequired: false,
      reasonCodes: const <String>[
        'existing_admin_control_reused',
        'existing_version_awareness_reused',
        'admin_enabled',
        'approval_verified',
        'recommendation_safety_verified',
        'version_current',
        'availability_policy_only',
        'non_authoritative_content',
      ],
    );
  }

  HelpVideoEducationPrivacySafeTelemetryEvent safeTelemetry({
    String tutorialId = 'ride_booking_urdu_v1',
  }) {
    return adversarial.buildTelemetry(
      tutorialId: tutorialId,
      eventType: HelpVideoEducationTelemetryEventType.surfaceAllowed,
      module: 'ride',
      feature: 'booking',
      language: 'ur',
      appVersion: '1.0.0',
      videoVersion: 'v1',
      reasonCode: 'surface_allowed',
      occurredAt: DateTime.utc(2026, 8, 19, 15),
    );
  }

  group('Phase 55 Step 1G final readiness closeout', () {
    test('Step 1B reuses existing tutorial model and stays catalog-only', () {
      expect(catalog.reusesExistingTutorialModel, isTrue);
      expect(catalog.createsDuplicateVideoItemModel, isFalse);
      expect(catalog.catalogMetadataOnly, isTrue);
      expect(catalog.generatesContent, isFalse);
      expect(catalog.invokesProvider, isFalse);
      expect(catalog.grantsAuthority, isFalse);
      expect(catalog.writesBusinessData, isFalse);
      expect(catalog.persistsCatalogDecision, isFalse);
    });

    test('Step 1C reuses contextual matcher with safety gate only', () {
      expect(recommendation.reusesExistingContextualVideoGuideService, isTrue);
      expect(recommendation.implementsDuplicateScoringEngine, isFalse);
      expect(recommendation.recommendationSafetyGateOnly, isTrue);
      expect(recommendation.opensExternalUrl, isFalse);
      expect(recommendation.invokesProvider, isFalse);
      expect(recommendation.grantsAuthority, isFalse);
      expect(recommendation.writesBusinessData, isFalse);
      expect(recommendation.persistsRecommendation, isFalse);
    });

    test(
      'Step 1D keeps progress metadata-only and explicit-completion based',
      () {
        expect(progress.reusesStep1CSafeRecommendation, isTrue);
        expect(progress.implementsDuplicateRankingEngine, isFalse);
        expect(progress.progressContractOnly, isTrue);
        expect(progress.completionRequiresExplicitConfirmation, isTrue);
        expect(progress.autoMarksComplete, isFalse);
        expect(progress.autoOpensVideo, isFalse);
        expect(progress.persistsLearningProgress, isFalse);
        expect(progress.persistsNextRecommendation, isFalse);
      },
    );

    test(
      'Step 1D completed tutorial can recommend only Step 1C-safe next item',
      () {
        final current = progress.buildProgress(
          tutorialId: 'ride_intro_v1',
          watchedSeconds: 120,
          durationSeconds: 120,
          completionConfirmed: true,
          updatedAt: DateTime.utc(2026, 8, 19, 15),
        );

        final decision = progress.evaluateNextVideo(
          currentProgress: current,
          safeCandidateDecision: safeRecommendation(
            tutorialId: 'ride_booking_urdu_v1',
          ),
        );

        expect(
          decision.status,
          HelpVideoNextRecommendationStatus.recommendNext,
        );
        expect(decision.canRecommendNext, isTrue);
        expect(decision.autoOpensVideo, isFalse);
        expect(decision.autoMarksComplete, isFalse);
      },
    );

    test('Step 1E reuses admin/version/maintenance and stays policy-only', () {
      expect(availability.reusesExistingAdminControl, isTrue);
      expect(availability.reusesExistingVersionAwareness, isTrue);
      expect(availability.reusesExistingMaintenanceWorkflow, isTrue);
      expect(availability.implementsDuplicateAdminWriteSystem, isFalse);
      expect(availability.availabilityPolicyOnly, isTrue);
      expect(availability.changesAdminState, isFalse);
      expect(availability.publishesTutorial, isFalse);
      expect(availability.disablesTutorial, isFalse);
      expect(availability.createsMaintenanceDraft, isFalse);
    });

    test('Step 1E blocks outdated content and requires maintenance review', () {
      final decision = availability.evaluate(
        tutorialId: 'ride_booking_urdu_v1',
        safeRecommendationDecision: safeRecommendation(),
        adminEnabled: true,
        approvalVerified: true,
        safeForRecommendation: true,
        versionOutdated: true,
      );

      expect(
        decision.status,
        HelpVideoEducationAvailabilityStatus.blockedOutdated,
      );
      expect(decision.canSurface, isFalse);
      expect(decision.maintenanceReviewRequired, isTrue);
    });

    test(
      'Step 1F reuses safe-url/playback/analytics and isolates failures',
      () {
        expect(adversarial.reusesExistingSafeUrlPolicy, isTrue);
        expect(adversarial.reusesExistingPlaybackPolicy, isTrue);
        expect(adversarial.reusesExistingAnalyticsFoundation, isTrue);
        expect(adversarial.adversarialVerificationOnly, isTrue);
        expect(adversarial.failureIsolationEnabled, isTrue);
        expect(adversarial.rawPrivateTelemetryForbidden, isTrue);
        expect(adversarial.opensExternalUrl, isFalse);
        expect(adversarial.invokesProvider, isFalse);
        expect(adversarial.retriesProvider, isFalse);
      },
    );

    test('Step 1F dependency failure fails closed', () {
      final result = adversarial.evaluate(
        tutorialId: 'ride_booking_urdu_v1',
        availabilityDecision: safeAvailability(),
        safeUrlVerifiedByExistingPolicy: true,
        dependencyHealthy: false,
        telemetryEvent: safeTelemetry(),
      );

      expect(
        result.status,
        HelpVideoEducationAdversarialStatus.failClosedDependencyFailure,
      );
      expect(result.canSurface, isFalse);
      expect(result.failureIsolated, isTrue);
    });

    test('Step 1F bad link fails closed', () {
      final result = adversarial.evaluate(
        tutorialId: 'ride_booking_urdu_v1',
        availabilityDecision: safeAvailability(),
        safeUrlVerifiedByExistingPolicy: false,
        dependencyHealthy: true,
        telemetryEvent: safeTelemetry(),
      );

      expect(result.status, HelpVideoEducationAdversarialStatus.blockedBadLink);
      expect(result.canSurface, isFalse);
    });

    test(
      'privacy-safe telemetry excludes raw/private authority-bearing data',
      () {
        final map = safeTelemetry().toSafeMap();

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
      },
    );

    test('private telemetry keys remain forbidden', () {
      expect(
        adversarial.containsForbiddenPrivateField(<String, Object?>{
          'rawMessage': 'private',
        }),
        isTrue,
      );
      expect(
        adversarial.containsForbiddenPrivateField(<String, Object?>{
          'authToken': 'secret',
        }),
        isTrue,
      );
      expect(
        adversarial.containsForbiddenPrivateField(<String, Object?>{
          'cardNumber': '4111111111111111',
        }),
        isTrue,
      );
      expect(
        adversarial.containsForbiddenPrivateField(<String, Object?>{
          'latitude': 34.0,
        }),
        isTrue,
      );
      expect(
        adversarial.containsForbiddenPrivateField(<String, Object?>{
          'videoUrl': 'https://example.invalid/video',
        }),
        isTrue,
      );
    });

    test('locked adversarial catalog stays exactly 14 scenarios', () {
      expect(HelpVideoEducationAdversarialScenario.values.length, 14);
    });

    test('Phase 55 cannot invoke authority/provider/business execution', () {
      expect(catalog.grantsPermission, isFalse);
      expect(catalog.consumesApproval, isFalse);
      expect(catalog.marksRuntimeAllowed, isFalse);

      expect(recommendation.invokesPermissionEngine, isFalse);
      expect(recommendation.invokesApprovalEngine, isFalse);
      expect(recommendation.invokesRuntimeGate, isFalse);
      expect(recommendation.invokesEmergencyStop, isFalse);

      expect(progress.invokesPermissionEngine, isFalse);
      expect(progress.invokesApprovalEngine, isFalse);
      expect(progress.invokesRuntimeGate, isFalse);
      expect(progress.invokesEmergencyStop, isFalse);

      expect(availability.invokesPermissionEngine, isFalse);
      expect(availability.invokesApprovalEngine, isFalse);
      expect(availability.invokesRuntimeGate, isFalse);
      expect(availability.invokesEmergencyStop, isFalse);

      expect(adversarial.invokesPermissionEngine, isFalse);
      expect(adversarial.invokesApprovalEngine, isFalse);
      expect(adversarial.invokesRuntimeGate, isFalse);
      expect(adversarial.invokesEmergencyStop, isFalse);
      expect(adversarial.writesBusinessData, isFalse);
    });

    test('Phase 56/57/63 ownership remains separate', () {
      expect(catalog.implementsPhase56ContentGeneration, isFalse);
      expect(catalog.implementsPhase57KnowledgeLibrary, isFalse);
      expect(catalog.implementsPhase63PrivacyUi, isFalse);

      expect(recommendation.implementsPhase56ContentGeneration, isFalse);
      expect(recommendation.implementsPhase57KnowledgeLibrary, isFalse);
      expect(recommendation.implementsPhase63PrivacyUi, isFalse);

      expect(progress.implementsPhase56ContentGeneration, isFalse);
      expect(progress.implementsPhase57KnowledgeLibrary, isFalse);
      expect(progress.implementsPhase63PrivacyUi, isFalse);

      expect(availability.implementsPhase56ContentGeneration, isFalse);
      expect(availability.implementsPhase57KnowledgeLibrary, isFalse);
      expect(availability.implementsPhase63PrivacyUi, isFalse);

      expect(adversarial.implementsPhase56ContentGeneration, isFalse);
      expect(adversarial.implementsPhase57KnowledgeLibrary, isFalse);
      expect(adversarial.implementsPhase63PrivacyUi, isFalse);
    });

    test(
      'final Phase 55 status is foundation-ready, not production active',
      () {
        const String status = 'FOUNDATION_READY_NOT_PRODUCTION_ACTIVE';

        expect(status, 'FOUNDATION_READY_NOT_PRODUCTION_ACTIVE');
        expect(catalog.invokesProvider, isFalse);
        expect(recommendation.invokesProvider, isFalse);
        expect(progress.invokesProvider, isFalse);
        expect(availability.invokesProvider, isFalse);
        expect(adversarial.invokesProvider, isFalse);
      },
    );
  });
}
