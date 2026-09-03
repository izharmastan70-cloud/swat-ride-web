import '../constants/agent_evaluation_constants.dart';

/// Explicit expected outcome for one synthetic/offline evaluation case.
///
/// This contract is descriptive only. It grants no runtime permission and
/// cannot approve, execute, deploy, mutate prompts, or train a model.
class AgentEvaluationExpectation {
  const AgentEvaluationExpectation({
    required this.expectedDecision,
    required this.expectedBehaviorSummary,
    required this.requiresApproval,
    required this.mustRefuse,
    required this.mustEscalate,
    required this.mustProtectPrivateData,
    required this.mustUseSafeFallback,
    required this.mustNotWrite,
    required this.mustNotDeploy,
  });

  final String expectedDecision;
  final String expectedBehaviorSummary;

  final bool requiresApproval;
  final bool mustRefuse;
  final bool mustEscalate;
  final bool mustProtectPrivateData;
  final bool mustUseSafeFallback;
  final bool mustNotWrite;
  final bool mustNotDeploy;

  void validate() {
    if (!AgentEvaluationExpectedDecision.values.contains(expectedDecision)) {
      throw AgentEvaluationCaseException(
        'Invalid expected decision "$expectedDecision".',
      );
    }

    if (expectedBehaviorSummary.trim().isEmpty) {
      throw const AgentEvaluationCaseException(
        'Expected behavior summary cannot be empty.',
      );
    }

    if (expectedDecision == AgentEvaluationExpectedDecision.askApproval &&
        !requiresApproval) {
      throw const AgentEvaluationCaseException(
        'ASK_APPROVAL expectation must require approval.',
      );
    }

    if (expectedDecision == AgentEvaluationExpectedDecision.refuse &&
        !mustRefuse) {
      throw const AgentEvaluationCaseException(
        'REFUSE expectation must set mustRefuse=true.',
      );
    }

    if (expectedDecision == AgentEvaluationExpectedDecision.escalate &&
        !mustEscalate) {
      throw const AgentEvaluationCaseException(
        'ESCALATE expectation must set mustEscalate=true.',
      );
    }

    if (expectedDecision == AgentEvaluationExpectedDecision.safeFallback &&
        !mustUseSafeFallback) {
      throw const AgentEvaluationCaseException(
        'SAFE_FALLBACK expectation must set mustUseSafeFallback=true.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'expectedDecision': expectedDecision,
      'expectedBehaviorSummary': expectedBehaviorSummary.trim(),
      'requiresApproval': requiresApproval,
      'mustRefuse': mustRefuse,
      'mustEscalate': mustEscalate,
      'mustProtectPrivateData': mustProtectPrivateData,
      'mustUseSafeFallback': mustUseSafeFallback,
      'mustNotWrite': mustNotWrite,
      'mustNotDeploy': mustNotDeploy,
    };
  }

  factory AgentEvaluationExpectation.fromMap(Map<String, dynamic> map) {
    final AgentEvaluationExpectation value = AgentEvaluationExpectation(
      expectedDecision: (map['expectedDecision'] ?? '').toString(),
      expectedBehaviorSummary: (map['expectedBehaviorSummary'] ?? '')
          .toString(),
      requiresApproval: map['requiresApproval'] == true,
      mustRefuse: map['mustRefuse'] == true,
      mustEscalate: map['mustEscalate'] == true,
      mustProtectPrivateData: map['mustProtectPrivateData'] == true,
      mustUseSafeFallback: map['mustUseSafeFallback'] == true,
      mustNotWrite: map['mustNotWrite'] == true,
      mustNotDeploy: map['mustNotDeploy'] == true,
    );

    value.validate();
    return value;
  }
}

/// Fixture-safety declaration.
///
/// Phase 42 evaluation fixtures are synthetic/offline by default. Secrets,
/// private user content, payment credentials and production credentials are
/// forbidden in this contract.
class AgentEvaluationFixtureSafety {
  const AgentEvaluationFixtureSafety({
    this.syntheticOnly = true,
    this.containsSecrets = false,
    this.containsPrivateUserData = false,
    this.containsPaymentCredentials = false,
    this.containsProductionCredentials = false,
  });

  final bool syntheticOnly;
  final bool containsSecrets;
  final bool containsPrivateUserData;
  final bool containsPaymentCredentials;
  final bool containsProductionCredentials;

  bool get safeForEvaluation =>
      syntheticOnly &&
      !containsSecrets &&
      !containsPrivateUserData &&
      !containsPaymentCredentials &&
      !containsProductionCredentials;

  void validate() {
    if (!safeForEvaluation) {
      throw const AgentEvaluationCaseException(
        'Evaluation fixtures must be synthetic and must not contain '
        'secrets, private user data, payment credentials, or production '
        'credentials.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'syntheticOnly': syntheticOnly,
      'containsSecrets': containsSecrets,
      'containsPrivateUserData': containsPrivateUserData,
      'containsPaymentCredentials': containsPaymentCredentials,
      'containsProductionCredentials': containsProductionCredentials,
    };
  }

  factory AgentEvaluationFixtureSafety.fromMap(Map<String, dynamic> map) {
    final AgentEvaluationFixtureSafety value = AgentEvaluationFixtureSafety(
      syntheticOnly: map['syntheticOnly'] == true,
      containsSecrets: map['containsSecrets'] == true,
      containsPrivateUserData: map['containsPrivateUserData'] == true,
      containsPaymentCredentials: map['containsPaymentCredentials'] == true,
      containsProductionCredentials:
          map['containsProductionCredentials'] == true,
    );

    value.validate();
    return value;
  }
}

/// One deterministic evaluation scenario.
///
/// This is intentionally a pure data contract:
/// - no Firestore import;
/// - no provider call;
/// - no runtime action execution;
/// - no prompt/model mutation;
/// - no autonomous learning;
/// - no production deployment.
class AgentEvaluationCase {
  const AgentEvaluationCase({
    required this.caseId,
    required this.title,
    required this.roleId,
    required this.module,
    required this.category,
    required this.risk,
    required this.inputPrompt,
    required this.expectation,
    required this.fixtureSafety,
    required this.tags,
    required this.version,
    required this.enabled,
    required this.createdAt,
  });

  final String caseId;
  final String title;
  final String roleId;
  final String module;
  final String category;
  final String risk;
  final String inputPrompt;
  final AgentEvaluationExpectation expectation;
  final AgentEvaluationFixtureSafety fixtureSafety;
  final List<String> tags;
  final int version;
  final bool enabled;
  final DateTime createdAt;

  bool get isRuntimeExecutable => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayChangePrompt => false;
  bool get mayTrainModel => false;
  bool get mayDeploy => false;

  void validate() {
    if (caseId.trim().isEmpty ||
        title.trim().isEmpty ||
        roleId.trim().isEmpty ||
        module.trim().isEmpty ||
        inputPrompt.trim().isEmpty) {
      throw const AgentEvaluationCaseException(
        'Evaluation identity, role/module and input fields cannot be empty.',
      );
    }

    if (!AgentEvaluationCategory.values.contains(category)) {
      throw AgentEvaluationCaseException(
        'Invalid evaluation category "$category".',
      );
    }

    if (!AgentEvaluationRisk.values.contains(risk)) {
      throw AgentEvaluationCaseException('Invalid evaluation risk "$risk".');
    }

    if (version < 1) {
      throw const AgentEvaluationCaseException(
        'Evaluation case version must be >= 1.',
      );
    }

    final List<String> normalizedTags = tags
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);

    if (normalizedTags.length != tags.length) {
      throw const AgentEvaluationCaseException(
        'Evaluation tags cannot contain empty values.',
      );
    }

    if (normalizedTags.toSet().length != normalizedTags.length) {
      throw const AgentEvaluationCaseException(
        'Evaluation tags must be unique.',
      );
    }

    expectation.validate();
    fixtureSafety.validate();
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'caseId': caseId.trim(),
      'title': title.trim(),
      'roleId': roleId.trim(),
      'module': module.trim(),
      'category': category,
      'risk': risk,
      'inputPrompt': inputPrompt,
      'expectation': expectation.toMap(),
      'fixtureSafety': fixtureSafety.toMap(),
      'tags': tags.map((String value) => value.trim()).toList(),
      'version': version,
      'enabled': enabled,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'isRuntimeExecutable': false,
      'mayGrantPermission': false,
      'mayConsumeApproval': false,
      'mayWriteBusinessData': false,
      'mayChangePrompt': false,
      'mayTrainModel': false,
      'mayDeploy': false,
    };
  }

  factory AgentEvaluationCase.fromMap(Map<String, dynamic> map) {
    final AgentEvaluationCase value = AgentEvaluationCase(
      caseId: (map['caseId'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      roleId: (map['roleId'] ?? '').toString(),
      module: (map['module'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      risk: (map['risk'] ?? '').toString(),
      inputPrompt: (map['inputPrompt'] ?? '').toString(),
      expectation: AgentEvaluationExpectation.fromMap(
        Map<String, dynamic>.from(
          map['expectation'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      fixtureSafety: AgentEvaluationFixtureSafety.fromMap(
        Map<String, dynamic>.from(
          map['fixtureSafety'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      tags: (map['tags'] as List? ?? const <dynamic>[])
          .map((dynamic value) => value.toString())
          .toList(growable: false),
      version: (map['version'] as num?)?.toInt() ?? 0,
      enabled: map['enabled'] == true,
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );

    value.validate();
    return value;
  }
}

class AgentEvaluationCaseException implements Exception {
  const AgentEvaluationCaseException(this.message);

  final String message;

  @override
  String toString() => 'AgentEvaluationCaseException: $message';
}
