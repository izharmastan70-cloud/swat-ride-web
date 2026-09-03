import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_foundation.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_module_capability.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_response.dart';
import 'package:swat_ride/ai_agent/services/agent_voice_super_admin_output_policy.dart';

void main() {
  const foundation = AgentVoiceSuperAdminFoundation();
  const outputPolicy = AgentVoiceSuperAdminOutputPolicy();

  group('Phase 48 Step 1B foundation', () {
    test('whole ecosystem read report explain scope is locked', () {
      expect(foundation.coversWholeSwatRideEcosystem, isTrue);
      expect(
        AgentVoiceSuperAdminFoundation.initialScope,
        containsAll(<String>[
          AgentVoiceSuperAdminScope.read,
          AgentVoiceSuperAdminScope.report,
          AgentVoiceSuperAdminScope.explain,
        ]),
      );
      expect(AgentVoiceSuperAdminFoundation.initialScope.length, 3);
    });

    test('text output is mandatory and voice playback defaults OFF', () {
      expect(foundation.readableTextOutputMandatory, isTrue);
      expect(foundation.voicePlaybackOptional, isTrue);
      expect(foundation.voicePlaybackDefaultEnabled, isFalse);
      expect(foundation.textOutputIsSourceOfTruthForPlayback, isTrue);
    });

    test('voice itself grants no authority', () {
      expect(foundation.voiceInputGrantsAuthority, isFalse);
      expect(foundation.voiceIdentityAloneIsOwnerAuthority, isFalse);
      expect(foundation.speechTransportIsAuthorityLayer, isFalse);
    });

    test('all consequential writes remain forbidden', () {
      expect(foundation.maySuspendUserOrDriver, isFalse);
      expect(foundation.mayApproveOrRejectApplication, isFalse);
      expect(foundation.mayRefund, isFalse);
      expect(foundation.mayExecutePayout, isFalse);
      expect(foundation.mayMutateWalletOrPayment, isFalse);
      expect(foundation.mayChangePricingOrCommission, isFalse);
      expect(foundation.mayChangeServiceControl, isFalse);
      expect(foundation.mayChangePermissionOrSecurity, isFalse);
      expect(foundation.mayConsumeApproval, isFalse);
      expect(foundation.maySelfApprove, isFalse);
      expect(foundation.mayMutateSafetyOrEmergency, isFalse);
      expect(foundation.mayDeploy, isFalse);
    });

    test('raw audio is default-deny for storage and training', () {
      expect(foundation.mayStoreRawAudioByDefault, isFalse);
      expect(foundation.mayTrainOnRawAudioByDefault, isFalse);
    });
  });

  group('Phase 48 Step 1B capability matrix', () {
    test('existing read-only connectors are marked verified available', () {
      for (final String module in <String>[
        AgentVoiceSuperAdminModule.normalRide,
        AgentVoiceSuperAdminModule.driver,
        AgentVoiceSuperAdminModule.food,
        AgentVoiceSuperAdminModule.restaurant,
        AgentVoiceSuperAdminModule.hotel,
        AgentVoiceSuperAdminModule.tour,
        AgentVoiceSuperAdminModule.systemHealth,
      ]) {
        final capability = AgentVoiceSuperAdminInitialCapabilityMatrix.byModule(
          module,
        );
        capability.validate();
        expect(capability.isVerifiedAvailable, isTrue, reason: module);
      }
    });

    test('Cargo and Student remain NOT_CONNECTED because they are stubs', () {
      expect(
        AgentVoiceSuperAdminInitialCapabilityMatrix.byModule(
          AgentVoiceSuperAdminModule.cargo,
        ).status,
        AgentVoiceSuperAdminCapabilityStatus.notConnected,
      );

      expect(
        AgentVoiceSuperAdminInitialCapabilityMatrix.byModule(
          AgentVoiceSuperAdminModule.studentRide,
        ).status,
        AgentVoiceSuperAdminCapabilityStatus.notConnected,
      );
    });

    test('Safety does not inherit Phase 47 authority automatically', () {
      final capability = AgentVoiceSuperAdminInitialCapabilityMatrix.byModule(
        AgentVoiceSuperAdminModule.safetySos,
      );

      expect(
        capability.status,
        AgentVoiceSuperAdminCapabilityStatus.notConnected,
      );
      expect(capability.note.toLowerCase(), contains('must not inherit'));
    });

    test('unknown module fails to UNAVAILABLE rather than fake data', () {
      final capability = AgentVoiceSuperAdminInitialCapabilityMatrix.byModule(
        'UNKNOWN_MODULE',
      );

      expect(
        capability.status,
        AgentVoiceSuperAdminCapabilityStatus.unavailable,
      );
      expect(capability.mustSurfaceUnavailable, isTrue);
    });
  });

  group('Phase 48 Step 1B text-first output', () {
    test('voice OFF still returns mandatory readable text', () {
      final response = outputPolicy.build(
        verifiedTextReport: 'Ride: healthy. Food: 12 active orders.',
        preference: const AgentVoiceSuperAdminOutputPreference(),
        verifiedSourceIds: const <String>['ride', 'food'],
        unavailableModuleIds: const <String>['cargo'],
        now: DateTime.utc(2026, 8, 18, 4),
      );

      expect(response.textOutput, isNotEmpty);
      expect(response.readableTextOutputMandatory, isTrue);
      expect(response.voicePlaybackEnabled, isFalse);
      expect(response.voicePlaybackText, isNull);
      expect(response.mayPlayVoice, isFalse);
      expect(response.historyReady, isTrue);
      expect(response.persistentHistoryWritten, isFalse);
    });

    test('voice ON uses the same verified text as playback source', () {
      const String verified = 'Verified SWAT RIDE summary.';

      final response = outputPolicy.build(
        verifiedTextReport: verified,
        preference: const AgentVoiceSuperAdminOutputPreference(
          voicePlaybackEnabled: true,
        ),
        verifiedSourceIds: const <String>['core'],
        unavailableModuleIds: const <String>[],
        now: DateTime.utc(2026, 8, 18, 4),
      );

      expect(response.textOutput, verified);
      expect(response.voicePlaybackText, verified);
      expect(response.mayPlayVoice, isTrue);
    });

    test('empty verified text fails closed before voice output', () {
      expect(
        () => outputPolicy.build(
          verifiedTextReport: '   ',
          preference: const AgentVoiceSuperAdminOutputPreference(
            voicePlaybackEnabled: true,
          ),
          verifiedSourceIds: const <String>[],
          unavailableModuleIds: const <String>[],
          now: DateTime.utc(2026, 8, 18, 4),
        ),
        throwsA(isA<AgentVoiceSuperAdminResponseException>()),
      );
    });

    test('response layer cannot grant authority or execute writes', () {
      final response = outputPolicy.build(
        verifiedTextReport: 'Verified status only.',
        preference: const AgentVoiceSuperAdminOutputPreference(),
        verifiedSourceIds: const <String>['core'],
        unavailableModuleIds: const <String>[],
        now: DateTime.utc(2026, 8, 18, 4),
      );

      expect(response.mayGrantPermission, isFalse);
      expect(response.mayConsumeApproval, isFalse);
      expect(response.mayWriteBusinessData, isFalse);
      expect(response.mayMutateSafety, isFalse);
      expect(response.mayCallProvider, isFalse);
      expect(response.mayDeploy, isFalse);
      expect(response.rawAudioStored, isFalse);
      expect(response.rawAudioUsedForTraining, isFalse);
      expect(outputPolicy.mayUseSpeechToTextProvider, isFalse);
      expect(outputPolicy.mayUseTextToSpeechProvider, isFalse);
    });
  });
}
