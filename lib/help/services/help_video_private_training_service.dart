import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/help_video_tutorial_model.dart';
import 'help_video_tutorial_service.dart';

class HelpVideoPrivateTrainingService {
  HelpVideoPrivateTrainingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    HelpVideoTutorialService? tutorialService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _tutorialService = tutorialService ?? HelpVideoTutorialService();

  static const String entitlementCollection =
      'help_video_training_entitlements';

  static const Set<String> allowedPrivateAudiences = <String>{
    'driver',
    'food_rider',
    'restaurant_partner',
    'hotel_partner',
    'tourism_driver',
    'tour_guide',
    'admin',
    'super_admin',
  };

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final HelpVideoTutorialService _tutorialService;

  Future<List<String>> loadMyAllowedAudiences() async {
    final user = _auth.currentUser;

    if (user == null) {
      return const <String>[];
    }

    final snapshot = await _firestore
        .collection(entitlementCollection)
        .doc(user.uid)
        .get();

    if (!snapshot.exists) {
      return const <String>[];
    }

    final data = snapshot.data() ?? <String, dynamic>{};

    if (data['isActive'] != true) {
      return const <String>[];
    }

    final raw = data['allowedAudiences'];

    if (raw is! Iterable) {
      return const <String>[];
    }

    final audiences =
        raw
            .map((item) => item.toString().trim().toLowerCase())
            .where(allowedPrivateAudiences.contains)
            .toSet()
            .toList(growable: false)
          ..sort();

    return audiences;
  }

  Future<List<HelpVideoTutorialModel>> loadMyPrivateTutorials() async {
    final audiences = await loadMyAllowedAudiences();

    if (audiences.isEmpty) {
      return const <HelpVideoTutorialModel>[];
    }

    final tutorials = <HelpVideoTutorialModel>[];

    for (final audience in audiences) {
      final snapshot = await _firestore
          .collection(HelpVideoTutorialService.collectionName)
          .where('audience', isEqualTo: audience)
          .where('isEnabled', isEqualTo: true)
          .where('publishedStatus', isEqualTo: 'published')
          .where('outdated', isEqualTo: false)
          .get();

      for (final document in snapshot.docs) {
        final tutorial = HelpVideoTutorialModel.fromMap(
          id: document.id,
          map: document.data(),
        );

        if (tutorial.audience.trim().toLowerCase() != audience) {
          continue;
        }

        if (!tutorial.isSafeForRecommendation) {
          continue;
        }

        if (!_tutorialService.isSafeVideoUrl(tutorial.videoUrl)) {
          continue;
        }

        tutorials.add(tutorial);
      }
    }

    tutorials.sort((first, second) {
      final audienceCompare = first.audience.compareTo(second.audience);

      if (audienceCompare != 0) {
        return audienceCompare;
      }

      final orderCompare = first.displayOrder.compareTo(second.displayOrder);

      if (orderCompare != 0) {
        return orderCompare;
      }

      return first.title.compareTo(second.title);
    });

    return List<HelpVideoTutorialModel>.unmodifiable(tutorials);
  }
}
