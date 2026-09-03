import '../constants/agent_privacy_export_delivery_constants.dart';
import 'agent_privacy_export_download_payload.dart';

class AgentPrivacyExportDeliveryHandoff {
  AgentPrivacyExportDeliveryHandoff({
    required this.status,
    required this.payload,
    required this.explicitUserGestureConfirmed,
    required this.trustedPlatformAdapterRequired,
    required this.reasonCode,
  }) {
    validate();
  }

  final String status;
  final AgentPrivacyExportDownloadPayload payload;

  final bool explicitUserGestureConfirmed;
  final bool trustedPlatformAdapterRequired;

  final String reasonCode;

  bool get readyForTrustedAdapter =>
      status == AgentPrivacyExportDeliveryStatus.readyForTrustedAdapter;

  bool get deliveryContractOnly => true;

  bool get downloadAlreadyDelivered => false;
  bool get autoDownloadTriggered => false;
  bool get permissionGranted => false;
  bool get approvalConsumed => false;
  bool get runtimeGateOverridden => false;
  bool get providerCalled => false;
  bool get businessWritePerformed => false;
  bool get deletionPerformed => false;

  void validate() {
    payload.validate();

    if (!AgentPrivacyExportDeliveryStatus.values.contains(status) ||
        reasonCode.trim().isEmpty ||
        !trustedPlatformAdapterRequired) {
      throw const FormatException('Invalid privacy export delivery handoff.');
    }

    if (readyForTrustedAdapter && !explicitUserGestureConfirmed) {
      throw const FormatException(
        'Trusted download handoff requires explicit user gesture.',
      );
    }
  }
}
