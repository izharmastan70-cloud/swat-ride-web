import '../constants/agent_call_constants.dart';
import 'agent_call_food_order_trusted_resolution.dart';

class AgentCallFoodOrderStatusOrchestrationStatus {
  AgentCallFoodOrderStatusOrchestrationStatus._();

  static const String answerReady = 'ANSWER_READY';
  static const String escalationRecommended = 'ESCALATION_RECOMMENDED';

  static const Set<String> values = <String>{
    answerReady,
    escalationRecommended,
  };
}

class AgentCallFoodOrderStatusOrchestrationResult {
  const AgentCallFoodOrderStatusOrchestrationResult({
    required this.status,
    required this.escalationLevel,
    required this.reason,
    required this.processedAt,
    this.snapshot,
  });

  final String status;
  final String escalationLevel;
  final String reason;
  final DateTime processedAt;
  final AgentCallFoodOrderStatusSnapshot? snapshot;

  bool get answerReady =>
      status == AgentCallFoodOrderStatusOrchestrationStatus.answerReady;

  bool get escalationRecommended =>
      status ==
      AgentCallFoodOrderStatusOrchestrationStatus.escalationRecommended;

  void validate() {
    if (!AgentCallFoodOrderStatusOrchestrationStatus.values.contains(status)) {
      throw const AgentCallFoodOrderStatusOrchestrationException(
        'Unknown Food status orchestration result.',
      );
    }

    if (reason.trim().isEmpty) {
      throw const AgentCallFoodOrderStatusOrchestrationException(
        'Food status orchestration reason is required.',
      );
    }

    if (answerReady) {
      if (escalationLevel != AgentCallEscalationLevel.ai || snapshot == null) {
        throw const AgentCallFoodOrderStatusOrchestrationException(
          'ANSWER_READY requires AI level and a safe Food snapshot.',
        );
      }

      snapshot!.validate();
      return;
    }

    if (escalationLevel == AgentCallEscalationLevel.ai || snapshot != null) {
      throw const AgentCallFoodOrderStatusOrchestrationException(
        'Escalation recommendation must expose no Food snapshot.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return <String, dynamic>{
      'status': status,
      'escalationLevel': escalationLevel,
      'reason': reason.trim(),
      'processedAt': processedAt.toUtc().toIso8601String(),
      'snapshot': snapshot?.toSafeMap(),
      'recommendationOnly': true,
      'actualTransferExecuted': false,
      'foodWriteExecuted': false,
      'refundExecuted': false,
      'cancelExecuted': false,
      'paymentChanged': false,
      'riderAssignmentChanged': false,
      'providerInvoked': false,
    };
  }
}

class AgentCallFoodOrderStatusOrchestrationException implements Exception {
  const AgentCallFoodOrderStatusOrchestrationException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentCallFoodOrderStatusOrchestrationException: $message';
}
