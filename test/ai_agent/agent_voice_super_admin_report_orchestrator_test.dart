import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_authorization.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_foundation.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_report_orchestration_request.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_response.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_source_acquisition_request.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_verified_section.dart';
import 'package:swat_ride/ai_agent/services/agent_voice_super_admin_report_orchestrator.dart';

class _FakeGateway implements AgentVoiceSuperAdminSourceAcquisitionGateway {
  _FakeGateway(this.sectionsByModule);

  final Map<String, AgentVoiceSuperAdminVerifiedSection> sectionsByModule;

  int calls = 0;
  final List<String> requestedModules = <String>[];

  @override
  Future<AgentVoiceSuperAdminVerifiedSection> acquire({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentVoiceSuperAdminSessionBinding session,
    required AgentVoiceSuperAdminAuthorizationRequest authorizationRequest,
    required AgentVoiceSuperAdminSourceAcquisitionRequest sourceRequest,
    required DateTime now,
  }) async {
    calls += 1;
    requestedModules.add(sourceRequest.moduleId);

    return sectionsByModule[sourceRequest.moduleId] ??
        AgentVoiceSuperAdminVerifiedSection.unavailable(
          moduleId: sourceRequest.moduleId,
          sourceId: 'fake.gateway',
          reason: 'No fake verified source configured.',
          verifiedAt: now,
        );
  }
}

AgentRole _voiceRole() => buildInitialAgentRoles().firstWhere(
  (AgentRole role) => role.roleId == AgentVoiceSuperAdminFoundation.roleId,
);

AgentMasterSettings _settings() => AgentMasterSettings.safeDefaults().copyWith(
  masterEnabled: true,
  freeAiEnabled: true,
  voiceSuperAdminAgentEnabled: true,
);

AgentVoiceSuperAdminSessionBinding _session() =>
    AgentVoiceSuperAdminSessionBinding(
      principalType: AgentVoiceSuperAdminPrincipalType.superAdmin,
      principalUid: 'owner-1',
      deviceBindingId: 'device-1',
      sessionId: 'session-1',
      verificationLevel: AgentVoiceSuperAdminVerificationLevel.linkedAccount,
      verifiedAt: DateTime.utc(2026, 8, 18, 5),
      expiresAt: DateTime.utc(2026, 8, 18, 8),
    );

AgentVoiceSuperAdminAuthorizationRequest _authorizationRequest() =>
    const AgentVoiceSuperAdminAuthorizationRequest(
      actionId: AgentActionId.readVoiceSuperAdminVerifiedReport,
      actorId: 'owner-1',
      expectedDeviceBindingId: 'device-1',
      expectedSessionId: 'session-1',
    );

AgentVoiceSuperAdminVerifiedSection _verified({
  required String module,
  required String source,
  required Map<String, Object?> facts,
}) {
  return AgentVoiceSuperAdminVerifiedSection.verified(
    moduleId: module,
    sourceId: source,
    summaryText: 'upstream generic summary',
    facts: facts,
    verifiedAt: DateTime.utc(2026, 8, 18, 5, 30),
  );
}

AgentVoiceSuperAdminVerifiedSection _unavailable(String module) {
  return AgentVoiceSuperAdminVerifiedSection.unavailable(
    moduleId: module,
    sourceId: 'fake.$module',
    reason: 'Current verified source is not connected.',
    verifiedAt: DateTime.utc(2026, 8, 18, 5, 30),
  );
}

void main() {
  group('Phase 48 Step 2E-B report orchestration', () {
    test(
      'multi-source verified report creates mandatory readable text',
      () async {
        final gateway = _FakeGateway(
          <String, AgentVoiceSuperAdminVerifiedSection>{
            'NORMAL_RIDE': _verified(
              module: 'NORMAL_RIDE',
              source: 'connector.ride.read_only',
              facts: const <String, Object?>{
                'status': 'driver_assigned',
                'estimatedFare': 850,
              },
            ),
            'DRIVER': _verified(
              module: 'DRIVER',
              source: 'connector.driver.read_only',
              facts: const <String, Object?>{
                'status': 'approved',
                'isOnline': true,
              },
            ),
          },
        );

        final orchestrator = AgentVoiceSuperAdminReportOrchestrator(
          sourceGateway: gateway,
        );

        final result = await orchestrator.build(
          settings: _settings(),
          role: _voiceRole(),
          session: _session(),
          authorizationRequest: _authorizationRequest(),
          request: const AgentVoiceSuperAdminReportOrchestrationRequest(
            reportId: 'report-1',
            sourceRequests: <AgentVoiceSuperAdminSourceAcquisitionRequest>[
              AgentVoiceSuperAdminSourceAcquisitionRequest(
                moduleId: 'NORMAL_RIDE',
                readKind: AgentVoiceSuperAdminSourceReadKind.status,
                referenceId: 'ride-1',
              ),
              AgentVoiceSuperAdminSourceAcquisitionRequest(
                moduleId: 'DRIVER',
                readKind: AgentVoiceSuperAdminSourceReadKind.status,
                referenceId: 'driver-1',
              ),
            ],
          ),
          now: DateTime.utc(2026, 8, 18, 5, 40),
        );

        expect(gateway.calls, 2);
        expect(result.verifiedReport.status, 'READY');
        expect(result.response.textOutput, contains('NORMAL_RIDE: VERIFIED'));
        expect(result.response.textOutput, contains('status: driver_assigned'));
        expect(result.response.textOutput, contains('estimatedFare: 850'));
        expect(result.response.textOutput, contains('DRIVER: VERIFIED'));
        expect(result.response.voicePlaybackEnabled, isFalse);
        expect(result.response.voicePlaybackText, isNull);
        expect(result.response.verifiedSourceIds, <String>[
          'connector.ride.read_only',
          'connector.driver.read_only',
        ]);
        expect(result.response.unavailableModuleIds, isEmpty);
      },
    );

    test('mixed verified/unavailable report is PARTIAL and explicit', () async {
      final gateway = _FakeGateway(
        <String, AgentVoiceSuperAdminVerifiedSection>{
          'SYSTEM_HEALTH': _verified(
            module: 'SYSTEM_HEALTH',
            source: 'connector.ai_core.read_only',
            facts: const <String, Object?>{
              'aiMasterEnabled': true,
              'rolesOperational': 12,
            },
          ),
          'HOTEL': _unavailable('HOTEL'),
          'CARGO': _unavailable('CARGO'),
        },
      );

      final result =
          await AgentVoiceSuperAdminReportOrchestrator(
            sourceGateway: gateway,
          ).build(
            settings: _settings(),
            role: _voiceRole(),
            session: _session(),
            authorizationRequest: _authorizationRequest(),
            request: const AgentVoiceSuperAdminReportOrchestrationRequest(
              reportId: 'report-partial',
              sourceRequests: <AgentVoiceSuperAdminSourceAcquisitionRequest>[
                AgentVoiceSuperAdminSourceAcquisitionRequest(
                  moduleId: 'SYSTEM_HEALTH',
                  readKind: AgentVoiceSuperAdminSourceReadKind.status,
                ),
                AgentVoiceSuperAdminSourceAcquisitionRequest(
                  moduleId: 'HOTEL',
                  readKind: AgentVoiceSuperAdminSourceReadKind.status,
                  referenceId: 'hotel-1',
                ),
                AgentVoiceSuperAdminSourceAcquisitionRequest(
                  moduleId: 'CARGO',
                  readKind: AgentVoiceSuperAdminSourceReadKind.status,
                  referenceId: 'cargo-1',
                ),
              ],
            ),
            now: DateTime.utc(2026, 8, 18, 5, 40),
          );

      expect(result.verifiedReport.status, 'PARTIAL');
      expect(result.response.textOutput, contains('HOTEL: UNAVAILABLE'));
      expect(result.response.textOutput, contains('CARGO: UNAVAILABLE'));
      expect(result.response.unavailableModuleIds, <String>['HOTEL', 'CARGO']);
      expect(result.response.textOutput, isNot(contains('HOTEL: 0')));
      expect(result.response.textOutput, isNot(contains('CARGO: 0')));
    });

    test(
      'all unavailable sources produce UNAVAILABLE report without guesses',
      () async {
        final gateway =
            _FakeGateway(<String, AgentVoiceSuperAdminVerifiedSection>{
              'HOTEL': _unavailable('HOTEL'),
              'TOUR': _unavailable('TOUR'),
              'STUDENT_RIDE': _unavailable('STUDENT_RIDE'),
            });

        final result =
            await AgentVoiceSuperAdminReportOrchestrator(
              sourceGateway: gateway,
            ).build(
              settings: _settings(),
              role: _voiceRole(),
              session: _session(),
              authorizationRequest: _authorizationRequest(),
              request: const AgentVoiceSuperAdminReportOrchestrationRequest(
                reportId: 'report-unavailable',
                sourceRequests: <AgentVoiceSuperAdminSourceAcquisitionRequest>[
                  AgentVoiceSuperAdminSourceAcquisitionRequest(
                    moduleId: 'HOTEL',
                    readKind: AgentVoiceSuperAdminSourceReadKind.status,
                    referenceId: 'hotel-1',
                  ),
                  AgentVoiceSuperAdminSourceAcquisitionRequest(
                    moduleId: 'TOUR',
                    readKind: AgentVoiceSuperAdminSourceReadKind.status,
                    referenceId: 'tour-1',
                  ),
                  AgentVoiceSuperAdminSourceAcquisitionRequest(
                    moduleId: 'STUDENT_RIDE',
                    readKind: AgentVoiceSuperAdminSourceReadKind.status,
                    referenceId: 'student-1',
                  ),
                ],
              ),
              now: DateTime.utc(2026, 8, 18, 5, 40),
            );

        expect(result.verifiedReport.status, 'UNAVAILABLE');
        expect(result.response.verifiedSourceIds, isEmpty);
        expect(result.response.unavailableModuleIds, <String>[
          'HOTEL',
          'TOUR',
          'STUDENT_RIDE',
        ]);
        expect(result.response.textOutput, isNot(contains('0 bookings')));
        expect(result.response.textOutput, isNot(contains('0 rides')));
      },
    );

    test(
      'duplicate module request fails before source gateway is touched',
      () async {
        final gateway = _FakeGateway(
          <String, AgentVoiceSuperAdminVerifiedSection>{},
        );
        final orchestrator = AgentVoiceSuperAdminReportOrchestrator(
          sourceGateway: gateway,
        );

        expect(
          () => orchestrator.build(
            settings: _settings(),
            role: _voiceRole(),
            session: _session(),
            authorizationRequest: _authorizationRequest(),
            request: const AgentVoiceSuperAdminReportOrchestrationRequest(
              reportId: 'duplicate',
              sourceRequests: <AgentVoiceSuperAdminSourceAcquisitionRequest>[
                AgentVoiceSuperAdminSourceAcquisitionRequest(
                  moduleId: 'FOOD',
                  readKind: AgentVoiceSuperAdminSourceReadKind.status,
                  referenceId: 'order-1',
                ),
                AgentVoiceSuperAdminSourceAcquisitionRequest(
                  moduleId: 'food',
                  readKind: AgentVoiceSuperAdminSourceReadKind.details,
                  referenceId: 'order-2',
                ),
              ],
            ),
            now: DateTime.utc(2026, 8, 18, 5, 40),
          ),
          throwsA(
            isA<AgentVoiceSuperAdminReportOrchestrationRequestException>(),
          ),
        );

        await Future<void>.delayed(Duration.zero);
        expect(gateway.calls, 0);
      },
    );

    test('voice playback ON uses exact same verified text', () async {
      final gateway = _FakeGateway(
        <String, AgentVoiceSuperAdminVerifiedSection>{
          'RESTAURANT': _verified(
            module: 'RESTAURANT',
            source: 'connector.restaurant.read_only',
            facts: const <String, Object?>{
              'name': 'Demo Restaurant',
              'isOpen': true,
            },
          ),
        },
      );

      final result =
          await AgentVoiceSuperAdminReportOrchestrator(
            sourceGateway: gateway,
          ).build(
            settings: _settings(),
            role: _voiceRole(),
            session: _session(),
            authorizationRequest: _authorizationRequest(),
            request: const AgentVoiceSuperAdminReportOrchestrationRequest(
              reportId: 'voice-on',
              outputPreference: AgentVoiceSuperAdminOutputPreference(
                voicePlaybackEnabled: true,
              ),
              sourceRequests: <AgentVoiceSuperAdminSourceAcquisitionRequest>[
                AgentVoiceSuperAdminSourceAcquisitionRequest(
                  moduleId: 'RESTAURANT',
                  readKind: AgentVoiceSuperAdminSourceReadKind.status,
                  referenceId: 'restaurant-1',
                ),
              ],
            ),
            now: DateTime.utc(2026, 8, 18, 5, 40),
          );

      expect(result.response.voicePlaybackEnabled, isTrue);
      expect(result.response.voicePlaybackText, result.response.textOutput);
      expect(result.response.textOutput, result.verifiedReport.readableText);
    });

    test(
      'unsupported aggregate module stays unavailable instead of inferred total',
      () async {
        final gateway =
            _FakeGateway(<String, AgentVoiceSuperAdminVerifiedSection>{
              'WHOLE_ECOSYSTEM_TOTALS':
                  AgentVoiceSuperAdminVerifiedSection.unavailable(
                    moduleId: 'WHOLE_ECOSYSTEM_TOTALS',
                    sourceId: 'voice_super_admin.readiness',
                    reason: 'No verified aggregate source is connected.',
                    verifiedAt: DateTime.utc(2026, 8, 18, 5, 30),
                  ),
            });

        final result =
            await AgentVoiceSuperAdminReportOrchestrator(
              sourceGateway: gateway,
            ).build(
              settings: _settings(),
              role: _voiceRole(),
              session: _session(),
              authorizationRequest: _authorizationRequest(),
              request: const AgentVoiceSuperAdminReportOrchestrationRequest(
                reportId: 'aggregate-unavailable',
                sourceRequests: <AgentVoiceSuperAdminSourceAcquisitionRequest>[
                  AgentVoiceSuperAdminSourceAcquisitionRequest(
                    moduleId: 'WHOLE_ECOSYSTEM_TOTALS',
                    readKind: AgentVoiceSuperAdminSourceReadKind.status,
                  ),
                ],
              ),
              now: DateTime.utc(2026, 8, 18, 5, 40),
            );

        expect(
          result.response.textOutput,
          contains('WHOLE_ECOSYSTEM_TOTALS: UNAVAILABLE'),
        );
        expect(result.response.textOutput, isNot(contains('total: 0')));
        expect(result.response.textOutput, isNot(contains('rides: 0')));
      },
    );

    test('orchestrator exposes no authority or persistence capability', () {
      final orchestrator = AgentVoiceSuperAdminReportOrchestrator(
        sourceGateway: _FakeGateway(
          <String, AgentVoiceSuperAdminVerifiedSection>{},
        ),
      );

      expect(orchestrator.usesStep2DAuthorizedAcquisition, isTrue);
      expect(orchestrator.usesExistingVerifiedComposition, isTrue);
      expect(orchestrator.usesExistingOutputPolicy, isTrue);
      expect(orchestrator.inventsAggregateTotals, isFalse);
      expect(orchestrator.hiddenBroadQueryAllowed, isFalse);
      expect(orchestrator.persistentHistoryWritten, isFalse);

      expect(orchestrator.grantsPermission, isFalse);
      expect(orchestrator.createsApproval, isFalse);
      expect(orchestrator.consumesApproval, isFalse);
      expect(orchestrator.writesBusinessData, isFalse);
      expect(orchestrator.mutatesSafety, isFalse);
      expect(orchestrator.callsProvider, isFalse);
      expect(orchestrator.usesSpeechToText, isFalse);
      expect(orchestrator.usesTextToSpeechProvider, isFalse);
      expect(orchestrator.deploys, isFalse);
    });
  });
}
