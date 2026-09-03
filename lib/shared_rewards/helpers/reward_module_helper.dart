// =============================================================
// SWAT RIDE - GLOBAL LOYALTY, REWARDS & PROMO ENGINE
// File: lib/shared_rewards/helpers/reward_module_helper.dart
//
// Shared module mapping used by every booking, order and Admin flow.
// =============================================================

import '../../rewards/models/reward_point_model.dart';

class RewardModuleHelper {
  const RewardModuleHelper._();

  /// Modules shown to normal customers.
  static const List<RewardModule> customerModules = [
    RewardModule.ride,
    RewardModule.studentRide,
    RewardModule.food,
    RewardModule.hotel,
    RewardModule.tourism,
    RewardModule.cargo,
    RewardModule.parcel,
    RewardModule.wallet,
  ];

  /// Driver, rider, owner, partner and guide earning roles.
  static const List<RewardModule> partnerModules = [
    RewardModule.rideDriver,
    RewardModule.studentDriver,
    RewardModule.foodDeliveryRider,
    RewardModule.restaurantPartner,
    RewardModule.hotelOwner,
    RewardModule.tourismDriver,
    RewardModule.tourGuide,
    RewardModule.cargoDriver,
    RewardModule.parcelDriver,
  ];

  /// Modules Admin can select for a global reward/promo rule.
  static const List<RewardModule> adminSelectableModules = [
    ...customerModules,
    ...partnerModules,
  ];

  static bool isCustomerModule(RewardModule module) {
    return customerModules.contains(module);
  }

  static bool isPartnerModule(RewardModule module) {
    return partnerModules.contains(module);
  }

  static bool isGlobalModule(RewardModule module) {
    return module == RewardModule.all;
  }

  static bool isFutureModule(RewardModule module) {
    return module == RewardModule.future;
  }

  static bool supportsModule({
    required Iterable<RewardModule> supportedModules,
    required RewardModule selectedModule,
  }) {
    final modules = supportedModules.toSet();

    if (modules.isEmpty) {
      return false;
    }

    return modules.contains(RewardModule.all) ||
        modules.contains(selectedModule);
  }

  static bool supportsAnyModule({
    required Iterable<RewardModule> supportedModules,
    required Iterable<RewardModule> selectedModules,
  }) {
    final supported = supportedModules.toSet();

    if (supported.contains(RewardModule.all)) {
      return true;
    }

    return selectedModules.any(supported.contains);
  }

  static bool supportsEveryModule({
    required Iterable<RewardModule> supportedModules,
    required Iterable<RewardModule> selectedModules,
  }) {
    final supported = supportedModules.toSet();

    if (supported.contains(RewardModule.all)) {
      return true;
    }

    return selectedModules.every(supported.contains);
  }

  /// Converts Firestore, route and legacy module names safely.
  /// Unknown values never crash the app and return [fallback].
  static RewardModule fromValue(
    dynamic value, {
    RewardModule fallback = RewardModule.future,
  }) {
    if (value is RewardModule) {
      return value;
    }

    final normalized = normalizeKey(value?.toString() ?? '');

    if (normalized.isEmpty) {
      return fallback;
    }

    final direct = RewardModule.values.where(
      (module) => normalizeKey(module.name) == normalized,
    );

    if (direct.isNotEmpty) {
      return direct.first;
    }

    return _aliases[normalized] ?? fallback;
  }

  static List<RewardModule> listFromValues(
    Iterable<dynamic>? values, {
    bool emptyMeansAll = false,
    bool includeFuture = false,
  }) {
    if (values == null || values.isEmpty) {
      return emptyMeansAll
          ? const [RewardModule.all]
          : const <RewardModule>[];
    }

    final modules = <RewardModule>{};

    for (final value in values) {
      final module = fromValue(value);

      if (module == RewardModule.future && !includeFuture) {
        continue;
      }

      modules.add(module);
    }

    if (modules.contains(RewardModule.all)) {
      return const [RewardModule.all];
    }

    return sortModules(modules);
  }

  static List<String> namesFromModules(
    Iterable<RewardModule> modules,
  ) {
    final unique = modules.toSet();

    if (unique.contains(RewardModule.all)) {
      return [RewardModule.all.name];
    }

    return sortModules(unique).map((module) => module.name).toList();
  }

  static List<RewardModule> sortModules(
    Iterable<RewardModule> modules,
  ) {
    final result = modules.toSet().toList();

    result.sort((first, second) {
      final firstIndex = RewardModule.values.indexOf(first);
      final secondIndex = RewardModule.values.indexOf(second);
      return firstIndex.compareTo(secondIndex);
    });

    return result;
  }

  static RewardModule customerModuleFor(RewardModule module) {
    switch (module) {
      case RewardModule.rideDriver:
        return RewardModule.ride;
      case RewardModule.studentDriver:
        return RewardModule.studentRide;
      case RewardModule.foodDeliveryRider:
      case RewardModule.restaurantPartner:
        return RewardModule.food;
      case RewardModule.hotelOwner:
        return RewardModule.hotel;
      case RewardModule.tourismDriver:
      case RewardModule.tourGuide:
        return RewardModule.tourism;
      case RewardModule.cargoDriver:
        return RewardModule.cargo;
      case RewardModule.parcelDriver:
        return RewardModule.parcel;
      default:
        return module;
    }
  }

  static List<RewardModule> relatedModules(RewardModule module) {
    switch (customerModuleFor(module)) {
      case RewardModule.ride:
        return const [RewardModule.ride, RewardModule.rideDriver];
      case RewardModule.studentRide:
        return const [
          RewardModule.studentRide,
          RewardModule.studentDriver,
        ];
      case RewardModule.food:
        return const [
          RewardModule.food,
          RewardModule.foodDeliveryRider,
          RewardModule.restaurantPartner,
        ];
      case RewardModule.hotel:
        return const [RewardModule.hotel, RewardModule.hotelOwner];
      case RewardModule.tourism:
        return const [
          RewardModule.tourism,
          RewardModule.tourismDriver,
          RewardModule.tourGuide,
        ];
      case RewardModule.cargo:
        return const [RewardModule.cargo, RewardModule.cargoDriver];
      case RewardModule.parcel:
        return const [RewardModule.parcel, RewardModule.parcelDriver];
      default:
        return [module];
    }
  }

  static String label(RewardModule module) {
    switch (module) {
      case RewardModule.ride:
        return 'Ride';
      case RewardModule.rideDriver:
        return 'Ride Driver';
      case RewardModule.studentRide:
        return 'Student Ride';
      case RewardModule.studentDriver:
        return 'Student Driver';
      case RewardModule.food:
        return 'Food';
      case RewardModule.foodDeliveryRider:
        return 'Food Delivery Rider';
      case RewardModule.restaurantPartner:
        return 'Restaurant Partner';
      case RewardModule.hotel:
        return 'Hotel';
      case RewardModule.hotelOwner:
        return 'Hotel Owner';
      case RewardModule.tourism:
        return 'Tourism';
      case RewardModule.tourismDriver:
        return 'Tourism Driver';
      case RewardModule.tourGuide:
        return 'Tour Guide';
      case RewardModule.cargo:
        return 'Cargo';
      case RewardModule.cargoDriver:
        return 'Cargo Driver';
      case RewardModule.parcel:
        return 'Parcel';
      case RewardModule.parcelDriver:
        return 'Parcel Driver';
      case RewardModule.wallet:
        return 'Wallet';
      case RewardModule.all:
        return 'All Modules';
      case RewardModule.future:
        return 'Future Module';
    }
  }

  static String shortLabel(RewardModule module) {
    switch (module) {
      case RewardModule.rideDriver:
      case RewardModule.studentDriver:
      case RewardModule.tourismDriver:
      case RewardModule.cargoDriver:
      case RewardModule.parcelDriver:
        return 'Driver';
      case RewardModule.foodDeliveryRider:
        return 'Delivery Rider';
      case RewardModule.restaurantPartner:
        return 'Restaurant';
      case RewardModule.hotelOwner:
        return 'Hotel Owner';
      case RewardModule.tourGuide:
        return 'Guide';
      default:
        return label(module);
    }
  }

  static String bookingNoun(RewardModule module) {
    switch (customerModuleFor(module)) {
      case RewardModule.food:
        return 'order';
      case RewardModule.hotel:
        return 'hotel booking';
      case RewardModule.tourism:
        return 'tour booking';
      case RewardModule.cargo:
        return 'cargo booking';
      case RewardModule.parcel:
        return 'parcel booking';
      case RewardModule.wallet:
        return 'wallet transaction';
      default:
        return 'ride';
    }
  }

  static String sourceIdKey(RewardModule module) {
    switch (customerModuleFor(module)) {
      case RewardModule.food:
        return 'orderId';
      case RewardModule.wallet:
        return 'walletTransactionId';
      default:
        return 'bookingId';
    }
  }

  static String normalizeKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static const Map<String, RewardModule> _aliases = {
    'rider': RewardModule.ride,
    'normalride': RewardModule.ride,
    'taxi': RewardModule.ride,
    'driver': RewardModule.rideDriver,
    'ridedriver': RewardModule.rideDriver,
    'student': RewardModule.studentRide,
    'schoolride': RewardModule.studentRide,
    'studentride': RewardModule.studentRide,
    'schooldriver': RewardModule.studentDriver,
    'studentdriver': RewardModule.studentDriver,
    'foodorder': RewardModule.food,
    'fooddelivery': RewardModule.food,
    'deliveryrider': RewardModule.foodDeliveryRider,
    'foodrider': RewardModule.foodDeliveryRider,
    'restaurant': RewardModule.restaurantPartner,
    'restaurantowner': RewardModule.restaurantPartner,
    'hotelbooking': RewardModule.hotel,
    'hotels': RewardModule.hotel,
    'hotelpartner': RewardModule.hotelOwner,
    'hotelowner': RewardModule.hotelOwner,
    'tour': RewardModule.tourism,
    'tours': RewardModule.tourism,
    'tourbooking': RewardModule.tourism,
    'tourdriver': RewardModule.tourismDriver,
    'tourismdriver': RewardModule.tourismDriver,
    'guide': RewardModule.tourGuide,
    'tourguide': RewardModule.tourGuide,
    'cargobooking': RewardModule.cargo,
    'cargodriver': RewardModule.cargoDriver,
    'parcelbooking': RewardModule.parcel,
    'delivery': RewardModule.parcel,
    'parceldriver': RewardModule.parcelDriver,
    'paymentwallet': RewardModule.wallet,
    'rewardwallet': RewardModule.wallet,
    'global': RewardModule.all,
    'allmodules': RewardModule.all,
    'unknown': RewardModule.future,
  };
}

