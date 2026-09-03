import '../models/agent_retention_owner_settings.dart';

/// Validates Owner retention preferences.
///
/// IMPORTANT:
/// - No Firestore access.
/// - No delete authority.
/// - No cleanup execution.
/// - Protected audit/security/finance evidence is outside this
///   generic owner-adjustable retention path.
abstract final class AgentRetentionOwnerControlService {
  static const int minimumTransientRetentionDays = 7;
  static const int maximumTransientRetentionDays = 3650;

  static AgentRetentionOwnerSettings validateAndNormalize(
    AgentRetentionOwnerSettings input,
  ) {
    final String ownerId = input.updatedBy.trim();

    if (ownerId.isEmpty) {
      throw ArgumentError(
        'Owner ID is required for retention setting changes.',
      );
    }

    return input.copyWith(
      callSessionDays: _safeDays(input.callSessionDays),
      supportContextDays: _safeDays(input.supportContextDays),
      crashEventDays: _safeDays(input.crashEventDays),
      approvalDays: _safeDays(input.approvalDays),
      completedTaskDays: _safeDays(input.completedTaskDays),
      taskIdempotencyDays: _safeDays(input.taskIdempotencyDays),
      providerHealthDays: _safeDays(input.providerHealthDays),
      updatedBy: ownerId,
    );
  }

  static bool canRequestCleanup(AgentRetentionOwnerSettings settings) {
    final AgentRetentionOwnerSettings normalized = validateAndNormalize(
      settings,
    );

    return normalized.cleanupRequested;
  }

  static bool canExecuteDeletion(AgentRetentionOwnerSettings settings) {
    // Phase 37 safety:
    // Owner preference alone can NEVER execute deletion.
    return false;
  }

  static bool canOverrideProtectedEvidenceRetention() {
    // Audit/security/finance evidence is not controlled by
    // generic transient-retention preferences.
    return false;
  }

  static int _safeDays(int value) {
    if (value < minimumTransientRetentionDays) {
      return minimumTransientRetentionDays;
    }

    if (value > maximumTransientRetentionDays) {
      return maximumTransientRetentionDays;
    }

    return value;
  }
}
