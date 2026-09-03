import '../constants/agent_provider_constants.dart';
import '../models/agent_provider_health.dart';
import '../models/agent_provider_routing_profile.dart';

// =========================================================
// AI AGENT - PROVIDER SELECTION POLICY
// =========================================================
//
// Phase 29 Step 3.
//
// PURE SELECTION POLICY:
// - capability matching
// - provider enabled check
// - provider health check
// - daily quota check
// - rate-limit check
// - max-cost-tier check
// - priority ordering
// - controlled fallback eligibility
//
// NO API CALLS.
// NO FIRESTORE WRITES.
// NO PROVIDER EXECUTION.
// NO SECRET ACCESS.

class AgentProviderSelectionCandidate {
  final AgentProviderRoutingProfile profile;
  final AgentProviderHealth health;
  final int requestsInCurrentWindow;

  const AgentProviderSelectionCandidate({
    required this.profile,
    required this.health,
    this.requestsInCurrentWindow = 0,
  });

  void validate() {
    profile.validate();

    if (health.providerId.trim().isEmpty) {
      throw const AgentProviderSelectionException(
        'Provider health providerId cannot be empty.',
      );
    }

    if (health.providerId != profile.providerId) {
      throw AgentProviderSelectionException(
        'Provider health/profile ID mismatch: '
        '${health.providerId} != ${profile.providerId}.',
      );
    }

    if (requestsInCurrentWindow < 0) {
      throw const AgentProviderSelectionException(
        'requestsInCurrentWindow cannot be negative.',
      );
    }
  }
}

class AgentProviderSelectionDecision {
  final String providerId;
  final bool eligible;
  final String reason;
  final int priority;
  final String costTier;

  const AgentProviderSelectionDecision({
    required this.providerId,
    required this.eligible,
    required this.reason,
    required this.priority,
    required this.costTier,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'providerId': providerId,
      'eligible': eligible,
      'reason': reason,
      'priority': priority,
      'costTier': costTier,
    };
  }
}

class AgentProviderSelectionResult {
  final List<AgentProviderSelectionDecision> decisions;
  final List<String> orderedEligibleProviderIds;

  const AgentProviderSelectionResult({
    required this.decisions,
    required this.orderedEligibleProviderIds,
  });

  bool get hasEligibleProvider =>
      orderedEligibleProviderIds.isNotEmpty;

  String? get primaryProviderId =>
      orderedEligibleProviderIds.isEmpty
          ? null
          : orderedEligibleProviderIds.first;

  List<String> get fallbackProviderIds =>
      orderedEligibleProviderIds.length <= 1
          ? const <String>[]
          : List<String>.unmodifiable(
              orderedEligibleProviderIds.skip(1),
            );

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'hasEligibleProvider': hasEligibleProvider,
      'primaryProviderId': primaryProviderId,
      'fallbackProviderIds': fallbackProviderIds,
      'orderedEligibleProviderIds':
          orderedEligibleProviderIds,
      'decisions': decisions
          .map(
            (AgentProviderSelectionDecision item) =>
                item.toMap(),
          )
          .toList(growable: false),
    };
  }
}

class AgentProviderSelectionPolicy {
  const AgentProviderSelectionPolicy();

  AgentProviderSelectionResult select({
    required Iterable<AgentProviderSelectionCandidate>
        candidates,
    required String requiredCapability,
    String maxCostTier = AgentProviderCostTier.high,
    bool allowFallback = true,
  }) {
    if (!AgentProviderCapability.isValid(
      requiredCapability,
    )) {
      throw AgentProviderSelectionException(
        'Invalid required capability '
        '"$requiredCapability".',
      );
    }

    if (!AgentProviderCostTier.isValid(maxCostTier)) {
      throw AgentProviderSelectionException(
        'Invalid max cost tier "$maxCostTier".',
      );
    }

    final List<AgentProviderSelectionCandidate>
        candidateList =
        candidates.toList(growable: false);

    final List<AgentProviderSelectionDecision>
        decisions =
        <AgentProviderSelectionDecision>[];

    final List<AgentProviderSelectionCandidate>
        eligible =
        <AgentProviderSelectionCandidate>[];

    for (final AgentProviderSelectionCandidate
        candidate in candidateList) {
      candidate.validate();

      final AgentProviderSelectionDecision decision =
          _evaluateCandidate(
        candidate: candidate,
        requiredCapability: requiredCapability,
        maxCostTier: maxCostTier,
      );

      decisions.add(decision);

      if (decision.eligible) {
        eligible.add(candidate);
      }
    }

    eligible.sort(
      (
        AgentProviderSelectionCandidate a,
        AgentProviderSelectionCandidate b,
      ) {
        final int costCompare = _costRank(
          a.profile.costTier,
        ).compareTo(
          _costRank(b.profile.costTier),
        );

        if (costCompare != 0) {
          return costCompare;
        }

        final int healthCompare = _healthRank(
          a.health.status,
        ).compareTo(
          _healthRank(b.health.status),
        );

        if (healthCompare != 0) {
          return healthCompare;
        }

        return a.profile.priority.compareTo(
          b.profile.priority,
        );
      },
    );

    List<String> orderedIds = eligible
        .map(
          (AgentProviderSelectionCandidate candidate) =>
              candidate.profile.providerId,
        )
        .toList(growable: false);

    if (!allowFallback && orderedIds.length > 1) {
      orderedIds = <String>[
        orderedIds.first,
      ];
    } else if (allowFallback) {
      final String? primaryId =
          orderedIds.isEmpty
              ? null
              : orderedIds.first;

      orderedIds = orderedIds
          .where(
            (String providerId) {
              if (providerId == primaryId) {
                return true;
              }

              final AgentProviderSelectionCandidate
                  candidate =
                  eligible.firstWhere(
                (
                  AgentProviderSelectionCandidate item,
                ) =>
                    item.profile.providerId ==
                    providerId,
              );

              return candidate
                  .profile.fallbackEligible;
            },
          )
          .toList(growable: false);
    }

    return AgentProviderSelectionResult(
      decisions:
          List<AgentProviderSelectionDecision>.unmodifiable(
        decisions,
      ),
      orderedEligibleProviderIds:
          List<String>.unmodifiable(
        orderedIds,
      ),
    );
  }

  AgentProviderSelectionDecision _evaluateCandidate({
    required AgentProviderSelectionCandidate candidate,
    required String requiredCapability,
    required String maxCostTier,
  }) {
    final AgentProviderRoutingProfile profile =
        candidate.profile;

    final AgentProviderHealth health =
        candidate.health;

    if (!profile.enabled) {
      return _deny(
        profile,
        'Provider routing profile is disabled.',
      );
    }

    if (!profile.supportsCapability(
      requiredCapability,
    )) {
      return _deny(
        profile,
        'Provider does not support required capability.',
      );
    }

    if (_costRank(profile.costTier) >
        _costRank(maxCostTier)) {
      return _deny(
        profile,
        'Provider exceeds maximum allowed cost tier.',
      );
    }

    if (health.status ==
            AgentProviderStatus.unavailable ||
        health.status ==
            AgentProviderStatus.disabled) {
      return _deny(
        profile,
        'Provider health status is ${health.status}.',
      );
    }

    if (profile.hasDailyQuota &&
        health.requestsToday >=
            profile.dailyRequestLimit) {
      return _deny(
        profile,
        'Provider daily request quota reached.',
      );
    }

    if (profile.hasRateLimit &&
        candidate.requestsInCurrentWindow >=
            profile.rateLimitMaxRequests) {
      return _deny(
        profile,
        'Provider rate limit reached for current window.',
      );
    }

    return AgentProviderSelectionDecision(
      providerId: profile.providerId,
      eligible: true,
      reason:
          'Provider is eligible for controlled routing.',
      priority: profile.priority,
      costTier: profile.costTier,
    );
  }

  AgentProviderSelectionDecision _deny(
    AgentProviderRoutingProfile profile,
    String reason,
  ) {
    return AgentProviderSelectionDecision(
      providerId: profile.providerId,
      eligible: false,
      reason: reason,
      priority: profile.priority,
      costTier: profile.costTier,
    );
  }

  int _costRank(String costTier) {
    switch (costTier) {
      case AgentProviderCostTier.free:
        return 0;
      case AgentProviderCostTier.low:
        return 1;
      case AgentProviderCostTier.medium:
        return 2;
      case AgentProviderCostTier.high:
        return 3;
      default:
        return 999;
    }
  }

  int _healthRank(String status) {
    switch (status) {
      case AgentProviderStatus.healthy:
        return 0;
      case AgentProviderStatus.unknown:
        return 1;
      case AgentProviderStatus.degraded:
        return 2;
      case AgentProviderStatus.unavailable:
        return 3;
      case AgentProviderStatus.disabled:
        return 4;
      default:
        return 999;
    }
  }
}

class AgentProviderSelectionException
    implements Exception {
  final String message;

  const AgentProviderSelectionException(
    this.message,
  );

  @override
  String toString() =>
      'AgentProviderSelectionException: $message';
}