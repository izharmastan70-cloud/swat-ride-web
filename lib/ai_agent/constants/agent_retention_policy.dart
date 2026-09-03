/// Central privacy-safe retention policy for the SWAT RIDE AI Agent.
///
/// IMPORTANT:
/// - This file only defines retention classifications.
/// - It does NOT delete Firestore documents.
/// - It does NOT enable automatic cleanup.
/// - Audit/security evidence must not be blindly deleted.
/// - Financial/security/legal records may require longer preservation.
/// - Transient customer/call context should not be retained forever.
abstract final class AgentRetentionPolicy {
  // ---------------------------------------------------------
  // Transient / privacy-sensitive operational context
  // ---------------------------------------------------------

  /// Raw/transient call-session context.
  static const Duration callSessionRetention = Duration(days: 30);

  /// General support/feedback operational context.
  static const Duration supportContextRetention = Duration(days: 90);

  /// Crash diagnostic records after sanitization.
  static const Duration crashEventRetention = Duration(days: 90);

  /// Completed/expired approval workflow records.
  static const Duration approvalRetention = Duration(days: 180);

  /// Completed operational AI tasks.
  static const Duration completedTaskRetention = Duration(days: 90);

  /// Idempotency records only need bounded operational history.
  static const Duration taskIdempotencyRetention = Duration(days: 30);

  /// Provider health/status operational history.
  static const Duration providerHealthRetention = Duration(days: 30);

  // ---------------------------------------------------------
  // Higher-value evidence
  // ---------------------------------------------------------

  /// Audit evidence gets longer preservation.
  ///
  /// Automatic deletion must NOT be enabled merely because
  /// this duration exists. Cleanup must later pass explicit
  /// safety/legal/security policy checks.
  static const Duration auditLogMinimumRetention = Duration(days: 365);

  /// Security/crash/fraud evidence may be required for
  /// investigation and must not be blindly purged.
  static const Duration securityEvidenceMinimumRetention = Duration(days: 365);

  /// Finance records are deliberately classified separately.
  ///
  /// No automatic finance deletion is authorized by this
  /// policy contract.
  static const Duration financeRecordMinimumRetention = Duration(days: 365);

  // ---------------------------------------------------------
  // Safety switches
  // ---------------------------------------------------------

  /// Production cleanup remains OFF until a separately audited
  /// cleanup service and owner/admin controls are implemented.
  static const bool automaticCleanupEnabled = false;

  /// Financial records must never be auto-deleted by the
  /// generic AI cleanup path.
  static const bool allowAutomaticFinanceDeletion = false;

  /// Security/audit evidence must never be blindly deleted by
  /// the generic cleanup path.
  static const bool allowAutomaticSecurityEvidenceDeletion = false;

  /// Raw/transient privacy-sensitive records are eligible for
  /// future bounded cleanup only after the cleanup engine is
  /// separately implemented and audited.
  static const bool transientDataMayBeEligibleForCleanup = true;
}
