import '../constants/agent_action_ids.dart';
import '../models/agent_approval_request.dart';
import '../models/agent_email_draft.dart';
import '../models/agent_email_send_authorization_request.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import 'agent_permission_engine.dart';
import 'agent_runtime_gate.dart';

class AgentEmailSendPreflightStatus {
  AgentEmailSendPreflightStatus._();

  static const String readyForApprovalConsumption =
      'READY_FOR_APPROVAL_CONSUMPTION';
  static const String denied = 'DENIED';
  static const String invalid = 'INVALID';
  static const String approvalUnavailable = 'APPROVAL_UNAVAILABLE';
  static const String approvalMismatch = 'APPROVAL_MISMATCH';

  static const Set<String> values = <String>{
    readyForApprovalConsumption,
    denied,
    invalid,
    approvalUnavailable,
    approvalMismatch,
  };
}

class AgentEmailSendPreflightResult {
  const AgentEmailSendPreflightResult({
    required this.status,
    required this.permissionDecision,
    required this.runtimeDecision,
    required this.authorizationRequestId,
    required this.approvalId,
    required this.reason,
  });

  final String status;
  final AgentPermissionDecision? permissionDecision;
  final AgentPermissionDecision? runtimeDecision;
  final String authorizationRequestId;
  final String approvalId;
  final String reason;

  bool get readyForApprovalConsumption =>
      status == AgentEmailSendPreflightStatus.readyForApprovalConsumption;

  bool get denied => status == AgentEmailSendPreflightStatus.denied;

  bool get approvalConsumptionPerformed => false;
  bool get approvalMutationPerformed => false;
  bool get transportPerformed => false;
  bool get providerExecutionPerformed => false;
  bool get firestoreReadPerformed => false;
  bool get firestoreWritePerformed => false;
  bool get emailSent => false;
  bool get maySend => false;
  bool get mayConsumeApproval => false;
  bool get mayGrantPermission => false;
  bool get mayOpenNetworkConnection => false;
  bool get mayDeploy => false;
}

class AgentEmailSendPreflightCoordinator {
  const AgentEmailSendPreflightCoordinator({
    this.permissionEngine = const AgentPermissionEngine(),
    this.runtimeGate = const AgentRuntimeGate(),
    this.authorizationFactory = const AgentEmailSendAuthorizationFactory(),
  });

  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;
  final AgentEmailSendAuthorizationFactory authorizationFactory;

  bool get approvalConsumptionAllowed => false;
  bool get approvalMutationAllowed => false;
  bool get transportExecutionAllowed => false;
  bool get providerExecutionAllowed => false;
  bool get firestoreReadAllowed => false;
  bool get firestoreWriteAllowed => false;
  bool get smtpExecutionAllowed => false;
  bool get mailboxReadAllowed => false;
  bool get mailboxWriteAllowed => false;
  bool get deploymentAllowed => false;

  AgentEmailSendPreflightResult evaluate({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentEmailSendAuthorizationRequest authorizationRequest,
    required AgentEmailDraft currentDraft,
    required AgentApprovalRequest? approvalSnapshot,
  }) {
    try {
      settings.validate();
      authorizationRequest.validate();
      currentDraft.validate();
      approvalSnapshot?.validate();
    } catch (error) {
      return _result(
        status: AgentEmailSendPreflightStatus.invalid,
        authorizationRequest: authorizationRequest,
        approvalSnapshot: approvalSnapshot,
        reason: 'Invalid Email send preflight input: $error',
      );
    }

    if (role.roleId != authorizationRequest.roleId) {
      return _result(
        status: AgentEmailSendPreflightStatus.denied,
        authorizationRequest: authorizationRequest,
        approvalSnapshot: approvalSnapshot,
        reason: 'Authorization roleId does not match supplied AgentRole.',
      );
    }

    if (authorizationRequest.actionId != AgentActionId.sendEmail ||
        authorizationRequest.module != 'email') {
      return _result(
        status: AgentEmailSendPreflightStatus.denied,
        authorizationRequest: authorizationRequest,
        approvalSnapshot: approvalSnapshot,
        reason:
            'Email preflight only accepts the dedicated email.send action in the email module.',
      );
    }

    if (!authorizationFactory.stillMatchesApprovedDraft(
      request: authorizationRequest,
      currentDraft: currentDraft,
    )) {
      return _result(
        status: AgentEmailSendPreflightStatus.denied,
        authorizationRequest: authorizationRequest,
        approvalSnapshot: approvalSnapshot,
        reason:
            'Current Email Draft no longer exactly matches the authorized fingerprint.',
      );
    }

    final AgentPermissionDecision permission = permissionEngine.evaluate(
      role: role,
      actionId: AgentActionId.sendEmail,
    );

    if (!permission.needsApproval ||
        permission.isAllowed ||
        permission.isDenied) {
      return _result(
        status: AgentEmailSendPreflightStatus.denied,
        authorizationRequest: authorizationRequest,
        approvalSnapshot: approvalSnapshot,
        permissionDecision: permission,
        reason:
            'email.send must resolve to REQUIRE_APPROVAL before runtime preflight.',
      );
    }

    final AgentPermissionDecision runtime = runtimeGate.apply(
      settings: settings,
      role: role,
      permissionDecision: permission,
    );

    if (!runtime.needsApproval || runtime.isAllowed || runtime.isDenied) {
      return _result(
        status: AgentEmailSendPreflightStatus.denied,
        authorizationRequest: authorizationRequest,
        approvalSnapshot: approvalSnapshot,
        permissionDecision: permission,
        runtimeDecision: runtime,
        reason: 'Runtime Gate denied the Email send approval path.',
      );
    }

    if (approvalSnapshot == null) {
      return _result(
        status: AgentEmailSendPreflightStatus.approvalUnavailable,
        authorizationRequest: authorizationRequest,
        approvalSnapshot: null,
        permissionDecision: permission,
        runtimeDecision: runtime,
        reason: 'No central approval snapshot was supplied.',
      );
    }

    if (!approvalSnapshot.canBeConsumed) {
      return _result(
        status: AgentEmailSendPreflightStatus.approvalUnavailable,
        authorizationRequest: authorizationRequest,
        approvalSnapshot: approvalSnapshot,
        permissionDecision: permission,
        runtimeDecision: runtime,
        reason:
            'Approval is not APPROVED/unexpired/unconsumed and cannot be consumed.',
      );
    }

    final Map<String, dynamic> expectedScope = authorizationRequest
        .toApprovalActionScope();

    if (approvalSnapshot.roleId != authorizationRequest.roleId ||
        approvalSnapshot.actionId != AgentActionId.sendEmail ||
        approvalSnapshot.module != 'email' ||
        !_deepMapEquals(approvalSnapshot.actionScope, expectedScope)) {
      return _result(
        status: AgentEmailSendPreflightStatus.approvalMismatch,
        authorizationRequest: authorizationRequest,
        approvalSnapshot: approvalSnapshot,
        permissionDecision: permission,
        runtimeDecision: runtime,
        reason:
            'Approval role/action/module/actionScope does not exactly match the current Email authorization request.',
      );
    }

    return _result(
      status: AgentEmailSendPreflightStatus.readyForApprovalConsumption,
      authorizationRequest: authorizationRequest,
      approvalSnapshot: approvalSnapshot,
      permissionDecision: permission,
      runtimeDecision: runtime,
      reason:
          'Pure preflight passed. Central one-time approval consumption may be attempted by a separate execution boundary; transport remains disconnected.',
    );
  }

  AgentEmailSendPreflightResult _result({
    required String status,
    required AgentEmailSendAuthorizationRequest authorizationRequest,
    required AgentApprovalRequest? approvalSnapshot,
    required String reason,
    AgentPermissionDecision? permissionDecision,
    AgentPermissionDecision? runtimeDecision,
  }) {
    if (!AgentEmailSendPreflightStatus.values.contains(status)) {
      throw ArgumentError.value(
        status,
        'status',
        'Unknown Email send preflight status.',
      );
    }

    return AgentEmailSendPreflightResult(
      status: status,
      permissionDecision: permissionDecision,
      runtimeDecision: runtimeDecision,
      authorizationRequestId: authorizationRequest.authorizationRequestId
          .trim(),
      approvalId: approvalSnapshot?.approvalId.trim() ?? '',
      reason: reason,
    );
  }

  static bool _deepMapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;

    for (final String key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!_deepEquals(a[key], b[key])) return false;
    }

    return true;
  }

  static bool _deepEquals(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      final Map<String, dynamic> mapA = a.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );

      final Map<String, dynamic> mapB = b.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );

      return _deepMapEquals(mapA, mapB);
    }

    if (a is Iterable && b is Iterable) {
      final List<dynamic> listA = a.toList(growable: false);
      final List<dynamic> listB = b.toList(growable: false);

      if (listA.length != listB.length) return false;

      for (int index = 0; index < listA.length; index++) {
        if (!_deepEquals(listA[index], listB[index])) return false;
      }

      return true;
    }

    return a == b;
  }
}
