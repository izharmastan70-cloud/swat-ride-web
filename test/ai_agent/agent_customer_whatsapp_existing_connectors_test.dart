import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/constants/agent_customer_whatsapp_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_support_constants.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_customer_whatsapp_control_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_customer_whatsapp_verified_read.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_read_only_payload.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/models/agent_tool_request.dart';
import 'package:swat_ride/ai_agent/services/agent_customer_whatsapp_existing_connector_source.dart';
import 'package:swat_ride/ai_agent/services/agent_customer_whatsapp_support_escalation_bridge.dart';
import 'package:swat_ride/ai_agent/services/agent_customer_whatsapp_verified_read_router.dart';
import 'package:swat_ride/ai_agent/services/agent_read_only_connector.dart';
import 'package:swat_ride/ai_agent/services/agent_read_only_connector_registry.dart';

class _FakeRideConnector implements AgentReadOnlyConnector {
  int calls = 0;
  AgentToolRequest? lastRequest;

  @override
  String get connectorId => 'connector.test.ride';

  @override
  String get module => 'ride';

  @override
  Set<String> get supportedActionIds => const <String>{
    AgentActionId.readRide,
    AgentActionId.readRideStatus,
  };

  @override
  bool supports(String actionId) => supportedActionIds.contains(actionId);

  @override
  Future<AgentReadOnlyPayload> executeReadOnly(AgentToolRequest request) async {
    calls += 1;
    lastRequest = request;

    return AgentReadOnlyPayload(
      actionId: request.actionId,
      module: module,
      data: <String, dynamic>{
        'rideId': request.actionScope['rideId'],
        'status': 'driver_assigned',
        'estimatedFare': 850,
        'apiToken': 'must-be-redacted',
      },
      generatedAt: DateTime.now().toUtc(),
    );
  }
}

AgentRole _whatsappRole() => buildInitialAgentRoles().firstWhere(
  (AgentRole role) => role.roleId == 'customer_whatsapp_agent',
);

AgentMasterSettings _enabledSettings() =>
    AgentMasterSettings.safeDefaults().copyWith(
      masterEnabled: true,
      emergencyReadOnly: false,
      freeAiEnabled: true,
      approvalEngineEnabled: true,
      customerWhatsAppAgentEnabled: true,
    );

void main() {
  test(
    'Customer WhatsApp role keeps module isolation and has no direct Ride/Food/etc read authority',
    () {
      final AgentRole role = _whatsappRole();

      expect(role.module, 'customer_whatsapp');

      expect(
        role.allowedActions,
        contains(AgentActionId.readCustomerWhatsAppVerifiedData),
      );

      expect(
        role.allowedActions,
        contains(AgentActionId.requestCustomerWhatsAppBusinessAction),
      );

      expect(role.allowedActions, isNot(contains(AgentActionId.readRide)));
      expect(
        role.allowedActions,
        isNot(contains(AgentActionId.readRideStatus)),
      );
      expect(role.allowedActions, isNot(contains(AgentActionId.readFoodOrder)));
      expect(
        role.allowedActions,
        isNot(contains(AgentActionId.readHotelBooking)),
      );
      expect(
        role.allowedActions,
        isNot(contains(AgentActionId.readTourBooking)),
      );
      expect(
        role.allowedActions,
        isNot(contains(AgentActionId.readCargoStatus)),
      );
    },
  );

  test(
    'verified Ride status uses narrow broker and central registered connector',
    () async {
      final _FakeRideConnector connector = _FakeRideConnector();

      final AgentCustomerWhatsAppExistingConnectorSource source =
          AgentCustomerWhatsAppExistingConnectorSource(
            service: AgentCustomerWhatsAppService.ride,
            settings: _enabledSettings(),
            role: _whatsappRole(),
            requestedBy: 'phase45_test',
            connectorRegistry: AgentReadOnlyConnectorRegistry(
              connectors: <AgentReadOnlyConnector>[connector],
            ),
          );

      final AgentCustomerWhatsAppVerifiedReadRouter router =
          AgentCustomerWhatsAppVerifiedReadRouter(
            sources: <String, AgentCustomerWhatsAppVerifiedReadSource>{
              AgentCustomerWhatsAppService.ride: source,
            },
          );

      final AgentCustomerWhatsAppVerifiedReadResult result = await router.route(
        controls: const AgentCustomerWhatsAppControlSettings(
          enabled: true,
          rideEnabled: true,
        ),
        request: const AgentCustomerWhatsAppVerifiedReadRequest(
          service: AgentCustomerWhatsAppService.ride,
          kind: AgentCustomerWhatsAppReadKind.bookingStatus,
          referenceId: 'ride-123',
          customerVerified: true,
        ),
      );

      expect(connector.calls, 1);
      expect(connector.lastRequest?.actionId, AgentActionId.readRideStatus);
      expect(connector.lastRequest?.actionScope, <String, dynamic>{
        'rideId': 'ride-123',
      });

      expect(result.mayUseInCustomerReply, isTrue);
      expect(result.backendVerified, isTrue);
      expect(result.safeData['status'], 'driver_assigned');

      // Existing sanitizer preserves the key but redacts the secret value.
      expect(result.safeData.containsKey('apiToken'), isTrue);
      expect(result.safeData['apiToken'], '[REDACTED]');
      expect(result.safeData['apiToken'], isNot('must-be-redacted'));

      expect(source.usesCentralConnectorRegistry, isTrue);
      expect(source.preservesPermissionModuleIsolation, isTrue);
      expect(source.directFirestoreAllowed, isFalse);
      expect(source.businessWriteAllowed, isFalse);
      expect(source.providerNetworkAllowed, isFalse);
      expect(source.ownerAuthorityAllowed, isFalse);
      expect(source.emergencyAuthorityAllowed, isFalse);
    },
  );

  test('master OFF blocks broker before connector is touched', () async {
    final _FakeRideConnector connector = _FakeRideConnector();

    final AgentMasterSettings offSettings = _enabledSettings().copyWith(
      customerWhatsAppAgentEnabled: false,
    );

    final AgentCustomerWhatsAppExistingConnectorSource source =
        AgentCustomerWhatsAppExistingConnectorSource(
          service: AgentCustomerWhatsAppService.ride,
          settings: offSettings,
          role: _whatsappRole(),
          requestedBy: 'phase45_test',
          connectorRegistry: AgentReadOnlyConnectorRegistry(
            connectors: <AgentReadOnlyConnector>[connector],
          ),
        );

    final AgentCustomerWhatsAppVerifiedReadResult result = await source
        .readVerified(
          const AgentCustomerWhatsAppVerifiedReadRequest(
            service: AgentCustomerWhatsAppService.ride,
            kind: AgentCustomerWhatsAppReadKind.bookingStatus,
            referenceId: 'ride-123',
            customerVerified: true,
          ),
        );

    expect(connector.calls, 0);
    expect(result.mayUseInCustomerReply, isFalse);
    expect(result.requiresHumanEscalation, isTrue);
    expect(result.code, 'WHATSAPP_RUNTIME_DENIED');
  });

  test(
    'missing registered business connector fails closed instead of guessing',
    () async {
      final AgentCustomerWhatsAppExistingConnectorSource source =
          AgentCustomerWhatsAppExistingConnectorSource(
            service: AgentCustomerWhatsAppService.hotel,
            settings: _enabledSettings(),
            role: _whatsappRole(),
            requestedBy: 'phase45_test',
            connectorRegistry: AgentReadOnlyConnectorRegistry(
              connectors: const <AgentReadOnlyConnector>[],
            ),
          );

      final AgentCustomerWhatsAppVerifiedReadResult result = await source
          .readVerified(
            const AgentCustomerWhatsAppVerifiedReadRequest(
              service: AgentCustomerWhatsAppService.hotel,
              kind: AgentCustomerWhatsAppReadKind.bookingStatus,
              referenceId: 'hotel-booking-1',
              customerVerified: true,
            ),
          );

      expect(result.mayUseInCustomerReply, isFalse);
      expect(result.requiresHumanEscalation, isTrue);
      expect(result.safeData, isEmpty);
      expect(result.code, 'VERIFIED_BACKEND_CONNECTOR_UNAVAILABLE');
    },
  );

  test('unsupported availability read never invents availability', () async {
    final AgentCustomerWhatsAppExistingConnectorSource source =
        AgentCustomerWhatsAppExistingConnectorSource(
          service: AgentCustomerWhatsAppService.ride,
          settings: _enabledSettings(),
          role: _whatsappRole(),
          requestedBy: 'phase45_test',
          connectorRegistry: AgentReadOnlyConnectorRegistry(
            connectors: const <AgentReadOnlyConnector>[],
          ),
        );

    final AgentCustomerWhatsAppVerifiedReadResult result = await source
        .readVerified(
          const AgentCustomerWhatsAppVerifiedReadRequest(
            service: AgentCustomerWhatsAppService.ride,
            kind: AgentCustomerWhatsAppReadKind.availability,
            referenceId: 'ride-1',
            customerVerified: true,
          ),
        );

    expect(result.mayUseInCustomerReply, isFalse);
    expect(result.requiresHumanEscalation, isTrue);
    expect(result.code, 'VERIFIED_READ_KIND_NOT_CONNECTED');
  });

  test('existing support policy routes refund to human support', () {
    const AgentCustomerWhatsAppSupportEscalationBridge bridge =
        AgentCustomerWhatsAppSupportEscalationBridge();

    final AgentCustomerWhatsAppSupportDecision decision = bridge.assess(
      message: 'I need a refund for my payment',
      module: 'ride',
      referenceId: 'ride-1',
      userIdAlias: 'customer-alias',
    );

    expect(decision.escalation, AgentSupportEscalation.humanSupport);
    expect(decision.humanHandoffRequired, isTrue);
    expect(decision.mayAutoResolve, isFalse);

    expect(bridge.reusesExistingSupportPolicy, isTrue);
    expect(bridge.createsTicketDirectly, isFalse);
    expect(bridge.sendsWhatsAppDirectly, isFalse);
  });

  test(
    'safety escalates without granting Phase 47 Emergency WhatsApp authority',
    () {
      const AgentCustomerWhatsAppSupportEscalationBridge bridge =
          AgentCustomerWhatsAppSupportEscalationBridge();

      final AgentCustomerWhatsAppSupportDecision decision = bridge.assess(
        message: 'SOS emergency accident',
        module: 'ride',
        referenceId: 'ride-1',
        userIdAlias: 'customer-alias',
      );

      expect(decision.escalation, AgentSupportEscalation.safetyHuman);
      expect(decision.humanHandoffRequired, isTrue);
      expect(decision.grantsEmergencyWhatsAppAuthority, isFalse);
      expect(decision.grantsOwnerWhatsAppAuthority, isFalse);
      expect(decision.createsDuplicateComplaintSystem, isFalse);
    },
  );

  test('general FAQ remains eligible for existing safe support flow', () {
    const AgentCustomerWhatsAppSupportEscalationBridge bridge =
        AgentCustomerWhatsAppSupportEscalationBridge();

    final AgentCustomerWhatsAppSupportDecision decision = bridge.assess(
      message: 'help what is SWAT RIDE service available',
      module: 'general',
      referenceId: '',
      userIdAlias: 'customer-alias',
    );

    expect(decision.escalation, AgentSupportEscalation.none);
    expect(decision.mayAutoResolve, isTrue);
  });
}
