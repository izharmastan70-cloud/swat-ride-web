class AgentVoiceSuperAdminOutputPreference {
  const AgentVoiceSuperAdminOutputPreference({
    this.voicePlaybackEnabled = false,
  });

  final bool voicePlaybackEnabled;

  bool get textOutputEnabled => true;
  bool get textOutputMandatory => true;
  bool get voicePlaybackOptional => true;
}

class AgentVoiceSuperAdminResponse {
  const AgentVoiceSuperAdminResponse({
    required this.textOutput,
    required this.voicePlaybackEnabled,
    required this.voicePlaybackText,
    required this.verifiedSourceIds,
    required this.unavailableModuleIds,
    required this.createdAt,
  });

  final String textOutput;
  final bool voicePlaybackEnabled;

  /// When playback is enabled this must be derived from the same verified text
  /// report. Step 1B does not connect a TTS engine.
  final String? voicePlaybackText;

  final List<String> verifiedSourceIds;
  final List<String> unavailableModuleIds;
  final DateTime createdAt;

  bool get readableTextOutputMandatory => true;
  bool get mayPlayVoice => voicePlaybackEnabled && voicePlaybackText != null;

  /// Persistence is deliberately not implemented in Step 1B. The response is
  /// history-ready, but retention/access/deletion policy must gate storage.
  bool get historyReady => true;
  bool get persistentHistoryWritten => false;

  bool get rawAudioStored => false;
  bool get rawAudioUsedForTraining => false;

  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayMutateSafety => false;
  bool get mayCallProvider => false;
  bool get mayDeploy => false;

  void validate() {
    if (textOutput.trim().isEmpty) {
      throw const AgentVoiceSuperAdminResponseException(
        'Voice Super Admin readable text output is mandatory.',
      );
    }

    if (voicePlaybackEnabled &&
        (voicePlaybackText == null || voicePlaybackText!.trim().isEmpty)) {
      throw const AgentVoiceSuperAdminResponseException(
        'Voice playback cannot be enabled without verified playback text.',
      );
    }

    if (!voicePlaybackEnabled && voicePlaybackText != null) {
      throw const AgentVoiceSuperAdminResponseException(
        'Voice playback text must be absent when playback is OFF.',
      );
    }
  }
}

class AgentVoiceSuperAdminResponseException implements Exception {
  const AgentVoiceSuperAdminResponseException(this.message);

  final String message;

  @override
  String toString() => 'AgentVoiceSuperAdminResponseException: $message';
}
