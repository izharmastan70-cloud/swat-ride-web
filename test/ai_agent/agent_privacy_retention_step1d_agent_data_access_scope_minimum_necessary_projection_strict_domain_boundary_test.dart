import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_privacy_access_scope_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_privacy_retention_classification_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_privacy_access_scope.dart';
import 'package:swat_ride/ai_agent/models/agent_privacy_data_access_request.dart';
import 'package:swat_ride/ai_agent/services/agent_privacy_minimum_necessary_access_policy.dart';

void main() {
  const AgentPrivacyMinimumNecessaryAccessPolicy policy =
      AgentPrivacyMinimumNecessaryAccessPolicy();

  final DateTime evaluatedAtUtc = DateTime.utc(2026, 8, 24, 5);

  AgentPrivacyAccessScope scope({
    String agentId = 'support_agent',
    Set<String>? allowedKinds,
    Set<String>? allowedDomains,
    String maximumTier = AgentPrivacySensitivityTier.highlySensitive,
    bool protectedEvidenceAllowed = false,
    DateTime? validUntilUtc,
  }) {
    return AgentPrivacyAccessScope(
      scopeId: 'scope:support_agent:phase63',
      agentId: agentId,
      allowedDataKinds:
          allowedKinds ??
          <String>{
            AgentPrivacyDataKind.operationalMetadata,
            AgentPrivacyDataKind.chatContent,
          },
      allowedDomains:
          allowedDomains ?? <String>{AgentPrivacyAccessDomain.general},
      maximumSensitivityTier: maximumTier,
      protectedEvidenceProjectionAllowed: protectedEvidenceAllowed,
      validUntilUtc: validUntilUtc ?? DateTime.utc(2026, 8, 25, 5),
    );
  }

  AgentPrivacyDataAccessRequest request({
    String agentId = 'support_agent',
    String domain = AgentPrivacyAccessDomain.general,
    String purpose = AgentPrivacyAccessPurpose.supportStatus,
    List<String>? kinds,
  }) {
    return AgentPrivacyDataAccessRequest(
      requestId: 'request:phase63:1',
      agentId: agentId,
      domain: domain,
      purpose: purpose,
      requestedDataKinds:
          kinds ?? <String>[AgentPrivacyDataKind.operationalMetadata],
      requestedAtUtc: DateTime.utc(2026, 8, 24, 4, 59),
    );
  }

  test('internal metadata grants minimum-necessary metadata only', () {
    final result = policy.evaluate(
      scope: scope(),
      request: request(),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(result.granted, true);
    expect(result.status, AgentPrivacyDataAccessStatus.grantedMinimumNecessary);
    expect(result.rawPayloadReturned, false);
    expect(result.allowedDataKinds, <String>[
      AgentPrivacyDataKind.operationalMetadata,
    ]);
  });

  test('private chat grants verified projection only', () {
    final result = policy.evaluate(
      scope: scope(),
      request: request(kinds: <String>[AgentPrivacyDataKind.chatContent]),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(
      result.status,
      AgentPrivacyDataAccessStatus.grantedVerifiedProjectionOnly,
    );
    expect(result.verifiedProjectionOnly, true);
    expect(result.rawPayloadReturned, false);
  });

  test('unscoped requested data kind fails whole request closed', () {
    final result = policy.evaluate(
      scope: scope(),
      request: request(
        kinds: <String>[
          AgentPrivacyDataKind.operationalMetadata,
          AgentPrivacyDataKind.emailContent,
        ],
      ),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(result.status, AgentPrivacyDataAccessStatus.blockedScope);
    expect(result.allowedDataKinds, isEmpty);
  });

  test('agent mismatch blocks', () {
    final result = policy.evaluate(
      scope: scope(agentId: 'support_agent'),
      request: request(agentId: 'owner_agent'),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(result.status, AgentPrivacyDataAccessStatus.blockedAgentMismatch);
  });

  test('expired scope blocks', () {
    final result = policy.evaluate(
      scope: scope(validUntilUtc: DateTime.utc(2026, 8, 24, 4, 59)),
      request: request(),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(result.status, AgentPrivacyDataAccessStatus.blockedExpired);
  });

  test('Student data requires STUDENT domain and high sensitivity ceiling', () {
    final studentScope = scope(
      allowedKinds: <String>{AgentPrivacyDataKind.studentData},
      allowedDomains: <String>{AgentPrivacyAccessDomain.student},
      maximumTier: AgentPrivacySensitivityTier.highlySensitive,
    );

    final wrongDomain = policy.evaluate(
      scope: studentScope,
      request: request(
        domain: AgentPrivacyAccessDomain.general,
        kinds: <String>[AgentPrivacyDataKind.studentData],
      ),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(wrongDomain.status, AgentPrivacyDataAccessStatus.blockedDomain);

    final allowed = policy.evaluate(
      scope: studentScope,
      request: request(
        domain: AgentPrivacyAccessDomain.student,
        kinds: <String>[AgentPrivacyDataKind.studentData],
      ),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(
      allowed.status,
      AgentPrivacyDataAccessStatus.grantedVerifiedProjectionOnly,
    );
  });

  test('Safety data requires SAFETY domain', () {
    final result = policy.evaluate(
      scope: scope(
        allowedKinds: <String>{AgentPrivacyDataKind.safetyEmergencyData},
        allowedDomains: <String>{AgentPrivacyAccessDomain.safety},
      ),
      request: request(
        domain: AgentPrivacyAccessDomain.safety,
        purpose: AgentPrivacyAccessPurpose.emergencySupport,
        kinds: <String>[AgentPrivacyDataKind.safetyEmergencyData],
      ),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(
      result.status,
      AgentPrivacyDataAccessStatus.grantedVerifiedProjectionOnly,
    );
  });

  test('Financial data requires FINANCIAL domain', () {
    final result = policy.evaluate(
      scope: scope(
        allowedKinds: <String>{AgentPrivacyDataKind.financialData},
        allowedDomains: <String>{AgentPrivacyAccessDomain.financial},
      ),
      request: request(
        domain: AgentPrivacyAccessDomain.financial,
        purpose: AgentPrivacyAccessPurpose.ownerReport,
        kinds: <String>[AgentPrivacyDataKind.financialData],
      ),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(
      result.status,
      AgentPrivacyDataAccessStatus.grantedVerifiedProjectionOnly,
    );
  });

  test('sensitivity ceiling cannot be exceeded', () {
    final result = policy.evaluate(
      scope: scope(
        allowedKinds: <String>{AgentPrivacyDataKind.studentData},
        allowedDomains: <String>{AgentPrivacyAccessDomain.student},
        maximumTier: AgentPrivacySensitivityTier.private,
      ),
      request: request(
        domain: AgentPrivacyAccessDomain.student,
        kinds: <String>[AgentPrivacyDataKind.studentData],
      ),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(result.status, AgentPrivacyDataAccessStatus.blockedSensitivity);
  });

  test('raw call recording is always blocked', () {
    final result = policy.evaluate(
      scope: scope(
        allowedKinds: <String>{AgentPrivacyDataKind.callRecording},
        maximumTier: AgentPrivacySensitivityTier.restrictedCritical,
      ),
      request: request(kinds: <String>[AgentPrivacyDataKind.callRecording]),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(
      result.status,
      AgentPrivacyDataAccessStatus.blockedRestrictedCritical,
    );
  });

  test('auth/API/payment credentials are always blocked', () {
    for (final String kind in <String>[
      AgentPrivacyDataKind.authSecret,
      AgentPrivacyDataKind.apiCredential,
      AgentPrivacyDataKind.paymentCredential,
    ]) {
      final result = policy.evaluate(
        scope: scope(
          allowedKinds: <String>{kind},
          maximumTier: AgentPrivacySensitivityTier.restrictedCritical,
        ),
        request: request(kinds: <String>[kind]),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentPrivacyDataAccessStatus.blockedRestrictedCritical,
      );
    }
  });

  test('protected evidence requires explicit projection scope', () {
    final denied = policy.evaluate(
      scope: scope(
        allowedKinds: <String>{AgentPrivacyDataKind.auditEvidence},
        protectedEvidenceAllowed: false,
      ),
      request: request(kinds: <String>[AgentPrivacyDataKind.auditEvidence]),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(denied.status, AgentPrivacyDataAccessStatus.blockedScope);

    final allowed = policy.evaluate(
      scope: scope(
        allowedKinds: <String>{AgentPrivacyDataKind.auditEvidence},
        protectedEvidenceAllowed: true,
      ),
      request: request(kinds: <String>[AgentPrivacyDataKind.auditEvidence]),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(
      allowed.status,
      AgentPrivacyDataAccessStatus.grantedVerifiedProjectionOnly,
    );
  });

  test('decision performs no read/write/provider/business action', () {
    final result = policy.evaluate(
      scope: scope(),
      request: request(),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(result.metadataOnly, true);
    expect(result.userDataFetched, false);
    expect(result.firestoreReadPerformed, false);
    expect(result.firestoreWritePerformed, false);
    expect(result.providerCalled, false);
    expect(result.runtimePermissionGranted, false);
    expect(result.approvalConsumed, false);
    expect(result.businessExecutionPerformed, false);
    expect(result.trainingPerformed, false);
    expect(result.deletionPerformed, false);
    expect(result.retentionMutationPerformed, false);
  });

  test('policy cannot override runtime/security authority', () {
    expect(policy.privacyEligibilityOnly, true);
    expect(policy.fetchesUserData, false);
    expect(policy.readsFirestore, false);
    expect(policy.writesFirestore, false);
    expect(policy.callsProvider, false);
    expect(policy.grantsRuntimePermission, false);
    expect(policy.consumesApproval, false);
    expect(policy.overridesPermissionEngine, false);
    expect(policy.overridesRuntimeGate, false);
    expect(policy.writesBusinessData, false);
    expect(policy.trainsModel, false);
    expect(policy.deploysChange, false);
    expect(policy.deletesData, false);
    expect(policy.changesRetention, false);
  });
}
