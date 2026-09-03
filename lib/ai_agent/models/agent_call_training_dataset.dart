import '../constants/agent_call_constants.dart';
import '../constants/agent_evaluation_constants.dart';
import 'agent_evaluation_case.dart';

class AgentCallTrainingCapability {
  AgentCallTrainingCapability._();

  static const String rideBooking = 'RIDE_BOOKING';
  static const String existingRideStatus = 'EXISTING_RIDE_STATUS';
  static const String foodOrderStatus = 'FOOD_ORDER_STATUS';
  static const String tourBookingStatus = 'TOUR_BOOKING_STATUS';

  static const Set<String> values = <String>{
    rideBooking,
    existingRideStatus,
    foodOrderStatus,
    tourBookingStatus,
  };
}

class AgentCallTrainingDatasetMode {
  AgentCallTrainingDatasetMode._();

  static const String syntheticOffline = 'SYNTHETIC_OFFLINE';
}

class AgentCallTrainingScenario {
  const AgentCallTrainingScenario({
    required this.scenarioId,
    required this.datasetVersion,
    required this.title,
    required this.capability,
    required this.syntheticCallerUtterance,
    required this.syntheticContextSummary,
    required this.expectedActionId,
    required this.expectedEscalationLevel,
    required this.expectedEvaluationDecision,
    required this.requiresTrustedBinding,
    required this.requiresFreshVerification,
    required this.requiresCustomerConfirmation,
    required this.mustProtectPrivateData,
    required this.mustNotWriteBusinessData,
    required this.mustNotGrantPermission,
    required this.mustNotUseTranscriptAsAuthority,
    required this.mustNotUseLiveProvider,
    required this.enabled,
    required this.tags,
  });

  final String scenarioId;
  final int datasetVersion;
  final String title;
  final String capability;

  /// Synthetic training text only. Never caller identity or authority.
  final String syntheticCallerUtterance;

  /// Privacy-minimized synthetic context only.
  final String syntheticContextSummary;

  /// One of the four Phase 49 dedicated Call action IDs, or empty when the
  /// correct behavior is escalation/refusal/fallback before any action.
  final String expectedActionId;

  final String expectedEscalationLevel;
  final String expectedEvaluationDecision;

  final bool requiresTrustedBinding;
  final bool requiresFreshVerification;
  final bool requiresCustomerConfirmation;

  final bool mustProtectPrivateData;
  final bool mustNotWriteBusinessData;
  final bool mustNotGrantPermission;
  final bool mustNotUseTranscriptAsAuthority;
  final bool mustNotUseLiveProvider;

  final bool enabled;
  final List<String> tags;

  bool get isSyntheticOnly => true;
  bool get isRuntimeExecutable => false;
  bool get mayTrainModel => false;
  bool get mayChangePrompt => false;
  bool get mayDeploy => false;
  bool get mayConsumeApproval => false;
  bool get mayGrantAuthority => false;

  void validate() {
    if (scenarioId.trim().isEmpty ||
        title.trim().isEmpty ||
        syntheticCallerUtterance.trim().isEmpty ||
        syntheticContextSummary.trim().isEmpty) {
      throw const AgentCallTrainingDatasetException(
        'Call training scenario identity/text cannot be empty.',
      );
    }

    if (datasetVersion < 1) {
      throw const AgentCallTrainingDatasetException(
        'Call training dataset version must be >= 1.',
      );
    }

    if (!AgentCallTrainingCapability.values.contains(capability)) {
      throw AgentCallTrainingDatasetException(
        'Unsupported Call training capability: $capability',
      );
    }

    if (!<String>{
      AgentCallEscalationLevel.ai,
      AgentCallEscalationLevel.humanSupport,
      AgentCallEscalationLevel.managerAdmin,
      AgentCallEscalationLevel.owner,
    }.contains(expectedEscalationLevel)) {
      throw AgentCallTrainingDatasetException(
        'Unsupported Call escalation level: $expectedEscalationLevel',
      );
    }

    if (!AgentEvaluationExpectedDecision.values.contains(
      expectedEvaluationDecision,
    )) {
      throw AgentCallTrainingDatasetException(
        'Unsupported evaluation decision: $expectedEvaluationDecision',
      );
    }

    if (!mustProtectPrivateData ||
        !mustNotWriteBusinessData ||
        !mustNotGrantPermission ||
        !mustNotUseTranscriptAsAuthority ||
        !mustNotUseLiveProvider) {
      throw const AgentCallTrainingDatasetException(
        'All Call training scenarios must keep privacy, authority, write, '
        'transcript and provider safety locks enabled.',
      );
    }

    if (tags.isEmpty || tags.any((String tag) => tag.trim().isEmpty)) {
      throw const AgentCallTrainingDatasetException(
        'Call training scenario tags cannot be empty.',
      );
    }
  }

  AgentEvaluationCase toEvaluationCase({required DateTime createdAt}) {
    validate();

    final bool mustEscalate =
        expectedEvaluationDecision == AgentEvaluationExpectedDecision.escalate;

    final bool mustRefuse =
        expectedEvaluationDecision == AgentEvaluationExpectedDecision.refuse;

    final bool mustUseSafeFallback =
        expectedEvaluationDecision ==
        AgentEvaluationExpectedDecision.safeFallback;

    final String category = mustEscalate
        ? AgentEvaluationCategory.escalation
        : mustRefuse
        ? AgentEvaluationCategory.privacy
        : mustUseSafeFallback
        ? AgentEvaluationCategory.hallucinationControl
        : AgentEvaluationCategory.safeAnswer;

    final String risk =
        expectedEscalationLevel == AgentCallEscalationLevel.owner
        ? AgentEvaluationRisk.critical
        : expectedEscalationLevel == AgentCallEscalationLevel.managerAdmin
        ? AgentEvaluationRisk.high
        : expectedEscalationLevel == AgentCallEscalationLevel.humanSupport
        ? AgentEvaluationRisk.medium
        : AgentEvaluationRisk.low;

    return AgentEvaluationCase(
      caseId: 'call_training_$scenarioId',
      title: title,
      roleId: 'call_agent',
      module: 'call',
      category: category,
      risk: risk,
      inputPrompt:
          '$syntheticCallerUtterance\nContext: $syntheticContextSummary',
      expectation: AgentEvaluationExpectation(
        expectedDecision: expectedEvaluationDecision,
        expectedBehaviorSummary:
            'Capability=$capability; escalation=$expectedEscalationLevel; '
            'trustedBinding=$requiresTrustedBinding; '
            'freshVerification=$requiresFreshVerification; '
            'customerConfirmation=$requiresCustomerConfirmation; '
            'expectedAction=$expectedActionId.',
        requiresApproval: false,
        mustRefuse: mustRefuse,
        mustEscalate: mustEscalate,
        mustProtectPrivateData: true,
        mustUseSafeFallback: mustUseSafeFallback,
        mustNotWrite: true,
        mustNotDeploy: true,
      ),
      fixtureSafety: const AgentEvaluationFixtureSafety(),
      tags: <String>[
        'phase50',
        'call_training',
        capability.toLowerCase(),
        ...tags,
      ],
      version: datasetVersion,
      enabled: enabled,
      createdAt: createdAt.toUtc(),
    );
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return <String, dynamic>{
      'scenarioId': scenarioId.trim(),
      'datasetVersion': datasetVersion,
      'title': title.trim(),
      'capability': capability,
      'syntheticCallerUtterance': syntheticCallerUtterance.trim(),
      'syntheticContextSummary': syntheticContextSummary.trim(),
      'expectedActionId': expectedActionId.trim(),
      'expectedEscalationLevel': expectedEscalationLevel,
      'expectedEvaluationDecision': expectedEvaluationDecision,
      'requiresTrustedBinding': requiresTrustedBinding,
      'requiresFreshVerification': requiresFreshVerification,
      'requiresCustomerConfirmation': requiresCustomerConfirmation,
      'syntheticOnly': true,
      'runtimeExecutable': false,
      'mayGrantAuthority': false,
      'mayTrainModel': false,
      'mayChangePrompt': false,
      'mayDeploy': false,
      'mustProtectPrivateData': mustProtectPrivateData,
      'mustNotWriteBusinessData': mustNotWriteBusinessData,
      'mustNotGrantPermission': mustNotGrantPermission,
      'mustNotUseTranscriptAsAuthority': mustNotUseTranscriptAsAuthority,
      'mustNotUseLiveProvider': mustNotUseLiveProvider,
      'enabled': enabled,
      'tags': List<String>.unmodifiable(tags),
    };
  }
}

class AgentCallTrainingDataset {
  const AgentCallTrainingDataset({
    required this.datasetId,
    required this.version,
    required this.createdAt,
    required this.scenarios,
  });

  static const String roleId = 'call_agent';
  static const String module = 'call';
  static const String mode = AgentCallTrainingDatasetMode.syntheticOffline;

  final String datasetId;
  final int version;
  final DateTime createdAt;
  final List<AgentCallTrainingScenario> scenarios;

  bool get usesLiveTelephony => false;
  bool get usesStt => false;
  bool get usesTts => false;
  bool get usesSms => false;
  bool get usesProductionBusinessData => false;
  bool get silentlySelfTrains => false;
  bool get autoDeploys => false;
  bool get expandsPermissions => false;
  bool get transcriptIsAuthority => false;

  void validate() {
    if (datasetId.trim().isEmpty || version < 1) {
      throw const AgentCallTrainingDatasetException(
        'Call training dataset identity/version is invalid.',
      );
    }

    if (scenarios.isEmpty) {
      throw const AgentCallTrainingDatasetException(
        'Call training dataset cannot be empty.',
      );
    }

    final Set<String> ids = <String>{};
    final Set<String> capabilities = <String>{};

    for (final AgentCallTrainingScenario scenario in scenarios) {
      scenario.validate();

      if (scenario.datasetVersion != version) {
        throw const AgentCallTrainingDatasetException(
          'Every scenario must use the dataset version.',
        );
      }

      if (!ids.add(scenario.scenarioId.trim())) {
        throw AgentCallTrainingDatasetException(
          'Duplicate Call training scenario ID: ${scenario.scenarioId}',
        );
      }

      capabilities.add(scenario.capability);

      final AgentEvaluationCase evaluationCase = scenario.toEvaluationCase(
        createdAt: createdAt,
      );

      evaluationCase.validate();

      if (!evaluationCase.fixtureSafety.safeForEvaluation ||
          evaluationCase.isRuntimeExecutable ||
          evaluationCase.mayGrantPermission ||
          evaluationCase.mayWriteBusinessData ||
          evaluationCase.mayTrainModel ||
          evaluationCase.mayDeploy) {
        throw const AgentCallTrainingDatasetException(
          'Mapped Phase 42 evaluation case violates training safety.',
        );
      }
    }

    if (!capabilities.containsAll(AgentCallTrainingCapability.values)) {
      throw const AgentCallTrainingDatasetException(
        'Dataset must cover all four Phase 49 Call capabilities.',
      );
    }
  }

  List<AgentEvaluationCase> toEvaluationCases() {
    validate();

    return scenarios
        .where((AgentCallTrainingScenario scenario) => scenario.enabled)
        .map(
          (AgentCallTrainingScenario scenario) =>
              scenario.toEvaluationCase(createdAt: createdAt),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> toSafeManifest() {
    validate();

    return <String, dynamic>{
      'datasetId': datasetId.trim(),
      'version': version,
      'roleId': roleId,
      'module': module,
      'mode': mode,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'scenarioCount': scenarios.length,
      'capabilities': AgentCallTrainingCapability.values.toList()..sort(),
      'usesLiveTelephony': false,
      'usesStt': false,
      'usesTts': false,
      'usesSms': false,
      'usesProductionBusinessData': false,
      'silentlySelfTrains': false,
      'autoDeploys': false,
      'expandsPermissions': false,
      'transcriptIsAuthority': false,
    };
  }
}

class AgentCallTrainingDatasetException implements Exception {
  const AgentCallTrainingDatasetException(this.message);

  final String message;

  @override
  String toString() => 'AgentCallTrainingDatasetException: $message';
}
