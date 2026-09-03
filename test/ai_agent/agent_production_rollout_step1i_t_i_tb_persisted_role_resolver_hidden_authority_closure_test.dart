import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_persisted_role_resolution_result.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_role_inventory_revision_design.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_runtime_attachment_preflight_result.dart';

void main() {
  group('Phase66 Step1I-T-I persisted role authority closure', () {
    test('dedicated persisted role identity remains versioned and exact', () {
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.dedicatedRoleId,
        'security_incident_agent',
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.dedicatedModule,
        'security_incident',
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.attachRuntimeActionId,
        'security_incident.attach_runtime',
      );
    });

    test('caller supplied synthetic role authority remains prohibited', () {
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
    });

    test('missing persisted role has a dedicated fail-closed reason', () {
      expect(
        AgentSecurityIncidentPersistedRoleResolutionReason.missing,
        'persisted_security_incident_role_missing',
      );
    });

    test(
      'corrupt or wrong persisted role has distinct fail-closed reasons',
      () {
        expect(
          AgentSecurityIncidentPersistedRoleResolutionReason.failClosed,
          isNotEmpty,
        );
        expect(
          AgentSecurityIncidentPersistedRoleResolutionReason.invalid,
          isNotEmpty,
        );
        expect(
          AgentSecurityIncidentPersistedRoleResolutionReason.roleIdMismatch,
          isNotEmpty,
        );
        expect(
          AgentSecurityIncidentPersistedRoleResolutionReason.moduleMismatch,
          isNotEmpty,
        );
      },
    );

    test('permission-policy drift has distinct fail-closed reasons', () {
      expect(
        AgentSecurityIncidentPersistedRoleResolutionReason
            .allowedActionsMismatch,
        isNotEmpty,
      );
      expect(
        AgentSecurityIncidentPersistedRoleResolutionReason
            .approvalActionsMismatch,
        isNotEmpty,
      );
      expect(
        AgentSecurityIncidentPersistedRoleResolutionReason.actionForbidden,
        isNotEmpty,
      );
    });

    test('runtime attachment preflight can report persisted role block', () {
      expect(
        AgentSecurityIncidentRuntimeAttachmentPreflightStatus
            .persistedRoleBlocked,
        'PERSISTED_ROLE_BLOCKED',
      );
    });

    test('blocked resolution cannot carry execution authority', () {
      final result = AgentSecurityIncidentPersistedRoleResolutionResult.blocked(
        AgentSecurityIncidentPersistedRoleResolutionReason.missing,
      );

      expect(result.verified, isFalse);
      expect(result.role, isNull);
      expect(result.callerSuppliedRoleAccepted, isFalse);
      expect(result.syntheticRoleAuthorityAccepted, isFalse);
      expect(result.writesFirestore, isFalse);
      expect(result.consumesApproval, isFalse);
      expect(result.attachesRuntime, isFalse);
      expect(result.armsRepository, isFalse);
      expect(result.writesIncident, isFalse);
    });

    test('Step1I-T-I does not authorize rollout advancement', () {
      final result = AgentSecurityIncidentPersistedRoleResolutionResult.blocked(
        AgentSecurityIncidentPersistedRoleResolutionReason.missing,
      );

      expect(result.authorizesSuggestOnly, isFalse);
      expect(result.authorizesAuto, isFalse);
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .currentRolloutRemainsMonitorOnly,
        isTrue,
      );
    });

    test('future role remains ASK_FIRST and approval-required by design', () {
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.proposedStoredRoleMode,
        'ASK_FIRST',
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .attachRuntimeAlwaysRequiresApproval,
        isTrue,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .proposedApprovalRequiredActions,
        <String>['security_incident.attach_runtime'],
      );
    });
  });
}
