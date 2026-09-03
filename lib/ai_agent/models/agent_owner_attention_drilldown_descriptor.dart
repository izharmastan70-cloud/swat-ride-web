class AgentOwnerAttentionDrilldownDescriptor {
  const AgentOwnerAttentionDrilldownDescriptor({
    required this.sourceLabel,
    required this.routeKey,
    required this.reviewInstruction,
  });

  final String sourceLabel;
  final String routeKey;
  final String reviewInstruction;

  bool get informationalOnly => true;
  bool get rawSourcePayloadIncluded => false;
  bool get sourceActionExecuted => false;
  bool get approvalConsumed => false;
  bool get permissionGranted => false;
  bool get businessWritePerformed => false;
}
