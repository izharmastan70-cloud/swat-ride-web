import '../constants/agent_production_rollout_snapshot_constants.dart';

class AgentProductionRolloutSnapshot {
  AgentProductionRolloutSnapshot({
    required this.source,
    required this.capturedAtUtc,
    required this.snapshotFingerprintSha256,
    required this.phase65SafetyEvidenceSha256,
    required this.phase62VersionEvidenceSha256,
    required this.masterSettingsProjection,
    required this.roleControlProjections,
  }) {
    validate();
  }

  final String source;
  final DateTime capturedAtUtc;

  final String snapshotFingerprintSha256;
  final String phase65SafetyEvidenceSha256;
  final String phase62VersionEvidenceSha256;

  /// Operational AI control-plane metadata only.
  final Map<String, dynamic> masterSettingsProjection;

  /// Sorted role authority/control projections only.
  final List<Map<String, dynamic>> roleControlProjections;

  bool get liveReadOnlySnapshot => true;
  bool get containsRawSecrets => false;
  bool get containsAuthTokens => false;
  bool get containsPaymentCredentials => false;
  bool get containsPrivateCustomerPayload => false;

  bool get masterEnabled => masterSettingsProjection['masterEnabled'] == true;

  bool get emergencyReadOnly =>
      masterSettingsProjection['emergencyReadOnly'] == true;

  bool get approvalEngineEnabled =>
      masterSettingsProjection['approvalEngineEnabled'] == true;

  bool get auditLoggingEnabled =>
      masterSettingsProjection['auditLoggingEnabled'] == true;

  bool get anyEnabledAutoRole {
    for (final Map<String, dynamic> role in roleControlProjections) {
      if (role['enabled'] == true && role['mode'] == 'AUTO') {
        return true;
      }
    }
    return false;
  }

  int get roleCount => roleControlProjections.length;

  void validate() {
    final RegExp sha256 = RegExp(r'^[A-Fa-f0-9]{64}$');

    if (source != AgentProductionRolloutSnapshotSource.liveFirestore ||
        !capturedAtUtc.isUtc ||
        !sha256.hasMatch(snapshotFingerprintSha256) ||
        !sha256.hasMatch(phase65SafetyEvidenceSha256) ||
        !sha256.hasMatch(phase62VersionEvidenceSha256) ||
        masterSettingsProjection.isEmpty) {
      throw const FormatException('Invalid production rollout snapshot.');
    }

    String previousRoleId = '';
    for (final Map<String, dynamic> role in roleControlProjections) {
      final String roleId = (role['roleId'] ?? '').toString().trim();
      final String mode = (role['mode'] ?? '').toString().trim();

      if (roleId.isEmpty || mode.isEmpty) {
        throw const FormatException(
          'Incomplete role projection in production rollout snapshot.',
        );
      }

      if (previousRoleId.isNotEmpty && roleId.compareTo(previousRoleId) <= 0) {
        throw const FormatException(
          'Role projections must be unique and sorted by roleId.',
        );
      }
      previousRoleId = roleId;
    }
  }
}
