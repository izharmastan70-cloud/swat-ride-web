import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_permission_decision.dart';
import 'package:swat_ride/ai_agent/models/agent_read_only_payload.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/models/agent_tool_request.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_authorization.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_foundation.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_source_acquisition_request.dart';

import 'package:swat_ride/ai_agent/services/agent_read_only_connector.dart';
import 'package:swat_ride/ai_agent/services/agent_read_only_connector_registry.dart';
import 'package:swat_ride/ai_agent/services/agent_voice_super_admin_authorization_broker.dart';
import 'package:swat_ride/ai_agent/services/agent_voice_super_admin_authorized_source_acquisition.dart';

class _MemoryVoiceAudit implements AgentVoiceSuperAdminAuthorizationAudit {
  final List<AgentPermissionDecision> decisions = <AgentPermissionDecision>[];

  @override
  Future<void> recordPermissionDecision({
    required AgentRole role,
    required AgentPermissionDecision decision,
    required String actorId,
  }) async {
    decisions.add(decision);
  }
}

class _FakeConnector implements AgentReadOnlyConnector {
  _FakeConnector({
    required this.connectorId,
    required this.module,
    required this.supportedActionIds,
    required this.responseData,
    this.throwOnExecute = false,

    this.overridePayloadModule,
  });

  @override
  final String connectorId;

  @override
  final String module;

  @override
  final Set<String> supportedActionIds;

  final Map<String, dynamic> responseData;
  final bool throwOnExecute;

  final String? overridePayloadModule;

  int calls = 0;
  AgentToolRequest? lastRequest;

  @override
  bool supports(String actionId) => supportedActionIds.contains(actionId);

  @override
  Future<AgentReadOnlyPayload> executeReadOnly(AgentToolRequest request) async {
    calls += 1;
    lastRequest = request;

    if (throwOnExecute) {
      throw StateError('connector failed');
    }

    return AgentReadOnlyPayload(
      actionId: request.actionId,
      module: overridePayloadModule ?? module,
      data: responseData,
      generatedAt: DateTime.utc(2026, 8, 18, 5, 30),
    );
  }
}

AgentRole _voiceRole() => buildInitialAgentRoles().firstWhere(
  (AgentRole role) => role.roleId == AgentVoiceSuperAdminFoundation.roleId,
);

AgentMasterSettings _enabledSettings() =>
    AgentMasterSettings.safeDefaults().copyWith(
      masterEnabled: true,
      freeAiEnabled: true,
      voiceSuperAdminAgentEnabled: true,
    );

AgentVoiceSuperAdminSessionBinding _session() {
  return AgentVoiceSuperAdminSessionBinding(
    principalType: AgentVoiceSuperAdminPrincipalType.superAdmin,
    principalUid: 'owner-1',
    deviceBindingId: 'device-1',
    sessionId: 'session-1',
    verificationLevel: AgentVoiceSuperAdminVerificationLevel.linkedAccount,
    verifiedAt: DateTime.utc(2026, 8, 18, 5),
    expiresAt: DateTime.utc(2026, 8, 18, 7),
  );
}

AgentVoiceSuperAdminAuthorizationRequest _authorizationRequest() {
  return const AgentVoiceSuperAdminAuthorizationRequest(
    actionId: AgentActionId.readVoiceSuperAdminVerifiedReport,
    actorId: 'owner-1',
    expectedDeviceBindingId: 'device-1',
    expectedSessionId: 'session-1',
  );
}

AgentVoiceSuperAdminAuthorizedSourceAcquisition _acquisition(
  AgentReadOnlyConnector connector, {
  _MemoryVoiceAudit? audit,
}) {
  final _MemoryVoiceAudit selectedAudit = audit ?? _MemoryVoiceAudit();

  return AgentVoiceSuperAdminAuthorizedSourceAcquisition(
    authorizationBroker: AgentVoiceSuperAdminAuthorizationBroker(
      audit: selectedAudit,
    ),
    connectorRegistry: AgentReadOnlyConnectorRegistry(
      connectors: <AgentReadOnlyConnector>[connector],
    ),
  );
}

void main() {
  group('Phase 48 Step 2D-B authorized source acquisition', () {
    test(
      'authorization failure blocks connector before source acquisition',
      () async {
        final connector = _FakeConnector(
          connectorId: 'connector.test.ride',
          module: 'ride',
          supportedActionIds: const <String>{AgentActionId.readRideStatus},
          responseData: const <String, dynamic>{'status': 'driver_assigned'},
        );

        final acquisition = _acquisition(connector);

        final section = await acquisition.acquire(
          settings: _enabledSettings().copyWith(
            voiceSuperAdminAgentEnabled: false,
          ),
          role: _voiceRole(),
          session: _session(),
          authorizationRequest: _authorizationRequest(),
          sourceRequest: const AgentVoiceSuperAdminSourceAcquisitionRequest(
            moduleId: 'NORMAL_RIDE',
            readKind: AgentVoiceSuperAdminSourceReadKind.status,
            referenceId: 'ride-1',
          ),
          now: DateTime.utc(2026, 8, 18, 5, 30),
        );

        expect(connector.calls, 0);
        expect(section.isUnavailable, isTrue);
        expect(section.facts, isEmpty);
      },
    );

    test(
      'authorized Ride status uses exact registered connector scope',
      () async {
        final connector = _FakeConnector(
          connectorId: 'connector.test.ride',
          module: 'ride',
          supportedActionIds: const <String>{AgentActionId.readRideStatus},
          responseData: const <String, dynamic>{
            'rideId': 'ride-1',
            'status': 'driver_assigned',
            'apiToken': 'must-be-redacted',
          },
        );

        final acquisition = _acquisition(connector);

        final section = await acquisition.acquire(
          settings: _enabledSettings(),
          role: _voiceRole(),
          session: _session(),
          authorizationRequest: _authorizationRequest(),
          sourceRequest: const AgentVoiceSuperAdminSourceAcquisitionRequest(
            moduleId: 'NORMAL_RIDE',
            readKind: AgentVoiceSuperAdminSourceReadKind.status,
            referenceId: 'ride-1',
          ),
          now: DateTime.utc(2026, 8, 18, 5, 30),
        );

        expect(connector.calls, 1);
        expect(
          connector.lastRequest?.roleId,
          AgentVoiceSuperAdminFoundation.roleId,
        );
        expect(connector.lastRequest?.actionId, AgentActionId.readRideStatus);
        expect(connector.lastRequest?.actionScope, <String, dynamic>{
          'rideId': 'ride-1',
        });

        expect(section.isVerified, isTrue);
        expect(section.moduleId, 'NORMAL_RIDE');
        expect(section.facts['status'], 'driver_assigned');
        expect(section.facts['apiToken'], '[REDACTED]');
      },
    );

    test(
      'Driver details maps only to exact Driver read connector action',
      () async {
        final connector = _FakeConnector(
          connectorId: 'connector.test.driver',
          module: 'driver',
          supportedActionIds: const <String>{AgentActionId.readDriver},
          responseData: const <String, dynamic>{'status': 'approved'},
        );

        final section = await _acquisition(connector).acquire(
          settings: _enabledSettings(),
          role: _voiceRole(),
          session: _session(),
          authorizationRequest: _authorizationRequest(),
          sourceRequest: const AgentVoiceSuperAdminSourceAcquisitionRequest(
            moduleId: 'DRIVER',
            readKind: AgentVoiceSuperAdminSourceReadKind.details,
            referenceId: 'driver-1',
          ),
          now: DateTime.utc(2026, 8, 18, 5, 30),
        );

        expect(connector.lastRequest?.actionId, AgentActionId.readDriver);
        expect(connector.lastRequest?.actionScope, <String, dynamic>{
          'driverId': 'driver-1',
        });
        expect(section.isVerified, isTrue);
      },
    );

    test('Food and Restaurant preserve exact ID-only scopes', () async {
      final food = _FakeConnector(
        connectorId: 'connector.test.food',
        module: 'food',
        supportedActionIds: const <String>{AgentActionId.readFoodOrder},
        responseData: const <String, dynamic>{'status': 'preparing'},
      );

      final foodSection = await _acquisition(food).acquire(
        settings: _enabledSettings(),
        role: _voiceRole(),
        session: _session(),
        authorizationRequest: _authorizationRequest(),
        sourceRequest: const AgentVoiceSuperAdminSourceAcquisitionRequest(
          moduleId: 'FOOD',
          readKind: AgentVoiceSuperAdminSourceReadKind.status,
          referenceId: 'order-1',
        ),
        now: DateTime.utc(2026, 8, 18, 5, 30),
      );

      expect(food.lastRequest?.actionId, AgentActionId.readFoodOrder);
      expect(food.lastRequest?.actionScope, <String, dynamic>{
        'orderId': 'order-1',
      });
      expect(foodSection.isVerified, isTrue);

      final restaurant = _FakeConnector(
        connectorId: 'connector.test.restaurant',
        module: 'restaurant',
        supportedActionIds: const <String>{AgentActionId.readRestaurant},
        responseData: const <String, dynamic>{'isOpen': true},
      );

      final restaurantSection = await _acquisition(restaurant).acquire(
        settings: _enabledSettings(),
        role: _voiceRole(),
        session: _session(),
        authorizationRequest: _authorizationRequest(),
        sourceRequest: const AgentVoiceSuperAdminSourceAcquisitionRequest(
          moduleId: 'RESTAURANT',
          readKind: AgentVoiceSuperAdminSourceReadKind.details,
          referenceId: 'restaurant-1',
        ),
        now: DateTime.utc(2026, 8, 18, 5, 30),
      );

      expect(restaurant.lastRequest?.actionId, AgentActionId.readRestaurant);
      expect(restaurant.lastRequest?.actionScope, <String, dynamic>{
        'restaurantId': 'restaurant-1',
      });
      expect(restaurantSection.isVerified, isTrue);
    });

    test(
      'Core System Health uses registered Core action with empty scope',
      () async {
        final connector = _FakeConnector(
          connectorId: 'connector.test.core',
          module: 'core',
          supportedActionIds: const <String>{AgentActionId.readSystemHealth},
          responseData: const <String, dynamic>{'aiMasterEnabled': true},
        );

        final section = await _acquisition(connector).acquire(
          settings: _enabledSettings(),
          role: _voiceRole(),
          session: _session(),
          authorizationRequest: _authorizationRequest(),
          sourceRequest: const AgentVoiceSuperAdminSourceAcquisitionRequest(
            moduleId: 'SYSTEM_HEALTH',
            readKind: AgentVoiceSuperAdminSourceReadKind.status,
          ),
          now: DateTime.utc(2026, 8, 18, 5, 30),
        );

        expect(connector.lastRequest?.actionId, AgentActionId.readSystemHealth);
        expect(connector.lastRequest?.actionScope, isEmpty);
        expect(section.isVerified, isTrue);
      },
    );

    test(
      'Hotel stays unavailable even if a fake Hotel connector is supplied',
      () async {
        final connector = _FakeConnector(
          connectorId: 'connector.test.hotel',
          module: 'hotel',
          supportedActionIds: const <String>{AgentActionId.readHotelBooking},
          responseData: const <String, dynamic>{'status': 'confirmed'},
        );

        final section = await _acquisition(connector).acquire(
          settings: _enabledSettings(),
          role: _voiceRole(),
          session: _session(),
          authorizationRequest: _authorizationRequest(),
          sourceRequest: const AgentVoiceSuperAdminSourceAcquisitionRequest(
            moduleId: 'HOTEL',
            readKind: AgentVoiceSuperAdminSourceReadKind.status,
            referenceId: 'hotel-booking-1',
          ),
          now: DateTime.utc(2026, 8, 18, 5, 30),
        );

        expect(connector.calls, 0);
        expect(section.isUnavailable, isTrue);
        expect(section.facts, isEmpty);
      },
    );

    test(
      'Cargo and Student remain unavailable and never invent data',
      () async {
        final connector = _FakeConnector(
          connectorId: 'connector.test.unused',
          module: 'cargo',
          supportedActionIds: const <String>{AgentActionId.readCargoStatus},
          responseData: const <String, dynamic>{'status': 'fake'},
        );

        final acquisition = _acquisition(connector);

        for (final String module in <String>['CARGO', 'STUDENT_RIDE']) {
          final section = await acquisition.acquire(
            settings: _enabledSettings(),
            role: _voiceRole(),
            session: _session(),
            authorizationRequest: _authorizationRequest(),
            sourceRequest: AgentVoiceSuperAdminSourceAcquisitionRequest(
              moduleId: module,
              readKind: AgentVoiceSuperAdminSourceReadKind.status,
              referenceId: 'ref-1',
            ),
            now: DateTime.utc(2026, 8, 18, 5, 30),
          );

          expect(section.isUnavailable, isTrue, reason: module);
          expect(section.facts, isEmpty, reason: module);
        }

        expect(connector.calls, 0);
      },
    );

    test('missing exact identifier fails before connector call', () async {
      final connector = _FakeConnector(
        connectorId: 'connector.test.ride',
        module: 'ride',
        supportedActionIds: const <String>{AgentActionId.readRideStatus},
        responseData: const <String, dynamic>{'status': 'driver_assigned'},
      );

      final section = await _acquisition(connector).acquire(
        settings: _enabledSettings(),
        role: _voiceRole(),
        session: _session(),
        authorizationRequest: _authorizationRequest(),
        sourceRequest: const AgentVoiceSuperAdminSourceAcquisitionRequest(
          moduleId: 'NORMAL_RIDE',
          readKind: AgentVoiceSuperAdminSourceReadKind.status,
        ),
        now: DateTime.utc(2026, 8, 18, 5, 30),
      );

      expect(connector.calls, 0);
      expect(section.isUnavailable, isTrue);
      expect(section.facts, isEmpty);
    });

    test(
      'connector exception fails to UNAVAILABLE with no guessed zero/default',
      () async {
        final connector = _FakeConnector(
          connectorId: 'connector.test.ride',
          module: 'ride',
          supportedActionIds: const <String>{AgentActionId.readRideStatus},
          responseData: const <String, dynamic>{},
          throwOnExecute: true,
        );

        final section = await _acquisition(connector).acquire(
          settings: _enabledSettings(),
          role: _voiceRole(),
          session: _session(),
          authorizationRequest: _authorizationRequest(),
          sourceRequest: const AgentVoiceSuperAdminSourceAcquisitionRequest(
            moduleId: 'NORMAL_RIDE',
            readKind: AgentVoiceSuperAdminSourceReadKind.status,
            referenceId: 'ride-1',
          ),
          now: DateTime.utc(2026, 8, 18, 5, 30),
        );

        expect(section.isUnavailable, isTrue);
        expect(section.facts, isEmpty);
        expect(section.summaryText, 'UNAVAILABLE');
      },
    );

    test(
      'malformed connector payload action/module binding fails closed',
      () async {
        final connector = _FakeConnector(
          connectorId: 'connector.test.ride',
          module: 'ride',
          supportedActionIds: const <String>{AgentActionId.readRideStatus},
          responseData: const <String, dynamic>{'status': 'driver_assigned'},
          overridePayloadModule: 'food',
        );

        final section = await _acquisition(connector).acquire(
          settings: _enabledSettings(),
          role: _voiceRole(),
          session: _session(),
          authorizationRequest: _authorizationRequest(),
          sourceRequest: const AgentVoiceSuperAdminSourceAcquisitionRequest(
            moduleId: 'NORMAL_RIDE',
            readKind: AgentVoiceSuperAdminSourceReadKind.status,
            referenceId: 'ride-1',
          ),
          now: DateTime.utc(2026, 8, 18, 5, 30),
        );

        expect(section.isUnavailable, isTrue);
        expect(section.facts, isEmpty);
      },
    );

    test(
      'acquisition layer has no write/approval/Safety/provider authority',
      () {
        final connector = _FakeConnector(
          connectorId: 'connector.test.core',
          module: 'core',
          supportedActionIds: const <String>{AgentActionId.readSystemHealth},
          responseData: const <String, dynamic>{},
        );

        final acquisition = _acquisition(connector);

        expect(acquisition.usesDedicatedVoiceAuthorizationBroker, isTrue);
        expect(acquisition.usesCentralConnectorRegistry, isTrue);
        expect(acquisition.usesExistingReadOnlySanitizer, isTrue);
        expect(acquisition.preservesPermissionModuleIsolation, isTrue);
        expect(acquisition.usesReadOnlyExecutorWithVoiceRole, isFalse);

        expect(acquisition.grantsPermission, isFalse);
        expect(acquisition.createsApproval, isFalse);
        expect(acquisition.consumesApproval, isFalse);
        expect(acquisition.directFirestoreAllowed, isFalse);
        expect(acquisition.businessWriteAllowed, isFalse);
        expect(acquisition.safetyMutationAllowed, isFalse);
        expect(acquisition.providerNetworkAllowed, isFalse);
        expect(acquisition.speechTransportAllowed, isFalse);
        expect(acquisition.deployAllowed, isFalse);
      },
    );
  });
}
