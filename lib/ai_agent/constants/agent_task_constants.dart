// =========================================================
// AI AGENT — TASK QUEUE CONSTANTS
// =========================================================
//
// Phase 21 task queue foundation.
//
// Important:
// - Unknown status or priority must be rejected.
// - A task may be processed by only one active worker lease.
// - Idempotency keys prevent duplicate logical tasks.
// - Failed tasks use controlled retry limits.

class AgentTaskCollection {
  AgentTaskCollection._();

  static const String tasks = 'agent_tasks';
}

class AgentTaskStatus {
  AgentTaskStatus._();

  static const String queued = 'queued';
  static const String leased = 'leased';
  static const String processing = 'processing';
  static const String awaitingApproval = 'awaiting_approval';
  static const String awaitingReview = 'awaiting_review';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String cancelled = 'cancelled';
  static const String deadLetter = 'dead_letter';

  static const List<String> values = <String>[
    queued,
    leased,
    processing,
    awaitingApproval,
    awaitingReview,
    completed,
    failed,
    cancelled,
    deadLetter,
  ];

  static const List<String> terminalValues = <String>[
    completed,
    cancelled,
    deadLetter,
  ];

  static bool isValid(String value) => values.contains(value);

  static bool isTerminal(String value) => terminalValues.contains(value);
}

class AgentTaskPriority {
  AgentTaskPriority._();

  static const String low = 'low';
  static const String normal = 'normal';
  static const String high = 'high';
  static const String critical = 'critical';

  static const List<String> values = <String>[
    low,
    normal,
    high,
    critical,
  ];

  static bool isValid(String value) => values.contains(value);

  static int rank(String value) {
    switch (value) {
      case critical:
        return 4;
      case high:
        return 3;
      case normal:
        return 2;
      case low:
        return 1;
      default:
        return 0;
    }
  }
}

class AgentTaskSource {
  AgentTaskSource._();

  static const String system = 'system';
  static const String superAdmin = 'super_admin';
  static const String appEvent = 'app_event';
  static const String scheduled = 'scheduled';
  static const String agent = 'agent';

  static const List<String> values = <String>[
    system,
    superAdmin,
    appEvent,
    scheduled,
    agent,
  ];

  static bool isValid(String value) => values.contains(value);
}

class AgentTaskFailureCode {
  AgentTaskFailureCode._();

  static const String providerUnavailable = 'provider_unavailable';
  static const String workerUnavailable = 'worker_unavailable';
  static const String permissionDenied = 'permission_denied';
  static const String approvalRequired = 'approval_required';
  static const String invalidPayload = 'invalid_payload';
  static const String connectorUnavailable = 'connector_unavailable';
  static const String leaseExpired = 'lease_expired';
  static const String retryLimitReached = 'retry_limit_reached';
  static const String unexpected = 'unexpected';
}

class AgentTaskDefaults {
  AgentTaskDefaults._();

  static const int maxAttempts = 3;
  static const int leaseDurationSeconds = 120;
  static const int maxErrorLength = 1000;
  static const int maxPayloadKeys = 50;
}