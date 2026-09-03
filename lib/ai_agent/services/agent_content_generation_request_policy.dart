import '../constants/agent_content_generation_contract_constants.dart';
import '../models/agent_content_generation_request.dart';
import '../models/agent_content_generation_request_decision.dart';

class AgentContentGenerationRequestPolicy {
  const AgentContentGenerationRequestPolicy();

  AgentContentGenerationRequestDecision evaluate(
    AgentContentGenerationRequest request,
  ) {
    try {
      request.validateStructure();
    } catch (_) {
      return _decision(
        status: AgentContentRequestStatus.blockedInvalidRequest,
        requestId: _safeId(request.requestId),
        draftType: request.draftType.trim(),
        platform: request.platform.trim(),
        ownerWhatsAppReviewEligible: false,
        reasons: const <String>[
          'invalid_request_structure',
          'draft_only_boundary',
          'human_review_required',
          'no_direct_publish_or_send',
        ],
      );
    }

    if (AgentContentDraftType.socialPlatformRequired.contains(
          request.draftType,
        ) &&
        request.platform == AgentContentPlatform.none) {
      return _decision(
        status: AgentContentRequestStatus.blockedMissingSocialPlatform,
        requestId: request.requestId,
        draftType: request.draftType,
        platform: request.platform,
        ownerWhatsAppReviewEligible: false,
        reasons: const <String>[
          'social_platform_required',
          'draft_only_boundary',
          'human_review_required',
          'no_direct_publish_or_send',
        ],
      );
    }

    if (_containsSensitiveExecutionIntent(
      '${request.purpose} ${request.brief}',
    )) {
      return _decision(
        status: AgentContentRequestStatus.blockedSensitiveExecutionIntent,
        requestId: request.requestId,
        draftType: request.draftType,
        platform: request.platform,
        ownerWhatsAppReviewEligible: false,
        reasons: const <String>[
          'sensitive_execution_intent_blocked',
          'content_is_not_business_authority',
          'draft_only_boundary',
          'human_review_required',
          'no_direct_publish_or_send',
        ],
      );
    }

    return _decision(
      status: AgentContentRequestStatus.acceptedDraftOnly,
      requestId: request.requestId,
      draftType: request.draftType,
      platform: request.platform,
      ownerWhatsAppReviewEligible:
          request.reviewChannel == AgentContentReviewChannel.ownerWhatsApp,
      reasons: const <String>[
        'safe_draft_type',
        'bounded_request_metadata',
        'human_review_required',
        'draft_only_boundary',
        'no_direct_publish_or_send',
        'content_is_not_business_authority',
      ],
    );
  }

  bool _containsSensitiveExecutionIntent(String value) {
    final String normalized = value.toLowerCase();
    const List<String> blocked = <String>[
      'execute refund',
      'refund now',
      'change wallet',
      'wallet balance',
      'change price',
      'change fare',
      'approve driver',
      'approve registration',
      'grant permission',
      'change permission',
      'disable user',
      'suspend user',
      'book ride now',
      'place order now',
      'publish now',
      'post now',
      'send now',
      'auto publish',
      'auto send',
    ];
    return blocked.any(normalized.contains);
  }

  AgentContentGenerationRequestDecision _decision({
    required String status,
    required String requestId,
    required String draftType,
    required String platform,
    required bool ownerWhatsAppReviewEligible,
    required List<String> reasons,
  }) {
    final AgentContentGenerationRequestDecision decision =
        AgentContentGenerationRequestDecision(
          status: status,
          requestId: requestId,
          normalizedDraftType: draftType,
          normalizedPlatform: platform,
          reviewRequired: status == AgentContentRequestStatus.acceptedDraftOnly,
          ownerWhatsAppReviewEligible: ownerWhatsAppReviewEligible,
          reasonCodes: reasons,
        );
    decision.validateStructure();
    return decision;
  }

  String _safeId(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return 'invalid_request';
    if (trimmed.length <= 180) return trimmed;
    return trimmed.substring(0, 180);
  }

  bool get draftOnly => true;
  bool get supportsOwnerAdminWhatsAppReviewVisibility => true;
  bool get reusesExistingOwnerWhatsAppSecurity => true;
  bool get reusesExistingApprovalArchitecture => true;
  bool get reusesExistingGroundingArchitecture => true;
  bool get duplicatesEmailTransport => false;
  bool get duplicatesWhatsAppTransport => false;
  bool get autoPublishes => false;
  bool get autoSchedules => false;
  bool get sendsWhatsApp => false;
  bool get sendsEmail => false;
  bool get postsSocialMedia => false;
  bool get executesApproval => false;
  bool get executesBusinessAction => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;
  bool get persistsRequest => false;
  bool get implementsPhase57KnowledgeLibrary => false;
  bool get implementsPhase62SelfDeployment => false;
  bool get implementsPhase63PrivacyUi => false;
}
