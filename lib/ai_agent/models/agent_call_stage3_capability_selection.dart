import '../constants/agent_action_ids.dart';
import 'agent_call_service_request_draft.dart';

/// Phase 49 Stage 3 Step 3B.
///
/// Audit-driven selection of the FIRST multi-service Call capability.
///
/// IMPORTANT:
/// This file selects what Stage 3 should implement first. It does not grant a
/// permission, execute a connector, fetch an order, create an order, mutate
/// Food state, or connect telephony.
///
/// The selected capability is FOOD ORDER STATUS / READ because:
/// - FOOD already exists in the Call service draft/facade;
/// - food.read_order is LOW risk and read-only;
/// - AgentFoodOrderReadOnlyConnector is a real connector;
/// - that Food connector is already registered in the central read-only
///   connector registry;
/// - Hotel/Tour connector files exist but are not yet central-registry ready;
/// - Cargo/Student are still connector stubs;
/// - Parcel has no verified Call/AI connector in the Step 3A audit.
class AgentCallStage3CapabilitySelection {
  const AgentCallStage3CapabilitySelection._();

  static const String selectedService = AgentCallServiceType.food;
  static const String selectedRequestType = AgentCallServiceRequestType.status;
  static const String selectedBusinessReadAction = AgentActionId.readFoodOrder;

  static const String selectedCapability = 'FOOD_ORDER_STATUS_READ';

  static const bool selectedConnectorExists = true;
  static const bool selectedConnectorCentrallyRegistered = true;
  static const bool selectedBusinessActionReadOnly = true;
  static const bool selectedBusinessActionLowRisk = true;

  // Step 3B is selection/readiness only.
  static const bool addsCallPermission = false;
  static const bool executesFoodConnector = false;
  static const bool readsFoodOrderNow = false;
  static const bool createsFoodOrder = false;
  static const bool cancelsFoodOrder = false;
  static const bool refundsFoodOrder = false;
  static const bool changesPayment = false;
  static const bool assignsRider = false;
  static const bool writesFoodData = false;

  // Stage 3C must introduce a dedicated CALL action and trusted customer/order
  // binding. call_agent must not inherit the generic food.read_order action.
  static const bool requiresDedicatedCallAction = true;
  static const bool mayGrantGenericFoodActionToCallAgent = false;
  static const bool requiresCentralPermissionEngine = true;
  static const bool requiresRuntimeGate = true;
  static const bool requiresTrustedCallerContactBinding = true;
  static const bool requiresTrustedOrderAccessBinding = true;
  static const bool rawPhoneCanAuthorize = false;
  static const bool transcriptCanAuthorize = false;
  static const bool voiceCanAuthorize = false;
  static const bool orderIdAloneCanAuthorize = false;
  static const bool currentFirebaseUserCanImpersonateCaller = false;

  // Other modules remain deferred after the Step 3A audit.
  static const bool hotelSelectedNow = false;
  static const bool hotelCentralRegistryReady = false;
  static const bool tourSelectedNow = false;
  static const bool tourCentralRegistryReady = false;
  static const bool cargoSelectedNow = false;
  static const bool cargoConnectorReady = false;
  static const bool studentSelectedNow = false;
  static const bool studentConnectorReady = false;
  static const bool parcelSelectedNow = false;
  static const bool parcelConnectorVerified = false;

  static const bool stage3BSelectionReady =
      selectedService == AgentCallServiceType.food &&
      selectedRequestType == AgentCallServiceRequestType.status &&
      selectedBusinessReadAction == AgentActionId.readFoodOrder &&
      selectedConnectorExists &&
      selectedConnectorCentrallyRegistered &&
      selectedBusinessActionReadOnly &&
      selectedBusinessActionLowRisk &&
      requiresDedicatedCallAction &&
      !addsCallPermission &&
      !executesFoodConnector &&
      !writesFoodData;

  static Map<String, dynamic> toSafeMap() {
    return <String, dynamic>{
      'selectedService': selectedService,
      'selectedRequestType': selectedRequestType,
      'selectedCapability': selectedCapability,
      'selectedBusinessReadAction': selectedBusinessReadAction,
      'selectedConnectorExists': selectedConnectorExists,
      'selectedConnectorCentrallyRegistered':
          selectedConnectorCentrallyRegistered,
      'selectedBusinessActionReadOnly': selectedBusinessActionReadOnly,
      'selectedBusinessActionLowRisk': selectedBusinessActionLowRisk,
      'stage3BSelectionReady': stage3BSelectionReady,
      'addsCallPermission': addsCallPermission,
      'executesFoodConnector': executesFoodConnector,
      'writesFoodData': writesFoodData,
      'requiresDedicatedCallAction': requiresDedicatedCallAction,
      'mayGrantGenericFoodActionToCallAgent':
          mayGrantGenericFoodActionToCallAgent,
      'rawPhoneCanAuthorize': rawPhoneCanAuthorize,
      'transcriptCanAuthorize': transcriptCanAuthorize,
      'voiceCanAuthorize': voiceCanAuthorize,
      'orderIdAloneCanAuthorize': orderIdAloneCanAuthorize,
      'hotelCentralRegistryReady': hotelCentralRegistryReady,
      'tourCentralRegistryReady': tourCentralRegistryReady,
      'cargoConnectorReady': cargoConnectorReady,
      'studentConnectorReady': studentConnectorReady,
      'parcelConnectorVerified': parcelConnectorVerified,
    };
  }
}
