import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_role_inventory_revision_design.dart';

void main() {
  group('Phase66 Step1I-T-G Security Incident role inventory design', () {
    test('inventory revision is exactly 22 to 23', () {
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.currentRoleCount,
        22,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.proposedRoleCount,
        23,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.roleCountDelta,
        1,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.countRevisionIsExact,
        isTrue,
      );
    });

    test('dedicated role does not reuse safety_agent', () {
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.dedicatedRoleId,
        'security_incident_agent',
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.forbiddenReuseRoleId,
        'safety_agent',
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.dedicatedRoleId,
        isNot(
          AgentSecurityIncidentRoleInventoryRevisionDesign.forbiddenReuseRoleId,
        ),
      );
    });

    test(
      'dedicated action is critical, consequential, and approval required',
      () {
        expect(
          AgentSecurityIncidentRoleInventoryRevisionDesign
              .attachRuntimeActionId,
          'security_incident.attach_runtime',
        );
        expect(
          AgentSecurityIncidentRoleInventoryRevisionDesign
              .attachRuntimeActionRisk,
          'CRITICAL',
        );
        expect(
          AgentSecurityIncidentRoleInventoryRevisionDesign
              .attachRuntimeReadOnly,
          isFalse,
        );
        expect(
          AgentSecurityIncidentRoleInventoryRevisionDesign
              .attachRuntimeAlwaysRequiresApproval,
          isTrue,
        );
      },
    );

    test('role permission policy is one-action least privilege', () {
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .permissionPolicyIsLeastPrivilege,
        isTrue,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.proposedAllowedActions,
        <String>['security_incident.attach_runtime'],
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .proposedApprovalRequiredActions,
        <String>['security_incident.attach_runtime'],
      );
    });

    test('stored role mode is ASK_FIRST and never AUTO', () {
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.proposedStoredRoleMode,
        'ASK_FIRST',
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.proposedRoleAuto,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .proposedRoleFullSafeAuto,
        isFalse,
      );
    });

    test('approval scope binds exact migration target', () {
      final scope = AgentSecurityIncidentRoleInventoryRevisionDesign
          .approvalScopeTemplate;

      expect(scope['operation'], 'ATTACH_SECURITY_INCIDENT_RUNTIME');
      expect(scope['inventoryFrom'], 'phase66_roles_v1_22');
      expect(scope['inventoryTo'], 'phase66_roles_v2_23_security_incident');
      expect(scope['fromRoleCount'], 22);
      expect(scope['toRoleCount'], 23);
      expect(scope['targetRoleId'], 'security_incident_agent');
      expect(scope['targetModule'], 'security_incident');
      expect(scope['targetActionId'], 'security_incident.attach_runtime');
      expect(scope['expectedRolloutStage'], 'MONITOR_ONLY');
      expect(scope['firstIncidentWriteAuthorized'], isFalse);
    });

    test('old activation evidence remains immutable', () {
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .oldActivationEvidenceIsImmutable,
        isTrue,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .reuseExistingArmingToken,
        isFalse,
      );
    });

    test('future live migration requires wholly fresh evidence', () {
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .migrationRequiresFreshEvidence,
        isTrue,
      );
    });

    test('caller-supplied synthetic role can never authorize execution', () {
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .callerSuppliedRoleMayAuthorizeExecution,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .persistedRoleResolutionRequired,
        isTrue,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .exactPersistedRoleBindingRequired,
        isTrue,
      );
    });

    test('design does not activate persistence or rollout', () {
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.designOnlyFailClosed,
        isTrue,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.addsLiveRole,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.addsLiveAction,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.consumesApproval,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.attachesRuntime,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.armsRepository,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.writesIncident,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .currentRolloutRemainsMonitorOnly,
        isTrue,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.authorizesSuggestOnly,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.authorizesAuto,
        isFalse,
      );
    });

    test('post migration MONITOR_ONLY observation remains mandatory', () {
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .postMigrationMonitorObservationRequired,
        isTrue,
      );
    });
  });
}
