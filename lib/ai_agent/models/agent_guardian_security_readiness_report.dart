class AgentGuardianSecurityReadinessStatus {
  AgentGuardianSecurityReadinessStatus._();

  static const String foundationReadyNotProductionActive =
      'FOUNDATION_READY_NOT_PRODUCTION_ACTIVE';

  static const String blockedNotReady = 'BLOCKED_NOT_READY';

  static const Set<String> values = <String>{
    foundationReadyNotProductionActive,
    blockedNotReady,
  };
}

class AgentGuardianSecurityReadinessReport {
  AgentGuardianSecurityReadinessReport({
    required this.status,
    required this.guardianFoundationReady,
    required this.productionActive,
    required this.adversarialCoverageCount,
    required this.allAdversarialCasesPassed,
    required this.failClosedMonitoringVerified,
    required this.failureIsolationVerified,
    required this.safeEvidenceOnlyVerified,
    required this.authoritativeControlsRemainFinal,
    required this.authoritativeChecksRemainRequired,
    required this.guardianIsFinalEnforcer,
    required this.permissionApprovalRuntimeBypassAllowed,
    required this.phase54IncidentResponseImplemented,
    required this.persistentGuardianMonitoringImplemented,
    required this.securityAuditPersistenceImplemented,
    required this.providerExecutionImplemented,
    required this.targetAgentExecutionImplemented,
    required this.businessWriteImplemented,
    required this.rawSensitiveEvidenceAllowed,
    required this.coreAppFailureCoupledToGuardian,
    required this.otherChannelFailureCoupledToGuardian,
    required this.callAgentLockedActionSetPreserved,
    required this.generatedAt,
    required List<String> readinessEvidenceCodes,
  }) : readinessEvidenceCodes = List<String>.unmodifiable(
         readinessEvidenceCodes,
       );

  final String status;

  final bool guardianFoundationReady;
  final bool productionActive;

  final int adversarialCoverageCount;
  final bool allAdversarialCasesPassed;

  final bool failClosedMonitoringVerified;
  final bool failureIsolationVerified;
  final bool safeEvidenceOnlyVerified;

  final bool authoritativeControlsRemainFinal;
  final bool authoritativeChecksRemainRequired;

  final bool guardianIsFinalEnforcer;
  final bool permissionApprovalRuntimeBypassAllowed;

  final bool phase54IncidentResponseImplemented;
  final bool persistentGuardianMonitoringImplemented;
  final bool securityAuditPersistenceImplemented;

  final bool providerExecutionImplemented;
  final bool targetAgentExecutionImplemented;
  final bool businessWriteImplemented;

  final bool rawSensitiveEvidenceAllowed;

  final bool coreAppFailureCoupledToGuardian;
  final bool otherChannelFailureCoupledToGuardian;

  final bool callAgentLockedActionSetPreserved;

  final DateTime generatedAt;
  final List<String> readinessEvidenceCodes;

  bool get foundationReadyNotProductionActive =>
      status ==
      AgentGuardianSecurityReadinessStatus.foundationReadyNotProductionActive;

  bool get blocked =>
      status == AgentGuardianSecurityReadinessStatus.blockedNotReady;

  bool get recommendationOnly => true;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get executesBlock => false;
  bool get executesEscalation => false;
  bool get createsIncident => false;
  bool get mutatesSecurityControls => false;
  bool get persistsReport => false;

  void validateStructure() {
    if (!AgentGuardianSecurityReadinessStatus.values.contains(status)) {
      throw const AgentGuardianSecurityReadinessReportException(
        'Guardian readiness status is invalid.',
      );
    }

    if (adversarialCoverageCount < 0 || adversarialCoverageCount > 100) {
      throw const AgentGuardianSecurityReadinessReportException(
        'Guardian adversarial coverage count is invalid.',
      );
    }

    if (readinessEvidenceCodes.isEmpty || readinessEvidenceCodes.length > 16) {
      throw const AgentGuardianSecurityReadinessReportException(
        'Guardian readiness evidence must contain 1 to 16 codes.',
      );
    }

    final RegExp safeCodePattern = RegExp(r'^[A-Za-z0-9._:-]{1,120}$');

    for (final String code in readinessEvidenceCodes) {
      if (!safeCodePattern.hasMatch(code)) {
        throw const AgentGuardianSecurityReadinessReportException(
          'Guardian readiness evidence code is invalid.',
        );
      }
    }

    if (foundationReadyNotProductionActive) {
      final bool readyInvariant =
          guardianFoundationReady &&
          !productionActive &&
          adversarialCoverageCount == 14 &&
          allAdversarialCasesPassed &&
          failClosedMonitoringVerified &&
          failureIsolationVerified &&
          safeEvidenceOnlyVerified &&
          authoritativeControlsRemainFinal &&
          authoritativeChecksRemainRequired &&
          !guardianIsFinalEnforcer &&
          !permissionApprovalRuntimeBypassAllowed &&
          !phase54IncidentResponseImplemented &&
          !persistentGuardianMonitoringImplemented &&
          !securityAuditPersistenceImplemented &&
          !providerExecutionImplemented &&
          !targetAgentExecutionImplemented &&
          !businessWriteImplemented &&
          !rawSensitiveEvidenceAllowed &&
          !coreAppFailureCoupledToGuardian &&
          !otherChannelFailureCoupledToGuardian &&
          callAgentLockedActionSetPreserved;

      if (!readyInvariant) {
        throw const AgentGuardianSecurityReadinessReportException(
          'Guardian ready report violates locked safety invariants.',
        );
      }
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'guardianFoundationReady': guardianFoundationReady,
      'productionActive': productionActive,
      'adversarialCoverageCount': adversarialCoverageCount,
      'allAdversarialCasesPassed': allAdversarialCasesPassed,
      'failClosedMonitoringVerified': failClosedMonitoringVerified,
      'failureIsolationVerified': failureIsolationVerified,
      'safeEvidenceOnlyVerified': safeEvidenceOnlyVerified,
      'authoritativeControlsRemainFinal': authoritativeControlsRemainFinal,
      'authoritativeChecksRemainRequired': authoritativeChecksRemainRequired,
      'guardianIsFinalEnforcer': guardianIsFinalEnforcer,
      'permissionApprovalRuntimeBypassAllowed':
          permissionApprovalRuntimeBypassAllowed,
      'phase54IncidentResponseImplemented': phase54IncidentResponseImplemented,
      'persistentGuardianMonitoringImplemented':
          persistentGuardianMonitoringImplemented,
      'securityAuditPersistenceImplemented':
          securityAuditPersistenceImplemented,
      'providerExecutionImplemented': providerExecutionImplemented,
      'targetAgentExecutionImplemented': targetAgentExecutionImplemented,
      'businessWriteImplemented': businessWriteImplemented,
      'rawSensitiveEvidenceAllowed': rawSensitiveEvidenceAllowed,
      'coreAppFailureCoupledToGuardian': coreAppFailureCoupledToGuardian,
      'otherChannelFailureCoupledToGuardian':
          otherChannelFailureCoupledToGuardian,
      'callAgentLockedActionSetPreserved': callAgentLockedActionSetPreserved,
      'generatedAt': generatedAt.toUtc().toIso8601String(),
      'readinessEvidenceCodes': List<String>.unmodifiable(
        readinessEvidenceCodes,
      ),
      'recommendationOnly': true,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'marksRuntimeAllowed': false,
      'invokesPermissionEngine': false,
      'invokesApprovalEngine': false,
      'invokesRuntimeGate': false,
      'invokesEmergencyStop': false,
      'executesBlock': false,
      'executesEscalation': false,
      'createsIncident': false,
      'mutatesSecurityControls': false,
      'persistsReport': false,
      'rawEvidencePayloadIncluded': false,
    });
  }
}

class AgentGuardianSecurityReadinessReportException implements Exception {
  const AgentGuardianSecurityReadinessReportException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentGuardianSecurityReadinessReportException: $message';
}
