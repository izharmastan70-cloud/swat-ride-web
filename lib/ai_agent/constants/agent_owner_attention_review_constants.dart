class AgentOwnerAttentionReviewRole {
  AgentOwnerAttentionReviewRole._();

  static const String owner = 'OWNER';
  static const String superAdmin = 'SUPER_ADMIN';

  static const Set<String> values = <String>{owner, superAdmin};
}

class AgentOwnerAttentionRepositoryLimits {
  AgentOwnerAttentionRepositoryLimits._();

  static const int recentLimitMax = 200;
  static const int reviewerRefMaxLength = 220;
}
