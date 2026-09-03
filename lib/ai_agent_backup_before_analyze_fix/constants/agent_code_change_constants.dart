// =========================================================
// AI AGENT — CODE CHANGE CONSTANTS
// =========================================================

class AgentCodeChangeStatus {
  AgentCodeChangeStatus._();

  static const String proposed = 'PROPOSED';
  static const String approved = 'APPROVED';
  static const String backupReady = 'BACKUP_READY';
  static const String applying = 'APPLYING';
  static const String applied = 'APPLIED';
  static const String testing = 'TESTING';
  static const String testPassed = 'TEST_PASSED';
  static const String testFailed = 'TEST_FAILED';
  static const String rollbackReady = 'ROLLBACK_READY';
  static const String rolledBack = 'ROLLED_BACK';
  static const String kept = 'KEPT';
  static const String denied = 'DENIED';

  static const Set<String> values = <String>{
    proposed,
    approved,
    backupReady,
    applying,
    applied,
    testing,
    testPassed,
    testFailed,
    rollbackReady,
    rolledBack,
    kept,
    denied,
  };
}

class AgentCodeTestStatus {
  AgentCodeTestStatus._();

  static const String notRun = 'NOT_RUN';
  static const String passed = 'PASSED';
  static const String failed = 'FAILED';
  static const String unavailable = 'UNAVAILABLE';
}
