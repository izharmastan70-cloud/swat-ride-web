import '../constants/agent_omnichannel_constants.dart';
import 'agent_omnichannel_identity_privacy.dart';

class AgentOmnichannelContinuityMetadata {
  const AgentOmnichannelContinuityMetadata({
    required this.continuityId,
    required this.previousEnvelopeId,
    required this.previousExternalMessageRef,
    required this.previousChannel,
    required this.currentEnvelopeId,
    required this.currentExternalMessageRef,
    required this.currentChannel,
    required this.continuitySubjectRef,
    required this.previousReceivedAt,
    required this.currentReceivedAt,
    required this.hopCount,
    required this.generatedByTrustedBoundary,
  });

  final String continuityId;
  final String previousEnvelopeId;
  final String previousExternalMessageRef;
  final String previousChannel;
  final String currentEnvelopeId;
  final String currentExternalMessageRef;
  final String currentChannel;

  /// Pseudonymous subject reference only. This is routing continuity metadata,
  /// not a shared customer profile or cross-channel conversation memory.
  final String continuitySubjectRef;

  final DateTime previousReceivedAt;
  final DateTime currentReceivedAt;
  final int hopCount;
  final bool generatedByTrustedBoundary;

  bool get containsMessageHistory => false;
  bool get containsConversationSummary => false;
  bool get containsSharedCustomerContext => false;
  bool get loadsPriorChannelContent => false;
  bool get grantsAuthority => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;

  Duration get continuityAge =>
      currentReceivedAt.toUtc().difference(previousReceivedAt.toUtc());

  void validate() {
    if (continuityId.trim().isEmpty ||
        previousEnvelopeId.trim().isEmpty ||
        previousExternalMessageRef.trim().isEmpty ||
        currentEnvelopeId.trim().isEmpty ||
        currentExternalMessageRef.trim().isEmpty ||
        continuitySubjectRef.trim().isEmpty ||
        !AgentOmnichannelChannel.values.contains(previousChannel) ||
        !AgentOmnichannelChannel.values.contains(currentChannel) ||
        previousChannel == currentChannel ||
        hopCount < 1 ||
        hopCount > 8 ||
        currentReceivedAt.toUtc().isBefore(previousReceivedAt.toUtc())) {
      throw const AgentOmnichannelContractException(
        'Omnichannel continuity metadata is structurally invalid.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'continuityId': continuityId.trim(),
      'previousChannel': previousChannel,
      'currentChannel': currentChannel,
      'hopCount': hopCount,
      'generatedByTrustedBoundary': generatedByTrustedBoundary,
      'containsMessageHistory': false,
      'containsConversationSummary': false,
      'containsSharedCustomerContext': false,
      'loadsPriorChannelContent': false,
      'grantsAuthority': false,
      'mayGrantPermission': false,
      'mayConsumeApproval': false,
      'mayWriteBusinessData': false,
    });
  }
}
