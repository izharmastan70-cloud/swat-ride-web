import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_knowledge_library_contract_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_knowledge_item.dart';
import 'package:swat_ride/ai_agent/models/agent_knowledge_source_reference.dart';
import 'package:swat_ride/ai_agent/services/agent_knowledge_item_contract_policy.dart';

void main() {
  const AgentKnowledgeItemContractPolicy policy =
      AgentKnowledgeItemContractPolicy();

  final DateTime now = DateTime.utc(2026, 8, 19, 12);

  AgentKnowledgeSourceReference source({
    bool verified = true,
    bool approved = true,
    bool active = true,
    bool fresh = true,
    String sourceVersion = 'v1',
    DateTime? expiresAt,
  }) {
    return AgentKnowledgeSourceReference(
      sourceId: 'source:ride_faq',
      sourceType: AgentKnowledgeSourceType.helpFaq,
      sourceReferenceId: 'faq:ride:001',
      sourceVersion: sourceVersion,
      authorityClass: AgentKnowledgeAuthorityClass.systemVerified,
      verified: verified,
      approved: approved,
      active: active,
      fresh: fresh,
      lastVerifiedAt: DateTime.utc(2026, 8, 19, 10),
      expiresAt: expiresAt,
    );
  }

  AgentKnowledgeItem item({
    String status = AgentKnowledgeItemStatus.approvedActive,
    String sourceVersion = 'v1',
    Set<String> scopes = const <String>{AgentKnowledgeScope.public},
    DateTime? effectiveAt,
    DateTime? expiresAt,
  }) {
    return AgentKnowledgeItem(
      itemId: 'knowledge:ride_faq:001',
      sourceId: 'source:ride_faq',
      title: 'How normal ride booking works',
      module: 'ride',
      topic: 'booking',
      language: AgentKnowledgeLanguage.urdu,
      status: status,
      revision: 1,
      sourceVersion: sourceVersion,
      contentReferenceId: 'content:ride_faq:001',
      scopes: scopes,
      effectiveAt: effectiveAt ?? DateTime.utc(2026, 8, 19, 8),
      expiresAt: expiresAt,
    );
  }

  group('Phase 57 Step 1B knowledge contracts', () {
    test('11 knowledge source types are locked', () {
      expect(AgentKnowledgeSourceType.values.length, 11);
    });

    test('5 authority classes are locked', () {
      expect(AgentKnowledgeAuthorityClass.values.length, 5);
    });

    test('16 knowledge scopes are locked', () {
      expect(AgentKnowledgeScope.values.length, 16);
    });

    test('3 languages are locked', () {
      expect(AgentKnowledgeLanguage.values, <String>{
        AgentKnowledgeLanguage.urdu,
        AgentKnowledgeLanguage.pashto,
        AgentKnowledgeLanguage.english,
      });
    });

    test('verified approved active fresh version-matched item is eligible', () {
      final result = policy.evaluate(item: item(), source: source(), now: now);

      expect(result.eligible, true);
      expect(
        result.status,
        AgentKnowledgeContractStatus.eligibleForLibraryIndexing,
      );
      expect(result.indexingEligible, true);
      expect(result.humanReviewRequired, true);
      expect(result.eligibilityIsNotIndexWrite, true);
    });

    test('unverified source fails closed', () {
      final result = policy.evaluate(
        item: item(),
        source: source(verified: false),
        now: now,
      );

      expect(
        result.status,
        AgentKnowledgeContractStatus.blockedUnverifiedSource,
      );
      expect(result.eligible, false);
    });

    test('unapproved source fails closed', () {
      final result = policy.evaluate(
        item: item(),
        source: source(approved: false),
        now: now,
      );

      expect(
        result.status,
        AgentKnowledgeContractStatus.blockedUnapprovedSource,
      );
    });

    test('inactive source fails closed', () {
      final result = policy.evaluate(
        item: item(),
        source: source(active: false),
        now: now,
      );

      expect(result.status, AgentKnowledgeContractStatus.blockedInactiveSource);
    });

    test('stale source fails closed', () {
      final result = policy.evaluate(
        item: item(),
        source: source(fresh: false),
        now: now,
      );

      expect(result.status, AgentKnowledgeContractStatus.blockedStaleSource);
    });

    test('expired source fails closed', () {
      final result = policy.evaluate(
        item: item(),
        source: source(expiresAt: DateTime.utc(2026, 8, 19, 11)),
        now: now,
      );

      expect(result.status, AgentKnowledgeContractStatus.blockedStaleSource);
    });

    test('draft item cannot enter indexing eligibility', () {
      final result = policy.evaluate(
        item: item(status: AgentKnowledgeItemStatus.draft),
        source: source(),
        now: now,
      );

      expect(
        result.status,
        AgentKnowledgeContractStatus.blockedItemNotApproved,
      );
    });

    test('deprecated item cannot enter indexing eligibility', () {
      final result = policy.evaluate(
        item: item(status: AgentKnowledgeItemStatus.deprecated),
        source: source(),
        now: now,
      );

      expect(
        result.status,
        AgentKnowledgeContractStatus.blockedItemNotApproved,
      );
    });

    test('source version mismatch fails closed', () {
      final result = policy.evaluate(
        item: item(sourceVersion: 'v2'),
        source: source(sourceVersion: 'v1'),
        now: now,
      );

      expect(
        result.status,
        AgentKnowledgeContractStatus.blockedVersionMismatch,
      );
    });

    test('public plus privileged scope mix is blocked', () {
      final result = policy.evaluate(
        item: item(
          scopes: const <String>{
            AgentKnowledgeScope.public,
            AgentKnowledgeScope.owner,
          },
        ),
        source: source(),
        now: now,
      );

      expect(result.status, AgentKnowledgeContractStatus.blockedScopeConflict);
    });

    test('role-scoped internal knowledge can stay non-public', () {
      final result = policy.evaluate(
        item: item(
          scopes: const <String>{
            AgentKnowledgeScope.owner,
            AgentKnowledgeScope.admin,
          },
        ),
        source: source(),
        now: now,
      );

      expect(result.eligible, true);
    });

    test('future effective item is blocked', () {
      final result = policy.evaluate(
        item: item(effectiveAt: DateTime.utc(2026, 8, 20)),
        source: source(),
        now: now,
      );

      expect(result.status, AgentKnowledgeContractStatus.blockedNotEffective);
    });

    test('expired item is blocked', () {
      final result = policy.evaluate(
        item: item(expiresAt: DateTime.utc(2026, 8, 19, 11)),
        source: source(),
        now: now,
      );

      expect(result.status, AgentKnowledgeContractStatus.blockedExpired);
    });

    test(
      'knowledge item stores metadata reference not raw secret material',
      () {
        final value = item();

        expect(value.metadataReferencesContentOnly, true);
        expect(value.containsRawSecret, false);
        expect(value.containsAuthToken, false);
        expect(value.containsPassword, false);
        expect(value.containsPaymentCard, false);
        expect(value.containsCvv, false);
        expect(value.containsPin, false);
        expect(value.grantsPermission, false);
        expect(value.consumesApproval, false);
        expect(value.marksRuntimeAllowed, false);
        expect(value.executesBusinessAction, false);
        expect(value.writesBusinessData, false);
        expect(value.indexesContentHere, false);
        expect(value.retrievesContentHere, false);
        expect(value.invokesProvider, false);
        expect(value.persistsItem, false);
      },
    );

    test('knowledge source metadata grants no authority', () {
      final value = source();

      expect(value.sourceIsInformationNotAuthority, true);
      expect(value.approvalMetadataDoesNotExecuteApproval, true);
      expect(value.grantsPermission, false);
      expect(value.consumesApproval, false);
      expect(value.marksRuntimeAllowed, false);
      expect(value.executesBusinessAction, false);
      expect(value.writesBusinessData, false);
      expect(value.invokesProvider, false);
      expect(value.persistsSource, false);
    });

    test('eligible decision still executes nothing', () {
      final result = policy.evaluate(item: item(), source: source(), now: now);

      expect(result.knowledgeIsInformationOnly, true);
      expect(result.approvalMetadataIsNotApprovalExecution, true);
      expect(result.grantsPermission, false);
      expect(result.consumesApproval, false);
      expect(result.marksRuntimeAllowed, false);
      expect(result.executesBusinessAction, false);
      expect(result.writesBusinessData, false);
      expect(result.indexesContent, false);
      expect(result.retrievesContent, false);
      expect(result.invokesProvider, false);
      expect(result.persistsDecision, false);
    });

    test('policy locks source/scope/version/freshness requirements', () {
      expect(policy.sourceVerificationRequired, true);
      expect(policy.sourceApprovalRequired, true);
      expect(policy.sourceActiveRequired, true);
      expect(policy.sourceFreshnessRequired, true);
      expect(policy.itemApprovedActiveRequired, true);
      expect(policy.sourceVersionMatchRequired, true);
      expect(policy.scopeValidationRequired, true);
      expect(policy.publicPrivilegedScopeMixBlocked, true);
      expect(policy.effectiveTimeRequired, true);
      expect(policy.expiryEnforced, true);
      expect(policy.versionedSupersessionSupported, true);
      expect(policy.humanReviewRequired, true);
      expect(policy.knowledgeIsInformationOnly, true);
      expect(policy.indexingEligibilityIsNotIndexWrite, true);
    });

    test('existing phase ownership is preserved', () {
      expect(policy.reusesConversationGrounding, true);
      expect(policy.reusesResponseGuard, true);
      expect(policy.reusesExistingApprovalArchitecture, true);
      expect(policy.duplicatesPhase55VideoCatalog, false);
      expect(policy.implementsPhase62TrainingDeployment, false);
      expect(policy.implementsPhase63RetentionUi, false);
    });

    test('policy has no production authority or persistence', () {
      expect(policy.grantsPermission, false);
      expect(policy.consumesApproval, false);
      expect(policy.marksRuntimeAllowed, false);
      expect(policy.executesBusinessAction, false);
      expect(policy.writesBusinessData, false);
      expect(policy.indexesContent, false);
      expect(policy.retrievesContent, false);
      expect(policy.invokesProvider, false);
      expect(policy.sendsWhatsApp, false);
      expect(policy.persistsKnowledge, false);
    });
  });
}
