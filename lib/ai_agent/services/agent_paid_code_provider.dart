import '../models/agent_paid_code_request.dart';
import '../models/agent_paid_code_response.dart';

// =========================================================
// AI AGENT — PAID CODE PROVIDER CONTRACT
// =========================================================
//
// Dedicated technical provider only.
// It has no access to business support, payments, users, Ride/Food/Hotel
// operations, or unrestricted Firebase.
//
// Real provider adapter is added later with owner-controlled secrets.

abstract class AgentPaidCodeProvider {
  String get providerId;
  bool get enabled;

  Future<bool> isAvailable();

  Future<AgentPaidCodeResponse> analyze(
    AgentPaidCodeRequest request,
  );
}
