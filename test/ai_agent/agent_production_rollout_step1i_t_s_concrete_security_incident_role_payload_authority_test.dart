import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_enums.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_role_inventory_revision_design.dart';

void main() {
  group('Phase66 Step1I-T-S concrete role payload authority', () {
    test('concrete payload is explicit and fail-closed', () {
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.proposedEnabled,
        isFalse,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.proposedAiClass,
        AiClass.freeAi,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.proposedPrivacyLevel,
        PrivacyLevel.highlySensitive,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .proposedForbiddenActions,
        isEmpty,
      );
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .requiresSeparatePostRebindEnableBoundary,
        isTrue,
      );
    });

    test('proposed AgentRole is valid but not operational', () {
      final role = AgentRole(
        roleId:
            AgentSecurityIncidentRoleInventoryRevisionDesign.dedicatedRoleId,
        name:
            AgentSecurityIncidentRoleInventoryRevisionDesign.dedicatedRoleName,
        description: AgentSecurityIncidentRoleInventoryRevisionDesign
            .dedicatedRoleDescription,
        module:
            AgentSecurityIncidentRoleInventoryRevisionDesign.dedicatedModule,
        enabled:
            AgentSecurityIncidentRoleInventoryRevisionDesign.proposedEnabled,
        mode: AgentSecurityIncidentRoleInventoryRevisionDesign
            .proposedStoredRoleMode,
        allowedActions: AgentSecurityIncidentRoleInventoryRevisionDesign
            .proposedAllowedActions,
        approvalRequiredActions:
            AgentSecurityIncidentRoleInventoryRevisionDesign
                .proposedApprovalRequiredActions,
        forbiddenActions: AgentSecurityIncidentRoleInventoryRevisionDesign
            .proposedForbiddenActions,
        aiClass:
            AgentSecurityIncidentRoleInventoryRevisionDesign.proposedAiClass,
        privacyLevel: AgentSecurityIncidentRoleInventoryRevisionDesign
            .proposedPrivacyLevel,
        createdAt: DateTime.utc(2026, 8, 28),
      );

      expect(role.isValid, isTrue);
      expect(role.isOperational, isFalse);
      expect(role.enabled, isFalse);
    });

    test('role authority remains one-action and approval-required', () {
      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign.proposedAllowedActions,
        <String>[
          AgentSecurityIncidentRoleInventoryRevisionDesign
              .attachRuntimeActionId,
        ],
      );

      expect(
        AgentSecurityIncidentRoleInventoryRevisionDesign
            .proposedApprovalRequiredActions,
        <String>[
          AgentSecurityIncidentRoleInventoryRevisionDesign
              .attachRuntimeActionId,
        ],
      );
    });

    test('concrete payload does not authorize rollout progression', () {
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
  });
}
