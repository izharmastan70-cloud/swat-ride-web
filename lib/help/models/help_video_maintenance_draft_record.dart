import 'package:cloud_firestore/cloud_firestore.dart';

class HelpVideoMaintenanceDraftRecord {
  const HelpVideoMaintenanceDraftRecord({
    required this.id,
    required this.sourceTutorialId,
    required this.title,
    required this.module,
    required this.feature,
    required this.targetAppVersion,
    required this.baseVideoVersion,
    required this.proposedVideoVersion,
    required this.changeSummary,
    required this.reviewStatus,
    required this.needsExtraReview,
    required this.extraReviewReasons,
    required this.automaticPublishAllowed,
    required this.reviewedBy,
    required this.rejectionReason,
    this.createdAt,
    this.reviewedAt,
  });

  final String id;
  final String sourceTutorialId;
  final String title;
  final String module;
  final String feature;
  final String targetAppVersion;
  final String baseVideoVersion;
  final String proposedVideoVersion;
  final String changeSummary;

  final String reviewStatus;

  final bool needsExtraReview;
  final List<String> extraReviewReasons;
  final bool automaticPublishAllowed;

  final String reviewedBy;
  final String rejectionReason;

  final DateTime? createdAt;
  final DateTime? reviewedAt;

  bool get isPending => reviewStatus.trim().toLowerCase() == 'pending';

  factory HelpVideoMaintenanceDraftRecord.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    return HelpVideoMaintenanceDraftRecord(
      id: document.id,
      sourceTutorialId: _s(data['sourceTutorialId']),
      title: _s(data['title']),
      module: _s(data['module']),
      feature: _s(data['feature']),
      targetAppVersion: _s(data['targetAppVersion']),
      baseVideoVersion: _s(data['baseVideoVersion']),
      proposedVideoVersion: _s(data['proposedVideoVersion']),
      changeSummary: _s(data['changeSummary']),
      reviewStatus: _s(data['reviewStatus']),
      needsExtraReview: data['needsExtraReview'] == true,
      extraReviewReasons: _list(data['extraReviewReasons']),
      automaticPublishAllowed: data['automaticPublishAllowed'] == true,
      reviewedBy: _s(data['reviewedBy']),
      rejectionReason: _s(data['rejectionReason']),
      createdAt: _date(data['createdAt']),
      reviewedAt: _date(data['reviewedAt']),
    );
  }

  static String _s(Object? value) => value?.toString().trim() ?? '';

  static List<String> _list(Object? value) {
    if (value is! Iterable) {
      return const <String>[];
    }

    return List<String>.unmodifiable(
      value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
