import '../models/agent_fraud_risk_assessment.dart';

// =========================================================
// AI AGENT - FRAUD / RISK SCORING SERVICE
// =========================================================
//
// Phase 32 Step 3.
//
// Evidence-based intelligence only.
//
// A risk score is NOT a guilt verdict.
//
// The service:
// - scores supplied signals
// - caps score at 100
// - derives Low/Moderate/High/Critical
// - recommends review
// - requires stronger review for severe cases
//
// It DOES NOT:
// - suspend or ban
// - charge a no-show fee
// - debit a wallet
// - refund a payment
// - cancel a booking
// - mark a booking no-show
// - change a promo
// - punish a driver/rider
//
// Enforcement stays outside this service.

class AgentFraudRiskScoringService {
  const AgentFraudRiskScoringService();

  AgentFraudRiskAssessment assess({
    required String assessmentId,
    required String module,
    required String subjectType,
    required String subjectId,
    required Iterable<String> signals,
    Iterable<String> evidenceRefs =
        const <String>[],
    DateTime? createdAt,
  }) {
    final Set<String> uniqueSignals =
        signals.toSet();

    final List<String> cleanEvidence =
        evidenceRefs
            .map((String value) =>
                value.trim())
            .where(
              (String value) =>
                  value.isNotEmpty,
            )
            .toSet()
            .toList(growable: false);

    for (final String signal
        in uniqueSignals) {
      if (!AgentFraudSignalType.isValid(
        signal,
      )) {
        throw AgentFraudRiskScoringException(
          'Unknown fraud signal "$signal".',
        );
      }
    }

    int score = 0;

    for (final String signal
        in uniqueSignals) {
      score += _weight(signal);
    }

    if (score > 100) {
      score = 100;
    }

    final String level =
        _levelForScore(score);

    final bool hasSeriousSignal =
        uniqueSignals.contains(
          AgentFraudSignalType.fakeBooking,
        ) ||
        uniqueSignals.contains(
          AgentFraudSignalType.falseNoShowClaim,
        ) ||
        uniqueSignals.contains(
          AgentFraudSignalType.arrivalSpoof,
        ) ||
        uniqueSignals.contains(
          AgentFraudSignalType.paymentRisk,
        ) ||
        uniqueSignals.contains(
          AgentFraudSignalType.possibleCollusion,
        );

    final bool requiresAdminReview =
        score >= 40 ||
        hasSeriousSignal;

    final bool requiresSuperAdminReview =
        score >= 80 &&
        cleanEvidence.isNotEmpty;

    final String recommendation =
        _recommendation(
      score: score,
      level: level,
      hasEvidence:
          cleanEvidence.isNotEmpty,
      signalCount:
          uniqueSignals.length,
    );

    final AgentFraudRiskAssessment result =
        AgentFraudRiskAssessment(
      assessmentId:
          assessmentId.trim(),
      module:
          module.trim(),
      subjectType:
          subjectType,
      subjectId:
          subjectId.trim(),
      riskScore:
          score,
      riskLevel:
          level,
      signals:
          uniqueSignals
              .toList(growable: false),
      evidenceRefs:
          cleanEvidence,
      recommendation:
          recommendation,
      requiresAdminReview:
          requiresAdminReview,
      requiresSuperAdminReview:
          requiresSuperAdminReview,
      createdAt:
          createdAt ?? DateTime.now(),
    );

    result.validate();

    return result;
  }

  int _weight(String signal) {
    switch (signal) {
      case AgentFraudSignalType.verifiedNoShow:
        return 10;

      case AgentFraudSignalType.repeatedNoShow:
        return 20;

      case AgentFraudSignalType.unreachablePattern:
        return 10;

      case AgentFraudSignalType.falseNoShowClaim:
        return 30;

      case AgentFraudSignalType.fakeBooking:
        return 30;

      case AgentFraudSignalType.gpsAnomaly:
        return 15;

      case AgentFraudSignalType.arrivalSpoof:
        return 30;

      case AgentFraudSignalType.multiAccountPattern:
        return 25;

      case AgentFraudSignalType.promoAbuse:
        return 20;

      case AgentFraudSignalType.referralAbuse:
        return 20;

      case AgentFraudSignalType.paymentRisk:
        return 30;

      case AgentFraudSignalType.possibleCollusion:
        return 35;
    }

    return 0;
  }

  String _levelForScore(int score) {
    if (score >= 80) {
      return AgentFraudRiskLevel.critical;
    }

    if (score >= 60) {
      return AgentFraudRiskLevel.high;
    }

    if (score >= 30) {
      return AgentFraudRiskLevel.moderate;
    }

    return AgentFraudRiskLevel.low;
  }

  String _recommendation({
    required int score,
    required String level,
    required bool hasEvidence,
    required int signalCount,
  }) {
    if (signalCount == 0) {
      return 'No current fraud signal. Continue normal monitoring.';
    }

    if (!hasEvidence) {
      return 'Risk signals detected, but evidence references are missing. Collect and verify evidence before any enforcement.';
    }

    if (level ==
        AgentFraudRiskLevel.critical) {
      return 'Critical risk indicators detected. Escalate for Admin/Super Admin evidence review; do not apply automatic punishment.';
    }

    if (level ==
            AgentFraudRiskLevel.high ||
        score >= 40) {
      return 'Material risk indicators detected. Admin should review the evidence before any restriction, fee or account action.';
    }

    return 'Risk indicators detected. Continue evidence-based monitoring; do not treat the score as proof of fraud.';
  }
}

class AgentFraudRiskScoringException
    implements Exception {
  final String message;

  const AgentFraudRiskScoringException(
    this.message,
  );

  @override
  String toString() =>
      'AgentFraudRiskScoringException: $message';
}