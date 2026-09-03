import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_dispatcher_constants.dart';

// =========================================================
// AI AGENT — DISPATCHER WORKER MODEL
// =========================================================
//
// A worker advertises its roles/modules and sends heartbeats.
// Dispatcher may assign work only when:
// - worker is enabled
// - status accepts tasks
// - heartbeat is fresh
// - capacity is available
// - task role/module is supported

class AgentWorker {
  final String workerId;
  final String name;
  final String workerType;
  final String status;
  final String? providerId;
  final List<String> supportedRoleIds;
  final List<String> supportedModules;
  final List<String> currentTaskIds;
  final int maxConcurrentTasks;
  final bool enabled;
  final DateTime lastHeartbeatAt;
  final DateTime registeredAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const AgentWorker({
    required this.workerId,
    required this.name,
    required this.workerType,
    required this.status,
    required this.supportedRoleIds,
    required this.supportedModules,
    required this.currentTaskIds,
    required this.maxConcurrentTasks,
    required this.enabled,
    required this.lastHeartbeatAt,
    required this.registeredAt,
    required this.updatedAt,
    required this.metadata,
    this.providerId,
  });

  bool get isAtCapacity =>
      currentTaskIds.length >= maxConcurrentTasks;

  bool isStale({
    DateTime? now,
    Duration staleAfter = const Duration(minutes: 2),
  }) {
    final DateTime effectiveNow =
        (now ?? DateTime.now()).toUtc();

    return !lastHeartbeatAt
        .toUtc()
        .add(staleAfter)
        .isAfter(effectiveNow);
  }

  bool supports({
    required String roleId,
    required String module,
  }) {
    return supportedRoleIds.contains(roleId) &&
        supportedModules.contains(module);
  }

  bool canAcceptTask({
    required String roleId,
    required String module,
    DateTime? now,
  }) {
    return enabled &&
        AgentWorkerStatus.canAcceptTask(status) &&
        !isAtCapacity &&
        !isStale(now: now) &&
        supports(roleId: roleId, module: module);
  }

  void validate() {
    if (workerId.trim().isEmpty) {
      throw const AgentWorkerException(
        'workerId is required.',
      );
    }

    if (name.trim().isEmpty) {
      throw const AgentWorkerException(
        'Worker name is required.',
      );
    }

    if (!AgentWorkerType.isValid(workerType)) {
      throw AgentWorkerException(
        'Invalid workerType: $workerType',
      );
    }

    if (!AgentWorkerStatus.isValid(status)) {
      throw AgentWorkerException(
        'Invalid worker status: $status',
      );
    }

    if (supportedRoleIds.isEmpty) {
      throw const AgentWorkerException(
        'At least one supported role is required.',
      );
    }

    if (supportedModules.isEmpty) {
      throw const AgentWorkerException(
        'At least one supported module is required.',
      );
    }

    if (supportedRoleIds.length >
        AgentDispatcherDefaults.maximumRoleCount) {
      throw const AgentWorkerException(
        'Worker has too many supported roles.',
      );
    }

    if (supportedModules.length >
        AgentDispatcherDefaults.maximumModuleCount) {
      throw const AgentWorkerException(
        'Worker has too many supported modules.',
      );
    }

    if (maxConcurrentTasks < 1 ||
        maxConcurrentTasks >
            AgentDispatcherDefaults.maximumConcurrentTasks) {
      throw AgentWorkerException(
        'maxConcurrentTasks must be between 1 and '
        '${AgentDispatcherDefaults.maximumConcurrentTasks}.',
      );
    }

    if (currentTaskIds.length > maxConcurrentTasks) {
      throw const AgentWorkerException(
        'Current task count exceeds worker capacity.',
      );
    }

    if (providerId != null && providerId!.trim().isEmpty) {
      throw const AgentWorkerException(
        'providerId cannot be blank.',
      );
    }

    _validateUniqueNonEmpty(
      supportedRoleIds,
      fieldName: 'supportedRoleIds',
    );

    _validateUniqueNonEmpty(
      supportedModules,
      fieldName: 'supportedModules',
    );

    _validateUniqueNonEmpty(
      currentTaskIds,
      fieldName: 'currentTaskIds',
    );
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'workerId': workerId,
      'name': name,
      'workerType': workerType,
      'status': status,
      'providerId': providerId,
      'supportedRoleIds': supportedRoleIds,
      'supportedModules': supportedModules,
      'currentTaskIds': currentTaskIds,
      'activeTaskCount': currentTaskIds.length,
      'maxConcurrentTasks': maxConcurrentTasks,
      'enabled': enabled,
      'lastHeartbeatAt': Timestamp.fromDate(lastHeartbeatAt),
      'registeredAt': Timestamp.fromDate(registeredAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  factory AgentWorker.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    final AgentWorker worker = AgentWorker(
      workerId: _readString(
        map['workerId'],
        fallback: documentId,
      ),
      name: _readString(map['name']),
      workerType: _readString(map['workerType']),
      status: _readString(map['status']),
      providerId: _readNullableString(map['providerId']),
      supportedRoleIds:
          _readStringList(map['supportedRoleIds']),
      supportedModules:
          _readStringList(map['supportedModules']),
      currentTaskIds:
          _readStringList(map['currentTaskIds']),
      maxConcurrentTasks: _readInt(
        map['maxConcurrentTasks'],
        fallback:
            AgentDispatcherDefaults.defaultMaxConcurrentTasks,
      ),
      enabled: map['enabled'] == true,
      lastHeartbeatAt:
          _readDateTime(map['lastHeartbeatAt']) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      registeredAt: _readDateTime(map['registeredAt']) ??
          DateTime.now().toUtc(),
      updatedAt: _readDateTime(map['updatedAt']) ??
          DateTime.now().toUtc(),
      metadata: _readMap(map['metadata']),
    );

    worker.validate();
    return worker;
  }

  AgentWorker copyWith({
    String? workerId,
    String? name,
    String? workerType,
    String? status,
    String? providerId,
    List<String>? supportedRoleIds,
    List<String>? supportedModules,
    List<String>? currentTaskIds,
    int? maxConcurrentTasks,
    bool? enabled,
    DateTime? lastHeartbeatAt,
    DateTime? registeredAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    bool clearProviderId = false,
  }) {
    return AgentWorker(
      workerId: workerId ?? this.workerId,
      name: name ?? this.name,
      workerType: workerType ?? this.workerType,
      status: status ?? this.status,
      providerId:
          clearProviderId ? null : providerId ?? this.providerId,
      supportedRoleIds:
          supportedRoleIds ?? this.supportedRoleIds,
      supportedModules:
          supportedModules ?? this.supportedModules,
      currentTaskIds: currentTaskIds ?? this.currentTaskIds,
      maxConcurrentTasks:
          maxConcurrentTasks ?? this.maxConcurrentTasks,
      enabled: enabled ?? this.enabled,
      lastHeartbeatAt:
          lastHeartbeatAt ?? this.lastHeartbeatAt,
      registeredAt: registeredAt ?? this.registeredAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  static void _validateUniqueNonEmpty(
    List<String> values, {
    required String fieldName,
  }) {
    if (values.any((String value) => value.trim().isEmpty)) {
      throw AgentWorkerException(
        '$fieldName cannot contain blank values.',
      );
    }

    if (values.toSet().length != values.length) {
      throw AgentWorkerException(
        '$fieldName cannot contain duplicates.',
      );
    }
  }

  static String _readString(
    dynamic value, {
    String? fallback,
  }) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return fallback?.trim() ?? '';
  }

  static String? _readNullableString(dynamic value) {
    if (value is! String) return null;

    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const <String>[];

    return List<String>.unmodifiable(
      value
          .whereType<String>()
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty),
    );
  }

  static int _readInt(
    dynamic value, {
    required int fallback,
  }) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.unmodifiable(value);
    }

    return const <String, dynamic>{};
  }
}

class AgentWorkerException implements Exception {
  final String message;

  const AgentWorkerException(this.message);

  @override
  String toString() => 'AgentWorkerException: $message';
}