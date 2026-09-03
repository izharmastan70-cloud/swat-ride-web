import '../constants/agent_customer_whatsapp_constants.dart';

class AgentCustomerWhatsAppControlSettings {
  const AgentCustomerWhatsAppControlSettings({
    this.enabled = false,
    this.rideEnabled = false,
    this.foodEnabled = false,
    this.hotelEnabled = false,
    this.tourEnabled = false,
    this.cargoEnabled = false,
  });

  final bool enabled;
  final bool rideEnabled;
  final bool foodEnabled;
  final bool hotelEnabled;
  final bool tourEnabled;
  final bool cargoEnabled;

  /// Critical Phase 45 separation:
  /// turning the Customer WhatsApp Agent OFF must never disable the
  /// Admin/Super Admin control plane or core SWAT RIDE services.
  bool get adminControlPlaneRemainsAvailable => true;
  bool get coreSwatRideServicesRemainAvailable => true;

  /// WhatsApp customer messages are input, not authority.
  bool get whatsappMessageGrantsAuthority => false;

  /// Provider transport is intentionally not enabled by this pure model.
  bool get providerTransportEnabled => false;
  bool get webhookExecutionEnabled => false;
  bool get outboundMessageExecutionEnabled => false;

  /// Phase 46 Owner WhatsApp and Phase 47 Emergency WhatsApp stay separate.
  bool get ownerWhatsAppAuthorityIncluded => false;
  bool get emergencyWhatsAppAuthorityIncluded => false;

  bool isServiceEnabled(String service) {
    if (!enabled) return false;

    switch (service) {
      case AgentCustomerWhatsAppService.ride:
        return rideEnabled;
      case AgentCustomerWhatsAppService.food:
        return foodEnabled;
      case AgentCustomerWhatsAppService.hotel:
        return hotelEnabled;
      case AgentCustomerWhatsAppService.tour:
        return tourEnabled;
      case AgentCustomerWhatsAppService.cargo:
        return cargoEnabled;
      default:
        return false;
    }
  }

  AgentCustomerWhatsAppControlSettings copyWith({
    bool? enabled,
    bool? rideEnabled,
    bool? foodEnabled,
    bool? hotelEnabled,
    bool? tourEnabled,
    bool? cargoEnabled,
  }) {
    return AgentCustomerWhatsAppControlSettings(
      enabled: enabled ?? this.enabled,
      rideEnabled: rideEnabled ?? this.rideEnabled,
      foodEnabled: foodEnabled ?? this.foodEnabled,
      hotelEnabled: hotelEnabled ?? this.hotelEnabled,
      tourEnabled: tourEnabled ?? this.tourEnabled,
      cargoEnabled: cargoEnabled ?? this.cargoEnabled,
    );
  }
}
