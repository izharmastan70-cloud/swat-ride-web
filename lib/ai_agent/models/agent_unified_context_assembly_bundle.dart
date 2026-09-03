import '../models/agent_unified_context_item.dart';

class AgentUnifiedContextAssemblyStatus {
  AgentUnifiedContextAssemblyStatus._();

  static const String ready = 'READY';
  static const String blockedRequest = 'BLOCKED_REQUEST';
}

class AgentUnifiedContextAssemblyReason {
  AgentUnifiedContextAssemblyReason._();

  static const String ready = 'context_bundle_ready';
  static const String invalidRequest = 'invalid_assembly_request';
  static const String roleChannelMismatch = 'role_channel_mismatch';
  static const String purposeNotAllowedForRole = 'purpose_not_allowed_for_role';
  static const String itemBudgetExceeded = 'item_budget_exceeded';
  static const String characterBudgetExceeded = 'character_budget_exceeded';
  static const String duplicateContextId = 'duplicate_context_id';
}

class AgentUnifiedContextAssemblyBundle {
  AgentUnifiedContextAssemblyBundle({
    required this.status,
    required this.reasonCode,
    required this.requestId,
    required this.requestingSubjectRef,
    required this.requestedPurpose,
    required List<AgentUnifiedContextItem> selectedItems,
    required Map<String, String> rejectedReasonsByContextId,
    required this.totalSanitizedCharacters,
  }) : selectedItems = List<AgentUnifiedContextItem>.unmodifiable(
         selectedItems,
       ),
       rejectedReasonsByContextId = Map<String, String>.unmodifiable(
         rejectedReasonsByContextId,
       );

  final String status;
  final String reasonCode;
  final String requestId;
  final String requestingSubjectRef;
  final String requestedPurpose;
  final List<AgentUnifiedContextItem> selectedItems;
  final Map<String, String> rejectedReasonsByContextId;
  final int totalSanitizedCharacters;

  bool get ready => status == AgentUnifiedContextAssemblyStatus.ready;
  bool get blockedRequest =>
      status == AgentUnifiedContextAssemblyStatus.blockedRequest;

  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get invokesRuntimeGate => false;
  bool get writesBusinessData => false;
  bool get persistsBundle => false;
  bool get containsRawMessageHistory => selectedItems.any(
    (AgentUnifiedContextItem item) => item.containsRawMessageHistory,
  );
  bool get containsRawSecret => selectedItems.any(
    (AgentUnifiedContextItem item) => item.containsRawSecret,
  );
  bool get containsPaymentCredential => selectedItems.any(
    (AgentUnifiedContextItem item) => item.containsPaymentCredential,
  );
  bool get containsAuthToken => selectedItems.any(
    (AgentUnifiedContextItem item) => item.containsAuthToken,
  );

  Map<String, dynamic> toSafeMetadataMap() {
    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'reasonCode': reasonCode,
      'requestId': requestId,
      'requestingSubjectRef': requestingSubjectRef,
      'requestedPurpose': requestedPurpose,
      'selectedContextIds': List<String>.unmodifiable(
        selectedItems.map((AgentUnifiedContextItem item) => item.contextId),
      ),
      'selectedItemCount': selectedItems.length,
      'rejectedItemCount': rejectedReasonsByContextId.length,
      'totalSanitizedCharacters': totalSanitizedCharacters,
      'sanitizedValuesIncluded': false,
      'containsRawMessageHistory': containsRawMessageHistory,
      'containsRawSecret': containsRawSecret,
      'containsPaymentCredential': containsPaymentCredential,
      'containsAuthToken': containsAuthToken,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'invokesProvider': false,
      'invokesTargetAgent': false,
      'invokesRuntimeGate': false,
      'writesBusinessData': false,
      'persistsBundle': false,
    });
  }
}
