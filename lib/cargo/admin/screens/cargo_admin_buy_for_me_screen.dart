import 'package:flutter/material.dart';

import '../../models/cargo_pricing_model.dart';
import '../../services/cargo_pricing_config_service.dart';

class CargoAdminBuyForMeScreen extends StatefulWidget {
  const CargoAdminBuyForMeScreen({super.key});

  @override
  State<CargoAdminBuyForMeScreen> createState() =>
      _CargoAdminBuyForMeScreenState();
}

class _CargoAdminBuyForMeScreenState extends State<CargoAdminBuyForMeScreen> {
  final CargoPricingConfigService _service = CargoPricingConfigService();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _advanceController = TextEditingController();

  final TextEditingController _maxPurchaseController = TextEditingController();

  bool _enabled = true;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _advanceController.dispose();
    _maxPurchaseController.dispose();
    super.dispose();
  }

  void _load(CargoPricingModel pricing) {
    if (_loaded) {
      return;
    }

    _enabled = pricing.buyForMeEnabled;

    _advanceController.text = pricing.buyForMeAdvancePercentage.toString();

    _maxPurchaseController.text = pricing.buyForMeMaxPurchaseAmount.toString();

    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy For Me Controls'),
        centerTitle: true,
      ),
      body: StreamBuilder<CargoPricingModel>(
        stream: _service.watchPricing(),
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
                  'Could not load Buy For Me settings: '
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final CargoPricingModel pricing =
              snapshot.data ?? CargoPricingModel.defaults();

          _load(pricing);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Enable Buy For Me',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Admin can disable this service '
                    'without requiring an app update.',
                  ),
                  value: _enabled,
                  onChanged: (value) {
                    setState(() {
                      _enabled = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _advanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Required Advance %',
                    border: OutlineInputBorder(),
                    helperText:
                        'Example: 50 = half advance, 100 = full advance',
                  ),
                  validator: (value) {
                    final double? number = double.tryParse(value?.trim() ?? '');

                    if (number == null) {
                      return 'Enter a valid percentage.';
                    }

                    if (number < 0 || number > 100) {
                      return 'Percentage must be between 0 and 100.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _maxPurchaseController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Max Purchase Amount (Rs.)',
                    border: OutlineInputBorder(),
                    helperText: '0 = no custom maximum limit',
                  ),
                  validator: (value) {
                    final double? number = double.tryParse(value?.trim() ?? '');

                    if (number == null) {
                      return 'Enter a valid amount.';
                    }

                    if (number < 0) {
                      return 'Amount cannot be negative.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Buy For Me shopping remains blocked '
                    'until the required advance is verified. '
                    'Real JazzCash, Easypaisa, Wallet and '
                    'Card gateway charging remains bypassed '
                    'during the current testing phase.',
                    style: TextStyle(height: 1.4),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _saving ? 'Saving...' : 'Save Buy For Me Settings',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final CargoPricingModel current = await _service.getPricing();

      final double advance = double.parse(_advanceController.text.trim());

      final double maxPurchase = double.parse(
        _maxPurchaseController.text.trim(),
      );

      final CargoPricingModel updated = CargoPricingModel(
        baseFare: current.baseFare,
        perKmRate: current.perKmRate,
        perMinuteRate: current.perMinuteRate,
        weightChargePerKg: current.weightChargePerKg,
        loadingCharge: current.loadingCharge,
        unloadingCharge: current.unloadingCharge,
        adminCommissionPercentage: current.adminCommissionPercentage,
        surgeMultiplier: current.surgeMultiplier,
        surgeEnabled: current.surgeEnabled,

        cashEnabled: current.cashEnabled,
        walletEnabled: current.walletEnabled,
        jazzCashEnabled: current.jazzCashEnabled,
        easypaisaEnabled: current.easypaisaEnabled,
        cardEnabled: current.cardEnabled,

        buyForMeEnabled: _enabled,
        buyForMeAdvancePercentage: advance,
        buyForMeMaxPurchaseAmount: maxPurchase,
      );

      await _service.savePricing(updated);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buy For Me settings updated.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save Buy For Me settings: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}
