import 'package:flutter/material.dart';

import '../../models/cargo_driver_application_model.dart';
import '../../services/cargo_driver_application_service.dart';

class CargoAdminDriversScreen extends StatelessWidget {
  const CargoAdminDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CargoDriverApplicationService service =
        CargoDriverApplicationService();

    return Scaffold(
      appBar: AppBar(title: const Text('Cargo Drivers'), centerTitle: true),
      body: StreamBuilder<List<CargoDriverApplicationModel>>(
        stream: service.watchAllApplications(),
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
                  'Could not load Cargo Drivers: '
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final List<CargoDriverApplicationModel> drivers =
              snapshot.data ?? <CargoDriverApplicationModel>[];

          if (drivers.isEmpty) {
            return const Center(
              child: Text('No Cargo Driver applications yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              return _driverCard(context, service, drivers[index]);
            },
          );
        },
      ),
    );
  }

  Widget _driverCard(
    BuildContext context,
    CargoDriverApplicationService service,
    CargoDriverApplicationModel driver,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Text(
            driver.fullName.isEmpty ? '?' : driver.fullName[0].toUpperCase(),
          ),
        ),
        title: Text(
          driver.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${driver.vehicleType} â€¢ ${driver.status}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _infoRow('Phone', driver.phone),
          _infoRow('CNIC', driver.cnicNumber),
          _infoRow('Vehicle', driver.vehicleNumber),
          _infoRow('Address', driver.address),
          _infoRow(
            'Commission %',
            driver.commissionPercentage > 0
                ? driver.commissionPercentage.toStringAsFixed(1)
                : 'Global default',
          ),
          _infoRow(
            'Outstanding Commission',
            'Rs. ${driver.outstandingCommission.toStringAsFixed(0)}',
          ),
          _infoRow(
            'Total Commission Paid',
            'Rs. ${driver.totalCommissionPaid.toStringAsFixed(0)}',
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (driver.status == CargoDriverApplicationModel.pending)
                ElevatedButton(
                  onPressed: () async {
                    await _runAction(
                      context,
                      () => service.approveApplication(
                        applicationId: driver.applicationId,
                      ),
                      'Cargo Driver approved.',
                    );
                  },
                  child: const Text('Approve'),
                ),

              if (driver.status == CargoDriverApplicationModel.pending)
                OutlinedButton(
                  onPressed: () async {
                    await _runAction(
                      context,
                      () => service.rejectApplication(
                        applicationId: driver.applicationId,
                      ),
                      'Cargo Driver rejected.',
                    );
                  },
                  child: const Text('Reject'),
                ),

              if (driver.status == CargoDriverApplicationModel.approved)
                OutlinedButton(
                  onPressed: () async {
                    await _runAction(
                      context,
                      () => service.suspendApplication(
                        applicationId: driver.applicationId,
                      ),
                      'Cargo Driver suspended.',
                    );
                  },
                  child: const Text('Suspend'),
                ),

              if (driver.status == CargoDriverApplicationModel.suspended)
                ElevatedButton(
                  onPressed: () async {
                    await _runAction(
                      context,
                      () => service.restoreApplication(
                        applicationId: driver.applicationId,
                      ),
                      'Cargo Driver restored.',
                    );
                  },
                  child: const Text('Restore'),
                ),

              OutlinedButton.icon(
                icon: const Icon(Icons.percent_outlined),
                label: const Text('Commission'),
                onPressed: () {
                  _editCommission(context, service, driver);
                },
              ),

              if (driver.outstandingCommission > 0)
                OutlinedButton.icon(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Settle'),
                  onPressed: () {
                    _settleCommission(context, service, driver);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _editCommission(
    BuildContext context,
    CargoDriverApplicationService service,
    CargoDriverApplicationModel driver,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: driver.commissionPercentage.toStringAsFixed(1),
    );

    final double? result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Driver Commission %'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: '0 = use global commission',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final double? value = double.tryParse(controller.text.trim());

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null || !context.mounted) {
      return;
    }

    await _runAction(
      context,
      () => service.updateCommissionPercentage(
        applicationId: driver.applicationId,
        commissionPercentage: result,
      ),
      'Cargo Driver commission updated.',
    );
  }

  Future<void> _settleCommission(
    BuildContext context,
    CargoDriverApplicationService service,
    CargoDriverApplicationModel driver,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: driver.outstandingCommission.toStringAsFixed(0),
    );

    final double? amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Settle Commission'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Outstanding: Rs. '
                '${driver.outstandingCommission.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Settlement Amount',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final double? value = double.tryParse(controller.text.trim());

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Settle'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (amount == null || !context.mounted) {
      return;
    }

    await _runAction(
      context,
      () => service.settleOutstandingCommission(
        applicationId: driver.applicationId,
        amount: amount,
      ),
      'Cargo Driver commission settlement recorded.',
    );
  }

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cargo Driver action failed: $error')),
      );
    }
  }
}
