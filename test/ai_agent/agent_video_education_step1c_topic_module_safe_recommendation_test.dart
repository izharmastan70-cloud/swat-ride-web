import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/help/constants/help_video_education_recommendation_constants.dart';
import 'package:swat_ride/help/models/help_video_education_recommendation_decision.dart';
import 'package:swat_ride/help/services/help_video_education_safe_recommendation_service.dart';

void main() {
  const HelpVideoEducationSafeRecommendationService service =
      HelpVideoEducationSafeRecommendationService();

  Map<String, Object> candidate({
    String tutorialId = 'ride_booking_urdu_v1',
    String title = 'Ride booking ka tareeqa',
    String module = 'ride',
    String feature = 'booking',
    String audience = 'customer',
    String language = 'ur',
    List<String> keywords = const <String>['ride', 'booking'],
    List<String> intents = const <String>['how_to_book_ride'],
  }) {
    return <String, Object>{
      'tutorialId': tutorialId,
      'title': title,
      'module': module,
      'feature': feature,
      'audience': audience,
      'language': language,
      'keywords': keywords,
      'intents': intents,
    };
  }

  HelpVideoEducationRecommendationDecision evaluate({
    Map<String, Object>? item,
    String requestedAudience = 'customer',
    String requestedLanguage = 'ur',
    String requestedModule = 'ride',
    String requestedFeature = 'booking',
    List<String> requestedIntents = const <String>['how_to_book_ride'],
  }) {
    final Map<String, Object> data = item ?? candidate();

    return service.evaluateCandidateMetadata(
      tutorialId: data['tutorialId']! as String,
      title: data['title']! as String,
      module: data['module']! as String,
      feature: data['feature']! as String,
      audience: data['audience']! as String,
      language: data['language']! as String,
      keywords: data['keywords']! as List<String>,
      intents: data['intents']! as List<String>,
      requestedAudience: requestedAudience,
      requestedLanguage: requestedLanguage,
      requestedModule: requestedModule,
      requestedFeature: requestedFeature,
      requestedIntents: requestedIntents,
    );
  }

  group('Phase 55 Step 1C safe video recommendation', () {
    test('exact module/feature/audience/language candidate is recommended', () {
      final decision = evaluate();

      expect(
        decision.status,
        HelpVideoEducationRecommendationStatus.recommended,
      );
      expect(decision.canRecommend, isTrue);
      expect(decision.matchedModule, isTrue);
      expect(decision.matchedFeature, isTrue);
    });

    test('intent-only context can safely match', () {
      final decision = evaluate(
        requestedModule: '',
        requestedFeature: '',
        requestedIntents: const <String>['how_to_book_ride'],
      );

      expect(decision.canRecommend, isTrue);
      expect(decision.intentMatchCount, 1);
    });

    test('keyword can satisfy requested intent/topic match', () {
      final decision = evaluate(
        requestedModule: '',
        requestedFeature: '',
        requestedIntents: const <String>['booking'],
      );

      expect(decision.canRecommend, isTrue);
      expect(decision.intentMatchCount, 1);
    });

    test('all-audience tutorial may serve customer request', () {
      final decision = evaluate(item: candidate(audience: 'all'));

      expect(decision.canRecommend, isTrue);
    });

    test('customer tutorial is blocked for driver audience', () {
      final decision = evaluate(requestedAudience: 'driver');

      expect(
        decision.status,
        HelpVideoEducationRecommendationStatus.blockedAudienceMismatch,
      );
      expect(decision.canRecommend, isFalse);
    });

    test('Urdu tutorial is blocked for Pashto request', () {
      final decision = evaluate(requestedLanguage: 'ps');

      expect(
        decision.status,
        HelpVideoEducationRecommendationStatus.blockedLanguageMismatch,
      );
    });

    test('unspecified candidate language allows safe fallback', () {
      final decision = evaluate(item: candidate(language: 'und'));

      expect(
        decision.status,
        HelpVideoEducationRecommendationStatus.recommendedLanguageFallback,
      );
      expect(decision.canRecommend, isTrue);
    });

    test('unspecified requested language allows safe fallback', () {
      final decision = evaluate(requestedLanguage: 'und');

      expect(
        decision.status,
        HelpVideoEducationRecommendationStatus.recommendedLanguageFallback,
      );
    });

    test('different module/feature/intents is blocked', () {
      final decision = evaluate(
        requestedModule: 'food',
        requestedFeature: 'checkout',
        requestedIntents: const <String>['pay_food_order'],
      );

      expect(
        decision.status,
        HelpVideoEducationRecommendationStatus.blockedContextMismatch,
      );
    });

    test('invalid/unsupported request audience fails safely', () {
      final decision = evaluate(requestedAudience: 'root_operator');

      expect(
        decision.status,
        HelpVideoEducationRecommendationStatus.blockedInvalidRequest,
      );
    });

    test('empty topic/module/feature request fails safely', () {
      final decision = evaluate(
        requestedModule: '',
        requestedFeature: '',
        requestedIntents: const <String>[],
      );

      expect(
        decision.status,
        HelpVideoEducationRecommendationStatus.blockedInvalidRequest,
      );
    });

    test('catalog-invalid candidate is blocked before recommendation', () {
      final decision = evaluate(item: candidate(title: ' '));

      expect(
        decision.status,
        HelpVideoEducationRecommendationStatus.blockedCatalog,
      );
    });

    test('recommendation decision is non-authoritative', () {
      final decision = evaluate();

      expect(decision.recommendationOnly, isTrue);
      expect(decision.executesTutorial, isFalse);
      expect(decision.opensExternalUrl, isFalse);
      expect(decision.generatesContent, isFalse);
      expect(decision.grantsAuthority, isFalse);
      expect(decision.grantsPermission, isFalse);
      expect(decision.consumesApproval, isFalse);
      expect(decision.marksRuntimeAllowed, isFalse);
      expect(decision.invokesProvider, isFalse);
      expect(decision.writesBusinessData, isFalse);
      expect(decision.persistsDecision, isFalse);
    });

    test('service reuses existing contextual matcher and adds safety only', () {
      expect(service.reusesExistingContextualVideoGuideService, isTrue);
      expect(service.implementsDuplicateScoringEngine, isFalse);
      expect(service.recommendationSafetyGateOnly, isTrue);
    });

    test('service cannot execute provider/gates/business actions', () {
      expect(service.executesTutorial, isFalse);
      expect(service.opensExternalUrl, isFalse);
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
      expect(service.persistsRecommendation, isFalse);
    });

    test('Phase 56/57/63 boundaries remain separate', () {
      expect(service.implementsPhase56ContentGeneration, isFalse);
      expect(service.implementsPhase57KnowledgeLibrary, isFalse);
      expect(service.implementsPhase63PrivacyUi, isFalse);
    });
  });
}
