import '../constants/agent_omnichannel_constants.dart';

class AgentOmnichannelControlActorRole {
  AgentOmnichannelControlActorRole._();

  static const String admin = 'admin';
  static const String superAdmin = 'super_admin';

  static const Set<String> values = <String>{admin, superAdmin};
}

class AgentOmnichannelChannelControlSnapshot {
  const AgentOmnichannelChannelControlSnapshot({
    required this.globalOmnichannelEnabled,
    required this.appChatEnabled,
    required this.customerWhatsAppEnabled,
    required this.ownerWhatsAppEnabled,
    required this.emergencyWhatsAppEnabled,
    required this.emailEnabled,
    required this.phoneCallEnabled,
    required this.ownerVoiceEnabled,
    required this.whatsAppProviderLiveEnabled,
    required this.updatedByRoleId,
    required this.updatedAt,
  });

  final bool globalOmnichannelEnabled;
  final bool appChatEnabled;
  final bool customerWhatsAppEnabled;
  final bool ownerWhatsAppEnabled;
  final bool emergencyWhatsAppEnabled;
  final bool emailEnabled;
  final bool phoneCallEnabled;
  final bool ownerVoiceEnabled;

  /// Separate live transport switch for WhatsApp. Turning this OFF must not
  /// disable App Chat, Email, Phone Call, Owner Voice, or core SWAT RIDE.
  final bool whatsAppProviderLiveEnabled;

  final String updatedByRoleId;
  final DateTime updatedAt;

  bool isChannelEnabled(String channel) {
    switch (channel) {
      case AgentOmnichannelChannel.appChat:
        return appChatEnabled;
      case AgentOmnichannelChannel.customerWhatsApp:
        return customerWhatsAppEnabled;
      case AgentOmnichannelChannel.ownerWhatsApp:
        return ownerWhatsAppEnabled;
      case AgentOmnichannelChannel.emergencyWhatsApp:
        return emergencyWhatsAppEnabled;
      case AgentOmnichannelChannel.email:
        return emailEnabled;
      case AgentOmnichannelChannel.phoneCall:
        return phoneCallEnabled;
      case AgentOmnichannelChannel.ownerVoice:
        return ownerVoiceEnabled;
      default:
        return false;
    }
  }

  bool isWhatsAppChannel(String channel) =>
      channel == AgentOmnichannelChannel.customerWhatsApp ||
      channel == AgentOmnichannelChannel.ownerWhatsApp ||
      channel == AgentOmnichannelChannel.emergencyWhatsApp;

  bool isTransportEnabled(String channel) {
    if (!isWhatsAppChannel(channel)) {
      return true;
    }

    return whatsAppProviderLiveEnabled;
  }

  bool isRouteEnabled(String channel) =>
      globalOmnichannelEnabled &&
      isChannelEnabled(channel) &&
      isTransportEnabled(channel);

  bool get coreSwatRideEnabledByThisSnapshot => true;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayActivateProviderByItself => false;

  void validate() {
    if (!AgentOmnichannelControlActorRole.values.contains(updatedByRoleId)) {
      throw const AgentOmnichannelChannelControlException(
        'Omnichannel channel controls may be changed only by Admin/Super Admin.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'globalOmnichannelEnabled': globalOmnichannelEnabled,
      'appChatEnabled': appChatEnabled,
      'customerWhatsAppEnabled': customerWhatsAppEnabled,
      'ownerWhatsAppEnabled': ownerWhatsAppEnabled,
      'emergencyWhatsAppEnabled': emergencyWhatsAppEnabled,
      'emailEnabled': emailEnabled,
      'phoneCallEnabled': phoneCallEnabled,
      'ownerVoiceEnabled': ownerVoiceEnabled,
      'whatsAppProviderLiveEnabled': whatsAppProviderLiveEnabled,
      'updatedByRoleId': updatedByRoleId,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'coreSwatRideEnabledByThisSnapshot': true,
      'mayGrantPermission': false,
      'mayConsumeApproval': false,
      'mayWriteBusinessData': false,
      'mayActivateProviderByItself': false,
    });
  }
}

class AgentOmnichannelChannelControlUpdateRequest {
  const AgentOmnichannelChannelControlUpdateRequest({
    required this.requestId,
    required this.actorRoleId,
    required this.channel,
    required this.enabled,
    required this.requestedAt,
  });

  final String requestId;
  final String actorRoleId;
  final String channel;
  final bool enabled;
  final DateTime requestedAt;

  bool get directlyPersistsChange => false;
  bool get grantsAuthority => false;
  bool get changesProviderStateByItself => false;

  void validate() {
    if (requestId.trim().isEmpty ||
        !AgentOmnichannelControlActorRole.values.contains(actorRoleId) ||
        !AgentOmnichannelChannel.values.contains(channel)) {
      throw const AgentOmnichannelChannelControlException(
        'Invalid Admin/Super Admin omnichannel control request.',
      );
    }
  }
}

class AgentOmnichannelProviderControlUpdateRequest {
  const AgentOmnichannelProviderControlUpdateRequest({
    required this.requestId,
    required this.actorRoleId,
    required this.whatsAppProviderLiveEnabled,
    required this.requestedAt,
  });

  final String requestId;
  final String actorRoleId;
  final bool whatsAppProviderLiveEnabled;
  final DateTime requestedAt;

  bool get directlyPersistsChange => false;
  bool get activatesProviderByItself => false;

  void validate() {
    if (requestId.trim().isEmpty ||
        !AgentOmnichannelControlActorRole.values.contains(actorRoleId)) {
      throw const AgentOmnichannelChannelControlException(
        'Invalid Admin/Super Admin WhatsApp provider control request.',
      );
    }
  }
}

class AgentOmnichannelChannelControlException implements Exception {
  const AgentOmnichannelChannelControlException(this.message);

  final String message;

  @override
  String toString() => 'AgentOmnichannelChannelControlException: $message';
}
