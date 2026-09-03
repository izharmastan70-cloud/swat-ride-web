import '../models/agent_security_finding.dart';

// =========================================================
// AI AGENT - SECURITY POLICY AUDIT SERVICE
// =========================================================
//
// Phase 27 Step 4.
//
// Detects risky configuration/runtime metadata such as:
// - secret / credential exposure
// - testing or bypass flags
// - suspicious admin override indicators
// - unsafe debug/production combinations
//
// AUDIT ONLY:
// - no Firestore writes
// - no permission changes
// - no automatic account action
// - no tool execution
// - no secret value is copied into a finding

class AgentSecurityPolicyService {
  const AgentSecurityPolicyService();

  List<AgentSecurityFinding> auditConfiguration(
    Map<String, dynamic> configuration, {
    String roleId = '',
    String module = 'core',
  }) {
    final List<AgentSecurityFinding> findings =
        <AgentSecurityFinding>[];

    _scanMap(
      configuration,
      path: 'root',
      roleId: roleId,
      module: module,
      findings: findings,
    );

    return List<AgentSecurityFinding>.unmodifiable(
      findings,
    );
  }

  void _scanMap(
    Map<String, dynamic> input, {
    required String path,
    required String roleId,
    required String module,
    required List<AgentSecurityFinding> findings,
  }) {
    for (final MapEntry<String, dynamic> entry
        in input.entries) {
      final String key = entry.key.trim();

      final String normalizedKey =
          _normalize(key);

      final String currentPath =
          path == 'root'
              ? key
              : '$path.$key';

      if (_looksSecretKey(normalizedKey)) {
        findings.add(
          AgentSecurityFinding(
            findingType:
                AgentSecurityFindingType
                    .securityPolicyViolation,
            severity:
                AgentSecuritySeverity.critical,
            roleId: roleId,
            module: module,
            reason:
                'Secret/credential-like field detected in AI configuration metadata.',
            metadata: <String, dynamic>{
              'path': currentPath,
              'key': key,
              'valueRedacted': true,
            },
          ),
        );
      }

      if (_looksBypassKey(normalizedKey) &&
          _isEnabledLike(entry.value)) {
        findings.add(
          AgentSecurityFinding(
            findingType:
                AgentSecurityFindingType
                    .suspiciousRuntimeState,
            severity:
                AgentSecuritySeverity.high,
            roleId: roleId,
            module: module,
            reason:
                'Testing/bypass-like configuration appears enabled.',
            metadata: <String, dynamic>{
              'path': currentPath,
              'key': key,
            },
          ),
        );
      }

      if (_looksAdminOverrideKey(normalizedKey) &&
          _isEnabledLike(entry.value)) {
        findings.add(
          AgentSecurityFinding(
            findingType:
                AgentSecurityFindingType
                    .securityPolicyViolation,
            severity:
                AgentSecuritySeverity.high,
            roleId: roleId,
            module: module,
            reason:
                'Admin override/access-like configuration requires explicit authorization review.',
            metadata: <String, dynamic>{
              'path': currentPath,
              'key': key,
            },
          ),
        );
      }

      if (_looksDangerousProductionDebugKey(
            normalizedKey,
          ) &&
          _isEnabledLike(entry.value)) {
        findings.add(
          AgentSecurityFinding(
            findingType:
                AgentSecurityFindingType
                    .suspiciousRuntimeState,
            severity:
                AgentSecuritySeverity.warning,
            roleId: roleId,
            module: module,
            reason:
                'Debug/development-style runtime flag appears enabled and should be reviewed before production.',
            metadata: <String, dynamic>{
              'path': currentPath,
              'key': key,
            },
          ),
        );
      }

      _scanValue(
        entry.value,
        path: currentPath,
        roleId: roleId,
        module: module,
        findings: findings,
      );
    }
  }

  void _scanValue(
    dynamic value, {
    required String path,
    required String roleId,
    required String module,
    required List<AgentSecurityFinding> findings,
  }) {
    if (value is Map) {
      _scanMap(
        value.map(
          (dynamic key, dynamic item) =>
              MapEntry<String, dynamic>(
            key.toString(),
            item,
          ),
        ),
        path: path,
        roleId: roleId,
        module: module,
        findings: findings,
      );

      return;
    }

    if (value is Iterable) {
      int index = 0;

      for (final dynamic item in value) {
        _scanValue(
          item,
          path: '$path[$index]',
          roleId: roleId,
          module: module,
          findings: findings,
        );

        index++;
      }

      return;
    }

    if (value is String) {
      final String normalized =
          _normalize(value);

      if (_looksSuspiciousOperation(normalized)) {
        findings.add(
          AgentSecurityFinding(
            findingType:
                AgentSecurityFindingType
                    .suspiciousRuntimeState,
            severity:
                AgentSecuritySeverity.warning,
            roleId: roleId,
            module: module,
            reason:
                'Suspicious privileged-operation indicator detected in configuration/runtime metadata.',
            metadata: <String, dynamic>{
              'path': path,
              'valueRedacted': true,
            },
          ),
        );
      }

      if (_looksSecretValue(normalized)) {
        findings.add(
          AgentSecurityFinding(
            findingType:
                AgentSecurityFindingType
                    .securityPolicyViolation,
            severity:
                AgentSecuritySeverity.critical,
            roleId: roleId,
            module: module,
            reason:
                'Possible credential/secret material detected in a configuration value.',
            metadata: <String, dynamic>{
              'path': path,
              'valueRedacted': true,
            },
          ),
        );
      }
    }
  }

  bool _looksSecretKey(String key) {
    const List<String> fragments = <String>[
      'password',
      'passwd',
      'secret',
      'token',
      'apikey',
      'privatekey',
      'authorization',
      'credential',
      'serviceaccount',
      'gatewaykey',
      'banklogin',
    ];

    return fragments.any(key.contains);
  }

  bool _looksBypassKey(String key) {
    const List<String> fragments = <String>[
      'bypass',
      'skipauth',
      'skippermission',
      'disablepermission',
      'disableauth',
      'testingbypass',
      'testbypass',
      'forceallow',
      'allowall',
    ];

    return fragments.any(key.contains);
  }

  bool _looksAdminOverrideKey(String key) {
    const List<String> fragments = <String>[
      'adminoverride',
      'superadminoverride',
      'forceadmin',
      'adminbypass',
      'unrestrictedadmin',
      'adminaccessall',
    ];

    return fragments.any(key.contains);
  }

  bool _looksDangerousProductionDebugKey(
    String key,
  ) {
    const List<String> fragments = <String>[
      'debugmode',
      'developmentmode',
      'devmode',
      'testmode',
      'testingmode',
      'fakepayment',
      'fakeapproval',
    ];

    return fragments.any(key.contains);
  }

  bool _looksSuspiciousOperation(String value) {
    const List<String> fragments = <String>[
      'bypass permission',
      'bypass authorization',
      'disable security',
      'ignore approval',
      'skip approval',
      'force admin',
      'unrestricted firestore',
      'unrestricted firebase',
      'deploy without approval',
      'auto suspend account',
      'auto ban account',
    ];

    return fragments.any(value.contains);
  }

  bool _looksSecretValue(String value) {
    return value.startsWith('bearer ') ||
        value.contains('private key-----') ||
        value.contains('begin private key') ||
        value.contains('service_account') ||
        value.contains('api_key=') ||
        value.contains('apikey=');
  }

  bool _isEnabledLike(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String normalized =
        _normalize(value?.toString() ?? '');

    return normalized == 'true' ||
        normalized == 'yes' ||
        normalized == 'on' ||
        normalized == 'enabled' ||
        normalized == '1';
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '',
        );
  }
}