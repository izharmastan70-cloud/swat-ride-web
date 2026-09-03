import '../models/agent_voice_super_admin_response.dart';

class AgentVoiceSuperAdminOutputPolicy {
  const AgentVoiceSuperAdminOutputPolicy();

  AgentVoiceSuperAdminResponse build({
    required String verifiedTextReport,
    required AgentVoiceSuperAdminOutputPreference preference,
    required List<String> verifiedSourceIds,
    required List<String> unavailableModuleIds,
    required DateTime now,
  }) {
    final String text = verifiedTextReport.trim();

    if (text.isEmpty) {
      throw const AgentVoiceSuperAdminResponseException(
        'A verified readable text report is required before any response.',
      );
    }

    final AgentVoiceSuperAdminResponse response = AgentVoiceSuperAdminResponse(
      textOutput: text,
      voicePlaybackEnabled: preference.voicePlaybackEnabled,

      // Voice output is deliberately the same verified report text in
      // Step 1B. A future shortened voice summary must be separately
      // proven to be a verified subset; it may never invent facts.
      voicePlaybackText: preference.voicePlaybackEnabled ? text : null,

      verifiedSourceIds: List<String>.unmodifiable(
        verifiedSourceIds
            .map((String value) => value.trim())
            .where((String value) => value.isNotEmpty),
      ),
      unavailableModuleIds: List<String>.unmodifiable(
        unavailableModuleIds
            .map((String value) => value.trim())
            .where((String value) => value.isNotEmpty),
      ),
      createdAt: now,
    );

    response.validate();
    return response;
  }

  bool get mayUseSpeechToTextProvider => false;
  bool get mayUseTextToSpeechProvider => false;
  bool get mayPersistRawAudio => false;
  bool get mayTrainOnRawAudio => false;
}
