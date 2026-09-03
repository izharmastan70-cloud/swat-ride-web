class CargoPaymentGatewayResult {
  const CargoPaymentGatewayResult({
    required this.started,
    required this.message,
  });

  final bool started;
  final String message;
}

class CargoPaymentGatewayService {
  const CargoPaymentGatewayService();

  Future<CargoPaymentGatewayResult> startPayment({
    required String bookingId,
    required String method,
    required double amount,
  }) async {
    final String paymentMethod = method.trim().toLowerCase();

    if (paymentMethod == 'cash') {
      return const CargoPaymentGatewayResult(
        started: true,
        message: 'Cash payment selected. No online charge performed.',
      );
    }

    /*
    ============================================================
    REAL BILLING / PAYMENT CODE - CONNECT LATER
    ============================================================

    JAZZCASH:
    - Create merchant/business account.
    - Obtain merchant credentials securely from backend.
    - Create payment request from secure server/cloud function.
    - Never keep merchant secret/key in Flutter app.
    - Verify callback/webhook server-side.
    - Only after verified success call:
        CargoBookingService.markPaymentPaid(...)

    EASYPAISA:
    - Merchant/business integration.
    - Backend creates transaction request.
    - Server verifies Easypaisa response/callback.
    - Never trust client-only "success".
    - After verified success:
        CargoBookingService.markPaymentPaid(...)

    BANK CARD:
    - Connect PCI-compliant payment gateway.
    - Do NOT store raw card number, CVV or expiry in Firestore.
    - Use gateway tokenization / hosted payment flow.
    - Server verifies transaction before booking is marked paid.

    SWAT RIDE WALLET:
    - Use Firestore transaction / trusted backend.
    - Check balance atomically.
    - Debit customer wallet.
    - Credit appropriate settlement ledger.
    - Prevent duplicate transaction IDs.
    - Mark payment paid only after successful atomic transaction.

    BUY FOR ME:
    - Advance payment must be verified.
    - Driver shopping must remain blocked until:
        advancePaid == true
        paymentStatus == 'paid'

    ============================================================
    */

    return CargoPaymentGatewayResult(
      started: false,
      message:
          '$paymentMethod real payment integration is '
          'disabled until billing/API credentials are connected.',
    );
  }
}
