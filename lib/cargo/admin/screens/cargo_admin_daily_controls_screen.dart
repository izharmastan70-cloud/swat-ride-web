import 'package:flutter/material.dart';

import '../../models/cargo_operational_settings_model.dart';
import '../../services/cargo_operational_settings_service.dart';

class CargoAdminDailyControlsScreen extends StatelessWidget {
  const CargoAdminDailyControlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CargoOperationalSettingsService service =
        CargoOperationalSettingsService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargo Daily Controls'),
        centerTitle: true,
      ),
      body: StreamBuilder<CargoOperationalSettingsModel>(
        stream: service.watchSettings(),
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
                  'Could not load Cargo controls: '
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final CargoOperationalSettingsModel settings =
              snapshot.data ?? CargoOperationalSettingsModel.defaults();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'These switches control Cargo operations '
                  'without requiring a customer app update. '
                  'Turning a feature off should block new use '
                  'while keeping existing records safe.',
                  style: TextStyle(height: 1.4),
                ),
              ),

              const SizedBox(height: 18),

              _controlSwitch(
                context: context,
                title: 'Cargo Service',
                subtitle: 'Master switch for the Cargo module.',
                icon: Icons.local_shipping_outlined,
                value: settings.cargoEnabled,
                onChanged: (enabled) {
                  return service.updateCargoEnabled(enabled);
                },
              ),

              _controlSwitch(
                context: context,
                title: 'Accept New Bookings',
                subtitle: 'Allow customers to create new Cargo orders.',
                icon: Icons.add_shopping_cart_outlined,
                value: settings.acceptingNewBookings,
                onChanged: (enabled) {
                  return service.updateAcceptingNewBookings(enabled);
                },
              ),

              _controlSwitch(
                context: context,
                title: 'Cargo Driver Applications',
                subtitle: 'Allow new Cargo Driver registrations.',
                icon: Icons.badge_outlined,
                value: settings.driverApplicationsEnabled,
                onChanged: (enabled) {
                  return service.updateDriverApplicationsEnabled(enabled);
                },
              ),

              _controlSwitch(
                context: context,
                title: 'Off-platform Reporting',
                subtitle:
                    'Allow customers to report drivers who '
                    'ask them to cancel and deal privately.',
                icon: Icons.report_outlined,
                value: settings.offPlatformReportingEnabled,
                onChanged: (enabled) {
                  return service.updateOffPlatformReportingEnabled(enabled);
                },
              ),

              const SizedBox(height: 12),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.price_change_outlined),
                  title: const Text(
                    'Surge & Pricing',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Base fare, per KM, time, weight, '
                    'commission and surge are managed from '
                    'Pricing & Commission.',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _controlSwitch({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Future<void> Function(bool enabled) onChanged,
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
            await onChanged(enabled);

            if (!context.mounted) {
              return;
            }

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$title updated.')));
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
