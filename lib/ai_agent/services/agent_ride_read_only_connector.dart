import '../../models/ride_model.dart';
import '../../services/ride_service.dart';
import '../constants/agent_action_ids.dart';
import '../models/agent_read_only_payload.dart';
import '../models/agent_tool_request.dart';
import 'agent_read_only_connector.dart';

// =========================================================
// AI AGENT — RIDE READ-ONLY CONNECTOR
// =========================================================
//
// Safe scope:
// - read one exact ride by rideId
// - read its operational status
//
// Never returns:
// - phone numbers
// - ride start PIN
// - precise locations/GPS
// - arbitrary Firestore documents
//
// No write method is exposed.

class AgentRideReadOnlyConnector
    implements AgentReadOnlyConnector {
  final RideService rideService;

  AgentRideReadOnlyConnector({
    RideService? rideService,
  }) : rideService = rideService ?? RideService();

  @override
  String get connectorId => 'connector.ride.read_only';

  @override
  String get module => 'ride';

  @override
  Set<String> get supportedActionIds => const <String>{
        AgentActionId.readRide,
        AgentActionId.readRideStatus,
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
      throw AgentRideConnectorException(
        'Unsupported Ride action: ${request.actionId}',
      );
    }

    _validateExactScope(request.actionScope);

    final String rideId =
        (request.actionScope['rideId'] as String).trim();

    final RideModel? ride =
        await rideService.getRide(rideId);

    if (ride == null) {
      throw const AgentRideConnectorException(
        'Ride was not found.',
      );
    }

    final Map<String, dynamic> data =
        request.actionId == AgentActionId.readRideStatus
            ? _statusPayload(ride)
            : _ridePayload(ride);

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
        !scope.containsKey('rideId')) {
      throw const AgentRideConnectorException(
        'Ride read scope must contain only rideId.',
      );
    }

    final dynamic rideId = scope['rideId'];

    if (rideId is! String || rideId.trim().isEmpty) {
      throw const AgentRideConnectorException(
        'A valid rideId is required.',
      );
    }

    if (rideId.trim().length > 200) {
      throw const AgentRideConnectorException(
        'rideId exceeds the allowed length.',
      );
    }
  }

  static Map<String, dynamic> _statusPayload(
    RideModel ride,
  ) {
    return <String, dynamic>{
      'rideId': ride.rideId,
      'status': ride.status,
      'hasDriver': ride.hasDriver,
      'isSearching': ride.isSearching,
      'isActive': ride.isActive,
      'isFinished': ride.isFinished,
      'requestExpired': ride.isRequestExpired,
      'paymentStatus': ride.paymentStatus,
      'updatedAt': _date(ride.updatedAt),
      'acceptedAt': _date(ride.acceptedAt),
      'driverArrivingAt': _date(ride.driverArrivingAt),
      'driverArrivedAt': _date(ride.driverArrivedAt),
      'rideStartedAt': _date(ride.rideStartedAt),
      'completedAt': _date(ride.completedAt),
      'cancelledAt': _date(ride.cancelledAt),
    };
  }

  static Map<String, dynamic> _ridePayload(
    RideModel ride,
  ) {
    return <String, dynamic>{
      ..._statusPayload(ride),
      'vehicleId': ride.vehicleId,
      'vehicleName': ride.vehicleName,
      'distanceKm': ride.distanceKm,
      'estimatedMinutes': ride.estimatedMinutes,
      'baseFare': ride.baseFare,
      'estimatedFare': ride.estimatedFare,
      'promoApplied':
          ride.promoCode?.trim().isNotEmpty == true,
      'promoDiscount': ride.promoDiscount,
      'paymentMethod': ride.paymentMethod,
      'commissionAmount': ride.commissionAmount,
      'netDriverEarning': ride.netDriverEarning,
      'cancelledBy': ride.cancelledBy,
      'cancellationReason': ride.cancellationReason,
      'createdAt': _date(ride.createdAt),
    };
  }

  static String? _date(DateTime? value) {
    return value?.toUtc().toIso8601String();
  }
}

class AgentRideConnectorException implements Exception {
  final String message;

  const AgentRideConnectorException(this.message);

  @override
  String toString() =>
      'AgentRideConnectorException: $message';
}