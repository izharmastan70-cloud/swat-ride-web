import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_source_readiness.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_verified_report.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_verified_section.dart';
import 'package:swat_ride/ai_agent/services/agent_voice_super_admin_verified_composition.dart';

void main() {
  const composition = AgentVoiceSuperAdminVerifiedComposition();

  group('Phase 48 Step 2B source readiness', () {
    test('active generic read-only registry modules are registry-ready', () {
      for (final String module in <String>[
        'NORMAL_RIDE',
        'DRIVER',
        'FOOD',
        'RESTAURANT',
        'SYSTEM_HEALTH',
      ]) {
        final readiness = AgentVoiceSuperAdminInitialSourceReadiness.forModule(
          module,
        );
        readiness.validate();
        expect(
          readiness.status,
          AgentVoiceSuperAdminSourceReadinessStatus.registryReady,
          reason: module,
        );
        expect(readiness.mayExecuteThroughExistingReadPath, isTrue);
      }
    });

    test('Hotel and Tour are not treated as live while registry is off', () {
      for (final String module in <String>['HOTEL', 'TOUR']) {
        final readiness = AgentVoiceSuperAdminInitialSourceReadiness.forModule(
          module,
        );

        expect(
          readiness.status,
          AgentVoiceSuperAdminSourceReadinessStatus
              .connectorExistsButRegistryNotConnected,
          reason: module,
        );
        expect(readiness.mayExecuteThroughExistingReadPath, isFalse);
        expect(readiness.mustSurfaceUnavailable, isTrue);
      }
    });

    test('Cargo and Student remain not connected', () {
      for (final String module in <String>['CARGO', 'STUDENT_RIDE']) {
        expect(
          AgentVoiceSuperAdminInitialSourceReadiness.forModule(module).status,
          AgentVoiceSuperAdminSourceReadinessStatus.notConnected,
        );
      }
    });

    test('unknown module is fail-closed not connected', () {
      final readiness = AgentVoiceSuperAdminInitialSourceReadiness.forModule(
        'UNKNOWN',
      );

      expect(
        readiness.status,
        AgentVoiceSuperAdminSourceReadinessStatus.notConnected,
      );
      expect(readiness.mustSurfaceUnavailable, isTrue);
    });
  });

  group('Phase 48 Step 2B verified section contract', () {
    test('verified section carries structured sanitized facts only', () {
      final section = AgentVoiceSuperAdminVerifiedSection.verified(
        moduleId: 'NORMAL_RIDE',
        sourceId: 'ride.read_only',
        summaryText: '12 rides are active.',
        facts: const <String, Object?>{'activeRideCount': 12},
        verifiedAt: DateTime.utc(2026, 8, 18, 4, 40),
      );

      section.validate();
      expect(section.isVerified, isTrue);
      expect(section.grantsAuthority, isFalse);
      expect(section.mayExecuteConnector, isFalse);
      expect(section.mayGrantPermission, isFalse);
      expect(section.mayConsumeApproval, isFalse);
      expect(section.mayWriteBusinessData, isFalse);
      expect(section.mayMutateSafety, isFalse);
      expect(section.mayCallProvider, isFalse);
      expect(section.mayDeploy, isFalse);
    });

    test('unavailable section never invents fallback facts', () {
      final section = AgentVoiceSuperAdminVerifiedSection.unavailable(
        moduleId: 'HOTEL',
        sourceId: 'hotel.registry_off',
        reason: 'Verified connector is not active in the central registry.',
        verifiedAt: DateTime.utc(2026, 8, 18, 4, 40),
      );

      section.validate();
      expect(section.isUnavailable, isTrue);
      expect(section.summaryText, 'UNAVAILABLE');
      expect(section.facts, isEmpty);
    });
  });

  group('Phase 48 Step 2B composition', () {
    test('all verified sections produce READY mandatory text report', () {
      final report = composition.compose(
        reportId: 'owner-today',
        requestedSections: <AgentVoiceSuperAdminVerifiedSection>[
          AgentVoiceSuperAdminVerifiedSection.verified(
            moduleId: 'NORMAL_RIDE',
            sourceId: 'ride.read_only',
            summaryText: '12 active rides.',
            facts: const <String, Object?>{'activeRideCount': 12},
            verifiedAt: DateTime.utc(2026, 8, 18, 4, 40),
          ),
          AgentVoiceSuperAdminVerifiedSection.verified(
            moduleId: 'FOOD',
            sourceId: 'food.read_only',
            summaryText: '8 active orders.',
            facts: const <String, Object?>{'activeOrderCount': 8},
            verifiedAt: DateTime.utc(2026, 8, 18, 4, 40),
          ),
        ],
        now: DateTime.utc(2026, 8, 18, 4, 40),
      );

      expect(report.status, AgentVoiceSuperAdminReportStatus.ready);
      expect(report.readableTextMandatory, isTrue);
      expect(report.readableText, contains('NORMAL_RIDE: 12 active rides.'));
      expect(report.readableText, contains('FOOD: 8 active orders.'));
      expect(report.voicePlaybackMustDeriveFromReadableText, isTrue);
    });

    test('mixed verified/unavailable sections produce PARTIAL report', () {
      final report = composition.compose(
        reportId: 'owner-today',
        requestedSections: <AgentVoiceSuperAdminVerifiedSection>[
          AgentVoiceSuperAdminVerifiedSection.verified(
            moduleId: 'NORMAL_RIDE',
            sourceId: 'ride.read_only',
            summaryText: '12 active rides.',
            facts: const <String, Object?>{'activeRideCount': 12},
            verifiedAt: DateTime.utc(2026, 8, 18, 4, 40),
          ),
          AgentVoiceSuperAdminVerifiedSection.unavailable(
            moduleId: 'HOTEL',
            sourceId: 'hotel.registry_off',
            reason: 'Verified source is not active.',
            verifiedAt: DateTime.utc(2026, 8, 18, 4, 40),
          ),
        ],
        now: DateTime.utc(2026, 8, 18, 4, 40),
      );

      expect(report.status, AgentVoiceSuperAdminReportStatus.partial);
      expect(report.readableText, contains('HOTEL: UNAVAILABLE'));
      expect(report.readableText, isNot(contains('0 bookings')));
    });

    test('all unavailable sections produce UNAVAILABLE report', () {
      final report = composition.compose(
        reportId: 'owner-today',
        requestedSections: <AgentVoiceSuperAdminVerifiedSection>[
          AgentVoiceSuperAdminVerifiedSection.unavailable(
            moduleId: 'CARGO',
            sourceId: 'cargo.stub',
            reason: 'Connector is not connected.',
            verifiedAt: DateTime.utc(2026, 8, 18, 4, 40),
          ),
        ],
        now: DateTime.utc(2026, 8, 18, 4, 40),
      );

      expect(report.status, AgentVoiceSuperAdminReportStatus.unavailable);
      expect(report.readableText, contains('CARGO: UNAVAILABLE'));
    });

    test('duplicate module section fails closed', () {
      final section = AgentVoiceSuperAdminVerifiedSection.verified(
        moduleId: 'DRIVER',
        sourceId: 'driver.read_only',
        summaryText: 'Verified driver status.',
        facts: const <String, Object?>{},
        verifiedAt: DateTime.utc(2026, 8, 18, 4, 40),
      );

      expect(
        () => composition.compose(
          reportId: 'duplicate',
          requestedSections: <AgentVoiceSuperAdminVerifiedSection>[
            section,
            section,
          ],
          now: DateTime.utc(2026, 8, 18, 4, 40),
        ),
        throwsA(isA<AgentVoiceSuperAdminVerifiedReportException>()),
      );
    });

    test('composition layer has zero authority/execution capability', () {
      expect(composition.executesConnectors, isFalse);
      expect(composition.authenticatesOwner, isFalse);
      expect(composition.grantsPermission, isFalse);
      expect(composition.evaluatesRuntimeGate, isFalse);
      expect(composition.recordsAudit, isFalse);
      expect(composition.createsApproval, isFalse);
      expect(composition.consumesApproval, isFalse);
      expect(composition.writesBusinessData, isFalse);
      expect(composition.mutatesSafety, isFalse);
      expect(composition.callsProvider, isFalse);
      expect(composition.usesSpeechToText, isFalse);
      expect(composition.usesTextToSpeech, isFalse);
      expect(composition.deploys, isFalse);
    });
  });
}
