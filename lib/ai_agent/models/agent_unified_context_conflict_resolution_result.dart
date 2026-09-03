import 'agent_unified_context_item.dart';

class AgentUnifiedContextConflictResolutionStatus {
  AgentUnifiedContextConflictResolutionStatus._();

  static const String ready = 'READY';
  static const String readyWithUnresolvedConflicts =
      'READY_WITH_UNRESOLVED_CONFLICTS';
  static const String blocked = 'BLOCKED';
}

class AgentUnifiedContextConflictResolutionReason {
  AgentUnifiedContextConflictResolutionReason._();

  static const String sourceBundleNotReady = 'source_bundle_not_ready';
  static const String missingConflictKey = 'missing_conflict_key';
  static const String invalidConflictKey = 'invalid_conflict_key';
  static const String noFreshCandidate = 'no_fresh_candidate';
  static const String noConflict = 'no_conflict';
  static const String identicalDuplicate = 'identical_duplicate';
  static const String trustPrecedence = 'trust_precedence';
  static const String newerSameTrust = 'newer_same_trust';
  static const String exactTieUnresolved = 'exact_tie_unresolved';
  static const String expiredCandidate = 'expired_candidate';
  static const String futureDatedCandidate = 'future_dated_candidate';
}

class AgentUnifiedContextConflictResolutionResult {
  AgentUnifiedContextConflictResolutionResult({
    required this.status,
    required this.requestId,
    required this.requestingSubjectRef,
    required this.requestedPurpose,
    required List<AgentUnifiedContextItem> selectedItems,
    required Map<String, String> resolutionReasonByConflictKey,
    required Set<String> unresolvedConflictKeys,
    required Map<String, String> rejectedReasonsByContextId,
  }) : selectedItems = List<AgentUnifiedContextItem>.unmodifiable(
         selectedItems,
       ),
       resolutionReasonByConflictKey = Map<String, String>.unmodifiable(
         resolutionReasonByConflictKey,
       ),
       unresolvedConflictKeys = Set<String>.unmodifiable(
         unresolvedConflictKeys,
       ),
       rejectedReasonsByContextId = Map<String, String>.unmodifiable(
         rejectedReasonsByContextId,
       );

  final String status;
  final String requestId;
  final String requestingSubjectRef;
  final String requestedPurpose;
  final List<AgentUnifiedContextItem> selectedItems;
  final Map<String, String> resolutionReasonByConflictKey;
  final Set<String> unresolvedConflictKeys;
  final Map<String, String> rejectedReasonsByContextId;

  bool get ready =>
      status == AgentUnifiedContextConflictResolutionStatus.ready ||
      status ==
          AgentUnifiedContextConflictResolutionStatus
              .readyWithUnresolvedConflicts;

  bool get blocked =>
      status == AgentUnifiedContextConflictResolutionStatus.blocked;

  bool get hasUnresolvedConflicts => unresolvedConflictKeys.isNotEmpty;

  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get invokesRuntimeGate => false;
  bool get writesBusinessData => false;
  bool get persistsResolution => false;
  bool get mutatesSourceBundle => false;
  bool get mergesConflictingValues => false;

  Map<String, dynamic> toSafeMetadataMap() {
    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'requestId': requestId,
      'requestingSubjectRef': requestingSubjectRef,
      'requestedPurpose': requestedPurpose,
      'selectedContextIds': List<String>.unmodifiable(
        selectedItems.map((AgentUnifiedContextItem item) => item.contextId),
      ),
      'selectedItemCount': selectedItems.length,
      'unresolvedConflictKeys': List<String>.unmodifiable(
        unresolvedConflictKeys.toList()..sort(),
      ),
      'rejectedItemCount': rejectedReasonsByContextId.length,
      'sanitizedValuesIncluded': false,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'invokesProvider': false,
      'invokesTargetAgent': false,
      'invokesRuntimeGate': false,
      'writesBusinessData': false,
      'persistsResolution': false,
      'mutatesSourceBundle': false,
      'mergesConflictingValues': false,
    });
  }
}
