import 'agent_voice_super_admin_report_orchestration_request.dart';

class AgentVoiceSuperAdminQueryPlanStatus {
  AgentVoiceSuperAdminQueryPlanStatus._();

  static const String planned = 'PLANNED';
  static const String unsupported = 'UNSUPPORTED';

  static const Set<String> values = <String>{planned, unsupported};
}

class AgentVoiceSuperAdminQueryPlan {
  const AgentVoiceSuperAdminQueryPlan({
    required this.status,
    required this.code,
    required this.intent,
    required this.normalizedQuery,
    required this.createdAt,
    this.reportRequest,
  });

  final String status;
  final String code;
  final String intent;
  final String normalizedQuery;
  final DateTime createdAt;
  final AgentVoiceSuperAdminReportOrchestrationRequest? reportRequest;

  bool get isPlanned => status == AgentVoiceSuperAdminQueryPlanStatus.planned;
  bool get isUnsupported =>
      status == AgentVoiceSuperAdminQueryPlanStatus.unsupported;

  bool get voiceInputGrantsAuthority => false;
  bool get textInputGrantsAuthority => false;
  bool get voiceprintGrantsAuthority => false;
  bool get grantsPermission => false;
  bool get executesConnector => false;
  bool get consumesApproval => false;
  bool get writesBusinessData => false;
  bool get mutatesSafety => false;
  bool get callsProvider => false;
  bool get usesSpeechToText => false;
  bool get usesTextToSpeech => false;
  bool get deploys => false;

  void validate() {
    if (!AgentVoiceSuperAdminQueryPlanStatus.values.contains(status) ||
        code.trim().isEmpty ||
        intent.trim().isEmpty ||
        normalizedQuery.trim().isEmpty) {
      throw const AgentVoiceSuperAdminQueryPlanException(
        'Voice Super Admin query plan is invalid.',
      );
    }

    if (isPlanned && reportRequest == null) {
      throw const AgentVoiceSuperAdminQueryPlanException(
        'A planned Voice Super Admin query requires an explicit report request.',
      );
    }

    if (isUnsupported && reportRequest != null) {
      throw const AgentVoiceSuperAdminQueryPlanException(
        'Unsupported Voice Super Admin query cannot carry an executable report request.',
      );
    }

    reportRequest?.validate();
  }
}

class AgentVoiceSuperAdminQueryPlanException implements Exception {
  const AgentVoiceSuperAdminQueryPlanException(this.message);

  final String message;

  @override
  String toString() => 'AgentVoiceSuperAdminQueryPlanException: $message';
}
