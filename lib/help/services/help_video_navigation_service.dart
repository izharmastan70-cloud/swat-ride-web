import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/help_video_navigation_metadata.dart';

class HelpVideoNavigationService {
  HelpVideoNavigationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'help_video_navigation_metadata';

  final FirebaseFirestore _firestore;

  Future<HelpVideoNavigationMetadata?> getMetadata({
    required String tutorialId,
  }) async {
    final id = tutorialId.trim();

    if (id.isEmpty) {
      return null;
    }

    final snapshot = await _firestore.collection(collectionName).doc(id).get();

    if (!snapshot.exists) {
      return null;
    }

    final metadata = HelpVideoNavigationMetadata.fromDocument(snapshot);

    if (!metadata.isEnabled) {
      return null;
    }

    return metadata;
  }

  static String timestampLabel(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;

    final hours = safe ~/ 3600;

    final minutes = (safe % 3600) ~/ 60;

    final remaining = safe % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${remaining.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remaining.toString().padLeft(2, '0')}';
  }
}
