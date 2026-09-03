import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/constants/agent_customer_whatsapp_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_enums.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_customer_whatsapp_control_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_customer_whatsapp_verified_read.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_action_registry.dart';
import 'package:swat_ride/ai_agent/services/agent_customer_whatsapp_verified_read_router.dart';
import 'package:swat_ride/ai_agent/services/agent_permission_engine.dart';
import 'package:swat_ride/ai_agent/services/agent_runtime_gate.dart';

class _FakeVerifiedSource implements AgentCustomerWhatsAppVerifiedReadSource {
  _FakeVerifiedSource({required this.result});

  final AgentCustomerWhatsAppVerifiedReadResult result;
  int calls = 0;

  @override
  Future<AgentCustomerWhatsAppVerifiedReadResult> readVerified(
    AgentCustomerWhatsAppVerifiedReadRequest request,
  ) async {
    calls += 1;
    return result;
  }
}

void main() {
  test(
    'Customer WhatsApp action IDs are registered with correct authority',
    () {
      expect(
        AgentActionId.isKnown(AgentActionId.readCustomerWhatsAppVerifiedData),
        isTrue,
      );

      expect(
        AgentActionId.isKnown(
          AgentActionId.requestCustomerWhatsAppBusinessAction,
        ),
        isTrue,
      );

      final readDefinition = AgentActionRegistry.get(
        AgentActionId.readCustomerWhatsAppVerifiedData,
      );

      final writeDefinition = AgentActionRegistry.get(
        AgentActionId.requestCustomerWhatsAppBusinessAction,
      );

      expect(readDefinition, isNotNull);
      expect(readDefinition!.module, 'customer_whatsapp');
      expect(readDefinition.readOnly, isTrue);
      expect(readDefinition.alwaysRequiresApproval, isFalse);

      expect(writeDefinition, isNotNull);
      expect(writeDefinition!.module, 'customer_whatsapp');
      expect(writeDefinition.readOnly, isFalse);
      expect(writeDefinition.alwaysRequiresApproval, isTrue);
    },
  );

  test(
    'Customer WhatsApp role is suggest-only and business action requires approval',
    () {
      final AgentRole role = buildInitialAgentRoles().firstWhere(
        (AgentRole value) => value.roleId == 'customer_whatsapp_agent',
      );

      expect(role.mode, AgentMode.suggestOnly);
      expect(role.privacyLevel, PrivacyLevel.private);

      expect(
        role.allowedActions,
        contains(AgentActionId.readCustomerWhatsAppVerifiedData),
      );

      expect(
        role.allowedActions,
        contains(AgentActionId.requestCustomerWhatsAppBusinessAction),
      );

      expect(
        role.approvalRequiredActions,
        contains(AgentActionId.requestCustomerWhatsAppBusinessAction),
      );

      final readDecision = const AgentPermissionEngine().evaluate(
        role: role,
        actionId: AgentActionId.readCustomerWhatsAppVerifiedData,
      );

      expect(readDecision.isAllowed, isTrue);

      final writeDecision = const AgentPermissionEngine().evaluate(
        role: role,
        actionId: AgentActionId.requestCustomerWhatsAppBusinessAction,
      );

      expect(writeDecision.needsApproval, isTrue);
      expect(writeDecision.isAllowed, isFalse);
      expect(writeDecision.isDenied, isFalse);
    },
  );

  test(
    'Runtime Gate denies Customer WhatsApp role while master switch is OFF',
    () {
      final AgentRole role = buildInitialAgentRoles().firstWhere(
        (AgentRole value) => value.roleId == 'customer_whatsapp_agent',
      );

      final permissionDecision = const AgentPermissionEngine().evaluate(
        role: role,
        actionId: AgentActionId.readCustomerWhatsAppVerifiedData,
      );

      final AgentMasterSettings settings = AgentMasterSettings.safeDefaults()
          .copyWith(
            masterEnabled: true,
            emergencyReadOnly: false,
            freeAiEnabled: true,
            approvalEngineEnabled: true,
            customerWhatsAppAgentEnabled: false,
          );

      final runtimeDecision = const AgentRuntimeGate().apply(
        settings: settings,
        role: role,
        permissionDecision: permissionDecision,
      );

      expect(runtimeDecision.isDenied, isTrue);
      expect(
        runtimeDecision.reason,
        contains('Customer WhatsApp Agent master switch is OFF'),
      );
    },
  );

  test(
    'Runtime Gate permits already-authorized read when Customer WhatsApp switch is ON',
    () {
      final AgentRole role = buildInitialAgentRoles().firstWhere(
        (AgentRole value) => value.roleId == 'customer_whatsapp_agent',
      );

      final permissionDecision = const AgentPermissionEngine().evaluate(
        role: role,
        actionId: AgentActionId.readCustomerWhatsAppVerifiedData,
      );

      final AgentMasterSettings settings = AgentMasterSettings.safeDefaults()
          .copyWith(
            masterEnabled: true,
            emergencyReadOnly: false,
            freeAiEnabled: true,
            approvalEngineEnabled: true,
            customerWhatsAppAgentEnabled: true,
          );

      final runtimeDecision = const AgentRuntimeGate().apply(
        settings: settings,
        role: role,
        permissionDecision: permissionDecision,
      );

      expect(runtimeDecision.isAllowed, isTrue);
    },
  );

  test(
    'verified router blocks service when master or service toggle is OFF',
    () async {
      final source = _FakeVerifiedSource(
        result: AgentCustomerWhatsAppVerifiedReadResult(
          ok: true,
          backendVerified: true,
          code: 'VERIFIED',
          safeData: const <String, dynamic>{'status': 'confirmed'},
        ),
      );

      final router = AgentCustomerWhatsAppVerifiedReadRouter(
        sources: <String, AgentCustomerWhatsAppVerifiedReadSource>{
          AgentCustomerWhatsAppService.ride: source,
        },
      );

      final masterOff = await router.route(
        controls: const AgentCustomerWhatsAppControlSettings(
          enabled: false,
          rideEnabled: true,
        ),
        request: const AgentCustomerWhatsAppVerifiedReadRequest(
          service: AgentCustomerWhatsAppService.ride,
          kind: AgentCustomerWhatsAppReadKind.serviceInfo,
        ),
      );

      expect(masterOff.mayUseInCustomerReply, isFalse);
      expect(source.calls, 0);

      final serviceOff = await router.route(
        controls: const AgentCustomerWhatsAppControlSettings(
          enabled: true,
          rideEnabled: false,
        ),
        request: const AgentCustomerWhatsAppVerifiedReadRequest(
          service: AgentCustomerWhatsAppService.ride,
          kind: AgentCustomerWhatsAppReadKind.serviceInfo,
        ),
      );

      expect(serviceOff.mayUseInCustomerReply, isFalse);
      expect(source.calls, 0);
    },
  );

  test(
    'sensitive booking status requires customer verification before backend read',
    () async {
      final source = _FakeVerifiedSource(
        result: AgentCustomerWhatsAppVerifiedReadResult(
          ok: true,
          backendVerified: true,
          code: 'VERIFIED',
        ),
      );

      final router = AgentCustomerWhatsAppVerifiedReadRouter(
        sources: <String, AgentCustomerWhatsAppVerifiedReadSource>{
          AgentCustomerWhatsAppService.ride: source,
        },
      );

      final result = await router.route(
        controls: const AgentCustomerWhatsAppControlSettings(
          enabled: true,
          rideEnabled: true,
        ),
        request: const AgentCustomerWhatsAppVerifiedReadRequest(
          service: AgentCustomerWhatsAppService.ride,
          kind: AgentCustomerWhatsAppReadKind.bookingStatus,
          customerVerified: false,
        ),
      );

      expect(result.requiresCustomerVerification, isTrue);
      expect(result.mayUseInCustomerReply, isFalse);
      expect(source.calls, 0);
    },
  );

  test(
    'unverified backend result can never be used in customer reply',
    () async {
      final source = _FakeVerifiedSource(
        result: AgentCustomerWhatsAppVerifiedReadResult(
          ok: true,
          backendVerified: false,
          code: 'UNVERIFIED_SOURCE',
          safeData: const <String, dynamic>{'fare': 999},
        ),
      );

      final router = AgentCustomerWhatsAppVerifiedReadRouter(
        sources: <String, AgentCustomerWhatsAppVerifiedReadSource>{
          AgentCustomerWhatsAppService.ride: source,
        },
      );

      final result = await router.route(
        controls: const AgentCustomerWhatsAppControlSettings(
          enabled: true,
          rideEnabled: true,
        ),
        request: const AgentCustomerWhatsAppVerifiedReadRequest(
          service: AgentCustomerWhatsAppService.ride,
          kind: AgentCustomerWhatsAppReadKind.fare,
        ),
      );

      expect(source.calls, 1);
      expect(result.mayUseInCustomerReply, isFalse);
      expect(result.safeData, isEmpty);
      expect(result.code, 'BACKEND_FACT_NOT_VERIFIED');
    },
  );

  test(
    'verified backend result may be used only as safe read-only reply data',
    () async {
      final source = _FakeVerifiedSource(
        result: AgentCustomerWhatsAppVerifiedReadResult(
          ok: true,
          backendVerified: true,
          code: 'VERIFIED_BACKEND_FACT',
          safeData: const <String, dynamic>{'fare': 850, 'currency': 'PKR'},
        ),
      );

      final router = AgentCustomerWhatsAppVerifiedReadRouter(
        sources: <String, AgentCustomerWhatsAppVerifiedReadSource>{
          AgentCustomerWhatsAppService.ride: source,
        },
      );

      final result = await router.route(
        controls: const AgentCustomerWhatsAppControlSettings(
          enabled: true,
          rideEnabled: true,
        ),
        request: const AgentCustomerWhatsAppVerifiedReadRequest(
          service: AgentCustomerWhatsAppService.ride,
          kind: AgentCustomerWhatsAppReadKind.fare,
        ),
      );

      expect(result.mayUseInCustomerReply, isTrue);
      expect(result.safeData['fare'], 850);

      expect(router.providerTransportAllowed, isFalse);
      expect(router.whatsappNetworkAllowed, isFalse);
      expect(router.businessWriteAllowed, isFalse);
      expect(router.approvalBypassAllowed, isFalse);
      expect(router.runtimeGateBypassAllowed, isFalse);
    },
  );
}
