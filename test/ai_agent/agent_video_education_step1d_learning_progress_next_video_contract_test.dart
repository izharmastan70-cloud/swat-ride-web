import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/help/constants/help_video_education_progress_constants.dart';
import 'package:swat_ride/help/constants/help_video_education_recommendation_constants.dart';
import 'package:swat_ride/help/models/help_video_education_recommendation_decision.dart';
import 'package:swat_ride/help/models/help_video_learning_progress.dart';
import 'package:swat_ride/help/services/help_video_learning_progress_contract_service.dart';

void main() {
  const HelpVideoLearningProgressContractService service =
      HelpVideoLearningProgressContractService();

  HelpVideoEducationRecommendationDecision safeCandidate({
    String tutorialId = 'ride_next_v1',
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

  group('Phase 55 Step 1D learning progress/next-video contract', () {
    test('zero watch builds NOT_STARTED', () {
      final progress = service.buildProgress(
        tutorialId: 'ride_intro_v1',
        watchedSeconds: 0,
        durationSeconds: 120,
        completionConfirmed: false,
        updatedAt: DateTime.utc(2026, 8, 19, 13),
      );

      expect(progress.status, HelpVideoLearningProgressStatus.notStarted);
      expect(progress.progressPercent, 0);
    });

    test('partial watch builds IN_PROGRESS', () {
      final progress = service.buildProgress(
        tutorialId: 'ride_intro_v1',
        watchedSeconds: 60,
        durationSeconds: 120,
        completionConfirmed: false,
        updatedAt: DateTime.utc(2026, 8, 19, 13),
      );

      expect(progress.status, HelpVideoLearningProgressStatus.inProgress);
      expect(progress.progressPercent, 50);
    });

    test('explicit confirmation builds COMPLETED', () {
      final progress = service.buildProgress(
        tutorialId: 'ride_intro_v1',
        watchedSeconds: 120,
        durationSeconds: 120,
        completionConfirmed: true,
        updatedAt: DateTime.utc(2026, 8, 19, 13),
      );

      expect(progress.status, HelpVideoLearningProgressStatus.completed);
      expect(progress.isCompleted, isTrue);
    });

    test('watch duration cannot exceed tutorial duration', () {
      expect(
        () => service.buildProgress(
          tutorialId: 'ride_intro_v1',
          watchedSeconds: 121,
          durationSeconds: 120,
          completionConfirmed: false,
          updatedAt: DateTime.utc(2026, 8, 19, 13),
        ),
        throwsA(isA<HelpVideoLearningProgressException>()),
      );
    });

    test('completion cannot be inferred without explicit confirmation', () {
      expect(
        () => service.buildProgress(
          tutorialId: 'ride_intro_v1',
          watchedSeconds: 120,
          durationSeconds: 120,
          completionConfirmed: false,
          updatedAt: DateTime.utc(2026, 8, 19, 13),
        ),
        throwsA(isA<HelpVideoLearningProgressException>()),
      );
    });

    test('NOT_STARTED resumes current video', () {
      final progress = service.buildProgress(
        tutorialId: 'ride_intro_v1',
        watchedSeconds: 0,
        durationSeconds: 120,
        completionConfirmed: false,
        updatedAt: DateTime.utc(2026, 8, 19, 13),
      );

      final decision = service.evaluateNextVideo(
        currentProgress: progress,
        safeCandidateDecision: safeCandidate(),
      );

      expect(decision.status, HelpVideoNextRecommendationStatus.resumeCurrent);
      expect(decision.shouldResumeCurrent, isTrue);
      expect(decision.canRecommendNext, isFalse);
    });

    test('IN_PROGRESS resumes current video', () {
      final progress = service.buildProgress(
        tutorialId: 'ride_intro_v1',
        watchedSeconds: 45,
        durationSeconds: 120,
        completionConfirmed: false,
        updatedAt: DateTime.utc(2026, 8, 19, 13),
      );

      final decision = service.evaluateNextVideo(
        currentProgress: progress,
        safeCandidateDecision: safeCandidate(),
      );

      expect(decision.status, HelpVideoNextRecommendationStatus.resumeCurrent);
    });

    test('COMPLETED + safe different candidate recommends next', () {
      final progress = service.buildProgress(
        tutorialId: 'ride_intro_v1',
        watchedSeconds: 120,
        durationSeconds: 120,
        completionConfirmed: true,
        updatedAt: DateTime.utc(2026, 8, 19, 13),
      );

      final decision = service.evaluateNextVideo(
        currentProgress: progress,
        safeCandidateDecision: safeCandidate(tutorialId: 'ride_next_v1'),
      );

      expect(decision.status, HelpVideoNextRecommendationStatus.recommendNext);
      expect(decision.canRecommendNext, isTrue);
      expect(decision.candidateTutorialId, 'ride_next_v1');
    });

    test('COMPLETED + same tutorial does not loop as next', () {
      final progress = service.buildProgress(
        tutorialId: 'ride_intro_v1',
        watchedSeconds: 120,
        durationSeconds: 120,
        completionConfirmed: true,
        updatedAt: DateTime.utc(2026, 8, 19, 13),
      );

      final decision = service.evaluateNextVideo(
        currentProgress: progress,
        safeCandidateDecision: safeCandidate(tutorialId: 'ride_intro_v1'),
      );

      expect(decision.status, HelpVideoNextRecommendationStatus.noNextRequired);
    });

    test('unsafe Step 1C candidate is blocked', () {
      final progress = service.buildProgress(
        tutorialId: 'ride_intro_v1',
        watchedSeconds: 120,
        durationSeconds: 120,
        completionConfirmed: true,
        updatedAt: DateTime.utc(2026, 8, 19, 13),
      );

      final decision = service.evaluateNextVideo(
        currentProgress: progress,
        safeCandidateDecision: safeCandidate(
          status: HelpVideoEducationRecommendationStatus.blockedContextMismatch,
        ),
      );

      expect(
        decision.status,
        HelpVideoNextRecommendationStatus.blockedUnsafeCandidate,
      );
    });

    test('progress safe map contains metadata only', () {
      final progress = service.buildProgress(
        tutorialId: 'ride_intro_v1',
        watchedSeconds: 60,
        durationSeconds: 120,
        completionConfirmed: false,
        updatedAt: DateTime.utc(2026, 8, 19, 13),
      );

      final map = progress.toSafeMap();

      expect(map['progressMetadataOnly'], isTrue);
      expect(map['grantsAuthority'], isFalse);
      expect(map['writesBusinessData'], isFalse);
      expect(map['persistsProgress'], isFalse);
    });

    test('next-video decision cannot auto-open or auto-complete', () {
      final progress = service.buildProgress(
        tutorialId: 'ride_intro_v1',
        watchedSeconds: 120,
        durationSeconds: 120,
        completionConfirmed: true,
        updatedAt: DateTime.utc(2026, 8, 19, 13),
      );

      final decision = service.evaluateNextVideo(
        currentProgress: progress,
        safeCandidateDecision: safeCandidate(),
      );

      expect(decision.recommendationOnly, isTrue);
      expect(decision.autoOpensVideo, isFalse);
      expect(decision.autoMarksComplete, isFalse);
      expect(decision.generatesContent, isFalse);
      expect(decision.grantsAuthority, isFalse);
      expect(decision.invokesProvider, isFalse);
      expect(decision.writesBusinessData, isFalse);
      expect(decision.persistsDecision, isFalse);
    });

    test('service reuses Step 1C safe recommendation', () {
      expect(service.reusesStep1CSafeRecommendation, isTrue);
      expect(service.implementsDuplicateRankingEngine, isFalse);
      expect(service.progressContractOnly, isTrue);
      expect(service.completionRequiresExplicitConfirmation, isTrue);
    });

    test('service cannot execute authoritative/provider/business actions', () {
      expect(service.autoMarksComplete, isFalse);
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
      expect(service.persistsLearningProgress, isFalse);
      expect(service.persistsNextRecommendation, isFalse);
    });

    test('Phase 56/57/63 boundaries remain separate', () {
      expect(service.implementsPhase56ContentGeneration, isFalse);
      expect(service.implementsPhase57KnowledgeLibrary, isFalse);
      expect(service.implementsPhase63PrivacyUi, isFalse);
    });
  });
}
