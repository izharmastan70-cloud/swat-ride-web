class AgentVoiceSuperAdminSourceReadinessStatus {
  AgentVoiceSuperAdminSourceReadinessStatus._();

  /// A read-only connector is attached to the active read-only registry or
  /// otherwise already has an audited active read path.
  static const String registryReady = 'REGISTRY_READY';

  /// A connector implementation file exists and passed semantic read-only
  /// inspection, but the central module registry still says NOT_CONNECTED.
  /// Voice Super Admin must NOT execute it as if live.
  static const String connectorExistsButRegistryNotConnected =
      'CONNECTOR_EXISTS_BUT_REGISTRY_NOT_CONNECTED';

  /// No trusted Voice Super Admin read path is attached yet.
  static const String notConnected = 'NOT_CONNECTED';

  static const Set<String> values = <String>{
    registryReady,
    connectorExistsButRegistryNotConnected,
    notConnected,
  };

  static bool isValid(String value) => values.contains(value);
}

class AgentVoiceSuperAdminSourceReadiness {
  const AgentVoiceSuperAdminSourceReadiness({
    required this.moduleId,
    required this.status,
    required this.evidence,
  });

  final String moduleId;
  final String status;
  final String evidence;

  bool get mayExecuteThroughExistingReadPath =>
      status == AgentVoiceSuperAdminSourceReadinessStatus.registryReady;

  bool get mustSurfaceUnavailable => !mayExecuteThroughExistingReadPath;

  void validate() {
    if (moduleId.trim().isEmpty ||
        !AgentVoiceSuperAdminSourceReadinessStatus.isValid(status) ||
        evidence.trim().isEmpty) {
      throw const AgentVoiceSuperAdminSourceReadinessException(
        'Voice Super Admin source readiness is invalid.',
      );
    }
  }
}

/// Step 2A reconciled readiness.
///
/// Important nuance:
/// Hotel/Tour connector files exist, but AgentModuleConnectorRegistry still
/// reports them NOT_CONNECTED. They are therefore NOT live-executable from
/// Voice Super Admin yet.
class AgentVoiceSuperAdminInitialSourceReadiness {
  AgentVoiceSuperAdminInitialSourceReadiness._();

  static const List<AgentVoiceSuperAdminSourceReadiness>
  values = <AgentVoiceSuperAdminSourceReadiness>[
    AgentVoiceSuperAdminSourceReadiness(
      moduleId: 'NORMAL_RIDE',
      status: AgentVoiceSuperAdminSourceReadinessStatus.registryReady,
      evidence:
          'AgentReadOnlyConnectorRegistry includes AgentRideReadOnlyConnector.',
    ),
    AgentVoiceSuperAdminSourceReadiness(
      moduleId: 'DRIVER',
      status: AgentVoiceSuperAdminSourceReadinessStatus.registryReady,
      evidence:
          'AgentReadOnlyConnectorRegistry includes AgentDriverReadOnlyConnector.',
    ),
    AgentVoiceSuperAdminSourceReadiness(
      moduleId: 'FOOD',
      status: AgentVoiceSuperAdminSourceReadinessStatus.registryReady,
      evidence:
          'AgentReadOnlyConnectorRegistry includes AgentFoodOrderReadOnlyConnector.',
    ),
    AgentVoiceSuperAdminSourceReadiness(
      moduleId: 'RESTAURANT',
      status: AgentVoiceSuperAdminSourceReadinessStatus.registryReady,
      evidence:
          'AgentReadOnlyConnectorRegistry includes AgentRestaurantReadOnlyConnector.',
    ),
    AgentVoiceSuperAdminSourceReadiness(
      moduleId: 'SYSTEM_HEALTH',
      status: AgentVoiceSuperAdminSourceReadinessStatus.registryReady,
      evidence:
          'AgentReadOnlyConnectorRegistry includes AgentCoreReadOnlyConnector.',
    ),
    AgentVoiceSuperAdminSourceReadiness(
      moduleId: 'HOTEL',
      status: AgentVoiceSuperAdminSourceReadinessStatus
          .connectorExistsButRegistryNotConnected,
      evidence:
          'Hotel read-only connector file exists but central module registry reports NOT_CONNECTED.',
    ),
    AgentVoiceSuperAdminSourceReadiness(
      moduleId: 'TOUR',
      status: AgentVoiceSuperAdminSourceReadinessStatus
          .connectorExistsButRegistryNotConnected,
      evidence:
          'Tour read-only connector file exists but central module registry reports NOT_CONNECTED.',
    ),
    AgentVoiceSuperAdminSourceReadiness(
      moduleId: 'CARGO',
      status: AgentVoiceSuperAdminSourceReadinessStatus.notConnected,
      evidence: 'Cargo AI connector is still a stub/disabled.',
    ),
    AgentVoiceSuperAdminSourceReadiness(
      moduleId: 'STUDENT_RIDE',
      status: AgentVoiceSuperAdminSourceReadinessStatus.notConnected,
      evidence: 'Student Ride AI connector is still a stub/disabled.',
    ),
  ];

  static AgentVoiceSuperAdminSourceReadiness forModule(String moduleId) {
    for (final AgentVoiceSuperAdminSourceReadiness item in values) {
      if (item.moduleId == moduleId) {
        return item;
      }
    }

    return AgentVoiceSuperAdminSourceReadiness(
      moduleId: moduleId,
      status: AgentVoiceSuperAdminSourceReadinessStatus.notConnected,
      evidence: 'No verified active Voice Super Admin read path is registered.',
    );
  }
}

class AgentVoiceSuperAdminSourceReadinessException implements Exception {
  const AgentVoiceSuperAdminSourceReadinessException(this.message);

  final String message;

  @override
  String toString() => 'AgentVoiceSuperAdminSourceReadinessException: $message';
}
