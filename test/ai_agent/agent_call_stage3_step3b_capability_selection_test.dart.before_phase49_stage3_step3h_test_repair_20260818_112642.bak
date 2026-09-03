import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_action_definition.dart';
import 'package:swat_ride/ai_agent/models/agent_call_service_request_draft.dart';
import 'package:swat_ride/ai_agent/models/agent_call_stage3_capability_selection.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_action_registry.dart';

AgentRole _callRole() {
  return buildInitialAgentRoles().firstWhere(
    (AgentRole role) => role.roleId == 'call_agent',
  );
}

String _readProjectFile(String path) {
  final File file = File(path);

  if (!file.existsSync()) {
    throw StateError('Required source file not found: $path');
  }

  return file.readAsStringSync();
}

void main() {
  group('Phase 49 Stage 3 Step 3B capability selection', () {
    test('Food order STATUS/READ is the selected first capability', () {
      expect(
        AgentCallStage3CapabilitySelection.selectedService,
        AgentCallServiceType.food,
      );
      expect(
        AgentCallStage3CapabilitySelection.selectedRequestType,
        AgentCallServiceRequestType.status,
      );
      expect(
        AgentCallStage3CapabilitySelection.selectedBusinessReadAction,
        AgentActionId.readFoodOrder,
      );
      expect(AgentCallStage3CapabilitySelection.stage3BSelectionReady, isTrue);
    });

    test('selected Food business action is LOW risk and read-only', () {
      final AgentActionDefinition definition = AgentActionRegistry.get(
        AgentActionId.readFoodOrder,
      )!;

      expect(definition.module, 'food');
      expect(definition.risk, AgentActionRisk.low);
      expect(definition.readOnly, isTrue);
      expect(definition.alwaysRequiresApproval, isFalse);
    });

    test('real Food read-only connector is centrally registered', () {
      final String registrySource = _readProjectFile(
        'lib/ai_agent/services/agent_read_only_connector_registry.dart',
      );
      final String foodConnectorSource = _readProjectFile(
        'lib/ai_agent/services/agent_food_order_read_only_connector.dart',
      );

      expect(registrySource, contains('AgentFoodOrderReadOnlyConnector()'));
      expect(
        foodConnectorSource,
        contains('class AgentFoodOrderReadOnlyConnector'),
      );
      expect(
        foodConnectorSource,
        contains('implements AgentReadOnlyConnector'),
      );
      expect(foodConnectorSource, contains('AgentActionId.readFoodOrder'));
    });

    test('Hotel and Tour are not central-registry ready yet', () {
      final String registrySource = _readProjectFile(
        'lib/ai_agent/services/agent_read_only_connector_registry.dart',
      );

      expect(
        registrySource,
        isNot(contains('AgentHotelBookingReadOnlyConnector()')),
      );
      expect(
        registrySource,
        isNot(contains('AgentTourBookingReadOnlyConnector()')),
      );

      expect(
        AgentCallStage3CapabilitySelection.hotelCentralRegistryReady,
        isFalse,
      );
      expect(
        AgentCallStage3CapabilitySelection.tourCentralRegistryReady,
        isFalse,
      );
    });

    test('Cargo Student and Parcel stay deferred', () {
      expect(AgentCallStage3CapabilitySelection.cargoConnectorReady, isFalse);
      expect(AgentCallStage3CapabilitySelection.studentConnectorReady, isFalse);
      expect(
        AgentCallStage3CapabilitySelection.parcelConnectorVerified,
        isFalse,
      );

      expect(AgentCallStage3CapabilitySelection.cargoSelectedNow, isFalse);
      expect(AgentCallStage3CapabilitySelection.studentSelectedNow, isFalse);
      expect(AgentCallStage3CapabilitySelection.parcelSelectedNow, isFalse);
    });

    test('Step 3B does not expand call_agent permissions', () {
      final AgentRole role = _callRole();

      expect(role.allowedActions, <String>[
        AgentActionId.createCallRideBooking,
        AgentActionId.readCallExistingRide,
        AgentActionId.readCallFoodOrderStatus,
        AgentActionId.readCallTourBookingStatus,
      ]);

      expect(role.allowedActions, isNot(contains(AgentActionId.readFoodOrder)));
    });

    test('generic Food action cannot become Call authority', () {
      expect(
        AgentCallStage3CapabilitySelection.requiresDedicatedCallAction,
        isTrue,
      );
      expect(
        AgentCallStage3CapabilitySelection.mayGrantGenericFoodActionToCallAgent,
        isFalse,
      );
      expect(
        AgentCallStage3CapabilitySelection.requiresCentralPermissionEngine,
        isTrue,
      );
      expect(AgentCallStage3CapabilitySelection.requiresRuntimeGate, isTrue);
      expect(
        AgentCallStage3CapabilitySelection.requiresTrustedOrderAccessBinding,
        isTrue,
      );
    });

    test(
      'phone transcript voice orderId and Firebase user are not authority',
      () {
        expect(
          AgentCallStage3CapabilitySelection.rawPhoneCanAuthorize,
          isFalse,
        );
        expect(
          AgentCallStage3CapabilitySelection.transcriptCanAuthorize,
          isFalse,
        );
        expect(AgentCallStage3CapabilitySelection.voiceCanAuthorize, isFalse);
        expect(
          AgentCallStage3CapabilitySelection.orderIdAloneCanAuthorize,
          isFalse,
        );
        expect(
          AgentCallStage3CapabilitySelection
              .currentFirebaseUserCanImpersonateCaller,
          isFalse,
        );
      },
    );

    test('Step 3B executes no Food write or connector read', () {
      expect(AgentCallStage3CapabilitySelection.addsCallPermission, isFalse);
      expect(AgentCallStage3CapabilitySelection.executesFoodConnector, isFalse);
      expect(AgentCallStage3CapabilitySelection.readsFoodOrderNow, isFalse);
      expect(AgentCallStage3CapabilitySelection.createsFoodOrder, isFalse);
      expect(AgentCallStage3CapabilitySelection.cancelsFoodOrder, isFalse);
      expect(AgentCallStage3CapabilitySelection.refundsFoodOrder, isFalse);
      expect(AgentCallStage3CapabilitySelection.changesPayment, isFalse);
      expect(AgentCallStage3CapabilitySelection.assignsRider, isFalse);
      expect(AgentCallStage3CapabilitySelection.writesFoodData, isFalse);
    });

    test('safe selection map cannot overclaim implementation', () {
      final Map<String, dynamic> map =
          AgentCallStage3CapabilitySelection.toSafeMap();

      expect(map['selectedService'], 'FOOD');
      expect(map['selectedRequestType'], 'STATUS');
      expect(map['stage3BSelectionReady'], isTrue);
      expect(map['addsCallPermission'], isFalse);
      expect(map['executesFoodConnector'], isFalse);
      expect(map['writesFoodData'], isFalse);
      expect(map['requiresDedicatedCallAction'], isTrue);
    });
  });
}
