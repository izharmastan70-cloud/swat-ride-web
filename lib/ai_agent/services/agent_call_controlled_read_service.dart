import '../models/agent_call_service_request_draft.dart';
import 'agent_call_service_read_only_facade.dart';

// =========================================================
// AI AGENT - CONTROLLED CALL READ SERVICE
// =========================================================
//
// Phase 32 Step 7B.
//
// This is the safe boundary between:
// - Call Agent request
// - existing master/runtime/permission decisions
// - unified Food/Hotel/Tour read-only facade
//
// IMPORTANT:
//
// This class does NOT replace AgentRuntimeGate.
// This class does NOT replace AgentPermissionEngine.
//
// The authoritative engines must calculate the supplied
// decisions BEFORE this service is called.
//
// It intentionally fails closed.
//
// NO telephony provider.
// NO real outbound call.
// NO Firestore write.
// NO booking mutation.
// NO payment/refund.
// NO account enforcement.

class AgentCallReadAuthorization {
  final bool callAgentMasterEnabled;
  final bool runtimeAllowed;
  final bool permissionAllowed;
  final bool approvalSatisfied;

  final String reason;

  const AgentCallReadAuthorization({
    required this.callAgentMasterEnabled,
    required this.runtimeAllowed,
    required this.permissionAllowed,
    required this.approvalSatisfied,
    this.reason = '',
  });

  bool get isAllowed =>
      callAgentMasterEnabled &&
      runtimeAllowed &&
      permissionAllowed &&
      approvalSatisfied;

  void validate() {
    if (!isAllowed &&
        reason.trim().isEmpty) {
      throw const AgentCallControlledReadException(
        'Blocked Call read authorization requires a reason.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'callAgentMasterEnabled':
          callAgentMasterEnabled,
      'runtimeAllowed':
          runtimeAllowed,
      'permissionAllowed':
          permissionAllowed,
      'approvalSatisfied':
          approvalSatisfied,
      'isAllowed':
          isAllowed,
      'reason':
          reason,
    };
  }
}

class AgentCallControlledReadService {
  final AgentCallServiceReadOnlyFacade facade;

  AgentCallControlledReadService({
    AgentCallServiceReadOnlyFacade? facade,
  }) : facade =
            facade ??
            AgentCallServiceReadOnlyFacade();

  AgentCallServiceRequestDraft
      buildAuthorizedStatusDraft({
    required AgentCallReadAuthorization
        authorization,
    required String serviceType,
    required String customerName,
    required String contactPhoneMasked,
    required String referenceId,
    required Map<String, dynamic>
        sanitizedData,
  }) {
    authorization.validate();

    if (!authorization.isAllowed) {
      throw AgentCallControlledReadException(
        'Call read blocked: ${authorization.reason.trim()}',
      );
    }

    if (contactPhoneMasked.trim().isEmpty) {
      throw const AgentCallControlledReadException(
        'A masked contact phone is required.',
      );
    }

    final AgentCallServiceRequestDraft draft =
        facade.buildStatusDraft(
      serviceType:
          serviceType,
      customerName:
          customerName,
      contactPhoneMasked:
          contactPhoneMasked,
      referenceId:
          referenceId,
      sanitizedData:
          sanitizedData,
    );

    draft.validate();

    return draft;
  }
}

class AgentCallControlledReadException
    implements Exception {
  final String message;

  const AgentCallControlledReadException(
    this.message,
  );

  @override
  String toString() =>
      'AgentCallControlledReadException: $message';
}