import 'package:cloud_firestore/cloud_firestore.dart';

import '../../driver/models/driver_model.dart';
import '../../driver/services/driver_availability_service.dart';
import '../constants/agent_action_ids.dart';
import '../models/agent_read_only_payload.dart';
import '../models/agent_tool_request.dart';
import 'agent_read_only_connector.dart';

// =========================================================
// AI AGENT — DRIVER READ-ONLY CONNECTOR
// =========================================================
//
// Safe scope:
// - read one exact driver by driverId
// - read operational availability/status
//
// Never returns:
// - phone number
// - vehicle registration number
// - latitude/longitude or precise GPS
// - CNIC, licence or application documents
// - arbitrary Firestore documents
//
// No write method is exposed.

class AgentDriverReadOnlyConnector
    implements AgentReadOnlyConnector {
  final DriverAvailabilityService availabilityService;

  AgentDriverReadOnlyConnector({
    DriverAvailabilityService? availabilityService,
  }) : availabilityService =
            availabilityService ??
            DriverAvailabilityService();

  @override
  String get connectorId => 'connector.driver.read_only';

  @override
  String get module => 'driver';

  @override
  Set<String> get supportedActionIds => const <String>{
        AgentActionId.readDriver,
        AgentActionId.readDriverStatus,
      };

  @override
  bool supports(String actionId) =>
      supportedActionIds.contains(actionId);

  @override
  Future<AgentReadOnlyPayload> executeReadOnly(
    AgentToolRequest request,
  ) async {
    request.validate();

    if (!supports(request.actionId)) {
      throw AgentDriverConnectorException(
        'Unsupported Driver action: ${request.actionId}',
      );
    }

    _validateExactScope(request.actionScope);

    final String driverId =
        (request.actionScope['driverId'] as String).trim();

    final DocumentSnapshot<Map<String, dynamic>>? snapshot =
        await availabilityService.getDriverStatus(driverId);

    if (snapshot == null || !snapshot.exists) {
      throw const AgentDriverConnectorException(
        'Driver was not found.',
      );
    }

    final DriverModel driver =
        DriverModel.fromFirestore(snapshot);

    final Map<String, dynamic> data =
        request.actionId == AgentActionId.readDriverStatus
            ? _statusPayload(driver)
            : _driverPayload(driver);

    return AgentReadOnlyPayload(
      actionId: request.actionId,
      module: module,
      data: data,
      generatedAt: DateTime.now().toUtc(),
    );
  }

  static void _validateExactScope(
    Map<String, dynamic> scope,
  ) {
    if (scope.length != 1 ||
        !scope.containsKey('driverId')) {
      throw const AgentDriverConnectorException(
        'Driver read scope must contain only driverId.',
      );
    }

    final dynamic driverId = scope['driverId'];

    if (driverId is! String ||
        driverId.trim().isEmpty) {
      throw const AgentDriverConnectorException(
        'A valid driverId is required.',
      );
    }

    if (driverId.trim().length > 200) {
      throw const AgentDriverConnectorException(
        'driverId exceeds the allowed length.',
      );
    }
  }

  static Map<String, dynamic> _statusPayload(
    DriverModel driver,
  ) {
    return <String, dynamic>{
      'driverId': driver.driverId,
      'status': driver.status,
      'isOnline': driver.isOnline,
      'isAvailable': driver.isAvailable,
      'canReceiveRide':
          driver.status == 'approved' &&
          driver.isOnline &&
          driver.isAvailable,
      'updatedAt': _date(driver.updatedAt),
    };
  }

  static Map<String, dynamic> _driverPayload(
    DriverModel driver,
  ) {
    return <String, dynamic>{
      ..._statusPayload(driver),
      'displayName': driver.fullName.trim(),
      'vehicleType': driver.vehicleType.trim(),
      'hasRegisteredVehicle':
          driver.vehicleType.trim().isNotEmpty &&
          driver.vehicleNumber.trim().isNotEmpty,
      'createdAt': _date(driver.createdAt),
    };
  }

  static String? _date(DateTime? value) {
    return value?.toUtc().toIso8601String();
  }
}

class AgentDriverConnectorException implements Exception {
  final String message;

  const AgentDriverConnectorException(this.message);

  @override
  String toString() =>
      'AgentDriverConnectorException: $message';
}