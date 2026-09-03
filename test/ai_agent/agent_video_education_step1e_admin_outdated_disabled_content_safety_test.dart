import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/help/constants/help_video_education_availability_constants.dart';
import 'package:swat_ride/help/constants/help_video_education_recommendation_constants.dart';
import 'package:swat_ride/help/models/help_video_education_recommendation_decision.dart';
import 'package:swat_ride/help/services/help_video_education_availability_policy_service.dart';

void main() {
  const HelpVideoEducationAvailabilityPolicyService service =
      HelpVideoEducationAvailabilityPolicyService();

  HelpVideoEducationRecommendationDecision safeRecommendation({
    String tutorialId = 'ride_booking_urdu_v1',
    String status = HelpVideoEducationRecommendationStatus.recommended,
  }) {
    return HelpVideoEducationRecommendationDecision(
      status: status,
      tutorialId: tutorialId,
      normalizedAudience: 'customer',
      normalizedLanguage: 'ur',
      matchedModule: true,
      matchedFeature: false,
      intentMatchCount: 0,
      reasonCodes: const <String>[
        'existing_contextual_ranking_reused',
        'candidate_catalog_eligible',
        'audience_matched',
        'language_matched',
        'module_matched',
        'recommendation_only',
        'non_authoritative_content',
      ],
    );
  }

  group('Phase 55 Step 1E admin/outdated-disabled safety', () {
    test('enabled approved safe current candidate is AVAILABLE', () {
      final decision = service.evaluate(
        tutorialId: 'ride_booking_urdu_v1',
        safeRecommendationDecision: safeRecommendation(),
        adminEnabled: true,
        approvalVerified: true,
        safeForRecommendation: true,
        versionOutdated: false,
      );

      expect(decision.status, HelpVideoEducationAvailabilityStatus.available);
      expect(decision.canSurface, isTrue);
      expect(decision.maintenanceReviewRequired, isFalse);
    });

    test('disabled tutorial is blocked', () {
      final decision = service.evaluate(
        tutorialId: 'ride_booking_urdu_v1',
        safeRecommendationDecision: safeRecommendation(),
        adminEnabled: false,
        approvalVerified: true,
        safeForRecommendation: true,
        versionOutdated: false,
      );

      expect(
        decision.status,
        HelpVideoEducationAvailabilityStatus.blockedDisabled,
      );
      expect(decision.canSurface, isFalse);
    });

    test('unapproved tutorial is blocked', () {
      final decision = service.evaluate(
        tutorialId: 'ride_booking_urdu_v1',
        safeRecommendationDecision: safeRecommendation(),
        adminEnabled: true,
        approvalVerified: false,
        safeForRecommendation: true,
        versionOutdated: false,
      );

      expect(
        decision.status,
        HelpVideoEducationAvailabilityStatus.blockedUnapproved,
      );
    });

    test('unsafe tutorial is blocked', () {
      final decision = service.evaluate(
        tutorialId: 'ride_booking_urdu_v1',
        safeRecommendationDecision: safeRecommendation(),
        adminEnabled: true,
        approvalVerified: true,
        safeForRecommendation: false,
        versionOutdated: false,
      );

      expect(
        decision.status,
        HelpVideoEducationAvailabilityStatus.blockedUnsafe,
      );
    });

    test('outdated tutorial is blocked and requires maintenance review', () {
      final decision = service.evaluate(
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

    test('unsafe Step 1C candidate is blocked before admin availability', () {
      final decision = service.evaluate(
        tutorialId: 'ride_booking_urdu_v1',
        safeRecommendationDecision: safeRecommendation(
          status: HelpVideoEducationRecommendationStatus.blockedContextMismatch,
        ),
        adminEnabled: true,
        approvalVerified: true,
        safeForRecommendation: true,
        versionOutdated: false,
      );

      expect(
        decision.status,
        HelpVideoEducationAvailabilityStatus.blockedRecommendation,
      );
    });

    test('mismatched tutorial identity is blocked', () {
      final decision = service.evaluate(
        tutorialId: 'ride_booking_urdu_v2',
        safeRecommendationDecision: safeRecommendation(
          tutorialId: 'ride_booking_urdu_v1',
        ),
        adminEnabled: true,
        approvalVerified: true,
        safeForRecommendation: true,
        versionOutdated: false,
      );

      expect(
        decision.status,
        HelpVideoEducationAvailabilityStatus.blockedRecommendation,
      );
    });

    test('disabled takes precedence over later approval/safety/version', () {
      final decision = service.evaluate(
        tutorialId: 'ride_booking_urdu_v1',
        safeRecommendationDecision: safeRecommendation(),
        adminEnabled: false,
        approvalVerified: false,
        safeForRecommendation: false,
        versionOutdated: true,
      );

      expect(
        decision.status,
        HelpVideoEducationAvailabilityStatus.blockedDisabled,
      );
    });

    test('unapproved takes precedence before unsafe/outdated', () {
      final decision = service.evaluate(
        tutorialId: 'ride_booking_urdu_v1',
        safeRecommendationDecision: safeRecommendation(),
        adminEnabled: true,
        approvalVerified: false,
        safeForRecommendation: false,
        versionOutdated: true,
      );

      expect(
        decision.status,
        HelpVideoEducationAvailabilityStatus.blockedUnapproved,
      );
    });

    test('unsafe takes precedence before outdated', () {
      final decision = service.evaluate(
        tutorialId: 'ride_booking_urdu_v1',
        safeRecommendationDecision: safeRecommendation(),
        adminEnabled: true,
        approvalVerified: true,
        safeForRecommendation: false,
        versionOutdated: true,
      );

      expect(
        decision.status,
        HelpVideoEducationAvailabilityStatus.blockedUnsafe,
      );
    });

    test('availability decision is policy only and non-authoritative', () {
      final decision = service.evaluate(
        tutorialId: 'ride_booking_urdu_v1',
        safeRecommendationDecision: safeRecommendation(),
        adminEnabled: true,
        approvalVerified: true,
        safeForRecommendation: true,
        versionOutdated: false,
      );

      expect(decision.availabilityPolicyOnly, isTrue);
      expect(decision.changesAdminState, isFalse);
      expect(decision.publishesTutorial, isFalse);
      expect(decision.disablesTutorial, isFalse);
      expect(decision.createsMaintenanceDraft, isFalse);
      expect(decision.autoOpensVideo, isFalse);
      expect(decision.generatesContent, isFalse);
      expect(decision.grantsAuthority, isFalse);
      expect(decision.invokesProvider, isFalse);
      expect(decision.writesBusinessData, isFalse);
      expect(decision.persistsDecision, isFalse);
    });

    test('service reuses existing admin/version/maintenance foundations', () {
      expect(service.reusesExistingAdminControl, isTrue);
      expect(service.reusesExistingVersionAwareness, isTrue);
      expect(service.reusesExistingMaintenanceWorkflow, isTrue);
      expect(service.implementsDuplicateAdminWriteSystem, isFalse);
      expect(service.availabilityPolicyOnly, isTrue);
    });

    test('service cannot write, publish, disable, or execute providers', () {
      expect(service.changesAdminState, isFalse);
      expect(service.publishesTutorial, isFalse);
      expect(service.disablesTutorial, isFalse);
      expect(service.createsMaintenanceDraft, isFalse);
      expect(service.autoOpensVideo, isFalse);
      expect(service.generatesContent, isFalse);
      expect(service.invokesProvider, isFalse);
      expect(service.grantsAuthority, isFalse);
      expect(service.grantsPermission, isFalse);
      expect(service.consumesApproval, isFalse);
      expect(service.marksRuntimeAllowed, isFalse);
      expect(service.invokesPermissionEngine, isFalse);
      expect(service.invokesApprovalEngine, isFalse);
      expect(service.invokesRuntimeGate, isFalse);
      expect(service.invokesEmergencyStop, isFalse);
      expect(service.writesBusinessData, isFalse);
      expect(service.persistsAvailabilityDecision, isFalse);
    });

    test('Phase 56/57/63 boundaries remain separate', () {
      expect(service.implementsPhase56ContentGeneration, isFalse);
      expect(service.implementsPhase57KnowledgeLibrary, isFalse);
      expect(service.implementsPhase63PrivacyUi, isFalse);
    });
  });
}
