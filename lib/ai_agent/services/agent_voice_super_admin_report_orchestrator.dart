import '../models/agent_master_settings.dart';
import '../models/agent_role.dart';
import '../models/agent_voice_super_admin_authorization.dart';
import '../models/agent_voice_super_admin_orchestrated_report.dart';
import '../models/agent_voice_super_admin_report_orchestration_request.dart';
import '../models/agent_voice_super_admin_source_acquisition_request.dart';
import '../models/agent_voice_super_admin_verified_report.dart';
import '../models/agent_voice_super_admin_verified_section.dart';
import 'agent_voice_super_admin_authorized_source_acquisition.dart';
import 'agent_voice_super_admin_output_policy.dart';
import 'agent_voice_super_admin_verified_composition.dart';

/// Narrow interface used so orchestration can be tested independently while
/// production still delegates to the exact Step 2D-B acquisition service.
abstract class AgentVoiceSuperAdminSourceAcquisitionGateway {
  Future<AgentVoiceSuperAdminVerifiedSection> acquire({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentVoiceSuperAdminSessionBinding session,
    required AgentVoiceSuperAdminAuthorizationRequest authorizationRequest,
    required AgentVoiceSuperAdminSourceAcquisitionRequest sourceRequest,
    required DateTime now,
  });
}

class AgentVoiceSuperAdminStep2DAcquisitionGateway
    implements AgentVoiceSuperAdminSourceAcquisitionGateway {
  const AgentVoiceSuperAdminStep2DAcquisitionGateway({
    required this.acquisition,
  });

  final AgentVoiceSuperAdminAuthorizedSourceAcquisition acquisition;

  @override
  Future<AgentVoiceSuperAdminVerifiedSection> acquire({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentVoiceSuperAdminSessionBinding session,
    required AgentVoiceSuperAdminAuthorizationRequest authorizationRequest,
    required AgentVoiceSuperAdminSourceAcquisitionRequest sourceRequest,
    required DateTime now,
  }) {
    return acquisition.acquire(
      settings: settings,
      role: role,
      session: session,
      authorizationRequest: authorizationRequest,
      sourceRequest: sourceRequest,
      now: now,
    );
  }
}

/// Phase 48 Step 2E verified report orchestrator.
///
/// It owns no data authority:
/// - every source goes through Step 2D-B;
/// - it accepts only VERIFIED/UNAVAILABLE sections;
/// - composition remains in AgentVoiceSuperAdminVerifiedComposition;
/// - text/voice projection remains in AgentVoiceSuperAdminOutputPolicy.
class AgentVoiceSuperAdminReportOrchestrator {
  const AgentVoiceSuperAdminReportOrchestrator({
    required this.sourceGateway,
    this.composition = const AgentVoiceSuperAdminVerifiedComposition(),
    this.outputPolicy = const AgentVoiceSuperAdminOutputPolicy(),
  });

  final AgentVoiceSuperAdminSourceAcquisitionGateway sourceGateway;
  final AgentVoiceSuperAdminVerifiedComposition composition;
  final AgentVoiceSuperAdminOutputPolicy outputPolicy;

  Future<AgentVoiceSuperAdminOrchestratedReport> build({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentVoiceSuperAdminSessionBinding session,
    required AgentVoiceSuperAdminAuthorizationRequest authorizationRequest,
    required AgentVoiceSuperAdminReportOrchestrationRequest request,
    required DateTime now,
  }) async {
    // Fail before touching any connector when duplicate/invalid modules exist.
    request.validate();

    final List<AgentVoiceSuperAdminVerifiedSection> sections =
        <AgentVoiceSuperAdminVerifiedSection>[];

    for (final AgentVoiceSuperAdminSourceAcquisitionRequest sourceRequest
        in request.sourceRequests) {
      final AgentVoiceSuperAdminVerifiedSection acquired = await sourceGateway
          .acquire(
            settings: settings,
            role: role,
            session: session,
            authorizationRequest: authorizationRequest,
            sourceRequest: sourceRequest,
            now: now,
          );

      acquired.validate();
      sections.add(_forReadableComposition(acquired));
    }

    final AgentVoiceSuperAdminVerifiedReport report = composition.compose(
      reportId: request.reportId,
      requestedSections: sections,
      now: now,
    );

    final List<String> verifiedSourceIds = _unique(
      sections
          .where((AgentVoiceSuperAdminVerifiedSection item) => item.isVerified)
          .map((AgentVoiceSuperAdminVerifiedSection item) => item.sourceId),
    );

    final List<String> unavailableModuleIds = _unique(
      sections
          .where(
            (AgentVoiceSuperAdminVerifiedSection item) => item.isUnavailable,
          )
          .map((AgentVoiceSuperAdminVerifiedSection item) => item.moduleId),
    );

    final response = outputPolicy.build(
      verifiedTextReport: report.readableText,
      preference: request.outputPreference,
      verifiedSourceIds: verifiedSourceIds,
      unavailableModuleIds: unavailableModuleIds,
      now: now,
    );

    final AgentVoiceSuperAdminOrchestratedReport result =
        AgentVoiceSuperAdminOrchestratedReport(
          verifiedReport: report,
          response: response,
        );

    result.validate();
    return result;
  }

  /// Converts already-sanitized structured facts into deterministic readable
  /// text. This is presentation only: no inference, ranking, counting or
  /// missing-value fabrication is performed.
  AgentVoiceSuperAdminVerifiedSection _forReadableComposition(
    AgentVoiceSuperAdminVerifiedSection section,
  ) {
    if (section.isUnavailable) {
      return section;
    }

    final String summary = _verifiedFactsSummary(section.facts);

    return AgentVoiceSuperAdminVerifiedSection.verified(
      moduleId: section.moduleId,
      sourceId: section.sourceId,
      summaryText: summary,
      facts: section.facts,
      verifiedAt: section.verifiedAt,
    );
  }

  String _verifiedFactsSummary(Map<String, Object?> facts) {
    if (facts.isEmpty) {
      return 'VERIFIED - source returned no displayable facts.';
    }

    final List<MapEntry<String, Object?>> entries = facts.entries
        .take(12)
        .toList(growable: false);

    final StringBuffer text = StringBuffer('VERIFIED - ');

    for (int index = 0; index < entries.length; index++) {
      if (index > 0) {
        text.write('; ');
      }

      final MapEntry<String, Object?> entry = entries[index];
      text.write('${entry.key}: ${_renderValue(entry.value)}');
    }

    if (facts.length > entries.length) {
      text.write(
        '; +${facts.length - entries.length} additional verified fields',
      );
    }

    return text.toString();
  }

  String _renderValue(Object? value) {
    if (value == null) {
      return 'null';
    }

    if (value is Map) {
      final List<MapEntry<dynamic, dynamic>> entries = value.entries
          .take(6)
          .toList(growable: false);

      final String body = entries
          .map(
            (MapEntry<dynamic, dynamic> entry) =>
                '${entry.key}=${_renderValue(entry.value)}',
          )
          .join(', ');

      final int remaining = value.length - entries.length;
      return remaining > 0 ? '{$body, +$remaining more}' : '{$body}';
    }

    if (value is Iterable) {
      final List<Object?> values = value
          .cast<Object?>()
          .take(6)
          .toList(growable: false);

      final String body = values.map(_renderValue).join(', ');
      final int total = value.length;
      final int remaining = total - values.length;

      return remaining > 0 ? '[$body, +$remaining more]' : '[$body]';
    }

    final String compact = value
        .toString()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (compact.length <= 180) {
      return compact;
    }

    return '${compact.substring(0, 177)}...';
  }

  List<String> _unique(Iterable<String> values) {
    final Set<String> seen = <String>{};
    final List<String> output = <String>[];

    for (final String value in values) {
      final String clean = value.trim();
      if (clean.isNotEmpty && seen.add(clean)) {
        output.add(clean);
      }
    }

    return List<String>.unmodifiable(output);
  }

  bool get usesStep2DAuthorizedAcquisition => true;
  bool get usesExistingVerifiedComposition => true;
  bool get usesExistingOutputPolicy => true;
  bool get inventsAggregateTotals => false;
  bool get hiddenBroadQueryAllowed => false;
  bool get persistentHistoryWritten => false;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get writesBusinessData => false;
  bool get mutatesSafety => false;
  bool get callsProvider => false;
  bool get usesSpeechToText => false;
  bool get usesTextToSpeechProvider => false;
  bool get deploys => false;
}
