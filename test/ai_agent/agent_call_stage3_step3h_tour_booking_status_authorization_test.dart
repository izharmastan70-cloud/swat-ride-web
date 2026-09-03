import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/constants/agent_enums.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_action_definition.dart';
import 'package:swat_ride/ai_agent/models/agent_call_tour_booking_status_contract.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_action_registry.dart';
import 'package:swat_ride/ai_agent/services/agent_call_tour_booking_status_authorization_service.dart';

AgentRole _callRole() {
  return buildInitialAgentRoles().firstWhere(
    (AgentRole role) => role.roleId == 'call_agent',
  );
}

AgentRole _tourRole() {
  return buildInitialAgentRoles().firstWhere(
    (AgentRole role) => role.roleId == 'tour_agent',
  );
}

AgentMasterSettings _settings({
  bool masterEnabled = true,
  bool emergencyReadOnly = false,
  bool freeAiEnabled = true,
  bool callAgentEnabled = true,
}) {
  final DateTime now = DateTime.utc(2026, 8, 18, 11);

  return AgentMasterSettings(
    masterEnabled: masterEnabled,
    emergencyReadOnly: emergencyReadOnly,
    freeAiEnabled: freeAiEnabled,
    localAiEnabled: false,
    paidCodeAiEnabled: false,
    callAgentEnabled: callAgentEnabled,
    approvalEngineEnabled: true,
    auditLoggingEnabled: true,
    monthlyPaidCodeBudgetRs: 0,
    paidCodeBudgetUsedRs: 0,
    emergencyActivatedAt: emergencyReadOnly ? now : null,
    emergencyActivatedBy: emergencyReadOnly ? 'test' : '',
    emergencyReason: emergencyReadOnly ? 'test emergency' : '',
    createdAt: now,
    updatedAt: null,
  );
}

AgentCallTourBookingStatusRequest _request({
  String session = 'call-session-tour-1',
  String requestedBy = 'trusted-call-actor-1',
  String caller = 'caller-ref-1',
  String contact = 'contact-ref-1',
  String booking = 'tour-booking-ref-1',
}) {
  return AgentCallTourBookingStatusRequest(
    callSessionId: session,
    requestedBy: requestedBy,
    trustedCallerReferenceId: caller,
    trustedContactReferenceId: contact,
    trustedTourBookingReferenceId: booking,
  );
}

void main() {
  group('Phase 49 Stage 3 Step 3H Tour status authorization', () {
    const AgentCallTourBookingStatusAuthorizationService service =
        AgentCallTourBookingStatusAuthorizationService();

    test(
      'dedicated Call Tour status action is registered low-risk read-only',
      () {
        expect(
          AgentActionId.values,
          contains(AgentActionId.readCallTourBookingStatus),
        );

        final AgentActionDefinition definition = AgentActionRegistry.get(
          AgentActionId.readCallTourBookingStatus,
        )!;

        expect(definition.actionId, AgentActionId.readCallTourBookingStatus);
        expect(definition.module, 'call');
        expect(definition.readOnly, isTrue);
        expect(definition.risk, AgentActionRisk.low);
        expect(definition.alwaysRequiresApproval, isFalse);
      },
    );

    test('call_agent has exactly four dedicated Call actions', () {
      final AgentRole role = _callRole();

      expect(role.mode, AgentMode.auto);
      expect(role.allowedActions, <String>[
        AgentActionId.createCallRideBooking,
        AgentActionId.readCallExistingRide,
        AgentActionId.readCallFoodOrderStatus,
        AgentActionId.readCallTourBookingStatus,
      ]);

      expect(role.allowedActions, isNot(contains(AgentActionId.readFoodOrder)));
      expect(
        role.allowedActions,
        isNot(contains(AgentActionId.readTourBooking)),
      );
      expect(
        role.allowedActions,
        isNot(contains(AgentActionId.cancelTourBooking)),
      );
      expect(
        role.allowedActions,
        isNot(contains(AgentActionId.changeTourPrice)),
      );
    });

    test('complete trusted Tour booking binding validates safely', () {
      final AgentCallTourBookingStatusRequest request = _request();

      expect(request.hasCompleteTrustedBinding, isTrue);
      expect(request.validate, returnsNormally);

      final Map<String, dynamic> map = request.toSafeMap();

      expect(map['trustedTourBookingReferenceId'], 'tour-booking-ref-1');
      expect(map['rawPhoneIncluded'], isFalse);
      expect(map['transcriptIncluded'], isFalse);
      expect(map['voiceIncluded'], isFalse);
      expect(map['firebaseUidIncluded'], isFalse);
      expect(map['pickupCoordinatesIncluded'], isFalse);
      expect(map['specialRequestIncluded'], isFalse);
      expect(map['financialAmountsIncluded'], isFalse);
      expect(map['privateAssignmentIdsIncluded'], isFalse);
      expect(map['tourReadExecuted'], isFalse);
      expect(map['tourWriteAuthority'], isFalse);
    });

    test('missing trusted Tour booking binding fails closed', () {
      final result = service.authorize(
        settings: _settings(),
        role: _callRole(),
        request: _request(booking: ''),
      );

      expect(result.isAllowed, isFalse);
      expect(result.trustedContextBound, isFalse);
      expect(result.reason, 'TRUSTED_TOUR_BOOKING_BINDING_REQUIRED');
    });

    test(
      'valid trusted request passes Permission Engine then Runtime Gate',
      () {
        final result = service.authorize(
          settings: _settings(),
          role: _callRole(),
          request: _request(),
        );

        expect(result.isAllowed, isTrue);
        expect(result.permissionAllowed, isTrue);
        expect(result.runtimeAllowed, isTrue);
        expect(result.trustedContextBound, isTrue);
        expect(result.exactRoleBound, isTrue);
        expect(result.exactModuleBound, isTrue);
        expect(result.exactActionBound, isTrue);
        expect(result.approvalFreeRead, isTrue);
        expect(result.reason, isEmpty);
      },
    );

    test('AI master OFF blocks dedicated Tour status authorization', () {
      final result = service.authorize(
        settings: _settings(masterEnabled: false),
        role: _callRole(),
        request: _request(),
      );

      expect(result.isAllowed, isFalse);
      expect(result.runtimeAllowed, isFalse);
    });

    test(
      'Call Agent switch OFF blocks dedicated Tour status authorization',
      () {
        final result = service.authorize(
          settings: _settings(callAgentEnabled: false),
          role: _callRole(),
          request: _request(),
        );

        expect(result.isAllowed, isFalse);
        expect(result.runtimeAllowed, isFalse);
      },
    );

    test('Free AI OFF blocks free-AI Call role', () {
      final result = service.authorize(
        settings: _settings(freeAiEnabled: false),
        role: _callRole(),
        request: _request(),
      );

      expect(result.isAllowed, isFalse);
      expect(result.runtimeAllowed, isFalse);
    });

    test(
      'Emergency read-only blocks AUTO Call role via existing Runtime Gate',
      () {
        final result = service.authorize(
          settings: _settings(emergencyReadOnly: true),
          role: _callRole(),
          request: _request(),
        );

        expect(result.isAllowed, isFalse);
        expect(result.runtimeAllowed, isFalse);
      },
    );

    test('Tour Agent role cannot impersonate Call Agent authority', () {
      final result = service.authorize(
        settings: _settings(),
        role: _tourRole(),
        request: _request(),
      );

      expect(result.isAllowed, isFalse);
      expect(result.exactRoleBound, isFalse);
      expect(result.exactModuleBound, isFalse);
    });

    test('authorization itself executes no Tour read/write capability', () {
      expect(service.usesAgentPermissionEngine, isTrue);
      expect(service.usesAgentRuntimeGate, isTrue);
      expect(service.duplicatesPermissionLogic, isFalse);

      expect(service.genericTourActionCanGrantCallPermission, isFalse);
      expect(service.rawPhoneCanGrantPermission, isFalse);
      expect(service.transcriptCanGrantPermission, isFalse);
      expect(service.voiceCanGrantPermission, isFalse);
      expect(service.currentFirebaseUserCanGrantPermission, isFalse);
      expect(service.bookingReferenceAloneCanGrantPermission, isFalse);

      expect(service.executesTourConnector, isFalse);
      expect(service.readsTourBooking, isFalse);
      expect(service.writesTourBooking, isFalse);
      expect(service.createsTourBooking, isFalse);
      expect(service.cancelsTourBooking, isFalse);
      expect(service.changesTourPrice, isFalse);
      expect(service.changesTourPayment, isFalse);
      expect(service.changesTourAssignment, isFalse);

      expect(service.invokesFirestore, isFalse);
      expect(service.invokesFirebaseAuth, isFalse);
      expect(service.invokesTourBookingService, isFalse);
      expect(service.invokesHttp, isFalse);
      expect(service.invokesCloudFunctions, isFalse);
      expect(service.invokesTelephonyProvider, isFalse);
    });

    test('Tour connector remains outside central registry in Step 3H', () {
      final String registry = File(
        'lib/ai_agent/services/'
        'agent_read_only_connector_registry.dart',
      ).readAsStringSync();

      expect(registry, isNot(contains('AgentTourBookingReadOnlyConnector()')));
    });
  });
}
