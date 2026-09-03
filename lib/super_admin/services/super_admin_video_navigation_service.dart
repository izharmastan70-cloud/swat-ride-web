import 'package:cloud_firestore/cloud_firestore.dart';

import '../../help/models/help_video_navigation_metadata.dart';

class SuperAdminVideoNavigationService {
  SuperAdminVideoNavigationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'help_video_navigation_metadata';

  final FirebaseFirestore _firestore;

  Future<HelpVideoNavigationMetadata?> loadMetadata(String tutorialId) async {
    final id = _requiredTutorialId(tutorialId);

    final snapshot = await _firestore.collection(collectionName).doc(id).get();

    if (!snapshot.exists) {
      return null;
    }

    return HelpVideoNavigationMetadata.fromDocument(snapshot);
  }

  Future<void> saveMetadata({
    required String tutorialId,
    required String deepLinkPath,
    required List<HelpVideoChapterMarker> chapters,
    required bool isEnabled,
    required String adminId,
  }) async {
    final id = _requiredTutorialId(tutorialId);

    final reviewer = adminId.trim();

    if (reviewer.isEmpty) {
      throw ArgumentError('Super Admin ID is required.');
    }

    final normalizedDeepLink = _validateDeepLink(
      deepLinkPath,
      fieldName: 'Tutorial deep link',
    );

    if (chapters.length > 100) {
      throw ArgumentError(
        'A tutorial may contain at most 100 chapter markers.',
      );
    }

    int previousStart = -1;

    final cleanChapters = <HelpVideoChapterMarker>[];

    for (final chapter in chapters) {
      final title = chapter.title.trim();

      if (title.isEmpty) {
        throw ArgumentError('Every chapter needs a title.');
      }

      if (title.length > 200) {
        throw ArgumentError('Chapter title is too long.');
      }

      if (chapter.startSeconds < 0 || chapter.startSeconds > 86400) {
        throw ArgumentError(
          'Chapter start timestamp must be '
          'between 0 and 86400 seconds.',
        );
      }

      if (chapter.endSeconds < 0 || chapter.endSeconds > 86400) {
        throw ArgumentError(
          'Chapter end timestamp must be '
          'between 0 and 86400 seconds.',
        );
      }

      if (chapter.endSeconds > 0 && chapter.endSeconds < chapter.startSeconds) {
        throw ArgumentError(
          'Chapter end timestamp cannot be '
          'before its start timestamp.',
        );
      }

      if (chapter.startSeconds < previousStart) {
        throw ArgumentError('Chapter timestamps must be in ascending order.');
      }

      previousStart = chapter.startSeconds;

      cleanChapters.add(
        HelpVideoChapterMarker(
          title: title,
          startSeconds: chapter.startSeconds,
          endSeconds: chapter.endSeconds,
          deepLinkPath: _validateDeepLink(
            chapter.deepLinkPath,
            fieldName: 'Chapter deep link',
          ),
        ),
      );
    }

    final reference = _firestore.collection(collectionName).doc(id);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);

      final data = <String, dynamic>{
        'tutorialId': id,
        'deepLinkPath': normalizedDeepLink,
        'chapters': cleanChapters
            .map((chapter) => chapter.toMap())
            .toList(growable: false),
        'isEnabled': isEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': reviewer,
      };

      if (!existing.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();

        data['createdBy'] = reviewer;

        transaction.set(reference, data);

        return;
      }

      transaction.update(reference, data);
    });
  }

  List<HelpVideoChapterMarker> parseChapterLines(String raw) {
    final chapters = <HelpVideoChapterMarker>[];

    final lines = raw.split(RegExp(r'\r?\n'));

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index].trim();

      if (line.isEmpty) {
        continue;
      }

      final parts = line.split('|');

      if (parts.length < 3 || parts.length > 4) {
        throw FormatException(
          'Chapter line ${index + 1} must use: '
          'startSeconds|endSeconds|Title|/optional/path',
        );
      }

      final start = int.tryParse(parts[0].trim());

      final end = int.tryParse(parts[1].trim());

      if (start == null || end == null) {
        throw FormatException(
          'Chapter line ${index + 1} has an invalid timestamp.',
        );
      }

      chapters.add(
        HelpVideoChapterMarker(
          startSeconds: start,
          endSeconds: end,
          title: parts[2].trim(),
          deepLinkPath: parts.length == 4 ? parts[3].trim() : '',
        ),
      );
    }

    return chapters;
  }

  String serializeChapterLines(List<HelpVideoChapterMarker> chapters) {
    return chapters
        .map(
          (chapter) =>
              '${chapter.startSeconds}|'
              '${chapter.endSeconds}|'
              '${chapter.title}|'
              '${chapter.deepLinkPath}',
        )
        .join('\n');
  }

  String _validateDeepLink(String value, {required String fieldName}) {
    final path = value.trim();

    if (path.isEmpty) {
      return '';
    }

    if (path.length > 500) {
      throw ArgumentError('$fieldName is too long.');
    }

    if (!path.startsWith('/') || path.contains('://')) {
      throw ArgumentError(
        '$fieldName must be an internal path '
        'starting with "/" and must not contain a URL scheme.',
      );
    }

    return path;
  }

  String _requiredTutorialId(String value) {
    final id = value.trim();

    if (id.isEmpty) {
      throw ArgumentError('Tutorial ID is required.');
    }

    return id;
  }
}
