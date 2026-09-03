import 'package:flutter/material.dart';

import '../data/vehicle_data.dart';
import '../models/vehicle_model.dart';
import '../widgets/vehicle_card.dart';
import '../cargo/screens/cargo_booking_details_screen.dart';

class CargoSelectionScreen extends StatelessWidget {
  final String serviceType;

  const CargoSelectionScreen({super.key, this.serviceType = 'cargo'});

  @override
  Widget build(BuildContext context) {
    final List<VehicleModel> vehicles = _vehiclesForService();

    return Scaffold(
      appBar: AppBar(title: Text(_screenTitle), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _heading,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            _subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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

  List<VehicleModel> _vehiclesForService() {
    final List<VehicleModel> allVehicles = VehicleData.cargoVehicles;

    switch (serviceType) {
      case 'buy_for_me':
      case 'pickup_my_item':
        return allVehicles.where((vehicle) {
          return vehicle.id == 'bike_delivery' ||
              vehicle.id == 'rickshaw_delivery';
        }).toList();

      default:
        return allVehicles;
    }
  }

  String get _screenTitle {
    switch (serviceType) {
      case 'parcel':
        return 'Send Parcel';
      case 'goods':
        return 'Move Goods';
      case 'shifting':
        return 'House Shifting';
      case 'pickup_my_item':
        return 'Pickup My Item';
      case 'buy_for_me':
        return 'Buy For Me';
      default:
        return 'Select Cargo Vehicle';
    }
  }

  String get _heading {
    switch (serviceType) {
      case 'parcel':
        return 'Choose Parcel Vehicle';
      case 'goods':
        return 'Choose Goods Vehicle';
      case 'shifting':
        return 'Choose Shifting Vehicle';
      case 'pickup_my_item':
        return 'Choose Pickup Vehicle';
      case 'buy_for_me':
        return 'Choose Delivery Vehicle';
      default:
        return 'Choose Cargo Vehicle';
    }
  }

  String get _subtitle {
    switch (serviceType) {
      case 'parcel':
        return 'Select a suitable vehicle for documents, packages or small items.';
      case 'goods':
        return 'Select a suitable vehicle for boxes, shop goods or larger items.';
      case 'shifting':
        return 'Select a suitable vehicle for furniture and household moving.';
      case 'pickup_my_item':
        return 'Choose Bike or Rickshaw to collect your ready item.';
      case 'buy_for_me':
        return 'Choose Bike or Rickshaw to buy and deliver your items.';
      default:
        return 'Select the vehicle that best suits your cargo or delivery.';
    }
  }

  void _selectCargoVehicle(BuildContext context, VehicleModel vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CargoBookingDetailsScreen(
          serviceType: serviceType,
          vehicle: vehicle,
        ),
      ),
    );
  }
}
