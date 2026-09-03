import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student_ride_package_model.dart';

class StudentRidePackageService {
  StudentRidePackageService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String collectionName = 'student_ride_packages';

  CollectionReference<Map<String, dynamic>> get _packagesCollection =>
      _firestore.collection(collectionName);

  Stream<List<StudentRidePackageModel>> watchEnabledPackages({
    String? schoolId,
    String? routeId,
    String? vehicleType,
  }) {
    return _packagesCollection
        .where('isEnabled', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final packages = snapshot.docs
          .map(
            (document) => StudentRidePackageModel.fromMap(
              document.data(),
              documentId: document.id,
            ),
          )
          .where((package) {
        if (schoolId != null &&
            schoolId.trim().isNotEmpty &&
            !package.supportsSchool(schoolId.trim())) {
          return false;
        }

        if (routeId != null &&
            routeId.trim().isNotEmpty &&
            !package.supportsRoute(routeId.trim())) {
          return false;
        }

        if (vehicleType != null &&
            vehicleType.trim().isNotEmpty &&
            !package.supportsVehicle(vehicleType.trim())) {
          return false;
        }

        return true;
      }).toList();

      packages.sort(
        (first, second) =>
            first.displayOrder.compareTo(second.displayOrder),
      );

      return packages;
    });
  }

  Stream<List<StudentRidePackageModel>> watchAllPackagesForAdmin() {
    return _packagesCollection.snapshots().map((snapshot) {
      final packages = snapshot.docs
          .map(
            (document) => StudentRidePackageModel.fromMap(
              document.data(),
              documentId: document.id,
            ),
          )
          .toList();

      packages.sort(
        (first, second) =>
            first.displayOrder.compareTo(second.displayOrder),
      );

      return packages;
    });
  }

  Future<StudentRidePackageModel?> getPackage(
    String packageId,
  ) async {
    final id = packageId.trim();

    if (id.isEmpty) {
      throw ArgumentError('Package ID is required.');
    }

    final snapshot = await _packagesCollection.doc(id).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return StudentRidePackageModel.fromMap(
      data,
      documentId: snapshot.id,
    );
  }

  Future<String> savePackage({
    required StudentRidePackageModel package,
    required String adminId,
  }) async {
    final cleanAdminId = adminId.trim();

    if (cleanAdminId.isEmpty) {
      throw ArgumentError('Admin ID is required.');
    }

    _validatePackage(package);

    final existingId = package.packageId.trim();
    final reference = existingId.isEmpty
        ? _packagesCollection.doc()
        : _packagesCollection.doc(existingId);

    final existingSnapshot = await reference.get();
    final data = package.toMap()
      ..['packageId'] = reference.id
      ..['updatedBy'] = cleanAdminId
      ..['updatedAt'] = FieldValue.serverTimestamp();

    if (!existingSnapshot.exists) {
      data['createdBy'] = cleanAdminId;
      data['createdAt'] = FieldValue.serverTimestamp();
    } else {
      data.remove('createdBy');
      data.remove('createdAt');
    }

    await reference.set(
      data,
      SetOptions(merge: true),
    );

    return reference.id;
  }

  Future<void> setPackageEnabled({
    required String packageId,
    required bool enabled,
    required String adminId,
    String disabledMessage =
        'This Student Ride package is currently unavailable.',
  }) async {
    final cleanPackageId = packageId.trim();
    final cleanAdminId = adminId.trim();

    if (cleanPackageId.isEmpty) {
      throw ArgumentError('Package ID is required.');
    }

    if (cleanAdminId.isEmpty) {
      throw ArgumentError('Admin ID is required.');
    }

    await _packagesCollection.doc(cleanPackageId).set(
      <String, dynamic>{
        'isEnabled': enabled,
        'disabledMessage':
            enabled ? '' : disabledMessage.trim(),
        'updatedBy': cleanAdminId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updatePackagePricing({
    required String packageId,
    required StudentRidePackagePriceMode priceMode,
    required double basePrice,
    required double perKmPrice,
    required double perDayPrice,
    required double doorToDoorCharge,
    required double registrationFee,
    required double siblingDiscountPercent,
    required double maximumDiscountAmount,
    required String currencyCode,
    required String adminId,
  }) async {
    final values = <double>[
      basePrice,
      perKmPrice,
      perDayPrice,
      doorToDoorCharge,
      registrationFee,
      siblingDiscountPercent,
      maximumDiscountAmount,
    ];

    if (values.any((value) => value < 0)) {
      throw ArgumentError('Package prices cannot be negative.');
    }

    if (siblingDiscountPercent > 100) {
      throw ArgumentError(
        'Sibling discount cannot exceed 100 percent.',
      );
    }

    await _packagesCollection.doc(packageId.trim()).set(
      <String, dynamic>{
        'priceMode': priceMode.name,
        'basePrice': basePrice,
        'perKmPrice': perKmPrice,
        'perDayPrice': perDayPrice,
        'doorToDoorCharge': doorToDoorCharge,
        'registrationFee': registrationFee,
        'siblingDiscountPercent': siblingDiscountPercent,
        'maximumDiscountAmount': maximumDiscountAmount,
        'currencyCode': currencyCode.trim().isEmpty
            ? 'PKR'
            : currencyCode.trim().toUpperCase(),
        'updatedBy': adminId.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  void _validatePackage(StudentRidePackageModel package) {
    if (package.name.trim().isEmpty) {
      throw ArgumentError('Package name is required.');
    }

    final prices = <double>[
      package.basePrice,
      package.perKmPrice,
      package.perDayPrice,
      package.doorToDoorCharge,
      package.registrationFee,
      package.siblingDiscountPercent,
      package.maximumDiscountAmount,
    ];

    if (prices.any((value) => value < 0)) {
      throw ArgumentError('Package prices cannot be negative.');
    }

    if (package.siblingDiscountPercent > 100) {
      throw ArgumentError(
        'Sibling discount cannot exceed 100 percent.',
      );
    }

    if (package.minimumDays < 1) {
      throw ArgumentError(
        'Package minimum days must be at least 1.',
      );
    }

    if (package.maximumStudents < 1) {
      throw ArgumentError(
        'Maximum students must be at least 1.',
      );
    }

    if (package.paymentDueDay < 1 ||
        package.paymentDueDay > 28) {
      throw ArgumentError(
        'Payment due day must be between 1 and 28.',
      );
    }

    if (package.paymentGraceDays < 0) {
      throw ArgumentError(
        'Payment grace days cannot be negative.',
      );
    }

    if (package.operatingWeekdays.any(
      (day) => day < 1 || day > 7,
    )) {
      throw ArgumentError(
        'Operating weekdays must be between 1 and 7.',
      );
    }
  }
}
