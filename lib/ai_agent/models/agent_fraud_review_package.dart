import 'agent_fake_booking_evidence.dart';
import 'agent_fraud_risk_assessment.dart';
import 'agent_no_show_evidence.dart';

// =========================================================
// AI AGENT - FRAUD REVIEW PACKAGE
// =========================================================
//
// Phase 32 Step 6.
//
// Consolidates:
// - Fraud/Risk assessment
// - optional No-Show evidence
// - optional Fake Booking/repeated-abuse evidence
//
// REVIEW PACKAGE ONLY.
//
// It does NOT:
// - decide guilt
// - suspend/ban
// - charge a fee
// - debit wallet
// - cancel booking
// - mark no-show
// - execute refund
//
// Admin gets one understandable package instead of
// scattered intelligence objects.

class AgentFraudReviewPackage {
  final String packageId;

  final AgentFraudRiskAssessment riskAssessment;

  final AgentNoShowEvidence? noShowEvidence;

  final AgentFakeBookingEvidence?
      fakeBookingEvidence;

  final List<String> evidenceRefs;

  final bool requiresAdminReview;
  final bool requiresSuperAdminReview;

  final String reviewSummary;

  final DateTime createdAt;

  const AgentFraudReviewPackage({
    required this.packageId,
    required this.riskAssessment,
    this.noShowEvidence,
    this.fakeBookingEvidence,
    required this.evidenceRefs,
    required this.requiresAdminReview,
    required this.requiresSuperAdminReview,
    required this.reviewSummary,
    required this.createdAt,
  });

  bool get hasNoShowEvidence =>
      noShowEvidence != null;

  bool get hasFakeBookingEvidence =>
      fakeBookingEvidence != null;

  bool get hasSupportingEvidence =>
      evidenceRefs.isNotEmpty;

  void validate() {
    if (packageId.trim().isEmpty) {
      throw const AgentFraudReviewPackageException(
        'packageId cannot be empty.',
      );
    }

    riskAssessment.validate();

    noShowEvidence?.validate();

    fakeBookingEvidence?.validate();

    if (reviewSummary.trim().isEmpty) {
      throw const AgentFraudReviewPackageException(
        'reviewSummary cannot be empty.',
      );
    }

    if (requiresSuperAdminReview &&
        !requiresAdminReview) {
      throw const AgentFraudReviewPackageException(
        'Super Admin review also requires Admin review.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'packageId':
          packageId,
      'riskAssessment':
          riskAssessment.toMap(),
      'noShowEvidence':
          noShowEvidence?.toMap(),
      'fakeBookingEvidence':
          fakeBookingEvidence?.toMap(),
      'evidenceRefs':
          List<String>.from(evidenceRefs),
      'requiresAdminReview':
          requiresAdminReview,
      'requiresSuperAdminReview':
          requiresSuperAdminReview,
      'reviewSummary':
          reviewSummary,
      'createdAt':
          createdAt.toIso8601String(),
    };
  }
}

class AgentFraudReviewPackageException
    implements Exception {
  final String message;

  const AgentFraudReviewPackageException(
    this.message,
  );

  @override
  String toString() =>
      'AgentFraudReviewPackageException: $message';
}