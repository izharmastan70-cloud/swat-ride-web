import '../models/agent_role.dart';
import '../models/agent_security_finding.dart';
import 'agent_security_audit_service.dart';
import 'agent_security_policy_service.dart';
import 'agent_tool_permission_security_auditor.dart';

// =========================================================
// AI AGENT - UNIFIED SECURITY AGENT SERVICE
// =========================================================
//
// Phase 27 Step 7.
//
// Combines:
// - role/action security audit
// - configuration / secret / bypass audit
// - controlled tool permission audit
//
// AUDIT / REPORT ONLY:
// - no Firestore writes
// - no permission mutation
// - no role mutation
// - no connector activation
// - no account suspension/ban
// - no production deployment
//
// Existing Permission Engine + Runtime Gate stay authoritative.

class AgentSecurityAuditReport {
  final List<AgentSecurityFinding> findings;

  const AgentSecurityAuditReport({
    required this.findings,
  });

  int get total => findings.length;

  int get criticalCount => findings
      .where(
        (AgentSecurityFinding finding) =>
            finding.severity ==
            AgentSecuritySeverity.critical,
      )
      .length;

  int get highCount => findings
      .where(
        (AgentSecurityFinding finding) =>
            finding.severity ==
            AgentSecuritySeverity.high,
      )
      .length;

  int get warningCount => findings
      .where(
        (AgentSecurityFinding finding) =>
            finding.severity ==
            AgentSecuritySeverity.warning,
      )
      .length;

  int get infoCount => findings
      .where(
        (AgentSecurityFinding finding) =>
            finding.severity ==
            AgentSecuritySeverity.info,
      )
      .length;

  bool get hasCritical => criticalCount > 0;

  bool get hasHighOrCritical =>
      criticalCount > 0 || highCount > 0;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'total': total,
      'critical': criticalCount,
      'high': highCount,
      'warning': warningCount,
      'info': infoCount,
      'hasCritical': hasCritical,
      'hasHighOrCritical': hasHighOrCritical,
      'findings': findings
          .map(
            (AgentSecurityFinding finding) =>
                finding.toMap(),
          )
          .toList(growable: false),
    };
  }
}

class AgentSecurityAgentService {
  final AgentSecurityAuditService roleAuditService;
  final AgentSecurityPolicyService policyService;
  final AgentToolPermissionSecurityAuditor
      toolPermissionAuditor;

  const AgentSecurityAgentService({
    this.roleAuditService =
        const AgentSecurityAuditService(),
    this.policyService =
        const AgentSecurityPolicyService(),
    this.toolPermissionAuditor =
        const AgentToolPermissionSecurityAuditor(),
  });

  AgentSecurityAuditReport audit({
    required Iterable<AgentRole> roles,
    Map<String, dynamic> configuration =
        const <String, dynamic>{},
  }) {
    final List<AgentRole> roleList =
        roles.toList(growable: false);

    final List<AgentSecurityFinding> findings =
        <AgentSecurityFinding>[];

    findings.addAll(
      roleAuditService.auditRoles(roleList),
    );

    findings.addAll(
      policyService.auditConfiguration(
        configuration,
        module: 'core',
      ),
    );

    findings.addAll(
      toolPermissionAuditor.auditAllTools(
        roles: roleList,
      ),
    );

    final List<AgentSecurityFinding>
        validatedFindings =
        findings.where(
      (AgentSecurityFinding finding) =>
          finding.isValid,
    ).toList(growable: false);

    return AgentSecurityAuditReport(
      findings:
          List<AgentSecurityFinding>.unmodifiable(
        validatedFindings,
      ),
    );
  }
}