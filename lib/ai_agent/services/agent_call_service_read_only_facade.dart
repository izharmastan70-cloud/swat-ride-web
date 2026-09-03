import '../models/agent_call_service_request_draft.dart';
import 'agent_call_food_read_only_bridge.dart';
import 'agent_call_hotel_read_only_bridge.dart';
import 'agent_call_tour_read_only_bridge.dart';

// =========================================================
// AI AGENT - CALL SERVICE READ-ONLY FACADE
// =========================================================
//
// Phase 32 Step 6.
//
// Gives Call Agent ONE simple interface for:
// - Food order status
// - Hotel booking status
// - Tour booking status
//
// Existing module bridges remain responsible for:
// - sanitization
// - privacy
// - module-specific formatting
//
// This facade does NOT execute writes.

class AgentCallServiceReadOnlyFacade {
  final AgentCallFoodReadOnlyBridge foodBridge;
  final AgentCallHotelReadOnlyBridge hotelBridge;
  final AgentCallTourReadOnlyBridge tourBridge;

  AgentCallServiceReadOnlyFacade({
    AgentCallFoodReadOnlyBridge? foodBridge,
    AgentCallHotelReadOnlyBridge? hotelBridge,
    AgentCallTourReadOnlyBridge? tourBridge,
  })  : foodBridge =
            foodBridge ??
            AgentCallFoodReadOnlyBridge(),
        hotelBridge =
            hotelBridge ??
            AgentCallHotelReadOnlyBridge(),
        tourBridge =
            tourBridge ??
            AgentCallTourReadOnlyBridge();

  AgentCallServiceRequestDraft
      buildStatusDraft({
    required String serviceType,
    required String customerName,
    required String contactPhoneMasked,
    required String referenceId,
    required Map<String, dynamic>
        sanitizedData,
  }) {
    switch (serviceType) {
      case AgentCallServiceType.food:
        foodBridge.verifySanitizedPayload(
          sanitizedData,
        );

        return foodBridge.buildOrderStatusDraft(
          customerName:
              customerName,
          contactPhoneMasked:
              contactPhoneMasked,
          orderId:
              referenceId,
          sanitizedOrderData:
              sanitizedData,
        );

      case AgentCallServiceType.hotel:
        hotelBridge.verifySanitizedPayload(
          sanitizedData,
        );

        return hotelBridge.buildBookingStatusDraft(
          customerName:
              customerName,
          contactPhoneMasked:
              contactPhoneMasked,
          bookingId:
              referenceId,
          sanitizedBookingData:
              sanitizedData,
        );

      case AgentCallServiceType.tour:
        tourBridge.verifySanitizedPayload(
          sanitizedData,
        );

        return tourBridge.buildBookingStatusDraft(
          customerName:
              customerName,
          contactPhoneMasked:
              contactPhoneMasked,
          bookingId:
              referenceId,
          sanitizedBookingData:
              sanitizedData,
        );
    }

    throw AgentCallServiceReadOnlyFacadeException(
      'Unsupported Call service type "$serviceType".',
    );
  }
}

class AgentCallServiceReadOnlyFacadeException
    implements Exception {
  final String message;

  const AgentCallServiceReadOnlyFacadeException(
    this.message,
  );

  @override
  String toString() =>
      'AgentCallServiceReadOnlyFacadeException: $message';
}