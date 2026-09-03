import '../models/agent_future_evidence_snapshot.dart';

class AgentFutureEvidenceSourceId {
  AgentFutureEvidenceSourceId._();

  static const String customerFeedback = 'customer_feedback';
  static const String ratingsReviews = 'ratings_reviews';
  static const String supportTickets = 'support_tickets';
  static const String crashErrors = 'crash_errors';
  static const String failedBookings = 'failed_bookings';
  static const String cancellationReasons = 'cancellation_reasons';
  static const String searchBehavior = 'search_behavior';
  static const String featureUsage = 'feature_usage';
  static const String abandonedFlows = 'abandoned_flows';
  static const String adminDriverFeedback = 'admin_driver_feedback';
  static const String partnerFeedback = 'partner_feedback';

  static const Set<String> values = <String>{
    customerFeedback,
    ratingsReviews,
    supportTickets,
    crashErrors,
    failedBookings,
    cancellationReasons,
    searchBehavior,
    featureUsage,
    abandonedFlows,
    adminDriverFeedback,
    partnerFeedback,
  };
}

class AgentFutureEvidenceSourceDescriptor {
  const AgentFutureEvidenceSourceDescriptor({
    required this.sourceId,
    required this.module,
    required this.description,
    required this.defaultStatus,
    required this.existingReadPathHint,
  });

  final String sourceId;
  final String module;
  final String description;
  final String defaultStatus;

  /// Documentation-only hint to an existing read path/service/connector.
  ///
  /// This registry does not instantiate connectors and does not execute reads.
  final String existingReadPathHint;

  bool get isConnectedByDefault =>
      defaultStatus == AgentFutureEvidenceSourceStatus.available;

  void validate() {
    if (!AgentFutureEvidenceSourceId.values.contains(sourceId)) {
      throw AgentFutureEvidenceSourceRegistryException(
        'Unsupported sourceId: $sourceId',
      );
    }

    if (module.trim().isEmpty ||
        description.trim().isEmpty ||
        existingReadPathHint.trim().isEmpty) {
      throw const AgentFutureEvidenceSourceRegistryException(
        'Evidence source descriptor fields cannot be empty.',
      );
    }

    if (!AgentFutureEvidenceSourceStatus.isValid(defaultStatus)) {
      throw AgentFutureEvidenceSourceRegistryException(
        'Unsupported defaultStatus: $defaultStatus',
      );
    }
  }
}

/// Phase 41 source metadata registry.
///
/// IMPORTANT:
/// - This is NOT a second AgentReadOnlyConnectorRegistry.
/// - It does not call Firestore.
/// - It does not execute existing connectors.
/// - It only describes which read-only source should be used later by the
///   Future Evidence collector.
/// - Any unverified source remains NOT_CONNECTED/UNAVAILABLE.
/// - No fake analytics counts are created.
class AgentFutureEvidenceSourceRegistry {
  const AgentFutureEvidenceSourceRegistry();

  static const List<AgentFutureEvidenceSourceDescriptor>
  sources = <AgentFutureEvidenceSourceDescriptor>[
    AgentFutureEvidenceSourceDescriptor(
      sourceId: AgentFutureEvidenceSourceId.customerFeedback,
      module: 'feedback',
      description: 'Customer feedback and suggestions.',
      defaultStatus: AgentFutureEvidenceSourceStatus.available,
      existingReadPathHint: 'AgentFeedbackService / feedback read paths',
    ),
    AgentFutureEvidenceSourceDescriptor(
      sourceId: AgentFutureEvidenceSourceId.ratingsReviews,
      module: 'feedback',
      description: 'Ratings and review evidence.',
      defaultStatus: AgentFutureEvidenceSourceStatus.available,
      existingReadPathHint:
          'feedback rating/review services and module review services',
    ),
    AgentFutureEvidenceSourceDescriptor(
      sourceId: AgentFutureEvidenceSourceId.supportTickets,
      module: 'support',
      description: 'Support request/ticket evidence.',
      defaultStatus: AgentFutureEvidenceSourceStatus.available,
      existingReadPathHint: 'AgentSupportRequest / support service read paths',
    ),
    AgentFutureEvidenceSourceDescriptor(
      sourceId: AgentFutureEvidenceSourceId.crashErrors,
      module: 'core',
      description: 'Crash/error occurrence evidence.',
      defaultStatus: AgentFutureEvidenceSourceStatus.available,
      existingReadPathHint: 'AgentCrashEventService.watchOpen()',
    ),
    AgentFutureEvidenceSourceDescriptor(
      sourceId: AgentFutureEvidenceSourceId.failedBookings,
      module: 'booking',
      description: 'Failed-booking evidence from existing booking modules.',
      defaultStatus: AgentFutureEvidenceSourceStatus.notConnected,
      existingReadPathHint:
          'module booking services; exact read adapter required',
    ),
    AgentFutureEvidenceSourceDescriptor(
      sourceId: AgentFutureEvidenceSourceId.cancellationReasons,
      module: 'booking',
      description: 'Cancellation reason evidence.',
      defaultStatus: AgentFutureEvidenceSourceStatus.notConnected,
      existingReadPathHint:
          'module cancellation models/services; exact read adapter required',
    ),
    AgentFutureEvidenceSourceDescriptor(
      sourceId: AgentFutureEvidenceSourceId.searchBehavior,
      module: 'core',
      description: 'Search-query/behavior evidence.',
      defaultStatus: AgentFutureEvidenceSourceStatus.notConnected,
      existingReadPathHint:
          'existing search flows; dedicated safe read source not verified',
    ),
    AgentFutureEvidenceSourceDescriptor(
      sourceId: AgentFutureEvidenceSourceId.featureUsage,
      module: 'core',
      description: 'Feature usage/interaction telemetry.',
      defaultStatus: AgentFutureEvidenceSourceStatus.unavailable,
      existingReadPathHint: 'no verified app-wide feature telemetry source yet',
    ),
    AgentFutureEvidenceSourceDescriptor(
      sourceId: AgentFutureEvidenceSourceId.abandonedFlows,
      module: 'core',
      description: 'Abandoned/incomplete flow evidence.',
      defaultStatus: AgentFutureEvidenceSourceStatus.notConnected,
      existingReadPathHint:
          'existing flow-specific signals; dedicated safe read adapter required',
    ),
    AgentFutureEvidenceSourceDescriptor(
      sourceId: AgentFutureEvidenceSourceId.adminDriverFeedback,
      module: 'operations',
      description: 'Admin and driver feedback evidence.',
      defaultStatus: AgentFutureEvidenceSourceStatus.notConnected,
      existingReadPathHint:
          'driver/admin feedback paths; exact privacy-minimized adapter required',
    ),
    AgentFutureEvidenceSourceDescriptor(
      sourceId: AgentFutureEvidenceSourceId.partnerFeedback,
      module: 'partners',
      description: 'Restaurant/hotel/tour partner feedback evidence.',
      defaultStatus: AgentFutureEvidenceSourceStatus.notConnected,
      existingReadPathHint:
          'partner feedback/review paths; exact safe adapter required',
    ),
  ];

  AgentFutureEvidenceSourceDescriptor? descriptorFor(String sourceId) {
    final String normalized = sourceId.trim();

    for (final AgentFutureEvidenceSourceDescriptor source in sources) {
      if (source.sourceId == normalized) {
        return source;
      }
    }

    return null;
  }

  List<AgentFutureEvidenceSourceDescriptor> get connectedByDefault => sources
      .where(
        (AgentFutureEvidenceSourceDescriptor source) =>
            source.isConnectedByDefault,
      )
      .toList(growable: false);

  List<AgentFutureEvidenceSourceDescriptor> get unavailableOrNotConnected =>
      sources
          .where(
            (AgentFutureEvidenceSourceDescriptor source) =>
                !source.isConnectedByDefault,
          )
          .toList(growable: false);

  void validate() {
    final Set<String> ids = <String>{};

    for (final AgentFutureEvidenceSourceDescriptor source in sources) {
      source.validate();

      if (!ids.add(source.sourceId)) {
        throw AgentFutureEvidenceSourceRegistryException(
          'Duplicate evidence sourceId: ${source.sourceId}',
        );
      }
    }

    if (ids.length != AgentFutureEvidenceSourceId.values.length) {
      throw const AgentFutureEvidenceSourceRegistryException(
        'Future evidence registry must describe every required source.',
      );
    }
  }
}

class AgentFutureEvidenceSourceRegistryException implements Exception {
  const AgentFutureEvidenceSourceRegistryException(this.message);

  final String message;

  @override
  String toString() => 'AgentFutureEvidenceSourceRegistryException: $message';
}
