import '../models/agent_voice_super_admin_verified_report.dart';
import '../models/agent_voice_super_admin_verified_section.dart';

/// Pure composition layer.
///
/// It receives already-authorized, already-sanitized verified section results.
/// It does NOT call Firestore, module services, the Permission Engine, Runtime
/// Gate, Approval Engine, provider APIs, STT/TTS, or Safety mutation paths.
///
/// A future broker is responsible for exact Super Admin session + Permission +
/// Runtime + Audit before any source is asked to produce a section.
class AgentVoiceSuperAdminVerifiedComposition {
  const AgentVoiceSuperAdminVerifiedComposition();

  AgentVoiceSuperAdminVerifiedReport compose({
    required String reportId,
    required List<AgentVoiceSuperAdminVerifiedSection> requestedSections,
    required DateTime now,
  }) {
    final String cleanReportId = reportId.trim();

    if (cleanReportId.isEmpty || requestedSections.isEmpty) {
      throw const AgentVoiceSuperAdminVerifiedReportException(
        'Voice Super Admin composition requires reportId and sections.',
      );
    }

    final Set<String> seenModules = <String>{};
    final List<AgentVoiceSuperAdminVerifiedSection> sections =
        <AgentVoiceSuperAdminVerifiedSection>[];

    for (final AgentVoiceSuperAdminVerifiedSection section
        in requestedSections) {
      section.validate();

      if (!seenModules.add(section.moduleId)) {
        throw const AgentVoiceSuperAdminVerifiedReportException(
          'Voice Super Admin report cannot contain duplicate module sections.',
        );
      }

      sections.add(section);
    }

    final int verifiedCount = sections.where((
      AgentVoiceSuperAdminVerifiedSection item,
    ) {
      return item.isVerified;
    }).length;

    final String status;
    if (verifiedCount == sections.length) {
      status = AgentVoiceSuperAdminReportStatus.ready;
    } else if (verifiedCount == 0) {
      status = AgentVoiceSuperAdminReportStatus.unavailable;
    } else {
      status = AgentVoiceSuperAdminReportStatus.partial;
    }

    final StringBuffer text = StringBuffer();

    for (final AgentVoiceSuperAdminVerifiedSection section in sections) {
      if (text.isNotEmpty) {
        text.writeln();
      }

      text.write('${section.moduleId}: ');

      if (section.isVerified) {
        text.write(section.summaryText.trim());
      } else {
        text.write('UNAVAILABLE');

        final String reason = section.unavailableReason?.trim() ?? '';
        if (reason.isNotEmpty) {
          text.write(' - $reason');
        }
      }
    }

    final AgentVoiceSuperAdminVerifiedReport report =
        AgentVoiceSuperAdminVerifiedReport(
          reportId: cleanReportId,
          status: status,
          sections: List<AgentVoiceSuperAdminVerifiedSection>.unmodifiable(
            sections,
          ),
          readableText: text.toString().trim(),
          createdAt: now,
        );

    report.validate();
    return report;
  }

  bool get executesConnectors => false;
  bool get authenticatesOwner => false;
  bool get grantsPermission => false;
  bool get evaluatesRuntimeGate => false;
  bool get recordsAudit => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get writesBusinessData => false;
  bool get mutatesSafety => false;
  bool get callsProvider => false;
  bool get usesSpeechToText => false;
  bool get usesTextToSpeech => false;
  bool get deploys => false;
}
