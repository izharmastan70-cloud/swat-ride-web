import '../constants/agent_unified_context_constants.dart';
import '../models/agent_unified_context_assembly_bundle.dart';
import '../models/agent_unified_context_conflict_resolution_result.dart';
import '../models/agent_unified_context_item.dart';

class AgentUnifiedContextConflictResolutionService {
  const AgentUnifiedContextConflictResolutionService();

  static final RegExp _safeConflictKeyPattern = RegExp(
    r'^[A-Za-z0-9._:-]{1,100}$',
  );

  AgentUnifiedContextConflictResolutionResult resolve({
    required AgentUnifiedContextAssemblyBundle sourceBundle,
    required Map<String, String> conflictKeyByContextId,
    required DateTime now,
  }) {
    if (!sourceBundle.ready) {
      return _blocked(
        sourceBundle: sourceBundle,
        reasonCode:
            AgentUnifiedContextConflictResolutionReason.sourceBundleNotReady,
      );
    }

    for (final AgentUnifiedContextItem item in sourceBundle.selectedItems) {
      final String? conflictKey = conflictKeyByContextId[item.contextId];

      if (conflictKey == null || conflictKey.trim().isEmpty) {
        return _blocked(
          sourceBundle: sourceBundle,
          reasonCode:
              AgentUnifiedContextConflictResolutionReason.missingConflictKey,
        );
      }

      if (!_safeConflictKeyPattern.hasMatch(conflictKey)) {
        return _blocked(
          sourceBundle: sourceBundle,
          reasonCode:
              AgentUnifiedContextConflictResolutionReason.invalidConflictKey,
        );
      }
    }

    final Map<String, List<AgentUnifiedContextItem>> groups =
        <String, List<AgentUnifiedContextItem>>{};

    for (final AgentUnifiedContextItem item in sourceBundle.selectedItems) {
      final String conflictKey = conflictKeyByContextId[item.contextId]!;

      groups
          .putIfAbsent(conflictKey, () => <AgentUnifiedContextItem>[])
          .add(item);
    }

    final List<AgentUnifiedContextItem> selected = <AgentUnifiedContextItem>[];

    final Map<String, String> resolutionReasons = <String, String>{};

    final Set<String> unresolved = <String>{};

    final Map<String, String> rejectedReasons = <String, String>{};

    final List<String> orderedKeys = groups.keys.toList()..sort();

    for (final String conflictKey in orderedKeys) {
      final List<AgentUnifiedContextItem> fresh = <AgentUnifiedContextItem>[];

      for (final AgentUnifiedContextItem item in groups[conflictKey]!) {
        if (item.capturedAt.isAfter(now)) {
          rejectedReasons[item.contextId] =
              AgentUnifiedContextConflictResolutionReason.futureDatedCandidate;
          continue;
        }

        if (!now.isBefore(item.expiresAt)) {
          rejectedReasons[item.contextId] =
              AgentUnifiedContextConflictResolutionReason.expiredCandidate;
          continue;
        }

        fresh.add(item);
      }

      if (fresh.isEmpty) {
        resolutionReasons[conflictKey] =
            AgentUnifiedContextConflictResolutionReason.noFreshCandidate;
        continue;
      }

      final int highestTrustRank = fresh
          .map((AgentUnifiedContextItem item) => _trustRank(item.sourceTrust))
          .reduce((int a, int b) => a > b ? a : b);

      final List<AgentUnifiedContextItem> highestTrustItems = fresh
          .where(
            (AgentUnifiedContextItem item) =>
                _trustRank(item.sourceTrust) == highestTrustRank,
          )
          .toList();

      DateTime latestCapture = highestTrustItems.first.capturedAt;

      for (final AgentUnifiedContextItem item in highestTrustItems.skip(1)) {
        if (item.capturedAt.isAfter(latestCapture)) {
          latestCapture = item.capturedAt;
        }
      }

      final List<AgentUnifiedContextItem> topTier =
          highestTrustItems
              .where(
                (AgentUnifiedContextItem item) =>
                    item.capturedAt.isAtSameMomentAs(latestCapture),
              )
              .toList()
            ..sort(
              (AgentUnifiedContextItem a, AgentUnifiedContextItem b) =>
                  a.contextId.compareTo(b.contextId),
            );

      final Set<String> topTierValues = topTier
          .map((AgentUnifiedContextItem item) => item.sanitizedValue.trim())
          .toSet();

      if (topTierValues.length > 1) {
        unresolved.add(conflictKey);
        resolutionReasons[conflictKey] =
            AgentUnifiedContextConflictResolutionReason.exactTieUnresolved;
        continue;
      }

      final AgentUnifiedContextItem winner = topTier.first;
      selected.add(winner);

      final Set<String> allValues = fresh
          .map((AgentUnifiedContextItem item) => item.sanitizedValue.trim())
          .toSet();

      if (fresh.length == 1) {
        resolutionReasons[conflictKey] =
            AgentUnifiedContextConflictResolutionReason.noConflict;
        continue;
      }

      if (allValues.length == 1) {
        resolutionReasons[conflictKey] =
            AgentUnifiedContextConflictResolutionReason.identicalDuplicate;
        continue;
      }

      final bool newerResolvedSameTrust = highestTrustItems.any(
        (AgentUnifiedContextItem item) =>
            item.capturedAt.isBefore(latestCapture) &&
            item.sanitizedValue.trim() != winner.sanitizedValue.trim(),
      );

      if (newerResolvedSameTrust) {
        resolutionReasons[conflictKey] =
            AgentUnifiedContextConflictResolutionReason.newerSameTrust;
        continue;
      }

      final bool lowerTrustConflict = fresh.any(
        (AgentUnifiedContextItem item) =>
            _trustRank(item.sourceTrust) < highestTrustRank &&
            item.sanitizedValue.trim() != winner.sanitizedValue.trim(),
      );

      if (lowerTrustConflict) {
        resolutionReasons[conflictKey] =
            AgentUnifiedContextConflictResolutionReason.trustPrecedence;
        continue;
      }

      resolutionReasons[conflictKey] =
          AgentUnifiedContextConflictResolutionReason.identicalDuplicate;
    }

    final String status = unresolved.isEmpty
        ? AgentUnifiedContextConflictResolutionStatus.ready
        : AgentUnifiedContextConflictResolutionStatus
              .readyWithUnresolvedConflicts;

    return AgentUnifiedContextConflictResolutionResult(
      status: status,
      requestId: sourceBundle.requestId,
      requestingSubjectRef: sourceBundle.requestingSubjectRef,
      requestedPurpose: sourceBundle.requestedPurpose,
      selectedItems: selected,
      resolutionReasonByConflictKey: resolutionReasons,
      unresolvedConflictKeys: unresolved,
      rejectedReasonsByContextId: rejectedReasons,
    );
  }

  int _trustRank(String sourceTrust) {
    switch (sourceTrust) {
      case AgentUnifiedContextSourceTrust.verifiedSystem:
        return 5;
      case AgentUnifiedContextSourceTrust.verifiedIdentityBound:
        return 4;
      case AgentUnifiedContextSourceTrust.userAsserted:
        return 3;
      case AgentUnifiedContextSourceTrust.derivedSummary:
        return 2;
      case AgentUnifiedContextSourceTrust.untrustedExternal:
        return 1;
      default:
        return 0;
    }
  }

  AgentUnifiedContextConflictResolutionResult _blocked({
    required AgentUnifiedContextAssemblyBundle sourceBundle,
    required String reasonCode,
  }) {
    return AgentUnifiedContextConflictResolutionResult(
      status: AgentUnifiedContextConflictResolutionStatus.blocked,
      requestId: sourceBundle.requestId,
      requestingSubjectRef: sourceBundle.requestingSubjectRef,
      requestedPurpose: sourceBundle.requestedPurpose,
      selectedItems: const <AgentUnifiedContextItem>[],
      resolutionReasonByConflictKey: <String, String>{
        '__request__': reasonCode,
      },
      unresolvedConflictKeys: const <String>{},
      rejectedReasonsByContextId: const <String, String>{},
    );
  }

  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get invokesRuntimeGate => false;
  bool get writesBusinessData => false;
  bool get persistsContext => false;
  bool get persistsResolution => false;
  bool get loadsFullConversationHistory => false;
  bool get loadsCrossSubjectContext => false;
  bool get mutatesSourceBundle => false;
  bool get mergesConflictingValues => false;
}
