abstract final class AgentSecurityIncidentRoleInventoryMigrationStatus {
  static const String blocked = 'BLOCKED';
  static const String readyForSeparateAtomicExecutorDesign =
      'READY_FOR_SEPARATE_ATOMIC_EXECUTOR_IMPLEMENTATION';
}

class AgentSecurityIncidentRoleInventoryMigrationDecision {
  const AgentSecurityIncidentRoleInventoryMigrationDecision({
    required this.status,
    required this.reasonCode,
  });

  final String status;
  final String reasonCode;

  bool get readyForSeparateAtomicExecutorDesign =>
      status ==
      AgentSecurityIncidentRoleInventoryMigrationStatus
          .readyForSeparateAtomicExecutorDesign;

  // Architecture result only. Never execution authority.
  bool get writesFirestore => false;
  bool get createsRole => false;
  bool get mutatesGuard => false;
  bool get createsArmingToken => false;
  bool get consumesApproval => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
