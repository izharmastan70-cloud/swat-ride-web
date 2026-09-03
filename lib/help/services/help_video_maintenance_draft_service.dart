import '../models/help_video_maintenance_draft.dart';
import '../models/help_video_tutorial_model.dart';
import 'help_video_version_awareness_service.dart';

/// Creates an approval-required tutorial maintenance draft.
///
/// This service:
/// - does not write to Firestore;
/// - does not publish tutorials;
/// - does not replace the approved tutorial;
/// - does not use random internet content;
/// - converts an already detected app/tutorial mismatch into a structured
///   draft package for later Owner/Super Admin review.
class HelpVideoMaintenanceDraftService {
  const HelpVideoMaintenanceDraftService();

  HelpVideoMaintenanceDraft buildVersionMismatchDraft({
    required String sourceTutorialId,
    required HelpVideoTutorialModel tutorial,
    required HelpVideoVersionAwarenessResult versionResult,
    required String targetAppVersion,
    required String changeSummary,
    String approvedKnowledgeSummary = '',
  }) {
    final normalizedSourceId = sourceTutorialId.trim();
    final normalizedTargetVersion = targetAppVersion.trim();
    final normalizedChangeSummary = changeSummary.trim();
    final normalizedKnowledge = approvedKnowledgeSummary.trim();

    if (normalizedSourceId.isEmpty) {
      throw ArgumentError('Source tutorial ID is required.');
    }

    if (!versionResult.shouldCreateUpdateTask) {
      throw StateError(
        'A maintenance draft may only be created after a review/mismatch signal.',
      );
    }

    if (normalizedTargetVersion.isEmpty) {
      throw ArgumentError('Target app version is required.');
    }

    if (normalizedChangeSummary.isEmpty) {
      throw ArgumentError('Change summary is required.');
    }

    final risk = _detectExtraReview(
      tutorial: tutorial,
      changeSummary: normalizedChangeSummary,
    );

    final approvedContext = normalizedKnowledge.isEmpty
        ? 'No approved knowledge summary attached yet. Human review must '
              'supply verified product facts before publication.'
        : normalizedKnowledge;

    final proposedVideoVersion = _nextVideoVersion(tutorial.videoVersion);

    return HelpVideoMaintenanceDraft(
      sourceTutorialId: normalizedSourceId,
      title: tutorial.title,
      module: tutorial.module,
      feature: tutorial.feature,
      language: tutorial.language,
      audience: tutorial.audience,
      targetAppVersion: normalizedTargetVersion,
      baseVideoVersion: tutorial.videoVersion,
      proposedVideoVersion: proposedVideoVersion,
      changeSummary: normalizedChangeSummary,
      scriptDraft: _scriptScaffold(
        title: tutorial.title,
        changeSummary: normalizedChangeSummary,
        approvedKnowledge: approvedContext,
      ),
      storyboardDraft: _storyboardScaffold(
        changeSummary: normalizedChangeSummary,
      ),
      scenePlanDraft: _sceneScaffold(
        module: tutorial.module,
        feature: tutorial.feature,
      ),
      narrationDraft: _narrationScaffold(
        language: tutorial.language,
        approvedKnowledge: approvedContext,
      ),
      captionDraft: _captionScaffold(language: tutorial.language),
      keywords: List<String>.unmodifiable(tutorial.keywords),
      intents: List<String>.unmodifiable(tutorial.intents),
      maintenanceSource: 'agent_change_detection',
      requiresApproval: true,
      approvalStatus: 'pending',
      supersedesVideoId: normalizedSourceId,
      needsExtraReview: risk.isNotEmpty,
      extraReviewReasons: List<String>.unmodifiable(risk),
      automaticPublishAllowed: false,
    );
  }

  String _nextVideoVersion(String current) {
    final normalized = current.trim();

    final parsed = int.tryParse(normalized);

    if (parsed != null && parsed >= 0) {
      return '${parsed + 1}';
    }

    if (normalized.isEmpty) {
      return '1';
    }

    return '$normalized.1';
  }

  List<String> _detectExtraReview({
    required HelpVideoTutorialModel tutorial,
    required String changeSummary,
  }) {
    final text = <String>[
      tutorial.module,
      tutorial.feature,
      tutorial.title,
      changeSummary,
      ...tutorial.keywords,
      ...tutorial.intents,
    ].join(' ').toLowerCase();

    final reasons = <String>[];

    void flag(String value, String reason) {
      if (text.contains(value) && !reasons.contains(reason)) {
        reasons.add(reason);
      }
    }

    flag('payment', 'financial_or_payment_content');
    flag('refund', 'financial_or_payment_content');
    flag('wallet', 'financial_or_payment_content');
    flag('easypaisa', 'financial_or_payment_content');
    flag('jazzcash', 'financial_or_payment_content');

    flag('cancel', 'cancellation_policy_content');

    flag('privacy', 'privacy_content');
    flag('retention', 'privacy_content');

    flag('safety', 'safety_or_emergency_content');
    flag('sos', 'safety_or_emergency_content');
    flag('emergency', 'safety_or_emergency_content');

    return reasons;
  }

  String _scriptScaffold({
    required String title,
    required String changeSummary,
    required String approvedKnowledge,
  }) {
    return '''
DRAFT ONLY - HUMAN APPROVAL REQUIRED

Tutorial: $title

Detected change:
$changeSummary

Approved knowledge basis:
$approvedKnowledge

Required script structure:
1. Explain what changed.
2. Show only verified current SWAT RIDE UI/actions.
3. Do not invent prices, payment rules, cancellation rules, safety behavior,
   account state, booking state or unsupported functionality.
4. End with the correct user action or text fallback.
''';
  }

  String _storyboardScaffold({required String changeSummary}) {
    return '''
DRAFT STORYBOARD
- Before/entry state
- Changed screen or feature
- Correct user action
- Success/result state
- Text fallback/help path

Change focus:
$changeSummary
''';
  }

  String _sceneScaffold({required String module, required String feature}) {
    return '''
DRAFT SCENES
Module: $module
Feature: $feature

Use demo/fake data only.
No real customer, CNIC, payment credential, API key or private admin data.
''';
  }

  String _narrationScaffold({
    required String language,
    required String approvedKnowledge,
  }) {
    return '''
DRAFT NARRATION
Language: $language

Narration must stay aligned with approved knowledge:
$approvedKnowledge
''';
  }

  String _captionScaffold({required String language}) {
    return '''
DRAFT CAPTIONS
Language: $language
Captions must match final approved narration exactly.
''';
  }
}
