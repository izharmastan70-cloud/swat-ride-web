import 'agent_voice_super_admin_orchestrated_report.dart';
import 'agent_voice_super_admin_query_plan.dart';

class AgentVoiceSuperAdminExecutionStatus {
  AgentVoiceSuperAdminExecutionStatus._();

  static const String executed = 'EXECUTED';
  static const String unsupported = 'UNSUPPORTED';

  static const Set<String> values = <String>{executed, unsupported};
}

class AgentVoiceSuperAdminExecutionResult {
  const AgentVoiceSuperAdminExecutionResult({
    required this.status,
    required this.code,
    required this.queryPlan,
    required this.createdAt,
    this.report,
  });

  final String status;
  final String code;
  final AgentVoiceSuperAdminQueryPlan queryPlan;
  final AgentVoiceSuperAdminOrchestratedReport? report;
  final DateTime createdAt;

  bool get isExecuted => status == AgentVoiceSuperAdminExecutionStatus.executed;
  bool get isUnsupported =>
      status == AgentVoiceSuperAdminExecutionStatus.unsupported;

  String? get textOutput => report?.response.textOutput;

  void validate() {
    if (!AgentVoiceSuperAdminExecutionStatus.values.contains(status) ||
        code.trim().isEmpty) {
      throw const AgentVoiceSuperAdminExecutionResultException(
        'Voice Super Admin execution result is invalid.',
      );
    }

    queryPlan.validate();

    if (isExecuted && (!queryPlan.isPlanned || report == null)) {
      throw const AgentVoiceSuperAdminExecutionResultException(
        'Executed Voice Super Admin result requires a planned query and verified report.',
      );
    }

    if (isUnsupported && report != null) {
      throw const AgentVoiceSuperAdminExecutionResultException(
        'Unsupported Voice Super Admin result cannot contain a report.',
      );
    }

    report?.validate();
  }

  bool get queryTextGrantsAuthority => false;
  bool get voiceTranscriptGrantsAuthority => false;
  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get writesBusinessData => false;
  bool get mutatesSafety => false;
  bool get callsProvider => false;
  bool get storesRawAudio => false;
  bool get trainsOnRawAudio => false;
  bool get deploys => false;
}

class AgentVoiceSuperAdminExecutionResultException implements Exception {
  const AgentVoiceSuperAdminExecutionResultException(this.message);

  final String message;

  @override
  String toString() => 'AgentVoiceSuperAdminExecutionResultException: $message';
}
