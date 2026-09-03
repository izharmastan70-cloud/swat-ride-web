import '../constants/agent_performance_metric_constants.dart';

class AgentPerformanceMetricObservation {
  const AgentPerformanceMetricObservation({
    required this.observationId,
    required this.metricId,
    required this.agentId,
    required this.sourceReference,
    required this.windowStartEpochMs,
    required this.windowEndEpochMs,
    required this.numericValue,
    required this.sampleCount,
    required this.trustedSourceProjection,
    required this.minimumNecessaryMetadata,
    required this.privacySafeProjection,
  });

  final String observationId;
  final String metricId;
  final String agentId;
  final String sourceReference;

  final int windowStartEpochMs;
  final int windowEndEpochMs;
  final double numericValue;
  final int sampleCount;

  final bool trustedSourceProjection;
  final bool minimumNecessaryMetadata;
  final bool privacySafeProjection;

  bool get containsRawPrompt => false;
  bool get containsRawConversation => false;
  bool get containsRawProviderResponse => false;
  bool get containsPrivatePayload => false;
  bool get containsSecret => false;
  bool get containsAuthToken => false;
  bool get containsApprovalToken => false;
  bool get containsPermissionToken => false;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get authorizesExecution => false;
  bool get executesBusinessAction => false;
  bool get mutatesAgentState => false;
  bool get persistsObservation => false;

  void validateStructure() {
    final List<String> opaqueIds = <String>[
      observationId,
      agentId,
      sourceReference,
    ];

    final bool badOpaqueId = opaqueIds.any((String value) {
      final String trimmed = value.trim();

      return trimmed.isEmpty ||
          trimmed.length > AgentPerformanceMetricLimits.opaqueIdMaxLength ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
    });

    if (badOpaqueId ||
        !AgentPerformanceMetricId.values.contains(metricId) ||
        windowStartEpochMs < 0 ||
        windowEndEpochMs <= windowStartEpochMs ||
        numericValue.isNaN ||
        numericValue.isInfinite ||
        sampleCount < 0 ||
        sampleCount > AgentPerformanceMetricLimits.maxSampleCount) {
      throw const FormatException(
        'Invalid Agent Performance metric observation.',
      );
    }
  }
}
