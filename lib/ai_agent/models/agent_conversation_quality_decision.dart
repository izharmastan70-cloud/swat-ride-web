import '../constants/agent_conversation_quality_constants.dart';

/// One source/evidence reference used to support a conversation decision.
///
/// This is descriptive metadata only. It does not fetch, mutate or execute.
class AgentConversationEvidenceRef {
  const AgentConversationEvidenceRef({
    required this.sourceId,
    required this.sourceType,
    required this.summary,
    required this.verified,
  });

  final String sourceId;
  final String sourceType;
  final String summary;
  final bool verified;

  void validate() {
    if (sourceId.trim().isEmpty ||
        sourceType.trim().isEmpty ||
        summary.trim().isEmpty) {
      throw const AgentConversationQualityException(
        'Evidence source id/type/summary cannot be empty.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'sourceId': sourceId.trim(),
      'sourceType': sourceType.trim(),
      'summary': summary.trim(),
      'verified': verified,
    };
  }

  factory AgentConversationEvidenceRef.fromMap(Map<String, dynamic> map) {
    final AgentConversationEvidenceRef value = AgentConversationEvidenceRef(
      sourceId: (map['sourceId'] ?? '').toString(),
      sourceType: (map['sourceType'] ?? '').toString(),
      summary: (map['summary'] ?? '').toString(),
      verified: map['verified'] == true,
    );

    value.validate();
    return value;
  }
}

/// Pure Phase 43 anti-wrong-answer decision.
///
/// This contract decides what an agent SHOULD do with available evidence:
/// answer, verify, clarify, safe-fallback, escalate, or refuse.
///
/// It grants no runtime authority and cannot call providers, consume approvals,
/// mutate business state, update prompts/models, or deploy anything.
class AgentConversationQualityDecision {
  const AgentConversationQualityDecision({
    required this.action,
    required this.knowledgeState,
    required this.risk,
    required this.confidence,
    required this.reason,
    required this.evidenceRefs,
    required this.requiresFreshVerification,
    required this.requiresClarification,
    required this.requiresHumanEscalation,
    required this.mustDiscloseUncertainty,
    required this.mustNotInvent,
  });

  final String action;
  final String knowledgeState;
  final String risk;

  /// Explicit 0.0..1.0 confidence in the current evidence-supported decision.
  ///
  /// Confidence never grants permission and never bypasses verification.
  final double confidence;

  final String reason;
  final List<AgentConversationEvidenceRef> evidenceRefs;

  final bool requiresFreshVerification;
  final bool requiresClarification;
  final bool requiresHumanEscalation;
  final bool mustDiscloseUncertainty;
  final bool mustNotInvent;

  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayCallProvider => false;
  bool get mayChangePrompt => false;
  bool get mayTrainModel => false;
  bool get mayDeploy => false;

  bool get hasVerifiedEvidence =>
      evidenceRefs.any((AgentConversationEvidenceRef value) => value.verified);

  bool get mayAnswerDirectly =>
      action == AgentConversationQualityAction.answer &&
      knowledgeState == AgentConversationKnowledgeState.sufficient &&
      confidence >= 0.80 &&
      hasVerifiedEvidence &&
      !requiresFreshVerification &&
      !requiresClarification &&
      !requiresHumanEscalation;

  void validate() {
    if (!AgentConversationQualityAction.values.contains(action)) {
      throw AgentConversationQualityException(
        'Invalid conversation quality action "$action".',
      );
    }

    if (!AgentConversationKnowledgeState.values.contains(knowledgeState)) {
      throw AgentConversationQualityException(
        'Invalid knowledge state "$knowledgeState".',
      );
    }

    if (!AgentConversationRisk.values.contains(risk)) {
      throw AgentConversationQualityException(
        'Invalid conversation risk "$risk".',
      );
    }

    if (confidence < 0 || confidence > 1) {
      throw const AgentConversationQualityException(
        'Conversation confidence must be between 0.0 and 1.0.',
      );
    }

    if (reason.trim().isEmpty) {
      throw const AgentConversationQualityException(
        'Conversation quality reason cannot be empty.',
      );
    }

    final Set<String> evidenceIdentities = <String>{};

    for (final AgentConversationEvidenceRef evidence in evidenceRefs) {
      evidence.validate();

      final String identity =
          '${evidence.sourceType.trim()}::${evidence.sourceId.trim()}';

      if (!evidenceIdentities.add(identity)) {
        throw AgentConversationQualityException(
          'Duplicate conversation evidence "$identity".',
        );
      }
    }

    if (!mustNotInvent) {
      throw const AgentConversationQualityException(
        'Anti-wrong-answer decisions must always set mustNotInvent=true.',
      );
    }

    if (action == AgentConversationQualityAction.answer) {
      if (knowledgeState != AgentConversationKnowledgeState.sufficient) {
        throw const AgentConversationQualityException(
          'Direct ANSWER requires SUFFICIENT knowledge.',
        );
      }

      if (confidence < 0.80) {
        throw const AgentConversationQualityException(
          'Direct ANSWER requires confidence >= 0.80.',
        );
      }

      if (!hasVerifiedEvidence) {
        throw const AgentConversationQualityException(
          'Direct ANSWER requires at least one verified evidence source.',
        );
      }

      if (requiresFreshVerification ||
          requiresClarification ||
          requiresHumanEscalation) {
        throw const AgentConversationQualityException(
          'Direct ANSWER cannot retain unresolved verify/clarify/escalate requirements.',
        );
      }
    }

    if (knowledgeState == AgentConversationKnowledgeState.missing ||
        knowledgeState == AgentConversationKnowledgeState.conflicting ||
        knowledgeState == AgentConversationKnowledgeState.unverified) {
      if (action == AgentConversationQualityAction.answer) {
        throw const AgentConversationQualityException(
          'Missing/conflicting/unverified knowledge cannot produce direct ANSWER.',
        );
      }

      if (!mustDiscloseUncertainty) {
        throw const AgentConversationQualityException(
          'Missing/conflicting/unverified knowledge must disclose uncertainty.',
        );
      }
    }

    if (action == AgentConversationQualityAction.verify &&
        !requiresFreshVerification) {
      throw const AgentConversationQualityException(
        'VERIFY action must require fresh verification.',
      );
    }

    if (action == AgentConversationQualityAction.clarify &&
        !requiresClarification) {
      throw const AgentConversationQualityException(
        'CLARIFY action must require clarification.',
      );
    }

    if (action == AgentConversationQualityAction.escalate &&
        !requiresHumanEscalation) {
      throw const AgentConversationQualityException(
        'ESCALATE action must require human escalation.',
      );
    }

    if ((risk == AgentConversationRisk.high ||
            risk == AgentConversationRisk.critical) &&
        action == AgentConversationQualityAction.answer &&
        confidence < 0.95) {
      throw const AgentConversationQualityException(
        'HIGH/CRITICAL direct ANSWER requires confidence >= 0.95.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'action': action,
      'knowledgeState': knowledgeState,
      'risk': risk,
      'confidence': confidence,
      'reason': reason.trim(),
      'evidenceRefs': evidenceRefs
          .map((AgentConversationEvidenceRef value) => value.toMap())
          .toList(growable: false),
      'requiresFreshVerification': requiresFreshVerification,
      'requiresClarification': requiresClarification,
      'requiresHumanEscalation': requiresHumanEscalation,
      'mustDiscloseUncertainty': mustDiscloseUncertainty,
      'mustNotInvent': true,
      'mayGrantPermission': false,
      'mayConsumeApproval': false,
      'mayWriteBusinessData': false,
      'mayCallProvider': false,
      'mayChangePrompt': false,
      'mayTrainModel': false,
      'mayDeploy': false,
    };
  }

  factory AgentConversationQualityDecision.fromMap(Map<String, dynamic> map) {
    final AgentConversationQualityDecision value =
        AgentConversationQualityDecision(
          action: (map['action'] ?? '').toString(),
          knowledgeState: (map['knowledgeState'] ?? '').toString(),
          risk: (map['risk'] ?? '').toString(),
          confidence: (map['confidence'] as num?)?.toDouble() ?? -1,
          reason: (map['reason'] ?? '').toString(),
          evidenceRefs: (map['evidenceRefs'] as List? ?? const <dynamic>[])
              .map(
                (dynamic raw) => AgentConversationEvidenceRef.fromMap(
                  Map<String, dynamic>.from(raw as Map),
                ),
              )
              .toList(growable: false),
          requiresFreshVerification: map['requiresFreshVerification'] == true,
          requiresClarification: map['requiresClarification'] == true,
          requiresHumanEscalation: map['requiresHumanEscalation'] == true,
          mustDiscloseUncertainty: map['mustDiscloseUncertainty'] == true,
          mustNotInvent: map['mustNotInvent'] == true,
        );

    value.validate();
    return value;
  }
}

class AgentConversationQualityException implements Exception {
  const AgentConversationQualityException(this.message);

  final String message;

  @override
  String toString() => 'AgentConversationQualityException: $message';
}
