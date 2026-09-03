class AgentOwnerAttentionSourceMappingDecision {
  AgentOwnerAttentionSourceMappingDecision({
    required this.category,
    required this.minimumPriority,
    required this.reasonCode,
  });

  final String category;
  final String minimumPriority;
  final String reasonCode;

  bool get mappingOnly => true;
  bool get executionAuthorityGranted => false;
}
