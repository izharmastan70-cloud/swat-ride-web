import 'admin_intelligence_security_authorization.dart';

class AdminIntelligenceExecutionBoundaryStatus {
  AdminIntelligenceExecutionBoundaryStatus._();

  static const String blocked = 'BLOCKED';
  static const String waitingApproval = 'WAITING_APPROVAL';
  static const String approvalConsumedReady = 'APPROVAL_CONSUMED_READY';
  static const String readyNoApproval = 'READY_NO_APPROVAL';
}

class AdminIntelligenceExecutionBoundaryResult {
  const AdminIntelligenceExecutionBoundaryResult({
    required this.status,
    required this.authorization,
    required this.auditRecorded,
    required this.providerExecutionPerformed,
    required this.businessDataWritePerformed,
    required this.costCharged,
    required this.budgetMutated,
    required this.reason,
    this.approvalId,
  });

  final String status;
  final AdminIntelligenceSecurityAuthorization authorization;

  final bool auditRecorded;

  /// Must remain false in Phase 38-H2C.
  final bool providerExecutionPerformed;

  /// Must remain false in Phase 38-H2C.
  final bool businessDataWritePerformed;

  /// Must remain false in Phase 38-H2C.
  final bool costCharged;

  /// Must remain false in Phase 38-H2C.
  final bool budgetMutated;

  final String reason;
  final String? approvalId;

  bool get boundaryReady =>
      (status ==
              AdminIntelligenceExecutionBoundaryStatus.approvalConsumedReady ||
          status == AdminIntelligenceExecutionBoundaryStatus.readyNoApproval) &&
      auditRecorded &&
      !providerExecutionPerformed &&
      !businessDataWritePerformed &&
      !costCharged &&
      !budgetMutated;
}
