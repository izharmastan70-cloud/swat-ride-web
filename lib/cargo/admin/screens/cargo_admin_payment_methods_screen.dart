import 'package:flutter/material.dart';

import '../../models/cargo_pricing_model.dart';
import '../../services/cargo_pricing_config_service.dart';

class CargoAdminPaymentMethodsScreen extends StatelessWidget {
  const CargoAdminPaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CargoPricingConfigService service = CargoPricingConfigService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargo Payment Methods'),
        centerTitle: true,
      ),
      body: StreamBuilder<CargoPricingModel>(
        stream: service.watchPricing(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load payment settings: '
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final CargoPricingModel pricing =
              snapshot.data ?? CargoPricingModel.defaults();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Enable or disable Cargo payment methods. '
                'Changes are stored in Firestore and do not '
                'require a customer app update.',
                style: TextStyle(height: 1.4),
              ),

              const SizedBox(height: 18),

              _paymentSwitch(
                context: context,
                service: service,
                title: 'Cash',
                subtitle: 'Allow payment in cash.',
                method: 'cash',
                value: pricing.cashEnabled,
                icon: Icons.payments_outlined,
              ),

              _paymentSwitch(
                context: context,
                service: service,
                title: 'SWAT RIDE Wallet',
                subtitle: 'Allow Cargo payment through Wallet.',
                method: 'wallet',
                value: pricing.walletEnabled,
                icon: Icons.account_balance_wallet_outlined,
              ),

              _paymentSwitch(
                context: context,
                service: service,
                title: 'JazzCash',
                subtitle:
                    'Enable JazzCash option. Real gateway '
                    'remains billing-bypassed for testing.',
                method: 'jazzcash',
                value: pricing.jazzCashEnabled,
                icon: Icons.phone_android_outlined,
              ),

              _paymentSwitch(
                context: context,
                service: service,
                title: 'Easypaisa',
                subtitle:
                    'Enable Easypaisa option. Real gateway '
                    'remains billing-bypassed for testing.',
                method: 'easypaisa',
                value: pricing.easypaisaEnabled,
                icon: Icons.phone_iphone_outlined,
              ),

              _paymentSwitch(
                context: context,
                service: service,
                title: 'Bank Card',
                subtitle: 'Allow supported debit or credit cards.',
                method: 'card',
                value: pricing.cardEnabled,
                icon: Icons.credit_card_outlined,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _paymentSwitch({
    required BuildContext context,
    required CargoPricingConfigService service,
    required String title,
    required String subtitle,
    required String method,
    required bool value,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        secondary: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: (enabled) async {
          try {
            await service.setPaymentMethodEnabled(
              method: method,
              enabled: enabled,
            );
          } catch (error) {
            if (!context.mounted) {
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not update $title: $error')),
            );
          }
        },
      ),
    );
  }
}
