// =========================================================
// AI AGENT - VALIDATION POLICY / IMPORTANCE GATE
// =========================================================
//
// Phase 28 Step 4.
//
// Decides whether an AI recommendation requires an
// independent second-agent validation.
//
// POLICY ONLY:
// - no Firestore access
// - no tool execution
// - no approval bypass
// - no business action
// - no permission mutation
//
// Permission Engine + Runtime Gate remain authoritative.

class AgentDecisionRisk {
  AgentDecisionRisk._();

  static const String low = 'LOW';
  static const String medium = 'MEDIUM';
  static const String high = 'HIGH';
  static const String critical = 'CRITICAL';

  static const Set<String> values = <String>{
    low,
    medium,
    high,
    critical,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentValidationPolicyDecision {
  final bool validationRequired;
  final String risk;
  final String reason;

  const AgentValidationPolicyDecision({
    required this.validationRequired,
    required this.risk,
    required this.reason,
  });

  void validate() {
    if (!AgentDecisionRisk.isValid(risk)) {
      throw AgentValidationPolicyException(
        'Invalid decision risk "$risk".',
      );
    }

    if (reason.trim().isEmpty) {
      throw const AgentValidationPolicyException(
        'Validation policy reason cannot be empty.',
      );
    }

    if ((risk == AgentDecisionRisk.high ||
            risk == AgentDecisionRisk.critical) &&
        !validationRequired) {
      throw const AgentValidationPolicyException(
        'HIGH/CRITICAL decisions must require validation.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'validationRequired': validationRequired,
      'risk': risk,
      'reason': reason,
    };
  }
}

class AgentValidationPolicy {
  const AgentValidationPolicy();

  AgentValidationPolicyDecision evaluate({
    required String actionId,
    bool permanentlyForbiddenForAi = false,
    bool requiresApproval = false,
    bool writesData = false,
    bool affectsMoney = false,
    bool affectsAccountStatus = false,
    bool affectsPermissions = false,
    bool affectsSafety = false,
    bool affectsProduction = false,
    bool usesPaidAi = false,
    bool containsSensitiveData = false,
    bool irreversible = false,
  }) {
    if (actionId.trim().isEmpty) {
      throw const AgentValidationPolicyException(
        'actionId cannot be empty.',
      );
    }

    if (permanentlyForbiddenForAi) {
      final AgentValidationPolicyDecision decision =
          AgentValidationPolicyDecision(
        validationRequired: true,
        risk: AgentDecisionRisk.critical,
        reason:
            'Action is permanently forbidden for AI. '
            'It must never be treated as normal executable work.',
      );

      decision.validate();
      return decision;
    }

    final List<String> criticalReasons = <String>[];

    if (affectsPermissions) {
      criticalReasons.add('permission change');
    }

    if (affectsSafety) {
      criticalReasons.add('safety impact');
    }

    if (affectsProduction) {
      criticalReasons.add('production impact');
    }

    if (irreversible) {
      criticalReasons.add('irreversible operation');
    }

    if (criticalReasons.isNotEmpty) {
      final AgentValidationPolicyDecision decision =
          AgentValidationPolicyDecision(
        validationRequired: true,
        risk: AgentDecisionRisk.critical,
        reason:
            'Critical decision requires independent validation: '
            '${criticalReasons.join(", ")}.',
      );

      decision.validate();
      return decision;
    }

    final List<String> highReasons = <String>[];

    if (affectsMoney) {
      highReasons.add('financial impact');
    }

    if (affectsAccountStatus) {
      highReasons.add('account status impact');
    }

    if (requiresApproval) {
      highReasons.add('approval-required action');
    }

    if (containsSensitiveData) {
      highReasons.add('sensitive data');
    }

    if (usesPaidAi) {
      highReasons.add('paid AI usage');
    }

    if (highReasons.isNotEmpty) {
      final AgentValidationPolicyDecision decision =
          AgentValidationPolicyDecision(
        validationRequired: true,
        risk: AgentDecisionRisk.high,
        reason:
            'High-risk decision requires independent validation: '
            '${highReasons.join(", ")}.',
      );

      decision.validate();
      return decision;
    }

    if (writesData) {
      final AgentValidationPolicyDecision decision =
          const AgentValidationPolicyDecision(
        validationRequired: true,
        risk: AgentDecisionRisk.medium,
        reason:
            'Data-changing recommendation requires second-agent validation.',
      );

      decision.validate();
      return decision;
    }

    final AgentValidationPolicyDecision decision =
        const AgentValidationPolicyDecision(
      validationRequired: false,
      risk: AgentDecisionRisk.low,
      reason:
          'Read-only/low-risk recommendation does not require mandatory second-agent validation.',
    );

    decision.validate();
    return decision;
  }
}

class AgentValidationPolicyException
    implements Exception {
  final String message;

  const AgentValidationPolicyException(
    this.message,
  );

  @override
  String toString() =>
      'AgentValidationPolicyException: $message';
}