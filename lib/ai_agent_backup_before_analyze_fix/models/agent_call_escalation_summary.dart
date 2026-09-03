// =========================================================
// AI AGENT — CALL ESCALATION SUMMARY
// =========================================================
//
// Required before transfer so the next human does not make the caller
// repeat the entire issue.

class AgentCallEscalationSummary {
  final String callerName;
  final String callerPhoneMasked;
  final String module;
  final String referenceId;
  final String problem;
  final String alreadyChecked;
  final String escalationReason;
  final String targetLevel;

  const AgentCallEscalationSummary({
    required this.callerName,
    required this.callerPhoneMasked,
    required this.module,
    required this.referenceId,
    required this.problem,
    required this.alreadyChecked,
    required this.escalationReason,
    required this.targetLevel,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        'callerName': callerName,
        'callerPhoneMasked': callerPhoneMasked,
        'module': module,
        'referenceId': referenceId,
        'problem': problem,
        'alreadyChecked': alreadyChecked,
        'escalationReason': escalationReason,
        'targetLevel': targetLevel,
      };
}
