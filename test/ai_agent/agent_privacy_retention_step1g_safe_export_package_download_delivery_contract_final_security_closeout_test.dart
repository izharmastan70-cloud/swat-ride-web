import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_privacy_control_export_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_privacy_export_delivery_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_privacy_retention_classification_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_privacy_export_decision.dart';
import 'package:swat_ride/ai_agent/models/agent_privacy_export_record.dart';
import 'package:swat_ride/ai_agent/services/agent_privacy_export_delivery_handoff_service.dart';
import 'package:swat_ride/ai_agent/services/agent_privacy_export_package_builder.dart';
import 'package:swat_ride/ai_agent/services/agent_privacy_retention_final_readiness_service.dart';

void main() {
  const builder = AgentPrivacyExportPackageBuilder();
  const handoff = AgentPrivacyExportDeliveryHandoffService();
  const readiness = AgentPrivacyRetentionFinalReadinessService();

  AgentPrivacyExportDecision decision({
    String format = AgentPrivacyExportFormat.json,
    List<String>? kinds,
  }) {
    return AgentPrivacyExportDecision(
      status: AgentPrivacyExportStatus.eligibleForSafeExportPackage,
      exportId: 'export:user:123:final',
      format: format,
      allowedDataKinds: kinds ?? <String>[AgentPrivacyDataKind.chatContent],
      reasonCode: 'eligible_for_safe_redacted_export_package',
    );
  }

  AgentPrivacyExportRecord chatRecord({Map<String, Object?>? fields}) {
    return AgentPrivacyExportRecord(
      dataKind: AgentPrivacyDataKind.chatContent,
      fields:
          fields ??
          <String, Object?>{
            'messageType': 'support',
            'summary': 'Redacted conversation summary',
          },
      redactedProjectionVerified: true,
      restrictedCriticalExcluded: true,
      protectedEvidenceExcluded: true,
    );
  }

  test('JSON package is generated in memory from redacted records', () {
    final payload = builder.build(
      decision: decision(),
      records: <AgentPrivacyExportRecord>[chatRecord()],
    );

    expect(payload.mimeType, AgentPrivacyExportMimeType.json);
    expect(payload.fileName, endsWith('.json'));
    expect(payload.byteLength, greaterThan(0));
    expect(payload.inMemoryOnly, true);
    expect(payload.filesystemWritePerformed, false);

    final decoded =
        jsonDecode(utf8.decode(payload.bytes)) as Map<String, dynamic>;

    expect(decoded['redactedProjectionOnly'], true);
    expect(decoded['restrictedCriticalExcluded'], true);
    expect(decoded['protectedEvidenceExcluded'], true);
  });

  test('CSV package is generated in memory', () {
    final payload = builder.build(
      decision: decision(format: AgentPrivacyExportFormat.csv),
      records: <AgentPrivacyExportRecord>[chatRecord()],
    );

    expect(payload.mimeType, AgentPrivacyExportMimeType.csv);
    expect(payload.fileName, endsWith('.csv'));

    final text = utf8.decode(payload.bytes);
    expect(text, contains('dataKind,field,value'));
    expect(text, contains('CHAT_CONTENT'));
  });

  test('ZIP_PACKAGE has ZIP signature and safe manifest', () {
    final payload = builder.build(
      decision: decision(format: AgentPrivacyExportFormat.zipPackage),
      records: <AgentPrivacyExportRecord>[chatRecord()],
    );

    expect(payload.mimeType, AgentPrivacyExportMimeType.zip);
    expect(payload.fileName, endsWith('.zip'));
    expect(payload.bytes.length, greaterThan(30));

    expect(payload.bytes[0], 0x50);
    expect(payload.bytes[1], 0x4b);
    expect(payload.bytes[2], 0x03);
    expect(payload.bytes[3], 0x04);
  });

  test('record kind outside eligible decision is blocked', () {
    expect(
      () => builder.build(
        decision: decision(kinds: <String>[AgentPrivacyDataKind.emailContent]),
        records: <AgentPrivacyExportRecord>[chatRecord()],
      ),
      throwsFormatException,
    );
  });

  test('restricted-critical raw call recording is blocked by builder', () {
    final rawRecord = AgentPrivacyExportRecord(
      dataKind: AgentPrivacyDataKind.callRecording,
      fields: <String, Object?>{'recordingStatus': 'not_included'},
      redactedProjectionVerified: true,
      restrictedCriticalExcluded: true,
      protectedEvidenceExcluded: true,
    );

    expect(
      () => builder.build(
        decision: decision(kinds: <String>[AgentPrivacyDataKind.callRecording]),
        records: <AgentPrivacyExportRecord>[rawRecord],
      ),
      throwsFormatException,
    );
  });

  test('protected audit/security/finance evidence is blocked', () {
    for (final kind in <String>[
      AgentPrivacyDataKind.auditEvidence,
      AgentPrivacyDataKind.securityEvidence,
      AgentPrivacyDataKind.financeEvidence,
    ]) {
      final record = AgentPrivacyExportRecord(
        dataKind: kind,
        fields: <String, Object?>{'status': 'protected'},
        redactedProjectionVerified: true,
        restrictedCriticalExcluded: true,
        protectedEvidenceExcluded: true,
      );

      expect(
        () => builder.build(
          decision: decision(kinds: <String>[kind]),
          records: <AgentPrivacyExportRecord>[record],
        ),
        throwsFormatException,
      );
    }
  });

  test('password field name fails closed', () {
    expect(
      () => chatRecord(
        fields: <String, Object?>{'password': 'should-never-export'},
      ),
      throwsFormatException,
    );
  });

  test('API key field name fails closed', () {
    expect(
      () => chatRecord(
        fields: <String, Object?>{'apiKey': 'should-never-export'},
      ),
      throwsFormatException,
    );
  });

  test('auth/approval/permission token field names fail closed', () {
    for (final key in <String>[
      'authToken',
      'approvalToken',
      'permissionToken',
    ]) {
      expect(
        () => chatRecord(fields: <String, Object?>{key: 'should-never-export'}),
        throwsFormatException,
      );
    }
  });

  test('card/cvv/payment credential field names fail closed', () {
    for (final key in <String>['cardNumber', 'cvv', 'paymentCredential']) {
      expect(
        () => chatRecord(fields: <String, Object?>{key: 'should-never-export'}),
        throwsFormatException,
      );
    }
  });

  test('raw recording/audio-byte fields fail closed', () {
    for (final key in <String>['rawRecording', 'audioBytes']) {
      expect(
        () => chatRecord(fields: <String, Object?>{key: 'blocked'}),
        throwsFormatException,
      );
    }
  });

  test('explicit user gesture is required for download handoff', () {
    final payload = builder.build(
      decision: decision(),
      records: <AgentPrivacyExportRecord>[chatRecord()],
    );

    final blocked = handoff.prepare(
      payload: payload,
      explicitUserGestureConfirmed: false,
    );

    expect(
      blocked.status,
      AgentPrivacyExportDeliveryStatus.blockedNoUserGesture,
    );
    expect(blocked.downloadAlreadyDelivered, false);

    final ready = handoff.prepare(
      payload: payload,
      explicitUserGestureConfirmed: true,
    );

    expect(ready.readyForTrustedAdapter, true);
    expect(ready.trustedPlatformAdapterRequired, true);
    expect(ready.downloadAlreadyDelivered, false);
  });

  test('package builder never fetches/writes/uploads/downloads itself', () {
    expect(builder.inMemoryOnly, true);
    expect(builder.fetchesUserData, false);
    expect(builder.readsFirestore, false);
    expect(builder.writesFirestore, false);
    expect(builder.writesFilesystem, false);
    expect(builder.uploadsCloudFile, false);
    expect(builder.autoDownloads, false);
    expect(builder.grantsPermission, false);
    expect(builder.consumesApproval, false);
    expect(builder.overridesRuntimeGate, false);
    expect(builder.callsProvider, false);
    expect(builder.writesBusinessData, false);
    expect(builder.deletesData, false);
  });

  test('delivery handoff never auto-downloads or grants authority', () {
    expect(handoff.handoffOnly, true);
    expect(handoff.autoDownloads, false);
    expect(handoff.writesFilesystem, false);
    expect(handoff.uploadsCloudFile, false);
    expect(handoff.readsFirestore, false);
    expect(handoff.writesFirestore, false);
    expect(handoff.grantsPermission, false);
    expect(handoff.consumesApproval, false);
    expect(handoff.overridesRuntimeGate, false);
    expect(handoff.callsProvider, false);
    expect(handoff.writesBusinessData, false);
    expect(handoff.deletesData, false);
  });

  test('final readiness requires every Phase 63 safety pillar', () {
    expect(
      readiness.evaluate(
        classificationTiersReady: true,
        channelRetentionReady: true,
        consentRedactionReady: true,
        minimumNecessaryAccessReady: true,
        deletionBoundaryReady: true,
        protectedEvidenceReady: true,
        ownerSuperAdminControlsReady: true,
        exportEligibilityReady: true,
        packageGenerationReady: true,
        trustedDownloadHandoffReady: true,
        runtimeSecurityBoundaryPreserved: true,
        coreAppFailureIsolationPreserved: true,
      ),
      true,
    );

    expect(
      readiness.evaluate(
        classificationTiersReady: true,
        channelRetentionReady: true,
        consentRedactionReady: true,
        minimumNecessaryAccessReady: true,
        deletionBoundaryReady: true,
        protectedEvidenceReady: true,
        ownerSuperAdminControlsReady: true,
        exportEligibilityReady: true,
        packageGenerationReady: true,
        trustedDownloadHandoffReady: false,
        runtimeSecurityBoundaryPreserved: true,
        coreAppFailureIsolationPreserved: true,
      ),
      false,
    );
  });

  test('final readiness grants no production/security authority', () {
    expect(readiness.phase63CompleteFoundation, true);
    expect(readiness.productionActivated, false);
    expect(readiness.automaticDeletionActivated, false);
    expect(readiness.automaticExportDeliveryActivated, false);
    expect(readiness.providerExecutionActivated, false);
    expect(readiness.permissionAuthorityGranted, false);
    expect(readiness.approvalAuthorityGranted, false);
    expect(readiness.runtimeGateOverridden, false);
    expect(readiness.phase62DeploymentAuthorityOverridden, false);
    expect(readiness.coreAppDependencyIntroduced, false);
  });
}
