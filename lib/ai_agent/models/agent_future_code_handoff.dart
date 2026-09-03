class AgentFutureCodeHandoffStatus {
  AgentFutureCodeHandoffStatus._();

  static const String readyForApprovalConsumption =
      'READY_FOR_APPROVAL_CONSUMPTION';
  static const String approvalConsumed = 'APPROVAL_CONSUMED';
  static const String handedToCodeAgent = 'HANDED_TO_CODE_AGENT';

  static const Set<String> values = <String>{
    readyForApprovalConsumption,
    approvalConsumed,
    handedToCodeAgent,
  };

  static bool isValid(String value) => values.contains(value);
}

/// Immutable product-proposal handoff package for the dedicated Code Agent.
///
/// IMPORTANT:
/// Future Proposal approval authorizes only the product proposal handoff.
/// It does NOT authorize source-code writes, paid provider use, deployment,
/// Firebase changes, package changes, migrations, or production actions.
class AgentFutureCodeHandoff {
  const AgentFutureCodeHandoff({
    required this.handoffId,
    required this.proposalId,
    required this.proposalApprovalId,
    required this.proposalApprovedBy,
    required this.problem,
    required this.affectedModule,
    required this.proposedSolution,
    required this.expectedBenefit,
    required this.evidenceRefs,
    required this.affectedUserCount,
    required this.affectedEventCount,
    required this.risk,
    required this.developmentComplexity,
    required this.candidateFiles,
    required this.affectedModules,
    required this.aiConfidence,
    required this.targetAgentRoleId,
    required this.status,
    required this.createdAt,
  });

  final String handoffId;
  final String proposalId;
  final String proposalApprovalId;
  final String proposalApprovedBy;
  final String problem;
  final String affectedModule;
  final String proposedSolution;
  final String expectedBenefit;
  final List<String> evidenceRefs;
  final int affectedUserCount;
  final int affectedEventCount;
  final String risk;
  final String developmentComplexity;

  /// Product proposal file hints only. These are NOT approved code-write paths.
  final List<String> candidateFiles;
  final List<String> affectedModules;

  final double aiConfidence;
  final String targetAgentRoleId;
  final String status;
  final DateTime createdAt;

  bool get proposalApproved => proposalApprovalId.trim().isNotEmpty;
  bool get codeWriteAuthorized => false;
  bool get createFileAuthorized => false;
  bool get deleteFileAuthorized => false;
  bool get paidProviderAuthorized => false;
  bool get firebaseMutationAuthorized => false;
  bool get deploymentAuthorized => false;
  bool get requiresSeparateCodeChangeApproval => true;
  bool get requiresPaidRuntimeGate => true;
  bool get requiresBackupBeforeWrite => true;
  bool get requiresQaAfterCodeChange => true;
  bool get requiresSecurityAfterQa => true;
  bool get requiresOwnerKeepRollback => true;

  void validate() {
    if (handoffId.trim().isEmpty ||
        proposalId.trim().isEmpty ||
        proposalApprovalId.trim().isEmpty ||
        proposalApprovedBy.trim().isEmpty) {
      throw const AgentFutureCodeHandoffValidationException(
        'Handoff/proposal/approval/approver identity cannot be empty.',
      );
    }

    if (problem.trim().isEmpty ||
        affectedModule.trim().isEmpty ||
        proposedSolution.trim().isEmpty ||
        expectedBenefit.trim().isEmpty) {
      throw const AgentFutureCodeHandoffValidationException(
        'Problem/module/solution/benefit cannot be empty.',
      );
    }

    if (evidenceRefs.isEmpty) {
      throw const AgentFutureCodeHandoffValidationException(
        'Code Agent handoff requires proposal evidence references.',
      );
    }

    if (affectedUserCount < 0 || affectedEventCount < 0) {
      throw const AgentFutureCodeHandoffValidationException(
        'Affected counts cannot be negative.',
      );
    }

    if (affectedModules.isEmpty) {
      throw const AgentFutureCodeHandoffValidationException(
        'At least one affected module is required.',
      );
    }

    if (aiConfidence.isNaN ||
        aiConfidence.isInfinite ||
        aiConfidence < 0 ||
        aiConfidence > 1) {
      throw const AgentFutureCodeHandoffValidationException(
        'aiConfidence must be between 0.0 and 1.0.',
      );
    }

    if (targetAgentRoleId != 'code_agent') {
      throw const AgentFutureCodeHandoffValidationException(
        'Future proposal handoff target must be code_agent.',
      );
    }

    if (!AgentFutureCodeHandoffStatus.isValid(status)) {
      throw AgentFutureCodeHandoffValidationException(
        'Unsupported handoff status: $status',
      );
    }

    if (codeWriteAuthorized ||
        createFileAuthorized ||
        deleteFileAuthorized ||
        paidProviderAuthorized ||
        firebaseMutationAuthorized ||
        deploymentAuthorized) {
      throw const AgentFutureCodeHandoffValidationException(
        'Future handoff must not grant execution/write/provider/deploy authority.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'handoffId': handoffId,
      'proposalId': proposalId,
      'proposalApprovalId': proposalApprovalId,
      'proposalApprovedBy': proposalApprovedBy,
      'problem': problem,
      'affectedModule': affectedModule,
      'proposedSolution': proposedSolution,
      'expectedBenefit': expectedBenefit,
      'evidenceRefs': List<String>.from(evidenceRefs),
      'affectedUserCount': affectedUserCount,
      'affectedEventCount': affectedEventCount,
      'risk': risk,
      'developmentComplexity': developmentComplexity,
      'candidateFiles': List<String>.from(candidateFiles),
      'affectedModules': List<String>.from(affectedModules),
      'aiConfidence': aiConfidence,
      'targetAgentRoleId': targetAgentRoleId,
      'status': status,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'proposalApproved': true,
      'codeWriteAuthorized': false,
      'createFileAuthorized': false,
      'deleteFileAuthorized': false,
      'paidProviderAuthorized': false,
      'firebaseMutationAuthorized': false,
      'deploymentAuthorized': false,
      'requiresSeparateCodeChangeApproval': true,
      'requiresPaidRuntimeGate': true,
      'requiresBackupBeforeWrite': true,
      'requiresQaAfterCodeChange': true,
      'requiresSecurityAfterQa': true,
      'requiresOwnerKeepRollback': true,
    };
  }
}

class AgentFutureCodeHandoffValidationException implements Exception {
  const AgentFutureCodeHandoffValidationException(this.message);

  final String message;

  @override
  String toString() => 'AgentFutureCodeHandoffValidationException: $message';
}
