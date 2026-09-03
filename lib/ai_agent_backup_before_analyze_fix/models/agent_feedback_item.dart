import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_feedback_constants.dart';

// =========================================================
// AI AGENT — CENTRAL FEEDBACK ITEM
// =========================================================
//
// Firestore collection: agent_feedback
// Standalone shared feedback model for future Ride/Food/Hotel/Tour/etc.
// integrations. No existing module is connected in Phase 12.

class AgentFeedbackItem {
  final String feedbackId;
  final String userIdAlias;
  final String module;
  final String referenceId;
  final String type;
  final int? rating;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AgentFeedbackItem({
    required this.feedbackId,
    required this.userIdAlias,
    required this.module,
    required this.referenceId,
    required this.type,
    required this.rating,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  void validate() {
    if (feedbackId.trim().isEmpty) {
      throw const AgentFeedbackValidationException(
        'feedbackId cannot be empty.',
      );
    }

    if (!AgentFeedbackType.isValid(type)) {
      throw AgentFeedbackValidationException(
        'Invalid feedback type "$type".',
      );
    }

    if (!AgentFeedbackStatus.isValid(status)) {
      throw AgentFeedbackValidationException(
        'Invalid feedback status "$status".',
      );
    }

    if (rating != null && (rating! < 1 || rating! > 5)) {
      throw const AgentFeedbackValidationException(
        'rating must be between 1 and 5.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'feedbackId': feedbackId,
      'userIdAlias': userIdAlias,
      'module': module,
      'referenceId': referenceId,
      'type': type,
      'rating': rating,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt':
          updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory AgentFeedbackItem.fromMap(Map<String, dynamic> map) {
    final AgentFeedbackItem item = AgentFeedbackItem(
      feedbackId: (map['feedbackId'] ?? '').toString().trim(),
      userIdAlias: (map['userIdAlias'] ?? '').toString().trim(),
      module: (map['module'] ?? '').toString().trim(),
      referenceId: (map['referenceId'] ?? '').toString().trim(),
      type: (map['type'] ?? AgentFeedbackType.review).toString(),
      rating: _nullableInt(map['rating']),
      message: (map['message'] ?? '').toString().trim(),
      status: (map['status'] ?? AgentFeedbackStatus.open).toString(),
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      updatedAt: _date(map['updatedAt']),
    );

    item.validate();
    return item;
  }

  factory AgentFeedbackItem.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(snapshot.data() ?? <String, dynamic>{});
    data['feedbackId'] ??= snapshot.id;
    return AgentFeedbackItem.fromMap(data);
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class AgentFeedbackValidationException implements Exception {
  final String message;
  const AgentFeedbackValidationException(this.message);

  @override
  String toString() => 'AgentFeedbackValidationException: $message';
}
