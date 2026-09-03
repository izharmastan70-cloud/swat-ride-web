class AgentVoiceSuperAdminSourceReadKind {
  AgentVoiceSuperAdminSourceReadKind._();

  static const String status = 'STATUS';
  static const String details = 'DETAILS';
  static const String dailySummary = 'DAILY_SUMMARY';

  static const Set<String> values = <String>{status, details, dailySummary};

  static bool isValid(String value) => values.contains(value);
}

/// One narrow source acquisition request after the Voice Super Admin
/// authorization boundary.
///
/// This request is data only. It grants no permission and cannot widen the
/// central read-only connector scope.
class AgentVoiceSuperAdminSourceAcquisitionRequest {
  const AgentVoiceSuperAdminSourceAcquisitionRequest({
    required this.moduleId,
    required this.readKind,
    this.referenceId = '',
  });

  final String moduleId;
  final String readKind;

  /// Exact existing business identifier when the target connector requires it.
  /// Core/System Health reads intentionally use an empty referenceId.
  final String referenceId;

  bool get hasStructurallyValidModuleAndKind =>
      moduleId.trim().isNotEmpty &&
      AgentVoiceSuperAdminSourceReadKind.isValid(readKind);

  bool get referenceIdWithinLimit => referenceId.trim().length <= 200;

  bool get grantsAuthority => false;
  bool get widensConnectorScope => false;
}
