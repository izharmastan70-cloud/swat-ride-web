class HelpVideoMaintenanceDraft {
  const HelpVideoMaintenanceDraft({
    required this.sourceTutorialId,
    required this.title,
    required this.module,
    required this.feature,
    required this.language,
    required this.audience,
    required this.targetAppVersion,
    required this.baseVideoVersion,
    required this.proposedVideoVersion,
    required this.changeSummary,
    required this.scriptDraft,
    required this.storyboardDraft,
    required this.scenePlanDraft,
    required this.narrationDraft,
    required this.captionDraft,
    required this.keywords,
    required this.intents,
    required this.maintenanceSource,
    required this.requiresApproval,
    required this.approvalStatus,
    required this.supersedesVideoId,
    required this.needsExtraReview,
    required this.extraReviewReasons,
    required this.automaticPublishAllowed,
  });

  final String sourceTutorialId;
  final String title;

  final String module;
  final String feature;
  final String language;
  final String audience;

  final String targetAppVersion;

  final String baseVideoVersion;
  final String proposedVideoVersion;

  final String changeSummary;

  /// Draft content only.
  ///
  /// Human/Super Admin review remains authoritative.
  final String scriptDraft;
  final String storyboardDraft;
  final String scenePlanDraft;
  final String narrationDraft;
  final String captionDraft;

  final List<String> keywords;
  final List<String> intents;

  /// Automatic change-detected drafts must use:
  /// agent_change_detection
  final String maintenanceSource;

  /// Must remain true until an authorized reviewer approves it.
  final bool requiresApproval;

  /// Initial automatic-draft state must be pending.
  final String approvalStatus;

  /// Version/archive relationship.
  final String supersedesVideoId;

  /// Payments, cancellation, privacy, Safety/SOS and similar content
  /// require additional human validation.
  final bool needsExtraReview;
  final List<String> extraReviewReasons;

  /// Permanent safety lock for generated maintenance drafts.
  final bool automaticPublishAllowed;

  bool get isPendingOwnerApproval =>
      requiresApproval && approvalStatus.trim().toLowerCase() == 'pending';

  bool get isSafeDraftContract =>
      maintenanceSource == 'agent_change_detection' &&
      isPendingOwnerApproval &&
      !automaticPublishAllowed;
}
