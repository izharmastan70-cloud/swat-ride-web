import '../models/vehicle_model.dart';

class VehicleData {
  // =========================
  // RIDE VEHICLES
  // =========================

  static const List<VehicleModel> rideVehicles = [
    VehicleModel(
      id: 'bike',
      name: 'Bike',
      image: 'assets/images/bike.png',
      category: 'ride',
      baseFare: 80,
      perKm: 25,
      capacity: '1 Passenger',
      description: 'Fast and affordable bike ride',
    ),

    VehicleModel(
      id: 'rickshaw',
      name: 'Rickshaw',
      image: 'assets/images/rickshaw.png',
      category: 'ride',
      baseFare: 120,
      perKm: 35,
      capacity: '3 Passengers',
      description: 'Comfortable local rickshaw ride',
    ),

    VehicleModel(
      id: 'alto',
      name: 'Suzuki Alto',
      image: 'assets/images/Suzuki Alto.jpg',
      category: 'ride',
      baseFare: 150,
      perKm: 30,
      capacity: '4 Passengers',
      description: 'Affordable and popular city ride',
    ),

    VehicleModel(
      id: 'wagon_r',
      name: 'Suzuki Wagon R',
      image: 'assets/images/Suzuki Wagon R.jpg',
      category: 'ride',
      baseFare: 180,
      perKm: 35,
      capacity: '4 Passengers',
      description: 'Comfortable family ride',
    ),

    VehicleModel(
      id: 'corolla',
      name: 'Toyota Corolla',
      image: 'assets/images/Toyota Corolla.jpg',
      category: 'ride',
      baseFare: 250,
      perKm: 50,
      capacity: '4 Passengers',
      description: 'Comfortable ride for city and long trips',
    ),

    VehicleModel(
      id: 'corolla_fielder',
      name: 'Corolla Fielder',
      image: 'assets/images/Corolla Fielder.jpg',
      category: 'ride',
      baseFare: 280,
      perKm: 55,
      capacity: '5 Passengers',
      description: 'Spacious family ride',
    ),

    VehicleModel(
      id: 'vitara',
      name: 'Suzuki Vitara',
      image: 'assets/images/Suzuki Vitara.jpg',
      category: 'ride',
      baseFare: 400,
      perKm: 80,
      capacity: '5 Passengers',
      description: 'Perfect for family and mountain trips',
    ),
  ];

  // =========================
  // CARGO / DELIVERY VEHICLES
  // =========================

  static const List<VehicleModel> cargoVehicles = [
    VehicleModel(
      id: 'bike_delivery',
      name: 'Bike Delivery',
      image: 'assets/images/bike.png',
      category: 'cargo',
      baseFare: 100,
      perKm: 25,
      capacity: 'Small Packages',
      description: 'Fast delivery for small packages',
    ),

    VehicleModel(
      id: 'suzuki_loader',
      name: 'Suzuki Loader',
      image: 'assets/images/Suzuki Alto.jpg',
      category: 'cargo',
      baseFare: 500,
      perKm: 70,
      capacity: 'Up to 800 KG',
      description: 'Suitable for local cargo delivery',
    ),
  ];
}