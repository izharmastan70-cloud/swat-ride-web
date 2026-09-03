import '../constants/agent_knowledge_library_contract_constants.dart';
import '../models/agent_knowledge_item.dart';
import '../models/agent_knowledge_item_contract_decision.dart';
import '../models/agent_knowledge_source_reference.dart';

class AgentKnowledgeItemContractPolicy {
  const AgentKnowledgeItemContractPolicy();

  AgentKnowledgeItemContractDecision evaluate({
    required AgentKnowledgeItem item,
    required AgentKnowledgeSourceReference source,
    required DateTime now,
  }) {
    try {
      item.validateStructure();
      source.validateStructure();
    } catch (_) {
      return _blocked(
        status: AgentKnowledgeContractStatus.blockedInvalidStructure,
        item: item,
        reason: 'invalid_structure',
      );
    }

    if (item.sourceId != source.sourceId) {
      return _blocked(
        status: AgentKnowledgeContractStatus.blockedVersionMismatch,
        item: item,
        reason: 'source_id_mismatch',
      );
    }

    if (!source.verified) {
      return _blocked(
        status: AgentKnowledgeContractStatus.blockedUnverifiedSource,
        item: item,
        reason: 'source_must_be_verified',
      );
    }

    if (!source.approved) {
      return _blocked(
        status: AgentKnowledgeContractStatus.blockedUnapprovedSource,
        item: item,
        reason: 'source_must_be_approved',
      );
    }

    if (!source.active) {
      return _blocked(
        status: AgentKnowledgeContractStatus.blockedInactiveSource,
        item: item,
        reason: 'source_must_be_active',
      );
    }

    if (!source.fresh || source.isExpiredAt(now)) {
      return _blocked(
        status: AgentKnowledgeContractStatus.blockedStaleSource,
        item: item,
        reason: 'source_must_be_fresh',
      );
    }

    if (item.status != AgentKnowledgeItemStatus.approvedActive) {
      return _blocked(
        status: AgentKnowledgeContractStatus.blockedItemNotApproved,
        item: item,
        reason: 'item_must_be_approved_active',
      );
    }

    if (item.sourceVersion != source.sourceVersion) {
      return _blocked(
        status: AgentKnowledgeContractStatus.blockedVersionMismatch,
        item: item,
        reason: 'source_version_mismatch',
      );
    }

    if (item.hasPublicPrivilegedScopeConflict) {
      return _blocked(
        status: AgentKnowledgeContractStatus.blockedScopeConflict,
        item: item,
        reason: 'public_privileged_scope_conflict',
      );
    }

    if (!item.isEffectiveAt(now)) {
      return _blocked(
        status: AgentKnowledgeContractStatus.blockedNotEffective,
        item: item,
        reason: 'item_not_effective_yet',
      );
    }

    if (item.isExpiredAt(now)) {
      return _blocked(
        status: AgentKnowledgeContractStatus.blockedExpired,
        item: item,
        reason: 'item_expired',
      );
    }

    return _decision(
      status: AgentKnowledgeContractStatus.eligibleForLibraryIndexing,
      item: item,
      indexingEligible: true,
      reasons: const <String>[
        'verified_source',
        'approved_source',
        'active_source',
        'fresh_source',
        'approved_active_item',
        'version_match',
        'scope_valid',
        'human_review_required',
        'eligibility_not_index_write',
        'knowledge_information_only',
      ],
    );
  }

  AgentKnowledgeItemContractDecision _blocked({
    required String status,
    required AgentKnowledgeItem item,
    required String reason,
  }) {
    return _decision(
      status: status,
      item: item,
      indexingEligible: false,
      reasons: <String>[
        reason,
        'fail_closed',
        'human_review_required',
        'no_index_write',
        'no_business_authority',
      ],
    );
  }

  AgentKnowledgeItemContractDecision _decision({
    required String status,
    required AgentKnowledgeItem item,
    required bool indexingEligible,
    required List<String> reasons,
  }) {
    final AgentKnowledgeItemContractDecision decision =
        AgentKnowledgeItemContractDecision(
          status: status,
          itemId: item.itemId.trim().isEmpty
              ? 'invalid_knowledge_item'
              : item.itemId,
          sourceId: item.sourceId.trim().isEmpty
              ? 'invalid_knowledge_source'
              : item.sourceId,
          revision: item.revision <= 0 ? 1 : item.revision,
          indexingEligible: indexingEligible,
          humanReviewRequired: true,
          reasonCodes: reasons,
        );

    decision.validateStructure();
    return decision;
  }

  bool get sourceVerificationRequired => true;
  bool get sourceApprovalRequired => true;
  bool get sourceActiveRequired => true;
  bool get sourceFreshnessRequired => true;
  bool get itemApprovedActiveRequired => true;
  bool get sourceVersionMatchRequired => true;
  bool get scopeValidationRequired => true;
  bool get publicPrivilegedScopeMixBlocked => true;
  bool get effectiveTimeRequired => true;
  bool get expiryEnforced => true;
  bool get versionedSupersessionSupported => true;
  bool get humanReviewRequired => true;
  bool get knowledgeIsInformationOnly => true;
  bool get indexingEligibilityIsNotIndexWrite => true;

  bool get reusesConversationGrounding => true;
  bool get reusesResponseGuard => true;
  bool get reusesExistingApprovalArchitecture => true;
  bool get duplicatesPhase55VideoCatalog => false;
  bool get implementsPhase62TrainingDeployment => false;
  bool get implementsPhase63RetentionUi => false;

  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get indexesContent => false;
  bool get retrievesContent => false;
  bool get invokesProvider => false;
  bool get sendsWhatsApp => false;
  bool get persistsKnowledge => false;
}
