import '../constants/agent_call_constants.dart';
import 'agent_call_tour_booking_trusted_resolution.dart';

class AgentCallTourBookingStatusOrchestrationStatus {
  AgentCallTourBookingStatusOrchestrationStatus._();

  static const String answerReady = 'ANSWER_READY';
  static const String escalationRecommended = 'ESCALATION_RECOMMENDED';

  static const Set<String> values = <String>{
    answerReady,
    escalationRecommended,
  };
}

class AgentCallTourBookingStatusOrchestrationResult {
  const AgentCallTourBookingStatusOrchestrationResult({
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
  final AgentCallTourBookingStatusSnapshot? snapshot;

  bool get answerReady =>
      status == AgentCallTourBookingStatusOrchestrationStatus.answerReady;

  bool get escalationRecommended =>
      status ==
      AgentCallTourBookingStatusOrchestrationStatus.escalationRecommended;

  void validate() {
    if (!AgentCallTourBookingStatusOrchestrationStatus.values.contains(
      status,
    )) {
      throw const AgentCallTourBookingStatusOrchestrationException(
        'Unknown Tour status orchestration result.',
      );
    }

    if (reason.trim().isEmpty) {
      throw const AgentCallTourBookingStatusOrchestrationException(
        'Tour status orchestration reason is required.',
      );
    }

    if (answerReady) {
      if (escalationLevel != AgentCallEscalationLevel.ai || snapshot == null) {
        throw const AgentCallTourBookingStatusOrchestrationException(
          'ANSWER_READY requires AI level and a safe Tour snapshot.',
        );
      }

      snapshot!.validate();
      return;
    }

    if (escalationLevel == AgentCallEscalationLevel.ai || snapshot != null) {
      throw const AgentCallTourBookingStatusOrchestrationException(
        'Escalation recommendation must expose no Tour snapshot.',
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
      'tourWriteExecuted': false,
      'tourCreateExecuted': false,
      'tourCancelExecuted': false,
      'tourPriceChanged': false,
      'tourPaymentChanged': false,
      'tourAssignmentChanged': false,
      'providerInvoked': false,
    };
  }
}

class AgentCallTourBookingStatusOrchestrationException implements Exception {
  const AgentCallTourBookingStatusOrchestrationException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentCallTourBookingStatusOrchestrationException: $message';
}
