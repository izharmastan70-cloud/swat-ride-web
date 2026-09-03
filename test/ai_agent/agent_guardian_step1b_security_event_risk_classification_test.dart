import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_guardian_security_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_omnichannel_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_risk_decision.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_security_event.dart';
import 'package:swat_ride/ai_agent/services/agent_guardian_risk_classifier.dart';

void main() {
  const AgentGuardianRiskClassifier classifier = AgentGuardianRiskClassifier();

  AgentGuardianSecurityEvent event({
    String eventId = 'guardian_event_001',
    String category = AgentGuardianRiskCategory.promptInjectionAttempt,
    String evidenceTrust = AgentGuardianEvidenceTrust.verifiedSystem,
    String sourceComponent = 'omnichannel_gateway',
    Set<String> evidenceCodes = const <String>{'pattern_match'},
    String? channel = AgentOmnichannelChannel.appChat,
    bool highImpact = false,
    bool repeated = false,
    bool activeExploit = false,
    bool authoritativeGateBlocked = false,
    bool rawPrompt = false,
    bool rawHistory = false,
    bool rawSecret = false,
    bool paymentCredential = false,
    bool authToken = false,
    bool ownerPrivate = false,
    bool customerPrivate = false,
  }) {
    return AgentGuardianSecurityEvent(
      eventId: eventId,
      category: category,
      evidenceTrust: evidenceTrust,
      sourceComponent: sourceComponent,
      occurredAt: DateTime.utc(2026, 8, 19, 8),
      observedAt: DateTime.utc(2026, 8, 19, 8, 1),
      evidenceCodes: evidenceCodes,
      pseudonymousSubjectRef: 'subject_hash_001',
      sourceChannel: channel,
      agentRoleId: 'support_agent',
      targetActionId: 'status.read',
      highImpactActionTargeted: highImpact,
      repeatedWithinWindow: repeated,
      activeExploitEvidence: activeExploit,
      existingAuthoritativeGateBlocked: authoritativeGateBlocked,
      containsRawPrompt: rawPrompt,
      containsRawMessageHistory: rawHistory,
      containsRawSecret: rawSecret,
      containsPaymentCredential: paymentCredential,
      containsAuthToken: authToken,
      containsOwnerPrivatePayload: ownerPrivate,
      containsCustomerPrivatePayload: customerPrivate,
    );
  }

  group('Phase 53 Step 1B Guardian event and risk classification', () {
    test('safe machine-readable event validates', () {
      final AgentGuardianSecurityEvent safeEvent = event();

      expect(() => safeEvent.validateStructure(), returnsNormally);
      expect(safeEvent.grantsAuthority, isFalse);
      expect(safeEvent.executesBlock, isFalse);
      expect(safeEvent.createsIncident, isFalse);
    });

    test('event rejects raw prompt/history/secrets/private payloads', () {
      final List<AgentGuardianSecurityEvent> prohibited =
          <AgentGuardianSecurityEvent>[
            event(rawPrompt: true),
            event(rawHistory: true),
            event(rawSecret: true),
            event(paymentCredential: true),
            event(authToken: true),
            event(ownerPrivate: true),
            event(customerPrivate: true),
          ];

      for (final AgentGuardianSecurityEvent item in prohibited) {
        expect(
          () => item.validateStructure(),
          throwsA(isA<AgentGuardianSecurityEventException>()),
        );
      }
    });

    test('event requires bounded evidence codes', () {
      expect(
        () => event(evidenceCodes: const <String>{}).validateStructure(),
        throwsA(isA<AgentGuardianSecurityEventException>()),
      );

      expect(
        () => event(
          evidenceCodes: const <String>{
            'a',
            'b',
            'c',
            'd',
            'e',
            'f',
            'g',
            'h',
            'i',
          },
        ).validateStructure(),
        throwsA(isA<AgentGuardianSecurityEventException>()),
      );
    });

    test('suspicious input starts LOW', () {
      final AgentGuardianRiskDecision decision = classifier.classify(
        event(category: AgentGuardianRiskCategory.suspiciousInputPattern),
      );

      expect(decision.severity, AgentGuardianSeverity.low);
      expect(
        decision.recommendedDisposition,
        AgentGuardianRecommendedDisposition.observe,
      );
    });

    test('prompt injection starts MEDIUM', () {
      final AgentGuardianRiskDecision decision = classifier.classify(event());

      expect(decision.severity, AgentGuardianSeverity.medium);
      expect(
        decision.recommendedDisposition,
        AgentGuardianRecommendedDisposition.review,
      );
    });

    test('permission/approval/runtime bypass attempts are HIGH', () {
      for (final String category in <String>[
        AgentGuardianRiskCategory.permissionBypassAttempt,
        AgentGuardianRiskCategory.approvalBypassAttempt,
        AgentGuardianRiskCategory.runtimeGateBypassAttempt,
      ]) {
        final AgentGuardianRiskDecision decision = classifier.classify(
          event(category: category),
        );

        expect(decision.severity, AgentGuardianSeverity.high);
      }
    });

    test('context boundary violations are HIGH', () {
      for (final String category in <String>[
        AgentGuardianRiskCategory.crossSubjectContextAttempt,
        AgentGuardianRiskCategory.ownerCustomerBoundaryViolation,
        AgentGuardianRiskCategory.emergencyContextIsolationViolation,
      ]) {
        final AgentGuardianRiskDecision decision = classifier.classify(
          event(category: category),
        );

        expect(decision.severity, AgentGuardianSeverity.high);
      }
    });

    test('emergency-stop/credential/tamper attempts are CRITICAL', () {
      for (final String category in <String>[
        AgentGuardianRiskCategory.emergencyStopBypassAttempt,
        AgentGuardianRiskCategory.secretOrCredentialExposureAttempt,
        AgentGuardianRiskCategory.securityControlTamperAttempt,
      ]) {
        final AgentGuardianRiskDecision decision = classifier.classify(
          event(category: category),
        );

        expect(decision.severity, AgentGuardianSeverity.critical);
      }
    });

    test('high-impact target elevates MEDIUM to HIGH', () {
      final AgentGuardianRiskDecision decision = classifier.classify(
        event(
          category: AgentGuardianRiskCategory.identityMismatch,
          highImpact: true,
        ),
      );

      expect(decision.severity, AgentGuardianSeverity.high);
      expect(
        decision.reasonCodes,
        contains(AgentGuardianRiskReason.highImpactTargetElevation),
      );
    });

    test('repeated suspicious pattern elevates to HIGH', () {
      final AgentGuardianRiskDecision decision = classifier.classify(
        event(
          category: AgentGuardianRiskCategory.suspiciousInputPattern,
          repeated: true,
        ),
      );

      expect(decision.severity, AgentGuardianSeverity.high);
    });

    test('active exploit elevates HIGH to CRITICAL', () {
      final AgentGuardianRiskDecision decision = classifier.classify(
        event(
          category: AgentGuardianRiskCategory.permissionBypassAttempt,
          activeExploit: true,
        ),
      );

      expect(decision.severity, AgentGuardianSeverity.critical);
      expect(
        decision.reasonCodes,
        contains(AgentGuardianRiskReason.activeExploitElevation),
      );
    });

    test('multiple strong indicators can elevate HIGH to CRITICAL', () {
      final AgentGuardianRiskDecision decision = classifier.classify(
        event(
          category: AgentGuardianRiskCategory.identityMismatch,
          highImpact: true,
          repeated: true,
        ),
      );

      expect(decision.severity, AgentGuardianSeverity.critical);
      expect(
        decision.reasonCodes,
        contains(AgentGuardianRiskReason.multipleStrongIndicatorsElevation),
      );
    });

    test('verified critical evidence recommends block and escalate', () {
      final AgentGuardianRiskDecision decision = classifier.classify(
        event(
          category: AgentGuardianRiskCategory.securityControlTamperAttempt,
          evidenceTrust: AgentGuardianEvidenceTrust.verifiedSecurityControl,
        ),
      );

      expect(decision.evidenceConfidence, AgentGuardianEvidenceConfidence.high);
      expect(
        decision.recommendedDisposition,
        AgentGuardianRecommendedDisposition.blockAndEscalateRecommended,
      );
    });

    test('unverified critical evidence does not auto-block', () {
      final AgentGuardianRiskDecision decision = classifier.classify(
        event(
          category: AgentGuardianRiskCategory.securityControlTamperAttempt,
          evidenceTrust: AgentGuardianEvidenceTrust.userReported,
        ),
      );

      expect(decision.evidenceConfidence, AgentGuardianEvidenceConfidence.low);
      expect(
        decision.recommendedDisposition,
        AgentGuardianRecommendedDisposition.reviewAndEscalate,
      );
      expect(decision.executesBlock, isFalse);
    });

    test('verified HIGH evidence recommends block but does not execute it', () {
      final AgentGuardianRiskDecision decision = classifier.classify(
        event(
          category: AgentGuardianRiskCategory.runtimeGateBypassAttempt,
          evidenceTrust: AgentGuardianEvidenceTrust.verifiedSystem,
        ),
      );

      expect(
        decision.recommendedDisposition,
        AgentGuardianRecommendedDisposition.blockRecommended,
      );
      expect(decision.recommendationOnly, isTrue);
      expect(decision.guardianIsFinalEnforcer, isFalse);
      expect(decision.executesBlock, isFalse);
    });

    test('invalid event fails closed to review-and-escalate', () {
      final AgentGuardianSecurityEvent invalid = event(rawSecret: true);

      final AgentGuardianRiskDecision decision = classifier.classify(invalid);

      expect(decision.invalidEvent, isTrue);
      expect(
        decision.recommendedDisposition,
        AgentGuardianRecommendedDisposition.reviewAndEscalate,
      );
      expect(decision.executesBlock, isFalse);
    });

    test('existing authoritative gate block is evidence only', () {
      final AgentGuardianRiskDecision decision = classifier.classify(
        event(
          category: AgentGuardianRiskCategory.permissionBypassAttempt,
          authoritativeGateBlocked: true,
        ),
      );

      expect(decision.existingAuthoritativeGateBlocked, isTrue);
      expect(decision.guardianIsFinalEnforcer, isFalse);
      expect(decision.executesBlock, isFalse);
    });

    test('safe event metadata contains no raw/private payload', () {
      final Map<String, dynamic> map = event().toSafeMap();

      expect(map['rawPromptIncluded'], isFalse);
      expect(map['rawMessageHistoryIncluded'], isFalse);
      expect(map['rawSecretIncluded'], isFalse);
      expect(map['paymentCredentialIncluded'], isFalse);
      expect(map['authTokenIncluded'], isFalse);
      expect(map['ownerPrivatePayloadIncluded'], isFalse);
      expect(map['customerPrivatePayloadIncluded'], isFalse);
      expect(map['createsIncident'], isFalse);
      expect(map['writesBusinessData'], isFalse);
    });

    test('risk decision metadata is recommendation-only', () {
      final AgentGuardianRiskDecision decision = classifier.classify(event());

      final Map<String, dynamic> map = decision.toSafeMap();

      expect(map['recommendationOnly'], isTrue);
      expect(map['guardianIsFinalEnforcer'], isFalse);
      expect(map['grantsAuthority'], isFalse);
      expect(map['grantsPermission'], isFalse);
      expect(map['consumesApproval'], isFalse);
      expect(map['executesBlock'], isFalse);
      expect(map['executesEscalation'], isFalse);
      expect(map['createsIncident'], isFalse);
      expect(map['mutatesSecurityControls'], isFalse);
      expect(map['writesBusinessData'], isFalse);
    });

    test('classifier never replaces authoritative security controls', () {
      expect(classifier.recommendationOnly, isTrue);
      expect(classifier.guardianIsFinalEnforcer, isFalse);
      expect(classifier.invokesPermissionEngine, isFalse);
      expect(classifier.invokesApprovalEngine, isFalse);
      expect(classifier.invokesRuntimeGate, isFalse);
      expect(classifier.invokesEmergencyStop, isFalse);
      expect(classifier.executesBlock, isFalse);
      expect(classifier.executesEscalation, isFalse);
      expect(classifier.createsIncident, isFalse);
      expect(classifier.implementsIncidentResponse, isFalse);
      expect(classifier.mutatesSecurityControls, isFalse);
      expect(classifier.invokesProvider, isFalse);
      expect(classifier.invokesTargetAgent, isFalse);
      expect(classifier.writesBusinessData, isFalse);
      expect(classifier.persistsEventOrDecision, isFalse);
    });
  });
}
