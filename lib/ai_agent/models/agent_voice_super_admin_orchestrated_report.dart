import 'agent_voice_super_admin_response.dart';
import 'agent_voice_super_admin_verified_report.dart';

/// Final Phase 48 Step 2E result.
///
/// [verifiedReport] is the structured verified source-of-truth.
/// [response] is the mandatory readable text projection and optional identical
/// voice-playback text.
class AgentVoiceSuperAdminOrchestratedReport {
  const AgentVoiceSuperAdminOrchestratedReport({
    required this.verifiedReport,
    required this.response,
  });

  final AgentVoiceSuperAdminVerifiedReport verifiedReport;
  final AgentVoiceSuperAdminResponse response;

  void validate() {
    verifiedReport.validate();
    response.validate();

    if (response.textOutput.trim() != verifiedReport.readableText.trim()) {
      throw const AgentVoiceSuperAdminOrchestratedReportException(
        'Voice Super Admin response text must equal the verified report text.',
      );
    }

    if (response.voicePlaybackEnabled &&
        response.voicePlaybackText?.trim() !=
            verifiedReport.readableText.trim()) {
      throw const AgentVoiceSuperAdminOrchestratedReportException(
        'Voice playback text must equal the verified report text.',
      );
    }
  }

  bool get readableTextMandatory => true;
  bool get voicePlaybackOptional => true;
  bool get persistentHistoryWritten => false;
  bool get rawAudioStored => false;
  bool get rawAudioUsedForTraining => false;

  bool get grantsAuthority => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayMutateSafety => false;
  bool get mayCallProvider => false;
  bool get mayDeploy => false;
}

class AgentVoiceSuperAdminOrchestratedReportException implements Exception {
  const AgentVoiceSuperAdminOrchestratedReportException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentVoiceSuperAdminOrchestratedReportException: $message';
}
