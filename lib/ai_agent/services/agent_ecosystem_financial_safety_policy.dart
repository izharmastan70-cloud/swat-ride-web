import '../constants/agent_ecosystem_financial_safety_constants.dart';
import '../models/agent_ecosystem_financial_safety_decision.dart';
import '../models/agent_ecosystem_financial_safety_request.dart';

class AgentEcosystemFinancialSafetyPolicy {
  const AgentEcosystemFinancialSafetyPolicy();

  AgentEcosystemFinancialSafetyDecision evaluate(
    AgentEcosystemFinancialSafetyRequest request,
  ) {
    request.validate();

    if (request.emergencyStopActive) {
      return _blocked(
        status: AgentEcosystemFinancialDecisionStatus.blockEmergencyStop,
        reasonCode: 'emergency_stop_active',
      );
    }

    if (!request.moduleEnabled) {
      return _blocked(
        status: AgentEcosystemFinancialDecisionStatus.blockModuleDisabled,
        reasonCode: 'financial_module_or_agent_kill_switch_off',
      );
    }

    if (!request.trustedIdentityVerified) {
      return AgentEcosystemFinancialSafetyDecision(
        status: AgentEcosystemFinancialDecisionStatus.blockUntrustedIdentity,
        routeTo: AgentEcosystemFinancialRoute.trustedIdentityGate,
        reasonCode: 'trusted_financial_actor_identity_required',
        auditRequired: true,
        existingCompletionReferenceOnly: false,
      );
    }

    if (!request.permissionAllowed) {
      return AgentEcosystemFinancialSafetyDecision(
        status: AgentEcosystemFinancialDecisionStatus.blockPermissionDenied,
        routeTo: AgentEcosystemFinancialRoute.permissionGate,
        reasonCode: 'financial_permission_denied',
        auditRequired: true,
        existingCompletionReferenceOnly: false,
      );
    }

    if (request.approvalRequired) {
      if (!request.approvalPresent) {
        return AgentEcosystemFinancialSafetyDecision(
          status: AgentEcosystemFinancialDecisionStatus.blockApprovalRequired,
          routeTo: AgentEcosystemFinancialRoute.approvalGate,
          reasonCode: 'financial_approval_required',
          auditRequired: true,
          existingCompletionReferenceOnly: false,
        );
      }

      if (!request.approvalFresh) {
        return AgentEcosystemFinancialSafetyDecision(
          status: AgentEcosystemFinancialDecisionStatus.blockApprovalExpired,
          routeTo: AgentEcosystemFinancialRoute.approvalGate,
          reasonCode: 'financial_approval_expired_or_consumed',
          auditRequired: true,
          existingCompletionReferenceOnly: false,
        );
      }

      if (!request.approvalBindingMatch) {
        return AgentEcosystemFinancialSafetyDecision(
          status: AgentEcosystemFinancialDecisionStatus
              .blockApprovalBindingMismatch,
          routeTo: AgentEcosystemFinancialRoute.approvalGate,
          reasonCode:
              'financial_approval_action_amount_subject_binding_mismatch',
          auditRequired: true,
          existingCompletionReferenceOnly: false,
        );
      }
    }

    if (!request.runtimeGateAllowed) {
      return AgentEcosystemFinancialSafetyDecision(
        status: AgentEcosystemFinancialDecisionStatus.blockRuntimeGate,
        routeTo: AgentEcosystemFinancialRoute.runtimeGate,
        reasonCode: 'financial_runtime_gate_denied',
        auditRequired: true,
        existingCompletionReferenceOnly: false,
      );
    }

    if (request.idempotencyKey.trim().isEmpty) {
      return AgentEcosystemFinancialSafetyDecision(
        status: AgentEcosystemFinancialDecisionStatus.blockIdempotencyMissing,
        routeTo: AgentEcosystemFinancialRoute.idempotencyGate,
        reasonCode: 'financial_idempotency_key_required',
        auditRequired: true,
        existingCompletionReferenceOnly: false,
      );
    }

    if (!request.reservationAcquired) {
      return AgentEcosystemFinancialSafetyDecision(
        status: AgentEcosystemFinancialDecisionStatus.blockReservationMissing,
        routeTo: AgentEcosystemFinancialRoute.idempotencyGate,
        reasonCode: 'financial_idempotency_reservation_required',
        auditRequired: true,
        existingCompletionReferenceOnly: false,
      );
    }

    if (!request.reservationBindingMatch) {
      return AgentEcosystemFinancialSafetyDecision(
        status: AgentEcosystemFinancialDecisionStatus
            .blockReservationBindingMismatch,
        routeTo: AgentEcosystemFinancialRoute.idempotencyGate,
        reasonCode: 'idempotency_reservation_operation_binding_mismatch',
        auditRequired: true,
        existingCompletionReferenceOnly: false,
      );
    }

    if (!request.operationAmountCurrencyBindingMatch) {
      return AgentEcosystemFinancialSafetyDecision(
        status:
            AgentEcosystemFinancialDecisionStatus.blockOperationBindingMismatch,
        routeTo: AgentEcosystemFinancialRoute.idempotencyGate,
        reasonCode: 'financial_operation_amount_currency_fingerprint_mismatch',
        auditRequired: true,
        existingCompletionReferenceOnly: false,
      );
    }

    if (request.providerCallbackReplayDetected) {
      return _blocked(
        status: AgentEcosystemFinancialDecisionStatus.blockCallbackReplay,
        reasonCode: 'payment_provider_callback_replay_blocked',
      );
    }

    if (request.priorCompletionDetected) {
      if (!request.priorCompletionBindingMatch) {
        return AgentEcosystemFinancialSafetyDecision(
          status: AgentEcosystemFinancialDecisionStatus
              .blockDuplicateBindingCollision,
          routeTo: AgentEcosystemFinancialRoute.duplicateReview,
          reasonCode:
              'duplicate_financial_completion_binding_collision_or_tamper',
          auditRequired: true,
          existingCompletionReferenceOnly: false,
        );
      }

      return AgentEcosystemFinancialSafetyDecision(
        status: AgentEcosystemFinancialDecisionStatus.blockDuplicateCompleted,
        routeTo: AgentEcosystemFinancialRoute.duplicateReview,
        reasonCode:
            'existing_verified_completion_must_be_reused_no_second_financial_action',
        auditRequired: true,
        existingCompletionReferenceOnly: true,
      );
    }

    if (!request.auditReady) {
      return AgentEcosystemFinancialSafetyDecision(
        status: AgentEcosystemFinancialDecisionStatus.blockAuditUnavailable,
        routeTo: AgentEcosystemFinancialRoute.auditGate,
        reasonCode: 'financial_audit_not_ready',
        auditRequired: true,
        existingCompletionReferenceOnly: false,
      );
    }

    return AgentEcosystemFinancialSafetyDecision(
      status: AgentEcosystemFinancialDecisionStatus
          .eligibleControlledFinancialHandoff,
      routeTo: AgentEcosystemFinancialRoute.controlledFinancialHandoff,
      reasonCode: 'all_financial_safety_controls_verified_handoff_only',
      auditRequired: true,
      existingCompletionReferenceOnly: false,
    );
  }

  AgentEcosystemFinancialSafetyDecision _blocked({
    required String status,
    required String reasonCode,
  }) {
    return AgentEcosystemFinancialSafetyDecision(
      status: status,
      routeTo: AgentEcosystemFinancialRoute.blocked,
      reasonCode: reasonCode,
      auditRequired: true,
      existingCompletionReferenceOnly: false,
    );
  }

  bool get policyOnly => true;
  bool get idempotencyIsAuthorization => false;

  bool get executesPayment => false;
  bool get executesRefund => false;
  bool get debitsWallet => false;
  bool get creditsWallet => false;
  bool get executesPayout => false;
  bool get approvesWithdrawal => false;
  bool get settlesCommission => false;

  bool get reservesIdempotencyKey => false;
  bool get marksCompletion => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get overridesRuntimeGate => false;
  bool get disablesEmergencyStop => false;
  bool get enablesModule => false;
  bool get callsPaymentProvider => false;
  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get writesBusinessData => false;
  bool get activatesProduction => false;
}
