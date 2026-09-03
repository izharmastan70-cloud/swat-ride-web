import '../models/agent_provider_health.dart';
import '../models/agent_provider_routing_profile.dart';

// =========================================================
// AI AGENT - PROVIDER USAGE ACCOUNTING SERVICE
// =========================================================
//
// Phase 29 Step 6.
//
// Runtime accounting policy for:
// - daily quota
// - current rate-limit window
// - remaining capacity
// - quota/rate-limit blocking
//
// Existing AgentProviderHealth.requestsToday is reused.
//
// ACCOUNTING ONLY:
// - no Firestore write
// - no provider execution
// - no API call
// - no secret access
// - no automatic provider enable/disable

class AgentProviderUsageSnapshot {
  final String providerId;

  final int requestsToday;
  final int dailyRequestLimit;
  final int remainingDailyRequests;

  final int requestsInCurrentWindow;
  final int rateLimitMaxRequests;
  final int remainingWindowRequests;

  final bool dailyQuotaReached;
  final bool rateLimitReached;

  const AgentProviderUsageSnapshot({
    required this.providerId,
    required this.requestsToday,
    required this.dailyRequestLimit,
    required this.remainingDailyRequests,
    required this.requestsInCurrentWindow,
    required this.rateLimitMaxRequests,
    required this.remainingWindowRequests,
    required this.dailyQuotaReached,
    required this.rateLimitReached,
  });

  bool get blocked =>
      dailyQuotaReached || rateLimitReached;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'providerId': providerId,
      'requestsToday': requestsToday,
      'dailyRequestLimit': dailyRequestLimit,
      'remainingDailyRequests':
          remainingDailyRequests,
      'requestsInCurrentWindow':
          requestsInCurrentWindow,
      'rateLimitMaxRequests':
          rateLimitMaxRequests,
      'remainingWindowRequests':
          remainingWindowRequests,
      'dailyQuotaReached':
          dailyQuotaReached,
      'rateLimitReached':
          rateLimitReached,
      'blocked': blocked,
    };
  }
}

class AgentProviderUsageAccountingService {
  const AgentProviderUsageAccountingService();

  AgentProviderUsageSnapshot evaluate({
    required AgentProviderRoutingProfile profile,
    required AgentProviderHealth health,
    int requestsInCurrentWindow = 0,
  }) {
    profile.validate();

    if (health.providerId.trim().isEmpty) {
      throw const AgentProviderUsageAccountingException(
        'Provider health providerId cannot be empty.',
      );
    }

    if (health.providerId != profile.providerId) {
      throw AgentProviderUsageAccountingException(
        'Provider health/profile ID mismatch: '
        '${health.providerId} != ${profile.providerId}.',
      );
    }

    if (health.requestsToday < 0) {
      throw const AgentProviderUsageAccountingException(
        'requestsToday cannot be negative.',
      );
    }

    if (requestsInCurrentWindow < 0) {
      throw const AgentProviderUsageAccountingException(
        'requestsInCurrentWindow cannot be negative.',
      );
    }

    final bool hasDailyQuota =
        profile.hasDailyQuota;

    final bool dailyQuotaReached =
        hasDailyQuota &&
        health.requestsToday >=
            profile.dailyRequestLimit;

    final int remainingDaily =
        hasDailyQuota
            ? _remaining(
                limit: profile.dailyRequestLimit,
                used: health.requestsToday,
              )
            : -1;

    final bool hasRateLimit =
        profile.hasRateLimit;

    final bool rateLimitReached =
        hasRateLimit &&
        requestsInCurrentWindow >=
            profile.rateLimitMaxRequests;

    final int remainingWindow =
        hasRateLimit
            ? _remaining(
                limit:
                    profile.rateLimitMaxRequests,
                used:
                    requestsInCurrentWindow,
              )
            : -1;

    return AgentProviderUsageSnapshot(
      providerId: profile.providerId,
      requestsToday: health.requestsToday,
      dailyRequestLimit:
          profile.dailyRequestLimit,
      remainingDailyRequests:
          remainingDaily,
      requestsInCurrentWindow:
          requestsInCurrentWindow,
      rateLimitMaxRequests:
          profile.rateLimitMaxRequests,
      remainingWindowRequests:
          remainingWindow,
      dailyQuotaReached:
          dailyQuotaReached,
      rateLimitReached:
          rateLimitReached,
    );
  }

  int nextWindowRequestCount({
    required int currentCount,
  }) {
    if (currentCount < 0) {
      throw const AgentProviderUsageAccountingException(
        'currentCount cannot be negative.',
      );
    }

    return currentCount + 1;
  }

  bool canAttemptProvider({
    required AgentProviderUsageSnapshot snapshot,
  }) {
    return !snapshot.blocked;
  }

  int _remaining({
    required int limit,
    required int used,
  }) {
    final int result = limit - used;

    return result < 0 ? 0 : result;
  }
}

class AgentProviderUsageAccountingException
    implements Exception {
  final String message;

  const AgentProviderUsageAccountingException(
    this.message,
  );

  @override
  String toString() =>
      'AgentProviderUsageAccountingException: $message';
}