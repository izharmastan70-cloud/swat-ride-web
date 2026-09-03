import '../constants/help_video_education_availability_constants.dart';

class HelpVideoEducationAvailabilityDecision {
  HelpVideoEducationAvailabilityDecision({
    required this.status,
    required this.tutorialId,
    required this.maintenanceReviewRequired,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String tutorialId;
  final bool maintenanceReviewRequired;
  final List<String> reasonCodes;

  bool get canSurface =>
      status == HelpVideoEducationAvailabilityStatus.available;

  bool get availabilityPolicyOnly => true;
  bool get changesAdminState => false;
  bool get publishesTutorial => false;
  bool get disablesTutorial => false;
  bool get createsMaintenanceDraft => false;
  bool get autoOpensVideo => false;
  bool get generatesContent => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;
  bool get persistsDecision => false;

  void validateStructure() {
    if (!HelpVideoEducationAvailabilityStatus.values.contains(status)) {
      throw const HelpVideoEducationAvailabilityDecisionException(
        'Video education availability status is invalid.',
      );
    }

    if (tutorialId.trim().isEmpty || tutorialId.length > 180) {
      throw const HelpVideoEducationAvailabilityDecisionException(
        'Video education availability tutorial ID is invalid.',
      );
    }

    if (reasonCodes.isEmpty || reasonCodes.length > 10) {
      throw const HelpVideoEducationAvailabilityDecisionException(
        'Video education availability reason codes are invalid.',
      );
    }

    for (final String reason in reasonCodes) {
      if (!HelpVideoEducationAvailabilityReason.values.contains(reason)) {
        throw const HelpVideoEducationAvailabilityDecisionException(
          'Video education availability reason code is invalid.',
        );
      }
    }

    if (status == HelpVideoEducationAvailabilityStatus.blockedOutdated &&
        !maintenanceReviewRequired) {
      throw const HelpVideoEducationAvailabilityDecisionException(
        'Outdated tutorial must require maintenance review.',
      );
    }

    if (canSurface && maintenanceReviewRequired) {
      throw const HelpVideoEducationAvailabilityDecisionException(
        'Available tutorial cannot require maintenance review.',
      );
    }
  }
}

class HelpVideoEducationAvailabilityDecisionException implements Exception {
  const HelpVideoEducationAvailabilityDecisionException(this.message);

  final String message;

  @override
  String toString() =>
      'HelpVideoEducationAvailabilityDecisionException: $message';
}
