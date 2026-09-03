import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_crash_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_enums.dart';
import 'package:swat_ride/ai_agent/models/agent_approval_request.dart';
import 'package:swat_ride/ai_agent/models/agent_crash_event.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_whatsapp_verified_report.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_whatsapp_verified_builtin_sources.dart';

final DateTime _now = DateTime.utc(2026, 8, 18, 1);

AgentOwnerWhatsAppVerifiedReportRequest _request(String sectionId) {
  return AgentOwnerWhatsAppVerifiedReportRequest(
    reportId: 'report_1',
    actorId: 'owner_1',
    fromInclusive: _now.subtract(const Duration(days: 1)),
    toExclusive: _now,
    requestedSectionIds: <String>{sectionId},
  );
}

AgentMasterSettings _settings() {
  return AgentMasterSettings(
    masterEnabled: true,
    emergencyReadOnly: false,
    freeAiEnabled: true,
    localAiEnabled: false,
    paidCodeAiEnabled: false,
    callAgentEnabled: true,
    emailAgentEnabled: true,
    customerWhatsAppAgentEnabled: true,
    ownerWhatsAppAgentEnabled: true,
    approvalEngineEnabled: true,
    auditLoggingEnabled: true,
    monthlyPaidCodeBudgetRs: 0,
    paidCodeBudgetUsedRs: 0,
    emergencyActivatedAt: null,
    emergencyActivatedBy: '',
    emergencyReason: '',
    createdAt: _now.subtract(const Duration(days: 10)),
    updatedAt: _now,
  );
}

AgentRole _role({
  required String roleId,
  bool enabled = true,
  String mode = AgentMode.suggestOnly,
}) {
  return AgentRole(
    roleId: roleId,
    name: roleId,
    description: 'test role',
    module: roleId == 'owner_whatsapp_agent' ? 'owner_whatsapp' : 'core',
    enabled: enabled,
    mode: mode,
    aiClass: AiClass.freeAi,
    privacyLevel: PrivacyLevel.internal,
    createdAt: _now.subtract(const Duration(days: 5)),
  );
}

void main() {
  group('Phase 46 Step 8C verified built-in sources', () {
    test(
      'pending approvals source returns only privacy-minimized counts',
      () async {
        final source = AgentOwnerWhatsAppPendingApprovalsReportSource(
          loader: () async => <AgentApprovalRequest>[
            AgentApprovalRequest(
              approvalId: 'approval_1',
              roleId: 'owner_whatsapp_agent',
              actionId: 'owner_whatsapp.request_consequential_action',
              module: 'owner_whatsapp',
              reason: 'test',
              risk: 'HIGH',
              requestedBy: 'owner_private_identity',
              actionScope: const <String, dynamic>{
                'privateBusinessId': 'must_not_surface',
              },
              status: AgentApprovalStatus.pending,
              createdAt: _now.subtract(const Duration(minutes: 10)),
              expiresAt: _now.add(const Duration(minutes: 10)),
            ),
          ],
          nowProvider: () => _now,
        );

        final result = await source.fetchVerifiedSection(
          sectionId: AgentOwnerWhatsAppReportSectionId.approvals,
          request: _request(AgentOwnerWhatsAppReportSectionId.approvals),
        );

        expect(result.available, isTrue);
        expect(result.backendVerified, isTrue);
        expect(result.data['pendingApprovalCount'], 1);
        expect(result.data['containsActionScope'], isFalse);
        expect(result.data['containsRequesterIdentity'], isFalse);
        expect(
          result.data.toString(),
          isNot(contains('owner_private_identity')),
        );
        expect(result.data.toString(), isNot(contains('must_not_surface')));
      },
    );

    test('agent status source reports current control-plane state', () async {
      final source = AgentOwnerWhatsAppAgentStatusReportSource(
        roleLoader: () async => <AgentRole>[
          _role(roleId: 'owner_whatsapp_agent'),
          _role(roleId: 'support_agent', enabled: false, mode: AgentMode.off),
        ],
        settingsLoader: () async => _settings(),
        nowProvider: () => _now,
      );

      final result = await source.fetchVerifiedSection(
        sectionId: AgentOwnerWhatsAppReportSectionId.agentStatus,
        request: _request(AgentOwnerWhatsAppReportSectionId.agentStatus),
      );

      expect(result.data['roleCount'], 2);
      expect(result.data['operationalRoleCount'], 1);
      expect(result.data['disabledOrInactiveRoleCount'], 1);
      expect(result.data['ownerWhatsAppRolePresent'], isTrue);
      expect(result.data['ownerWhatsAppAgentEnabled'], isTrue);
      expect(result.data['requestedRangeApplied'], isFalse);
    });

    test('security source returns counts only, not finding details', () async {
      final source = AgentOwnerWhatsAppSecurityReportSource(
        roleLoader: () async => <AgentRole>[
          _role(roleId: 'owner_whatsapp_agent'),
        ],
        settingsLoader: () async => _settings(),
        nowProvider: () => _now,
      );

      final result = await source.fetchVerifiedSection(
        sectionId: AgentOwnerWhatsAppReportSectionId.security,
        request: _request(AgentOwnerWhatsAppReportSectionId.security),
      );

      expect(result.available, isTrue);
      expect(result.data.containsKey('totalFindingCount'), isTrue);
      expect(result.data['findingDetailsIncluded'], isFalse);
      expect(result.data['secretValuesIncluded'], isFalse);
      expect(result.data['coverageType'], 'current_configuration_audit');
    });

    test(
      'open crash source never returns message, stack or crash IDs',
      () async {
        final source = AgentOwnerWhatsAppOpenCrashReportSource(
          loader: () async => <AgentCrashEvent>[
            AgentCrashEvent(
              crashId: 'private_crash_id',
              module: 'core',
              errorType: 'StateError',
              message: 'private message',
              stackSummary: 'private stack',
              appVersion: '1.0.0',
              platform: 'android',
              severity: AgentCrashSeverity.warning,
              category: AgentCrashCategory.unknown,
              status: AgentCrashStatus.open,
              occurrenceCount: 3,
              firstSeenAt: _now.subtract(const Duration(hours: 2)),
              lastSeenAt: _now.subtract(const Duration(minutes: 5)),
            ),
          ],
          nowProvider: () => _now,
        );

        final result = await source.fetchVerifiedSection(
          sectionId: AgentOwnerWhatsAppReportSectionId.crashes,
          request: _request(AgentOwnerWhatsAppReportSectionId.crashes),
        );

        expect(result.data['openCrashFingerprintCount'], 1);
        expect(result.data['totalOpenCrashOccurrences'], 3);
        expect(result.data['messageIncluded'], isFalse);
        expect(result.data['stackIncluded'], isFalse);
        expect(result.data['crashIdIncluded'], isFalse);
        expect(result.data.toString(), isNot(contains('private message')));
        expect(result.data.toString(), isNot(contains('private stack')));
        expect(result.data.toString(), isNot(contains('private_crash_id')));
      },
    );

    test('only four exact sections are connected in Step 8C', () {
      expect(
        AgentOwnerWhatsAppVerifiedBuiltInSources.connectedSectionIds,
        const <String>{
          AgentOwnerWhatsAppReportSectionId.approvals,
          AgentOwnerWhatsAppReportSectionId.agentStatus,
          AgentOwnerWhatsAppReportSectionId.security,
          AgentOwnerWhatsAppReportSectionId.crashes,
        },
      );

      expect(
        AgentOwnerWhatsAppVerifiedBuiltInSources.connectedSectionIds.contains(
          AgentOwnerWhatsAppReportSectionId.revenue,
        ),
        isFalse,
      );
      expect(
        AgentOwnerWhatsAppVerifiedBuiltInSources.connectedSectionIds.contains(
          AgentOwnerWhatsAppReportSectionId.tasks,
        ),
        isFalse,
      );
      expect(
        AgentOwnerWhatsAppVerifiedBuiltInSources.connectedSectionIds.contains(
          AgentOwnerWhatsAppReportSectionId.complaints,
        ),
        isFalse,
      );
      expect(
        AgentOwnerWhatsAppVerifiedBuiltInSources.connectedSectionIds.contains(
          AgentOwnerWhatsAppReportSectionId.refundsDisputes,
        ),
        isFalse,
      );
    });
  });
}
