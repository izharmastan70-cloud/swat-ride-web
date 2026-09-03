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
      id: 'mehran',
      name: 'Suzuki Mehran',
      image: 'assets/images/Suzuki Alto.jpg',
      category: 'economy',
      baseFare: 120,
      perKm: 28,
      capacity: '4 Passengers',
      description: 'Affordable local economy ride',
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
      id: 'cultus',
      name: 'Suzuki Cultus',
      image: 'assets/images/Suzuki Alto.jpg',
      category: 'economy',
      baseFare: 165,
      perKm: 32,
      capacity: '4 Passengers',
      description: 'Comfortable economy ride',
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
      id: 'aqua',
      name: 'Toyota Aqua',
      image: 'assets/images/Toyota Corolla.jpg',
      category: 'compact_hybrid',
      baseFare: 220,
      perKm: 42,
      capacity: '4 Passengers',
      description: 'Efficient compact hybrid ride',
    ),

    VehicleModel(
      id: 'vitz',
      name: 'Toyota Vitz',
      image: 'assets/images/Toyota Corolla.jpg',
      category: 'compact_hybrid',
      baseFare: 210,
      perKm: 40,
      capacity: '4 Passengers',
      description: 'Compact city and valley ride',
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
      id: 'city',
      name: 'Honda City',
      image: 'assets/images/Toyota Corolla.jpg',
      category: 'sedan_comfort',
      baseFare: 250,
      perKm: 50,
      capacity: '4 Passengers',
      description: 'Comfortable sedan ride',
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
      id: 'prius',
      name: 'Toyota Prius',
      image: 'assets/images/Toyota Corolla.jpg',
      category: 'sedan_comfort',
      baseFare: 320,
      perKm: 62,
      capacity: '4 Passengers',
      description: 'Premium hybrid comfort ride',
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

    VehicleModel(
      id: 'fortuner',
      name: 'Toyota Fortuner',
      image: 'assets/images/Toyota Corolla.jpg',
      category: 'suv_4x4_mpv',
      baseFare: 550,
      perKm: 105,
      capacity: '7 Passengers',
      description: '4x4 ride for Swat terrain',
    ),

    VehicleModel(
      id: 'land_cruiser',
      name: 'Toyota Land Cruiser',
      image: 'assets/images/Toyota Corolla.jpg',
      category: 'suv_4x4_mpv',
      baseFare: 700,
      perKm: 135,
      capacity: '7 Passengers',
      description: 'Premium 4x4 ride for mountain routes',
    ),

    VehicleModel(
      id: 'prado',
      name: 'Toyota Prado',
      image: 'assets/images/Toyota Corolla.jpg',
      category: 'suv_4x4_mpv',
      baseFare: 650,
      perKm: 125,
      capacity: '7 Passengers',
      description: 'Premium 4x4 ride for mountain routes',
    ),

    VehicleModel(
      id: 'hiace',
      name: 'Toyota Hiace',
      image: 'assets/images/Toyota Corolla.jpg',
      category: 'suv_4x4_mpv',
      baseFare: 600,
      perKm: 110,
      capacity: '12 Passengers',
      description: 'Group and family transport',
    ),

    VehicleModel(
      id: 'other_vehicle',
      name: 'Other Vehicle',
      image: 'assets/images/Suzuki Alto.jpg',
      category: 'other',
      baseFare: 0,
      perKm: 0,
      capacity: 'Admin configured',
      description: 'Requires Admin vehicle and pricing mapping before activation',
    ),
  ];

  // =========================
  // CARGO / DELIVERY VEHICLES
  // =========================

  static const List<VehicleModel> cargoVehicles = [
    VehicleModel(
      id: 'bike_delivery',
      name: 'Bike Delivery',
      image: 'assets/images/bike.png.jpg',
      category: 'cargo',
      baseFare: 0,
      perKm: 0,
      capacity: 'Small items',
      description: 'Medicine, grocery, documents and small packages',
    ),
    VehicleModel(
      id: 'rickshaw_delivery',
      name: 'Rickshaw',
      image: 'assets/images/rickshaw.png.jpg',
      category: 'cargo',
      baseFare: 0,
      perKm: 0,
      capacity: 'Small to medium cargo',
      description: 'Local goods, shopping and household items',
    ),
  ];
}
