import '../constants/agent_provider_quality_evidence_constants.dart';

class AgentProviderQualityCalibrationDecision {
  AgentProviderQualityCalibrationDecision({
    required this.status,
    required this.referenceScore,
    required this.robustEvidenceScore,
    required this.calibratedScore,
    required this.shiftPoints,
    required this.acceptedEvidenceCount,
    required this.excludedOutlierCount,
    required this.poisoningSuspected,
    required this.hardSafetyBlocked,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final double referenceScore;
  final double robustEvidenceScore;
  final double calibratedScore;
  final double shiftPoints;
  final int acceptedEvidenceCount;
  final int excludedOutlierCount;
  final bool poisoningSuspected;
  final bool hardSafetyBlocked;
  final List<String> reasonCodes;

  bool get recommendationMetadataOnly => true;

  bool get mayInvokeProvider => false;
  bool get mayMutateRouting => false;
  bool get mayEnableProvider => false;
  bool get mayDisableProvider => false;
  bool get mayMutateBudget => false;
  bool get mayChangeSecret => false;
  bool get mayDeployModel => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayExecuteBusinessAction => false;
  bool get persistsDecision => false;

  void validateStructure() {
    final List<double> scores = <double>[
      referenceScore,
      robustEvidenceScore,
      calibratedScore,
    ];

    if (!AgentProviderQualityCalibrationStatus.values.contains(status) ||
        scores.any(
          (double value) => !value.isFinite || value < 0 || value > 100,
        ) ||
        !shiftPoints.isFinite ||
        acceptedEvidenceCount < 0 ||
        excludedOutlierCount < 0 ||
        reasonCodes.isEmpty ||
        reasonCodes.length >
            AgentProviderQualityEvidencePolicyConfig.maxReasonCodes) {
      throw const FormatException(
        'Invalid provider quality calibration decision.',
      );
    }
  }
}
