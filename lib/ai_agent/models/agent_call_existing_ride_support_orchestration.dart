import '../constants/agent_call_constants.dart';
import 'agent_call_existing_ride_support_contract.dart';

class AgentCallExistingRideConcernKind {
  AgentCallExistingRideConcernKind._();

  static const String normal = 'NORMAL';
  static const String paymentDispute = 'PAYMENT_DISPUTE';
  static const String emergency = 'EMERGENCY';
  static const String legal = 'LEGAL';
  static const String fraud = 'FRAUD';

  static const Set<String> values = <String>{
    normal,
    paymentDispute,
    emergency,
    legal,
    fraud,
  };

  static String routerIntent(String concernKind) {
    switch (concernKind) {
      case paymentDispute:
        return AgentCallIntent.paymentDispute;
      case emergency:
        return AgentCallIntent.emergency;
      case legal:
        return AgentCallIntent.legal;
      case fraud:
        return AgentCallIntent.fraud;
      case normal:
      default:
        return AgentCallIntent.rideStatus;
    }
  }
}

/// Triage input may affect escalation routing only.
///
/// It is never:
/// - Ride ownership evidence;
/// - permission evidence;
/// - authorization to read sensitive Ride data;
/// - authorization to mutate/cancel/reassign/refund a Ride.
class AgentCallExistingRideConcern {
  const AgentCallExistingRideConcern({
    this.kind = AgentCallExistingRideConcernKind.normal,
    this.serious = false,
    this.critical = false,
  });

  final String kind;
  final bool serious;
  final bool critical;

  void validate() {
    if (!AgentCallExistingRideConcernKind.values.contains(kind)) {
      throw const AgentCallExistingRideSupportException(
        'Unsupported existing-Ride support concern kind.',
      );
    }
  }

  String get routerIntent =>
      AgentCallExistingRideConcernKind.routerIntent(kind);

  bool get needsImmediateEscalation =>
      critical ||
      serious ||
      kind == AgentCallExistingRideConcernKind.paymentDispute ||
      kind == AgentCallExistingRideConcernKind.emergency ||
      kind == AgentCallExistingRideConcernKind.legal ||
      kind == AgentCallExistingRideConcernKind.fraud;

  bool get grantsRideReadAuthority => false;
  bool get grantsRideWriteAuthority => false;
}

class AgentCallExistingRideOrchestrationStatus {
  AgentCallExistingRideOrchestrationStatus._();

  static const String answered = 'ANSWERED_FROM_TRUSTED_RIDE_SNAPSHOT';
  static const String escalated = 'SAFE_ESCALATION_RECOMMENDED';
  static const String blocked = 'SUPPORT_BLOCKED';

  static const Set<String> values = <String>{answered, escalated, blocked};
}

class AgentCallExistingRideSupportOrchestrationResult {
  const AgentCallExistingRideSupportOrchestrationResult({
    required this.status,
    required this.code,
    required this.authorizationAllowed,
    required this.readAttempted,
    required this.escalationLevel,
    required this.escalationRecommended,
    required this.createdAt,
    this.supportResult,
  });

  final String status;
  final String code;
  final bool authorizationAllowed;
  final bool readAttempted;
  final String escalationLevel;
  final bool escalationRecommended;
  final DateTime createdAt;
  final AgentCallExistingRideSupportResult? supportResult;

  bool get answered =>
      status == AgentCallExistingRideOrchestrationStatus.answered &&
      authorizationAllowed &&
      readAttempted &&
      !escalationRecommended &&
      escalationLevel == AgentCallEscalationLevel.ai &&
      (supportResult?.isReady ?? false);

  bool get escalated =>
      status == AgentCallExistingRideOrchestrationStatus.escalated &&
      escalationRecommended &&
      escalationLevel != AgentCallEscalationLevel.ai;

  bool get blocked =>
      status == AgentCallExistingRideOrchestrationStatus.blocked;

  Map<String, dynamic> toSafeMap() {
    return <String, dynamic>{
      'status': status,
      'code': code,
      'authorizationAllowed': authorizationAllowed,
      'readAttempted': readAttempted,
      'escalationLevel': escalationLevel,
      'escalationRecommended': escalationRecommended,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'supportResult': supportResult?.toSafeMap(),
      'transferExecuted': false,
      'rideWritePerformed': false,
      'rideCancelled': false,
      'driverReassigned': false,
      'paymentChanged': false,
      'refundIssued': false,
      'fareChanged': false,
    };
  }
}
