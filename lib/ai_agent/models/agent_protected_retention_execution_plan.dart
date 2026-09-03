import 'agent_protected_retention_action_request.dart';

/// Immutable plan describing one proposed protected-data operation.
///
/// IMPORTANT:
/// - This is a plan only.
/// - It does NOT perform Firestore reads/writes/deletes.
/// - It does NOT grant deletion authority.
/// - Exact record IDs are required; broad collection-wide deletion
///   is deliberately unsupported by this model.
class AgentProtectedRetentionExecutionPlan {
  final String executionPlanId;
  final String approvalId;
  final String requestId;

  final AgentProtectedRetentionActionType actionType;
  final AgentProtectedRetentionDataClass dataClass;

  final String collectionPath;
  final List<String> recordIds;

  final String actorId;
  final String actorRole;
  final String reason;

  final DateTime createdAt;

  final bool approvalConsumed;
  final bool exactScopeVerified;
  final bool finalConfirmationVerified;

  /// Phase 37 fail-closed boundary.
  ///
  /// A valid design plan does not itself authorize deletion.
  final bool deletionAuthorized;

  const AgentProtectedRetentionExecutionPlan({
    required this.executionPlanId,
    required this.approvalId,
    required this.requestId,
    required this.actionType,
    required this.dataClass,
    required this.collectionPath,
    required this.recordIds,
    required this.actorId,
    required this.actorRole,
    required this.reason,
    required this.createdAt,
    required this.approvalConsumed,
    required this.exactScopeVerified,
    required this.finalConfirmationVerified,
    this.deletionAuthorized = false,
  });

  bool get hasExplicitTargets =>
      collectionPath.trim().isNotEmpty &&
      recordIds.isNotEmpty &&
      recordIds.every((String value) => value.trim().isNotEmpty);

  bool get isSuperAdminPlan => actorRole.trim() == 'super_admin';

  bool get prerequisitesSatisfied =>
      approvalConsumed &&
      exactScopeVerified &&
      finalConfirmationVerified &&
      hasExplicitTargets &&
      isSuperAdminPlan &&
      actorId.trim().isNotEmpty &&
      reason.trim().length >= 10;

  Map<String, dynamic> toAuditMetadata() {
    return <String, dynamic>{
      'executionPlanId': executionPlanId.trim(),
      'approvalId': approvalId.trim(),
      'requestId': requestId.trim(),
      'actionType': actionType.name,
      'dataClass': dataClass.name,
      'collectionPath': collectionPath.trim(),
      'recordIds': List<String>.unmodifiable(recordIds),
      'actorId': actorId.trim(),
      'actorRole': actorRole.trim(),
      'reason': reason.trim(),
      'createdAt': createdAt.toIso8601String(),
      'approvalConsumed': approvalConsumed,
      'exactScopeVerified': exactScopeVerified,
      'finalConfirmationVerified': finalConfirmationVerified,
      'deletionAuthorized': deletionAuthorized,
    };
  }
}
