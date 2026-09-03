import '../constants/agent_versioning_constants.dart';
import '../models/agent_version_record.dart';
import 'agent_version_change_classification_policy.dart';

class AgentVersionContractService {
  const AgentVersionContractService({
    this.classificationPolicy = const AgentVersionChangeClassificationPolicy(),
  });

  final AgentVersionChangeClassificationPolicy classificationPolicy;

  AgentVersionRecord createProposedVersion({
    required String versionId,
    required String agentId,
    required String semanticVersion,
    required String? previousVersionId,
    required String changeType,
    required String changeCode,
    required String artifactFingerprintSha256,
    required DateTime proposedAtUtc,
  }) {
    final classification = classificationPolicy.classify(changeType);
    classification.validate();

    if (!classification.versionable ||
        classification.blockedProtectedAuthority) {
      throw StateError(
        'Protected authority change is outside Agent version contract.',
      );
    }

    final record = AgentVersionRecord(
      contractVersion: AgentVersionContract.contractVersion,
      versionId: versionId,
      agentId: agentId,
      semanticVersion: semanticVersion,
      previousVersionId: previousVersionId,
      changeType: changeType,
      changeRisk: classification.risk,
      changeCode: changeCode,
      artifactFingerprintSha256: artifactFingerprintSha256,
      status: AgentVersionLifecycleStatus.proposed,
      proposedAtUtc: proposedAtUtc,
      evaluationRunId: null,
    );

    record.validate();
    return record;
  }

  bool get reusesPhase42EvaluationEvidence => true;
  bool get immutableVersionIdentityRequired => true;
  bool get previousVersionRollbackLinkRequiredForUpgrade => true;

  bool get persistsVersion => false;
  bool get callsProvider => false;
  bool get trainsModel => false;
  bool get mutatesPrompt => false;
  bool get deploysVersion => false;
  bool get activatesProduction => false;
  bool get performsRollback => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get assignsRole => false;
  bool get mutatesProviderPolicy => false;
  bool get mutatesCostLimit => false;
  bool get mutatesSecurity => false;
  bool get writesBusinessData => false;
}
