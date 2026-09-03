enum StudentRideRouteShift {
  morning,
  afternoon,
}

enum StudentRideRouteStatus {
  draft,
  active,
  paused,
  full,
  disabled,
}

class StudentRideRouteStopModel {
  final String stopId;
  final String studentId;
  final String studentName;
  final String address;
  final double latitude;
  final double longitude;
  final int stopOrder;
  final String expectedTime;
  final bool isActive;

  const StudentRideRouteStopModel({
    required this.stopId,
    required this.studentId,
    required this.studentName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.stopOrder,
    required this.expectedTime,
    required this.isActive,
  });

  factory StudentRideRouteStopModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return StudentRideRouteStopModel(
      stopId: map['stopId']?.toString() ?? '',
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      latitude: _readDouble(map['latitude']),
      longitude: _readDouble(map['longitude']),
      stopOrder: _readInt(map['stopOrder']),
      expectedTime: map['expectedTime']?.toString() ?? '',
      isActive: map['isActive'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stopId': stopId,
      'studentId': studentId,
      'studentName': studentName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'stopOrder': stopOrder,
      'expectedTime': expectedTime,
      'isActive': isActive,
    };
  }

  static double _readDouble(dynamic value) {
    return value is num ? value.toDouble() : 0;
  }

  static int _readInt(dynamic value) {
    return value is num ? value.toInt() : 0;
  }
}

class StudentRideRouteModel {
  final String routeId;
  final String routeName;
  final StudentRideRouteShift shift;
  final StudentRideRouteStatus status;

  // School and schedule
  final String schoolId;
  final String schoolName;
  final String schoolAddress;
  final double schoolLatitude;
  final double schoolLongitude;
  final String routeStartTime;
  final String schoolArrivalTime;
  final List<int> operatingWeekdays;

  // Assignment
  final String driverId;
  final String driverName;
  final String vehicleId;
  final String vehicleRegistrationNumber;
  final int vehicleCapacity;

  // Route
  final List<StudentRideRouteStopModel> stops;
  final double estimatedDistanceKm;
  final int estimatedDurationMinutes;

  // Capacity
  final int assignedStudentCount;
  final int reservedSeatCount;
  final bool waitlistEnabled;

  // Admin control
  final String disabledMessage;
  final String createdBy;
  final String updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentRideRouteModel({
    required this.routeId,
    required this.routeName,
    required this.shift,
    required this.status,
    required this.schoolId,
    required this.schoolName,
    required this.schoolAddress,
    required this.schoolLatitude,
    required this.schoolLongitude,
    required this.routeStartTime,
    required this.schoolArrivalTime,
    required this.operatingWeekdays,
    required this.driverId,
    required this.driverName,
    required this.vehicleId,
    required this.vehicleRegistrationNumber,
    required this.vehicleCapacity,
    required this.stops,
    required this.estimatedDistanceKm,
    required this.estimatedDurationMinutes,
    required this.assignedStudentCount,
    required this.reservedSeatCount,
    required this.waitlistEnabled,
    required this.disabledMessage,
    required this.createdBy,
    required this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  int get availableSeats {
    final int value = vehicleCapacity -
        assignedStudentCount -
        reservedSeatCount;
    return value > 0 ? value : 0;
  }

  bool get hasAvailableSeat {
    return status == StudentRideRouteStatus.active &&
        availableSeats > 0;
  }

  bool get hasCompleteAssignment {
    return driverId.isNotEmpty && vehicleId.isNotEmpty;
  }

  List<StudentRideRouteStopModel> get orderedStops {
    final items = List<StudentRideRouteStopModel>.from(stops);
    items.sort(
      (first, second) =>
          first.stopOrder.compareTo(second.stopOrder),
    );
    return items;
  }

  factory StudentRideRouteModel.fromMap(
    Map<String, dynamic> map, {
    String documentId = '',
  }) {
    return StudentRideRouteModel(
      routeId: documentId.isNotEmpty
          ? documentId
          : map['routeId']?.toString() ?? '',
      routeName: map['routeName']?.toString() ?? '',
      shift: _shiftFromString(map['shift']?.toString()),
      status: _statusFromString(map['status']?.toString()),
      schoolId: map['schoolId']?.toString() ?? '',
      schoolName: map['schoolName']?.toString() ?? '',
      schoolAddress:
          map['schoolAddress']?.toString() ?? '',
      schoolLatitude:
          _readDouble(map['schoolLatitude']),
      schoolLongitude:
          _readDouble(map['schoolLongitude']),
      routeStartTime:
          map['routeStartTime']?.toString() ?? '',
      schoolArrivalTime:
          map['schoolArrivalTime']?.toString() ?? '',
      operatingWeekdays:
          _readIntList(map['operatingWeekdays']),
      driverId: map['driverId']?.toString() ?? '',
      driverName: map['driverName']?.toString() ?? '',
      vehicleId: map['vehicleId']?.toString() ?? '',
      vehicleRegistrationNumber:
          map['vehicleRegistrationNumber']?.toString() ?? '',
      vehicleCapacity:
          _readInt(map['vehicleCapacity'], fallback: 1),
      stops: _readStops(map['stops']),
      estimatedDistanceKm:
          _readDouble(map['estimatedDistanceKm']),
      estimatedDurationMinutes: _readInt(
        map['estimatedDurationMinutes'],
        fallback: 0,
      ),
      assignedStudentCount: _readInt(
        map['assignedStudentCount'],
        fallback: 0,
      ),
      reservedSeatCount: _readInt(
        map['reservedSeatCount'],
        fallback: 0,
      ),
      waitlistEnabled: map['waitlistEnabled'] != false,
      disabledMessage: map['disabledMessage']?.toString() ??
          'This Student Ride route is unavailable.',
      createdBy: map['createdBy']?.toString() ?? '',
      updatedBy: map['updatedBy']?.toString() ?? '',
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeId': routeId,
      'routeName': routeName,
      'shift': shift.name,
      'status': status.name,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'schoolAddress': schoolAddress,
      'schoolLatitude': schoolLatitude,
      'schoolLongitude': schoolLongitude,
      'routeStartTime': routeStartTime,
      'schoolArrivalTime': schoolArrivalTime,
      'operatingWeekdays': operatingWeekdays,
      'driverId': driverId,
      'driverName': driverName,
      'vehicleId': vehicleId,
      'vehicleRegistrationNumber':
          vehicleRegistrationNumber,
      'vehicleCapacity': vehicleCapacity,
      'stops': stops.map((item) => item.toMap()).toList(),
      'estimatedDistanceKm': estimatedDistanceKm,
      'estimatedDurationMinutes':
          estimatedDurationMinutes,
      'assignedStudentCount': assignedStudentCount,
      'reservedSeatCount': reservedSeatCount,
      'waitlistEnabled': waitlistEnabled,
      'disabledMessage': disabledMessage,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static StudentRideRouteShift _shiftFromString(
    String? value,
  ) {
    return StudentRideRouteShift.values.firstWhere(
      (item) => item.name == value,
      orElse: () => StudentRideRouteShift.morning,
    );
  }

  static StudentRideRouteStatus _statusFromString(
    String? value,
  ) {
    return StudentRideRouteStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => StudentRideRouteStatus.draft,
    );
  }

  static List<StudentRideRouteStopModel> _readStops(
    dynamic value,
  ) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map(
          (item) => StudentRideRouteStopModel.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  static double _readDouble(dynamic value) {
    return value is num ? value.toDouble() : 0;
  }

  static int _readInt(dynamic value, {required int fallback}) {
    return value is num ? value.toInt() : fallback;
  }

  static List<int> _readIntList(dynamic value) {
    if (value is! List) {
      return const [1, 2, 3, 4, 5];
    }

    return value
        .whereType<num>()
        .map((item) => item.toInt())
        .where((item) => item >= 1 && item <= 7)
        .toSet()
        .toList()
      ..sort();
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    try {
      final dynamic converted = value.toDate();
      if (converted is DateTime) return converted;
    } catch (_) {
      // Supports Firestore Timestamp without importing cloud_firestore.
    }

    return DateTime.tryParse(value.toString());
  }
}
