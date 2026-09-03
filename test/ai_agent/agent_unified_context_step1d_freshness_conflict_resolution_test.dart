import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_omnichannel_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_unified_context_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_unified_context_assembly_bundle.dart';
import 'package:swat_ride/ai_agent/models/agent_unified_context_assembly_request.dart';
import 'package:swat_ride/ai_agent/models/agent_unified_context_conflict_resolution_result.dart';
import 'package:swat_ride/ai_agent/models/agent_unified_context_item.dart';
import 'package:swat_ride/ai_agent/services/agent_unified_context_assembly_service.dart';
import 'package:swat_ride/ai_agent/services/agent_unified_context_conflict_resolution_service.dart';

void main() {
  const AgentUnifiedContextAssemblyService assemblyService =
      AgentUnifiedContextAssemblyService();

  const AgentUnifiedContextConflictResolutionService resolutionService =
      AgentUnifiedContextConflictResolutionService();

  AgentUnifiedContextAssemblyRequest request({
    String requestId = 'assembly_001',
    String subjectRef = 'subject_hash_001',
    String roleId = 'support_agent',
    String channel = AgentOmnichannelChannel.appChat,
    String purpose = AgentUnifiedContextPurpose.statusRead,
  }) {
    return AgentUnifiedContextAssemblyRequest(
      requestId: requestId,
      requestingSubjectRef: subjectRef,
      requestingRoleId: roleId,
      requestingChannel: channel,
      requestedPurpose: purpose,
      requestedAt: DateTime.utc(2026, 8, 19, 9),
      maxItems: 8,
      maxSanitizedCharacters: 2400,
    );
  }

  AgentUnifiedContextItem item({
    required String contextId,
    required String value,
    String subjectRef = 'subject_hash_001',
    String sourceChannel = AgentOmnichannelChannel.appChat,
    String sourceType = AgentUnifiedContextSourceType.domainServiceRead,
    String sourceTrust = AgentUnifiedContextSourceTrust.verifiedSystem,
    String purpose = AgentUnifiedContextPurpose.statusRead,
    String dataKind = AgentUnifiedContextDataKind.statusFact,
    DateTime? capturedAt,
    DateTime? expiresAt,
    bool identityBound = true,
    bool generatedByAgent = false,
  }) {
    return AgentUnifiedContextItem(
      contextId: contextId,
      subjectRef: subjectRef,
      sourceChannel: sourceChannel,
      sourceType: sourceType,
      sourceTrust: sourceTrust,
      sensitivity: AgentUnifiedContextSensitivity.personalData,
      purpose: purpose,
      dataKind: dataKind,
      sanitizedValue: value,
      capturedAt: capturedAt ?? DateTime.utc(2026, 8, 19, 8),
      expiresAt: expiresAt ?? DateTime.utc(2026, 8, 19, 11),
      identityBound: identityBound,
      containsRawSecret: false,
      containsPaymentCredential: false,
      containsAuthToken: false,
      containsRawMessageHistory: false,
      containsOwnerAdminPrivateData: false,
      generatedByAgent: generatedByAgent,
    );
  }

  AgentUnifiedContextAssemblyBundle assemble(
    List<AgentUnifiedContextItem> items,
  ) {
    return assemblyService.assemble(request: request(), candidates: items);
  }

  group('Phase 52 Step 1D freshness and conflict resolution', () {
    test('single fresh fact passes without conflict', () {
      final AgentUnifiedContextAssemblyBundle bundle = assemble(
        <AgentUnifiedContextItem>[item(contextId: 'ctx_1', value: 'assigned')],
      );

      final result = resolutionService.resolve(
        sourceBundle: bundle,
        conflictKeyByContextId: const <String, String>{
          'ctx_1': 'ride.current_status',
        },
        now: DateTime.utc(2026, 8, 19, 9),
      );

      expect(result.ready, isTrue);
      expect(result.selectedItems.single.contextId, 'ctx_1');
      expect(
        result.resolutionReasonByConflictKey['ride.current_status'],
        AgentUnifiedContextConflictResolutionReason.noConflict,
      );
    });

    test('verified system beats newer user-asserted conflict', () {
      final bundle = assemble(<AgentUnifiedContextItem>[
        item(
          contextId: 'ctx_system',
          value: 'assigned',
          capturedAt: DateTime.utc(2026, 8, 19, 8),
        ),
        item(
          contextId: 'ctx_user',
          value: 'cancelled',
          sourceType: AgentUnifiedContextSourceType.userStatement,
          sourceTrust: AgentUnifiedContextSourceTrust.userAsserted,
          capturedAt: DateTime.utc(2026, 8, 19, 8, 50),
        ),
      ]);

      final result = resolutionService.resolve(
        sourceBundle: bundle,
        conflictKeyByContextId: const <String, String>{
          'ctx_system': 'ride.current_status',
          'ctx_user': 'ride.current_status',
        },
        now: DateTime.utc(2026, 8, 19, 9),
      );

      expect(result.selectedItems.single.contextId, 'ctx_system');
      expect(
        result.resolutionReasonByConflictKey['ride.current_status'],
        AgentUnifiedContextConflictResolutionReason.trustPrecedence,
      );
    });

    test('verified identity-bound beats user assertion', () {
      final bundle = assemble(<AgentUnifiedContextItem>[
        item(
          contextId: 'ctx_identity',
          value: 'identity_verified',
          sourceType: AgentUnifiedContextSourceType.verifiedChannelIdentity,
          sourceTrust: AgentUnifiedContextSourceTrust.verifiedIdentityBound,
        ),
        item(
          contextId: 'ctx_user',
          value: 'identity_unverified',
          sourceType: AgentUnifiedContextSourceType.userStatement,
          sourceTrust: AgentUnifiedContextSourceTrust.userAsserted,
          capturedAt: DateTime.utc(2026, 8, 19, 8, 45),
        ),
      ]);

      final result = resolutionService.resolve(
        sourceBundle: bundle,
        conflictKeyByContextId: const <String, String>{
          'ctx_identity': 'identity.assurance',
          'ctx_user': 'identity.assurance',
        },
        now: DateTime.utc(2026, 8, 19, 9),
      );

      expect(result.selectedItems.single.contextId, 'ctx_identity');
    });

    test('user assertion beats newer derived summary', () {
      final bundle = assemble(<AgentUnifiedContextItem>[
        item(
          contextId: 'ctx_user',
          value: 'prefers_cash',
          sourceType: AgentUnifiedContextSourceType.userStatement,
          sourceTrust: AgentUnifiedContextSourceTrust.userAsserted,
        ),
        item(
          contextId: 'ctx_summary',
          value: 'prefers_wallet',
          sourceType: AgentUnifiedContextSourceType.agentDerivedSummary,
          sourceTrust: AgentUnifiedContextSourceTrust.derivedSummary,
          generatedByAgent: true,
          capturedAt: DateTime.utc(2026, 8, 19, 8, 55),
        ),
      ]);

      final result = resolutionService.resolve(
        sourceBundle: bundle,
        conflictKeyByContextId: const <String, String>{
          'ctx_user': 'payment.preference',
          'ctx_summary': 'payment.preference',
        },
        now: DateTime.utc(2026, 8, 19, 9),
      );

      expect(result.selectedItems.single.contextId, 'ctx_user');
    });

    test('derived summary beats untrusted external metadata', () {
      final bundle = assemble(<AgentUnifiedContextItem>[
        item(
          contextId: 'ctx_summary',
          value: 'swat',
          sourceType: AgentUnifiedContextSourceType.agentDerivedSummary,
          sourceTrust: AgentUnifiedContextSourceTrust.derivedSummary,
          generatedByAgent: true,
        ),
        item(
          contextId: 'ctx_external',
          value: 'mingora',
          sourceType: AgentUnifiedContextSourceType.externalProviderMetadata,
          sourceTrust: AgentUnifiedContextSourceTrust.untrustedExternal,
          capturedAt: DateTime.utc(2026, 8, 19, 8, 55),
        ),
      ]);

      final result = resolutionService.resolve(
        sourceBundle: bundle,
        conflictKeyByContextId: const <String, String>{
          'ctx_summary': 'location.preference',
          'ctx_external': 'location.preference',
        },
        now: DateTime.utc(2026, 8, 19, 9),
      );

      expect(result.selectedItems.single.contextId, 'ctx_summary');
    });

    test('same trust uses newer fresh fact', () {
      final bundle = assemble(<AgentUnifiedContextItem>[
        item(
          contextId: 'ctx_old',
          value: 'searching',
          capturedAt: DateTime.utc(2026, 8, 19, 8),
        ),
        item(
          contextId: 'ctx_new',
          value: 'assigned',
          capturedAt: DateTime.utc(2026, 8, 19, 8, 50),
        ),
      ]);

      final result = resolutionService.resolve(
        sourceBundle: bundle,
        conflictKeyByContextId: const <String, String>{
          'ctx_old': 'ride.current_status',
          'ctx_new': 'ride.current_status',
        },
        now: DateTime.utc(2026, 8, 19, 9),
      );

      expect(result.selectedItems.single.contextId, 'ctx_new');
      expect(
        result.resolutionReasonByConflictKey['ride.current_status'],
        AgentUnifiedContextConflictResolutionReason.newerSameTrust,
      );
    });

    test('exact same-trust same-time contradictory tie is unresolved', () {
      final DateTime sameTime = DateTime.utc(2026, 8, 19, 8, 30);

      final bundle = assemble(<AgentUnifiedContextItem>[
        item(contextId: 'ctx_a', value: 'assigned', capturedAt: sameTime),
        item(contextId: 'ctx_b', value: 'cancelled', capturedAt: sameTime),
      ]);

      final result = resolutionService.resolve(
        sourceBundle: bundle,
        conflictKeyByContextId: const <String, String>{
          'ctx_a': 'ride.current_status',
          'ctx_b': 'ride.current_status',
        },
        now: DateTime.utc(2026, 8, 19, 9),
      );

      expect(result.hasUnresolvedConflicts, isTrue);
      expect(result.selectedItems, isEmpty);
      expect(result.unresolvedConflictKeys, contains('ride.current_status'));
      expect(
        result.resolutionReasonByConflictKey['ride.current_status'],
        AgentUnifiedContextConflictResolutionReason.exactTieUnresolved,
      );
    });

    test('same-time identical facts resolve deterministically', () {
      final DateTime sameTime = DateTime.utc(2026, 8, 19, 8, 30);

      final bundle = assemble(<AgentUnifiedContextItem>[
        item(contextId: 'ctx_b', value: 'assigned', capturedAt: sameTime),
        item(contextId: 'ctx_a', value: 'assigned', capturedAt: sameTime),
      ]);

      final result = resolutionService.resolve(
        sourceBundle: bundle,
        conflictKeyByContextId: const <String, String>{
          'ctx_a': 'ride.current_status',
          'ctx_b': 'ride.current_status',
        },
        now: DateTime.utc(2026, 8, 19, 9),
      );

      expect(result.hasUnresolvedConflicts, isFalse);
      expect(result.selectedItems.single.contextId, 'ctx_a');
      expect(
        result.resolutionReasonByConflictKey['ride.current_status'],
        AgentUnifiedContextConflictResolutionReason.identicalDuplicate,
      );
    });

    test('expired candidate is rejected during resolution freshness check', () {
      final bundle = assemble(<AgentUnifiedContextItem>[
        item(
          contextId: 'ctx_expired',
          value: 'old_status',
          capturedAt: DateTime.utc(2026, 8, 19, 8),
          expiresAt: DateTime.utc(2026, 8, 19, 9, 30),
        ),
      ]);

      final result = resolutionService.resolve(
        sourceBundle: bundle,
        conflictKeyByContextId: const <String, String>{
          'ctx_expired': 'ride.current_status',
        },
        now: DateTime.utc(2026, 8, 19, 10),
      );

      expect(result.selectedItems, isEmpty);
      expect(
        result.rejectedReasonsByContextId['ctx_expired'],
        AgentUnifiedContextConflictResolutionReason.expiredCandidate,
      );
    });

    test('future-dated candidate is rejected during freshness check', () {
      final bundle = assemble(<AgentUnifiedContextItem>[
        item(
          contextId: 'ctx_future',
          value: 'future_status',
          capturedAt: DateTime.utc(2026, 8, 19, 9, 30),
          expiresAt: DateTime.utc(2026, 8, 19, 11),
        ),
      ]);

      final result = resolutionService.resolve(
        sourceBundle: bundle,
        conflictKeyByContextId: const <String, String>{
          'ctx_future': 'ride.current_status',
        },
        now: DateTime.utc(2026, 8, 19, 9),
      );

      expect(result.selectedItems, isEmpty);
      expect(
        result.rejectedReasonsByContextId['ctx_future'],
        AgentUnifiedContextConflictResolutionReason.futureDatedCandidate,
      );
    });

    test('independent semantic keys resolve independently', () {
      final bundle = assemble(<AgentUnifiedContextItem>[
        item(contextId: 'ctx_ride', value: 'assigned'),
        item(contextId: 'ctx_food', value: 'preparing'),
      ]);

      final result = resolutionService.resolve(
        sourceBundle: bundle,
        conflictKeyByContextId: const <String, String>{
          'ctx_ride': 'ride.current_status',
          'ctx_food': 'food.current_status',
        },
        now: DateTime.utc(2026, 8, 19, 9),
      );

      expect(result.selectedItems.length, 2);
      expect(result.hasUnresolvedConflicts, isFalse);
    });

    test('missing conflict key blocks resolution fail-closed', () {
      final bundle = assemble(<AgentUnifiedContextItem>[
        item(contextId: 'ctx_1', value: 'assigned'),
      ]);

      final result = resolutionService.resolve(
        sourceBundle: bundle,
        conflictKeyByContextId: const <String, String>{},
        now: DateTime.utc(2026, 8, 19, 9),
      );

      expect(result.blocked, isTrue);
      expect(result.selectedItems, isEmpty);
      expect(
        result.resolutionReasonByConflictKey['__request__'],
        AgentUnifiedContextConflictResolutionReason.missingConflictKey,
      );
    });

    test('unsafe conflict key blocks resolution fail-closed', () {
      final bundle = assemble(<AgentUnifiedContextItem>[
        item(contextId: 'ctx_1', value: 'assigned'),
      ]);

      final result = resolutionService.resolve(
        sourceBundle: bundle,
        conflictKeyByContextId: const <String, String>{
          'ctx_1': 'ride status with raw text',
        },
        now: DateTime.utc(2026, 8, 19, 9),
      );

      expect(result.blocked, isTrue);
      expect(
        result.resolutionReasonByConflictKey['__request__'],
        AgentUnifiedContextConflictResolutionReason.invalidConflictKey,
      );
    });

    test('blocked source bundle cannot be resolved', () {
      final AgentUnifiedContextAssemblyBundle blockedBundle =
          AgentUnifiedContextAssemblyBundle(
            status: AgentUnifiedContextAssemblyStatus.blockedRequest,
            reasonCode: AgentUnifiedContextAssemblyReason.roleChannelMismatch,
            requestId: 'blocked',
            requestingSubjectRef: 'subject_hash_001',
            requestedPurpose: AgentUnifiedContextPurpose.statusRead,
            selectedItems: const <AgentUnifiedContextItem>[],
            rejectedReasonsByContextId: const <String, String>{},
            totalSanitizedCharacters: 0,
          );

      final result = resolutionService.resolve(
        sourceBundle: blockedBundle,
        conflictKeyByContextId: const <String, String>{},
        now: DateTime.utc(2026, 8, 19, 9),
      );

      expect(result.blocked, isTrue);
      expect(
        result.resolutionReasonByConflictKey['__request__'],
        AgentUnifiedContextConflictResolutionReason.sourceBundleNotReady,
      );
    });

    test('safe metadata omits sanitized values and authority', () {
      final bundle = assemble(<AgentUnifiedContextItem>[
        item(contextId: 'ctx_1', value: 'private safe status fact'),
      ]);

      final result = resolutionService.resolve(
        sourceBundle: bundle,
        conflictKeyByContextId: const <String, String>{
          'ctx_1': 'ride.current_status',
        },
        now: DateTime.utc(2026, 8, 19, 9),
      );

      final Map<String, dynamic> map = result.toSafeMetadataMap();

      expect(map.containsKey('sanitizedValue'), isFalse);
      expect(map['sanitizedValuesIncluded'], isFalse);
      expect(map['grantsAuthority'], isFalse);
      expect(map['grantsPermission'], isFalse);
      expect(map['consumesApproval'], isFalse);
      expect(map['invokesProvider'], isFalse);
      expect(map['writesBusinessData'], isFalse);
      expect(map['persistsResolution'], isFalse);
      expect(map['mergesConflictingValues'], isFalse);
    });

    test('resolver never gains execution, persistence, or merge authority', () {
      expect(resolutionService.grantsAuthority, isFalse);
      expect(resolutionService.grantsPermission, isFalse);
      expect(resolutionService.consumesApproval, isFalse);
      expect(resolutionService.invokesProvider, isFalse);
      expect(resolutionService.invokesTargetAgent, isFalse);
      expect(resolutionService.invokesRuntimeGate, isFalse);
      expect(resolutionService.writesBusinessData, isFalse);
      expect(resolutionService.persistsContext, isFalse);
      expect(resolutionService.persistsResolution, isFalse);
      expect(resolutionService.loadsFullConversationHistory, isFalse);
      expect(resolutionService.loadsCrossSubjectContext, isFalse);
      expect(resolutionService.mutatesSourceBundle, isFalse);
      expect(resolutionService.mergesConflictingValues, isFalse);
    });
  });
}
