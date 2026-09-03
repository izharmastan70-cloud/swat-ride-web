import '../constants/agent_knowledge_ingestion_gate_constants.dart';
import '../models/agent_knowledge_ingestion_candidate.dart';
import '../models/agent_knowledge_ingestion_decision.dart';
import '../models/agent_knowledge_ingestion_review_evidence.dart';
import '../models/agent_knowledge_item_contract_decision.dart';

class AgentKnowledgeIngestionGate {
  const AgentKnowledgeIngestionGate();

  AgentKnowledgeIngestionDecision evaluate({
    required AgentKnowledgeItemContractDecision contractDecision,
    required AgentKnowledgeIngestionCandidate candidate,
    required AgentKnowledgeIngestionReviewEvidence reviewEvidence,
    required DateTime now,
  }) {
    try {
      contractDecision.validateStructure();
      candidate.validateStructure();
      reviewEvidence.validateStructure();
    } catch (_) {
      return _blocked(
        status: AgentKnowledgeIngestionStatus.blockedInvalidReviewEvidence,
        candidate: candidate,
        reason: 'invalid_ingestion_structure',
      );
    }

    if (!contractDecision.eligible ||
        !contractDecision.indexingEligible ||
        contractDecision.itemId != candidate.itemId ||
        contractDecision.revision != candidate.revision) {
      return _blocked(
        status: AgentKnowledgeIngestionStatus.blockedStep1BContract,
        candidate: candidate,
        reason: 'step1b_contract_not_eligible',
      );
    }

    if (!reviewEvidence.identityVerified) {
      return _blocked(
        status: AgentKnowledgeIngestionStatus.blockedUnverifiedReviewer,
        candidate: candidate,
        reason: 'reviewer_identity_verification_required',
      );
    }

    if (!reviewEvidence.roleAuthorized) {
      return _blocked(
        status: AgentKnowledgeIngestionStatus.blockedUnauthorizedReviewer,
        candidate: candidate,
        reason: 'reviewer_role_authorization_required',
      );
    }

    if (!reviewEvidence.approvedForIngestion) {
      return _blocked(
        status: AgentKnowledgeIngestionStatus.blockedApprovalMissing,
        candidate: candidate,
        reason: 'existing_approval_evidence_required',
      );
    }

    if (reviewEvidence.isStaleAt(now)) {
      return _blocked(
        status: AgentKnowledgeIngestionStatus.blockedApprovalStale,
        candidate: candidate,
        reason: 'approval_evidence_stale',
      );
    }

    if (reviewEvidence.reviewedItemId != candidate.itemId ||
        reviewEvidence.reviewedRevision != candidate.revision) {
      return _blocked(
        status: AgentKnowledgeIngestionStatus.blockedRevisionMismatch,
        candidate: candidate,
        reason: 'reviewed_revision_binding_mismatch',
      );
    }

    if (reviewEvidence.reviewedSourceVersion != candidate.sourceVersion) {
      return _blocked(
        status: AgentKnowledgeIngestionStatus.blockedSourceVersionMismatch,
        candidate: candidate,
        reason: 'reviewed_source_version_mismatch',
      );
    }

    if (reviewEvidence.reviewedContentBinding != candidate.contentBinding) {
      return _blocked(
        status: AgentKnowledgeIngestionStatus.blockedContentBindingMismatch,
        candidate: candidate,
        reason: 'reviewed_content_binding_mismatch',
      );
    }

    if (candidate.duplicateFingerprintDetected) {
      return _blocked(
        status: AgentKnowledgeIngestionStatus.blockedDuplicateCandidate,
        candidate: candidate,
        reason: 'duplicate_content_fingerprint',
      );
    }

    if (candidate.isSuperseding) {
      if (candidate.previousRevision <= 0 ||
          candidate.revision <= candidate.previousRevision) {
        return _blocked(
          status: AgentKnowledgeIngestionStatus.blockedSupersessionInvalid,
          candidate: candidate,
          reason: 'superseding_revision_must_increase',
        );
      }

      if (!candidate.deprecationAcknowledged) {
        return _blocked(
          status:
              AgentKnowledgeIngestionStatus.blockedDeprecationAcknowledgement,
          candidate: candidate,
          reason: 'previous_version_deprecation_ack_required',
        );
      }
    }

    final AgentKnowledgeIngestionDecision decision =
        AgentKnowledgeIngestionDecision(
          status: AgentKnowledgeIngestionStatus.eligibleForTrustedIndexWrite,
          itemId: candidate.itemId,
          revision: candidate.revision,
          trustedIndexWriteEligible: true,
          humanReviewRequired: true,
          reasonCodes: const <String>[
            'step1b_contract_reused',
            'verified_authorized_reviewer',
            'existing_approval_evidence_reused',
            'approval_evidence_fresh',
            'revision_binding_match',
            'source_version_binding_match',
            'content_binding_match',
            'duplicate_guard_passed',
            'supersession_deprecation_guard_passed',
            'eligibility_not_index_write',
            'knowledge_information_only',
          ],
        );

    decision.validateStructure();
    return decision;
  }

  AgentKnowledgeIngestionDecision _blocked({
    required String status,
    required AgentKnowledgeIngestionCandidate candidate,
    required String reason,
  }) {
    final AgentKnowledgeIngestionDecision decision =
        AgentKnowledgeIngestionDecision(
          status: status,
          itemId: candidate.itemId.trim().isEmpty
              ? 'invalid_knowledge_item'
              : candidate.itemId,
          revision: candidate.revision <= 0 ? 1 : candidate.revision,
          trustedIndexWriteEligible: false,
          humanReviewRequired: true,
          reasonCodes: <String>[
            reason,
            'fail_closed',
            'human_review_required',
            'no_index_write',
            'no_deprecation_write',
            'no_business_authority',
          ],
        );

    decision.validateStructure();
    return decision;
  }

  bool get reusesStep1BContract => true;
  bool get reusesExistingApprovalArchitecture => true;
  bool get approvalEvidenceRequired => true;
  bool get reviewerIdentityVerificationRequired => true;
  bool get reviewerRoleAuthorizationRequired => true;
  bool get approvalFreshnessRequired => true;
  bool get itemRevisionBindingRequired => true;
  bool get sourceVersionBindingRequired => true;
  bool get contentBindingRequired => true;
  bool get duplicateFingerprintGuardRequired => true;
  bool get supersedingRevisionMustIncrease => true;
  bool get deprecationAcknowledgementRequired => true;
  bool get staleApprovalFailsClosed => true;
  bool get humanReviewRequired => true;
  bool get eligibilityIsNotIndexWrite => true;
  bool get knowledgeIsInformationOnly => true;

  bool get writesTrustedIndex => false;
  bool get writesFirestore => false;
  bool get executesApproval => false;
  bool get executesDeprecation => false;
  bool get grantsPermission => false;
  bool get marksRuntimeAllowed => false;
  bool get executesBusinessAction => false;
  bool get invokesProvider => false;
  bool get sendsWhatsApp => false;
  bool get persistsKnowledge => false;

  bool get duplicatesPhase55VideoCatalog => false;
  bool get implementsPhase62TrainingDeployment => false;
  bool get implementsPhase63RetentionUi => false;
}
