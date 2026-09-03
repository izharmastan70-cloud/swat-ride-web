import '../constants/agent_action_ids.dart';

class AgentCallStage3NextServiceSelection {
  const AgentCallStage3NextServiceSelection._();

  static const String selectedService = 'TOUR';
  static const String selectedCapability = 'TOUR_BOOKING_STATUS_READ';
  static const String selectedRequestType = 'STATUS';
  static const String genericBusinessReadAction = AgentActionId.readTourBooking;

  static const bool selectionOnly = true;
  static const bool tourConnectorImplementationExists = true;
  static const bool tourCallStatusBridgeExists = true;
  static const bool tourGenericActionLowRisk = true;
  static const bool tourGenericActionReadOnly = true;

  // The selection does NOT activate the generic Tour connector path.
  static const bool tourCentralRegistryReadyNow = false;
  static const bool step3GAddsCallPermission = false;
  static const bool step3GExecutesTourConnector = false;
  static const bool step3GReadsRealTourBooking = false;
  static const bool mayGrantGenericTourActionToCallAgent = false;

  // Why Tour is selected before Hotel.
  static const bool tourRawPayloadReturnsUserId = false;
  static const bool tourRawPayloadReturnsFinancialAmounts = false;
  static const bool tourRawPayloadReturnsExactAssignmentIds = false;
  static const bool tourUsesAssignmentPresenceFlags = true;

  static const bool hotelConnectorImplementationExists = true;
  static const bool hotelCentralRegistryReadyNow = false;
  static const bool hotelRawPayloadCurrentlyReturnsUserId = true;
  static const bool hotelDeferred = true;

  static const bool cargoDeferred = true;
  static const bool studentDeferred = true;
  static const bool parcelDeferred = true;

  // Trusted Call authorization/binding remains mandatory before a real read.
  static const bool requiresDedicatedCallAction = true;
  static const bool requiresPermissionEngine = true;
  static const bool requiresRuntimeGate = true;
  static const bool requiresTrustedCallerBinding = true;
  static const bool requiresTrustedContactBinding = true;
  static const bool requiresTrustedTourBookingBinding = true;
  static const bool rawPhoneIsAuthority = false;
  static const bool transcriptIsAuthority = false;
  static const bool voiceIsAuthority = false;
  static const bool rawBookingIdAloneIsAuthority = false;
  static const bool firebaseCurrentUserMayImpersonateCaller = false;

  static const bool createsTourBooking = false;
  static const bool cancelsTourBooking = false;
  static const bool changesTourPrice = false;
  static const bool changesTourPayment = false;
  static const bool changesTourAssignment = false;
  static const bool writesTourBooking = false;

  static const String nextStep =
      'PHASE 49 STAGE 3 STEP 3H - TOUR BOOKING STATUS DEDICATED CALL AUTHORIZATION + TRUSTED BOOKING BINDING CONTRACT';

  static const bool isSafelySelected =
      selectedService == 'TOUR' &&
      selectedRequestType == 'STATUS' &&
      selectionOnly &&
      tourConnectorImplementationExists &&
      tourCallStatusBridgeExists &&
      tourGenericActionLowRisk &&
      tourGenericActionReadOnly &&
      !tourCentralRegistryReadyNow &&
      !step3GAddsCallPermission &&
      !step3GExecutesTourConnector &&
      !step3GReadsRealTourBooking &&
      !mayGrantGenericTourActionToCallAgent &&
      !tourRawPayloadReturnsUserId &&
      !tourRawPayloadReturnsFinancialAmounts &&
      !tourRawPayloadReturnsExactAssignmentIds &&
      tourUsesAssignmentPresenceFlags &&
      hotelDeferred &&
      requiresDedicatedCallAction &&
      requiresPermissionEngine &&
      requiresRuntimeGate &&
      requiresTrustedCallerBinding &&
      requiresTrustedContactBinding &&
      requiresTrustedTourBookingBinding &&
      !rawPhoneIsAuthority &&
      !transcriptIsAuthority &&
      !voiceIsAuthority &&
      !rawBookingIdAloneIsAuthority &&
      !firebaseCurrentUserMayImpersonateCaller &&
      !writesTourBooking;
}
