import 'package:flutter/material.dart';

import '../data/vehicle_data.dart';
import '../models/vehicle_model.dart';
import '../widgets/vehicle_card.dart';

class CargoSelectionScreen extends StatelessWidget {
  const CargoSelectionScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<VehicleModel> vehicles = VehicleData.cargoVehicles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Cargo Vehicle'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choose Cargo Vehicle',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Select the vehicle that best suits your cargo or delivery.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 20),

          ...vehicles.map(
            (vehicle) => VehicleCard(
              vehicle: vehicle,
              onTap: () {
                _selectCargoVehicle(context, vehicle);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectCargoVehicle(
    BuildContext context,
    VehicleModel vehicle,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${vehicle.name} selected',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}