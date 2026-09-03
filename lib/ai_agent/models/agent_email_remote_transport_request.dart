import 'agent_email_ephemeral_auth_token.dart';
import 'agent_email_transport_handoff.dart';

class AgentEmailRemoteTransportRequest {
  const AgentEmailRemoteTransportRequest({
    required this.endpointUrl,
    required this.handoff,
    required this.authToken,
    required this.createdAt,
  });

  final String endpointUrl;
  final AgentEmailTransportHandoff handoff;

  /// Ephemeral memory-only auth material.
  /// Never serialize this field into logs, Firestore, or audit metadata.
  final AgentEmailEphemeralAuthToken authToken;

  final DateTime createdAt;

  bool get requiresAuthorizationHeader => true;
  bool get containsProviderApiKey => false;
  bool get containsFirebaseAdminCredential => false;
  bool get networkExecutionPerformed => false;
  bool get mayPersistAuthToken => false;
  bool get mayLogAuthToken => false;

  void validate() {
    handoff.validate();
    authToken.validate();

    final Uri? uri = Uri.tryParse(endpointUrl.trim());
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.trim().isEmpty) {
      throw const AgentEmailRemoteTransportRequestException(
        'Remote Email endpoint must be valid HTTPS.',
      );
    }
  }

  Map<String, dynamic> toSafeMetadata() {
    return <String, dynamic>{
      'endpointUrl': endpointUrl.trim(),
      'handoffId': handoff.handoffId,
      'authorizationRequestId': handoff.authorizationRequestId,
      'approvalId': handoff.approvalId,
      'draftId': handoff.draftId,
      'senderIdentityId': handoff.senderIdentityId,
      'providerId': handoff.providerId,
      'auth': authToken.toSafeMetadata(),
      'authTokenValueIncluded': false,
      'providerApiKeyIncluded': false,
      'firebaseAdminCredentialIncluded': false,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  Map<String, String> buildEphemeralHeaders() {
    validate();

    return <String, String>{
      'Authorization': 'Bearer ${authToken.firebaseIdToken}',
      'Content-Type': 'application/json',
      'X-Swat-Ride-Email-Handoff': handoff.handoffId,
      'X-Swat-Ride-Approval-Id': handoff.approvalId,
    };
  }
}

class AgentEmailRemoteTransportRequestException implements Exception {
  const AgentEmailRemoteTransportRequestException(this.message);

  final String message;

  @override
  String toString() => 'AgentEmailRemoteTransportRequestException: $message';
}
