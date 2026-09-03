import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/help/constants/help_video_education_contract_constants.dart';
import 'package:swat_ride/help/services/help_video_education_catalog_contract_service.dart';

void main() {
  const HelpVideoEducationCatalogContractService service =
      HelpVideoEducationCatalogContractService();

  group('Phase 55 Step 1B catalog/audience/language contract', () {
    test('Urdu customer tutorial metadata is eligible', () {
      final decision = service.evaluateMetadata(
        tutorialId: 'ride_booking_urdu_v1',
        title: 'Ride booking ka tareeqa',
        module: 'ride',
        feature: 'booking',
        audience: 'customer',
        language: 'Urdu',
        keywords: const <String>['ride', 'booking'],
        intents: const <String>['how_to_book_ride'],
      );

      expect(decision.status, HelpVideoEducationCatalogStatus.eligible);
      expect(decision.normalizedLanguage, HelpVideoEducationLanguage.urdu);
      expect(decision.normalizedAudience, HelpVideoEducationAudience.customer);
      expect(decision.catalogEligible, isTrue);
    });

    test('Pashto alias normalizes to ps', () {
      final decision = service.evaluateMetadata(
        tutorialId: 'safety_pashto_v1',
        title: 'Safety guide',
        module: 'safety',
        feature: 'sos',
        audience: 'driver',
        language: 'Pashto',
        keywords: const <String>['sos'],
        intents: const <String>['use_sos'],
      );

      expect(decision.normalizedLanguage, HelpVideoEducationLanguage.pashto);
      expect(decision.catalogEligible, isTrue);
    });

    test('English alias normalizes to en', () {
      final decision = service.evaluateMetadata(
        tutorialId: 'food_partner_en_v1',
        title: 'Manage food orders',
        module: 'food',
        feature: 'orders',
        audience: 'restaurant_partner',
        language: 'English',
        keywords: const <String>['food', 'orders'],
        intents: const <String>['manage_order'],
      );

      expect(decision.normalizedLanguage, HelpVideoEducationLanguage.english);
      expect(decision.catalogEligible, isTrue);
    });

    test('rider alias maps to customer', () {
      expect(
        service.normalizeAudience('rider'),
        HelpVideoEducationAudience.customer,
      );
    });

    test('hotel owner alias maps to hotel partner', () {
      expect(
        service.normalizeAudience('hotel-owner'),
        HelpVideoEducationAudience.hotelPartner,
      );
    });

    test('unspecified language remains eligible with fallback', () {
      final decision = service.evaluateMetadata(
        tutorialId: 'general_help_v1',
        title: 'General help',
        module: 'general',
        feature: 'help',
        audience: 'all',
        language: '',
        keywords: const <String>[],
        intents: const <String>[],
      );

      expect(
        decision.status,
        HelpVideoEducationCatalogStatus.eligibleLanguageFallback,
      );
      expect(decision.requiresLanguageFallback, isTrue);
    });

    test('unsupported audience is blocked', () {
      final decision = service.evaluateMetadata(
        tutorialId: 'unknown_audience_v1',
        title: 'Unknown audience',
        module: 'ride',
        feature: 'booking',
        audience: 'root_operator',
        language: 'ur',
        keywords: const <String>[],
        intents: const <String>[],
      );

      expect(
        decision.status,
        HelpVideoEducationCatalogStatus.blockedUnsupportedAudience,
      );
      expect(decision.catalogEligible, isFalse);
    });

    test('unsupported language is blocked', () {
      final decision = service.evaluateMetadata(
        tutorialId: 'unsupported_language_v1',
        title: 'Unsupported language',
        module: 'ride',
        feature: 'booking',
        audience: 'customer',
        language: 'xx',
        keywords: const <String>[],
        intents: const <String>[],
      );

      expect(
        decision.status,
        HelpVideoEducationCatalogStatus.blockedUnsupportedLanguage,
      );
    });

    test('missing required title is blocked', () {
      final decision = service.evaluateMetadata(
        tutorialId: 'missing_title_v1',
        title: ' ',
        module: 'ride',
        feature: 'booking',
        audience: 'customer',
        language: 'ur',
        keywords: const <String>[],
        intents: const <String>[],
      );

      expect(
        decision.status,
        HelpVideoEducationCatalogStatus.blockedInvalidMetadata,
      );
    });

    test('keywords/intents are bounded to 24 entries', () {
      final decision = service.evaluateMetadata(
        tutorialId: 'too_many_terms_v1',
        title: 'Too many terms',
        module: 'ride',
        feature: 'booking',
        audience: 'customer',
        language: 'ur',
        keywords: List<String>.generate(25, (int i) => 'keyword_$i'),
        intents: const <String>[],
      );

      expect(
        decision.status,
        HelpVideoEducationCatalogStatus.blockedInvalidMetadata,
      );
    });

    test('catalog decision never performs recommendation ranking', () {
      final decision = service.evaluateMetadata(
        tutorialId: 'catalog_only_v1',
        title: 'Catalog only',
        module: 'ride',
        feature: 'booking',
        audience: 'customer',
        language: 'ur',
        keywords: const <String>[],
        intents: const <String>[],
      );

      expect(decision.catalogMetadataOnly, isTrue);
      expect(decision.performsRecommendationRanking, isFalse);
      expect(decision.generatesContent, isFalse);
      expect(decision.grantsAuthority, isFalse);
      expect(decision.writesBusinessData, isFalse);
      expect(decision.persistsDecision, isFalse);
    });

    test('service reuses existing tutorial model and avoids duplication', () {
      expect(service.reusesExistingTutorialModel, isTrue);
      expect(service.createsDuplicateVideoItemModel, isFalse);
      expect(service.catalogMetadataOnly, isTrue);
      expect(service.performsRecommendationRanking, isFalse);
      expect(service.generatesContent, isFalse);
    });

    test('service cannot invoke authoritative controls or provider', () {
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
      expect(service.persistsCatalogDecision, isFalse);
    });

    test('Phase 56/57/63 boundaries remain separate', () {
      expect(service.implementsPhase56ContentGeneration, isFalse);
      expect(service.implementsPhase57KnowledgeLibrary, isFalse);
      expect(service.implementsPhase63PrivacyUi, isFalse);
    });
  });
}
