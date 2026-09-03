import '../models/help_video_tutorial_model.dart';
import 'help_video_tutorial_service.dart';

class ContextualVideoGuideService {
  ContextualVideoGuideService({HelpVideoTutorialService? tutorialService})
    : _tutorialService = tutorialService ?? HelpVideoTutorialService();

  final HelpVideoTutorialService _tutorialService;

  Stream<HelpVideoTutorialModel?> watchBestGuide({
    required String module,
    required String feature,
    List<String> intents = const <String>[],
  }) {
    final String normalizedModule = _normalize(module);

    final String normalizedFeature = _normalize(feature);

    final Set<String> normalizedIntents = intents
        .map(_normalize)
        .where((String value) => value.isNotEmpty)
        .toSet();

    return _tutorialService.watchEnabledTutorials().map((
      List<HelpVideoTutorialModel> tutorials,
    ) {
      final List<_ScoredGuide> matches = <_ScoredGuide>[];

      for (final HelpVideoTutorialModel tutorial in tutorials) {
        final int score = _scoreTutorial(
          tutorial: tutorial,
          module: normalizedModule,
          feature: normalizedFeature,
          intents: normalizedIntents,
        );

        if (score <= 0) {
          continue;
        }

        matches.add(_ScoredGuide(tutorial: tutorial, score: score));
      }

      if (matches.isEmpty) {
        return null;
      }

      matches.sort((_ScoredGuide first, _ScoredGuide second) {
        final int scoreCompare = second.score.compareTo(first.score);

        if (scoreCompare != 0) {
          return scoreCompare;
        }

        final int orderCompare = first.tutorial.displayOrder.compareTo(
          second.tutorial.displayOrder,
        );

        if (orderCompare != 0) {
          return orderCompare;
        }

        return first.tutorial.title.toLowerCase().compareTo(
          second.tutorial.title.toLowerCase(),
        );
      });

      return matches.first.tutorial;
    });
  }

  bool isSafeVideoUrl(String value) {
    return _tutorialService.isSafeVideoUrl(value);
  }

  int _scoreTutorial({
    required HelpVideoTutorialModel tutorial,
    required String module,
    required String feature,
    required Set<String> intents,
  }) {
    final String tutorialModule = _normalize(tutorial.module);

    final String tutorialCategory = _normalize(tutorial.category);

    final String tutorialFeature = _normalize(tutorial.feature);

    final Set<String> tutorialIntents = tutorial.intents
        .map(_normalize)
        .where((String value) => value.isNotEmpty)
        .toSet();

    final Set<String> tutorialKeywords = tutorial.keywords
        .map(_normalize)
        .where((String value) => value.isNotEmpty)
        .toSet();

    bool hasContextMatch = false;
    int score = 0;

    if (module.isNotEmpty && tutorialModule == module) {
      score += 100;
      hasContextMatch = true;
    }

    if (module.isNotEmpty && tutorialCategory == module) {
      score += 70;
      hasContextMatch = true;
    }

    if (feature.isNotEmpty && tutorialFeature == feature) {
      score += 140;
      hasContextMatch = true;
    }

    if (feature.isNotEmpty && tutorialKeywords.contains(feature)) {
      score += 45;
      hasContextMatch = true;
    }

    if (feature.isNotEmpty && tutorialIntents.contains(feature)) {
      score += 55;
      hasContextMatch = true;
    }

    if (intents.isNotEmpty) {
      final int intentMatches = tutorialIntents.intersection(intents).length;

      final int keywordMatches = tutorialKeywords.intersection(intents).length;

      if (intentMatches > 0 || keywordMatches > 0) {
        hasContextMatch = true;

        score += intentMatches * 40;
        score += keywordMatches * 25;
      }
    }

    if (!hasContextMatch) {
      return 0;
    }

    return score;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
  }
}

class _ScoredGuide {
  const _ScoredGuide({required this.tutorial, required this.score});

  final HelpVideoTutorialModel tutorial;
  final int score;
}
