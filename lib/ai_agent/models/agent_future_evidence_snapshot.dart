class AgentFutureEvidenceSourceStatus {
  AgentFutureEvidenceSourceStatus._();

  static const String available = 'AVAILABLE';
  static const String unavailable = 'UNAVAILABLE';
  static const String notConnected = 'NOT_CONNECTED';
  static const String disabled = 'DISABLED';

  static const Set<String> values = <String>{
    available,
    unavailable,
    notConnected,
    disabled,
  };

  static bool isValid(String value) => values.contains(value);
}

/// One privacy-minimized read-only evidence source summary.
///
/// This never contains raw OTP values, auth tokens, precise GPS coordinates,
/// payment secrets, or arbitrary Firestore documents.
class AgentFutureEvidenceSourceSnapshot {
  const AgentFutureEvidenceSourceSnapshot({
    required this.sourceId,
    required this.module,
    required this.status,
    required this.evidenceRefs,
    required this.affectedUserCount,
    required this.affectedEventCount,
    required this.summary,
    required this.capturedAt,
  });

  final String sourceId;
  final String module;
  final String status;
  final List<String> evidenceRefs;
  final int affectedUserCount;
  final int affectedEventCount;
  final String summary;
  final DateTime capturedAt;

  bool get isAvailable => status == AgentFutureEvidenceSourceStatus.available;

  void validate() {
    if (sourceId.trim().isEmpty) {
      throw const AgentFutureEvidenceSnapshotValidationException(
        'sourceId cannot be empty.',
      );
    }

    if (module.trim().isEmpty) {
      throw const AgentFutureEvidenceSnapshotValidationException(
        'module cannot be empty.',
      );
    }

    if (!AgentFutureEvidenceSourceStatus.isValid(status)) {
      throw AgentFutureEvidenceSnapshotValidationException(
        'Unsupported evidence source status: $status',
      );
    }

    if (affectedUserCount < 0 || affectedEventCount < 0) {
      throw const AgentFutureEvidenceSnapshotValidationException(
        'Affected user/event counts cannot be negative.',
      );
    }

    if (isAvailable && evidenceRefs.isEmpty) {
      throw const AgentFutureEvidenceSnapshotValidationException(
        'Available evidence source requires at least one evidence reference.',
      );
    }

    if (summary.trim().isEmpty) {
      throw const AgentFutureEvidenceSnapshotValidationException(
        'summary cannot be empty.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'sourceId': sourceId,
      'module': module,
      'status': status,
      'evidenceRefs': List<String>.from(evidenceRefs),
      'affectedUserCount': affectedUserCount,
      'affectedEventCount': affectedEventCount,
      'summary': summary,
      'capturedAt': capturedAt.toUtc().toIso8601String(),
      'readOnly': true,
      'privacyMinimized': true,
    };
  }

  factory AgentFutureEvidenceSourceSnapshot.fromMap(Map<String, dynamic> map) {
    final AgentFutureEvidenceSourceSnapshot
    snapshot = AgentFutureEvidenceSourceSnapshot(
      sourceId: (map['sourceId'] ?? '').toString(),
      module: (map['module'] ?? '').toString(),
      status: (map['status'] ?? AgentFutureEvidenceSourceStatus.notConnected)
          .toString(),
      evidenceRefs: _stringList(map['evidenceRefs']),
      affectedUserCount: _intValue(map['affectedUserCount']),
      affectedEventCount: _intValue(map['affectedEventCount']),
      summary: (map['summary'] ?? 'Evidence source unavailable.').toString(),
      capturedAt: _dateTimeValue(map['capturedAt']),
    );

    snapshot.validate();
    return snapshot;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! Iterable) {
      return const <String>[];
    }

    return value
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _dateTimeValue(dynamic value) {
    if (value is DateTime) {
      return value.toUtc();
    }

    return DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}

/// Aggregated Phase 41 evidence window.
///
/// Counts are best-known counts from read-only sources. Missing/unconnected
/// sources remain explicit and are never replaced with invented values.
class AgentFutureEvidenceSnapshot {
  const AgentFutureEvidenceSnapshot({
    required this.snapshotId,
    required this.windowStart,
    required this.windowEnd,
    required this.sources,
    required this.createdAt,
  });

  final String snapshotId;
  final DateTime windowStart;
  final DateTime windowEnd;
  final List<AgentFutureEvidenceSourceSnapshot> sources;
  final DateTime createdAt;

  List<AgentFutureEvidenceSourceSnapshot> get availableSources => sources
      .where((AgentFutureEvidenceSourceSnapshot source) => source.isAvailable)
      .toList(growable: false);

  List<AgentFutureEvidenceSourceSnapshot> get unavailableSources => sources
      .where((AgentFutureEvidenceSourceSnapshot source) => !source.isAvailable)
      .toList(growable: false);

  int get totalAffectedUserCount => sources.fold<int>(
    0,
    (int total, AgentFutureEvidenceSourceSnapshot source) =>
        total + source.affectedUserCount,
  );

  int get totalAffectedEventCount => sources.fold<int>(
    0,
    (int total, AgentFutureEvidenceSourceSnapshot source) =>
        total + source.affectedEventCount,
  );

  List<String> get evidenceRefs => sources
      .expand((AgentFutureEvidenceSourceSnapshot source) => source.evidenceRefs)
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);

  bool get hasAnyAvailableEvidence => availableSources.isNotEmpty;

  void validate() {
    if (snapshotId.trim().isEmpty) {
      throw const AgentFutureEvidenceSnapshotValidationException(
        'snapshotId cannot be empty.',
      );
    }

    if (windowEnd.isBefore(windowStart)) {
      throw const AgentFutureEvidenceSnapshotValidationException(
        'windowEnd cannot be before windowStart.',
      );
    }

    final Set<String> sourceIds = <String>{};

    for (final AgentFutureEvidenceSourceSnapshot source in sources) {
      source.validate();

      if (!sourceIds.add(source.sourceId.trim())) {
        throw AgentFutureEvidenceSnapshotValidationException(
          'Duplicate evidence sourceId: ${source.sourceId}',
        );
      }
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'snapshotId': snapshotId,
      'windowStart': windowStart.toUtc().toIso8601String(),
      'windowEnd': windowEnd.toUtc().toIso8601String(),
      'sources': sources
          .map((AgentFutureEvidenceSourceSnapshot source) => source.toMap())
          .toList(growable: false),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'totalAffectedUserCount': totalAffectedUserCount,
      'totalAffectedEventCount': totalAffectedEventCount,
      'readOnly': true,
      'recommendationOnly': true,
    };
  }
}

class AgentFutureEvidenceSnapshotValidationException implements Exception {
  const AgentFutureEvidenceSnapshotValidationException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentFutureEvidenceSnapshotValidationException: $message';
}
