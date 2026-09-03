import '../models/agent_privacy_export_download_payload.dart';

/// Platform-specific delivery must be implemented by a trusted UI/platform
/// adapter and invoked only after an explicit user gesture.
///
/// This contract grants no Agent authority and performs no delivery itself.
abstract interface class AgentPrivacyExportDeliveryContract {
  Future<void> deliverAfterExplicitUserGesture(
    AgentPrivacyExportDownloadPayload payload,
  );
}
