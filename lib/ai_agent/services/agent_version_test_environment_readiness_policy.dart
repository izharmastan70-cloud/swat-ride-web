import '../constants/agent_version_rollout_constants.dart';
import '../models/agent_version_record.dart';
import '../models/agent_version_test_environment_evidence.dart';

class AgentVersionTestEnvironmentReadinessDecision {
  const AgentVersionTestEnvironmentReadinessDecision({
    required this.status,
    required this.reasonCode,
  });

  final String status;
  final String reasonCode;

  bool get ready => status == AgentVersionTestReadinessStatus.ready;

  bool get persistencePerformed => false;
  bool get deploymentPerformed => false;
  bool get productionActivationPerformed => false;
  bool get productionTrafficRouted => false;
  bool get providerExecutionPerformed => false;
  bool get modelTrainingPerformed => false;
  bool get promptMutationPerformed => false;
  bool get permissionGranted => false;
  bool get approvalConsumed => false;
  bool get businessWritePerformed => false;
}

class AgentVersionTestEnvironmentReadinessPolicy {
  const AgentVersionTestEnvironmentReadinessPolicy();

  AgentVersionTestEnvironmentReadinessDecision evaluate({
    required AgentVersionRecord version,
    required AgentVersionTestEnvironmentEvidence evidence,
    required DateTime evaluatedAtUtc,
  }) {
    try {
      version.validate();
      evidence.validate();

      if (!evaluatedAtUtc.isUtc) {
        throw const FormatException('Evaluation time must be UTC.');
      }
    } catch (_) {
      return const AgentVersionTestEnvironmentReadinessDecision(
        status: AgentVersionTestReadinessStatus.blockedInvalidEvidence,
        reasonCode: 'invalid_test_environment_evidence',
      );
    }

    if (evidence.versionId != version.versionId ||
        evidence.agentId != version.agentId ||
        evidence.artifactFingerprintSha256 !=
            version.artifactFingerprintSha256) {
      return const AgentVersionTestEnvironmentReadinessDecision(
        status: AgentVersionTestReadinessStatus.blockedIdentityMismatch,
        reasonCode: 'test_environment_identity_mismatch',
      );
    }

    if (evidence.completedAtUtc.isAfter(
      evaluatedAtUtc.add(
        AgentVersionTestEnvironmentPolicy.maximumFutureClockSkew,
      ),
    )) {
      return const AgentVersionTestEnvironmentReadinessDecision(
        status: AgentVersionTestReadinessStatus.blockedClockSkew,
        reasonCode: 'test_environment_clock_skew',
      );
    }

    if (evaluatedAtUtc.difference(evidence.completedAtUtc) >
        AgentVersionTestEnvironmentPolicy.maximumEvidenceAge) {
      return const AgentVersionTestEnvironmentReadinessDecision(
        status: AgentVersionTestReadinessStatus.blockedStaleEvidence,
        reasonCode: 'stale_test_environment_evidence',
      );
    }

    if (!evidence.syntheticOrApprovedNonPrivateDataOnly) {
      return const AgentVersionTestEnvironmentReadinessDecision(
        status: AgentVersionTestReadinessStatus.blockedPrivateData,
        reasonCode: 'private_test_data_blocked',
      );
    }

    if (evidence.productionTrafficUsed) {
      return const AgentVersionTestEnvironmentReadinessDecision(
        status: AgentVersionTestReadinessStatus.blockedProductionTraffic,
        reasonCode: 'production_traffic_not_allowed_in_test_environment',
      );
    }

    if (!evidence.allTechnicalChecksPassed || evidence.providerExecutionUsed) {
      return const AgentVersionTestEnvironmentReadinessDecision(
        status: AgentVersionTestReadinessStatus.blockedFailedChecks,
        reasonCode: 'test_environment_checks_failed',
      );
    }

    return const AgentVersionTestEnvironmentReadinessDecision(
      status: AgentVersionTestReadinessStatus.ready,
      reasonCode: 'test_environment_ready',
    );
  }

  bool get persistsEvidence => false;
  bool get deploysVersion => false;
  bool get activatesProduction => false;
  bool get routesProductionTraffic => false;
  bool get callsProvider => false;
  bool get trainsModel => false;
  bool get mutatesPrompt => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get writesBusinessData => false;
}
