import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/help_video_tutorial_model.dart';

class HelpVideoTutorialService {
  HelpVideoTutorialService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'help_video_tutorials';

  final FirebaseFirestore _firestore;

  Stream<List<HelpVideoTutorialModel>> watchEnabledTutorials() {
    return _firestore
        .collection(collectionName)
        .where('isEnabled', isEqualTo: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<HelpVideoTutorialModel> tutorials = snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> document) =>
                    HelpVideoTutorialModel.fromMap(
                      id: document.id,
                      map: document.data(),
                    ),
              )
              .where(_isCustomerVisible)
              .toList();

          tutorials.sort((
            HelpVideoTutorialModel first,
            HelpVideoTutorialModel second,
          ) {
            final int orderCompare = first.displayOrder.compareTo(
              second.displayOrder,
            );

            if (orderCompare != 0) {
              return orderCompare;
            }

            return first.title.toLowerCase().compareTo(
              second.title.toLowerCase(),
            );
          });

          return List<HelpVideoTutorialModel>.unmodifiable(tutorials);
        });
  }

  bool isSafeVideoUrl(String value) {
    final Uri? uri = Uri.tryParse(value.trim());

    if (uri == null) {
      return false;
    }

    if (uri.scheme.toLowerCase() != 'https') {
      return false;
    }

    if (uri.host.trim().isEmpty) {
      return false;
    }

    return true;
  }

  bool _isCustomerVisible(HelpVideoTutorialModel tutorial) {
    if (!tutorial.isEnabled) {
      return false;
    }

    if (tutorial.id.trim().isEmpty) {
      return false;
    }

    if (tutorial.title.trim().isEmpty) {
      return false;
    }

    if (!isSafeVideoUrl(tutorial.videoUrl)) {
      return false;
    }

    // Normal customer Help Library must never expose
    // Driver, Partner, Admin, or Super Admin training.
    if (tutorial.audience.trim().toLowerCase() != 'customer') {
      return false;
    }

    // Pending, rejected, outdated, draft, or archived tutorials
    // are not safe customer recommendations.
    if (!tutorial.isSafeForRecommendation) {
      return false;
    }
    return true;
  }
}
