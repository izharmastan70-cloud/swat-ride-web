import '../constants/agent_content_grounding_constants.dart';
import '../models/agent_content_grounding_decision.dart';
import '../models/agent_content_platform_draft_package.dart';
import '../models/agent_content_verified_grounding_snapshot.dart';

class AgentContentGroundingGate {
  const AgentContentGroundingGate();

  AgentContentGroundingDecision evaluate({
    required AgentContentPlatformDraftPackage draftPackage,
    required AgentContentVerifiedGroundingSnapshot snapshot,
    required Set<String> declaredClaimKeys,
  }) {
    try {
      draftPackage.validateStructure();
      snapshot.validateStructure();
    } catch (_) {
      return _blocked(
        status: AgentContentGroundingStatus.needsSource,
        draftPackage: draftPackage,
        snapshot: snapshot,
        reasons: const <String>[
          AgentContentGroundingReason.verifiedSourceReferenceRequired,
          AgentContentGroundingReason.noGeneratedFactAuthority,
          AgentContentGroundingReason.humanReviewRequired,
          AgentContentGroundingReason.noPublishAuthority,
        ],
      );
    }

    if (!draftPackage.readyForHumanReview) {
      return _blocked(
        status: AgentContentGroundingStatus.blockedStep1CPackage,
        draftPackage: draftPackage,
        snapshot: snapshot,
        reasons: const <String>[
          AgentContentGroundingReason.step1CReadyRequired,
          AgentContentGroundingReason.humanReviewRequired,
          AgentContentGroundingReason.noPublishAuthority,
        ],
      );
    }

    if (!snapshot.featureVerified) {
      return _blocked(
        status: AgentContentGroundingStatus.blockedUnverifiedFeature,
        draftPackage: draftPackage,
        snapshot: snapshot,
        reasons: const <String>[
          AgentContentGroundingReason.verifiedFeatureRequired,
          AgentContentGroundingReason.noGeneratedFactAuthority,
          AgentContentGroundingReason.humanReviewRequired,
          AgentContentGroundingReason.noPublishAuthority,
        ],
      );
    }

    if (!snapshot.featureStable) {
      return _blocked(
        status: AgentContentGroundingStatus.blockedUnstableFeature,
        draftPackage: draftPackage,
        snapshot: snapshot,
        reasons: const <String>[
          AgentContentGroundingReason.stableFeatureRequired,
          AgentContentGroundingReason.noGeneratedFactAuthority,
          AgentContentGroundingReason.humanReviewRequired,
          AgentContentGroundingReason.noPublishAuthority,
        ],
      );
    }

    if (!snapshot.approvedForCommunication) {
      return _blocked(
        status: AgentContentGroundingStatus.blockedUnapprovedFeature,
        draftPackage: draftPackage,
        snapshot: snapshot,
        reasons: const <String>[
          AgentContentGroundingReason.communicationApprovalRequired,
          AgentContentGroundingReason.noGeneratedFactAuthority,
          AgentContentGroundingReason.humanReviewRequired,
          AgentContentGroundingReason.noPublishAuthority,
        ],
      );
    }

    if (!snapshot.serviceEnabled) {
      return _blocked(
        status: AgentContentGroundingStatus.blockedServiceDisabled,
        draftPackage: draftPackage,
        snapshot: snapshot,
        reasons: const <String>[
          AgentContentGroundingReason.enabledServiceRequired,
          AgentContentGroundingReason.noGeneratedFactAuthority,
          AgentContentGroundingReason.humanReviewRequired,
          AgentContentGroundingReason.noPublishAuthority,
        ],
      );
    }

    if (!snapshot.sourceFresh) {
      return _blocked(
        status: AgentContentGroundingStatus.blockedSourceStale,
        draftPackage: draftPackage,
        snapshot: snapshot,
        reasons: const <String>[
          AgentContentGroundingReason.freshSourceRequired,
          AgentContentGroundingReason.noGeneratedFactAuthority,
          AgentContentGroundingReason.humanReviewRequired,
          AgentContentGroundingReason.noPublishAuthority,
        ],
      );
    }

    if (snapshot.sourceReferenceIds.isEmpty) {
      return _blocked(
        status: AgentContentGroundingStatus.needsSource,
        draftPackage: draftPackage,
        snapshot: snapshot,
        reasons: const <String>[
          AgentContentGroundingReason.verifiedSourceReferenceRequired,
          AgentContentGroundingReason.noGeneratedFactAuthority,
          AgentContentGroundingReason.humanReviewRequired,
          AgentContentGroundingReason.noPublishAuthority,
        ],
      );
    }

    if (declaredClaimKeys.isEmpty) {
      return _blocked(
        status: AgentContentGroundingStatus.needsSource,
        draftPackage: draftPackage,
        snapshot: snapshot,
        reasons: const <String>[
          AgentContentGroundingReason.declaredClaimsRequired,
          AgentContentGroundingReason.noGeneratedFactAuthority,
          AgentContentGroundingReason.humanReviewRequired,
          AgentContentGroundingReason.noPublishAuthority,
        ],
      );
    }

    if (declaredClaimKeys.length > AgentContentGroundingLimits.claimCountMax) {
      return _blocked(
        status: AgentContentGroundingStatus.blockedUnsupportedClaim,
        draftPackage: draftPackage,
        snapshot: snapshot,
        reasons: const <String>[
          AgentContentGroundingReason.unsupportedClaimBlocked,
          AgentContentGroundingReason.humanReviewRequired,
          AgentContentGroundingReason.noPublishAuthority,
        ],
      );
    }

    for (final String claim in declaredClaimKeys) {
      if (!AgentContentVerifiedClaimKey.values.contains(claim)) {
        return _blocked(
          status: AgentContentGroundingStatus.blockedUnsupportedClaim,
          draftPackage: draftPackage,
          snapshot: snapshot,
          reasons: const <String>[
            AgentContentGroundingReason.unsupportedClaimBlocked,
            AgentContentGroundingReason.noGeneratedFactAuthority,
            AgentContentGroundingReason.humanReviewRequired,
            AgentContentGroundingReason.noPublishAuthority,
          ],
        );
      }
    }

    if (!snapshot.verifiedClaimKeys.containsAll(declaredClaimKeys)) {
      return _blocked(
        status: AgentContentGroundingStatus.needsSource,
        draftPackage: draftPackage,
        snapshot: snapshot,
        reasons: const <String>[
          AgentContentGroundingReason.allClaimsMustBeVerified,
          AgentContentGroundingReason.verifiedSourceReferenceRequired,
          AgentContentGroundingReason.noGeneratedFactAuthority,
          AgentContentGroundingReason.humanReviewRequired,
          AgentContentGroundingReason.noPublishAuthority,
        ],
      );
    }

    final AgentContentGroundingDecision decision =
        AgentContentGroundingDecision(
          status: AgentContentGroundingStatus.groundedReadyForHumanReview,
          requestId: draftPackage.requestId,
          module: snapshot.module,
          feature: snapshot.feature,
          humanReviewRequired: true,
          ownerWhatsAppReviewEligible: draftPackage.ownerWhatsAppReviewEligible,
          verifiedClaimKeys: declaredClaimKeys,
          sourceReferenceIds: snapshot.sourceReferenceIds,
          reasonCodes: const <String>[
            AgentContentGroundingReason.existingGroundingReused,
            AgentContentGroundingReason.existingQualityReused,
            AgentContentGroundingReason.existingResponseGuardReused,
            AgentContentGroundingReason.allClaimsMustBeVerified,
            AgentContentGroundingReason.humanReviewRequired,
            AgentContentGroundingReason.noGeneratedFactAuthority,
            AgentContentGroundingReason.noPublishAuthority,
          ],
        );

    decision.validateStructure();
    return decision;
  }

  AgentContentGroundingDecision _blocked({
    required String status,
    required AgentContentPlatformDraftPackage draftPackage,
    required AgentContentVerifiedGroundingSnapshot snapshot,
    required List<String> reasons,
  }) {
    final AgentContentGroundingDecision decision =
        AgentContentGroundingDecision(
          status: status,
          requestId: _safeId(draftPackage.requestId),
          module: snapshot.module.trim(),
          feature: snapshot.feature.trim(),
          humanReviewRequired: true,
          ownerWhatsAppReviewEligible: false,
          verifiedClaimKeys: const <String>{},
          sourceReferenceIds: const <String>[],
          reasonCodes: reasons,
        );

    decision.validateStructure();
    return decision;
  }

  String _safeId(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'invalid_content_request';
    }

    if (trimmed.length <= 180) {
      return trimmed;
    }

    return trimmed.substring(0, 180);
  }

  bool get reusesExistingConversationGrounding => true;
  bool get reusesExistingConversationQuality => true;
  bool get reusesExistingResponseGuard => true;
  bool get duplicatesGroundingEngine => false;
  bool get verifiedStructuredSourcesRequired => true;
  bool get featureMustBeVerified => true;
  bool get featureMustBeStable => true;
  bool get featureMustBeApprovedForCommunication => true;
  bool get disabledServicePromotionBlocked => true;
  bool get staleSourceBlocked => true;
  bool get unsupportedClaimBlocked => true;
  bool get unverifiedClaimNeedsSource => true;
  bool get highSensitivityClaimsRequireVerification => true;
  bool get generatedTextIsNeverFactAuthority => true;
  bool get humanReviewAlwaysRequired => true;
  bool get ownerWhatsAppReviewOnlyAfterGrounding => true;
  bool get autoPublishes => false;
  bool get autoSchedules => false;
  bool get postsSocialMedia => false;
  bool get sendsWhatsApp => false;
  bool get invokesProvider => false;
  bool get executesApproval => false;
  bool get executesBusinessAction => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get writesBusinessData => false;
  bool get persistsGrounding => false;
  bool get implementsPhase57KnowledgeLibrary => false;
  bool get implementsPhase62SelfDeployment => false;
  bool get implementsPhase63PrivacyUi => false;
}
