import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_knowledge_answer_context_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_knowledge_conflict_resolution_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_knowledge_library_contract_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_knowledge_answer_context_request.dart';
import 'package:swat_ride/ai_agent/models/agent_knowledge_citation_reference.dart';
import 'package:swat_ride/ai_agent/models/agent_knowledge_conflict_resolution_result.dart';
import 'package:swat_ride/ai_agent/services/agent_knowledge_answer_context_policy.dart';

void main() {
  const AgentKnowledgeAnswerContextPolicy policy =
      AgentKnowledgeAnswerContextPolicy();

  AgentKnowledgeAnswerContextRequest request({
    String requestedLanguage = AgentKnowledgeLanguage.urdu,
    String sourceLanguage = AgentKnowledgeLanguage.urdu,
    String targetScope = AgentKnowledgeScope.public,
    bool scopeAuthorizationVerified = true,
    Set<String> privacyRiskFlags = const <String>{},
  }) {
    return AgentKnowledgeAnswerContextRequest(
      requestId: 'answer_context:ride:001',
      module: 'ride',
      topic: 'booking',
      requestedLanguage: requestedLanguage,
      sourceLanguage: sourceLanguage,
      targetScope: targetScope,
      scopeAuthorizationVerified: scopeAuthorizationVerified,
      privacyRiskFlags: privacyRiskFlags,
    );
  }

  AgentKnowledgeConflictResolutionResult readyConflict() {
    return AgentKnowledgeConflictResolutionResult(
      status: AgentKnowledgeConflictStatus.readyForGrounding,
      claimKey: 'ride_booking_available',
      selectedClaimValueBinding: 'binding:true',
      citations: const <AgentKnowledgeCitationReference>[
        AgentKnowledgeCitationReference(
          itemId: 'knowledge:ride:001',
          sourceId: 'source:ride:system',
          sourceReferenceId: 'source_ref:ride:001',
          contentReferenceId: 'content:ride:001',
          sourceType: AgentKnowledgeSourceType.verifiedFeatureState,
          authorityClass: AgentKnowledgeAuthorityClass.systemVerified,
          revision: 1,
          sourceVersion: 'v1',
          claimKey: 'ride_booking_available',
          claimValueBinding: 'binding:true',
        ),
      ],
      reasonCodes: const <String>[
        'citation_required',
        'conversation_grounding_required_next',
      ],
    );
  }

  AgentKnowledgeConflictResolutionResult blockedConflict() {
    return AgentKnowledgeConflictResolutionResult(
      status: AgentKnowledgeConflictStatus.noAnswerUnresolvedConflict,
      claimKey: 'ride_booking_available',
      selectedClaimValueBinding: '',
      citations: const <AgentKnowledgeCitationReference>[],
      reasonCodes: const <String>['equal_top_precedence_conflict', 'no_guess'],
    );
  }

  group('Phase 57 Step 1F answer context', () {
    test('7 answer-context statuses are locked', () {
      expect(AgentKnowledgeAnswerContextStatus.values.length, 7);
    });

    test('13 blocked privacy risk classes are locked', () {
      expect(AgentKnowledgeAnswerPrivacyRisk.blocked.length, 13);
    });

    test('3 Owner WhatsApp read roles are locked', () {
      expect(AgentKnowledgeOwnerWhatsAppReadRole.values.length, 3);
    });

    test('ready Step1E result builds privacy-minimized answer context', () {
      final result = policy.buildAnswerContext(
        request: request(),
        conflictResult: readyConflict(),
      );

      expect(result.ready, true);
      expect(
        result.status,
        AgentKnowledgeAnswerContextStatus.readyForGroundedAnswer,
      );
      expect(result.selectedClaimValueBinding, 'binding:true');
      expect(result.citations.length, 1);
      expect(result.noAnswerRequired, false);
      expect(result.conversationGroundingRequired, true);
      expect(result.responseGuardRequired, true);
    });

    test('unresolved Step1E conflict cannot produce answer context', () {
      final result = policy.buildAnswerContext(
        request: request(),
        conflictResult: blockedConflict(),
      );

      expect(result.ready, false);
      expect(
        result.status,
        AgentKnowledgeAnswerContextStatus.noContextConflictNotReady,
      );
      expect(result.noAnswerRequired, true);
      expect(result.selectedClaimValueBinding, isEmpty);
      expect(result.citations, isEmpty);
    });

    test('pre-authorized scope is mandatory', () {
      final result = policy.buildAnswerContext(
        request: request(scopeAuthorizationVerified: false),
        conflictResult: readyConflict(),
      );

      expect(
        result.status,
        AgentKnowledgeAnswerContextStatus.noContextScopeAuthorizationUnverified,
      );
      expect(result.noAnswerRequired, true);
    });

    test('language mismatch fails closed without auto-translation', () {
      final result = policy.buildAnswerContext(
        request: request(
          requestedLanguage: AgentKnowledgeLanguage.pashto,
          sourceLanguage: AgentKnowledgeLanguage.urdu,
        ),
        conflictResult: readyConflict(),
      );

      expect(
        result.status,
        AgentKnowledgeAnswerContextStatus.noContextLanguageMismatch,
      );
      expect(result.noAnswerRequired, true);
      expect(result.automaticTranslationPerformed, false);
    });

    test('Urdu exact match is allowed', () {
      final result = policy.buildAnswerContext(
        request: request(
          requestedLanguage: AgentKnowledgeLanguage.urdu,
          sourceLanguage: AgentKnowledgeLanguage.urdu,
        ),
        conflictResult: readyConflict(),
      );

      expect(result.ready, true);
      expect(result.language, AgentKnowledgeLanguage.urdu);
    });

    test('Pashto exact match is allowed', () {
      final result = policy.buildAnswerContext(
        request: request(
          requestedLanguage: AgentKnowledgeLanguage.pashto,
          sourceLanguage: AgentKnowledgeLanguage.pashto,
        ),
        conflictResult: readyConflict(),
      );

      expect(result.ready, true);
      expect(result.language, AgentKnowledgeLanguage.pashto);
    });

    test('English exact match is allowed', () {
      final result = policy.buildAnswerContext(
        request: request(
          requestedLanguage: AgentKnowledgeLanguage.english,
          sourceLanguage: AgentKnowledgeLanguage.english,
        ),
        conflictResult: readyConflict(),
      );

      expect(result.ready, true);
      expect(result.language, AgentKnowledgeLanguage.english);
    });

    test('privacy risk flag fails closed', () {
      final result = policy.buildAnswerContext(
        request: request(
          privacyRiskFlags: const <String>{
            AgentKnowledgeAnswerPrivacyRisk.authToken,
          },
        ),
        conflictResult: readyConflict(),
      );

      expect(
        result.status,
        AgentKnowledgeAnswerContextStatus.noContextPrivacyBlocked,
      );
      expect(result.noAnswerRequired, true);
      expect(result.citations, isEmpty);
    });

    test('all blocked privacy categories are rejected', () {
      for (final String risk in AgentKnowledgeAnswerPrivacyRisk.blocked) {
        final result = policy.buildAnswerContext(
          request: request(privacyRiskFlags: <String>{risk}),
          conflictResult: readyConflict(),
        );

        expect(
          result.status,
          AgentKnowledgeAnswerContextStatus.noContextPrivacyBlocked,
          reason: 'Risk must fail closed: $risk',
        );
      }
    });

    test('answer context citation projection drops claim value binding', () {
      final result = policy.buildAnswerContext(
        request: request(),
        conflictResult: readyConflict(),
      );

      final citation = result.citations.single;

      expect(citation.metadataOnly, true);
      expect(citation.containsClaimValueBinding, false);
      expect(citation.containsRawKnowledgeContent, false);
      expect(citation.containsRawSourcePayload, false);
      expect(citation.containsPrivatePayload, false);
      expect(citation.grantsAuthority, false);
      expect(citation.expandsScope, false);
      expect(citation.executesBusinessAction, false);
    });

    test('answer context excludes raw/private/provider payloads', () {
      final result = policy.buildAnswerContext(
        request: request(),
        conflictResult: readyConflict(),
      );

      expect(result.privacyMinimized, true);
      expect(result.exactLanguagePreserved, true);
      expect(result.automaticTranslationPerformed, false);
      expect(result.citationsMetadataOnly, true);
      expect(result.rawKnowledgeContentIncluded, false);
      expect(result.rawSourcePayloadIncluded, false);
      expect(result.rawConversationIncluded, false);
      expect(result.rawPromptIncluded, false);
      expect(result.privateIdentityIncluded, false);
      expect(result.paymentDataIncluded, false);
      expect(result.secretIncluded, false);
    });

    test('request itself contains no raw/private data and grants no scope', () {
      final value = request();

      expect(value.containsRawUserMessage, false);
      expect(value.containsRawConversation, false);
      expect(value.containsRawPrompt, false);
      expect(value.containsPhone, false);
      expect(value.containsEmail, false);
      expect(value.containsCnic, false);
      expect(value.containsAuthToken, false);
      expect(value.containsPassword, false);
      expect(value.containsPaymentCard, false);
      expect(value.containsCvv, false);
      expect(value.containsPin, false);
      expect(value.containsPreciseSensitiveLocation, false);
      expect(value.containsPrivateComplaintEvidence, false);
      expect(value.containsSecret, false);
      expect(value.automaticTranslationAllowed, false);
      expect(value.targetScopeConsumedNotGranted, true);
      expect(value.grantsScope, false);
      expect(value.expandsScope, false);
      expect(value.grantsPermission, false);
      expect(value.consumesApproval, false);
      expect(value.executesBusinessAction, false);
      expect(value.invokesProvider, false);
      expect(value.persistsRequest, false);
    });

    test('answer context executes no authority/provider/WhatsApp action', () {
      final result = policy.buildAnswerContext(
        request: request(),
        conflictResult: readyConflict(),
      );

      expect(result.grantsPermission, false);
      expect(result.expandsScope, false);
      expect(result.consumesApproval, false);
      expect(result.executesBusinessAction, false);
      expect(result.writesBusinessData, false);
      expect(result.sendsWhatsApp, false);
      expect(result.invokesProvider, false);
      expect(result.persistsProjection, false);
    });

    test('verified authorized Owner gets read-only WhatsApp projection', () {
      final answerContext = policy.buildAnswerContext(
        request: request(targetScope: AgentKnowledgeScope.owner),
        conflictResult: readyConflict(),
      );

      final projection = policy.buildOwnerWhatsAppReadProjection(
        answerContext: answerContext,
        targetRole: AgentKnowledgeOwnerWhatsAppReadRole.owner,
        whatsappIdentityVerified: true,
        roleAuthorized: true,
      );

      expect(projection, isNotNull);
      expect(projection!.readVisibilityOnly, true);
      expect(projection.verifiedIdentityRequired, true);
      expect(projection.roleAuthorizationRequired, true);
      expect(projection.sendsWhatsApp, false);
      expect(projection.executesApproval, false);
      expect(projection.executesBusinessAction, false);
    });

    test('verified authorized Admin gets read-only WhatsApp projection', () {
      final answerContext = policy.buildAnswerContext(
        request: request(targetScope: AgentKnowledgeScope.admin),
        conflictResult: readyConflict(),
      );

      final projection = policy.buildOwnerWhatsAppReadProjection(
        answerContext: answerContext,
        targetRole: AgentKnowledgeOwnerWhatsAppReadRole.admin,
        whatsappIdentityVerified: true,
        roleAuthorized: true,
      );

      expect(projection, isNotNull);
      expect(projection!.targetRole, 'admin');
    });

    test(
      'verified authorized Super Admin gets read-only WhatsApp projection',
      () {
        final answerContext = policy.buildAnswerContext(
          request: request(targetScope: AgentKnowledgeScope.superAdmin),
          conflictResult: readyConflict(),
        );

        final projection = policy.buildOwnerWhatsAppReadProjection(
          answerContext: answerContext,
          targetRole: AgentKnowledgeOwnerWhatsAppReadRole.superAdmin,
          whatsappIdentityVerified: true,
          roleAuthorized: true,
        );

        expect(projection, isNotNull);
        expect(projection!.targetRole, 'super_admin');
      },
    );

    test('unverified WhatsApp identity gets no projection', () {
      final answerContext = policy.buildAnswerContext(
        request: request(),
        conflictResult: readyConflict(),
      );

      final projection = policy.buildOwnerWhatsAppReadProjection(
        answerContext: answerContext,
        targetRole: AgentKnowledgeOwnerWhatsAppReadRole.owner,
        whatsappIdentityVerified: false,
        roleAuthorized: true,
      );

      expect(projection, isNull);
    });

    test('unauthorized WhatsApp role gets no projection', () {
      final answerContext = policy.buildAnswerContext(
        request: request(),
        conflictResult: readyConflict(),
      );

      final projection = policy.buildOwnerWhatsAppReadProjection(
        answerContext: answerContext,
        targetRole: AgentKnowledgeOwnerWhatsAppReadRole.owner,
        whatsappIdentityVerified: true,
        roleAuthorized: false,
      );

      expect(projection, isNull);
    });

    test('customer/driver cannot be Owner WhatsApp read role', () {
      final answerContext = policy.buildAnswerContext(
        request: request(),
        conflictResult: readyConflict(),
      );

      final customerProjection = policy.buildOwnerWhatsAppReadProjection(
        answerContext: answerContext,
        targetRole: 'authenticated_customer',
        whatsappIdentityVerified: true,
        roleAuthorized: true,
      );

      final driverProjection = policy.buildOwnerWhatsAppReadProjection(
        answerContext: answerContext,
        targetRole: 'driver',
        whatsappIdentityVerified: true,
        roleAuthorized: true,
      );

      expect(customerProjection, isNull);
      expect(driverProjection, isNull);
    });

    test('blocked answer context cannot be projected to WhatsApp', () {
      final answerContext = policy.buildAnswerContext(
        request: request(scopeAuthorizationVerified: false),
        conflictResult: readyConflict(),
      );

      final projection = policy.buildOwnerWhatsAppReadProjection(
        answerContext: answerContext,
        targetRole: AgentKnowledgeOwnerWhatsAppReadRole.owner,
        whatsappIdentityVerified: true,
        roleAuthorized: true,
      );

      expect(projection, isNull);
    });

    test('WhatsApp projection excludes claim binding/raw/private data', () {
      final answerContext = policy.buildAnswerContext(
        request: request(),
        conflictResult: readyConflict(),
      );

      final projection = policy.buildOwnerWhatsAppReadProjection(
        answerContext: answerContext,
        targetRole: AgentKnowledgeOwnerWhatsAppReadRole.owner,
        whatsappIdentityVerified: true,
        roleAuthorized: true,
      )!;

      expect(projection.containsSelectedClaimValueBinding, false);
      expect(projection.containsRawKnowledgeContent, false);
      expect(projection.containsRawSourcePayload, false);
      expect(projection.containsRawPrompt, false);
      expect(projection.containsRawConversation, false);
      expect(projection.containsPhone, false);
      expect(projection.containsEmail, false);
      expect(projection.containsCnic, false);
      expect(projection.containsAuthToken, false);
      expect(projection.containsPaymentData, false);
      expect(projection.containsSecret, false);
      expect(projection.sendsWhatsApp, false);
      expect(projection.executesApproval, false);
      expect(projection.grantsPermission, false);
      expect(projection.expandsScope, false);
      expect(projection.executesBusinessAction, false);
      expect(projection.writesBusinessData, false);
      expect(projection.persistsProjection, false);
    });

    test('policy locks privacy/language/grounding boundaries', () {
      expect(policy.consumesStep1EReadyConflictMetadata, true);
      expect(policy.exactLanguageMatchRequired, true);
      expect(policy.automaticTranslationDisabled, true);
      expect(policy.scopeAuthorizationMustBePreverified, true);
      expect(policy.answerContextCannotGrantScope, true);
      expect(policy.privacyRiskFailClosed, true);
      expect(policy.rawConversationExcluded, true);
      expect(policy.rawPromptExcluded, true);
      expect(policy.privateIdentityExcluded, true);
      expect(policy.paymentDataExcluded, true);
      expect(policy.secretExcluded, true);
      expect(policy.rawKnowledgeContentExcluded, true);
      expect(policy.rawSourcePayloadExcluded, true);
      expect(policy.citationMetadataRequired, true);
      expect(policy.selectedClaimBindingOpaque, true);
      expect(policy.conversationGroundingRequiredNext, true);
      expect(policy.responseGuardRequiredNext, true);
    });

    test('policy locks Owner WhatsApp read-only boundary', () {
      expect(policy.ownerWhatsAppReadVisibilityOnly, true);
      expect(policy.ownerWhatsAppIdentityVerificationRequired, true);
      expect(policy.ownerWhatsAppRoleAuthorizationRequired, true);
      expect(policy.ownerWhatsAppUsesExistingArchitecture, true);
      expect(policy.ownerWhatsAppExcludesSelectedClaimBinding, true);
      expect(policy.ownerWhatsAppExcludesPrivatePayload, true);
      expect(policy.ownerWhatsAppSendExecution, false);
      expect(policy.ownerWhatsAppApprovalExecution, false);
    });

    test('policy has no production authority/provider/persistence', () {
      expect(policy.grantsPermission, false);
      expect(policy.expandsScope, false);
      expect(policy.consumesApproval, false);
      expect(policy.executesBusinessAction, false);
      expect(policy.writesBusinessData, false);
      expect(policy.performsDatabaseSearch, false);
      expect(policy.retrievesRawKnowledgeContent, false);
      expect(policy.invokesProvider, false);
      expect(policy.persistsAnswerContext, false);
    });

    test('existing phase ownership remains separate', () {
      expect(policy.duplicatesStep1EConflictResolution, false);
      expect(policy.duplicatesConversationGrounding, false);
      expect(policy.duplicatesResponseGuard, false);
      expect(policy.duplicatesOwnerWhatsAppTransport, false);
      expect(policy.duplicatesPhase55VideoCatalog, false);
      expect(policy.implementsPhase62TrainingDeployment, false);
      expect(policy.implementsPhase63RetentionUi, false);
    });
  });
}
