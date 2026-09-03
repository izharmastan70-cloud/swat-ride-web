import '../models/agent_security_incident_role_inventory_migration_decision.dart';
import '../models/agent_security_incident_role_inventory_migration_plan.dart';
import 'agent_security_incident_role_inventory_migration_policy.dart';

/// Phase 66 Step1I-T-K.
///
/// OFFLINE ARCHITECTURE ONLY.
///
/// This is intentionally NOT the live Firestore migration executor.
///
/// T-J proved:
/// - core Phase66 snapshot/Owner/guard/token/receipt authorities exist;
/// - ordinary AgentRoleService writes are not sufficient migration authority;
/// - no dedicated atomic 22 -> 23 role/evidence migration boundary exists.
///
/// Therefore this coordinator only validates a fully bound migration plan.
/// A later separately reviewed executor must implement the actual Firestore
/// transaction/precondition and post-migration rebinding.
class AgentSecurityIncidentRoleInventoryMigrationCoordinator {
  const AgentSecurityIncidentRoleInventoryMigrationCoordinator({
    this.policy = const AgentSecurityIncidentRoleInventoryMigrationPolicy(),
  });

  final AgentSecurityIncidentRoleInventoryMigrationPolicy policy;

  AgentSecurityIncidentRoleInventoryMigrationDecision evaluateOffline(
    AgentSecurityIncidentRoleInventoryMigrationPlan plan,
  ) {
    return policy.evaluate(plan);
  }

  bool get executionArmed => false;
  bool get liveExecutorAttached => false;

  bool get usesOrdinaryCreateRoleAsMigrationAuthority => false;
  bool get requiresDedicatedAtomicExecutor => true;
  bool get requiresExactCurrentStatePrecondition => true;
  bool get requiresMigrationHold => true;

  bool get writesFirestore => false;
  bool get createsRole => false;
  bool get updatesRole => false;
  bool get syncsRolePermissions => false;

  bool get createsOwnerApproval => false;
  bool get consumesOwnerApproval => false;

  bool get mutatesExistingGuard => false;
  bool get mutatesExistingArmingToken => false;
  bool get mutatesExistingActivationReceipt => false;
  bool get reusesExistingArmingToken => false;

  bool get createsNewGuard => false;
  bool get createsNewArmingToken => false;
  bool get createsMigrationReceipt => false;

  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;

  bool get changesRolloutStage => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}
