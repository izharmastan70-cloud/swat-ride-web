/// Owner-controlled retention preferences.
///
/// IMPORTANT:
/// - These are preferences only.
/// - They do NOT authorize Firestore deletion.
/// - Protected finance/audit/security evidence cannot be made
///   generically deletable by these settings.
class AgentRetentionOwnerSettings {
  final bool cleanupRequested;

  final int callSessionDays;
  final int supportContextDays;
  final int crashEventDays;
  final int approvalDays;
  final int completedTaskDays;
  final int taskIdempotencyDays;
  final int providerHealthDays;

  final DateTime updatedAt;
  final String updatedBy;

  const AgentRetentionOwnerSettings({
    required this.cleanupRequested,
    required this.callSessionDays,
    required this.supportContextDays,
    required this.crashEventDays,
    required this.approvalDays,
    required this.completedTaskDays,
    required this.taskIdempotencyDays,
    required this.providerHealthDays,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory AgentRetentionOwnerSettings.safeDefaults({
    required String ownerId,
    DateTime? now,
  }) {
    return AgentRetentionOwnerSettings(
      cleanupRequested: false,
      callSessionDays: 30,
      supportContextDays: 90,
      crashEventDays: 90,
      approvalDays: 180,
      completedTaskDays: 90,
      taskIdempotencyDays: 30,
      providerHealthDays: 30,
      updatedAt: now ?? DateTime.now(),
      updatedBy: ownerId.trim(),
    );
  }

  AgentRetentionOwnerSettings copyWith({
    bool? cleanupRequested,
    int? callSessionDays,
    int? supportContextDays,
    int? crashEventDays,
    int? approvalDays,
    int? completedTaskDays,
    int? taskIdempotencyDays,
    int? providerHealthDays,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return AgentRetentionOwnerSettings(
      cleanupRequested: cleanupRequested ?? this.cleanupRequested,
      callSessionDays: callSessionDays ?? this.callSessionDays,
      supportContextDays: supportContextDays ?? this.supportContextDays,
      crashEventDays: crashEventDays ?? this.crashEventDays,
      approvalDays: approvalDays ?? this.approvalDays,
      completedTaskDays: completedTaskDays ?? this.completedTaskDays,
      taskIdempotencyDays: taskIdempotencyDays ?? this.taskIdempotencyDays,
      providerHealthDays: providerHealthDays ?? this.providerHealthDays,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'cleanupRequested': cleanupRequested,
      'callSessionDays': callSessionDays,
      'supportContextDays': supportContextDays,
      'crashEventDays': crashEventDays,
      'approvalDays': approvalDays,
      'completedTaskDays': completedTaskDays,
      'taskIdempotencyDays': taskIdempotencyDays,
      'providerHealthDays': providerHealthDays,
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }
}
