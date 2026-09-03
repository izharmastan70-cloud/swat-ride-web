class CargoPaymentGatewayResult {
  const CargoPaymentGatewayResult({
    required this.started,
    required this.success,
    required this.isBypass,
    required this.message,
    this.transactionId,
  });

  final bool started;
  final bool success;
  final bool isBypass;
  final String message;
  final String? transactionId;
}

class CargoPaymentGatewayService {
  const CargoPaymentGatewayService();

  /// TESTING ONLY.
  ///
  /// Keep TRUE while real billing/payment APIs are unavailable.
  /// Change to FALSE before production payment rollout.
  static const bool billingBypassEnabled = false;

  Future<CargoPaymentGatewayResult> startPayment({
    required String bookingId,
    required String method,
    required double amount,
  }) async {
    final String cleanBookingId = bookingId.trim();

    final String paymentMethod = method.trim().toLowerCase();

    if (cleanBookingId.isEmpty) {
      throw ArgumentError('bookingId cannot be empty.');
    }

    if (amount < 0 || !amount.isFinite) {
      throw ArgumentError('Invalid Cargo payment amount.');
    }

    if (paymentMethod == 'cash') {
      return const CargoPaymentGatewayResult(
        started: true,
        success: true,
        isBypass: false,
        message: 'Cash selected. No online charge required.',
      );
    }

    if (billingBypassEnabled) {
      final String transactionId =
          'CARGO_TEST_${DateTime.now().millisecondsSinceEpoch}';

      return CargoPaymentGatewayResult(
        started: true,
        success: true,
        isBypass: true,
        transactionId: transactionId,
        message: 'Cargo billing bypass successful for testing.',
      );
    }

    /*
    ============================================================
    REAL BILLING / PAYMENT CODE - ENABLE LATER
    ============================================================

    JAZZCASH:
    - Merchant/business credentials stay on secure backend.
    - Backend creates payment request.
    - Verify callback/webhook server-side.
    - Never keep merchant secrets in Flutter.
    - After verified payment:
        CargoBookingService.markPaymentPaid(...)

    EASYPAISA:
    - Merchant/business integration on trusted backend.
    - Backend creates transaction.
    - Verify Easypaisa callback server-side.
    - Never trust client-only success.
    - After verified payment:
        CargoBookingService.markPaymentPaid(...)

    BANK CARD:
    - Use PCI-compliant gateway/tokenization.
    - Never save raw card number/CVV in Firestore.
    - Server verifies transaction.
    - Then call markPaymentPaid(...).

    SWAT RIDE WALLET:
    - Use Firestore transaction / trusted backend.
    - Verify balance atomically.
    - Debit wallet once.
    - Prevent duplicate transaction IDs.
    - Then call markPaymentPaid(...).

    BUY FOR ME:
    - Advance must be verified before shopping.
    - Driver remains blocked until:
        advancePaid == true
        paymentStatus == 'paid'

    ============================================================
    */

    return CargoPaymentGatewayResult(
      started: false,
      success: false,
      isBypass: false,
      message: '$paymentMethod payment API is not connected.',
    );
  }
}
