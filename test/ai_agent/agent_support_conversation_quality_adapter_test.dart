import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/services/agent_conversation_response_guard.dart';
import 'package:swat_ride/ai_agent/services/agent_support_conversation_quality_adapter.dart';

void main() {
  const AgentSupportConversationQualityAdapter adapter =
      AgentSupportConversationQualityAdapter();

  test('ungrounded successful AI text is blocked from visible reply', () {
    final AgentSupportConversationQualityAdapterResult
    result = adapter.guardAiDraft(
      proposedAiReply: 'Invented booking fact that must never become visible.',
      deterministicFallback: 'Please check the verified support information.',
    );

    expect(result.usedDeterministicFallback, isTrue);
    expect(result.replyText, 'Please check the verified support information.');
    expect(result.replyText, isNot(contains('Invented booking fact')));
    expect(result.guardResult.visibleAnswerText, isEmpty);
    expect(
      result.guardResult.responseMode,
      AgentConversationResponseGuard.modeSafeFallback,
    );
  });

  test('approved video guide hint is preserved after safe fallback', () {
    final AgentSupportConversationQualityAdapterResult result = adapter
        .guardAiDraft(
          proposedAiReply: 'Unsupported AI draft.',
          deterministicFallback: 'Safe deterministic FAQ answer.',
          approvedGuideHint: '\n\nApproved SWAT RIDE video guide: Test Guide',
        );

    expect(
      result.replyText,
      'Safe deterministic FAQ answer.'
      '\n\nApproved SWAT RIDE video guide: Test Guide',
    );
  });

  test(
    'empty deterministic fallback becomes explicit verification message',
    () {
      final AgentSupportConversationQualityAdapterResult result = adapter
          .guardAiDraft(
            proposedAiReply: 'Unsupported AI answer.',
            deterministicFallback: '   ',
          );

      expect(
        result.replyText,
        'I need verified information before I can answer that reliably.',
      );
      expect(result.usedDeterministicFallback, isTrue);
    },
  );

  test('adapter keeps auto-send eligibility behind outer support policy', () {
    final AgentSupportConversationQualityAdapterResult result = adapter
        .guardAiDraft(
          proposedAiReply: 'Unsupported AI answer.',
          deterministicFallback: 'Curated fallback.',
        );

    expect(result.allowAutoSendLater, isTrue);
    expect(result.usedDeterministicFallback, isTrue);
  });

  test('adapter exposes no runtime authority', () {
    expect(adapter.providerExecutionAllowed, isFalse);
    expect(adapter.firestoreReadAllowed, isFalse);
    expect(adapter.firestoreWriteAllowed, isFalse);
    expect(adapter.runtimeActionAllowed, isFalse);
    expect(adapter.permissionGrantAllowed, isFalse);
    expect(adapter.approvalConsumptionAllowed, isFalse);
    expect(adapter.promptMutationAllowed, isFalse);
    expect(adapter.modelTrainingAllowed, isFalse);
    expect(adapter.deploymentAllowed, isFalse);
  });
}
