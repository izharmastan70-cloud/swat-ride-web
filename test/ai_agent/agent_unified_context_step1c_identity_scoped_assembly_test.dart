import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_omnichannel_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_unified_context_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_unified_context_assembly_bundle.dart';
import 'package:swat_ride/ai_agent/models/agent_unified_context_assembly_request.dart';
import 'package:swat_ride/ai_agent/models/agent_unified_context_item.dart';
import 'package:swat_ride/ai_agent/services/agent_unified_context_assembly_service.dart';

void main() {
  const AgentUnifiedContextAssemblyService service =
      AgentUnifiedContextAssemblyService();

  AgentUnifiedContextAssemblyRequest request({
    String requestId = 'assembly_001',
    String subjectRef = 'subject_hash_001',
    String roleId = 'support_agent',
    String channel = AgentOmnichannelChannel.appChat,
    String purpose = AgentUnifiedContextPurpose.statusRead,
    int maxItems = 6,
    int maxCharacters = 1800,
  }) {
    return AgentUnifiedContextAssemblyRequest(
      requestId: requestId,
      requestingSubjectRef: subjectRef,
      requestingRoleId: roleId,
      requestingChannel: channel,
      requestedPurpose: purpose,
      requestedAt: DateTime.utc(2026, 8, 19, 9, 0),
      maxItems: maxItems,
      maxSanitizedCharacters: maxCharacters,
    );
  }

  AgentUnifiedContextItem item({
    required String contextId,
    String subjectRef = 'subject_hash_001',
    String sourceChannel = AgentOmnichannelChannel.appChat,
    String sourceType = AgentUnifiedContextSourceType.domainServiceRead,
    String sourceTrust = AgentUnifiedContextSourceTrust.verifiedSystem,
    String sensitivity = AgentUnifiedContextSensitivity.personalData,
    String purpose = AgentUnifiedContextPurpose.statusRead,
    String dataKind = AgentUnifiedContextDataKind.statusFact,
    String value = 'Safe status fact.',
    DateTime? capturedAt,
    DateTime? expiresAt,
    bool identityBound = true,
    bool containsRawSecret = false,
    bool containsPaymentCredential = false,
    bool containsAuthToken = false,
    bool containsRawMessageHistory = false,
    bool containsOwnerAdminPrivateData = false,
    bool generatedByAgent = false,
  }) {
    final DateTime captured = capturedAt ?? DateTime.utc(2026, 8, 19, 8, 0);

    return AgentUnifiedContextItem(
      contextId: contextId,
      subjectRef: subjectRef,
      sourceChannel: sourceChannel,
      sourceType: sourceType,
      sourceTrust: sourceTrust,
      sensitivity: sensitivity,
      purpose: purpose,
      dataKind: dataKind,
      sanitizedValue: value,
      capturedAt: captured,
      expiresAt: expiresAt ?? DateTime.utc(2026, 8, 19, 10, 0),
      identityBound: identityBound,
      containsRawSecret: containsRawSecret,
      containsPaymentCredential: containsPaymentCredential,
      containsAuthToken: containsAuthToken,
      containsRawMessageHistory: containsRawMessageHistory,
      containsOwnerAdminPrivateData: containsOwnerAdminPrivateData,
      generatedByAgent: generatedByAgent,
    );
  }

  group('Phase 52 Step 1C identity-scoped context assembly', () {
    test('same-subject safe facts can assemble across source channels', () {
      final bundle = service.assemble(
        request: request(),
        candidates: <AgentUnifiedContextItem>[
          item(
            contextId: 'ctx_app',
            sourceChannel: AgentOmnichannelChannel.appChat,
          ),
          item(
            contextId: 'ctx_whatsapp',
            sourceChannel: AgentOmnichannelChannel.customerWhatsApp,
          ),
          item(
            contextId: 'ctx_email',
            sourceChannel: AgentOmnichannelChannel.email,
          ),
        ],
      );

      expect(bundle.ready, isTrue);
      expect(bundle.selectedItems.length, 3);
    });

    test('wrong subject is excluded from assembly', () {
      final bundle = service.assemble(
        request: request(),
        candidates: <AgentUnifiedContextItem>[
          item(contextId: 'ctx_same'),
          item(contextId: 'ctx_wrong', subjectRef: 'different_subject'),
        ],
      );

      expect(bundle.selectedItems.length, 1);
      expect(
        bundle.rejectedReasonsByContextId['ctx_wrong'],
        AgentUnifiedContextReason.subjectMismatchBlocked,
      );
    });

    test('wrong purpose is excluded from assembly', () {
      final bundle = service.assemble(
        request: request(),
        candidates: <AgentUnifiedContextItem>[
          item(contextId: 'ctx_status'),
          item(
            contextId: 'ctx_booking',
            purpose: AgentUnifiedContextPurpose.bookingAssistance,
            dataKind: AgentUnifiedContextDataKind.bookingFact,
          ),
        ],
      );

      expect(bundle.selectedItems.length, 1);
      expect(
        bundle.rejectedReasonsByContextId['ctx_booking'],
        AgentUnifiedContextReason.purposeMismatchBlocked,
      );
    });

    test(
      'raw history, secret, payment credential and auth token are excluded',
      () {
        final bundle = service.assemble(
          request: request(),
          candidates: <AgentUnifiedContextItem>[
            item(contextId: 'ctx_history', containsRawMessageHistory: true),
            item(contextId: 'ctx_secret', containsRawSecret: true),
            item(contextId: 'ctx_payment', containsPaymentCredential: true),
            item(contextId: 'ctx_auth', containsAuthToken: true),
          ],
        );

        expect(bundle.selectedItems, isEmpty);
        expect(bundle.containsRawMessageHistory, isFalse);
        expect(bundle.containsRawSecret, isFalse);
        expect(bundle.containsPaymentCredential, isFalse);
        expect(bundle.containsAuthToken, isFalse);
      },
    );

    test('expired context is excluded', () {
      final bundle = service.assemble(
        request: request(),
        candidates: <AgentUnifiedContextItem>[
          item(
            contextId: 'ctx_expired',
            capturedAt: DateTime.utc(2026, 8, 19, 6, 0),
            expiresAt: DateTime.utc(2026, 8, 19, 7, 0),
          ),
        ],
      );

      expect(bundle.selectedItems, isEmpty);
      expect(
        bundle.rejectedReasonsByContextId['ctx_expired'],
        AgentUnifiedContextReason.expiredBlocked,
      );
    });

    test('customer channel cannot assemble owner private context', () {
      final bundle = service.assemble(
        request: request(purpose: AgentUnifiedContextPurpose.statusRead),
        candidates: <AgentUnifiedContextItem>[
          item(
            contextId: 'ctx_owner_private',
            sourceChannel: AgentOmnichannelChannel.ownerWhatsApp,
            sensitivity: AgentUnifiedContextSensitivity.sensitiveData,
            containsOwnerAdminPrivateData: true,
          ),
        ],
      );

      expect(bundle.selectedItems, isEmpty);
      expect(
        bundle.rejectedReasonsByContextId['ctx_owner_private'],
        AgentUnifiedContextReason.ownerPrivateLeakBlocked,
      );
    });

    test('owner role/channel may assemble correctly-scoped owner context', () {
      final bundle = service.assemble(
        request: request(
          roleId: 'owner_whatsapp_agent',
          channel: AgentOmnichannelChannel.ownerWhatsApp,
          purpose: AgentUnifiedContextPurpose.ownerOperations,
        ),
        candidates: <AgentUnifiedContextItem>[
          item(
            contextId: 'ctx_owner',
            sourceChannel: AgentOmnichannelChannel.ownerWhatsApp,
            sensitivity: AgentUnifiedContextSensitivity.sensitiveData,
            purpose: AgentUnifiedContextPurpose.ownerOperations,
            dataKind: AgentUnifiedContextDataKind.ownerOperationalFact,
            containsOwnerAdminPrivateData: true,
          ),
        ],
      );

      expect(bundle.ready, isTrue);
      expect(bundle.selectedItems.length, 1);
    });

    test('role-channel mismatch blocks the entire assembly request', () {
      final bundle = service.assemble(
        request: request(
          roleId: 'support_agent',
          channel: AgentOmnichannelChannel.ownerVoice,
        ),
        candidates: <AgentUnifiedContextItem>[item(contextId: 'ctx_001')],
      );

      expect(bundle.blockedRequest, isTrue);
      expect(
        bundle.reasonCode,
        AgentUnifiedContextAssemblyReason.roleChannelMismatch,
      );
      expect(bundle.selectedItems, isEmpty);
    });

    test('purpose not allowed for role blocks the entire request', () {
      final bundle = service.assemble(
        request: request(
          roleId: 'emergency_whatsapp_agent',
          channel: AgentOmnichannelChannel.emergencyWhatsApp,
          purpose: AgentUnifiedContextPurpose.statusRead,
        ),
        candidates: <AgentUnifiedContextItem>[item(contextId: 'ctx_001')],
      );

      expect(bundle.blockedRequest, isTrue);
      expect(
        bundle.reasonCode,
        AgentUnifiedContextAssemblyReason.purposeNotAllowedForRole,
      );
    });

    test('emergency agent can assemble only safety-triage scoped context', () {
      final bundle = service.assemble(
        request: request(
          roleId: 'emergency_whatsapp_agent',
          channel: AgentOmnichannelChannel.emergencyWhatsApp,
          purpose: AgentUnifiedContextPurpose.safetyTriage,
        ),
        candidates: <AgentUnifiedContextItem>[
          item(
            contextId: 'ctx_safety',
            sourceChannel: AgentOmnichannelChannel.emergencyWhatsApp,
            sourceType: AgentUnifiedContextSourceType.emergencyTriageSignal,
            sourceTrust: AgentUnifiedContextSourceTrust.userAsserted,
            purpose: AgentUnifiedContextPurpose.safetyTriage,
            dataKind: AgentUnifiedContextDataKind.safetyNeed,
            value: 'Caller reports immediate safety assistance need.',
          ),
          item(
            contextId: 'ctx_status',
            sourceChannel: AgentOmnichannelChannel.appChat,
          ),
        ],
      );

      expect(bundle.selectedItems.length, 1);
      expect(bundle.selectedItems.single.contextId, 'ctx_safety');
    });

    test('max item budget is enforced', () {
      final bundle = service.assemble(
        request: request(maxItems: 2),
        candidates: <AgentUnifiedContextItem>[
          item(
            contextId: 'ctx_1',
            capturedAt: DateTime.utc(2026, 8, 19, 8, 30),
          ),
          item(
            contextId: 'ctx_2',
            capturedAt: DateTime.utc(2026, 8, 19, 8, 20),
          ),
          item(
            contextId: 'ctx_3',
            capturedAt: DateTime.utc(2026, 8, 19, 8, 10),
          ),
        ],
      );

      expect(bundle.selectedItems.length, 2);
      expect(
        bundle.rejectedReasonsByContextId['ctx_3'],
        AgentUnifiedContextAssemblyReason.itemBudgetExceeded,
      );
    });

    test('sanitized character budget is enforced without truncating facts', () {
      final bundle = service.assemble(
        request: request(maxCharacters: 20),
        candidates: <AgentUnifiedContextItem>[
          item(
            contextId: 'ctx_short',
            value: '1234567890',
            capturedAt: DateTime.utc(2026, 8, 19, 8, 30),
          ),
          item(
            contextId: 'ctx_over',
            value: 'abcdefghijk',
            capturedAt: DateTime.utc(2026, 8, 19, 8, 20),
          ),
        ],
      );

      expect(bundle.selectedItems.length, 1);
      expect(bundle.selectedItems.single.contextId, 'ctx_short');
      expect(bundle.totalSanitizedCharacters, 10);
      expect(
        bundle.rejectedReasonsByContextId['ctx_over'],
        AgentUnifiedContextAssemblyReason.characterBudgetExceeded,
      );
    });

    test('newest safe items win and duplicate context IDs are not reused', () {
      final bundle = service.assemble(
        request: request(maxItems: 3),
        candidates: <AgentUnifiedContextItem>[
          item(
            contextId: 'ctx_dup',
            value: 'older',
            capturedAt: DateTime.utc(2026, 8, 19, 8, 0),
          ),
          item(
            contextId: 'ctx_dup',
            value: 'newer',
            capturedAt: DateTime.utc(2026, 8, 19, 8, 40),
          ),
          item(
            contextId: 'ctx_other',
            value: 'other',
            capturedAt: DateTime.utc(2026, 8, 19, 8, 20),
          ),
        ],
      );

      expect(bundle.selectedItems.length, 2);
      expect(bundle.selectedItems.first.sanitizedValue, 'newer');
      expect(
        bundle.rejectedReasonsByContextId['ctx_dup'],
        AgentUnifiedContextAssemblyReason.duplicateContextId,
      );
    });

    test('bundle metadata does not expose sanitized values or authority', () {
      final bundle = service.assemble(
        request: request(),
        candidates: <AgentUnifiedContextItem>[
          item(contextId: 'ctx_001', value: 'private safe fact'),
        ],
      );

      final Map<String, dynamic> map = bundle.toSafeMetadataMap();

      expect(map.containsKey('sanitizedValue'), isFalse);
      expect(map['sanitizedValuesIncluded'], isFalse);
      expect(map['grantsAuthority'], isFalse);
      expect(map['grantsPermission'], isFalse);
      expect(map['consumesApproval'], isFalse);
      expect(map['invokesProvider'], isFalse);
      expect(map['writesBusinessData'], isFalse);
      expect(map['persistsBundle'], isFalse);
    });

    test('assembly service cannot persist, execute, or load full history', () {
      expect(service.grantsAuthority, isFalse);
      expect(service.grantsPermission, isFalse);
      expect(service.consumesApproval, isFalse);
      expect(service.invokesProvider, isFalse);
      expect(service.invokesTargetAgent, isFalse);
      expect(service.invokesRuntimeGate, isFalse);
      expect(service.writesBusinessData, isFalse);
      expect(service.persistsContext, isFalse);
      expect(service.persistsBundle, isFalse);
      expect(service.loadsFullConversationHistory, isFalse);
      expect(service.loadsCrossSubjectContext, isFalse);
      expect(service.bypassesRoleChannelMapping, isFalse);
    });
  });
}
