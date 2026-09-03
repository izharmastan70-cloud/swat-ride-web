import 'package:cloud_firestore/cloud_firestore.dart';

class HelpVideoChapterMarker {
  const HelpVideoChapterMarker({
    required this.title,
    required this.startSeconds,
    required this.endSeconds,
    required this.deepLinkPath,
  });

  final String title;
  final int startSeconds;

  /// Zero means no explicit end marker.
  final int endSeconds;

  /// Optional internal SWAT RIDE path.
  ///
  /// Example:
  /// /ride/booking
  ///
  /// This metadata layer does not blindly execute unknown routes.
  final String deepLinkPath;

  factory HelpVideoChapterMarker.fromMap(Map<String, dynamic> map) {
    return HelpVideoChapterMarker(
      title: map['title']?.toString().trim() ?? '',
      startSeconds: _nonNegativeInt(map['startSeconds']),
      endSeconds: _nonNegativeInt(map['endSeconds']),
      deepLinkPath: map['deepLinkPath']?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title.trim(),
      'startSeconds': startSeconds,
      'endSeconds': endSeconds,
      'deepLinkPath': deepLinkPath.trim(),
    };
  }

  static int _nonNegativeInt(Object? value) {
    if (value is int) {
      return value < 0 ? 0 : value;
    }

    final parsed = int.tryParse(value?.toString() ?? '');

    if (parsed == null || parsed < 0) {
      return 0;
    }

    return parsed;
  }
}

class HelpVideoNavigationMetadata {
  const HelpVideoNavigationMetadata({
    required this.tutorialId,
    required this.deepLinkPath,
    required this.chapters,
    required this.isEnabled,
    this.createdAt,
    this.updatedAt,
  });

  final String tutorialId;

  /// Optional top-level internal app path related to the tutorial.
  final String deepLinkPath;

  final List<HelpVideoChapterMarker> chapters;

  /// Allows Super Admin to temporarily hide navigation metadata
  /// without deleting tutorial history.
  final bool isEnabled;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory HelpVideoNavigationMetadata.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    final rawChapters = data['chapters'];

    final chapters = <HelpVideoChapterMarker>[];

    if (rawChapters is Iterable) {
      for (final raw in rawChapters) {
        if (raw is Map) {
          final map = raw.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          );

          chapters.add(HelpVideoChapterMarker.fromMap(map));
        }
      }
    }

    chapters.sort(
      (first, second) => first.startSeconds.compareTo(second.startSeconds),
    );

    return HelpVideoNavigationMetadata(
      tutorialId: data['tutorialId']?.toString().trim() ?? document.id,
      deepLinkPath: data['deepLinkPath']?.toString().trim() ?? '',
      chapters: List<HelpVideoChapterMarker>.unmodifiable(chapters),
      isEnabled: data['isEnabled'] == true,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
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
