// =========================================================
// AI AGENT — PAID CODE RESPONSE
// =========================================================
//
// Analysis/patch proposal only in Phase 15.
// No file write/deploy is executed here.

class AgentPaidCodeResponse {
  final String requestId;
  final String providerId;
  final String status;
  final String diagnosis;
  final String proposedFixSummary;
  final Map<String, String> proposedFilePatches;
  final List<String> additionalFilesRequested;
  final String message;
  final Map<String, dynamic> usage;

  const AgentPaidCodeResponse({
    required this.requestId,
    required this.providerId,
    required this.status,
    required this.diagnosis,
    required this.proposedFixSummary,
    required this.proposedFilePatches,
    required this.additionalFilesRequested,
    required this.message,
    this.usage = const <String, dynamic>{},
  });

  bool get isSuccess => status == 'SUCCESS';

  bool get requestsScopeExpansion =>
      additionalFilesRequested.isNotEmpty;
}
