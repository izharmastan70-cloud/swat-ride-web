import '../models/help_video_tutorial_model.dart';
import 'help_video_version_awareness_service.dart';
import 'help_video_tutorial_service.dart';

/// Read-only Support Agent lookup for official SWAT RIDE video guides.
///
/// Only approved Video Library records can be recommended.
/// Random internet results are never treated as official SWAT RIDE tutorials.
class SupportAgentVideoGuideLookupService {
  SupportAgentVideoGuideLookupService({
    HelpVideoTutorialService? tutorialService,
    HelpVideoVersionAwarenessService? versionAwarenessService,
  }) : _tutorialService = tutorialService ?? HelpVideoTutorialService(),
       _versionAwarenessService =
           versionAwarenessService ?? const HelpVideoVersionAwarenessService();

  final HelpVideoTutorialService _tutorialService;
  final HelpVideoVersionAwarenessService _versionAwarenessService;

  Future<HelpVideoTutorialModel?> findBestApprovedGuide({
    required String userQuery,
    String module = '',
    String feature = '',
    String language = '',
    String currentAppVersion = '',
    Iterable<String> intents = const <String>[],
  }) async {
    final tutorials = await _tutorialService.watchEnabledTutorials().first;

    final safeTutorials = tutorials
        .where((tutorial) {
          if (!tutorial.isSafeForRecommendation) {
            return false;
          }

          if (currentAppVersion.trim().isEmpty) {
            return true;
          }

          final versionResult = _versionAwarenessService.evaluate(
            tutorial: tutorial,
            currentAppVersion: currentAppVersion,
          );

          return versionResult.isCompatible;
        })
        .toList(growable: false);

    if (safeTutorials.isEmpty) {
      return null;
    }

    final queryTokens = _tokens(userQuery);
    final requestedModule = _normalized(module);
    final requestedFeature = _normalized(feature);
    final requestedLanguage = _normalized(language);

    final requestedIntents = intents
        .map(_normalized)
        .where((value) => value.isNotEmpty)
        .toSet();

    final ranked = <_RankedGuide>[];

    for (final tutorial in safeTutorials) {
      final score = _score(
        tutorial: tutorial,
        queryTokens: queryTokens,
        requestedModule: requestedModule,
        requestedFeature: requestedFeature,
        requestedLanguage: requestedLanguage,
        requestedIntents: requestedIntents,
      );

      if (score > 0) {
        ranked.add(_RankedGuide(tutorial: tutorial, score: score));
      }
    }

    if (ranked.isEmpty) {
      return null;
    }

    ranked.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);

      if (scoreCompare != 0) {
        return scoreCompare;
      }

      final orderCompare = a.tutorial.displayOrder.compareTo(
        b.tutorial.displayOrder,
      );

      if (orderCompare != 0) {
        return orderCompare;
      }

      return a.tutorial.title.toLowerCase().compareTo(
        b.tutorial.title.toLowerCase(),
      );
    });

    return ranked.first.tutorial;
  }

  int _score({
    required HelpVideoTutorialModel tutorial,
    required Set<String> queryTokens,
    required String requestedModule,
    required String requestedFeature,
    required String requestedLanguage,
    required Set<String> requestedIntents,
  }) {
    var score = 0;

    final tutorialModule = _normalized(tutorial.module);

    final tutorialFeature = _normalized(tutorial.feature);

    final tutorialLanguage = _normalized(tutorial.language);

    final titleTokens = _tokens(tutorial.title);

    final descriptionTokens = _tokens(tutorial.description);

    final keywordTokens = tutorial.keywords.expand(_tokens).toSet();

    final tutorialIntents = tutorial.intents
        .map(_normalized)
        .where((value) => value.isNotEmpty)
        .toSet();

    if (requestedModule.isNotEmpty && tutorialModule == requestedModule) {
      score += 120;
    }

    if (requestedFeature.isNotEmpty && tutorialFeature == requestedFeature) {
      score += 160;
    }

    if (requestedLanguage.isNotEmpty && tutorialLanguage == requestedLanguage) {
      score += 35;
    }

    for (final intent in requestedIntents) {
      if (tutorialIntents.contains(intent)) {
        score += 70;
      }

      if (keywordTokens.contains(intent)) {
        score += 30;
      }
    }

    for (final token in queryTokens) {
      if (titleTokens.contains(token)) {
        score += 20;
      }

      if (descriptionTokens.contains(token)) {
        score += 8;
      }

      if (keywordTokens.contains(token)) {
        score += 16;
      }

      if (tutorialIntents.contains(token)) {
        score += 22;
      }

      if (tutorialModule == token) {
        score += 18;
      }

      if (tutorialFeature == token) {
        score += 24;
      }
    }

    return score;
  }

  Set<String> _tokens(String value) {
    return _normalized(
      value,
    ).split(RegExp(r'[^a-z0-9]+')).where((token) => token.length >= 2).toSet();
  }

  String _normalized(Object? value) {
    return value?.toString().trim().toLowerCase() ?? '';
  }
}

class _RankedGuide {
  const _RankedGuide({required this.tutorial, required this.score});

  final HelpVideoTutorialModel tutorial;
  final int score;
}
