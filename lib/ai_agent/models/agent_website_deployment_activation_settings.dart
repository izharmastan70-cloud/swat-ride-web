import 'package:cloud_firestore/cloud_firestore.dart';

/// Phase 34 Step 3D-E3D2A.
///
/// Owner-controlled website deployment activation settings.
///
/// This contract controls whether the deployment subsystem may even
/// consider live provider execution.
///
/// IMPORTANT:
/// This model contains NO:
/// - GitHub token;
/// - Vercel token;
/// - password/private key;
/// - shell command;
/// - DNS/domain credential.
///
/// Safe default is fully OFF.
///
/// Live production execution must still separately satisfy:
/// - AI Master/runtime gates;
/// - provider relationship readiness;
/// - exact production approval;
/// - exact complete backup scope;
/// - deployment adapter safety;
/// - later execution-provider authority.
///
/// Turning this setting ON must never by itself execute a deployment.
class AgentWebsiteDeploymentActivationSettings {
  static const String documentId = 'website_deployment_activation';

  /// Owner-level master switch for the website deployment subsystem.
  final bool deploymentEnabled;

  /// Allows Git-connected provider selection.
  final bool gitConnectedProviderEnabled;

  /// Owner intent that Git push authority may be considered.
  ///
  /// This does NOT itself provide Git credentials or execute a push.
  final bool livePushActivationApproved;

  /// Owner intent that production deployment authority may be considered.
  ///
  /// This does NOT itself execute Vercel deployment.
  final bool liveDeploymentActivationApproved;

  /// Emergency/manual freeze for website deployment only.
  final bool emergencyBlocked;

  /// Human-readable reason for the current activation state.
  final String reason;

  /// Owner/admin identity that last changed this activation contract.
  final String updatedBy;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const AgentWebsiteDeploymentActivationSettings({
    required this.deploymentEnabled,
    required this.gitConnectedProviderEnabled,
    required this.livePushActivationApproved,
    required this.liveDeploymentActivationApproved,
    required this.emergencyBlocked,
    required this.reason,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AgentWebsiteDeploymentActivationSettings.safeDefaults() {
    return AgentWebsiteDeploymentActivationSettings(
      deploymentEnabled: false,
      gitConnectedProviderEnabled: false,
      livePushActivationApproved: false,
      liveDeploymentActivationApproved: false,
      emergencyBlocked: false,
      reason: 'Safe default. Owner has not enabled website deployment.',
      updatedBy: '',
      createdAt: DateTime.now(),
      updatedAt: null,
    );
  }

  /// Base subsystem readiness only.
  ///
  /// This is NOT permission to execute production deployment.
  bool get deploymentSubsystemReady => deploymentEnabled && !emergencyBlocked;

  /// Provider-selection readiness only.
  ///
  /// This is NOT live execution authority.
  bool get gitConnectedProviderAllowed =>
      deploymentSubsystemReady && gitConnectedProviderEnabled;

  /// Owner activation intent for later live execution.
  ///
  /// Even when true, production execution still requires all existing
  /// approval, backup, provider, and execution-authority gates.
  bool get ownerLiveActivationApproved =>
      gitConnectedProviderAllowed &&
      livePushActivationApproved &&
      liveDeploymentActivationApproved;

  AgentWebsiteDeploymentActivationSettings copyWith({
    bool? deploymentEnabled,
    bool? gitConnectedProviderEnabled,
    bool? livePushActivationApproved,
    bool? liveDeploymentActivationApproved,
    bool? emergencyBlocked,
    String? reason,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final AgentWebsiteDeploymentActivationSettings next =
        AgentWebsiteDeploymentActivationSettings(
          deploymentEnabled: deploymentEnabled ?? this.deploymentEnabled,
          gitConnectedProviderEnabled:
              gitConnectedProviderEnabled ?? this.gitConnectedProviderEnabled,
          livePushActivationApproved:
              livePushActivationApproved ?? this.livePushActivationApproved,
          liveDeploymentActivationApproved:
              liveDeploymentActivationApproved ??
              this.liveDeploymentActivationApproved,
          emergencyBlocked: emergencyBlocked ?? this.emergencyBlocked,
          reason: reason ?? this.reason,
          updatedBy: updatedBy ?? this.updatedBy,
          createdAt: createdAt ?? this.createdAt,
          updatedAt: updatedAt ?? this.updatedAt,
        );

    next.validate();
    return next;
  }

  void validate() {
    final String safeReason = reason.trim();

    final String safeUpdatedBy = updatedBy.trim();

    if (!deploymentEnabled) {
      if (gitConnectedProviderEnabled ||
          livePushActivationApproved ||
          liveDeploymentActivationApproved) {
        throw const AgentWebsiteDeploymentActivationSettingsException(
          'Website deployment master OFF requires all provider/live activation flags to remain OFF.',
        );
      }
    }

    if (!gitConnectedProviderEnabled &&
        (livePushActivationApproved || liveDeploymentActivationApproved)) {
      throw const AgentWebsiteDeploymentActivationSettingsException(
        'Live activation cannot be approved while Git-connected provider is disabled.',
      );
    }

    if (livePushActivationApproved != liveDeploymentActivationApproved) {
      throw const AgentWebsiteDeploymentActivationSettingsException(
        'Live Git push and live deployment activation approvals must change together.',
      );
    }

    if (emergencyBlocked &&
        (livePushActivationApproved || liveDeploymentActivationApproved)) {
      throw const AgentWebsiteDeploymentActivationSettingsException(
        'Emergency block requires live activation approvals to be OFF.',
      );
    }

    if (deploymentEnabled && safeReason.isEmpty) {
      throw const AgentWebsiteDeploymentActivationSettingsException(
        'Enabling website deployment requires a reason.',
      );
    }

    if (deploymentEnabled && safeUpdatedBy.isEmpty) {
      throw const AgentWebsiteDeploymentActivationSettingsException(
        'Enabling website deployment requires updatedBy.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'deploymentEnabled': deploymentEnabled,
      'gitConnectedProviderEnabled': gitConnectedProviderEnabled,
      'livePushActivationApproved': livePushActivationApproved,
      'liveDeploymentActivationApproved': liveDeploymentActivationApproved,
      'emergencyBlocked': emergencyBlocked,
      'reason': reason.trim(),
      'updatedBy': updatedBy.trim(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory AgentWebsiteDeploymentActivationSettings.fromMap(
    Map<String, dynamic> map,
  ) {
    try {
      final AgentWebsiteDeploymentActivationSettings
      settings = AgentWebsiteDeploymentActivationSettings(
        deploymentEnabled: _bool(map['deploymentEnabled']),
        gitConnectedProviderEnabled: _bool(map['gitConnectedProviderEnabled']),
        livePushActivationApproved: _bool(map['livePushActivationApproved']),
        liveDeploymentActivationApproved: _bool(
          map['liveDeploymentActivationApproved'],
        ),
        emergencyBlocked: _bool(map['emergencyBlocked']),
        reason: (map['reason'] ?? '').toString().trim(),
        updatedBy: (map['updatedBy'] ?? '').toString().trim(),
        createdAt: _date(map['createdAt']) ?? DateTime.now(),
        updatedAt: _date(map['updatedAt']),
      );

      settings.validate();
      return settings;
    } on AgentWebsiteDeploymentActivationSettingsException {
      return AgentWebsiteDeploymentActivationSettings.safeDefaults();
    }
  }

  static bool _bool(dynamic value) {
    if (value is bool) {
      return value;
    }

    return value?.toString().trim().toLowerCase() == 'true';
  }

  static DateTime? _date(dynamic value) {
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

class AgentWebsiteDeploymentActivationSettingsException implements Exception {
  final String message;

  const AgentWebsiteDeploymentActivationSettingsException(this.message);

  @override
  String toString() =>
      'AgentWebsiteDeploymentActivationSettingsException: $message';
}
