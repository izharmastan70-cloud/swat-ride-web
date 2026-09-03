import '../constants/agent_knowledge_answer_context_constants.dart';
import '../models/agent_knowledge_answer_context_projection.dart';
import '../models/agent_knowledge_answer_context_request.dart';
import '../models/agent_knowledge_conflict_resolution_result.dart';
import '../models/agent_knowledge_owner_whatsapp_read_projection.dart';

class AgentKnowledgeAnswerContextPolicy {
  const AgentKnowledgeAnswerContextPolicy();

  AgentKnowledgeAnswerContextProjection buildAnswerContext({
    required AgentKnowledgeAnswerContextRequest request,
    required AgentKnowledgeConflictResolutionResult conflictResult,
  }) {
    try {
      request.validateStructure();
      conflictResult.validateStructure();
    } catch (_) {
      return _blocked(
        status: AgentKnowledgeAnswerContextStatus.noContextInvalidRequest,
        request: request,
        reasons: const <String>[
          'invalid_answer_context_input',
          'fail_closed',
          'no_guess',
        ],
      );
    }

    if (!conflictResult.ready) {
      return _blocked(
        status: AgentKnowledgeAnswerContextStatus.noContextConflictNotReady,
        request: request,
        reasons: const <String>[
          'step1e_conflict_resolution_not_ready',
          'no_answer_inherited',
          'no_guess',
        ],
      );
    }

    if (!request.scopeAuthorizationVerified) {
      return _blocked(
        status: AgentKnowledgeAnswerContextStatus
            .noContextScopeAuthorizationUnverified,
        request: request,
        reasons: const <String>[
          'preauthorized_scope_required',
          'answer_context_cannot_grant_scope',
          'fail_closed',
          'no_guess',
        ],
      );
    }

    if (!request.exactLanguageMatch) {
      return _blocked(
        status: AgentKnowledgeAnswerContextStatus.noContextLanguageMismatch,
        request: request,
        reasons: const <String>[
          'exact_source_request_language_match_required',
          'automatic_translation_disabled',
          'no_guess',
        ],
      );
    }

    if (!request.privacySafe) {
      return _blocked(
        status: AgentKnowledgeAnswerContextStatus.noContextPrivacyBlocked,
        request: request,
        reasons: const <String>[
          'blocked_privacy_risk_present',
          'private_payload_not_allowed',
          'fail_closed',
          'no_guess',
        ],
      );
    }

    if (conflictResult.citations.isEmpty) {
      return _blocked(
        status: AgentKnowledgeAnswerContextStatus.noContextCitationMissing,
        request: request,
        reasons: const <String>[
          'citation_required_for_grounded_context',
          'no_guess',
        ],
      );
    }

    final List<AgentKnowledgeAnswerCitationProjection> citations =
        conflictResult.citations
            .take(AgentKnowledgeAnswerContextLimits.maxCitationReferences)
            .map(
              (citation) => AgentKnowledgeAnswerCitationProjection(
                itemId: citation.itemId,
                sourceId: citation.sourceId,
                sourceReferenceId: citation.sourceReferenceId,
                contentReferenceId: citation.contentReferenceId,
                sourceType: citation.sourceType,
                authorityClass: citation.authorityClass,
                revision: citation.revision,
                sourceVersion: citation.sourceVersion,
                claimKey: citation.claimKey,
              ),
            )
            .toList(growable: false);

    final AgentKnowledgeAnswerContextProjection projection =
        AgentKnowledgeAnswerContextProjection(
          status: AgentKnowledgeAnswerContextStatus.readyForGroundedAnswer,
          requestId: request.requestId,
          module: request.module,
          topic: request.topic,
          language: request.requestedLanguage,
          targetScope: request.targetScope,
          claimKey: conflictResult.claimKey,
          selectedClaimValueBinding: conflictResult.selectedClaimValueBinding,
          citations: citations,
          reasonCodes: const <String>[
            'step1e_ready_conflict_resolution_reused',
            'preauthorized_scope_consumed',
            'exact_language_match',
            'privacy_minimized_projection',
            'opaque_selected_claim_binding_only',
            'citation_metadata_only',
            'raw_knowledge_content_excluded',
            'raw_private_payload_excluded',
            'conversation_grounding_required_next',
            'response_guard_required_next',
            'no_business_authority',
          ],
        );

    projection.validateStructure();
    return projection;
  }

  AgentKnowledgeOwnerWhatsAppReadProjection? buildOwnerWhatsAppReadProjection({
    required AgentKnowledgeAnswerContextProjection answerContext,
    required String targetRole,
    required bool whatsappIdentityVerified,
    required bool roleAuthorized,
  }) {
    if (!answerContext.ready ||
        !AgentKnowledgeOwnerWhatsAppReadRole.values.contains(targetRole) ||
        !whatsappIdentityVerified ||
        !roleAuthorized) {
      return null;
    }

    final List<String> sourceReferenceIds =
        answerContext.citations
            .map((citation) => citation.sourceReferenceId)
            .toSet()
            .toList()
          ..sort();

    return AgentKnowledgeOwnerWhatsAppReadProjection(
      requestId: answerContext.requestId,
      targetRole: targetRole,
      module: answerContext.module,
      topic: answerContext.topic,
      language: answerContext.language,
      claimKey: answerContext.claimKey,
      citationCount: answerContext.citations.length,
      sourceReferenceIds: sourceReferenceIds,
      warningCodes: const <String>[
        'read_visibility_only',
        'reference_metadata_only',
        'no_raw_knowledge_payload',
        'no_private_payload',
        'no_whatsapp_send_execution',
        'no_approval_execution',
        'no_business_authority',
      ],
    );
  }

  AgentKnowledgeAnswerContextProjection _blocked({
    required String status,
    required AgentKnowledgeAnswerContextRequest request,
    required List<String> reasons,
  }) {
    final AgentKnowledgeAnswerContextProjection projection =
        AgentKnowledgeAnswerContextProjection(
          status: status,
          requestId: request.requestId.trim().isEmpty
              ? 'invalid_answer_context_request'
              : request.requestId,
          module: request.module,
          topic: request.topic,
          language: request.requestedLanguage,
          targetScope: request.targetScope,
          claimKey: '',
          selectedClaimValueBinding: '',
          citations: const <AgentKnowledgeAnswerCitationProjection>[],
          reasonCodes: reasons,
        );

    projection.validateStructure();
    return projection;
  }

  bool get consumesStep1EReadyConflictMetadata => true;
  bool get exactLanguageMatchRequired => true;
  bool get automaticTranslationDisabled => true;
  bool get scopeAuthorizationMustBePreverified => true;
  bool get answerContextCannotGrantScope => true;
  bool get privacyRiskFailClosed => true;
  bool get rawConversationExcluded => true;
  bool get rawPromptExcluded => true;
  bool get privateIdentityExcluded => true;
  bool get paymentDataExcluded => true;
  bool get secretExcluded => true;
  bool get rawKnowledgeContentExcluded => true;
  bool get rawSourcePayloadExcluded => true;
  bool get citationMetadataRequired => true;
  bool get selectedClaimBindingOpaque => true;
  bool get conversationGroundingRequiredNext => true;
  bool get responseGuardRequiredNext => true;

  bool get ownerWhatsAppReadVisibilityOnly => true;
  bool get ownerWhatsAppIdentityVerificationRequired => true;
  bool get ownerWhatsAppRoleAuthorizationRequired => true;
  bool get ownerWhatsAppUsesExistingArchitecture => true;
  bool get ownerWhatsAppExcludesSelectedClaimBinding => true;
  bool get ownerWhatsAppExcludesPrivatePayload => true;
  bool get ownerWhatsAppSendExecution => false;
  bool get ownerWhatsAppApprovalExecution => false;

  bool get grantsPermission => false;
  bool get expandsScope => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get performsDatabaseSearch => false;
  bool get retrievesRawKnowledgeContent => false;
  bool get invokesProvider => false;
  bool get persistsAnswerContext => false;

  bool get duplicatesStep1EConflictResolution => false;
  bool get duplicatesConversationGrounding => false;
  bool get duplicatesResponseGuard => false;
  bool get duplicatesOwnerWhatsAppTransport => false;
  bool get duplicatesPhase55VideoCatalog => false;
  bool get implementsPhase62TrainingDeployment => false;
  bool get implementsPhase63RetentionUi => false;
}
