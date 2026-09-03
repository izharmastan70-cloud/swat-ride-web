import 'dart:collection';

import '../models/agent_validation_result.dart';

// =========================================================
// AI AGENT - SECOND VALIDATOR SERVICE
// =========================================================
//
// Phase 28 Step 3.
//
// PURE VALIDATION ONLY:
// - no Firestore writes
// - no tool execution
// - no approval bypass
// - no account action
// - no deployment
//
// A second agent evaluates:
// - available evidence
// - required constraints
// - concerns
// - confidence
//
// Disagreement / weak evidence is escalated for
// Super Admin review.

class AgentSecondValidatorService {
  const AgentSecondValidatorService();

  AgentValidationResult validate({
    required String validationId,
    required String taskId,
    required String primaryAgentRoleId,
    required String validatorAgentRoleId,
    required String recommendation,
    required bool primaryRecommendationApproved,
    required List<String> availableEvidence,
    required List<String> requiredEvidence,
    required List<String> satisfiedConstraints,
    required List<String> requiredConstraints,
    List<String> concerns = const <String>[],
    double confidence = 0,
    DateTime? createdAt,
  }) {
    if (primaryAgentRoleId.trim().isEmpty) {
      throw const AgentValidationException(
        'primaryAgentRoleId cannot be empty.',
      );
    }

    if (validatorAgentRoleId.trim().isEmpty) {
      throw const AgentValidationException(
        'validatorAgentRoleId cannot be empty.',
      );
    }

    if (primaryAgentRoleId == validatorAgentRoleId) {
      throw const AgentValidationException(
        'Primary and validator agents must be different.',
      );
    }

    if (recommendation.trim().isEmpty) {
      throw const AgentValidationException(
        'recommendation cannot be empty.',
      );
    }

    if (confidence < 0 || confidence > 1) {
      throw const AgentValidationException(
        'confidence must be between 0 and 1.',
      );
    }

    final List<String> normalizedAvailableEvidence =
        _normalizeList(availableEvidence);

    final List<String> normalizedRequiredEvidence =
        _normalizeList(requiredEvidence);

    final List<String> normalizedSatisfiedConstraints =
        _normalizeList(satisfiedConstraints);

    final List<String> normalizedRequiredConstraints =
        _normalizeList(requiredConstraints);

    final List<String> normalizedConcerns =
        _normalizeList(concerns);

    final List<String> missingEvidence =
        normalizedRequiredEvidence
            .where(
              (String item) =>
                  !normalizedAvailableEvidence.contains(item),
            )
            .toList(growable: false);

    final List<String> missingConstraints =
        normalizedRequiredConstraints
            .where(
              (String item) =>
                  !normalizedSatisfiedConstraints.contains(item),
            )
            .toList(growable: false);

    final bool hasRequiredEvidence =
        missingEvidence.isEmpty;

    final bool hasRequiredConstraints =
        missingConstraints.isEmpty;

    final bool hasBlockingConcern =
        normalizedConcerns.isNotEmpty;

    String verdict;
    String status;
    String reason;
    bool requiresSuperAdminReview = false;

    if (!hasRequiredEvidence) {
      verdict =
          AgentValidationVerdict.insufficientEvidence;

      status =
          AgentValidationStatus.escalated;

      requiresSuperAdminReview = true;

      reason =
          'Required evidence is incomplete. '
          'Missing evidence count: ${missingEvidence.length}.';
    } else if (!hasRequiredConstraints) {
      verdict =
          AgentValidationVerdict.rejected;

      status =
          primaryRecommendationApproved
              ? AgentValidationStatus.disagreement
              : AgentValidationStatus.validated;

      requiresSuperAdminReview =
          status == AgentValidationStatus.disagreement;

      reason =
          'One or more required constraints are not satisfied. '
          'Missing constraint count: ${missingConstraints.length}.';
    } else if (hasBlockingConcern) {
      verdict =
          AgentValidationVerdict.needsReview;

      status =
          AgentValidationStatus.escalated;

      requiresSuperAdminReview = true;

      reason =
          'Validator identified concerns that require human review.';
    } else if (confidence < 0.60) {
      verdict =
          AgentValidationVerdict.needsReview;

      status =
          AgentValidationStatus.escalated;

      requiresSuperAdminReview = true;

      reason =
          'Validator confidence is below the minimum safe threshold.';
    } else {
      verdict =
          AgentValidationVerdict.approved;

      status =
          primaryRecommendationApproved
              ? AgentValidationStatus.validated
              : AgentValidationStatus.disagreement;

      requiresSuperAdminReview =
          status == AgentValidationStatus.disagreement;

      reason =
          status == AgentValidationStatus.validated
              ? 'Independent validator confirmed the recommendation.'
              : 'Independent validator approved a recommendation that the primary agent did not approve.';
    }

    final AgentValidationResult result =
        AgentValidationResult(
      validationId: validationId,
      taskId: taskId,
      primaryAgentRoleId: primaryAgentRoleId,
      validatorAgentRoleId: validatorAgentRoleId,
      recommendation: recommendation,
      verdict: verdict,
      status: status,
      evidenceChecked:
          normalizedAvailableEvidence,
      constraintsChecked:
          normalizedSatisfiedConstraints,
      concerns: <String>[
        ...normalizedConcerns,
        ...missingEvidence.map(
          (String item) =>
              'Missing evidence: $item',
        ),
        ...missingConstraints.map(
          (String item) =>
              'Missing constraint: $item',
        ),
      ],
      reason: reason,
      confidence: confidence,
      requiresSuperAdminReview:
          requiresSuperAdminReview,
      createdAt: createdAt ?? DateTime.now(),
    );

    result.validate();

    return result;
  }

  List<String> _normalizeList(
    Iterable<String> values,
  ) {
    final LinkedHashSet<String> normalized =
        LinkedHashSet<String>();

    for (final String value in values) {
      final String trimmed = value.trim();

      if (trimmed.isNotEmpty) {
        normalized.add(trimmed);
      }
    }

    return normalized.toList(growable: false);
  }
}