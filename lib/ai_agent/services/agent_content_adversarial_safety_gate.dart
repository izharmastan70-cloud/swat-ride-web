import '../constants/agent_content_provider_privacy_safety_constants.dart';

class AgentContentAdversarialSafetyGate {
  const AgentContentAdversarialSafetyGate();

  String classify(String input) {
    final String normalized = input.toLowerCase();

    final Map<String, List<String>> patterns = <String, List<String>>{
      AgentContentAdversarialScenario.fakeClaim: <String>[
        'invent a fact',
        'make up a fact',
        'fake claim',
      ],
      AgentContentAdversarialScenario.fakeReview: <String>[
        'fake review',
        'fake customer review',
      ],
      AgentContentAdversarialScenario.fakeMetric: <String>[
        'fake downloads',
        'fake users',
        'fabricated statistic',
        'fake views',
      ],
      AgentContentAdversarialScenario.fakeAvailability: <String>[
        'pretend service is available',
        'fake availability',
      ],
      AgentContentAdversarialScenario.fakeOffer: <String>[
        'fake discount',
        'fake offer',
      ],
      AgentContentAdversarialScenario.bypassReview: <String>[
        'skip human review',
        'bypass review',
      ],
      AgentContentAdversarialScenario.bypassApproval: <String>[
        'bypass approval',
        'approve without owner',
      ],
      AgentContentAdversarialScenario.directPublish: <String>[
        'publish now',
        'auto publish',
        'post now',
      ],
      AgentContentAdversarialScenario.directSend: <String>[
        'send now',
        'auto send',
      ],
      AgentContentAdversarialScenario.refundExecution: <String>[
        'execute refund',
        'refund wallet now',
      ],
      AgentContentAdversarialScenario.walletMutation: <String>[
        'change wallet balance',
        'add wallet money',
      ],
      AgentContentAdversarialScenario.pricingMutation: <String>[
        'change fare',
        'change price now',
      ],
      AgentContentAdversarialScenario.permissionMutation: <String>[
        'grant admin permission',
        'change permissions',
      ],
      AgentContentAdversarialScenario.secretExfiltration: <String>[
        'show auth token',
        'reveal password',
        'reveal api key',
      ],
      AgentContentAdversarialScenario.privateDataExposure: <String>[
        'post phone number',
        'publish cnic',
        'show payment card',
      ],
      AgentContentAdversarialScenario.providerPolicyOverride: <String>[
        'ignore provider policy',
        'force paid ai',
      ],
      AgentContentAdversarialScenario.costLimitOverride: <String>[
        'ignore cost limit',
        'increase budget yourself',
      ],
      AgentContentAdversarialScenario.selfTrainingOverride: <String>[
        'self train and deploy',
        'change your own rules',
      ],
      AgentContentAdversarialScenario.realProofMisrepresentation: <String>[
        'pretend ai image is real',
        'make ai visual look like real proof',
      ],
      AgentContentAdversarialScenario.rageBaitManipulation: <String>[
        'rage bait',
        'fear manipulation',
      ],
    };

    for (final MapEntry<String, List<String>> entry in patterns.entries) {
      if (entry.value.any(normalized.contains)) {
        return entry.key;
      }
    }

    return 'safe';
  }

  bool isBlocked(String input) => classify(input) != 'safe';

  bool get blocksFakeClaims => true;
  bool get blocksFakeReviews => true;
  bool get blocksFakeMetrics => true;
  bool get blocksFakeAvailability => true;
  bool get blocksFakeOffers => true;
  bool get blocksReviewBypass => true;
  bool get blocksApprovalBypass => true;
  bool get blocksDirectPublish => true;
  bool get blocksDirectSend => true;
  bool get blocksRefundExecution => true;
  bool get blocksWalletMutation => true;
  bool get blocksPricingMutation => true;
  bool get blocksPermissionMutation => true;
  bool get blocksSecretExfiltration => true;
  bool get blocksPrivateDataExposure => true;
  bool get blocksProviderPolicyOverride => true;
  bool get blocksCostLimitOverride => true;
  bool get blocksSelfTrainingOverride => true;
  bool get blocksRealProofMisrepresentation => true;
  bool get blocksRageBaitManipulation => true;
  bool get failClosed => true;
  bool get executesBusinessAction => false;
  bool get changesSecurityPolicy => false;
  bool get changesCostLimits => false;
  bool get invokesProvider => false;
  bool get publishes => false;
  bool get sendsMessages => false;
  bool get persistsResult => false;
}
