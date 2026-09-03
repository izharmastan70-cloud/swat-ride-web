import '../models/agent_call_food_order_status_contract.dart';
import '../models/agent_call_food_order_trusted_resolution.dart';

/// Trusted server boundary required by Phase 49 Stage 3.
///
/// There is intentionally NO default Flutter/client implementation.
///
/// Production must verify caller/contact/order access using trusted server-side
/// identity and Food order state. Raw phone, transcript, voice, current
/// Firebase user and an order reference alone are never ownership authority.
abstract class AgentCallFoodOrderTrustedBackendResolver {
  Future<AgentCallFoodOrderTrustedResolutionReceipt> resolveAndRead({
    required AgentCallFoodOrderTrustedResolutionRequest request,
    required DateTime now,
  });
}

/// Small interface for the next orchestration step.
///
/// Step 3E can depend on this abstraction without learning how the trusted
/// backend resolves the Food order.
abstract class AgentCallFoodOrderStatusReadGateway {
  Future<AgentCallFoodOrderStatusReadEvidence> readAuthorizedFoodOrderStatus({
    required AgentCallFoodOrderStatusRequest request,
    required DateTime now,
  });
}

class AgentCallFoodOrderTrustedBackendReadGateway
    implements AgentCallFoodOrderStatusReadGateway {
  const AgentCallFoodOrderTrustedBackendReadGateway({required this.resolver});

  final AgentCallFoodOrderTrustedBackendResolver resolver;

  @override
  Future<AgentCallFoodOrderStatusReadEvidence> readAuthorizedFoodOrderStatus({
    required AgentCallFoodOrderStatusRequest request,
    required DateTime now,
  }) async {
    final DateTime normalizedNow = now.toUtc();

    try {
      request.validate();

      final AgentCallFoodOrderTrustedResolutionRequest resolutionRequest =
          AgentCallFoodOrderTrustedResolutionRequest.fromStatusRequest(request);

      final AgentCallFoodOrderTrustedResolutionReceipt receipt = await resolver
          .resolveAndRead(request: resolutionRequest, now: normalizedNow);

      receipt.validateAgainst(request: resolutionRequest, now: normalizedNow);

      if (!receipt.isAuthorized) {
        return AgentCallFoodOrderStatusReadEvidence.unavailable(
          observedAt: normalizedNow,
        );
      }

      final AgentCallFoodOrderStatusSnapshot snapshot = receipt.snapshot!;

      final AgentCallFoodOrderStatusReadEvidence evidence =
          AgentCallFoodOrderStatusReadEvidence.authorized(
            snapshot: snapshot,
            observedAt: normalizedNow,
          );

      evidence.validate();
      return evidence;
    } catch (_) {
      // Fail closed and deliberately hide whether the order exists.
      return AgentCallFoodOrderStatusReadEvidence.unavailable(
        observedAt: normalizedNow,
      );
    }
  }

  bool get requiresTrustedBackendResolver => true;
  bool get defaultFlutterProductionResolverConnected => false;
  bool get requiresBackendOrderAccessVerification => true;
  bool get hidesUnauthorizedOrderExistence => true;
  bool get requiresExactSessionBinding => true;
  bool get requiresExactRequestedByBinding => true;
  bool get requiresExactCallerBinding => true;
  bool get requiresExactContactBinding => true;
  bool get requiresExactOrderBinding => true;
  bool get requiresFreshResolution => true;

  bool get rawPhoneCanAuthorize => false;
  bool get transcriptCanAuthorize => false;
  bool get voiceCanAuthorize => false;
  bool get currentFirebaseUserCanAuthorize => false;
  bool get orderReferenceAloneCanAuthorize => false;

  bool get invokesGenericFoodConnector => false;
  bool get invokesFoodOrderService => false;
  bool get invokesFirestore => false;
  bool get invokesFirebaseAuth => false;
  bool get invokesHttp => false;
  bool get invokesCloudFunctions => false;
  bool get invokesTelephonyProvider => false;

  bool get writesFoodOrder => false;
  bool get createsFoodOrder => false;
  bool get cancelsFoodOrder => false;
  bool get refundsFoodOrder => false;
  bool get changesPayment => false;
  bool get assignsRider => false;
}
