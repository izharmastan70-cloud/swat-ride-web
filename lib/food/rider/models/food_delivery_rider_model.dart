// lib/food/rider/models/food_delivery_rider_model.dart
// =============================================================
// SWAT RIDE - FOOD DELIVERY
// Food Delivery Rider Model
//
// This model is separate from the normal ride-hailing driver
// module because food delivery workflow and requirements differ.
//
// Used by:
// - Food rider registration
// - Admin approval
// - Rider availability
// - Live delivery assignment
// - Earnings
// - Delivery history
// - Firestore synchronization
//
// Firebase Storage uploads remain temporarily bypassed.
// Local document paths can be stored until Storage is enabled.
// =============================================================

enum FoodDeliveryRiderStatus {
  draft,
  pending,
  underReview,
  approved,
  rejected,
  suspended,
}

extension FoodDeliveryRiderStatusX
    on FoodDeliveryRiderStatus {
  String get value {
    switch (this) {
      case FoodDeliveryRiderStatus.draft:
        return 'draft';
      case FoodDeliveryRiderStatus.pending:
        return 'pending';
      case FoodDeliveryRiderStatus.underReview:
        return 'under_review';
      case FoodDeliveryRiderStatus.approved:
        return 'approved';
      case FoodDeliveryRiderStatus.rejected:
        return 'rejected';
      case FoodDeliveryRiderStatus.suspended:
        return 'suspended';
    }
  }

  String get displayName {
    switch (this) {
      case FoodDeliveryRiderStatus.draft:
        return 'Draft';
      case FoodDeliveryRiderStatus.pending:
        return 'Pending';
      case FoodDeliveryRiderStatus.underReview:
        return 'Under Review';
      case FoodDeliveryRiderStatus.approved:
        return 'Approved';
      case FoodDeliveryRiderStatus.rejected:
        return 'Rejected';
      case FoodDeliveryRiderStatus.suspended:
        return 'Suspended';
    }
  }

  static FoodDeliveryRiderStatus fromValue(
    dynamic value,
  ) {
    final String normalized =
        value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'draft':
        return FoodDeliveryRiderStatus.draft;
      case 'pending':
        return FoodDeliveryRiderStatus.pending;
      case 'underreview':
      case 'under_review':
      case 'under review':
        return FoodDeliveryRiderStatus.underReview;
      case 'approved':
        return FoodDeliveryRiderStatus.approved;
      case 'rejected':
        return FoodDeliveryRiderStatus.rejected;
      case 'suspended':
        return FoodDeliveryRiderStatus.suspended;
      default:
        return FoodDeliveryRiderStatus.draft;
    }
  }
}

enum FoodDeliveryVehicleType {
  motorcycle,
  rickshaw,
  car,
  other,
}

extension FoodDeliveryVehicleTypeX
    on FoodDeliveryVehicleType {
  String get value {
    switch (this) {
      case FoodDeliveryVehicleType.motorcycle:
        return 'motorcycle';
      case FoodDeliveryVehicleType.rickshaw:
        return 'rickshaw';
      case FoodDeliveryVehicleType.car:
        return 'car';
      case FoodDeliveryVehicleType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case FoodDeliveryVehicleType.motorcycle:
        return 'Motorcycle';
      case FoodDeliveryVehicleType.rickshaw:
        return 'Rickshaw';
      case FoodDeliveryVehicleType.car:
        return 'Car';
      case FoodDeliveryVehicleType.other:
        return 'Other';
    }
  }

  static FoodDeliveryVehicleType fromValue(
    dynamic value,
  ) {
    final String normalized =
        value?.toString().trim().toLowerCase() ?? '';

    switch (normalized) {
      case 'motorcycle':
      case 'bike':
      case 'motorbike':
        return FoodDeliveryVehicleType.motorcycle;
      case 'rickshaw':
      case 'rikshaw':
      case 'auto':
      case 'auto_rickshaw':
        return FoodDeliveryVehicleType.rickshaw;
      case 'car':
        return FoodDeliveryVehicleType.car;
      default:
        return FoodDeliveryVehicleType.other;
    }
  }
}

class FoodDeliveryRiderModel {
  // ===========================================================
  // IDENTIFIERS
  // ===========================================================

  final String riderId;
  final String userId;

  // ===========================================================
  // PERSONAL INFORMATION
  // ===========================================================

  final String fullName;
  final String phoneNumber;
  final String email;
  final String cnicNumber;
  final DateTime? dateOfBirth;

  // ===========================================================
  // ADDRESS
  // ===========================================================

  final String country;
  final String province;
  final String city;
  final String area;
  final String completeAddress;

  // ===========================================================
  // VEHICLE INFORMATION
  // ===========================================================

  final FoodDeliveryVehicleType vehicleType;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleColor;
  final String registrationNumber;

  // ===========================================================
  // DOCUMENTS
  // ===========================================================

  final String profileImageUrl;
  final String profileLocalImagePath;

  final String cnicFrontUrl;
  final String cnicFrontLocalPath;

  final String cnicBackUrl;
  final String cnicBackLocalPath;

  final String drivingLicenseFrontUrl;
  final String drivingLicenseFrontLocalPath;

  final String drivingLicenseBackUrl;
  final String drivingLicenseBackLocalPath;

  final String vehicleRegistrationUrl;
  final String vehicleRegistrationLocalPath;

  final String vehiclePhotoUrl;
  final String vehiclePhotoLocalPath;

  // ===========================================================
  // APPLICATION / APPROVAL
  // ===========================================================

  final FoodDeliveryRiderStatus status;

  final bool isApproved;
  final bool isRejected;
  final bool isSuspended;
  final bool isActive;

  final String rejectionReason;
  final String suspensionReason;
  final String adminNote;
  final String reviewedBy;
  final DateTime? reviewedAt;

  final DateTime? approvedAt;

  // ===========================================================
  // LIVE AVAILABILITY
  // ===========================================================

  final bool isOnline;
  final bool isAvailable;
  final bool isOnDelivery;

  final String currentOrderId;

  final double currentLatitude;
  final double currentLongitude;
  final double currentHeading;
  final double currentSpeed;

  final DateTime? lastLocationUpdate;

  // ===========================================================
  // BUSINESS / WALLET
  // ===========================================================

  final double commissionPercentage;
  final double walletBalance;
  final double outstandingCommission;
  final double totalCommissionPaid;
  final double totalEarnings;

  // ===========================================================
  // PERFORMANCE
  // ===========================================================

  final double rating;
  final int totalRatings;
  final int totalDeliveries;
  final int completedDeliveries;
  final int cancelledDeliveries;
  final int rejectedRequests;

  // ===========================================================
  // AUDIT
  // ===========================================================

  final DateTime createdAt;
  final DateTime updatedAt;

  const FoodDeliveryRiderModel({
    required this.riderId,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.cnicNumber,
    required this.dateOfBirth,
    required this.country,
    required this.province,
    required this.city,
    required this.area,
    required this.completeAddress,
    required this.vehicleType,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.registrationNumber,
    required this.profileImageUrl,
    required this.profileLocalImagePath,
    required this.cnicFrontUrl,
    required this.cnicFrontLocalPath,
    required this.cnicBackUrl,
    required this.cnicBackLocalPath,
    required this.drivingLicenseFrontUrl,
    required this.drivingLicenseFrontLocalPath,
    required this.drivingLicenseBackUrl,
    required this.drivingLicenseBackLocalPath,
    required this.vehicleRegistrationUrl,
    required this.vehicleRegistrationLocalPath,
    required this.vehiclePhotoUrl,
    required this.vehiclePhotoLocalPath,
    required this.status,
    required this.isApproved,
    required this.isRejected,
    required this.isSuspended,
    required this.isActive,
    required this.rejectionReason,
    required this.suspensionReason,
    required this.approvedAt,
    required this.isOnline,
    required this.isAvailable,
    required this.isOnDelivery,
    required this.currentOrderId,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.currentHeading,
    required this.currentSpeed,
    required this.lastLocationUpdate,
    required this.commissionPercentage,
    required this.walletBalance,
    required this.outstandingCommission,
    required this.totalCommissionPaid,
    required this.totalEarnings,
    required this.rating,
    required this.totalRatings,
    required this.totalDeliveries,
    required this.completedDeliveries,
    required this.cancelledDeliveries,
    required this.rejectedRequests,
    required this.createdAt,
    required this.updatedAt,
    this.adminNote = '',
    this.reviewedBy = '',
    this.reviewedAt,
  });

  factory FoodDeliveryRiderModel.empty({
    String userId = '',
  }) {
    final DateTime now = DateTime.now();

    return FoodDeliveryRiderModel(
      riderId: '',
      userId: userId,
      fullName: '',
      phoneNumber: '',
      email: '',
      cnicNumber: '',
      dateOfBirth: null,
      country: 'Pakistan',
      province: 'Khyber Pakhtunkhwa',
      city: 'Swat',
      area: '',
      completeAddress: '',
      vehicleType:
          FoodDeliveryVehicleType.motorcycle,
      vehicleMake: '',
      vehicleModel: '',
      vehicleColor: '',
      registrationNumber: '',
      profileImageUrl: '',
      profileLocalImagePath: '',
      cnicFrontUrl: '',
      cnicFrontLocalPath: '',
      cnicBackUrl: '',
      cnicBackLocalPath: '',
      drivingLicenseFrontUrl: '',
      drivingLicenseFrontLocalPath: '',
      drivingLicenseBackUrl: '',
      drivingLicenseBackLocalPath: '',
      vehicleRegistrationUrl: '',
      vehicleRegistrationLocalPath: '',
      vehiclePhotoUrl: '',
      vehiclePhotoLocalPath: '',
      status: FoodDeliveryRiderStatus.draft,
      isApproved: false,
      isRejected: false,
      isSuspended: false,
      isActive: false,
      rejectionReason: '',
      suspensionReason: '',
      approvedAt: null,
      isOnline: false,
      isAvailable: false,
      isOnDelivery: false,
      currentOrderId: '',
      currentLatitude: 0,
      currentLongitude: 0,
      currentHeading: 0,
      currentSpeed: 0,
      lastLocationUpdate: null,
      commissionPercentage: 0,
      walletBalance: 0,
      outstandingCommission: 0,
      totalCommissionPaid: 0,
      totalEarnings: 0,
      rating: 0,
      totalRatings: 0,
      totalDeliveries: 0,
      completedDeliveries: 0,
      cancelledDeliveries: 0,
      rejectedRequests: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ===========================================================
  // HELPERS
  // ===========================================================

  bool get canAccessRiderDashboard {
    return status == FoodDeliveryRiderStatus.approved &&
        isApproved &&
        !isRejected &&
        !isSuspended &&
        isActive;
  }

  bool get canReceiveOrders {
    return canAccessRiderDashboard &&
        isOnline &&
        isAvailable &&
        !isOnDelivery &&
        currentOrderId.trim().isEmpty;
  }

  bool get hasLiveLocation {
    return currentLatitude != 0 ||
        currentLongitude != 0;
  }

  bool get hasRequiredDocuments {
    final bool hasCnicFront =
        cnicFrontUrl.trim().isNotEmpty ||
            cnicFrontLocalPath.trim().isNotEmpty;

    final bool hasCnicBack =
        cnicBackUrl.trim().isNotEmpty ||
            cnicBackLocalPath.trim().isNotEmpty;

    final bool hasLicenseFront =
        drivingLicenseFrontUrl.trim().isNotEmpty ||
            drivingLicenseFrontLocalPath.trim().isNotEmpty;

    final bool hasLicenseBack =
        drivingLicenseBackUrl.trim().isNotEmpty ||
            drivingLicenseBackLocalPath.trim().isNotEmpty;

    final bool hasVehicleRegistration =
        vehicleRegistrationUrl.trim().isNotEmpty ||
            vehicleRegistrationLocalPath.trim().isNotEmpty;

    final bool hasVehiclePhoto =
        vehiclePhotoUrl.trim().isNotEmpty ||
            vehiclePhotoLocalPath.trim().isNotEmpty;

    return hasCnicFront &&
        hasCnicBack &&
        hasLicenseFront &&
        hasLicenseBack &&
        hasVehicleRegistration &&
        hasVehiclePhoto;
  }

  int get completionRate {
    if (totalDeliveries <= 0) {
      return 0;
    }

    return ((completedDeliveries / totalDeliveries) * 100)
        .clamp(0, 100)
        .round();
  }

  String get availabilityText {
    if (!canAccessRiderDashboard) {
      return 'Access unavailable';
    }

    if (!isOnline) {
      return 'Offline';
    }

    if (isOnDelivery) {
      return 'On delivery';
    }

    if (isAvailable) {
      return 'Available';
    }

    return 'Busy';
  }

  // ===========================================================
  // COPY WITH
  // ===========================================================

  FoodDeliveryRiderModel copyWith({
    String? riderId,
    String? userId,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? cnicNumber,
    DateTime? dateOfBirth,
    bool clearDateOfBirth = false,
    String? country,
    String? province,
    String? city,
    String? area,
    String? completeAddress,
    FoodDeliveryVehicleType? vehicleType,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleColor,
    String? registrationNumber,
    String? profileImageUrl,
    String? profileLocalImagePath,
    String? cnicFrontUrl,
    String? cnicFrontLocalPath,
    String? cnicBackUrl,
    String? cnicBackLocalPath,
    String? drivingLicenseFrontUrl,
    String? drivingLicenseFrontLocalPath,
    String? drivingLicenseBackUrl,
    String? drivingLicenseBackLocalPath,
    String? vehicleRegistrationUrl,
    String? vehicleRegistrationLocalPath,
    String? vehiclePhotoUrl,
    String? vehiclePhotoLocalPath,
    FoodDeliveryRiderStatus? status,
    bool? isApproved,
    bool? isRejected,
    bool? isSuspended,
    bool? isActive,
    String? rejectionReason,
    String? suspensionReason,
    String? adminNote,
    String? reviewedBy,
    DateTime? reviewedAt,
    bool clearReviewedAt = false,
    DateTime? approvedAt,
    bool clearApprovedAt = false,
    bool? isOnline,
    bool? isAvailable,
    bool? isOnDelivery,
    String? currentOrderId,
    double? currentLatitude,
    double? currentLongitude,
    double? currentHeading,
    double? currentSpeed,
    DateTime? lastLocationUpdate,
    bool clearLastLocationUpdate = false,
    double? commissionPercentage,
    double? walletBalance,
    double? outstandingCommission,
    double? totalCommissionPaid,
    double? totalEarnings,
    double? rating,
    int? totalRatings,
    int? totalDeliveries,
    int? completedDeliveries,
    int? cancelledDeliveries,
    int? rejectedRequests,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodDeliveryRiderModel(
      riderId: riderId ?? this.riderId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phoneNumber:
          phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      dateOfBirth: clearDateOfBirth
          ? null
          : dateOfBirth ?? this.dateOfBirth,
      country: country ?? this.country,
      province: province ?? this.province,
      city: city ?? this.city,
      area: area ?? this.area,
      completeAddress:
          completeAddress ?? this.completeAddress,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel:
          vehicleModel ?? this.vehicleModel,
      vehicleColor:
          vehicleColor ?? this.vehicleColor,
      registrationNumber:
          registrationNumber ??
              this.registrationNumber,
      profileImageUrl:
          profileImageUrl ?? this.profileImageUrl,
      profileLocalImagePath:
          profileLocalImagePath ??
              this.profileLocalImagePath,
      cnicFrontUrl:
          cnicFrontUrl ?? this.cnicFrontUrl,
      cnicFrontLocalPath:
          cnicFrontLocalPath ??
              this.cnicFrontLocalPath,
      cnicBackUrl:
          cnicBackUrl ?? this.cnicBackUrl,
      cnicBackLocalPath:
          cnicBackLocalPath ??
              this.cnicBackLocalPath,
      drivingLicenseFrontUrl:
          drivingLicenseFrontUrl ??
              this.drivingLicenseFrontUrl,
      drivingLicenseFrontLocalPath:
          drivingLicenseFrontLocalPath ??
              this.drivingLicenseFrontLocalPath,
      drivingLicenseBackUrl:
          drivingLicenseBackUrl ??
              this.drivingLicenseBackUrl,
      drivingLicenseBackLocalPath:
          drivingLicenseBackLocalPath ??
              this.drivingLicenseBackLocalPath,
      vehicleRegistrationUrl:
          vehicleRegistrationUrl ??
              this.vehicleRegistrationUrl,
      vehicleRegistrationLocalPath:
          vehicleRegistrationLocalPath ??
              this.vehicleRegistrationLocalPath,
      vehiclePhotoUrl:
          vehiclePhotoUrl ??
              this.vehiclePhotoUrl,
      vehiclePhotoLocalPath:
          vehiclePhotoLocalPath ??
              this.vehiclePhotoLocalPath,
      status: status ?? this.status,
      isApproved:
          isApproved ?? this.isApproved,
      isRejected:
          isRejected ?? this.isRejected,
      isSuspended:
          isSuspended ?? this.isSuspended,
      isActive: isActive ?? this.isActive,
      rejectionReason:
          rejectionReason ?? this.rejectionReason,
      suspensionReason:
          suspensionReason ??
              this.suspensionReason,
      adminNote: adminNote ?? this.adminNote,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: clearReviewedAt
          ? null
          : reviewedAt ?? this.reviewedAt,
      approvedAt: clearApprovedAt
          ? null
          : approvedAt ?? this.approvedAt,
      isOnline: isOnline ?? this.isOnline,
      isAvailable:
          isAvailable ?? this.isAvailable,
      isOnDelivery:
          isOnDelivery ?? this.isOnDelivery,
      currentOrderId:
          currentOrderId ?? this.currentOrderId,
      currentLatitude:
          currentLatitude ?? this.currentLatitude,
      currentLongitude:
          currentLongitude ?? this.currentLongitude,
      currentHeading:
          currentHeading ?? this.currentHeading,
      currentSpeed:
          currentSpeed ?? this.currentSpeed,
      lastLocationUpdate:
          clearLastLocationUpdate
              ? null
              : lastLocationUpdate ??
                  this.lastLocationUpdate,
      commissionPercentage:
          commissionPercentage ??
              this.commissionPercentage,
      walletBalance:
          walletBalance ?? this.walletBalance,
      outstandingCommission:
          outstandingCommission ??
              this.outstandingCommission,
      totalCommissionPaid:
          totalCommissionPaid ??
              this.totalCommissionPaid,
      totalEarnings:
          totalEarnings ?? this.totalEarnings,
      rating: rating ?? this.rating,
      totalRatings:
          totalRatings ?? this.totalRatings,
      totalDeliveries:
          totalDeliveries ?? this.totalDeliveries,
      completedDeliveries:
          completedDeliveries ??
              this.completedDeliveries,
      cancelledDeliveries:
          cancelledDeliveries ??
              this.cancelledDeliveries,
      rejectedRequests:
          rejectedRequests ??
              this.rejectedRequests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ===========================================================
  // FIRESTORE
  // ===========================================================

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'riderId': riderId,
      'userId': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'cnicNumber': cnicNumber,
      'dateOfBirth':
          dateOfBirth?.toIso8601String(),
      'country': country,
      'province': province,
      'city': city,
      'area': area,
      'completeAddress': completeAddress,
      'vehicleType': vehicleType.value,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'registrationNumber':
          registrationNumber,
      'profileImageUrl': profileImageUrl,
      'profileLocalImagePath':
          profileLocalImagePath,
      'cnicFrontUrl': cnicFrontUrl,
      'cnicFrontLocalPath':
          cnicFrontLocalPath,
      'cnicBackUrl': cnicBackUrl,
      'cnicBackLocalPath':
          cnicBackLocalPath,
      'drivingLicenseFrontUrl':
          drivingLicenseFrontUrl,
      'drivingLicenseFrontLocalPath':
          drivingLicenseFrontLocalPath,
      'drivingLicenseBackUrl':
          drivingLicenseBackUrl,
      'drivingLicenseBackLocalPath':
          drivingLicenseBackLocalPath,
      'vehicleRegistrationUrl':
          vehicleRegistrationUrl,
      'vehicleRegistrationLocalPath':
          vehicleRegistrationLocalPath,
      'vehiclePhotoUrl': vehiclePhotoUrl,
      'vehiclePhotoLocalPath':
          vehiclePhotoLocalPath,
      'status': status.value,
      'isApproved': isApproved,
      'isRejected': isRejected,
      'isSuspended': isSuspended,
      'isActive': isActive,
      'rejectionReason': rejectionReason,
      'suspensionReason': suspensionReason,
      'adminNote': adminNote.trim(),
      'reviewedBy': reviewedBy.trim(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'approvedAt':
          approvedAt?.toIso8601String(),
      'isOnline': isOnline,
      'isAvailable': isAvailable,
      'isOnDelivery': isOnDelivery,
      'currentOrderId': currentOrderId,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      'currentHeading': currentHeading,
      'currentSpeed': currentSpeed,
      'lastLocationUpdate':
          lastLocationUpdate?.toIso8601String(),
      'commissionPercentage':
          commissionPercentage,
      'walletBalance': walletBalance,
      'outstandingCommission':
          outstandingCommission,
      'totalCommissionPaid':
          totalCommissionPaid,
      'totalEarnings': totalEarnings,
      'rating': rating,
      'totalRatings': totalRatings,
      'totalDeliveries': totalDeliveries,
      'completedDeliveries':
          completedDeliveries,
      'cancelledDeliveries':
          cancelledDeliveries,
      'rejectedRequests': rejectedRequests,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FoodDeliveryRiderModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return FoodDeliveryRiderModel(
      riderId:
          _FoodRiderParser.stringValue(
        map['riderId'],
      ),
      userId:
          _FoodRiderParser.stringValue(
        map['userId'],
      ),
      fullName:
          _FoodRiderParser.stringValue(
        map['fullName'],
      ),
      phoneNumber:
          _FoodRiderParser.stringValue(
        map['phoneNumber'],
      ),
      email:
          _FoodRiderParser.stringValue(
        map['email'],
      ),
      cnicNumber:
          _FoodRiderParser.stringValue(
        map['cnicNumber'],
      ),
      dateOfBirth:
          _FoodRiderParser.dateTimeValue(
        map['dateOfBirth'],
      ),
      country:
          _FoodRiderParser.stringValue(
        map['country'],
        fallback: 'Pakistan',
      ),
      province:
          _FoodRiderParser.stringValue(
        map['province'],
        fallback: 'Khyber Pakhtunkhwa',
      ),
      city:
          _FoodRiderParser.stringValue(
        map['city'],
        fallback: 'Swat',
      ),
      area:
          _FoodRiderParser.stringValue(
        map['area'],
      ),
      completeAddress:
          _FoodRiderParser.stringValue(
        map['completeAddress'],
      ),
      vehicleType:
          FoodDeliveryVehicleTypeX.fromValue(
        map['vehicleType'],
      ),
      vehicleMake:
          _FoodRiderParser.stringValue(
        map['vehicleMake'],
      ),
      vehicleModel:
          _FoodRiderParser.stringValue(
        map['vehicleModel'],
      ),
      vehicleColor:
          _FoodRiderParser.stringValue(
        map['vehicleColor'],
      ),
      registrationNumber:
          _FoodRiderParser.stringValue(
        map['registrationNumber'],
      ),
      profileImageUrl:
          _FoodRiderParser.stringValue(
        map['profileImageUrl'],
      ),
      profileLocalImagePath:
          _FoodRiderParser.stringValue(
        map['profileLocalImagePath'],
      ),
      cnicFrontUrl:
          _FoodRiderParser.stringValue(
        map['cnicFrontUrl'],
      ),
      cnicFrontLocalPath:
          _FoodRiderParser.stringValue(
        map['cnicFrontLocalPath'],
      ),
      cnicBackUrl:
          _FoodRiderParser.stringValue(
        map['cnicBackUrl'],
      ),
      cnicBackLocalPath:
          _FoodRiderParser.stringValue(
        map['cnicBackLocalPath'],
      ),
      drivingLicenseFrontUrl:
          _FoodRiderParser.stringValue(
        map['drivingLicenseFrontUrl'] ??
            map['drivingLicenseUrl'],
      ),
      drivingLicenseFrontLocalPath:
          _FoodRiderParser.stringValue(
        map['drivingLicenseFrontLocalPath'] ??
            map['drivingLicenseLocalPath'],
      ),
      drivingLicenseBackUrl:
          _FoodRiderParser.stringValue(
        map['drivingLicenseBackUrl'],
      ),
      drivingLicenseBackLocalPath:
          _FoodRiderParser.stringValue(
        map['drivingLicenseBackLocalPath'],
      ),
      vehicleRegistrationUrl:
          _FoodRiderParser.stringValue(
        map['vehicleRegistrationUrl'],
      ),
      vehicleRegistrationLocalPath:
          _FoodRiderParser.stringValue(
        map['vehicleRegistrationLocalPath'],
      ),
      vehiclePhotoUrl:
          _FoodRiderParser.stringValue(
        map['vehiclePhotoUrl'],
      ),
      vehiclePhotoLocalPath:
          _FoodRiderParser.stringValue(
        map['vehiclePhotoLocalPath'],
      ),
      status:
          FoodDeliveryRiderStatusX.fromValue(
        map['status'],
      ),
      isApproved:
          _FoodRiderParser.boolValue(
        map['isApproved'],
      ),
      isRejected:
          _FoodRiderParser.boolValue(
        map['isRejected'],
      ),
      isSuspended:
          _FoodRiderParser.boolValue(
        map['isSuspended'],
      ),
      isActive:
          _FoodRiderParser.boolValue(
        map['isActive'],
      ),
      rejectionReason:
          _FoodRiderParser.stringValue(
        map['rejectionReason'],
      ),
      suspensionReason:
          _FoodRiderParser.stringValue(
        map['suspensionReason'],
      ),
      adminNote:
          _FoodRiderParser.stringValue(
        map['adminNote'],
      ),
      reviewedBy:
          _FoodRiderParser.stringValue(
        map['reviewedBy'],
      ),
      reviewedAt:
          _FoodRiderParser.dateTimeValue(
        map['reviewedAt'],
      ),
      approvedAt:
          _FoodRiderParser.dateTimeValue(
        map['approvedAt'],
      ),
      isOnline:
          _FoodRiderParser.boolValue(
        map['isOnline'],
      ),
      isAvailable:
          _FoodRiderParser.boolValue(
        map['isAvailable'],
      ),
      isOnDelivery:
          _FoodRiderParser.boolValue(
        map['isOnDelivery'],
      ),
      currentOrderId:
          _FoodRiderParser.stringValue(
        map['currentOrderId'],
      ),
      currentLatitude:
          _FoodRiderParser.doubleValue(
        map['currentLatitude'],
      ),
      currentLongitude:
          _FoodRiderParser.doubleValue(
        map['currentLongitude'],
      ),
      currentHeading:
          _FoodRiderParser.doubleValue(
        map['currentHeading'],
      ),
      currentSpeed:
          _FoodRiderParser.doubleValue(
        map['currentSpeed'],
      ),
      lastLocationUpdate:
          _FoodRiderParser.dateTimeValue(
        map['lastLocationUpdate'],
      ),
      commissionPercentage:
          _FoodRiderParser.doubleValue(
        map['commissionPercentage'],
      ),
      walletBalance:
          _FoodRiderParser.doubleValue(
        map['walletBalance'],
      ),
      outstandingCommission:
          _FoodRiderParser.doubleValue(
        map['outstandingCommission'],
      ),
      totalCommissionPaid:
          _FoodRiderParser.doubleValue(
        map['totalCommissionPaid'],
      ),
      totalEarnings:
          _FoodRiderParser.doubleValue(
        map['totalEarnings'],
      ),
      rating:
          _FoodRiderParser.doubleValue(
        map['rating'],
      ),
      totalRatings:
          _FoodRiderParser.intValue(
        map['totalRatings'],
      ),
      totalDeliveries:
          _FoodRiderParser.intValue(
        map['totalDeliveries'],
      ),
      completedDeliveries:
          _FoodRiderParser.intValue(
        map['completedDeliveries'],
      ),
      cancelledDeliveries:
          _FoodRiderParser.intValue(
        map['cancelledDeliveries'],
      ),
      rejectedRequests:
          _FoodRiderParser.intValue(
        map['rejectedRequests'],
      ),
      createdAt:
          _FoodRiderParser.dateTimeValue(
        map['createdAt'],
      ) ??
          DateTime.now(),
      updatedAt:
          _FoodRiderParser.dateTimeValue(
        map['updatedAt'],
      ) ??
          DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is FoodDeliveryRiderModel &&
        other.riderId == riderId;
  }

  @override
  int get hashCode => riderId.hashCode;

  @override
  String toString() {
    return 'FoodDeliveryRiderModel('
        'riderId: $riderId, '
        'fullName: $fullName, '
        'status: ${status.value}, '
        'availability: $availabilityText'
        ')';
  }
}

class _FoodRiderParser {
  const _FoodRiderParser._();

  static String stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    final String parsed =
        value?.toString().trim() ?? '';

    return parsed.isEmpty ? fallback : parsed;
  }

  static int intValue(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  static double doubleValue(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  static bool boolValue(
    dynamic value, {
    bool fallback = false,
  }) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String normalized =
        value?.toString().trim().toLowerCase() ?? '';

    if (normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes') {
      return true;
    }

    if (normalized == 'false' ||
        normalized == '0' ||
        normalized == 'no') {
      return false;
    }

    return fallback;
  }

  static DateTime? dateTimeValue(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    try {
      final dynamic converted =
          value.toDate();

      if (converted is DateTime) {
        return converted;
      }
    } catch (_) {
      // Supports Firestore Timestamp without direct import.
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}
