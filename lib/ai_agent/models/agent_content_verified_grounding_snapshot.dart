import '../constants/agent_content_grounding_constants.dart';

class AgentContentVerifiedGroundingSnapshot {
  AgentContentVerifiedGroundingSnapshot({
    required this.module,
    required this.feature,
    required this.featureVerified,
    required this.featureStable,
    required this.approvedForCommunication,
    required this.serviceEnabled,
    required this.sourceFresh,
    required List<String> sourceReferenceIds,
    required Set<String> verifiedClaimKeys,
    required this.verifiedAt,
  }) : sourceReferenceIds = List<String>.unmodifiable(sourceReferenceIds),
       verifiedClaimKeys = Set<String>.unmodifiable(verifiedClaimKeys);

  final String module;
  final String feature;
  final bool featureVerified;
  final bool featureStable;
  final bool approvedForCommunication;
  final bool serviceEnabled;
  final bool sourceFresh;
  final List<String> sourceReferenceIds;
  final Set<String> verifiedClaimKeys;
  final DateTime verifiedAt;

  bool get structuredVerifiedDataOnly => true;
  bool get generatedTextIsSourceOfTruth => false;
  bool get rawPromptIsSourceOfTruth => false;
  bool get providerOutputIsSourceOfTruth => false;
  bool get grantsAuthority => false;
  bool get writesBusinessData => false;
  bool get persistsSnapshot => false;

  void validateStructure() {
    if (module.trim().isEmpty || module.length > 100) {
      throw const AgentContentVerifiedGroundingSnapshotException(
        'Grounding module is invalid.',
      );
    }

    if (feature.trim().isEmpty || feature.length > 120) {
      throw const AgentContentVerifiedGroundingSnapshotException(
        'Grounding feature is invalid.',
      );
    }

    if (sourceReferenceIds.length >
        AgentContentGroundingLimits.sourceReferenceMax) {
      throw const AgentContentVerifiedGroundingSnapshotException(
        'Too many grounding source references.',
      );
    }

    for (final String sourceId in sourceReferenceIds) {
      final String trimmed = sourceId.trim();

      if (trimmed.isEmpty ||
          trimmed.length >
              AgentContentGroundingLimits.sourceReferenceLengthMax ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed)) {
        throw const AgentContentVerifiedGroundingSnapshotException(
          'Grounding source reference is invalid.',
        );
      }
    }

    if (verifiedClaimKeys.length > AgentContentGroundingLimits.claimCountMax) {
      throw const AgentContentVerifiedGroundingSnapshotException(
        'Too many verified grounding claims.',
      );
    }

    for (final String claim in verifiedClaimKeys) {
      if (!AgentContentVerifiedClaimKey.values.contains(claim)) {
        throw const AgentContentVerifiedGroundingSnapshotException(
          'Grounding verified claim key is unsupported.',
        );
      }
    }
  }
}

class AgentContentVerifiedGroundingSnapshotException implements Exception {
  const AgentContentVerifiedGroundingSnapshotException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentContentVerifiedGroundingSnapshotException: $message';
}
