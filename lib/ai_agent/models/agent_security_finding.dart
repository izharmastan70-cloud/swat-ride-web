// =========================================================
// AI AGENT - SECURITY FINDING
// =========================================================
//
// Phase 27 security foundation.
//
// Pure model only:
// - no Firestore access
// - no tool execution
// - no permission changes
// - no automatic blocking
// - no secrets stored
//
// Existing Permission Engine and Runtime Gate remain authoritative.

class AgentSecuritySeverity {
  AgentSecuritySeverity._();

  static const String info = 'INFO';
  static const String warning = 'WARNING';
  static const String high = 'HIGH';
  static const String critical = 'CRITICAL';

  static const Set<String> values = <String>{
    info,
    warning,
    high,
    critical,
  };

  static bool isValid(String value) => values.contains(value);
}

class AgentSecurityFindingType {
  AgentSecurityFindingType._();

  static const String invalidRoleConfiguration =
      'INVALID_ROLE_CONFIGURATION';

  static const String failClosedRole =
      'FAIL_CLOSED_ROLE';

  static const String unknownAllowedAction =
      'UNKNOWN_ALLOWED_ACTION';

  static const String forbiddenActionAlsoAllowed =
      'FORBIDDEN_ACTION_ALSO_ALLOWED';

  static const String approvalActionNotAllowed =
      'APPROVAL_ACTION_NOT_ALLOWED';

  static const String crossModulePermission =
      'CROSS_MODULE_PERMISSION';

  static const String paidAiRoleViolation =
      'PAID_AI_ROLE_VIOLATION';

  static const String excessivePermission =
      'EXCESSIVE_PERMISSION';

  static const String suspiciousRuntimeState =
      'SUSPICIOUS_RUNTIME_STATE';

  static const String securityPolicyViolation =
      'SECURITY_POLICY_VIOLATION';

  static const Set<String> values = <String>{
    invalidRoleConfiguration,
    failClosedRole,
    unknownAllowedAction,
    forbiddenActionAlsoAllowed,
    approvalActionNotAllowed,
    crossModulePermission,
    paidAiRoleViolation,
    excessivePermission,
    suspiciousRuntimeState,
    securityPolicyViolation,
  };

  static bool isValid(String value) => values.contains(value);
}

class AgentSecurityFinding {
  final String findingType;
  final String severity;
  final String roleId;
  final String module;
  final String actionId;
  final String reason;
  final Map<String, dynamic> metadata;

  const AgentSecurityFinding({
    required this.findingType,
    required this.severity,
    this.roleId = '',
    this.module = '',
    this.actionId = '',
    required this.reason,
    this.metadata = const <String, dynamic>{},
  });

  bool get isCritical =>
      severity == AgentSecuritySeverity.critical;

  bool get isHighOrCritical =>
      severity == AgentSecuritySeverity.high ||
      severity == AgentSecuritySeverity.critical;

  void validate() {
    if (!AgentSecurityFindingType.isValid(findingType)) {
      throw AgentSecurityFindingValidationException(
        'Invalid security finding type "$findingType".',
      );
    }

    if (!AgentSecuritySeverity.isValid(severity)) {
      throw AgentSecurityFindingValidationException(
        'Invalid security severity "$severity".',
      );
    }

    if (reason.trim().isEmpty) {
      throw const AgentSecurityFindingValidationException(
        'Security finding reason cannot be empty.',
      );
    }
  }

  bool get isValid {
    try {
      validate();
      return true;
    } on AgentSecurityFindingValidationException {
      return false;
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'findingType': findingType,
      'severity': severity,
      'roleId': roleId,
      'module': module,
      'actionId': actionId,
      'reason': reason,
      'metadata': Map<String, dynamic>.from(metadata),
    };
  }
}

class AgentSecurityFindingValidationException
    implements Exception {
  final String message;

  const AgentSecurityFindingValidationException(
    this.message,
  );

  @override
  String toString() =>
      'AgentSecurityFindingValidationException: $message';
}