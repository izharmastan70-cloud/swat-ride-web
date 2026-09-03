import '../constants/agent_future_proposal_constants.dart';
import '../models/agent_future_evidence_snapshot.dart';
import '../models/agent_future_proposal.dart';

class AgentFutureProposalDraftInput {
  const AgentFutureProposalDraftInput({
    required this.proposalId,
    required this.problem,
    required this.affectedModule,
    required this.selectedEvidenceSourceIds,
    required this.proposedSolution,
    required this.expectedBenefit,
    required this.risk,
    required this.developmentComplexity,
    required this.affectedFiles,
    required this.affectedModules,
    required this.aiConfidence,
    required this.createdByAgentId,
    required this.createdAt,
  });

  final String proposalId;
  final String problem;
  final String affectedModule;

  /// Only these source IDs may contribute evidence/counts to the proposal.
  final List<String> selectedEvidenceSourceIds;

  final String proposedSolution;
  final String expectedBenefit;
  final String risk;
  final String developmentComplexity;
  final List<String> affectedFiles;
  final List<String> affectedModules;

  /// Must be explicitly supplied by the reasoning layer.
  /// This deterministic engine never invents a confidence value.
  final double aiConfidence;

  final String createdByAgentId;
  final DateTime createdAt;

  void validate() {
    if (proposalId.trim().isEmpty) {
      throw const AgentFutureProposalEngineException(
        'proposalId cannot be empty.',
      );
    }

    if (problem.trim().isEmpty) {
      throw const AgentFutureProposalEngineException(
        'problem cannot be empty.',
      );
    }

    if (affectedModule.trim().isEmpty) {
      throw const AgentFutureProposalEngineException(
        'affectedModule cannot be empty.',
      );
    }

    if (selectedEvidenceSourceIds.isEmpty ||
        selectedEvidenceSourceIds.every((String item) => item.trim().isEmpty)) {
      throw const AgentFutureProposalEngineException(
        'At least one evidence source must be selected.',
      );
    }

    if (proposedSolution.trim().isEmpty) {
      throw const AgentFutureProposalEngineException(
        'proposedSolution cannot be empty.',
      );
    }

    if (expectedBenefit.trim().isEmpty) {
      throw const AgentFutureProposalEngineException(
        'expectedBenefit cannot be empty.',
      );
    }

    if (!AgentFutureProposalRisk.isValid(risk)) {
      throw AgentFutureProposalEngineException('Unsupported risk: $risk');
    }

    if (!AgentFutureProposalComplexity.isValid(developmentComplexity)) {
      throw AgentFutureProposalEngineException(
        'Unsupported developmentComplexity: $developmentComplexity',
      );
    }

    if (affectedModules.isEmpty ||
        affectedModules.every((String item) => item.trim().isEmpty)) {
      throw const AgentFutureProposalEngineException(
        'At least one affected module is required.',
      );
    }

    if (aiConfidence.isNaN ||
        aiConfidence.isInfinite ||
        aiConfidence < 0 ||
        aiConfidence > 1) {
      throw const AgentFutureProposalEngineException(
        'aiConfidence must be between 0.0 and 1.0.',
      );
    }

    if (createdByAgentId.trim().isEmpty) {
      throw const AgentFutureProposalEngineException(
        'createdByAgentId cannot be empty.',
      );
    }
  }
}

/// Deterministic Phase 41 proposal builder.
///
/// SAFETY:
/// - consumes an already privacy-minimized read-only evidence snapshot;
/// - never reads Firestore directly;
/// - never invokes a provider;
/// - never invokes Code Agent;
/// - never writes source files or business state;
/// - never invents missing evidence/counts/confidence;
/// - emits AWAITING_REVIEW only.
class AgentFutureProposalEngine {
  const AgentFutureProposalEngine();

  AgentFutureProposal buildProposal({
    required AgentFutureEvidenceSnapshot snapshot,
    required AgentFutureProposalDraftInput input,
  }) {
    snapshot.validate();
    input.validate();

    if (!snapshot.hasAnyAvailableEvidence) {
      throw const AgentFutureProposalEngineException(
        'No available evidence exists for a Future proposal.',
      );
    }

    final Set<String> selectedIds = input.selectedEvidenceSourceIds
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toSet();

    final List<AgentFutureEvidenceSourceSnapshot> selectedSources = snapshot
        .availableSources
        .where(
          (AgentFutureEvidenceSourceSnapshot source) =>
              selectedIds.contains(source.sourceId),
        )
        .toList(growable: false);

    if (selectedSources.isEmpty) {
      throw const AgentFutureProposalEngineException(
        'Selected evidence sources are unavailable or not connected.',
      );
    }

    final List<String> evidenceRefs = selectedSources
        .expand(
          (AgentFutureEvidenceSourceSnapshot source) => source.evidenceRefs,
        )
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (evidenceRefs.isEmpty) {
      throw const AgentFutureProposalEngineException(
        'Available selected sources produced no evidence references.',
      );
    }

    final int affectedUserCount = selectedSources.fold<int>(
      0,
      (int total, AgentFutureEvidenceSourceSnapshot source) =>
          total + source.affectedUserCount,
    );

    final int affectedEventCount = selectedSources.fold<int>(
      0,
      (int total, AgentFutureEvidenceSourceSnapshot source) =>
          total + source.affectedEventCount,
    );

    final AgentFutureProposal proposal = AgentFutureProposal(
      proposalId: input.proposalId.trim(),
      problem: input.problem.trim(),
      affectedModule: input.affectedModule.trim(),
      evidenceRefs: evidenceRefs,
      affectedUserCount: affectedUserCount,
      affectedEventCount: affectedEventCount,
      proposedSolution: input.proposedSolution.trim(),
      expectedBenefit: input.expectedBenefit.trim(),
      risk: input.risk,
      developmentComplexity: input.developmentComplexity,
      affectedFiles: _normalizedStrings(input.affectedFiles),
      affectedModules: _normalizedStrings(input.affectedModules),
      aiConfidence: input.aiConfidence,
      status: AgentFutureProposalStatus.awaitingReview,
      createdByAgentId: input.createdByAgentId.trim(),
      reviewerId: '',
      reviewNote: '',
      createdAt: input.createdAt.toUtc(),
      updatedAt: input.createdAt.toUtc(),
    );

    proposal.validate();

    if (proposal.mayImplementDirectly) {
      throw const AgentFutureProposalEngineException(
        'Future proposal violated recommendation-only safety invariant.',
      );
    }

    if (!proposal.requiresHumanReview) {
      throw const AgentFutureProposalEngineException(
        'Future proposal must require human review.',
      );
    }

    return proposal;
  }

  List<String> _normalizedStrings(Iterable<String> values) {
    return values
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}

class AgentFutureProposalEngineException implements Exception {
  const AgentFutureProposalEngineException(this.message);

  final String message;

  @override
  String toString() => 'AgentFutureProposalEngineException: $message';
}
