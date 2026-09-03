import '../constants/agent_action_ids.dart';
import '../constants/agent_module_connector_constants.dart';
import '../models/agent_module_connector_descriptor.dart';

// =========================================================
// AI AGENT — MODULE CONNECTOR REGISTRY
// =========================================================
//
// Phase 13 FOUNDATION ONLY.
//
// Every module is registered as NOT_CONNECTED or DISABLED.
// This lets the AI platform know what modules exist without pretending
// that real business data access is ready.

class AgentModuleConnectorRegistry {
  AgentModuleConnectorRegistry._();

  static const Map<String, AgentModuleConnectorDescriptor> _connectors =
      <String, AgentModuleConnectorDescriptor>{
    AgentModuleId.ride: AgentModuleConnectorDescriptor(
      connectorId: 'connector.ride',
      module: AgentModuleId.ride,
      status: AgentModuleConnectorStatus.notConnected,
      enabled: false,
      readOnlyFirst: true,
      requiresRealModuleAudit: true,
      plannedReadActionIds: <String>[
        AgentActionId.readRide,
        AgentActionId.readRideStatus,
      ],
      plannedWriteActionIds: <String>[
        AgentActionId.cancelRide,
      ],
      notes: 'Connect only after current Ride files/services are audited.',
    ),
    AgentModuleId.driver: AgentModuleConnectorDescriptor(
      connectorId: 'connector.driver',
      module: AgentModuleId.driver,
      status: AgentModuleConnectorStatus.notConnected,
      enabled: false,
      readOnlyFirst: true,
      requiresRealModuleAudit: true,
      plannedReadActionIds: <String>[
        AgentActionId.readDriver,
        AgentActionId.readDriverStatus,
      ],
      plannedWriteActionIds: <String>[
        AgentActionId.approveDriver,
        AgentActionId.rejectDriver,
        AgentActionId.suspendDriver,
      ],
      notes: 'Driver connector starts monitor/read-only after audit.',
    ),
    AgentModuleId.food: AgentModuleConnectorDescriptor(
      connectorId: 'connector.food',
      module: AgentModuleId.food,
      status: AgentModuleConnectorStatus.notConnected,
      enabled: false,
      readOnlyFirst: true,
      requiresRealModuleAudit: true,
      plannedReadActionIds: <String>[
        AgentActionId.readFoodOrder,
      ],
      plannedWriteActionIds: <String>[
        AgentActionId.refundFoodOrder,
      ],
      notes: 'Food customer/order connector not attached yet.',
    ),
    AgentModuleId.restaurant: AgentModuleConnectorDescriptor(
      connectorId: 'connector.restaurant',
      module: AgentModuleId.restaurant,
      status: AgentModuleConnectorStatus.notConnected,
      enabled: false,
      readOnlyFirst: true,
      requiresRealModuleAudit: true,
      plannedReadActionIds: <String>[
        AgentActionId.readRestaurant,
      ],
      plannedWriteActionIds: <String>[
        AgentActionId.suspendRestaurant,
      ],
      notes: 'Restaurant connector remains separate from customer Food connector.',
    ),
    AgentModuleId.hotel: AgentModuleConnectorDescriptor(
      connectorId: 'connector.hotel',
      module: AgentModuleId.hotel,
      status: AgentModuleConnectorStatus.notConnected,
      enabled: false,
      readOnlyFirst: true,
      requiresRealModuleAudit: true,
      plannedReadActionIds: <String>[
        AgentActionId.readHotelBooking,
      ],
      plannedWriteActionIds: <String>[
        AgentActionId.cancelHotelBooking,
        AgentActionId.changeHotelPrice,
      ],
      notes: 'Hotel connector not attached yet.',
    ),
    AgentModuleId.tour: AgentModuleConnectorDescriptor(
      connectorId: 'connector.tour',
      module: AgentModuleId.tour,
      status: AgentModuleConnectorStatus.notConnected,
      enabled: false,
      readOnlyFirst: true,
      requiresRealModuleAudit: true,
      plannedReadActionIds: <String>[
        AgentActionId.readTourBooking,
      ],
      plannedWriteActionIds: <String>[
        AgentActionId.cancelTourBooking,
        AgentActionId.changeTourPrice,
      ],
      notes: 'Tour connector not attached yet.',
    ),
    AgentModuleId.rewards: AgentModuleConnectorDescriptor(
      connectorId: 'connector.rewards',
      module: AgentModuleId.rewards,
      status: AgentModuleConnectorStatus.notConnected,
      enabled: false,
      readOnlyFirst: true,
      requiresRealModuleAudit: true,
      plannedReadActionIds: <String>[
        AgentActionId.readRewards,
      ],
      plannedWriteActionIds: <String>[
        AgentActionId.adjustRewardBalance,
      ],
      notes: 'Rewards connector not attached yet.',
    ),
    AgentModuleId.safety: AgentModuleConnectorDescriptor(
      connectorId: 'connector.safety',
      module: AgentModuleId.safety,
      status: AgentModuleConnectorStatus.notConnected,
      enabled: false,
      readOnlyFirst: true,
      requiresRealModuleAudit: true,
      plannedReadActionIds: <String>[
        AgentActionId.readSafetyAlert,
      ],
      plannedWriteActionIds: <String>[
        AgentActionId.sendSafetyAlert,
      ],
      notes: 'Safety remains ALERT + ASSIST only.',
    ),
    AgentModuleId.cargo: AgentModuleConnectorDescriptor(
      connectorId: 'connector.cargo',
      module: AgentModuleId.cargo,
      status: AgentModuleConnectorStatus.disabled,
      enabled: false,
      readOnlyFirst: true,
      requiresRealModuleAudit: true,
      plannedReadActionIds: <String>[
        AgentActionId.readCargoBooking,
        AgentActionId.readCargoStatus,
      ],
      plannedWriteActionIds: <String>[
        AgentActionId.cancelCargoBooking,
      ],
      notes: 'Cargo connector stays disabled until Cargo module is built.',
    ),
    AgentModuleId.student: AgentModuleConnectorDescriptor(
      connectorId: 'connector.student',
      module: AgentModuleId.student,
      status: AgentModuleConnectorStatus.disabled,
      enabled: false,
      readOnlyFirst: true,
      requiresRealModuleAudit: true,
      plannedReadActionIds: <String>[
        AgentActionId.readStudentRide,
        AgentActionId.readStudentAttendance,
        AgentActionId.readStudentSafety,
      ],
      plannedWriteActionIds: <String>[
        AgentActionId.changeGuardian,
        AgentActionId.overrideStudentSafety,
      ],
      notes: 'Student connector stays disabled until module + safety testing.',
    ),
    AgentModuleId.finance: AgentModuleConnectorDescriptor(
      connectorId: 'connector.finance',
      module: AgentModuleId.finance,
      status: AgentModuleConnectorStatus.notConnected,
      enabled: false,
      readOnlyFirst: true,
      requiresRealModuleAudit: true,
      plannedReadActionIds: <String>[
        AgentActionId.readFinanceSummary,
        AgentActionId.prepareSettlement,
      ],
      plannedWriteActionIds: <String>[
        AgentActionId.executeRefund,
        AgentActionId.approveWithdrawal,
      ],
      notes: 'Finance starts monitor/read-only; money execution remains approval-gated.',
    ),
  };

  static AgentModuleConnectorDescriptor? get(String module) =>
      _connectors[module];

  static List<AgentModuleConnectorDescriptor> get all =>
      _connectors.values.toList(growable: false);

  static bool isRealConnectorReady(String module) {
    final AgentModuleConnectorDescriptor? descriptor = _connectors[module];
    if (descriptor == null) return false;
    return descriptor.enabled && descriptor.connected;
  }
}
