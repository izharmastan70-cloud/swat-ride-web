import '../constants/help_video_education_availability_constants.dart';
import '../models/help_video_education_availability_decision.dart';
import '../models/help_video_education_recommendation_decision.dart';

class HelpVideoEducationAvailabilityPolicyService {
  const HelpVideoEducationAvailabilityPolicyService();

  HelpVideoEducationAvailabilityDecision evaluate({
    required String tutorialId,
    required HelpVideoEducationRecommendationDecision
    safeRecommendationDecision,
    required bool adminEnabled,
    required bool approvalVerified,
    required bool safeForRecommendation,
    required bool versionOutdated,
  }) {
    safeRecommendationDecision.validateStructure();

    if (!safeRecommendationDecision.canRecommend ||
        safeRecommendationDecision.tutorialId.trim() != tutorialId.trim()) {
      return _decision(
        status: HelpVideoEducationAvailabilityStatus.blockedRecommendation,
        tutorialId: _safeId(tutorialId),
        maintenanceReviewRequired: false,
        reasons: const <String>[
          HelpVideoEducationAvailabilityReason.existingAdminControlReused,
          HelpVideoEducationAvailabilityReason.existingVersionAwarenessReused,
          HelpVideoEducationAvailabilityReason
              .existingMaintenanceWorkflowReused,
          HelpVideoEducationAvailabilityReason.step1cRecommendationRequired,
          HelpVideoEducationAvailabilityReason.availabilityPolicyOnly,
          HelpVideoEducationAvailabilityReason.nonAuthoritativeContent,
        ],
      );
    }

    if (!adminEnabled) {
      return _decision(
        status: HelpVideoEducationAvailabilityStatus.blockedDisabled,
        tutorialId: tutorialId.trim(),
        maintenanceReviewRequired: false,
        reasons: const <String>[
          HelpVideoEducationAvailabilityReason.existingAdminControlReused,
          HelpVideoEducationAvailabilityReason.adminDisabled,
          HelpVideoEducationAvailabilityReason.availabilityPolicyOnly,
          HelpVideoEducationAvailabilityReason.nonAuthoritativeContent,
        ],
      );
    }

    if (!approvalVerified) {
      return _decision(
        status: HelpVideoEducationAvailabilityStatus.blockedUnapproved,
        tutorialId: tutorialId.trim(),
        maintenanceReviewRequired: false,
        reasons: const <String>[
          HelpVideoEducationAvailabilityReason.existingAdminControlReused,
          HelpVideoEducationAvailabilityReason.adminEnabled,
          HelpVideoEducationAvailabilityReason.approvalMissing,
          HelpVideoEducationAvailabilityReason.availabilityPolicyOnly,
          HelpVideoEducationAvailabilityReason.nonAuthoritativeContent,
        ],
      );
    }

    if (!safeForRecommendation) {
      return _decision(
        status: HelpVideoEducationAvailabilityStatus.blockedUnsafe,
        tutorialId: tutorialId.trim(),
        maintenanceReviewRequired: false,
        reasons: const <String>[
          HelpVideoEducationAvailabilityReason.existingAdminControlReused,
          HelpVideoEducationAvailabilityReason.adminEnabled,
          HelpVideoEducationAvailabilityReason.approvalVerified,
          HelpVideoEducationAvailabilityReason.recommendationSafetyBlocked,
          HelpVideoEducationAvailabilityReason.availabilityPolicyOnly,
          HelpVideoEducationAvailabilityReason.nonAuthoritativeContent,
        ],
      );
    }

    if (versionOutdated) {
      return _decision(
        status: HelpVideoEducationAvailabilityStatus.blockedOutdated,
        tutorialId: tutorialId.trim(),
        maintenanceReviewRequired: true,
        reasons: const <String>[
          HelpVideoEducationAvailabilityReason.existingVersionAwarenessReused,
          HelpVideoEducationAvailabilityReason
              .existingMaintenanceWorkflowReused,
          HelpVideoEducationAvailabilityReason.adminEnabled,
          HelpVideoEducationAvailabilityReason.approvalVerified,
          HelpVideoEducationAvailabilityReason.recommendationSafetyVerified,
          HelpVideoEducationAvailabilityReason.versionOutdated,
          HelpVideoEducationAvailabilityReason.maintenanceReviewRequired,
          HelpVideoEducationAvailabilityReason.availabilityPolicyOnly,
          HelpVideoEducationAvailabilityReason.nonAuthoritativeContent,
        ],
      );
    }

    return _decision(
      status: HelpVideoEducationAvailabilityStatus.available,
      tutorialId: tutorialId.trim(),
      maintenanceReviewRequired: false,
      reasons: const <String>[
        HelpVideoEducationAvailabilityReason.existingAdminControlReused,
        HelpVideoEducationAvailabilityReason.existingVersionAwarenessReused,
        HelpVideoEducationAvailabilityReason.adminEnabled,
        HelpVideoEducationAvailabilityReason.approvalVerified,
        HelpVideoEducationAvailabilityReason.recommendationSafetyVerified,
        HelpVideoEducationAvailabilityReason.versionCurrent,
        HelpVideoEducationAvailabilityReason.availabilityPolicyOnly,
        HelpVideoEducationAvailabilityReason.nonAuthoritativeContent,
      ],
    );
  }

  HelpVideoEducationAvailabilityDecision _decision({
    required String status,
    required String tutorialId,
    required bool maintenanceReviewRequired,
    required List<String> reasons,
  }) {
    final HelpVideoEducationAvailabilityDecision decision =
        HelpVideoEducationAvailabilityDecision(
          status: status,
          tutorialId: tutorialId,
          maintenanceReviewRequired: maintenanceReviewRequired,
          reasonCodes: reasons,
        );

    decision.validateStructure();
    return decision;
  }

  String _safeId(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'invalid_tutorial';
    }

    if (trimmed.length <= 180) {
      return trimmed;
    }

    return trimmed.substring(0, 180);
  }

  bool get reusesExistingAdminControl => true;
  bool get reusesExistingVersionAwareness => true;
  bool get reusesExistingMaintenanceWorkflow => true;
  bool get implementsDuplicateAdminWriteSystem => false;
  bool get availabilityPolicyOnly => true;
  bool get changesAdminState => false;
  bool get publishesTutorial => false;
  bool get disablesTutorial => false;
  bool get createsMaintenanceDraft => false;
  bool get autoOpensVideo => false;
  bool get generatesContent => false;
  bool get invokesProvider => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get writesBusinessData => false;
  bool get persistsAvailabilityDecision => false;
  bool get implementsPhase56ContentGeneration => false;
  bool get implementsPhase57KnowledgeLibrary => false;
  bool get implementsPhase63PrivacyUi => false;
}
