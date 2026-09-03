import 'agent_voice_super_admin_response.dart';
import 'agent_voice_super_admin_source_acquisition_request.dart';

/// Explicit multi-source request for one Voice Super Admin report.
///
/// There is no hidden broad query. Every requested module/read kind is visible
/// in [sourceRequests].
class AgentVoiceSuperAdminReportOrchestrationRequest {
  const AgentVoiceSuperAdminReportOrchestrationRequest({
    required this.reportId,
    required this.sourceRequests,
    this.outputPreference = const AgentVoiceSuperAdminOutputPreference(),
  });

  final String reportId;
  final List<AgentVoiceSuperAdminSourceAcquisitionRequest> sourceRequests;
  final AgentVoiceSuperAdminOutputPreference outputPreference;

  void validate() {
    if (reportId.trim().isEmpty || sourceRequests.isEmpty) {
      throw const AgentVoiceSuperAdminReportOrchestrationRequestException(
        'Voice Super Admin report requires a reportId and explicit source requests.',
      );
    }

    if (sourceRequests.length > 25) {
      throw const AgentVoiceSuperAdminReportOrchestrationRequestException(
        'Voice Super Admin report cannot request more than 25 source sections.',
      );
    }

    final Set<String> seenModules = <String>{};

    for (final AgentVoiceSuperAdminSourceAcquisitionRequest source
        in sourceRequests) {
      if (!source.hasStructurallyValidModuleAndKind ||
          !source.referenceIdWithinLimit) {
        throw const AgentVoiceSuperAdminReportOrchestrationRequestException(
          'Voice Super Admin source request is invalid.',
        );
      }

      final String normalizedModule = source.moduleId.trim().toUpperCase();

      if (!seenModules.add(normalizedModule)) {
        throw const AgentVoiceSuperAdminReportOrchestrationRequestException(
          'Voice Super Admin report cannot request the same module twice.',
        );
      }
    }
  }

  bool get containsHiddenBroadQuery => false;
  bool get grantsAuthority => false;
  bool get mayWriteBusinessData => false;
}

class AgentVoiceSuperAdminReportOrchestrationRequestException
    implements Exception {
  const AgentVoiceSuperAdminReportOrchestrationRequestException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentVoiceSuperAdminReportOrchestrationRequestException: $message';
}
