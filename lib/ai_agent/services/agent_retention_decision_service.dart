import '../constants/agent_retention_policy.dart';
import '../constants/agent_retention_record_map.dart';

/// Read-only retention assessment result.
///
/// This object describes policy status only.
/// It never authorizes or executes deletion.
class AgentRetentionDecision {
  final String collectionPath;
  final AgentRetentionCategory category;
  final DateTime? recordCreatedAt;
  final Duration? retentionDuration;
  final DateTime? nominalRetentionUntil;
  final bool retentionWindowReached;
  final bool automaticCleanupEnabled;
  final bool genericCleanupEligible;
  final bool protectedEvidence;
  final bool deletionAuthorized;
  final String decisionCode;
  final String explanation;

  const AgentRetentionDecision({
    required this.collectionPath,
    required this.category,
    required this.recordCreatedAt,
    required this.retentionDuration,
    required this.nominalRetentionUntil,
    required this.retentionWindowReached,
    required this.automaticCleanupEnabled,
    required this.genericCleanupEligible,
    required this.protectedEvidence,
    required this.deletionAuthorized,
    required this.decisionCode,
    required this.explanation,
  });

  Map<String, dynamic> toReportMap() {
    return <String, dynamic>{
      'collectionPath': collectionPath,
      'category': category.name,
      'recordCreatedAt': recordCreatedAt?.toIso8601String(),
      'retentionDays': retentionDuration?.inDays,
      'nominalRetentionUntil': nominalRetentionUntil?.toIso8601String(),
      'retentionWindowReached': retentionWindowReached,
      'automaticCleanupEnabled': automaticCleanupEnabled,
      'genericCleanupEligible': genericCleanupEligible,
      'protectedEvidence': protectedEvidence,
      'deletionAuthorized': deletionAuthorized,
      'decisionCode': decisionCode,
      'explanation': explanation,
    };
  }
}

/// Privacy-safe retention decision/reporting layer.
///
/// IMPORTANT:
/// - ZERO Firestore access.
/// - ZERO delete authority.
/// - ZERO automatic cleanup.
/// - Reaching a retention date does NOT itself authorize deletion.
/// - Audit/security/finance evidence remains protected.
abstract final class AgentRetentionDecisionService {
  static AgentRetentionDecision assess({
    required String collectionPath,
    DateTime? recordCreatedAt,
    DateTime? now,
  }) {
    final String normalizedCollection = collectionPath.trim();

    final AgentRetentionCategory category =
        AgentRetentionRecordMap.categoryForCollection(normalizedCollection);

    final Duration? retention = AgentRetentionRecordMap.retentionForCategory(
      category,
    );

    final bool protectedEvidence =
        AgentRetentionRecordMap.requiresProtectedEvidenceHandling(category);

    final DateTime assessmentTime = now ?? DateTime.now();

    final DateTime? nominalRetentionUntil =
        recordCreatedAt != null && retention != null
        ? recordCreatedAt.add(retention)
        : null;

    final bool retentionWindowReached =
        nominalRetentionUntil != null &&
        !assessmentTime.isBefore(nominalRetentionUntil);

    final bool policyCleanupEligible =
        AgentRetentionRecordMap.isGenericAutomaticCleanupEligible(category);

    final bool genericCleanupEligible =
        retentionWindowReached && policyCleanupEligible && !protectedEvidence;

    // Phase 37 safety rule:
    // reporting does NOT grant deletion authority.
    const bool deletionAuthorized = false;

    final String decisionCode;
    final String explanation;

    if (category == AgentRetentionCategory.unknown) {
      decisionCode = 'UNKNOWN_RECORD_TYPE';
      explanation =
          'No retention mapping exists. Keep the record unchanged until an explicit policy is defined.';
    } else if (category == AgentRetentionCategory.configuration) {
      decisionCode = 'CONFIGURATION_NO_GENERIC_RETENTION';
      explanation =
          'Configuration records are not handled by generic retention cleanup.';
    } else if (protectedEvidence) {
      decisionCode = 'PROTECTED_EVIDENCE';
      explanation =
          'This record is protected evidence. Retention duration is informational and does not authorize generic deletion.';
    } else if (recordCreatedAt == null) {
      decisionCode = 'CREATED_AT_REQUIRED';
      explanation =
          'A creation timestamp is required before the retention window can be assessed.';
    } else if (retention == null) {
      decisionCode = 'NO_RETENTION_DURATION';
      explanation =
          'No bounded retention duration is defined for this record category.';
    } else if (!retentionWindowReached) {
      decisionCode = 'WITHIN_RETENTION_WINDOW';
      explanation =
          'The record is still inside its configured retention window.';
    } else if (!AgentRetentionPolicy.automaticCleanupEnabled) {
      decisionCode = 'WINDOW_REACHED_CLEANUP_DISABLED';
      explanation =
          'The nominal retention window has been reached, but automatic cleanup is disabled.';
    } else if (!policyCleanupEligible) {
      decisionCode = 'NOT_GENERIC_CLEANUP_ELIGIBLE';
      explanation =
          'The record is not eligible for the generic automatic cleanup path.';
    } else {
      decisionCode = 'REVIEW_ELIGIBLE';
      explanation =
          'The retention window has been reached. This is a review signal only and does not authorize deletion.';
    }

    return AgentRetentionDecision(
      collectionPath: normalizedCollection,
      category: category,
      recordCreatedAt: recordCreatedAt,
      retentionDuration: retention,
      nominalRetentionUntil: nominalRetentionUntil,
      retentionWindowReached: retentionWindowReached,
      automaticCleanupEnabled: AgentRetentionPolicy.automaticCleanupEnabled,
      genericCleanupEligible: genericCleanupEligible,
      protectedEvidence: protectedEvidence,
      deletionAuthorized: deletionAuthorized,
      decisionCode: decisionCode,
      explanation: explanation,
    );
  }
}
