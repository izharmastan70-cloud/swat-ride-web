import '../models/agent_protected_retention_execution_settings.dart';
import 'agent_protected_retention_execution_settings_service.dart';

/// Owner/Super Admin management layer for protected-retention
/// execution settings.
///
/// This service intentionally exposes ONLY operational controls:
/// - master execution ON/OFF;
/// - protected deletion enablement ON/OFF;
/// - emergency stop ON/OFF;
/// - reason.
///
/// Mandatory safety guards remain permanently TRUE through this
/// management layer.
///
/// IMPORTANT:
/// This service does NOT delete protected data.
/// It does NOT expose a Firestore delete API.
/// It does NOT grant destructive execution authority.
class AgentProtectedRetentionExecutionManagementService {
  final AgentProtectedRetentionExecutionSettingsService settingsService;

  const AgentProtectedRetentionExecutionManagementService({
    required this.settingsService,
  });

  Future<AgentProtectedRetentionExecutionSettings> getCurrentSettings({
    required String ownerId,
  }) {
    return settingsService.getSettings(ownerId: ownerId);
  }

  Future<AgentProtectedRetentionExecutionSettings> setMasterExecution({
    required String ownerId,
    required bool enabled,
    required String reason,
  }) async {
    final AgentProtectedRetentionExecutionSettings current =
        await _loadForUpdate(ownerId: ownerId);

    final AgentProtectedRetentionExecutionSettings updated = _safeCopy(
      current: current,
      ownerId: ownerId,
      reason: reason,
      masterExecutionEnabled: enabled,
    );

    await settingsService.saveSettings(settings: updated);

    return updated;
  }

  Future<AgentProtectedRetentionExecutionSettings> setProtectedDeletion({
    required String ownerId,
    required bool enabled,
    required String reason,
  }) async {
    final AgentProtectedRetentionExecutionSettings current =
        await _loadForUpdate(ownerId: ownerId);

    final AgentProtectedRetentionExecutionSettings updated = _safeCopy(
      current: current,
      ownerId: ownerId,
      reason: reason,
      protectedDeletionEnabled: enabled,
    );

    await settingsService.saveSettings(settings: updated);

    return updated;
  }

  Future<AgentProtectedRetentionExecutionSettings> setEmergencyStop({
    required String ownerId,
    required bool active,
    required String reason,
  }) async {
    final AgentProtectedRetentionExecutionSettings current =
        await _loadForUpdate(ownerId: ownerId);

    final AgentProtectedRetentionExecutionSettings updated = _safeCopy(
      current: current,
      ownerId: ownerId,
      reason: reason,
      emergencyStopActive: active,
    );

    await settingsService.saveSettings(settings: updated);

    return updated;
  }

  /// Convenience hard-stop action.
  ///
  /// This turns:
  /// - Emergency Stop ON
  /// - Master execution OFF
  /// - Protected deletion OFF
  ///
  /// in one persisted settings update.
  Future<AgentProtectedRetentionExecutionSettings> emergencyDisableAll({
    required String ownerId,
    required String reason,
  }) async {
    final AgentProtectedRetentionExecutionSettings current =
        await _loadForUpdate(ownerId: ownerId);

    final AgentProtectedRetentionExecutionSettings updated = _safeCopy(
      current: current,
      ownerId: ownerId,
      reason: reason,
      masterExecutionEnabled: false,
      protectedDeletionEnabled: false,
      emergencyStopActive: true,
    );

    await settingsService.saveSettings(settings: updated);

    return updated;
  }

  Future<AgentProtectedRetentionExecutionSettings> _loadForUpdate({
    required String ownerId,
  }) async {
    final String safeOwnerId = ownerId.trim();

    if (safeOwnerId.isEmpty) {
      throw ArgumentError('Owner/Super Admin ID is required.');
    }

    return settingsService.getSettings(ownerId: safeOwnerId);
  }

  static AgentProtectedRetentionExecutionSettings _safeCopy({
    required AgentProtectedRetentionExecutionSettings current,
    required String ownerId,
    required String reason,
    bool? masterExecutionEnabled,
    bool? protectedDeletionEnabled,
    bool? emergencyStopActive,
  }) {
    final String safeOwnerId = ownerId.trim();

    final String safeReason = reason.trim();

    if (safeOwnerId.isEmpty) {
      throw ArgumentError('Owner/Super Admin ID is required.');
    }

    if (safeReason.length < 10) {
      throw ArgumentError(
        'A meaningful reason of at least 10 characters is required.',
      );
    }

    return AgentProtectedRetentionExecutionSettings(
      masterExecutionEnabled:
          masterExecutionEnabled ?? current.masterExecutionEnabled,
      protectedDeletionEnabled:
          protectedDeletionEnabled ?? current.protectedDeletionEnabled,
      emergencyStopActive: emergencyStopActive ?? current.emergencyStopActive,

      // Mandatory immutable safety guards.
      requireApproval: true,
      requireConsumedApproval: true,
      requireExplicitFinalConfirmation: true,
      requireAuditTrail: true,
      requireSuperAdmin: true,

      updatedAt: DateTime.now(),
      updatedBy: safeOwnerId,
      reason: safeReason,
    );
  }
}
