class AgentOwnerAttentionSlaState {
  AgentOwnerAttentionSlaState._();

  static const String withinSla = 'WITHIN_SLA';
  static const String stale = 'STALE';
  static const String immediateEscalation = 'IMMEDIATE_ESCALATION';
  static const String terminal = 'TERMINAL';

  static const Set<String> values = <String>{
    withinSla,
    stale,
    immediateEscalation,
    terminal,
  };
}

class AgentOwnerAttentionNotificationReason {
  AgentOwnerAttentionNotificationReason._();

  static const String criticalOpen = 'CRITICAL_OPEN';
  static const String emergencyOpen = 'EMERGENCY_OPEN';
  static const String staleHigh = 'STALE_HIGH';
  static const String staleNormal = 'STALE_NORMAL';

  static const Set<String> values = <String>{
    criticalOpen,
    emergencyOpen,
    staleHigh,
    staleNormal,
  };
}

class AgentOwnerAttentionSlaLimits {
  AgentOwnerAttentionSlaLimits._();

  static const Duration normal = Duration(hours: 24);
  static const Duration high = Duration(hours: 4);
  static const Duration critical = Duration(minutes: 15);
  static const Duration emergency = Duration(minutes: 5);

  static const Duration maximumFutureClockSkew = Duration(minutes: 5);

  static const int notificationTitleMaxLength = 140;
}
