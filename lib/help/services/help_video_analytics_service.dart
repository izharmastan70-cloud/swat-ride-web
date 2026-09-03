import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/help_video_tutorial_model.dart';

/// Privacy-safe SWAT RIDE Video Guide analytics.
///
/// Stored:
/// tutorial/content metadata + controlled quality signal.
///
/// Never stored:
/// user identity, phone, email, device ID, location,
/// search query, or free-text customer feedback.
class HelpVideoAnalyticsService {
  HelpVideoAnalyticsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'help_video_analytics_events';

  static const Set<String> notHelpfulReasons = <String>{
    'outdated',
    'unclear',
    'wrong_language',
    'did_not_solve',
    'missing_steps',
    'other',
  };

  final FirebaseFirestore _firestore;

  Future<void> recordVideoOpened({required HelpVideoTutorialModel tutorial}) {
    return _write(tutorial: tutorial, eventType: 'video_opened', reason: '');
  }

  Future<void> recordHelpfulness({
    required HelpVideoTutorialModel tutorial,
    required bool helpful,
    String reason = '',
  }) {
    if (helpful) {
      return _write(
        tutorial: tutorial,
        eventType: 'helpful',
        reason: 'helpful',
      );
    }

    final normalizedReason = reason.trim().toLowerCase();

    if (!notHelpfulReasons.contains(normalizedReason)) {
      throw ArgumentError('Controlled not-helpful reason required.');
    }

    return _write(
      tutorial: tutorial,
      eventType: 'not_helpful',
      reason: normalizedReason,
    );
  }

  Future<void> _write({
    required HelpVideoTutorialModel tutorial,
    required String eventType,
    required String reason,
  }) async {
    final tutorialId = tutorial.id.trim();

    if (tutorialId.isEmpty) {
      return;
    }

    await _firestore.collection(collectionName).add(<String, dynamic>{
      'tutorialId': tutorialId,
      'eventType': eventType,
      'reason': reason,
      'module': tutorial.module.trim(),
      'feature': tutorial.feature.trim(),
      'language': tutorial.language.trim(),
      'tutorialAppVersion': tutorial.appVersion.trim(),
      'videoVersion': tutorial.videoVersion.trim(),
      'source': 'video_guides',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
