class AgentOwnerAttentionInboxBadges {
  const AgentOwnerAttentionInboxBadges({
    required this.pendingReview,
    required this.criticalOrEmergency,
    required this.inReview,
    required this.totalOpen,
  });

  final int pendingReview;
  final int criticalOrEmergency;
  final int inReview;
  final int totalOpen;

  bool get hasUrgentAttention => criticalOrEmergency > 0;

  void validate() {
    if (pendingReview < 0 ||
        criticalOrEmergency < 0 ||
        inReview < 0 ||
        totalOpen < 0) {
      throw const FormatException(
        'Owner Attention badge counts cannot be negative.',
      );
    }
  }
}
