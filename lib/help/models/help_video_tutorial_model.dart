import 'package:cloud_firestore/cloud_firestore.dart';

class HelpVideoTutorialModel {
  const HelpVideoTutorialModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.isEnabled,
    required this.displayOrder,
    required this.category,
    this.module = 'general',
    this.feature = '',
    this.language = 'und',
    this.audience = 'customer',
    this.duration = 0,
    this.appVersion = '',
    this.videoVersion = '1',
    this.keywords = const <String>[],
    this.intents = const <String>[],
    this.publishedStatus = 'draft',
    this.storageReference = '',
    this.reviewedBy = '',
    this.outdated = false,
    this.maintenanceSource = 'manual',
    this.changeSummary = '',
    this.requiresApproval = false,
    this.approvalStatus = 'approved',
    this.approvedBy = '',
    this.approvedAt,
    this.supersedesVideoId = '',
    this.changeDetectedAt,
    this.updateTaskId = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final bool isEnabled;
  final int displayOrder;
  final String category;

  /// Product/module owning this tutorial.
  ///
  /// Examples:
  /// ride, food, hotel, tours, student, cargo, safety.
  final String module;

  /// Specific feature or flow explained by the tutorial.
  final String feature;

  /// Tutorial language code/name.
  ///
  /// Existing legacy records safely fall back to `und`
  /// (undetermined) until an Admin assigns a language.
  final String language;

  /// Intended audience.
  ///
  /// Examples:
  /// customer, driver, food_rider, restaurant_partner,
  /// hotel_partner, tourism_driver, tour_guide, admin,
  /// super_admin.
  final String audience;

  /// Approximate tutorial duration in seconds.
  final int duration;

  /// App version whose UI/flow this tutorial represents.
  final String appVersion;

  /// Independent tutorial/content version.
  final String videoVersion;

  /// Search terms attached to this tutorial.
  final List<String> keywords;

  /// Support/customer intents this tutorial can answer.
  final List<String> intents;

  /// Publication lifecycle.
  ///
  /// Expected values will be controlled by the Admin layer,
  /// for example draft, published, archived.
  final String publishedStatus;

  /// Optional hosted/CDN/storage reference.
  ///
  /// `videoUrl` remains supported for the existing lightweight
  /// external-launch architecture.
  final String storageReference;

  /// UID/identifier of the latest human reviewer when available.
  final String reviewedBy;

  /// True when the tutorial should not be recommended because
  /// the represented app flow may no longer match the current app.
  final bool outdated;

  /// Origin of this tutorial/update.
  ///
  /// Examples:
  /// manual
  /// agent_change_detection
  /// admin_update
  final String maintenanceSource;

  /// Human-readable summary of the app/feature change that caused
  /// this tutorial draft or update.
  final String changeSummary;

  /// True for AI/change-detection generated drafts that must not
  /// become public until Owner/Super Admin approval.
  final bool requiresApproval;

  /// Approval lifecycle.
  ///
  /// Expected values:
  /// pending, approved, rejected.
  final String approvalStatus;

  /// Owner/Super Admin UID that approved the tutorial/update.
  final String approvedBy;

  final DateTime? approvedAt;

  /// Previous tutorial/video record replaced by this version.
  /// Allows archive/rollback-safe version chains.
  final String supersedesVideoId;

  /// When the related app/feature change was detected.
  final DateTime? changeDetectedAt;

  /// Optional future Education/Training Agent task identifier.
  final String updateTaskId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory HelpVideoTutorialModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final bool enabled = _boolValue(map['isEnabled'], fallback: false);

    return HelpVideoTutorialModel(
      id: id.trim(),
      title: _stringValue(map['title']),
      description: _stringValue(map['description']),
      videoUrl: _stringValue(map['videoUrl']),
      isEnabled: enabled,
      displayOrder: _intValue(map['displayOrder']),
      category: _stringValue(map['category'], fallback: 'general'),
      module: _stringValue(map['module'], fallback: 'general'),
      feature: _stringValue(map['feature']),
      language: _stringValue(map['language'], fallback: 'und'),
      audience: _stringValue(map['audience'], fallback: 'customer'),
      duration: _nonNegativeIntValue(map['duration']),
      appVersion: _stringValue(map['appVersion']),
      videoVersion: _stringValue(map['videoVersion'], fallback: '1'),
      keywords: _stringListValue(map['keywords']),
      intents: _stringListValue(map['intents']),
      publishedStatus: _stringValue(
        map['publishedStatus'],
        fallback: enabled ? 'published' : 'draft',
      ),
      storageReference: _stringValue(map['storageReference']),
      reviewedBy: _stringValue(map['reviewedBy']),
      outdated: _boolValue(map['outdated'], fallback: false),
      maintenanceSource: _stringValue(
        map['maintenanceSource'],
        fallback: 'manual',
      ),
      changeSummary: _stringValue(map['changeSummary']),
      requiresApproval: _boolValue(map['requiresApproval'], fallback: false),
      approvalStatus: _stringValue(map['approvalStatus'], fallback: 'approved'),
      approvedBy: _stringValue(map['approvedBy']),
      approvedAt: _dateValue(map['approvedAt']),
      supersedesVideoId: _stringValue(map['supersedesVideoId']),
      changeDetectedAt: _dateValue(map['changeDetectedAt']),
      updateTaskId: _stringValue(map['updateTaskId']),
      createdAt: _dateValue(map['createdAt']),
      updatedAt: _dateValue(map['updatedAt']),
    );
  }

  bool get isPendingApproval =>
      requiresApproval && approvalStatus.toLowerCase() == 'pending';

  bool get isApprovedForPublication =>
      !requiresApproval || approvalStatus.toLowerCase() == 'approved';

  bool get isRejected =>
      requiresApproval && approvalStatus.toLowerCase() == 'rejected';

  bool get isSafeForRecommendation =>
      publishedStatus.toLowerCase() == 'published' &&
      !outdated &&
      isApprovedForPublication;

  static String _stringValue(dynamic value, {String fallback = ''}) {
    final String parsed = value?.toString().trim() ?? '';

    return parsed.isEmpty ? fallback : parsed;
  }

  static bool _boolValue(dynamic value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }

    return fallback;
  }

  static int _intValue(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _nonNegativeIntValue(dynamic value) {
    final int parsed = _intValue(value);

    return parsed < 0 ? 0 : parsed;
  }

  static List<String> _stringListValue(dynamic value) {
    if (value is! Iterable) {
      return const <String>[];
    }

    final List<String> parsed = value
        .map((dynamic item) => item?.toString().trim() ?? '')
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);

    return List<String>.unmodifiable(parsed);
  }

  static DateTime? _dateValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
