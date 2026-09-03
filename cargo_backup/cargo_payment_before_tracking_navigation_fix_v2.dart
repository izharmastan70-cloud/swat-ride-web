import 'package:flutter/material.dart';

import '../models/cargo_pricing_model.dart';
import '../services/cargo_booking_service.dart';
import 'cargo_tracking_screen.dart';

class CargoPaymentScreen extends StatefulWidget {
  const CargoPaymentScreen({
    super.key,
    required this.bookingId,
    required this.serviceType,
    required this.pricing,
    required this.deliveryFare,
    required this.expectedItemAmount,
    required this.requiredAdvance,
  });

  final String bookingId;
  final String serviceType;
  final CargoPricingModel pricing;
  final double deliveryFare;
  final double expectedItemAmount;
  final double requiredAdvance;

  @override
  State<CargoPaymentScreen> createState() => _CargoPaymentScreenState();
}

class _CargoPaymentScreenState extends State<CargoPaymentScreen> {
  static const Color _yellow = Color(0xFFFFD60A);
  static const Color _background = Color(0xFF0D0D0D);
  static const Color _card = Color(0xFF1A1A1A);

  String? _selectedMethod;

  final CargoBookingService _bookingService = CargoBookingService();

  bool _savingPaymentMethod = false;

  bool get _isBuyForMe => widget.serviceType == 'buy_for_me';

  @override
  Widget build(BuildContext context) {
    final List<_PaymentOption> methods = _availableMethods;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('Cargo Payment'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _summaryCard(),

            const SizedBox(height: 24),

            const Text(
              'Choose Payment Method',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Only payment methods enabled by Cargo Admin are shown.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),

            const SizedBox(height: 18),

            if (methods.isEmpty)
              _noPaymentMethods()
            else
              ...methods.map((method) => _paymentTile(method)),

            const SizedBox(height: 24),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _selectedMethod == null || _savingPaymentMethod
                    ? null
                    : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _yellow,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isBuyForMe
                      ? 'Continue with Advance'
                      : 'Continue with Payment',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          if (_isBuyForMe) ...[
            _summaryRow('Expected item amount', widget.expectedItemAmount),
            const SizedBox(height: 8),
            _summaryRow(
              'Required advance',
              widget.requiredAdvance,
              highlight: true,
            ),
          ] else ...[
            _summaryRow('Cargo fare', widget.deliveryFare, highlight: true),
          ],

          const SizedBox(height: 12),

          Text(
            'Booking ID: ${widget.bookingId}',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool highlight = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          'Rs. ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: highlight ? _yellow : null,
            fontWeight: FontWeight.bold,
            fontSize: highlight ? 17 : 14,
          ),
        ),
      ],
    );
  }

  Widget _paymentTile(_PaymentOption option) {
    final bool selected = _selectedMethod == option.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? _yellow : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: RadioListTile<String>(
        value: option.id,
        activeColor: _yellow,
        title: Text(
          option.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(option.subtitle),
        secondary: Icon(option.icon, color: selected ? _yellow : Colors.grey),
      ),
    );
  }

  Widget _noPaymentMethods() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: _yellow),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No Cargo payment method is currently enabled. '
              'Please try again later.',
            ),
          ),
        ],
      ),
    );
  }

  List<_PaymentOption> get _availableMethods {
    final List<_PaymentOption> methods = <_PaymentOption>[];

    if (widget.pricing.cashEnabled && !_isBuyForMe) {
      methods.add(
        const _PaymentOption(
          id: 'cash',
          title: 'Cash',
          subtitle: 'Pay according to Cargo payment rules.',
          icon: Icons.payments_outlined,
        ),
      );
    }

    if (widget.pricing.walletEnabled) {
      methods.add(
        const _PaymentOption(
          id: 'wallet',
          title: 'SWAT RIDE Wallet',
          subtitle: 'Pay from your wallet balance.',
          icon: Icons.account_balance_wallet_outlined,
        ),
      );
    }

    if (widget.pricing.jazzCashEnabled) {
      methods.add(
        const _PaymentOption(
          id: 'jazzcash',
          title: 'JazzCash',
          subtitle: 'Pay through JazzCash.',
          icon: Icons.phone_android_outlined,
        ),
      );
    }

    if (widget.pricing.cardEnabled) {
      methods.add(
        const _PaymentOption(
          id: 'card',
          title: 'Bank Card',
          subtitle: 'Pay with an enabled debit or credit card.',
          icon: Icons.credit_card_outlined,
        ),
      );
    }
    if (widget.pricing.easypaisaEnabled) {
      methods.add(
        const _PaymentOption(
          id: 'easypaisa',
          title: 'Easypaisa',
          subtitle: 'Pay through Easypaisa.',
          icon: Icons.smartphone_outlined,
        ),
      );
    }

    return methods;
  }

  Future<void> _confirmPayment() async {
    final String? method = _selectedMethod;

    if (method == null) {
      return;
    }

    if (_isBuyForMe && method == 'cash') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Buy For Me advance must be paid before shopping starts.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _savingPaymentMethod = true;
    });

    try {
      await _bookingService.setPaymentMethod(
        bookingId: widget.bookingId,
        paymentMethod: method,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBuyForMe
                ? 'Advance payment method saved: $method. '
                      'Payment must be verified before shopping starts.'
                : 'Cargo payment method saved: $method.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save Cargo payment method: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingPaymentMethod = false;
        });
      }
    }
  }
}

class _PaymentOption {
  const _PaymentOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}
