import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_privacy_access_scope_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_privacy_control_export_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_privacy_retention_classification_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_privacy_control_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_privacy_export_request.dart';
import 'package:swat_ride/ai_agent/services/agent_privacy_control_settings_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_privacy_export_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_privacy_export_preview_service.dart';

void main() {
  const settingsPolicy = AgentPrivacyControlSettingsPolicy();
  const exportPolicy = AgentPrivacyExportPolicy();
  const previewService = AgentPrivacyExportPreviewService();

  final evaluatedAtUtc = DateTime.utc(2026, 8, 24, 7);

  AgentPrivacyControlSettings settings({
    String role = AgentPrivacyControlRole.owner,
    int chat = 30,
    int transcript = 14,
    int recording = 0,
    int email = 30,
    int whatsapp = 30,
    bool exportEnabled = true,
    bool strictExportEnabled = false,
  }) {
    return AgentPrivacyControlSettings(
      settingsId: 'privacy:settings:global',
      updatedByRole: role,
      chatRetentionDays: chat,
      callTranscriptRetentionDays: transcript,
      callRecordingRetentionDays: recording,
      emailRetentionDays: email,
      whatsappAiRetentionDays: whatsapp,
      dataExportEnabled: exportEnabled,
      strictDomainExportEnabled: strictExportEnabled,
      updatedAtUtc: DateTime.utc(2026, 8, 24, 6, 59),
    );
  }

  AgentPrivacyExportRequest userExport({
    List<String>? kinds,
    String format = AgentPrivacyExportFormat.json,
    bool redacted = true,
    String domain = AgentPrivacyAccessDomain.general,
    bool strictDomainAuthorization = false,
    String requester = 'user:123',
    String subject = 'user:123',
  }) {
    return AgentPrivacyExportRequest(
      exportId: 'export:user:123:1',
      requestedByRole: AgentPrivacyControlRole.user,
      requesterRef: requester,
      subjectRef: subject,
      exportScope: AgentPrivacyExportScope.ownData,
      format: format,
      domain: domain,
      requestedDataKinds: kinds ?? <String>[AgentPrivacyDataKind.chatContent],
      redactedProjectionConfirmed: redacted,
      strictDomainAuthorizationConfirmed: strictDomainAuthorization,
      requestedAtUtc: DateTime.utc(2026, 8, 24, 6, 59),
    );
  }

  AgentPrivacyExportRequest adminExport({
    List<String>? kinds,
    String role = AgentPrivacyControlRole.superAdmin,
    String format = AgentPrivacyExportFormat.zipPackage,
    String domain = AgentPrivacyAccessDomain.general,
    bool redacted = true,
    bool strictDomainAuthorization = false,
  }) {
    return AgentPrivacyExportRequest(
      exportId: 'export:admin:1',
      requestedByRole: role,
      requesterRef: 'admin:1',
      subjectRef: 'user:123',
      exportScope: AgentPrivacyExportScope.authorizedScopedData,
      format: format,
      domain: domain,
      requestedDataKinds:
          kinds ??
          <String>[
            AgentPrivacyDataKind.emailContent,
            AgentPrivacyDataKind.whatsappContent,
          ],
      redactedProjectionConfirmed: redacted,
      strictDomainAuthorizationConfirmed: strictDomainAuthorization,
      requestedAtUtc: DateTime.utc(2026, 8, 24, 6, 59),
    );
  }

  group('Phase 63 Step 1F privacy control settings preview', () {
    test('safe Owner defaults are valid foundation settings', () {
      expect(
        settingsPolicy.isFoundationSettingsValid(
          settings: settings(),
          evaluatedAtUtc: evaluatedAtUtc,
        ),
        true,
      );
    });

    test('Super Admin settings within channel caps are valid', () {
      expect(
        settingsPolicy.isFoundationSettingsValid(
          settings: settings(
            role: AgentPrivacyControlRole.superAdmin,
            chat: 90,
            transcript: 30,
            recording: 7,
            email: 90,
            whatsapp: 90,
          ),
          evaluatedAtUtc: evaluatedAtUtc,
        ),
        true,
      );
    });

    test('recording retention above 7 fails settings preview', () {
      expect(
        settingsPolicy.isFoundationSettingsValid(
          settings: settings(recording: 8),
          evaluatedAtUtc: evaluatedAtUtc,
        ),
        false,
      );
    });

    test('settings policy performs no production mutation', () {
      expect(settingsPolicy.previewOnly, true);
      expect(settingsPolicy.appliesProductionSettings, false);
      expect(settingsPolicy.writesFirestore, false);
      expect(settingsPolicy.grantsPermission, false);
      expect(settingsPolicy.consumesApproval, false);
      expect(settingsPolicy.overridesRuntimeGate, false);
      expect(settingsPolicy.deletesData, false);
    });
  });

  group('Phase 63 Step 1F user own-data export', () {
    test('user can export own redacted chat as JSON', () {
      final result = exportPolicy.evaluate(
        request: userExport(),
        dataExportMasterEnabled: true,
        strictDomainExportEnabled: false,
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.eligibleForSafeExportPackage, true);

      final preview = previewService.buildPreview(result);

      expect(preview.previewOnly, true);
      expect(preview.suggestedFileName, endsWith('.json'));
      expect(preview.containsRawUserPayload, false);
      expect(preview.containsSecrets, false);
      expect(preview.containsTokens, false);
      expect(preview.containsPaymentCredentials, false);
      expect(preview.containsRawCallRecording, false);
    });

    test('user cannot export another subject as OWN_DATA', () {
      final result = exportPolicy.evaluate(
        request: userExport(subject: 'user:999'),
        dataExportMasterEnabled: true,
        strictDomainExportEnabled: false,
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.status, AgentPrivacyExportStatus.blockedRoleScope);
    });

    test('unredacted chat export is blocked', () {
      final result = exportPolicy.evaluate(
        request: userExport(redacted: false),
        dataExportMasterEnabled: true,
        strictDomainExportEnabled: false,
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.status, AgentPrivacyExportStatus.blockedRedaction);
    });

    test('export master switch OFF blocks', () {
      final result = exportPolicy.evaluate(
        request: userExport(),
        dataExportMasterEnabled: false,
        strictDomainExportEnabled: false,
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.status, AgentPrivacyExportStatus.blockedRoleScope);
    });
  });

  group('Phase 63 Step 1F restricted export blocks', () {
    test('raw call recording is never generic-exportable', () {
      final result = exportPolicy.evaluate(
        request: userExport(
          kinds: <String>[AgentPrivacyDataKind.callRecording],
        ),
        dataExportMasterEnabled: true,
        strictDomainExportEnabled: false,
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.status, AgentPrivacyExportStatus.blockedRestrictedCritical);
    });

    test('auth/API/payment credentials are never exportable', () {
      for (final kind in <String>[
        AgentPrivacyDataKind.authSecret,
        AgentPrivacyDataKind.apiCredential,
        AgentPrivacyDataKind.paymentCredential,
      ]) {
        final result = exportPolicy.evaluate(
          request: userExport(kinds: <String>[kind]),
          dataExportMasterEnabled: true,
          strictDomainExportEnabled: false,
          evaluatedAtUtc: evaluatedAtUtc,
        );

        expect(
          result.status,
          AgentPrivacyExportStatus.blockedRestrictedCritical,
        );
      }
    });

    test('protected audit/security/finance evidence is excluded', () {
      for (final kind in <String>[
        AgentPrivacyDataKind.auditEvidence,
        AgentPrivacyDataKind.securityEvidence,
        AgentPrivacyDataKind.financeEvidence,
      ]) {
        final result = exportPolicy.evaluate(
          request: adminExport(kinds: <String>[kind]),
          dataExportMasterEnabled: true,
          strictDomainExportEnabled: true,
          evaluatedAtUtc: evaluatedAtUtc,
        );

        expect(
          result.status,
          AgentPrivacyExportStatus.blockedProtectedEvidence,
        );
      }
    });
  });

  group('Phase 63 Step 1F strict-domain export', () {
    test(
      'Student export requires strict switch + exact domain authorization',
      () {
        final denied = exportPolicy.evaluate(
          request: adminExport(
            kinds: <String>[AgentPrivacyDataKind.studentData],
            domain: AgentPrivacyAccessDomain.student,
            strictDomainAuthorization: false,
          ),
          dataExportMasterEnabled: true,
          strictDomainExportEnabled: true,
          evaluatedAtUtc: evaluatedAtUtc,
        );

        expect(denied.status, AgentPrivacyExportStatus.blockedStrictDomain);

        final allowed = exportPolicy.evaluate(
          request: adminExport(
            kinds: <String>[AgentPrivacyDataKind.studentData],
            domain: AgentPrivacyAccessDomain.student,
            strictDomainAuthorization: true,
          ),
          dataExportMasterEnabled: true,
          strictDomainExportEnabled: true,
          evaluatedAtUtc: evaluatedAtUtc,
        );

        expect(allowed.eligibleForSafeExportPackage, true);
      },
    );

    test('Safety export requires SAFETY domain', () {
      final result = exportPolicy.evaluate(
        request: adminExport(
          kinds: <String>[AgentPrivacyDataKind.safetyEmergencyData],
          domain: AgentPrivacyAccessDomain.safety,
          strictDomainAuthorization: true,
        ),
        dataExportMasterEnabled: true,
        strictDomainExportEnabled: true,
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.eligibleForSafeExportPackage, true);
    });

    test('Financial export requires FINANCIAL domain', () {
      final result = exportPolicy.evaluate(
        request: adminExport(
          kinds: <String>[AgentPrivacyDataKind.financialData],
          domain: AgentPrivacyAccessDomain.financial,
          strictDomainAuthorization: true,
        ),
        dataExportMasterEnabled: true,
        strictDomainExportEnabled: true,
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.eligibleForSafeExportPackage, true);
    });

    test('strict domain master OFF blocks strict export', () {
      final result = exportPolicy.evaluate(
        request: adminExport(
          kinds: <String>[AgentPrivacyDataKind.financialData],
          domain: AgentPrivacyAccessDomain.financial,
          strictDomainAuthorization: true,
        ),
        dataExportMasterEnabled: true,
        strictDomainExportEnabled: false,
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.status, AgentPrivacyExportStatus.blockedStrictDomain);
    });
  });

  group('Phase 63 Step 1F format/preview', () {
    test('CSV preview uses csv extension', () {
      final result = exportPolicy.evaluate(
        request: userExport(format: AgentPrivacyExportFormat.csv),
        dataExportMasterEnabled: true,
        strictDomainExportEnabled: false,
        evaluatedAtUtc: evaluatedAtUtc,
      );

      final preview = previewService.buildPreview(result);
      expect(preview.suggestedFileName, endsWith('.csv'));
    });

    test('ZIP package preview uses zip extension', () {
      final result = exportPolicy.evaluate(
        request: adminExport(),
        dataExportMasterEnabled: true,
        strictDomainExportEnabled: false,
        evaluatedAtUtc: evaluatedAtUtc,
      );

      final preview = previewService.buildPreview(result);
      expect(preview.suggestedFileName, endsWith('.zip'));
    });

    test('blocked decision cannot create download preview', () {
      final result = exportPolicy.evaluate(
        request: userExport(redacted: false),
        dataExportMasterEnabled: true,
        strictDomainExportEnabled: false,
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(() => previewService.buildPreview(result), throwsFormatException);
    });

    test('export/preview has zero execution authority', () {
      expect(exportPolicy.eligibilityOnly, true);
      expect(exportPolicy.fetchesUserData, false);
      expect(exportPolicy.generatesFile, false);
      expect(exportPolicy.deliversDownload, false);
      expect(exportPolicy.readsFirestore, false);
      expect(exportPolicy.writesFirestore, false);
      expect(exportPolicy.callsProvider, false);
      expect(exportPolicy.grantsPermission, false);
      expect(exportPolicy.consumesApproval, false);
      expect(exportPolicy.overridesRuntimeGate, false);
      expect(exportPolicy.writesBusinessData, false);
      expect(exportPolicy.deletesData, false);

      expect(previewService.previewOnly, true);
      expect(previewService.fetchesUserData, false);
      expect(previewService.generatesFile, false);
      expect(previewService.deliversDownload, false);
      expect(previewService.writesFilesystem, false);
      expect(previewService.writesFirestore, false);
      expect(previewService.callsProvider, false);
      expect(previewService.grantsPermission, false);
      expect(previewService.consumesApproval, false);
      expect(previewService.deletesData, false);
    });
  });
}
