import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_enums.dart';

// =========================================================
// AGENT ROLE MODEL
// =========================================================
//
// Firestore collection: agent_roles
// Document ID == roleId
//
// Phase 1 scope only. Action lists are fully supported here.
// Phase 2 Permission Engine will enforce DEFAULT-DENY.

class AgentRole {
  static const String codeAgentRoleId = 'code_agent';
  static const String crashAgentRoleId = 'crash_agent';

  final String roleId;
  final String name;
  final String description;
  final String module;
  final bool enabled;
  final String mode;
  final List<String> allowedActions;
  final List<String> approvalRequiredActions;
  final List<String> forbiddenActions;
  final String aiClass;
  final String privacyLevel;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Client-side only. Never written to Firestore.
  final bool isFailClosed;

  const AgentRole({
    required this.roleId,
    required this.name,
    required this.description,
    required this.module,
    required this.enabled,
    required this.mode,
    this.allowedActions = const <String>[],
    this.approvalRequiredActions = const <String>[],
    this.forbiddenActions = const <String>[],
    required this.aiClass,
    required this.privacyLevel,
    required this.createdAt,
    this.updatedAt,
    this.isFailClosed = false,
  });

  bool get isOperational =>
      !isFailClosed && enabled && mode != AgentMode.off;

  void validate() {
    if (roleId.trim().isEmpty) {
      throw const AgentRoleValidationException('roleId cannot be empty.');
    }
    if (name.trim().isEmpty) {
      throw AgentRoleValidationException(
        'name cannot be empty for role "$roleId".',
      );
    }
    if (module.trim().isEmpty) {
      throw AgentRoleValidationException(
        'module cannot be empty for role "$roleId".',
      );
    }
    if (!AgentMode.isValid(mode)) {
      throw AgentRoleValidationException(
        'Invalid mode "$mode" for role "$roleId".',
      );
    }
    if (!AiClass.isValid(aiClass)) {
      throw AgentRoleValidationException(
        'Invalid aiClass "$aiClass" for role "$roleId".',
      );
    }
    if (!PrivacyLevel.isValid(privacyLevel)) {
      throw AgentRoleValidationException(
        'Invalid privacyLevel "$privacyLevel" for role "$roleId".',
      );
    }

    final bool isCodeAgent = roleId == codeAgentRoleId;
    final bool isCrashAgent = roleId == crashAgentRoleId;
    final bool isPaidCodeAi = aiClass == AiClass.paidCodeAi;

    if (isCodeAgent && !isPaidCodeAi) {
      throw AgentRoleValidationException(
        '"$codeAgentRoleId" must always use ${AiClass.paidCodeAi}.',
      );
    }

    if (isPaidCodeAi && !isCodeAgent) {
      throw AgentRoleValidationException(
        'Only "$codeAgentRoleId" may use ${AiClass.paidCodeAi}.',
      );
    }

    if (isCrashAgent && aiClass != AiClass.freeAi) {
      throw AgentRoleValidationException(
        '"$crashAgentRoleId" must stay on ${AiClass.freeAi} and hand '
        'technical issues to "$codeAgentRoleId".',
      );
    }
  }

  bool get isValid {
    try {
      validate();
      return true;
    } on AgentRoleValidationException {
      return false;
    }
  }

  AgentRole failClosed() {
    if (isValid) return this;

    final bool isCodeAgent = roleId == codeAgentRoleId;
    final bool isCrashAgent = roleId == crashAgentRoleId;

    String safeAiClass;
    if (isCodeAgent) {
      safeAiClass = AiClass.paidCodeAi;
    } else if (isCrashAgent) {
      safeAiClass = AiClass.freeAi;
    } else if (!AiClass.isValid(aiClass) || aiClass == AiClass.paidCodeAi) {
      safeAiClass = AiClass.freeAi;
    } else {
      safeAiClass = aiClass;
    }

    final String safePrivacyLevel = PrivacyLevel.isValid(privacyLevel)
        ? privacyLevel
        : PrivacyLevel.highlySensitive;

    final AgentRole corrected = copyWith(
      enabled: false,
      mode: AgentMode.off,
      aiClass: safeAiClass,
      privacyLevel: safePrivacyLevel,
      isFailClosed: true,
    );

    corrected.validate();
    return corrected;
  }

  AgentRole copyWith({
    String? roleId,
    String? name,
    String? description,
    String? module,
    bool? enabled,
    String? mode,
    List<String>? allowedActions,
    List<String>? approvalRequiredActions,
    List<String>? forbiddenActions,
    String? aiClass,
    String? privacyLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFailClosed,
  }) {
    return AgentRole(
      roleId: roleId ?? this.roleId,
      name: name ?? this.name,
      description: description ?? this.description,
      module: module ?? this.module,
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      allowedActions: allowedActions ?? this.allowedActions,
      approvalRequiredActions:
          approvalRequiredActions ?? this.approvalRequiredActions,
      forbiddenActions: forbiddenActions ?? this.forbiddenActions,
      aiClass: aiClass ?? this.aiClass,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFailClosed: isFailClosed ?? this.isFailClosed,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'roleId': roleId,
      'name': name,
      'description': description,
      'module': module,
      'enabled': enabled,
      'mode': mode,
      'allowedActions': allowedActions,
      'approvalRequiredActions': approvalRequiredActions,
      'forbiddenActions': forbiddenActions,
      'aiClass': aiClass,
      'privacyLevel': privacyLevel,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': _toTimestamp(updatedAt),
    };
  }

  factory AgentRole.fromMap(Map<String, dynamic> map) {
    return AgentRole(
      roleId: _string(map['roleId']),
      name: _string(map['name']),
      description: _string(map['description']),
      module: _string(map['module']),
      enabled: _bool(map['enabled']),
      mode: _string(map['mode'], fallback: AgentMode.off),
      allowedActions: _stringList(map['allowedActions']),
      approvalRequiredActions: _stringList(map['approvalRequiredActions']),
      forbiddenActions: _stringList(map['forbiddenActions']),
      aiClass: _string(map['aiClass'], fallback: AiClass.freeAi),
      privacyLevel:
          _string(map['privacyLevel'], fallback: PrivacyLevel.internal),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseNullableDateTime(map['updatedAt']),
    );
  }

  factory AgentRole.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(snapshot.data() ?? <String, dynamic>{});
    data['roleId'] ??= snapshot.id;
    return AgentRole.fromMap(data);
  }

  static String _string(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final String result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }

  static List<String> _stringList(dynamic value) {
    if (value is! Iterable<dynamic>) return const <String>[];
    return value
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static DateTime _parseDateTime(dynamic value) {
    return _parseNullableDateTime(value) ?? DateTime.now();
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Timestamp? _toTimestamp(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }
}

class AgentRoleValidationException implements Exception {
  final String message;
  const AgentRoleValidationException(this.message);

  @override
  String toString() => 'AgentRoleValidationException: $message';
}
