import 'package:flutter/material.dart';

import '../../models/cargo_pricing_model.dart';
import '../../services/cargo_pricing_config_service.dart';

class CargoAdminPricingScreen extends StatefulWidget {
  const CargoAdminPricingScreen({super.key});

  @override
  State<CargoAdminPricingScreen> createState() =>
      _CargoAdminPricingScreenState();
}

class _CargoAdminPricingScreenState extends State<CargoAdminPricingScreen> {
  final CargoPricingConfigService _service = CargoPricingConfigService();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _baseFareController = TextEditingController();

  final TextEditingController _perKmController = TextEditingController();

  final TextEditingController _perMinuteController = TextEditingController();

  final TextEditingController _weightController = TextEditingController();

  final TextEditingController _loadingController = TextEditingController();

  final TextEditingController _unloadingController = TextEditingController();

  final TextEditingController _commissionController = TextEditingController();

  final TextEditingController _surgeMultiplierController =
      TextEditingController();

  bool _surgeEnabled = false;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _baseFareController.dispose();
    _perKmController.dispose();
    _perMinuteController.dispose();
    _weightController.dispose();
    _loadingController.dispose();
    _unloadingController.dispose();
    _commissionController.dispose();
    _surgeMultiplierController.dispose();
    super.dispose();
  }

  void _loadPricing(CargoPricingModel pricing) {
    if (_loaded) {
      return;
    }

    _baseFareController.text = pricing.baseFare.toString();

    _perKmController.text = pricing.perKmRate.toString();

    _perMinuteController.text = pricing.perMinuteRate.toString();

    _weightController.text = pricing.weightChargePerKg.toString();

    _loadingController.text = pricing.loadingCharge.toString();

    _unloadingController.text = pricing.unloadingCharge.toString();

    _commissionController.text = pricing.adminCommissionPercentage.toString();

    _surgeMultiplierController.text = pricing.surgeMultiplier.toString();

    _surgeEnabled = pricing.surgeEnabled;
    _loaded = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargo Pricing & Commission'),
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
                  'Could not load Cargo pricing: '
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final CargoPricingModel pricing =
              snapshot.data ?? CargoPricingModel.defaults();

          _loadPricing(pricing);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle('Fare'),

                _numberField(_baseFareController, 'Base Fare'),

                _numberField(_perKmController, 'Per KM Rate'),

                _numberField(_perMinuteController, 'Per Minute Rate'),

                const SizedBox(height: 18),

                _sectionTitle('Cargo Charges'),

                _numberField(_weightController, 'Weight Charge Per KG'),

                _numberField(_loadingController, 'Loading Charge'),

                _numberField(_unloadingController, 'Unloading Charge'),

                const SizedBox(height: 18),

                _sectionTitle('Commission'),

                _numberField(
                  _commissionController,
                  'Admin Commission %',
                  percentage: true,
                ),

                const SizedBox(height: 18),

                _sectionTitle('Surge Pricing'),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Surge'),
                  subtitle: const Text(
                    'Admin can enable or disable Cargo surge pricing.',
                  ),
                  value: _surgeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _surgeEnabled = value;
                    });
                  },
                ),

                _numberField(_surgeMultiplierController, 'Surge Multiplier'),

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
                    label: Text(_saving ? 'Saving...' : 'Save Cargo Pricing'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool percentage = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          final double? number = double.tryParse(value?.trim() ?? '');

          if (number == null) {
            return 'Enter a valid number.';
          }

          if (number < 0) {
            return 'Value cannot be negative.';
          }

          if (percentage && number > 100) {
            return 'Percentage cannot exceed 100.';
          }

          return null;
        },
      ),
    );
  }

  double _value(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
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

      final CargoPricingModel updated = CargoPricingModel(
        baseFare: _value(_baseFareController),
        perKmRate: _value(_perKmController),
        perMinuteRate: _value(_perMinuteController),
        weightChargePerKg: _value(_weightController),
        loadingCharge: _value(_loadingController),
        unloadingCharge: _value(_unloadingController),
        adminCommissionPercentage: _value(_commissionController),
        surgeMultiplier: _value(_surgeMultiplierController),
        surgeEnabled: _surgeEnabled,

        cashEnabled: current.cashEnabled,
        walletEnabled: current.walletEnabled,
        jazzCashEnabled: current.jazzCashEnabled,
        easypaisaEnabled: current.easypaisaEnabled,
        cardEnabled: current.cardEnabled,

        buyForMeEnabled: current.buyForMeEnabled,
        buyForMeAdvancePercentage: current.buyForMeAdvancePercentage,
        buyForMeMaxPurchaseAmount: current.buyForMeMaxPurchaseAmount,
      );

      await _service.savePricing(updated);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargo pricing and commission updated.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save Cargo pricing: $error')),
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
