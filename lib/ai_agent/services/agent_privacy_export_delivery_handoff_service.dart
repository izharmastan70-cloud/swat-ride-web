import '../constants/agent_privacy_export_delivery_constants.dart';
import '../models/agent_privacy_export_delivery_handoff.dart';
import '../models/agent_privacy_export_download_payload.dart';

class AgentPrivacyExportDeliveryHandoffService {
  const AgentPrivacyExportDeliveryHandoffService();

  AgentPrivacyExportDeliveryHandoff prepare({
    required AgentPrivacyExportDownloadPayload payload,
    required bool explicitUserGestureConfirmed,
  }) {
    try {
      payload.validate();
    } catch (_) {
      return AgentPrivacyExportDeliveryHandoff(
        status: AgentPrivacyExportDeliveryStatus.blockedInvalidPackage,
        payload: payload,
        explicitUserGestureConfirmed: false,
        trustedPlatformAdapterRequired: true,
        reasonCode: 'invalid_safe_export_package',
      );
    }

    if (!explicitUserGestureConfirmed) {
      return AgentPrivacyExportDeliveryHandoff(
        status: AgentPrivacyExportDeliveryStatus.blockedNoUserGesture,
        payload: payload,
        explicitUserGestureConfirmed: false,
        trustedPlatformAdapterRequired: true,
        reasonCode: 'explicit_user_gesture_required',
      );
    }

    return AgentPrivacyExportDeliveryHandoff(
      status: AgentPrivacyExportDeliveryStatus.readyForTrustedAdapter,
      payload: payload,
      explicitUserGestureConfirmed: true,
      trustedPlatformAdapterRequired: true,
      reasonCode: 'ready_for_trusted_platform_download_adapter',
    );
  }

  bool get handoffOnly => true;
  bool get autoDownloads => false;
  bool get writesFilesystem => false;
  bool get uploadsCloudFile => false;
  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get overridesRuntimeGate => false;
  bool get callsProvider => false;
  bool get writesBusinessData => false;
  bool get deletesData => false;
}
