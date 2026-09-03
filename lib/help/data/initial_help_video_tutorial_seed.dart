import 'package:cloud_firestore/cloud_firestore.dart';

/// One deterministic Help Video Tutorial seed record.
///
/// Important:
/// - Seed IDs must remain stable.
/// - Existing Firestore documents are never overwritten.
/// - Initial records should normally stay disabled until a real,
///   verified tutorial video URL has been configured.
class InitialHelpVideoTutorialSeedItem {
  const InitialHelpVideoTutorialSeedItem({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.category,
    required this.displayOrder,
    this.isEnabled = false,
  });

  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String category;
  final int displayOrder;
  final bool isEnabled;
}

/// Intentionally empty until SWAT RIDE's real tutorial video URLs
/// are available.
///
/// Do not add fake, placeholder, test, or unrelated public videos here.
/// A tutorial should only be added after its final video URL is known
/// and verified.
const List<InitialHelpVideoTutorialSeedItem> initialHelpVideoTutorialSeedItems =
    <InitialHelpVideoTutorialSeedItem>[];

class InitialHelpVideoTutorialSeedResult {
  const InitialHelpVideoTutorialSeedResult({
    required this.createdCount,
    required this.skippedExistingCount,
  });

  final int createdCount;
  final int skippedExistingCount;
}

/// Development/bootstrap helper for Help Video Tutorials.
///
/// Safety guarantees:
/// - deterministic document IDs;
/// - create-only behavior;
/// - existing documents are skipped;
/// - no delete;
/// - no overwrite;
/// - HTTPS video URL required;
/// - customer visibility remains controlled by [isEnabled].
Future<InitialHelpVideoTutorialSeedResult> seedInitialHelpVideoTutorials({
  required String adminId,
  FirebaseFirestore? firestore,
  Iterable<InitialHelpVideoTutorialSeedItem> items =
      initialHelpVideoTutorialSeedItems,
}) async {
  final String normalizedAdminId = adminId.trim();

  if (normalizedAdminId.isEmpty) {
    throw ArgumentError('Super Admin ID is required.');
  }

  final FirebaseFirestore db = firestore ?? FirebaseFirestore.instance;

  final CollectionReference<Map<String, dynamic>> collection = db.collection(
    'help_video_tutorials',
  );

  int createdCount = 0;
  int skippedExistingCount = 0;

  for (final InitialHelpVideoTutorialSeedItem item in items) {
    final String normalizedId = item.id.trim();
    final String normalizedTitle = item.title.trim();
    final String normalizedDescription = item.description.trim();
    final String normalizedVideoUrl = item.videoUrl.trim();
    final String normalizedCategory = item.category.trim().isEmpty
        ? 'general'
        : item.category.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError('Tutorial seed ID is required.');
    }

    if (normalizedTitle.isEmpty) {
      throw ArgumentError(
        'Tutorial title is required for seed "$normalizedId".',
      );
    }

    if (!_isSafeVideoUrl(normalizedVideoUrl)) {
      throw ArgumentError(
        'A valid HTTPS video URL is required for seed "$normalizedId".',
      );
    }

    if (item.displayOrder < 0) {
      throw ArgumentError(
        'Display order cannot be negative for seed "$normalizedId".',
      );
    }

    final DocumentReference<Map<String, dynamic>> document = collection.doc(
      normalizedId,
    );

    final bool created = await db.runTransaction<bool>((
      Transaction transaction,
    ) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
          .get(document);

      if (snapshot.exists) {
        return false;
      }

      transaction.set(document, <String, dynamic>{
        'title': normalizedTitle,
        'description': normalizedDescription,
        'videoUrl': normalizedVideoUrl,
        'category': normalizedCategory,
        'displayOrder': item.displayOrder,
        'isEnabled': item.isEnabled,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': normalizedAdminId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': normalizedAdminId,
      });

      return true;
    });

    if (created) {
      createdCount++;
    } else {
      skippedExistingCount++;
    }
  }

  return InitialHelpVideoTutorialSeedResult(
    createdCount: createdCount,
    skippedExistingCount: skippedExistingCount,
  );
}

bool _isSafeVideoUrl(String value) {
  final Uri? uri = Uri.tryParse(value.trim());

  if (uri == null) {
    return false;
  }

  if (uri.scheme.toLowerCase() != 'https') {
    return false;
  }

  return uri.host.trim().isNotEmpty;
}
