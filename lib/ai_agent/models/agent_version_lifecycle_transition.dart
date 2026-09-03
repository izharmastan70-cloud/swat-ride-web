import '../constants/agent_version_lifecycle_constants.dart';
import '../constants/agent_versioning_constants.dart';

class AgentVersionLifecycleTransitionRequest {
  const AgentVersionLifecycleTransitionRequest({
    required this.versionId,
    required this.fromStatus,
    required this.toStatus,
    required this.humanApprovalGranted,
    required this.securityReviewPassed,
  });

  final String versionId;
  final String fromStatus;
  final String toStatus;
  final bool humanApprovalGranted;
  final bool securityReviewPassed;

  void validate() {
    final RegExp opaqueIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');

    if (versionId.isEmpty ||
        versionId != versionId.trim() ||
        versionId.length > AgentVersionContract.opaqueIdMaxLength ||
        !opaqueIdPattern.hasMatch(versionId) ||
        !AgentVersionLifecycleStatus.values.contains(fromStatus) ||
        !AgentVersionLifecycleStatus.values.contains(toStatus) ||
        fromStatus == toStatus) {
      throw const FormatException(
        'Invalid Agent version lifecycle transition request.',
      );
    }
  }
}

class AgentVersionLifecycleTransitionDecision {
  AgentVersionLifecycleTransitionDecision({
    required this.status,
    required this.versionId,
    required this.fromStatus,
    required this.toStatus,
    required this.reasonCode,
  }) {
    validate();
  }

  final String status;
  final String versionId;
  final String fromStatus;
  final String toStatus;
  final String reasonCode;

  bool get allowed => status == AgentVersionTransitionDecisionStatus.allowed;

  bool get mutatesVersionRecord => false;
  bool get persistsTransition => false;
  bool get deploymentPerformed => false;
  bool get productionActivationPerformed => false;
  bool get rollbackPerformed => false;
  bool get modelTrainingPerformed => false;
  bool get promptMutationPerformed => false;
  bool get permissionGranted => false;
  bool get approvalConsumed => false;
  bool get businessWritePerformed => false;
  bool get securityAuthorityPreserved => true;

  void validate() {
    if (!AgentVersionTransitionDecisionStatus.values.contains(status) ||
        versionId.trim().isEmpty ||
        reasonCode.trim().isEmpty ||
        !AgentVersionLifecycleStatus.values.contains(fromStatus) ||
        !AgentVersionLifecycleStatus.values.contains(toStatus)) {
      throw const FormatException(
        'Invalid Agent version lifecycle transition decision.',
      );
    }
  }
}
