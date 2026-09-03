import '../constants/agent_content_draft_package_constants.dart';

class AgentContentVideoScenePlan {
  const AgentContentVideoScenePlan({
    required this.order,
    required this.shotType,
    required this.visualSource,
    required this.objective,
    required this.voiceover,
    required this.onScreenText,
    required this.durationSeconds,
  });

  final int order;
  final String shotType;
  final String visualSource;
  final String objective;
  final String voiceover;
  final String onScreenText;
  final int durationSeconds;

  bool get planningOnly => true;
  bool get recordsVideo => false;
  bool get editsVideo => false;
  bool get uploadsMedia => false;
  bool get invokesProvider => false;

  void validateStructure() {
    if (order <= 0) {
      throw const AgentContentVideoScenePlanException(
        'Scene order is invalid.',
      );
    }

    if (!AgentContentShotType.values.contains(shotType)) {
      throw const AgentContentVideoScenePlanException(
        'Scene shot type is unsupported.',
      );
    }

    if (!AgentContentVisualSource.values.contains(visualSource)) {
      throw const AgentContentVideoScenePlanException(
        'Scene visual source is unsupported.',
      );
    }

    if (!_safeRequired(objective) ||
        !_safeOptional(voiceover) ||
        !_safeOptional(onScreenText)) {
      throw const AgentContentVideoScenePlanException('Scene text is invalid.');
    }

    if (durationSeconds <= 0 ||
        durationSeconds > AgentContentPackageLimits.sceneDurationSecondsMax) {
      throw const AgentContentVideoScenePlanException(
        'Scene duration is invalid.',
      );
    }
  }

  bool _safeRequired(String value) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= AgentContentPackageLimits.sceneTextMax &&
        !RegExp(r'[\u0000-\u001F]').hasMatch(trimmed);
  }

  bool _safeOptional(String value) {
    final String trimmed = value.trim();

    return trimmed.length <= AgentContentPackageLimits.sceneTextMax &&
        !RegExp(r'[\u0000-\u001F]').hasMatch(trimmed);
  }
}

class AgentContentVideoScenePlanException implements Exception {
  const AgentContentVideoScenePlanException(this.message);

  final String message;

  @override
  String toString() => 'AgentContentVideoScenePlanException: $message';
}
