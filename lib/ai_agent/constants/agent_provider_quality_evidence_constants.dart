class AgentProviderQualityEvidenceStatus {
  AgentProviderQualityEvidenceStatus._();

  static const String accepted = 'ACCEPTED';
  static const String rejectedInvalidProvenance = 'REJECTED_INVALID_PROVENANCE';
  static const String rejectedDuplicate = 'REJECTED_DUPLICATE';
  static const String rejectedUntrusted = 'REJECTED_UNTRUSTED';
  static const String rejectedPrivacyUnsafe = 'REJECTED_PRIVACY_UNSAFE';

  static const Set<String> values = <String>{
    accepted,
    rejectedInvalidProvenance,
    rejectedDuplicate,
    rejectedUntrusted,
    rejectedPrivacyUnsafe,
  };
}

class AgentProviderQualityCalibrationStatus {
  AgentProviderQualityCalibrationStatus._();

  static const String calibrated = 'CALIBRATED';
  static const String insufficientEvidence = 'INSUFFICIENT_EVIDENCE';
  static const String blockedPoisoningSuspected = 'BLOCKED_POISONING_SUSPECTED';
  static const String hardSafetyBlock = 'HARD_SAFETY_BLOCK';

  static const Set<String> values = <String>{
    calibrated,
    insufficientEvidence,
    blockedPoisoningSuspected,
    hardSafetyBlock,
  };
}

class AgentProviderQualityEvidencePolicyConfig {
  AgentProviderQualityEvidencePolicyConfig._();

  static const int minCalibrationEvidence = 4;
  static const int maxEvidencePerBatch = 24;

  /// Difference from median beyond this is a numeric outlier.
  static const double outlierDistancePoints = 25.0;

  /// If more than 40% of trusted evidence is numeric outlier,
  /// the batch is suspicious and calibration fails closed.
  static const double maxOutlierShare = 0.40;

  /// One calibration batch cannot move an existing score
  /// by more than 5 points.
  static const double maxCalibrationShiftPoints = 5.0;

  static const int maxReasonCodes = 20;
  static const int maxOpaqueRefLength = 220;
}
