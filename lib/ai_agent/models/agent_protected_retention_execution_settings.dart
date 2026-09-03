/// Owner/Super Admin controlled enablement settings for
/// protected-retention execution.
///
/// IMPORTANT:
/// - These settings do NOT themselves delete data.
/// - These settings do NOT provide Firestore delete capability.
/// - A real adapter must still be separately connected and audited.
class AgentProtectedRetentionExecutionSettings {
  final bool masterExecutionEnabled;
  final bool protectedDeletionEnabled;
  final bool emergencyStopActive;

  final bool requireApproval;
  final bool requireConsumedApproval;
  final bool requireExplicitFinalConfirmation;
  final bool requireAuditTrail;
  final bool requireSuperAdmin;

  final DateTime updatedAt;
  final String updatedBy;
  final String reason;

  const AgentProtectedRetentionExecutionSettings({
    required this.masterExecutionEnabled,
    required this.protectedDeletionEnabled,
    required this.emergencyStopActive,
    required this.requireApproval,
    required this.requireConsumedApproval,
    required this.requireExplicitFinalConfirmation,
    required this.requireAuditTrail,
    required this.requireSuperAdmin,
    required this.updatedAt,
    required this.updatedBy,
    required this.reason,
  });

  factory AgentProtectedRetentionExecutionSettings.safeDefaults({
    required String ownerId,
    DateTime? now,
  }) {
    return AgentProtectedRetentionExecutionSettings(
      masterExecutionEnabled: false,
      protectedDeletionEnabled: false,
      emergencyStopActive: false,
      requireApproval: true,
      requireConsumedApproval: true,
      requireExplicitFinalConfirmation: true,
      requireAuditTrail: true,
      requireSuperAdmin: true,
      updatedAt: now ?? DateTime.now(),
      updatedBy: ownerId.trim(),
      reason: 'Safe defaults: protected retention execution remains disabled.',
    );
  }

  factory AgentProtectedRetentionExecutionSettings.fromMap(
    Map<String, dynamic> map, {
    required String fallbackOwnerId,
  }) {
    DateTime readDate(dynamic value) {
      if (value is DateTime) {
        return value;
      }

      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }

      try {
        final dynamic converted = value?.toDate();

        if (converted is DateTime) {
          return converted;
        }
      } catch (_) {
        // Safe fallback below.
      }

      return DateTime.now();
    }

    return AgentProtectedRetentionExecutionSettings(
      masterExecutionEnabled: map['masterExecutionEnabled'] == true,
      protectedDeletionEnabled: map['protectedDeletionEnabled'] == true,
      emergencyStopActive: map['emergencyStopActive'] == true,
      requireApproval: map['requireApproval'] != false,
      requireConsumedApproval: map['requireConsumedApproval'] != false,
      requireExplicitFinalConfirmation:
          map['requireExplicitFinalConfirmation'] != false,
      requireAuditTrail: map['requireAuditTrail'] != false,
      requireSuperAdmin: map['requireSuperAdmin'] != false,
      updatedAt: readDate(map['updatedAt']),
      updatedBy: (map['updatedBy'] ?? fallbackOwnerId).toString().trim(),
      reason:
          (map['reason'] ??
                  'Safe fallback: protected execution remains controlled.')
              .toString()
              .trim(),
    );
  }
  bool get failClosed =>
      !masterExecutionEnabled ||
      !protectedDeletionEnabled ||
      emergencyStopActive;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'masterExecutionEnabled': masterExecutionEnabled,
      'protectedDeletionEnabled': protectedDeletionEnabled,
      'emergencyStopActive': emergencyStopActive,
      'requireApproval': requireApproval,
      'requireConsumedApproval': requireConsumedApproval,
      'requireExplicitFinalConfirmation': requireExplicitFinalConfirmation,
      'requireAuditTrail': requireAuditTrail,
      'requireSuperAdmin': requireSuperAdmin,
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedBy.trim(),
      'reason': reason.trim(),
    };
  }
}
