import 'package:cloud_firestore/cloud_firestore.dart';

class SuperAdminVideoAnalyticsSummary {
  const SuperAdminVideoAnalyticsSummary({
    required this.totalEvents,
    required this.videoOpened,
    required this.helpful,
    required this.notHelpful,
    required this.notHelpfulReasons,
  });

  final int totalEvents;
  final int videoOpened;
  final int helpful;
  final int notHelpful;

  final Map<String, int> notHelpfulReasons;

  double get helpfulRate {
    final responses = helpful + notHelpful;

    if (responses == 0) {
      return 0;
    }

    return helpful / responses;
  }
}

class SuperAdminVideoAnalyticsService {
  SuperAdminVideoAnalyticsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<SuperAdminVideoAnalyticsSummary> watchSummary() {
    return _firestore
        .collection('help_video_analytics_events')
        .orderBy('createdAt', descending: true)
        .limit(1000)
        .snapshots()
        .map((snapshot) {
          int videoOpened = 0;
          int helpful = 0;
          int notHelpful = 0;

          final notHelpfulReasons = <String, int>{};

          for (final document in snapshot.docs) {
            final data = document.data();

            final eventType =
                data['eventType']?.toString().trim().toLowerCase() ?? '';

            final reason =
                data['reason']?.toString().trim().toLowerCase() ?? '';

            switch (eventType) {
              case 'video_opened':
                videoOpened++;
                break;

              case 'helpful':
                helpful++;
                break;

              case 'not_helpful':
                notHelpful++;

                if (reason.isNotEmpty) {
                  notHelpfulReasons[reason] =
                      (notHelpfulReasons[reason] ?? 0) + 1;
                }

                break;
            }
          }

          return SuperAdminVideoAnalyticsSummary(
            totalEvents: snapshot.docs.length,
            videoOpened: videoOpened,
            helpful: helpful,
            notHelpful: notHelpful,
            notHelpfulReasons: Map<String, int>.unmodifiable(notHelpfulReasons),
          );
        });
  }
}
