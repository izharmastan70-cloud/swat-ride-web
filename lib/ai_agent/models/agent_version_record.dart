import '../constants/agent_versioning_constants.dart';

class AgentVersionRecord {
  AgentVersionRecord({
    required this.contractVersion,
    required this.versionId,
    required this.agentId,
    required this.semanticVersion,
    required this.previousVersionId,
    required this.changeType,
    required this.changeRisk,
    required this.changeCode,
    required this.artifactFingerprintSha256,
    required this.status,
    required this.proposedAtUtc,
    required this.evaluationRunId,
  }) {
    validate();
  }

  final String contractVersion;
  final String versionId;
  final String agentId;
  final String semanticVersion;
  final String? previousVersionId;
  final String changeType;
  final String changeRisk;
  final String changeCode;
  final String artifactFingerprintSha256;
  final String status;
  final DateTime proposedAtUtc;
  final String? evaluationRunId;

  bool get immutableIdentity => true;
  bool get metadataOnly => true;
  bool get rawPromptStored => false;
  bool get rawModelPayloadStored => false;
  bool get privateConversationStored => false;
  bool get secretsStored => false;
  bool get authTokenStored => false;
  bool get approvalTokenStored => false;
  bool get permissionTokenStored => false;

  bool get productionActive => false;
  bool get productionActivationPerformed => false;
  bool get deploymentPerformed => false;
  bool get rollbackPerformed => false;
  bool get modelTrainingPerformed => false;
  bool get promptMutationPerformed => false;
  bool get providerPolicyMutationPerformed => false;
  bool get costLimitMutationPerformed => false;
  bool get permissionGranted => false;
  bool get approvalConsumed => false;
  bool get businessWritePerformed => false;

  bool get rollbackLinkAvailable =>
      previousVersionId != null && previousVersionId!.isNotEmpty;

  void validate() {
    final RegExp opaqueIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');
    final RegExp semanticVersionPattern = RegExp(
      r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$',
    );
    final RegExp sha256Pattern = RegExp(r'^[A-Fa-f0-9]{64}$');

    if (contractVersion != AgentVersionContract.contractVersion ||
        !_validOpaqueId(versionId, opaqueIdPattern) ||
        !_validOpaqueId(agentId, opaqueIdPattern) ||
        !semanticVersionPattern.hasMatch(semanticVersion) ||
        !AgentVersionChangeType.versionableValues.contains(changeType) ||
        !AgentVersionChangeRisk.values.contains(changeRisk) ||
        changeRisk == AgentVersionChangeRisk.blockedProtectedAuthority ||
        !_validChangeCode(changeCode, opaqueIdPattern) ||
        !sha256Pattern.hasMatch(artifactFingerprintSha256) ||
        !AgentVersionLifecycleStatus.values.contains(status) ||
        !proposedAtUtc.isUtc) {
      throw const FormatException('Invalid immutable Agent version record.');
    }

    if (previousVersionId != null) {
      if (!_validOpaqueId(previousVersionId!, opaqueIdPattern) ||
          previousVersionId == versionId) {
        throw const FormatException('Invalid previous Agent version identity.');
      }
    }

    if (evaluationRunId != null &&
        !_validOpaqueId(evaluationRunId!, opaqueIdPattern)) {
      throw const FormatException('Invalid evaluation run identity.');
    }
  }

  bool _validOpaqueId(String value, RegExp pattern) {
    return value.isNotEmpty &&
        value == value.trim() &&
        value.length <= AgentVersionContract.opaqueIdMaxLength &&
        pattern.hasMatch(value);
  }

  bool _validChangeCode(String value, RegExp pattern) {
    return value.isNotEmpty &&
        value == value.trim() &&
        value.length <= AgentVersionContract.changeCodeMaxLength &&
        pattern.hasMatch(value);
  }
}
