import '../models/agent_fake_booking_evidence.dart';
import '../models/agent_fraud_review_package.dart';
import '../models/agent_fraud_risk_assessment.dart';
import '../models/agent_no_show_evidence.dart';

// =========================================================
// AI AGENT - FRAUD REVIEW PACKAGE SERVICE
// =========================================================
//
// Phase 32 Step 6.
//
// Consolidation only.
//
// IMPORTANT:
// Evidence conflicts are surfaced for review.
// They are not silently resolved.
//
// Risk != guilt.
// Review != punishment.

class AgentFraudReviewPackageService {
  const AgentFraudReviewPackageService();

  AgentFraudReviewPackage build({
    required String packageId,
    required AgentFraudRiskAssessment
        riskAssessment,
    AgentNoShowEvidence? noShowEvidence,
    AgentFakeBookingEvidence?
        fakeBookingEvidence,
    DateTime? createdAt,
  }) {
    riskAssessment.validate();

    noShowEvidence?.validate();

    fakeBookingEvidence?.validate();

    final Set<String> evidence =
        <String>{
      ...riskAssessment.evidenceRefs,
      ...?noShowEvidence?.evidenceRefs,
      ...?fakeBookingEvidence?.evidenceRefs,
    };

    final bool noShowNeedsReview =
        noShowEvidence?.requiresAdminReview ??
        false;

    final bool fakeNeedsReview =
        fakeBookingEvidence
                ?.requiresAdminReview ??
            false;

    final bool requiresAdminReview =
        riskAssessment.requiresAdminReview ||
        noShowNeedsReview ||
        fakeNeedsReview;

    final bool requiresSuperAdminReview =
        riskAssessment
                .requiresSuperAdminReview ||
        (fakeBookingEvidence
                ?.requiresSuperAdminReview ??
            false);

    final List<String> summaryParts =
        <String>[
      'Risk: ${riskAssessment.riskLevel} '
          '(${riskAssessment.riskScore}/100).',
    ];

    if (noShowEvidence != null) {
      summaryParts.add(
        'No-show: '
        '${noShowEvidence.verificationStatus}.',
      );
    }

    if (fakeBookingEvidence != null) {
      summaryParts.add(
        'Repeated-abuse/fake-booking evidence: '
        '${fakeBookingEvidence.status} '
        '(${fakeBookingEvidence.independentSignalCount} '
        'independent signal(s)).',
      );
    }

    if (evidence.isEmpty) {
      summaryParts.add(
        'No immutable evidence reference is attached; '
        'do not take enforcement action.',
      );
    }

    summaryParts.add(
      'This review package is intelligence only '
      'and is not proof of guilt.',
    );

    final AgentFraudReviewPackage result =
        AgentFraudReviewPackage(
      packageId:
          packageId.trim(),
      riskAssessment:
          riskAssessment,
      noShowEvidence:
          noShowEvidence,
      fakeBookingEvidence:
          fakeBookingEvidence,
      evidenceRefs:
          evidence.toList(growable: false),
      requiresAdminReview:
          requiresAdminReview,
      requiresSuperAdminReview:
          requiresSuperAdminReview,
      reviewSummary:
          summaryParts.join(' '),
      createdAt:
          createdAt ?? DateTime.now(),
    );

    result.validate();

    return result;
  }
}