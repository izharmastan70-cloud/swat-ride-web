import '../models/agent_email_delivery_receipt.dart';
import '../models/agent_email_ephemeral_auth_token.dart';
import '../models/agent_email_remote_transport_config.dart';
import '../models/agent_email_remote_transport_request.dart';
import '../models/agent_email_transport_handoff.dart';
import 'agent_email_transport.dart';

class AgentEmailVercelRemoteTransport implements AgentEmailTransport {
  const AgentEmailVercelRemoteTransport({required this.config});

  final AgentEmailRemoteTransportConfig config;

  @override
  String get providerId => config.providerId;

  @override
  bool get enabled => config.enabled;

  /// Phase 44-F3C intentionally does not include an HTTP executor.
  @override
  bool get liveSendCapable => false;

  bool get requiresFirebaseIdToken => config.requiresFirebaseIdToken;

  bool get requiresServerApprovalRecheck =>
      config.requiresServerApprovalRecheck;

  bool get requiresVerifiedSenderIdentity =>
      config.requiresVerifiedSenderIdentity;

  bool get providerSecretAvailableToFlutter => false;
  bool get firebaseAdminCredentialAvailableToFlutter => false;
  bool get httpExecutionAvailable => false;
  bool get directProviderExecutionAvailable => false;
  bool get mailboxWriteAvailable => false;

  AgentEmailRemoteTransportRequest buildRequest({
    required AgentEmailTransportHandoff handoff,
    required AgentEmailEphemeralAuthToken authToken,
    DateTime? createdAt,
  }) {
    config.validate();
    handoff.validate();
    authToken.validate();

    if (!config.enabled) {
      throw const AgentEmailVercelRemoteTransportException(
        'Remote Email transport is OFF.',
      );
    }

    if (config.serverBoundaryId !=
        AgentEmailServerBoundaryId.vercelServerless) {
      throw const AgentEmailVercelRemoteTransportException(
        'Vercel adapter requires vercel_serverless boundary.',
      );
    }

    if (config.providerId != handoff.providerId) {
      throw const AgentEmailVercelRemoteTransportException(
        'Transport provider does not match Email handoff provider.',
      );
    }

    if (!config.secureServerBoundaryRequired) {
      throw const AgentEmailVercelRemoteTransportException(
        'Remote Email transport security requirements are incomplete.',
      );
    }

    final AgentEmailRemoteTransportRequest request =
        AgentEmailRemoteTransportRequest(
          endpointUrl: config.endpointUrl,
          handoff: handoff,
          authToken: authToken,
          createdAt: createdAt ?? DateTime.now(),
        );

    request.validate();
    return request;
  }

  @override
  Future<AgentEmailDeliveryReceipt> deliver(
    AgentEmailTransportHandoff handoff,
  ) async {
    handoff.validate();

    final AgentEmailDeliveryReceipt receipt = AgentEmailDeliveryReceipt(
      receiptId: 'vercel_not_attempted_${handoff.handoffId}',
      handoffId: handoff.handoffId,
      providerId: providerId,
      status: enabled
          ? AgentEmailDeliveryStatus.notAttempted
          : AgentEmailDeliveryStatus.disabled,
      reason: enabled
          ? 'Authenticated Vercel request contract exists, but HTTP execution is intentionally OFF in Phase 44-F3C.'
          : 'Remote Email transport is disabled. No network/provider call was attempted.',
      createdAt: DateTime.now(),
    );

    receipt.validate();
    return receipt;
  }
}

class AgentEmailVercelRemoteTransportException implements Exception {
  const AgentEmailVercelRemoteTransportException(this.message);

  final String message;

  @override
  String toString() => 'AgentEmailVercelRemoteTransportException: $message';
}
