// =========================================================
// AI AGENT — SAFE FAQ SERVICE
// =========================================================
//
// Deterministic fallback answers only.
// No booking/order status is fabricated.

class AgentSupportFaqService {
  const AgentSupportFaqService();

  String answer(String userMessage) {
    final String text = userMessage.toLowerCase();

    if (text.contains('support')) {
      return 'SWAT RIDE support can help with rides, food, hotels, tours, '
          'rewards and account questions. Transaction-specific issues will '
          'be checked only after the relevant module connector is available.';
    }

    if (text.contains('payment')) {
      return 'SWAT RIDE payment availability depends on the enabled payment '
          'methods for the selected service. Payment disputes and refunds '
          'require human/admin review.';
    }

    if (text.contains('ride')) {
      return 'For a ride, choose pickup and destination, select a vehicle, '
          'review the fare and confirm. Live ride details require the Ride '
          'connector, which is not connected to the AI Agent yet.';
    }

    if (text.contains('hotel')) {
      return 'Hotel availability and booking details will be provided from '
          'the Hotel system once its read-only AI connector is enabled.';
    }

    if (text.contains('tour')) {
      return 'Tour package and booking information will be provided from '
          'the Tourism system once its read-only AI connector is enabled.';
    }

    return 'I can provide general SWAT RIDE guidance. For a specific ride, '
        'order, booking, payment, safety or refund issue, the relevant '
        'module or human support must verify the real record.';
  }
}
