import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Immutable, expiring project boundary for AI preparation work.
///
/// The trusted backend must issue and re-check this context before a real
/// provider or business operation. This client contract prevents accidental
/// cross-project routing and carries the exact scope into approvals and audits.
class AgentProjectContext {
  AgentProjectContext._({
    required this.tenantId,
    required this.projectId,
    required this.workspaceId,
    required List<String> allowedModules,
    required this.issuedAt,
    required this.expiresAt,
    required this.contextFingerprint,
  }) : allowedModules = List<String>.unmodifiable(allowedModules);

  final String tenantId;
  final String projectId;
  final String workspaceId;
  final List<String> allowedModules;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String contextFingerprint;

  factory AgentProjectContext.create({
    required String tenantId,
    required String projectId,
    required String workspaceId,
    required Iterable<String> allowedModules,
    required DateTime issuedAt,
    required DateTime expiresAt,
  }) {
    final List<String> normalizedModules = _normalizeModules(allowedModules);
    final AgentProjectContext context = AgentProjectContext._(
      tenantId: tenantId.trim(),
      projectId: projectId.trim(),
      workspaceId: workspaceId.trim(),
      allowedModules: normalizedModules,
      issuedAt: issuedAt.toUtc(),
      expiresAt: expiresAt.toUtc(),
      contextFingerprint: '',
    );

    context._validateFields();
    return AgentProjectContext._(
      tenantId: context.tenantId,
      projectId: context.projectId,
      workspaceId: context.workspaceId,
      allowedModules: context.allowedModules,
      issuedAt: context.issuedAt,
      expiresAt: context.expiresAt,
      contextFingerprint: context._fingerprint(),
    );
  }

  bool allowsModule(String module) => allowedModules.contains(module.trim());

  bool isExpiredAt(DateTime now) => !now.toUtc().isBefore(expiresAt);

  void validate({DateTime? now}) {
    _validateFields();
    if (contextFingerprint != _fingerprint()) {
      throw const FormatException('Project context fingerprint mismatch.');
    }
    if (now != null && isExpiredAt(now)) {
      throw const FormatException('Project context has expired.');
    }
  }

  Map<String, dynamic> toAuthorizationScope() => <String, dynamic>{
    'tenantId': tenantId,
    'projectId': projectId,
    'workspaceId': workspaceId,
    'allowedModules': allowedModules,
    'issuedAt': issuedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'contextFingerprint': contextFingerprint,
  };

  void _validateFields() {
    final RegExp identifier = RegExp(r'^[A-Za-z0-9_.:-]+$');
    if (!identifier.hasMatch(tenantId) ||
        !identifier.hasMatch(projectId) ||
        !identifier.hasMatch(workspaceId) ||
      allowedModules.any((String module) => !identifier.hasMatch(module)) ||
        allowedModules.isEmpty ||
        expiresAt.isBefore(issuedAt)) {
      throw const FormatException('Invalid project context.');
    }
  }

  String _fingerprint() => sha256
      .convert(
        utf8.encode(
          jsonEncode(<String, dynamic>{
            'tenantId': tenantId,
            'projectId': projectId,
            'workspaceId': workspaceId,
            'allowedModules': allowedModules,
            'issuedAt': issuedAt.toIso8601String(),
            'expiresAt': expiresAt.toIso8601String(),
          }),
        ),
      )
      .toString();

  static List<String> _normalizeModules(Iterable<String> modules) => modules
      .map((String module) => module.trim())
      .where((String module) => module.isNotEmpty)
      .toSet()
      .toList(growable: false)
    ..sort();
}