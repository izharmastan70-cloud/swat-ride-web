import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_query_plan.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_source_acquisition_request.dart';
import 'package:swat_ride/ai_agent/services/agent_voice_super_admin_query_planner.dart';

void main() {
  group('Phase 48 Step 2F deterministic query planner', () {
    const AgentVoiceSuperAdminQueryPlanner planner =
        AgentVoiceSuperAdminQueryPlanner();

    test('whole SWAT RIDE query becomes explicit ecosystem source list', () {
      final AgentVoiceSuperAdminQueryPlan plan = planner.plan(
        request: const AgentVoiceSuperAdminQueryPlanningRequest(
          queryText: 'Mujhe poore SWAT RIDE ka aaj ka haal batao',
        ),
        now: DateTime.utc(2026, 8, 18, 6),
      );

      expect(plan.isPlanned, isTrue);
      expect(plan.intent, 'WHOLE_ECOSYSTEM_STATUS');
      expect(plan.reportRequest, isNotNull);

      final List<String> modules = plan.reportRequest!.sourceRequests
          .map(
            (AgentVoiceSuperAdminSourceAcquisitionRequest item) =>
                item.moduleId,
          )
          .toList(growable: false);

      expect(modules, contains('SYSTEM_HEALTH'));
      expect(modules, contains('NORMAL_RIDE'));
      expect(modules, contains('DRIVER'));
      expect(modules, contains('FOOD'));
      expect(modules, contains('RESTAURANT'));
      expect(modules, contains('HOTEL'));
      expect(modules, contains('TOUR'));
      expect(modules, contains('CARGO'));
      expect(modules, contains('PARCEL'));
      expect(modules, contains('STUDENT_RIDE'));
      expect(modules, contains('FINANCE_OWNER_READ'));
      expect(modules, contains('COMPLAINTS_SUPPORT_READ'));
      expect(modules, contains('SAFETY_SOS_OWNER_READ'));
      expect(modules, contains('AI_USAGE_COST_OWNER_READ'));
      expect(modules, contains('SECURITY_AUDIT_OWNER_READ'));
      expect(modules.toSet().length, modules.length);
    });

    test(
      'ride status uses trusted supplied rideId and never parses one from text',
      () {
        final AgentVoiceSuperAdminQueryPlan plan = planner.plan(
          request: const AgentVoiceSuperAdminQueryPlanningRequest(
            queryText: 'ride status ride-should-not-be-parsed',
            referenceIds: <String, String>{
              AgentVoiceSuperAdminQueryReferenceKey.rideId: 'trusted-ride-1',
            },
          ),
          now: DateTime.utc(2026, 8, 18, 6),
        );

        expect(plan.isPlanned, isTrue);

        final AgentVoiceSuperAdminSourceAcquisitionRequest source =
            plan.reportRequest!.sourceRequests.single;

        expect(source.moduleId, 'NORMAL_RIDE');
        expect(source.readKind, AgentVoiceSuperAdminSourceReadKind.status);
        expect(source.referenceId, 'trusted-ride-1');
        expect(source.referenceId, isNot('ride-should-not-be-parsed'));
      },
    );

    test(
      'missing trusted exact ID remains empty for downstream UNAVAILABLE',
      () {
        final AgentVoiceSuperAdminQueryPlan plan = planner.plan(
          request: const AgentVoiceSuperAdminQueryPlanningRequest(
            queryText: 'driver status',
          ),
          now: DateTime.utc(2026, 8, 18, 6),
        );

        expect(plan.isPlanned, isTrue);
        expect(plan.reportRequest!.sourceRequests.single.referenceId, isEmpty);
      },
    );

    test('multi-module read query becomes explicit deduplicated requests', () {
      final AgentVoiceSuperAdminQueryPlan plan = planner.plan(
        request: const AgentVoiceSuperAdminQueryPlanningRequest(
          queryText:
              'system health and food order status and restaurant status',
          referenceIds: <String, String>{
            AgentVoiceSuperAdminQueryReferenceKey.orderId: 'order-1',
            AgentVoiceSuperAdminQueryReferenceKey.restaurantId: 'restaurant-1',
          },
        ),
        now: DateTime.utc(2026, 8, 18, 6),
      );

      expect(plan.isPlanned, isTrue);
      expect(plan.intent, 'MULTI_MODULE_STATUS');

      final List<String> modules = plan.reportRequest!.sourceRequests
          .map(
            (AgentVoiceSuperAdminSourceAcquisitionRequest item) =>
                item.moduleId,
          )
          .toList(growable: false);

      expect(modules, <String>['SYSTEM_HEALTH', 'FOOD', 'RESTAURANT']);
    });

    test(
      'finance/support/safety reads are planned explicitly even if adapters are not connected yet',
      () {
        final AgentVoiceSuperAdminQueryPlan plan = planner.plan(
          request: const AgentVoiceSuperAdminQueryPlanningRequest(
            queryText: 'finance payment wallet complaint support safety sos',
          ),
          now: DateTime.utc(2026, 8, 18, 6),
        );

        expect(plan.isPlanned, isTrue);

        final Set<String> modules = plan.reportRequest!.sourceRequests
            .map(
              (AgentVoiceSuperAdminSourceAcquisitionRequest item) =>
                  item.moduleId,
            )
            .toSet();

        expect(modules, contains('FINANCE_OWNER_READ'));
        expect(modules, contains('COMPLAINTS_SUPPORT_READ'));
        expect(modules, contains('SAFETY_SOS_OWNER_READ'));
      },
    );

    test('consequential command is rejected by read-only planner', () {
      final AgentVoiceSuperAdminQueryPlan plan = planner.plan(
        request: const AgentVoiceSuperAdminQueryPlanningRequest(
          queryText: 'suspend this driver and refund payment',
          referenceIds: <String, String>{
            AgentVoiceSuperAdminQueryReferenceKey.driverId: 'driver-1',
          },
        ),
        now: DateTime.utc(2026, 8, 18, 6),
      );

      expect(plan.isUnsupported, isTrue);
      expect(plan.code, 'READ_ONLY_PLANNER_REJECTED_CONSEQUENTIAL_REQUEST');
      expect(plan.reportRequest, isNull);
    });

    test('unknown query fails closed rather than inventing a module', () {
      final AgentVoiceSuperAdminQueryPlan plan = planner.plan(
        request: const AgentVoiceSuperAdminQueryPlanningRequest(
          queryText: 'tell me something random',
        ),
        now: DateTime.utc(2026, 8, 18, 6),
      );

      expect(plan.isUnsupported, isTrue);
      expect(plan.code, 'QUERY_INTENT_NOT_CONNECTED');
      expect(plan.reportRequest, isNull);
    });

    test('planner has no authority/provider/speech/write capability', () {
      expect(planner.deterministicOnly, isTrue);
      expect(planner.parsesIdentityFromVoice, isFalse);
      expect(planner.parsesReferenceIdsFromVoice, isFalse);
      expect(planner.hiddenBroadQueryAllowed, isFalse);
      expect(planner.executesConnector, isFalse);
      expect(planner.grantsPermission, isFalse);
      expect(planner.createsApproval, isFalse);
      expect(planner.consumesApproval, isFalse);
      expect(planner.writesBusinessData, isFalse);
      expect(planner.mutatesSafety, isFalse);
      expect(planner.callsProvider, isFalse);
      expect(planner.usesSpeechToTextProvider, isFalse);
      expect(planner.usesTextToSpeechProvider, isFalse);
      expect(planner.deploys, isFalse);
    });
  });
}
