import '../models/agent_validation_result.dart';
import 'agent_second_validator_service.dart';
import 'agent_validation_policy.dart';

// =========================================================
// AI AGENT - VALIDATION COORDINATOR
// =========================================================
//
// Phase 28 Step 5.
//
// Controlled coordinator for:
// 1) importance/risk policy
// 2) second-agent validation
// 3) structured validation result
//
// NO EXECUTION AUTHORITY:
// - no Firestore writes
// - no tool execution
// - no approval bypass
// - no account action
// - no deployment
// - no permission mutation
//
// Permission Engine + Runtime Gate remain authoritative.

class AgentValidationRequest {
  final String validationId;
  final String taskId;
  final String actionId;
  final String primaryAgentRoleId;
  final String validatorAgentRoleId;
  final String recommendation;

  final bool primaryRecommendationApproved;

  final List<String> availableEvidence;
  final List<String> requiredEvidence;

  final List<String> satisfiedConstraints;
  final List<String> requiredConstraints;

  final List<String> concerns;

  final double confidence;

  final bool permanentlyForbiddenForAi;
  final bool requiresApproval;
  final bool writesData;
  final bool affectsMoney;
  final bool affectsAccountStatus;
  final bool affectsPermissions;
  final bool affectsSafety;
  final bool affectsProduction;
  final bool usesPaidAi;
  final bool containsSensitiveData;
  final bool irreversible;

  const AgentValidationRequest({
    required this.validationId,
    required this.taskId,
    required this.actionId,
    required this.primaryAgentRoleId,
    required this.validatorAgentRoleId,
    required this.recommendation,
    required this.primaryRecommendationApproved,
    this.availableEvidence = const <String>[],
    this.requiredEvidence = const <String>[],
    this.satisfiedConstraints = const <String>[],
    this.requiredConstraints = const <String>[],
    this.concerns = const <String>[],
    this.confidence = 0,
    this.permanentlyForbiddenForAi = false,
    this.requiresApproval = false,
    this.writesData = false,
    this.affectsMoney = false,
    this.affectsAccountStatus = false,
    this.affectsPermissions = false,
    this.affectsSafety = false,
    this.affectsProduction = false,
    this.usesPaidAi = false,
    this.containsSensitiveData = false,
    this.irreversible = false,
  });

  void validate() {
    if (validationId.trim().isEmpty) {
      throw const AgentValidationCoordinatorException(
        'validationId cannot be empty.',
      );
    }

    if (taskId.trim().isEmpty) {
      throw const AgentValidationCoordinatorException(
        'taskId cannot be empty.',
      );
    }

    if (actionId.trim().isEmpty) {
      throw const AgentValidationCoordinatorException(
        'actionId cannot be empty.',
      );
    }

    if (primaryAgentRoleId.trim().isEmpty) {
      throw const AgentValidationCoordinatorException(
        'primaryAgentRoleId cannot be empty.',
      );
    }

    if (validatorAgentRoleId.trim().isEmpty) {
      throw const AgentValidationCoordinatorException(
        'validatorAgentRoleId cannot be empty.',
      );
    }

    if (primaryAgentRoleId == validatorAgentRoleId) {
      throw const AgentValidationCoordinatorException(
        'Primary and validator agents must be different.',
      );
    }

    if (recommendation.trim().isEmpty) {
      throw const AgentValidationCoordinatorException(
        'recommendation cannot be empty.',
      );
    }

    if (confidence < 0 || confidence > 1) {
      throw const AgentValidationCoordinatorException(
        'confidence must be between 0 and 1.',
      );
    }
  }
}

class AgentValidationCoordinatorResult {
  final AgentValidationPolicyDecision policyDecision;
  final AgentValidationResult? validationResult;

  const AgentValidationCoordinatorResult({
    required this.policyDecision,
    required this.validationResult,
  });

  bool get validationWasRequired =>
      policyDecision.validationRequired;

  bool get validationCompleted =>
      validationResult != null;

  bool get canProceedWithoutSecondValidation =>
      !policyDecision.validationRequired;

  bool get requiresSuperAdminReview =>
      validationResult?.needsHumanReview ?? false;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'policyDecision': policyDecision.toMap(),
      'validationWasRequired':
          validationWasRequired,
      'validationCompleted':
          validationCompleted,
      'canProceedWithoutSecondValidation':
          canProceedWithoutSecondValidation,
      'requiresSuperAdminReview':
          requiresSuperAdminReview,
      'validationResult':
          validationResult?.toMap(),
    };
  }
}

class AgentValidationCoordinator {
  final AgentValidationPolicy validationPolicy;
  final AgentSecondValidatorService validatorService;

  const AgentValidationCoordinator({
    this.validationPolicy =
        const AgentValidationPolicy(),
    this.validatorService =
        const AgentSecondValidatorService(),
  });

  AgentValidationCoordinatorResult evaluate(
    AgentValidationRequest request,
  ) {
    request.validate();

    final AgentValidationPolicyDecision
        policyDecision =
        validationPolicy.evaluate(
      actionId: request.actionId,
      permanentlyForbiddenForAi:
          request.permanentlyForbiddenForAi,
      requiresApproval:
          request.requiresApproval,
      writesData:
          request.writesData,
      affectsMoney:
          request.affectsMoney,
      affectsAccountStatus:
          request.affectsAccountStatus,
      affectsPermissions:
          request.affectsPermissions,
      affectsSafety:
          request.affectsSafety,
      affectsProduction:
          request.affectsProduction,
      usesPaidAi:
          request.usesPaidAi,
      containsSensitiveData:
          request.containsSensitiveData,
      irreversible:
          request.irreversible,
    );

    if (!policyDecision.validationRequired) {
      return AgentValidationCoordinatorResult(
        policyDecision: policyDecision,
        validationResult: null,
      );
    }

    final AgentValidationResult
        validationResult =
        validatorService.validate(
      validationId:
          request.validationId,
      taskId:
          request.taskId,
      primaryAgentRoleId:
          request.primaryAgentRoleId,
      validatorAgentRoleId:
          request.validatorAgentRoleId,
      recommendation:
          request.recommendation,
      primaryRecommendationApproved:
          request.primaryRecommendationApproved,
      availableEvidence:
          request.availableEvidence,
      requiredEvidence:
          request.requiredEvidence,
      satisfiedConstraints:
          request.satisfiedConstraints,
      requiredConstraints:
          request.requiredConstraints,
      concerns:
          request.concerns,
      confidence:
          request.confidence,
    );

    return AgentValidationCoordinatorResult(
      policyDecision: policyDecision,
      validationResult: validationResult,
    );
  }
}

class AgentValidationCoordinatorException
    implements Exception {
  final String message;

  const AgentValidationCoordinatorException(
    this.message,
  );

  @override
  String toString() =>
      'AgentValidationCoordinatorException: $message';
}