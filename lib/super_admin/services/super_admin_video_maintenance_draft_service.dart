import 'package:cloud_firestore/cloud_firestore.dart';

import '../../help/models/help_video_maintenance_draft.dart';
import '../../help/models/help_video_maintenance_draft_record.dart';
import '../../help/services/help_video_accuracy_review_service.dart';

class SuperAdminVideoMaintenanceDraftService {
  SuperAdminVideoMaintenanceDraftService({
    FirebaseFirestore? firestore,
    HelpVideoAccuracyReviewService? reviewService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _reviewService = reviewService ?? const HelpVideoAccuracyReviewService();

  static const collectionName = 'help_video_maintenance_drafts';

  final FirebaseFirestore _firestore;
  final HelpVideoAccuracyReviewService _reviewService;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Stream<List<HelpVideoMaintenanceDraftRecord>> watchDrafts() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(HelpVideoMaintenanceDraftRecord.fromDocument)
              .toList(growable: false),
        );
  }

  Future<String> submitForOwnerApproval({
    required HelpVideoMaintenanceDraft draft,
    required String adminId,
  }) async {
    final uid = _required(adminId, 'Admin ID');

    final review = _reviewService.reviewDraft(draft);

    if (!review.canSubmitToOwnerApproval) {
      throw StateError(
        'Draft failed pre-review: '
        '${review.blockingReasons.join(", ")}',
      );
    }

    if (!draft.isSafeDraftContract || draft.automaticPublishAllowed) {
      throw StateError('Unsafe maintenance draft blocked.');
    }

    final doc = _collection.doc();

    await doc.set(<String, dynamic>{
      'sourceTutorialId': draft.sourceTutorialId.trim(),
      'title': draft.title.trim(),
      'module': draft.module.trim(),
      'feature': draft.feature.trim(),
      'language': draft.language.trim(),
      'audience': draft.audience.trim(),
      'targetAppVersion': draft.targetAppVersion.trim(),
      'baseVideoVersion': draft.baseVideoVersion.trim(),
      'proposedVideoVersion': draft.proposedVideoVersion.trim(),
      'changeSummary': draft.changeSummary.trim(),
      'scriptDraft': draft.scriptDraft.trim(),
      'storyboardDraft': draft.storyboardDraft.trim(),
      'scenePlanDraft': draft.scenePlanDraft.trim(),
      'narrationDraft': draft.narrationDraft.trim(),
      'captionDraft': draft.captionDraft.trim(),
      'keywords': draft.keywords,
      'intents': draft.intents,
      'maintenanceSource': 'agent_change_detection',
      'requiresApproval': true,
      'approvalStatus': 'pending',
      'supersedesVideoId': draft.supersedesVideoId.trim(),
      'needsExtraReview': draft.needsExtraReview,
      'extraReviewReasons': draft.extraReviewReasons,
      'automaticPublishAllowed': false,
      'reviewStatus': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
      'reviewedBy': '',
      'rejectionReason': '',
    });

    return doc.id;
  }

  Future<void> approveDraft({
    required String draftId,
    required String reviewerId,
  }) async {
    await _finishReview(
      draftId: draftId,
      reviewerId: reviewerId,
      status: 'approved',
      reason: '',
    );
  }

  Future<void> rejectDraft({
    required String draftId,
    required String reviewerId,
    String reason = '',
  }) async {
    await _finishReview(
      draftId: draftId,
      reviewerId: reviewerId,
      status: 'rejected',
      reason: reason,
    );
  }

  Future<void> _finishReview({
    required String draftId,
    required String reviewerId,
    required String status,
    required String reason,
  }) async {
    final id = _required(draftId, 'Draft ID');
    final uid = _required(reviewerId, 'Reviewer ID');

    final snapshot = await _collection.doc(id).get();

    if (!snapshot.exists) {
      throw StateError('Maintenance draft does not exist.');
    }

    final data = snapshot.data() ?? <String, dynamic>{};

    if (data['reviewStatus']?.toString().trim().toLowerCase() != 'pending') {
      throw StateError('Only pending drafts may be reviewed.');
    }

    if (data['automaticPublishAllowed'] == true) {
      throw StateError('Unsafe automatic-publish flag detected.');
    }

    await _collection.doc(id).update(<String, dynamic>{
      'reviewStatus': status,
      'reviewedBy': uid,
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
      'automaticPublishAllowed': false,
    });
  }

  String _required(String value, String name) {
    final result = value.trim();

    if (result.isEmpty) {
      throw ArgumentError('$name is required.');
    }

    return result;
  }
}
