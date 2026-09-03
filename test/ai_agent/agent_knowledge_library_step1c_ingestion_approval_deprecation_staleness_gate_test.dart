import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_knowledge_ingestion_gate_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_knowledge_library_contract_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_knowledge_ingestion_candidate.dart';
import 'package:swat_ride/ai_agent/models/agent_knowledge_ingestion_review_evidence.dart';
import 'package:swat_ride/ai_agent/models/agent_knowledge_item.dart';
import 'package:swat_ride/ai_agent/models/agent_knowledge_source_reference.dart';
import 'package:swat_ride/ai_agent/services/agent_knowledge_ingestion_gate.dart';
import 'package:swat_ride/ai_agent/services/agent_knowledge_item_contract_policy.dart';

void main() {
  const AgentKnowledgeItemContractPolicy contractPolicy =
      AgentKnowledgeItemContractPolicy();

  const AgentKnowledgeIngestionGate gate = AgentKnowledgeIngestionGate();

  final DateTime now = DateTime.utc(2026, 8, 19, 12);

  AgentKnowledgeSourceReference source({
    bool verified = true,
    bool approved = true,
    bool active = true,
    bool fresh = true,
    String sourceVersion = 'v2',
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
    );
  }

  AgentKnowledgeItem item({
    int revision = 2,
    String sourceVersion = 'v2',
    String supersedesItemId = 'knowledge:ride_faq:001',
  }) {
    return AgentKnowledgeItem(
      itemId: 'knowledge:ride_faq:002',
      sourceId: 'source:ride_faq',
      title: 'How normal ride booking works',
      module: 'ride',
      topic: 'booking',
      language: AgentKnowledgeLanguage.urdu,
      status: AgentKnowledgeItemStatus.approvedActive,
      revision: revision,
      sourceVersion: sourceVersion,
      contentReferenceId: 'content:ride_faq:002',
      scopes: const <String>{AgentKnowledgeScope.public},
      effectiveAt: DateTime.utc(2026, 8, 19, 8),
      supersedesItemId: supersedesItemId,
    );
  }

  AgentKnowledgeIngestionCandidate candidate({
    int revision = 2,
    String sourceVersion = 'v2',
    String contentBinding = 'content_binding:ride_faq_002',
    String contentFingerprint = 'fingerprint:ride_faq_002',
    String supersedesItemId = 'knowledge:ride_faq:001',
    int previousRevision = 1,
    bool deprecationAcknowledged = true,
    bool duplicateFingerprintDetected = false,
  }) {
    return AgentKnowledgeIngestionCandidate(
      itemId: 'knowledge:ride_faq:002',
      revision: revision,
      sourceVersion: sourceVersion,
      contentBinding: contentBinding,
      contentFingerprint: contentFingerprint,
      supersedesItemId: supersedesItemId,
      previousRevision: previousRevision,
      deprecationAcknowledged: deprecationAcknowledged,
      duplicateFingerprintDetected: duplicateFingerprintDetected,
    );
  }

  AgentKnowledgeIngestionReviewEvidence evidence({
    bool identityVerified = true,
    bool roleAuthorized = true,
    bool approvedForIngestion = true,
    int reviewedRevision = 2,
    String reviewedSourceVersion = 'v2',
    String reviewedContentBinding = 'content_binding:ride_faq_002',
    DateTime? reviewedAt,
  }) {
    return AgentKnowledgeIngestionReviewEvidence(
      approvalReferenceId: 'approval:knowledge:002',
      reviewerRole: AgentKnowledgeIngestionReviewerRole.owner,
      reviewerBinding: 'reviewer:owner_001',
      identityVerified: identityVerified,
      roleAuthorized: roleAuthorized,
      approvedForIngestion: approvedForIngestion,
      reviewedItemId: 'knowledge:ride_faq:002',
      reviewedRevision: reviewedRevision,
      reviewedSourceVersion: reviewedSourceVersion,
      reviewedContentBinding: reviewedContentBinding,
      reviewedAt: reviewedAt ?? DateTime.utc(2026, 8, 19, 11),
    );
  }

  group('Phase 57 Step 1C ingestion gate', () {
    test('3 trusted reviewer roles are locked', () {
      expect(AgentKnowledgeIngestionReviewerRole.values.length, 3);
    });

    test(
      'eligible Step1B contract + fresh approval can pass ingestion gate',
      () {
        final contract = contractPolicy.evaluate(
          item: item(),
          source: source(),
          now: now,
        );

        final result = gate.evaluate(
          contractDecision: contract,
          candidate: candidate(),
          reviewEvidence: evidence(),
          now: now,
        );

        expect(result.eligible, true);
        expect(
          result.status,
          AgentKnowledgeIngestionStatus.eligibleForTrustedIndexWrite,
        );
        expect(result.trustedIndexWriteEligible, true);
        expect(result.eligibilityIsNotIndexWrite, true);
      },
    );

    test('Step1B ineligible contract is blocked', () {
      final contract = contractPolicy.evaluate(
        item: item(),
        source: source(verified: false),
        now: now,
      );

      final result = gate.evaluate(
        contractDecision: contract,
        candidate: candidate(),
        reviewEvidence: evidence(),
        now: now,
      );

      expect(
        result.status,
        AgentKnowledgeIngestionStatus.blockedStep1BContract,
      );
    });

    test('unverified reviewer is blocked', () {
      final contract = contractPolicy.evaluate(
        item: item(),
        source: source(),
        now: now,
      );

      final result = gate.evaluate(
        contractDecision: contract,
        candidate: candidate(),
        reviewEvidence: evidence(identityVerified: false),
        now: now,
      );

      expect(
        result.status,
        AgentKnowledgeIngestionStatus.blockedUnverifiedReviewer,
      );
    });

    test('unauthorized reviewer is blocked', () {
      final contract = contractPolicy.evaluate(
        item: item(),
        source: source(),
        now: now,
      );

      final result = gate.evaluate(
        contractDecision: contract,
        candidate: candidate(),
        reviewEvidence: evidence(roleAuthorized: false),
        now: now,
      );

      expect(
        result.status,
        AgentKnowledgeIngestionStatus.blockedUnauthorizedReviewer,
      );
    });

    test('missing existing approval evidence is blocked', () {
      final contract = contractPolicy.evaluate(
        item: item(),
        source: source(),
        now: now,
      );

      final result = gate.evaluate(
        contractDecision: contract,
        candidate: candidate(),
        reviewEvidence: evidence(approvedForIngestion: false),
        now: now,
      );

      expect(
        result.status,
        AgentKnowledgeIngestionStatus.blockedApprovalMissing,
      );
    });

    test('stale approval evidence fails closed', () {
      final contract = contractPolicy.evaluate(
        item: item(),
        source: source(),
        now: now,
      );

      final result = gate.evaluate(
        contractDecision: contract,
        candidate: candidate(),
        reviewEvidence: evidence(reviewedAt: DateTime.utc(2026, 7, 1)),
        now: now,
      );

      expect(result.status, AgentKnowledgeIngestionStatus.blockedApprovalStale);
    });

    test('future-dated review evidence is stale/invalid', () {
      final contract = contractPolicy.evaluate(
        item: item(),
        source: source(),
        now: now,
      );

      final result = gate.evaluate(
        contractDecision: contract,
        candidate: candidate(),
        reviewEvidence: evidence(reviewedAt: DateTime.utc(2026, 8, 20)),
        now: now,
      );

      expect(result.status, AgentKnowledgeIngestionStatus.blockedApprovalStale);
    });

    test('reviewed item revision mismatch is blocked', () {
      final contract = contractPolicy.evaluate(
        item: item(),
        source: source(),
        now: now,
      );

      final result = gate.evaluate(
        contractDecision: contract,
        candidate: candidate(),
        reviewEvidence: evidence(reviewedRevision: 1),
        now: now,
      );

      expect(
        result.status,
        AgentKnowledgeIngestionStatus.blockedRevisionMismatch,
      );
    });

    test('reviewed source version mismatch is blocked', () {
      final contract = contractPolicy.evaluate(
        item: item(),
        source: source(),
        now: now,
      );

      final result = gate.evaluate(
        contractDecision: contract,
        candidate: candidate(),
        reviewEvidence: evidence(reviewedSourceVersion: 'v1'),
        now: now,
      );

      expect(
        result.status,
        AgentKnowledgeIngestionStatus.blockedSourceVersionMismatch,
      );
    });

    test('reviewed content binding mismatch is blocked', () {
      final contract = contractPolicy.evaluate(
        item: item(),
        source: source(),
        now: now,
      );

      final result = gate.evaluate(
        contractDecision: contract,
        candidate: candidate(),
        reviewEvidence: evidence(
          reviewedContentBinding: 'content_binding:other',
        ),
        now: now,
      );

      expect(
        result.status,
        AgentKnowledgeIngestionStatus.blockedContentBindingMismatch,
      );
    });

    test('duplicate content fingerprint candidate is blocked', () {
      final contract = contractPolicy.evaluate(
        item: item(),
        source: source(),
        now: now,
      );

      final result = gate.evaluate(
        contractDecision: contract,
        candidate: candidate(duplicateFingerprintDetected: true),
        reviewEvidence: evidence(),
        now: now,
      );

      expect(
        result.status,
        AgentKnowledgeIngestionStatus.blockedDuplicateCandidate,
      );
    });

    test('superseding revision must increase', () {
      final contract = contractPolicy.evaluate(
        item: item(revision: 2),
        source: source(),
        now: now,
      );

      final result = gate.evaluate(
        contractDecision: contract,
        candidate: candidate(revision: 2, previousRevision: 2),
        reviewEvidence: evidence(),
        now: now,
      );

      expect(
        result.status,
        AgentKnowledgeIngestionStatus.blockedSupersessionInvalid,
      );
    });

    test('superseding item requires deprecation acknowledgement', () {
      final contract = contractPolicy.evaluate(
        item: item(),
        source: source(),
        now: now,
      );

      final result = gate.evaluate(
        contractDecision: contract,
        candidate: candidate(deprecationAcknowledged: false),
        reviewEvidence: evidence(),
        now: now,
      );

      expect(
        result.status,
        AgentKnowledgeIngestionStatus.blockedDeprecationAcknowledgement,
      );
    });

    test('non-superseding first revision does not require deprecation', () {
      final firstItem = AgentKnowledgeItem(
        itemId: 'knowledge:ride_faq:first',
        sourceId: 'source:ride_faq',
        title: 'First approved ride FAQ',
        module: 'ride',
        topic: 'booking',
        language: AgentKnowledgeLanguage.urdu,
        status: AgentKnowledgeItemStatus.approvedActive,
        revision: 1,
        sourceVersion: 'v2',
        contentReferenceId: 'content:ride_faq:first',
        scopes: const <String>{AgentKnowledgeScope.public},
        effectiveAt: DateTime.utc(2026, 8, 19, 8),
      );

      final contract = contractPolicy.evaluate(
        item: firstItem,
        source: source(),
        now: now,
      );

      const firstCandidate = AgentKnowledgeIngestionCandidate(
        itemId: 'knowledge:ride_faq:first',
        revision: 1,
        sourceVersion: 'v2',
        contentBinding: 'content_binding:first',
        contentFingerprint: 'fingerprint:first',
        supersedesItemId: '',
        previousRevision: 0,
        deprecationAcknowledged: false,
        duplicateFingerprintDetected: false,
      );

      final firstEvidence = AgentKnowledgeIngestionReviewEvidence(
        approvalReferenceId: 'approval:knowledge:first',
        reviewerRole: AgentKnowledgeIngestionReviewerRole.admin,
        reviewerBinding: 'reviewer:admin_001',
        identityVerified: true,
        roleAuthorized: true,
        approvedForIngestion: true,
        reviewedItemId: 'knowledge:ride_faq:first',
        reviewedRevision: 1,
        reviewedSourceVersion: 'v2',
        reviewedContentBinding: 'content_binding:first',
        reviewedAt: DateTime.utc(2026, 8, 19, 11),
      );

      final result = gate.evaluate(
        contractDecision: contract,
        candidate: firstCandidate,
        reviewEvidence: firstEvidence,
        now: now,
      );

      expect(result.eligible, true);
    });

    test('review evidence contains no raw private identity fields', () {
      final value = evidence();

      expect(value.approvalEvidenceIsReadOnlyMetadata, true);
      expect(value.evidenceDoesNotGrantApproval, true);
      expect(value.containsPhone, false);
      expect(value.containsEmail, false);
      expect(value.containsCnic, false);
      expect(value.containsAuthToken, false);
      expect(value.containsSecret, false);
      expect(value.executesApproval, false);
      expect(value.grantsPermission, false);
      expect(value.marksRuntimeAllowed, false);
      expect(value.executesBusinessAction, false);
      expect(value.persistsEvidence, false);
    });

    test('candidate is metadata-only and writes nothing', () {
      final value = candidate();

      expect(value.candidateIsMetadataOnly, true);
      expect(value.containsRawKnowledgeContent, false);
      expect(value.containsRawPrompt, false);
      expect(value.containsPrivatePayload, false);
      expect(value.writesIndex, false);
      expect(value.writesFirestore, false);
      expect(value.executesDeprecation, false);
      expect(value.executesApproval, false);
      expect(value.grantsAuthority, false);
      expect(value.executesBusinessAction, false);
      expect(value.persistsCandidate, false);
    });

    test('eligible decision still performs no write/action', () {
      final contract = contractPolicy.evaluate(
        item: item(),
        source: source(),
        now: now,
      );

      final result = gate.evaluate(
        contractDecision: contract,
        candidate: candidate(),
        reviewEvidence: evidence(),
        now: now,
      );

      expect(result.approvalEvidenceIsNotApprovalExecution, true);
      expect(result.deprecationAcknowledgementIsNotDeprecationWrite, true);
      expect(result.knowledgeRemainsInformationOnly, true);
      expect(result.writesIndex, false);
      expect(result.writesFirestore, false);
      expect(result.executesApproval, false);
      expect(result.executesDeprecation, false);
      expect(result.grantsPermission, false);
      expect(result.marksRuntimeAllowed, false);
      expect(result.executesBusinessAction, false);
      expect(result.invokesProvider, false);
      expect(result.persistsDecision, false);
    });

    test('gate locks ingestion safety requirements', () {
      expect(gate.reusesStep1BContract, true);
      expect(gate.reusesExistingApprovalArchitecture, true);
      expect(gate.approvalEvidenceRequired, true);
      expect(gate.reviewerIdentityVerificationRequired, true);
      expect(gate.reviewerRoleAuthorizationRequired, true);
      expect(gate.approvalFreshnessRequired, true);
      expect(gate.itemRevisionBindingRequired, true);
      expect(gate.sourceVersionBindingRequired, true);
      expect(gate.contentBindingRequired, true);
      expect(gate.duplicateFingerprintGuardRequired, true);
      expect(gate.supersedingRevisionMustIncrease, true);
      expect(gate.deprecationAcknowledgementRequired, true);
      expect(gate.staleApprovalFailsClosed, true);
      expect(gate.humanReviewRequired, true);
      expect(gate.eligibilityIsNotIndexWrite, true);
      expect(gate.knowledgeIsInformationOnly, true);
    });

    test('gate has no production authority/persistence', () {
      expect(gate.writesTrustedIndex, false);
      expect(gate.writesFirestore, false);
      expect(gate.executesApproval, false);
      expect(gate.executesDeprecation, false);
      expect(gate.grantsPermission, false);
      expect(gate.marksRuntimeAllowed, false);
      expect(gate.executesBusinessAction, false);
      expect(gate.invokesProvider, false);
      expect(gate.sendsWhatsApp, false);
      expect(gate.persistsKnowledge, false);
    });

    test('Phase 55/62/63 ownership remains separate', () {
      expect(gate.duplicatesPhase55VideoCatalog, false);
      expect(gate.implementsPhase62TrainingDeployment, false);
      expect(gate.implementsPhase63RetentionUi, false);
    });
  });
}
