import '../constants/agent_content_generation_contract_constants.dart';
import 'agent_content_generation_request.dart';
import 'agent_content_generation_request_decision.dart';

class AgentContentOwnerWhatsAppReviewProjection {
  AgentContentOwnerWhatsAppReviewProjection({
    required this.requestId,
    required this.draftType,
    required this.platform,
    required this.module,
    required this.audience,
    required this.language,
    required this.reviewState,
    required this.purposeSummary,
    required this.createdAt,
  });

  final String requestId;
  final String draftType;
  final String platform;
  final String module;
  final String audience;
  final String language;
  final String reviewState;
  final String purposeSummary;
  final DateTime createdAt;

  factory AgentContentOwnerWhatsAppReviewProjection.fromRequest({
    required AgentContentGenerationRequest request,
    required AgentContentGenerationRequestDecision decision,
  }) {
    request.validateStructure();
    decision.validateStructure();

    if (!decision.accepted ||
        !decision.ownerWhatsAppReviewEligible ||
        request.reviewChannel != AgentContentReviewChannel.ownerWhatsApp) {
      throw const AgentContentOwnerWhatsAppReviewProjectionException(
        'Content request is not eligible for Owner/Admin WhatsApp review.',
      );
    }

    return AgentContentOwnerWhatsAppReviewProjection(
      requestId: request.requestId,
      draftType: request.draftType,
      platform: request.platform,
      module: request.module,
      audience: request.audience,
      language: request.language,
      reviewState: AgentContentReviewState.reviewRequired,
      purposeSummary: request.purpose,
      createdAt: request.createdAt,
    );
  }

  bool get ownerOrAuthorizedAdminOnly => true;
  bool get requiresVerifiedWhatsAppIdentity => true;
  bool get requiresRoleAuthorization => true;
  bool get reviewVisibilityOnly => true;
  bool get containsRawPrompt => false;
  bool get containsSourcePayload => false;
  bool get containsSecrets => false;
  bool get containsPaymentData => false;
  bool get containsPrivateAccountData => false;
  bool get sendsWhatsAppMessage => false;
  bool get executesApproval => false;
  bool get publishesContent => false;
  bool get schedulesContent => false;
  bool get executesBusinessAction => false;
  bool get grantsAuthority => false;
  bool get persistsProjection => false;
}

class AgentContentOwnerWhatsAppReviewProjectionException implements Exception {
  const AgentContentOwnerWhatsAppReviewProjectionException(this.message);
  final String message;

  @override
  String toString() =>
      'AgentContentOwnerWhatsAppReviewProjectionException: $message';
}
