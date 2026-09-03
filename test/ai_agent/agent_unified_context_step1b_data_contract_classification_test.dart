import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_omnichannel_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_unified_context_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_unified_context_item.dart';
import 'package:swat_ride/ai_agent/services/agent_unified_context_classification_policy.dart';

void main() {
  const AgentUnifiedContextClassificationPolicy policy =
      AgentUnifiedContextClassificationPolicy();

  AgentUnifiedContextItem item({
    String contextId = 'ctx_001',
    String subjectRef = 'subject_hash_001',
    String sourceChannel = AgentOmnichannelChannel.appChat,
    String sourceType = AgentUnifiedContextSourceType.domainServiceRead,
    String sourceTrust = AgentUnifiedContextSourceTrust.verifiedSystem,
    String sensitivity = AgentUnifiedContextSensitivity.personalData,
    String purpose = AgentUnifiedContextPurpose.statusRead,
    String dataKind = AgentUnifiedContextDataKind.statusFact,
    String sanitizedValue = 'Current booking status is assigned.',
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
      sanitizedValue: sanitizedValue,
      capturedAt: captured,
      expiresAt: expiresAt ?? captured.add(const Duration(hours: 2)),
      identityBound: identityBound,
      containsRawSecret: containsRawSecret,
      containsPaymentCredential: containsPaymentCredential,
      containsAuthToken: containsAuthToken,
      containsRawMessageHistory: containsRawMessageHistory,
      containsOwnerAdminPrivateData: containsOwnerAdminPrivateData,
      generatedByAgent: generatedByAgent,
    );
  }

  group('Phase 52 Step 1B unified context data contract', () {
    test('classification vocabularies are closed and explicit', () {
      expect(AgentUnifiedContextSensitivity.values.length, 5);
      expect(AgentUnifiedContextSourceTrust.values.length, 5);
      expect(AgentUnifiedContextSourceType.values.length, 6);
      expect(AgentUnifiedContextPurpose.values.length, 5);
      expect(AgentUnifiedContextDataKind.values.length, 7);
    });

    test(
      'verified domain-service status fact is allowed for same subject/purpose',
      () {
        final AgentUnifiedContextItem context = item();

        final decision = policy.evaluate(
          item: context,
          requestingSubjectRef: 'subject_hash_001',
          requestingRoleId: 'support_agent',
          requestingChannel: AgentOmnichannelChannel.appChat,
          requestedPurpose: AgentUnifiedContextPurpose.statusRead,
          now: DateTime.utc(2026, 8, 19, 8, 30),
        );

        expect(decision.allowed, isTrue);
        expect(decision.reasonCode, AgentUnifiedContextReason.allowed);
      },
    );

    test('source trust describes provenance but grants no authority', () {
      final AgentUnifiedContextItem context = item();

      expect(context.grantsAuthority, isFalse);
      expect(context.grantsPermission, isFalse);
      expect(context.consumesApproval, isFalse);
      expect(context.invokesProvider, isFalse);
      expect(context.invokesRuntimeGate, isFalse);
      expect(context.writesBusinessData, isFalse);
      expect(context.persistsItself, isFalse);

      expect(policy.grantsAuthority, isFalse);
      expect(policy.grantsPermission, isFalse);
      expect(policy.consumesApproval, isFalse);
      expect(policy.invokesProvider, isFalse);
      expect(policy.writesBusinessData, isFalse);
    });

    test('raw secret is fail-closed', () {
      final decision = policy.evaluate(
        item: item(containsRawSecret: true),
        requestingSubjectRef: 'subject_hash_001',
        requestingRoleId: 'support_agent',
        requestingChannel: AgentOmnichannelChannel.appChat,
        requestedPurpose: AgentUnifiedContextPurpose.statusRead,
        now: DateTime.utc(2026, 8, 19, 8, 30),
      );

      expect(decision.blocked, isTrue);
      expect(decision.reasonCode, AgentUnifiedContextReason.rawSecretBlocked);
    });

    test('payment credential and auth token are fail-closed', () {
      final paymentDecision = policy.evaluate(
        item: item(containsPaymentCredential: true),
        requestingSubjectRef: 'subject_hash_001',
        requestingRoleId: 'support_agent',
        requestingChannel: AgentOmnichannelChannel.appChat,
        requestedPurpose: AgentUnifiedContextPurpose.statusRead,
        now: DateTime.utc(2026, 8, 19, 8, 30),
      );

      final authDecision = policy.evaluate(
        item: item(containsAuthToken: true),
        requestingSubjectRef: 'subject_hash_001',
        requestingRoleId: 'support_agent',
        requestingChannel: AgentOmnichannelChannel.appChat,
        requestedPurpose: AgentUnifiedContextPurpose.statusRead,
        now: DateTime.utc(2026, 8, 19, 8, 30),
      );

      expect(
        paymentDecision.reasonCode,
        AgentUnifiedContextReason.paymentCredentialBlocked,
      );
      expect(
        authDecision.reasonCode,
        AgentUnifiedContextReason.authTokenBlocked,
      );
    });

    test('raw message history is not accepted as unified context', () {
      final decision = policy.evaluate(
        item: item(containsRawMessageHistory: true),
        requestingSubjectRef: 'subject_hash_001',
        requestingRoleId: 'support_agent',
        requestingChannel: AgentOmnichannelChannel.appChat,
        requestedPurpose: AgentUnifiedContextPurpose.statusRead,
        now: DateTime.utc(2026, 8, 19, 8, 30),
      );

      expect(decision.blocked, isTrue);
      expect(decision.reasonCode, AgentUnifiedContextReason.rawHistoryBlocked);
    });

    test('expired context is blocked', () {
      final AgentUnifiedContextItem context = item(
        capturedAt: DateTime.utc(2026, 8, 19, 5, 0),
        expiresAt: DateTime.utc(2026, 8, 19, 6, 0),
      );

      final decision = policy.evaluate(
        item: context,
        requestingSubjectRef: 'subject_hash_001',
        requestingRoleId: 'support_agent',
        requestingChannel: AgentOmnichannelChannel.appChat,
        requestedPurpose: AgentUnifiedContextPurpose.statusRead,
        now: DateTime.utc(2026, 8, 19, 8, 30),
      );

      expect(decision.reasonCode, AgentUnifiedContextReason.expiredBlocked);
    });

    test('subject mismatch and purpose mismatch fail closed', () {
      final subjectDecision = policy.evaluate(
        item: item(),
        requestingSubjectRef: 'different_subject',
        requestingRoleId: 'support_agent',
        requestingChannel: AgentOmnichannelChannel.appChat,
        requestedPurpose: AgentUnifiedContextPurpose.statusRead,
        now: DateTime.utc(2026, 8, 19, 8, 30),
      );

      final purposeDecision = policy.evaluate(
        item: item(),
        requestingSubjectRef: 'subject_hash_001',
        requestingRoleId: 'support_agent',
        requestingChannel: AgentOmnichannelChannel.appChat,
        requestedPurpose: AgentUnifiedContextPurpose.bookingAssistance,
        now: DateTime.utc(2026, 8, 19, 8, 30),
      );

      expect(
        subjectDecision.reasonCode,
        AgentUnifiedContextReason.subjectMismatchBlocked,
      );
      expect(
        purposeDecision.reasonCode,
        AgentUnifiedContextReason.purposeMismatchBlocked,
      );
    });

    test('restricted sensitivity is blocked from Phase 52 unified context', () {
      final decision = policy.evaluate(
        item: item(sensitivity: AgentUnifiedContextSensitivity.restrictedData),
        requestingSubjectRef: 'subject_hash_001',
        requestingRoleId: 'support_agent',
        requestingChannel: AgentOmnichannelChannel.appChat,
        requestedPurpose: AgentUnifiedContextPurpose.statusRead,
        now: DateTime.utc(2026, 8, 19, 8, 30),
      );

      expect(
        decision.reasonCode,
        AgentUnifiedContextReason.restrictedSensitivityBlocked,
      );
    });

    test('owner private context cannot leak to customer-facing channel', () {
      final AgentUnifiedContextItem ownerContext = item(
        sourceChannel: AgentOmnichannelChannel.ownerWhatsApp,
        sensitivity: AgentUnifiedContextSensitivity.sensitiveData,
        purpose: AgentUnifiedContextPurpose.ownerOperations,
        dataKind: AgentUnifiedContextDataKind.ownerOperationalFact,
        containsOwnerAdminPrivateData: true,
      );

      final decision = policy.evaluate(
        item: ownerContext,
        requestingSubjectRef: 'subject_hash_001',
        requestingRoleId: 'support_agent',
        requestingChannel: AgentOmnichannelChannel.appChat,
        requestedPurpose: AgentUnifiedContextPurpose.ownerOperations,
        now: DateTime.utc(2026, 8, 19, 8, 30),
      );

      expect(decision.blocked, isTrue);
      expect(
        decision.reasonCode,
        AgentUnifiedContextReason.ownerPrivateLeakBlocked,
      );
    });

    test(
      'owner private context may classify only for locked owner role/channel',
      () {
        final AgentUnifiedContextItem ownerContext = item(
          sourceChannel: AgentOmnichannelChannel.ownerWhatsApp,
          sensitivity: AgentUnifiedContextSensitivity.sensitiveData,
          purpose: AgentUnifiedContextPurpose.ownerOperations,
          dataKind: AgentUnifiedContextDataKind.ownerOperationalFact,
          containsOwnerAdminPrivateData: true,
        );

        final decision = policy.evaluate(
          item: ownerContext,
          requestingSubjectRef: 'subject_hash_001',
          requestingRoleId: 'owner_whatsapp_agent',
          requestingChannel: AgentOmnichannelChannel.ownerWhatsApp,
          requestedPurpose: AgentUnifiedContextPurpose.ownerOperations,
          now: DateTime.utc(2026, 8, 19, 8, 30),
        );

        expect(decision.allowed, isTrue);
      },
    );

    test(
      'user statement cannot be silently promoted to verified system trust',
      () {
        final decision = policy.evaluate(
          item: item(
            sourceType: AgentUnifiedContextSourceType.userStatement,
            sourceTrust: AgentUnifiedContextSourceTrust.verifiedSystem,
          ),
          requestingSubjectRef: 'subject_hash_001',
          requestingRoleId: 'support_agent',
          requestingChannel: AgentOmnichannelChannel.appChat,
          requestedPurpose: AgentUnifiedContextPurpose.statusRead,
          now: DateTime.utc(2026, 8, 19, 8, 30),
        );

        expect(decision.blocked, isTrue);
        expect(
          decision.reasonCode,
          AgentUnifiedContextReason.sourceTrustMismatchBlocked,
        );
      },
    );

    test('agent-derived summary requires derived-summary trust', () {
      final AgentUnifiedContextItem summary = item(
        sourceType: AgentUnifiedContextSourceType.agentDerivedSummary,
        sourceTrust: AgentUnifiedContextSourceTrust.derivedSummary,
        dataKind: AgentUnifiedContextDataKind.conversationSummary,
        generatedByAgent: true,
      );

      final decision = policy.evaluate(
        item: summary,
        requestingSubjectRef: 'subject_hash_001',
        requestingRoleId: 'support_agent',
        requestingChannel: AgentOmnichannelChannel.appChat,
        requestedPurpose: AgentUnifiedContextPurpose.statusRead,
        now: DateTime.utc(2026, 8, 19, 8, 30),
      );

      expect(decision.allowed, isTrue);
    });

    test('safe metadata map omits sanitized value and execution authority', () {
      final Map<String, dynamic> map = item().toSafeMetadataMap();

      expect(map.containsKey('sanitizedValue'), isFalse);
      expect(map['sanitizedValueIncluded'], isFalse);
      expect(map['grantsAuthority'], isFalse);
      expect(map['grantsPermission'], isFalse);
      expect(map['consumesApproval'], isFalse);
      expect(map['invokesProvider'], isFalse);
      expect(map['writesBusinessData'], isFalse);
      expect(map['persistsItself'], isFalse);
    });

    test(
      'Step 1B adds no persistence/full-history/retention-control authority',
      () {
        expect(policy.persistsContext, isFalse);
        expect(policy.loadsFullConversationHistory, isFalse);
        expect(policy.implementsRetentionControlCenter, isFalse);
      },
    );
  });
}
