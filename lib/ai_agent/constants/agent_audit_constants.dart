// =========================================================
// AI AGENT ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â AUDIT CONSTANTS
// =========================================================

class AgentAuditEventType {
  AgentAuditEventType._();

  static const String permissionEvaluated = 'PERMISSION_EVALUATED';
  static const String approvalRequested = 'APPROVAL_REQUESTED';
  static const String approvalApproved = 'APPROVAL_APPROVED';
  static const String approvalRejected = 'APPROVAL_REJECTED';
  static const String approvalCancelled = 'APPROVAL_CANCELLED';
  static const String approvalExpired = 'APPROVAL_EXPIRED';
  static const String approvalConsumed = 'APPROVAL_CONSUMED';
  static const String roleFailClosed = 'ROLE_FAIL_CLOSED';
  static const String roleCreated = 'ROLE_CREATED';
  static const String roleUpdated = 'ROLE_UPDATED';
  static const String roleModeChanged = 'ROLE_MODE_CHANGED';
  static const String roleEnabledChanged = 'ROLE_ENABLED_CHANGED';
  static const String systemEvent = 'SYSTEM_EVENT';
  static const String taskQueued = 'TASK_QUEUED';
  static const String taskAssigned = 'TASK_ASSIGNED';
  static const String taskDeadLettered = 'TASK_DEAD_LETTERED';
  static const String taskStarted = 'TASK_STARTED';
  static const String taskCompleted = 'TASK_COMPLETED';
  static const String taskCancelled = 'TASK_CANCELLED';
  static const String taskFailed = 'TASK_FAILED';
  static const String taskLeaseAcquired = 'TASK_LEASE_ACQUIRED';
  static const String taskRecovered = 'TASK_RECOVERED';
  static const String providerRequestSucceeded = 'PROVIDER_REQUEST_SUCCEEDED';
  static const String providerRequestFailed = 'PROVIDER_REQUEST_FAILED';
  static const String providerMarkedUnavailable = 'PROVIDER_MARKED_UNAVAILABLE';

  static const Set<String> values = <String>{
    permissionEvaluated,
    approvalRequested,
    approvalApproved,
    approvalRejected,
    approvalCancelled,
    approvalExpired,
    approvalConsumed,
    roleFailClosed,
    roleCreated,
    roleUpdated,
    roleModeChanged,
    roleEnabledChanged,
    systemEvent,
  };

  static bool isValid(String value) => values.contains(value);
}

class AgentAuditSeverity {
  AgentAuditSeverity._();

  static const String info = 'INFO';
  static const String warning = 'WARNING';
  static const String high = 'HIGH';
  static const String critical = 'CRITICAL';

  static const Set<String> values = <String>{info, warning, high, critical};

  static bool isValid(String value) => values.contains(value);
}

class AgentAuditActorType {
  AgentAuditActorType._();

  static const String agent = 'AGENT';
  static const String owner = 'OWNER';
  static const String admin = 'ADMIN';
  static const String system = 'SYSTEM';

  static const Set<String> values = <String>{agent, owner, admin, system};

  static bool isValid(String value) => values.contains(value);
}
