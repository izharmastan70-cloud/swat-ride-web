class AgentProductionRolloutStep1GEvidence {
  AgentProductionRolloutStep1GEvidence._();

  static const String phase65SafetyEvidenceSha256 =
      'a492a9bdd54a0446b79adc66dea1144b66f2f7b7e4991464c3038f8e4f092ac0';

  static const String phase62VersionEvidenceSha256 =
      '4782e14245f09c14c87b59769d580f53ef9c6a4da50b00b0858095e0beab2b99';

  static const Duration maxFreshLoginAge = Duration(minutes: 5);

  static const Duration maxFutureAuthSkew = Duration(minutes: 1);

  static const Duration ownerApprovalValidity = Duration(minutes: 10);

  static const String requiredClaimRole = 'super_admin';

  static const String confirmationPhrase = 'MONITOR_ONLY';

  static const bool autoTrafficEnabled = false;
  static const bool businessWriteTrafficEnabled = false;
  static const bool externalChannelsEnabled = false;
}
