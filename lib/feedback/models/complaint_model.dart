import 'package:cloud_firestore/cloud_firestore.dart';

import 'feedback_model.dart';

enum ComplaintCategory {
  safety,
  fraud,
  harassment,
  paymentIssue,
  damagedItem,
  badFood,
  serviceQuality,
  lateService,
  driverBehavior,
  partnerBehavior,
  missingItem,
  cancellation,
  refund,
  discrimination,
  privacy,
  other,
}

enum ComplaintPriority { low, normal, high, urgent, critical }

enum ComplaintStatus {
  open,
  inReview,
  waitingForCustomer,
  waitingForPartner,
  resolved,
  closed,
  rejected,
}

enum ComplaintActorType {
  customer,
  partner,
  driver,
  admin,
  supportAgent,
  system,
}

extension ComplaintCategoryX on ComplaintCategory {
  String get value => name;

  String get displayName {
    switch (this) {
      case ComplaintCategory.safety:
        return 'Safety';
      case ComplaintCategory.fraud:
        return 'Fraud';
      case ComplaintCategory.harassment:
        return 'Harassment';
      case ComplaintCategory.paymentIssue:
        return 'Payment Issue';
      case ComplaintCategory.damagedItem:
        return 'Damaged Item';
      case ComplaintCategory.badFood:
        return 'Bad Food';
      case ComplaintCategory.serviceQuality:
        return 'Service Quality';
      case ComplaintCategory.lateService:
        return 'Late Service';
      case ComplaintCategory.driverBehavior:
        return 'Driver Behaviour';
      case ComplaintCategory.partnerBehavior:
        return 'Partner Behaviour';
      case ComplaintCategory.missingItem:
        return 'Missing Item';
      case ComplaintCategory.cancellation:
        return 'Cancellation';
      case ComplaintCategory.refund:
        return 'Refund';
      case ComplaintCategory.discrimination:
        return 'Discrimination';
      case ComplaintCategory.privacy:
        return 'Privacy';
      case ComplaintCategory.other:
        return 'Other';
    }
  }

  bool get requiresSafetyEscalation {
    return this == ComplaintCategory.safety ||
        this == ComplaintCategory.harassment ||
        this == ComplaintCategory.discrimination ||
        this == ComplaintCategory.privacy;
  }

  ComplaintPriority get recommendedPriority {
    switch (this) {
      case ComplaintCategory.safety:
      case ComplaintCategory.harassment:
        return ComplaintPriority.critical;
      case ComplaintCategory.fraud:
      case ComplaintCategory.discrimination:
      case ComplaintCategory.privacy:
        return ComplaintPriority.urgent;
      case ComplaintCategory.paymentIssue:
      case ComplaintCategory.damagedItem:
      case ComplaintCategory.badFood:
      case ComplaintCategory.driverBehavior:
      case ComplaintCategory.partnerBehavior:
      case ComplaintCategory.missingItem:
      case ComplaintCategory.refund:
        return ComplaintPriority.high;
      case ComplaintCategory.serviceQuality:
      case ComplaintCategory.lateService:
      case ComplaintCategory.cancellation:
        return ComplaintPriority.normal;
      case ComplaintCategory.other:
        return ComplaintPriority.normal;
    }
  }

  static ComplaintCategory fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'safety':
        return ComplaintCategory.safety;
      case 'fraud':
        return ComplaintCategory.fraud;
      case 'harassment':
        return ComplaintCategory.harassment;
      case 'paymentissue':
      case 'payment_issue':
      case 'payment issue':
        return ComplaintCategory.paymentIssue;
      case 'damageditem':
      case 'damaged_item':
      case 'damaged item':
        return ComplaintCategory.damagedItem;
      case 'badfood':
      case 'bad_food':
      case 'bad food':
      case 'foodquality':
      case 'food_quality':
        return ComplaintCategory.badFood;
      case 'servicequality':
      case 'service_quality':
      case 'service quality':
        return ComplaintCategory.serviceQuality;
      case 'lateservice':
      case 'late_service':
      case 'late service':
        return ComplaintCategory.lateService;
      case 'driverbehavior':
      case 'driver_behavior':
      case 'driver behaviour':
      case 'driver behavior':
        return ComplaintCategory.driverBehavior;
      case 'partnerbehavior':
      case 'partner_behavior':
      case 'partner behaviour':
      case 'partner behavior':
        return ComplaintCategory.partnerBehavior;
      case 'missingitem':
      case 'missing_item':
      case 'missing item':
        return ComplaintCategory.missingItem;
      case 'cancellation':
        return ComplaintCategory.cancellation;
      case 'refund':
        return ComplaintCategory.refund;
      case 'discrimination':
        return ComplaintCategory.discrimination;
      case 'privacy':
        return ComplaintCategory.privacy;
      default:
        return ComplaintCategory.other;
    }
  }
}

extension ComplaintPriorityX on ComplaintPriority {
  String get value => name;

  static ComplaintPriority fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'low':
        return ComplaintPriority.low;
      case 'high':
        return ComplaintPriority.high;
      case 'urgent':
        return ComplaintPriority.urgent;
      case 'critical':
        return ComplaintPriority.critical;
      default:
        return ComplaintPriority.normal;
    }
  }
}

extension ComplaintStatusX on ComplaintStatus {
  String get value => name;

  String get displayName {
    switch (this) {
      case ComplaintStatus.open:
        return 'Open';
      case ComplaintStatus.inReview:
        return 'In Review';
      case ComplaintStatus.waitingForCustomer:
        return 'Waiting for Customer';
      case ComplaintStatus.waitingForPartner:
        return 'Waiting for Partner';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.closed:
        return 'Closed';
      case ComplaintStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isFinal {
    return this == ComplaintStatus.closed || this == ComplaintStatus.rejected;
  }

  bool canTransitionTo(ComplaintStatus next) {
    if (this == next) {
      return true;
    }

    switch (this) {
      case ComplaintStatus.open:
        return next == ComplaintStatus.inReview ||
            next == ComplaintStatus.waitingForCustomer ||
            next == ComplaintStatus.waitingForPartner ||
            next == ComplaintStatus.resolved ||
            next == ComplaintStatus.rejected;
      case ComplaintStatus.inReview:
        return next == ComplaintStatus.waitingForCustomer ||
            next == ComplaintStatus.waitingForPartner ||
            next == ComplaintStatus.resolved ||
            next == ComplaintStatus.rejected;
      case ComplaintStatus.waitingForCustomer:
      case ComplaintStatus.waitingForPartner:
        return next == ComplaintStatus.inReview ||
            next == ComplaintStatus.resolved ||
            next == ComplaintStatus.rejected;
      case ComplaintStatus.resolved:
        return next == ComplaintStatus.inReview ||
            next == ComplaintStatus.closed;
      case ComplaintStatus.closed:
      case ComplaintStatus.rejected:
        return false;
    }
  }

  static ComplaintStatus fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'inreview':
      case 'in_review':
      case 'in review':
        return ComplaintStatus.inReview;
      case 'waitingforcustomer':
      case 'waiting_for_customer':
      case 'waiting for customer':
        return ComplaintStatus.waitingForCustomer;
      case 'waitingforpartner':
      case 'waiting_for_partner':
      case 'waiting for partner':
        return ComplaintStatus.waitingForPartner;
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'closed':
        return ComplaintStatus.closed;
      case 'rejected':
        return ComplaintStatus.rejected;
      default:
        return ComplaintStatus.open;
    }
  }
}

extension ComplaintActorTypeX on ComplaintActorType {
  String get value => name;

  static ComplaintActorType fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'partner':
        return ComplaintActorType.partner;
      case 'driver':
        return ComplaintActorType.driver;
      case 'admin':
        return ComplaintActorType.admin;
      case 'supportagent':
      case 'support_agent':
      case 'support agent':
        return ComplaintActorType.supportAgent;
      case 'system':
        return ComplaintActorType.system;
      default:
        return ComplaintActorType.customer;
    }
  }
}

class ComplaintStatusHistory {
  final ComplaintStatus status;
  final String changedBy;
  final ComplaintActorType actorType;
  final String note;
  final DateTime changedAt;

  const ComplaintStatusHistory({
    required this.status,
    required this.changedBy,
    required this.actorType,
    this.note = '',
    required this.changedAt,
  });

  void validate() {
    if (changedBy.trim().isEmpty) {
      throw const FormatException('Complaint status changer ID is required.');
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'status': status.value,
      'changedBy': changedBy.trim(),
      'actorType': actorType.value,
      'note': note.trim(),
      'changedAt': Timestamp.fromDate(changedAt),
    };
  }

  factory ComplaintStatusHistory.fromMap(Map<String, dynamic> map) {
    return ComplaintStatusHistory(
      status: ComplaintStatusX.fromValue(map['status']),
      changedBy: _stringValue(map['changedBy']),
      actorType: ComplaintActorTypeX.fromValue(map['actorType']),
      note: _stringValue(map['note']),
      changedAt: _dateTimeValue(map['changedAt']) ?? DateTime.now(),
    );
  }

  static String _stringValue(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static DateTime? _dateTimeValue(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.tryParse(value?.toString() ?? '');
  }
}

class ComplaintModel {
  static const int maximumTitleLength = 150;
  static const int maximumDescriptionLength = 3000;
  static const int maximumEvidenceCount = 10;

  final String id;
  final String ticketId;

  final FeedbackServiceType serviceType;
  final String sourceId;
  final String sourceReference;
  final String feedbackId;

  final String reporterId;
  final String reporterName;
  final String reporterPhone;

  final FeedbackTargetType targetType;
  final String targetId;
  final String targetName;

  final ComplaintCategory category;
  final ComplaintPriority priority;
  final ComplaintStatus status;

  final String title;
  final String description;

  /// URLs remain empty until Firebase Storage billing is enabled.
  final List<String> evidenceUrls;

  final bool safetyEscalationRequired;
  final bool safetyEscalationSent;
  final String safetyCaseId;
  final DateTime? safetyEscalatedAt;

  final String assignedAdminId;
  final String assignedAdminName;
  final DateTime? assignedAt;

  final String resolution;
  final String resolutionCode;
  final String resolvedBy;
  final DateTime? resolvedAt;
  final DateTime? closedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  final List<ComplaintStatusHistory> statusHistory;
  final Map<String, dynamic> metadata;

  const ComplaintModel({
    required this.id,
    required this.ticketId,
    required this.serviceType,
    required this.sourceId,
    this.sourceReference = '',
    this.feedbackId = '',
    required this.reporterId,
    this.reporterName = '',
    this.reporterPhone = '',
    required this.targetType,
    required this.targetId,
    this.targetName = '',
    required this.category,
    required this.priority,
    this.status = ComplaintStatus.open,
    required this.title,
    required this.description,
    this.evidenceUrls = const <String>[],
    this.safetyEscalationRequired = false,
    this.safetyEscalationSent = false,
    this.safetyCaseId = '',
    this.safetyEscalatedAt,
    this.assignedAdminId = '',
    this.assignedAdminName = '',
    this.assignedAt,
    this.resolution = '',
    this.resolutionCode = '',
    this.resolvedBy = '',
    this.resolvedAt,
    this.closedAt,
    required this.createdAt,
    required this.updatedAt,
    this.statusHistory = const <ComplaintStatusHistory>[],
    this.metadata = const <String, dynamic>{},
  });

  bool get isOpen =>
      status != ComplaintStatus.closed && status != ComplaintStatus.rejected;

  bool get isFinal => status.isFinal;

  bool get isAssigned => assignedAdminId.trim().isNotEmpty;

  bool get hasEvidence => evidenceUrls.isNotEmpty;

  bool get isSafetyComplaint =>
      category.requiresSafetyEscalation || safetyEscalationRequired;

  Duration get age => DateTime.now().difference(createdAt);

  static String generateTicketId({
    required FeedbackServiceType serviceType,
    DateTime? time,
    String suffix = '',
  }) {
    final now = time ?? DateTime.now();
    final cleanSuffix = suffix
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();

    final date =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';

    final milliseconds = now.millisecondsSinceEpoch.toString();
    final shortTime = milliseconds.substring(milliseconds.length - 6);

    final serviceCode = serviceType.value.toUpperCase();

    return cleanSuffix.isEmpty
        ? 'SWR-$serviceCode-$date-$shortTime'
        : 'SWR-$serviceCode-$date-$shortTime-$cleanSuffix';
  }

  void validate() {
    if (ticketId.trim().isEmpty) {
      throw const FormatException('Complaint ticket ID is required.');
    }

    if (sourceId.trim().isEmpty) {
      throw const FormatException('Service source ID is required.');
    }

    if (reporterId.trim().isEmpty) {
      throw const FormatException('Complaint reporter ID is required.');
    }

    if (targetId.trim().isEmpty) {
      throw const FormatException('Complaint target ID is required.');
    }

    if (title.trim().isEmpty) {
      throw const FormatException('Complaint title is required.');
    }

    if (title.trim().length > maximumTitleLength) {
      throw const FormatException(
        'Complaint title cannot exceed 150 characters.',
      );
    }

    if (description.trim().isEmpty) {
      throw const FormatException('Complaint description is required.');
    }

    if (description.trim().length > maximumDescriptionLength) {
      throw const FormatException(
        'Complaint description cannot exceed 3000 characters.',
      );
    }

    if (evidenceUrls.length > maximumEvidenceCount) {
      throw const FormatException(
        'A maximum of 10 evidence attachments is allowed.',
      );
    }

    if (updatedAt.isBefore(createdAt)) {
      throw const FormatException(
        'Updated date cannot be before created date.',
      );
    }

    if (assignedAt != null && assignedAdminId.trim().isEmpty) {
      throw const FormatException(
        'Assigned admin ID is required when assigned date exists.',
      );
    }

    if (safetyEscalationSent &&
        (safetyCaseId.trim().isEmpty || safetyEscalatedAt == null)) {
      throw const FormatException(
        'Safety case ID and escalation date are required.',
      );
    }

    if (status == ComplaintStatus.resolved &&
        (resolution.trim().isEmpty ||
            resolvedBy.trim().isEmpty ||
            resolvedAt == null)) {
      throw const FormatException(
        'Resolution, resolver and resolved date are required.',
      );
    }

    if (status == ComplaintStatus.closed && closedAt == null) {
      throw const FormatException(
        'Closed date is required for a closed complaint.',
      );
    }

    for (final history in statusHistory) {
      history.validate();
    }
  }

  ComplaintModel normalized() {
    final cleanEvidence = evidenceUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet()
        .take(maximumEvidenceCount)
        .toList(growable: false);

    final model = copyWith(
      id: id.trim(),
      ticketId: ticketId.trim().toUpperCase(),
      sourceId: sourceId.trim(),
      sourceReference: sourceReference.trim(),
      feedbackId: feedbackId.trim(),
      reporterId: reporterId.trim(),
      reporterName: reporterName.trim(),
      reporterPhone: reporterPhone.trim(),
      targetId: targetId.trim(),
      targetName: targetName.trim(),
      title: title.trim(),
      description: description.trim(),
      evidenceUrls: cleanEvidence,
      safetyCaseId: safetyCaseId.trim(),
      assignedAdminId: assignedAdminId.trim(),
      assignedAdminName: assignedAdminName.trim(),
      resolution: resolution.trim(),
      resolutionCode: resolutionCode.trim(),
      resolvedBy: resolvedBy.trim(),
      metadata: Map<String, dynamic>.unmodifiable(metadata),
    );

    model.validate();
    return model;
  }

  ComplaintModel transitionTo({
    required ComplaintStatus nextStatus,
    required String changedBy,
    required ComplaintActorType actorType,
    String note = '',
    String resolution = '',
    String resolutionCode = '',
    DateTime? changedAt,
  }) {
    final cleanChangedBy = changedBy.trim();

    if (cleanChangedBy.isEmpty) {
      throw const FormatException('Status changer ID is required.');
    }

    if (!status.canTransitionTo(nextStatus)) {
      throw StateError(
        'Complaint cannot move from ${status.displayName} '
        'to ${nextStatus.displayName}.',
      );
    }

    final time = changedAt ?? DateTime.now();
    final cleanResolution = resolution.trim();

    if (nextStatus == ComplaintStatus.resolved && cleanResolution.isEmpty) {
      throw const FormatException(
        'Resolution is required before resolving a complaint.',
      );
    }

    final history = ComplaintStatusHistory(
      status: nextStatus,
      changedBy: cleanChangedBy,
      actorType: actorType,
      note: note.trim(),
      changedAt: time,
    );

    return copyWith(
      status: nextStatus,
      resolution: nextStatus == ComplaintStatus.resolved
          ? cleanResolution
          : this.resolution,
      resolutionCode: nextStatus == ComplaintStatus.resolved
          ? resolutionCode.trim()
          : this.resolutionCode,
      resolvedBy: nextStatus == ComplaintStatus.resolved
          ? cleanChangedBy
          : resolvedBy,
      resolvedAt: nextStatus == ComplaintStatus.resolved ? time : resolvedAt,
      closedAt: nextStatus == ComplaintStatus.closed ? time : closedAt,
      updatedAt: time,
      statusHistory: <ComplaintStatusHistory>[...statusHistory, history],
    ).normalized();
  }

  Map<String, dynamic> toMap() {
    final model = normalized();

    return <String, dynamic>{
      'id': model.id,
      'ticketId': model.ticketId,
      'serviceType': model.serviceType.value,
      'sourceId': model.sourceId,
      'sourceReference': model.sourceReference,
      'feedbackId': model.feedbackId,
      'reporterId': model.reporterId,
      'reporterName': model.reporterName,
      'reporterPhone': model.reporterPhone,
      'targetType': model.targetType.value,
      'targetId': model.targetId,
      'targetName': model.targetName,
      'category': model.category.value,
      'priority': model.priority.value,
      'status': model.status.value,
      'title': model.title,
      'description': model.description,
      'evidenceUrls': model.evidenceUrls,
      'safetyEscalationRequired': model.safetyEscalationRequired,
      'safetyEscalationSent': model.safetyEscalationSent,
      'safetyCaseId': model.safetyCaseId,
      'safetyEscalatedAt': model.safetyEscalatedAt == null
          ? null
          : Timestamp.fromDate(model.safetyEscalatedAt!),
      'assignedAdminId': model.assignedAdminId,
      'assignedAdminName': model.assignedAdminName,
      'assignedAt': model.assignedAt == null
          ? null
          : Timestamp.fromDate(model.assignedAt!),
      'resolution': model.resolution,
      'resolutionCode': model.resolutionCode,
      'resolvedBy': model.resolvedBy,
      'resolvedAt': model.resolvedAt == null
          ? null
          : Timestamp.fromDate(model.resolvedAt!),
      'closedAt': model.closedAt == null
          ? null
          : Timestamp.fromDate(model.closedAt!),
      'createdAt': Timestamp.fromDate(model.createdAt),
      'updatedAt': Timestamp.fromDate(model.updatedAt),
      'statusHistory': model.statusHistory.map((item) => item.toMap()).toList(),
      'metadata': model.metadata,
    };
  }

  factory ComplaintModel.fromMap(
    Map<String, dynamic> map, {
    String documentId = '',
  }) {
    final category = ComplaintCategoryX.fromValue(map['category']);

    return ComplaintModel(
      id: _stringValue(map['id'], fallback: documentId),
      ticketId: _stringValue(map['ticketId']),
      serviceType: FeedbackServiceTypeX.fromValue(map['serviceType']),
      sourceId: _stringValue(
        map['sourceId'] ?? map['rideId'] ?? map['orderId'] ?? map['bookingId'],
      ),
      sourceReference: _stringValue(map['sourceReference']),
      feedbackId: _stringValue(map['feedbackId']),
      reporterId: _stringValue(map['reporterId'] ?? map['userId']),
      reporterName: _stringValue(map['reporterName'] ?? map['userName']),
      reporterPhone: _stringValue(map['reporterPhone']),
      targetType: FeedbackTargetTypeX.fromValue(map['targetType']),
      targetId: _stringValue(map['targetId']),
      targetName: _stringValue(map['targetName']),
      category: category,
      priority: map['priority'] == null
          ? category.recommendedPriority
          : ComplaintPriorityX.fromValue(map['priority']),
      status: ComplaintStatusX.fromValue(map['status']),
      title: _stringValue(map['title']),
      description: _stringValue(map['description']),
      evidenceUrls: _stringList(map['evidenceUrls']),
      safetyEscalationRequired:
          map['safetyEscalationRequired'] == true ||
          category.requiresSafetyEscalation,
      safetyEscalationSent: map['safetyEscalationSent'] == true,
      safetyCaseId: _stringValue(map['safetyCaseId']),
      safetyEscalatedAt: _dateTimeValue(map['safetyEscalatedAt']),
      assignedAdminId: _stringValue(map['assignedAdminId']),
      assignedAdminName: _stringValue(map['assignedAdminName']),
      assignedAt: _dateTimeValue(map['assignedAt']),
      resolution: _stringValue(map['resolution']),
      resolutionCode: _stringValue(map['resolutionCode']),
      resolvedBy: _stringValue(map['resolvedBy']),
      resolvedAt: _dateTimeValue(map['resolvedAt']),
      closedAt: _dateTimeValue(map['closedAt']),
      createdAt: _dateTimeValue(map['createdAt']) ?? DateTime.now(),
      updatedAt: _dateTimeValue(map['updatedAt']) ?? DateTime.now(),
      statusHistory: _historyList(map['statusHistory']),
      metadata: _dynamicMap(map['metadata']),
    );
  }

  factory ComplaintModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return ComplaintModel.fromMap(
      document.data() ?? const <String, dynamic>{},
      documentId: document.id,
    );
  }

  ComplaintModel copyWith({
    String? id,
    String? ticketId,
    FeedbackServiceType? serviceType,
    String? sourceId,
    String? sourceReference,
    String? feedbackId,
    String? reporterId,
    String? reporterName,
    String? reporterPhone,
    FeedbackTargetType? targetType,
    String? targetId,
    String? targetName,
    ComplaintCategory? category,
    ComplaintPriority? priority,
    ComplaintStatus? status,
    String? title,
    String? description,
    List<String>? evidenceUrls,
    bool? safetyEscalationRequired,
    bool? safetyEscalationSent,
    String? safetyCaseId,
    DateTime? safetyEscalatedAt,
    String? assignedAdminId,
    String? assignedAdminName,
    DateTime? assignedAt,
    String? resolution,
    String? resolutionCode,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? closedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ComplaintStatusHistory>? statusHistory,
    Map<String, dynamic>? metadata,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      serviceType: serviceType ?? this.serviceType,
      sourceId: sourceId ?? this.sourceId,
      sourceReference: sourceReference ?? this.sourceReference,
      feedbackId: feedbackId ?? this.feedbackId,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reporterPhone: reporterPhone ?? this.reporterPhone,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      targetName: targetName ?? this.targetName,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      safetyEscalationRequired:
          safetyEscalationRequired ?? this.safetyEscalationRequired,
      safetyEscalationSent: safetyEscalationSent ?? this.safetyEscalationSent,
      safetyCaseId: safetyCaseId ?? this.safetyCaseId,
      safetyEscalatedAt: safetyEscalatedAt ?? this.safetyEscalatedAt,
      assignedAdminId: assignedAdminId ?? this.assignedAdminId,
      assignedAdminName: assignedAdminName ?? this.assignedAdminName,
      assignedAt: assignedAt ?? this.assignedAt,
      resolution: resolution ?? this.resolution,
      resolutionCode: resolutionCode ?? this.resolutionCode,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statusHistory: statusHistory ?? this.statusHistory,
      metadata: metadata ?? this.metadata,
    );
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) {
      return const <String>[];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static List<ComplaintStatusHistory> _historyList(Object? value) {
    if (value is! Iterable) {
      return const <ComplaintStatusHistory>[];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => ComplaintStatusHistory.fromMap(
            item.map((key, entryValue) => MapEntry(key.toString(), entryValue)),
          ),
        )
        .toList(growable: false);
  }

  static Map<String, dynamic> _dynamicMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }

    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }

    return const <String, dynamic>{};
  }

  static DateTime? _dateTimeValue(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.tryParse(value.toString());
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ComplaintModel &&
            runtimeType == other.runtimeType &&
            id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ComplaintModel('
        'ticketId: $ticketId, '
        'serviceType: ${serviceType.value}, '
        'category: ${category.value}, '
        'priority: ${priority.value}, '
        'status: ${status.value}'
        ')';
  }
}
