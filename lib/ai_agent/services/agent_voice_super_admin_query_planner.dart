import '../models/agent_voice_super_admin_query_plan.dart';
import '../models/agent_voice_super_admin_report_orchestration_request.dart';
import '../models/agent_voice_super_admin_response.dart';
import '../models/agent_voice_super_admin_source_acquisition_request.dart';

class AgentVoiceSuperAdminQueryReferenceKey {
  AgentVoiceSuperAdminQueryReferenceKey._();

  static const String rideId = 'rideId';
  static const String driverId = 'driverId';
  static const String orderId = 'orderId';
  static const String restaurantId = 'restaurantId';
  static const String hotelBookingId = 'hotelBookingId';
  static const String tourBookingId = 'tourBookingId';
  static const String cargoBookingId = 'cargoBookingId';
  static const String parcelBookingId = 'parcelBookingId';
  static const String studentId = 'studentId';
}

class AgentVoiceSuperAdminQueryPlanningRequest {
  const AgentVoiceSuperAdminQueryPlanningRequest({
    required this.queryText,
    this.referenceIds = const <String, String>{},
    this.outputPreference = const AgentVoiceSuperAdminOutputPreference(),
  });

  /// May come from typed text now or a future STT transcript.
  ///
  /// It is intent data only and never authenticates/authorizes the Owner.
  final String queryText;

  /// Exact identifiers must be supplied by a trusted surrounding flow.
  /// The planner never extracts IDs from free-form voice/text.
  final Map<String, String> referenceIds;

  final AgentVoiceSuperAdminOutputPreference outputPreference;
}

/// Deterministic Phase 48 query planner.
///
/// No AI provider is used. It recognizes a deliberately small allowlist of
/// read/report/explain intents and converts them into explicit Step 2E report
/// source requests.
///
/// Security:
/// - raw voice/text is never authority;
/// - IDs are never guessed or parsed from speech;
/// - unsupported/ambiguous requests fail closed;
/// - writes, approvals and high-risk commands are never planned here.
class AgentVoiceSuperAdminQueryPlanner {
  const AgentVoiceSuperAdminQueryPlanner();

  AgentVoiceSuperAdminQueryPlan plan({
    required AgentVoiceSuperAdminQueryPlanningRequest request,
    required DateTime now,
  }) {
    final String query = _normalize(request.queryText);

    if (query.isEmpty) {
      return _unsupported(
        query: 'empty',
        code: 'QUERY_TEXT_REQUIRED',
        now: now,
      );
    }

    if (_looksConsequential(query)) {
      return _unsupported(
        query: query,
        code: 'READ_ONLY_PLANNER_REJECTED_CONSEQUENTIAL_REQUEST',
        now: now,
      );
    }

    if (_isWholeEcosystemIntent(query)) {
      return _planned(
        intent: 'WHOLE_ECOSYSTEM_STATUS',
        query: query,
        now: now,
        outputPreference: request.outputPreference,
        sources: _wholeEcosystemSources(request.referenceIds),
      );
    }

    final List<_PlannedModule> recognized = <_PlannedModule>[];

    if (_containsAny(query, <String>[
      'system health',
      'system status',
      'ai health',
    ])) {
      recognized.add(
        const _PlannedModule(
          moduleId: 'SYSTEM_HEALTH',
          readKind: AgentVoiceSuperAdminSourceReadKind.status,
        ),
      );
    }

    if (_containsAny(query, <String>[
      'normal ride',
      'ride status',
      'ride detail',
      'ride details',
    ])) {
      recognized.add(
        _PlannedModule(
          moduleId: 'NORMAL_RIDE',
          readKind: _wantsDetails(query)
              ? AgentVoiceSuperAdminSourceReadKind.details
              : AgentVoiceSuperAdminSourceReadKind.status,
          referenceId: _reference(
            request.referenceIds,
            AgentVoiceSuperAdminQueryReferenceKey.rideId,
          ),
        ),
      );
    }

    if (_containsAny(query, <String>[
      'driver status',
      'driver detail',
      'driver details',
      'driver',
    ])) {
      recognized.add(
        _PlannedModule(
          moduleId: 'DRIVER',
          readKind: _wantsDetails(query)
              ? AgentVoiceSuperAdminSourceReadKind.details
              : AgentVoiceSuperAdminSourceReadKind.status,
          referenceId: _reference(
            request.referenceIds,
            AgentVoiceSuperAdminQueryReferenceKey.driverId,
          ),
        ),
      );
    }

    if (_containsAny(query, <String>[
      'food order',
      'food status',
      'order status',
    ])) {
      recognized.add(
        _PlannedModule(
          moduleId: 'FOOD',
          readKind: _wantsDetails(query)
              ? AgentVoiceSuperAdminSourceReadKind.details
              : AgentVoiceSuperAdminSourceReadKind.status,
          referenceId: _reference(
            request.referenceIds,
            AgentVoiceSuperAdminQueryReferenceKey.orderId,
          ),
        ),
      );
    }

    if (_containsAny(query, <String>[
      'restaurant status',
      'restaurant detail',
      'restaurant details',
      'restaurant',
    ])) {
      recognized.add(
        _PlannedModule(
          moduleId: 'RESTAURANT',
          readKind: _wantsDetails(query)
              ? AgentVoiceSuperAdminSourceReadKind.details
              : AgentVoiceSuperAdminSourceReadKind.status,
          referenceId: _reference(
            request.referenceIds,
            AgentVoiceSuperAdminQueryReferenceKey.restaurantId,
          ),
        ),
      );
    }

    if (_containsAny(query, <String>['hotel', 'hotel booking'])) {
      recognized.add(
        _PlannedModule(
          moduleId: 'HOTEL',
          readKind: AgentVoiceSuperAdminSourceReadKind.status,
          referenceId: _reference(
            request.referenceIds,
            AgentVoiceSuperAdminQueryReferenceKey.hotelBookingId,
          ),
        ),
      );
    }

    if (_containsAny(query, <String>['tour', 'tour booking', 'tourism'])) {
      recognized.add(
        _PlannedModule(
          moduleId: 'TOUR',
          readKind: AgentVoiceSuperAdminSourceReadKind.status,
          referenceId: _reference(
            request.referenceIds,
            AgentVoiceSuperAdminQueryReferenceKey.tourBookingId,
          ),
        ),
      );
    }

    if (_containsAny(query, <String>['cargo', 'cargo booking'])) {
      recognized.add(
        _PlannedModule(
          moduleId: 'CARGO',
          readKind: AgentVoiceSuperAdminSourceReadKind.status,
          referenceId: _reference(
            request.referenceIds,
            AgentVoiceSuperAdminQueryReferenceKey.cargoBookingId,
          ),
        ),
      );
    }

    if (_containsAny(query, <String>['parcel', 'parcel booking'])) {
      recognized.add(
        _PlannedModule(
          moduleId: 'PARCEL',
          readKind: AgentVoiceSuperAdminSourceReadKind.status,
          referenceId: _reference(
            request.referenceIds,
            AgentVoiceSuperAdminQueryReferenceKey.parcelBookingId,
          ),
        ),
      );
    }

    if (_containsAny(query, <String>['student ride', 'student status'])) {
      recognized.add(
        _PlannedModule(
          moduleId: 'STUDENT_RIDE',
          readKind: AgentVoiceSuperAdminSourceReadKind.status,
          referenceId: _reference(
            request.referenceIds,
            AgentVoiceSuperAdminQueryReferenceKey.studentId,
          ),
        ),
      );
    }

    if (_containsAny(query, <String>[
      'finance',
      'payment',
      'wallet',
      'commission',
    ])) {
      recognized.add(
        const _PlannedModule(
          moduleId: 'FINANCE_OWNER_READ',
          readKind: AgentVoiceSuperAdminSourceReadKind.status,
        ),
      );
    }

    if (_containsAny(query, <String>[
      'application',
      'approval',
      'pending application',
    ])) {
      recognized.add(
        const _PlannedModule(
          moduleId: 'APPLICATIONS_APPROVALS_READ',
          readKind: AgentVoiceSuperAdminSourceReadKind.status,
        ),
      );
    }

    if (_containsAny(query, <String>['complaint', 'support case', 'support'])) {
      recognized.add(
        const _PlannedModule(
          moduleId: 'COMPLAINTS_SUPPORT_READ',
          readKind: AgentVoiceSuperAdminSourceReadKind.status,
        ),
      );
    }

    if (_containsAny(query, <String>['safety', 'sos', 'emergency status'])) {
      recognized.add(
        const _PlannedModule(
          moduleId: 'SAFETY_SOS_OWNER_READ',
          readKind: AgentVoiceSuperAdminSourceReadKind.status,
        ),
      );
    }

    if (_containsAny(query, <String>[
      'ai usage',
      'ai cost',
      'ai kharcha',
      'provider cost',
    ])) {
      recognized.add(
        const _PlannedModule(
          moduleId: 'AI_USAGE_COST_OWNER_READ',
          readKind: AgentVoiceSuperAdminSourceReadKind.status,
        ),
      );
    }

    if (_containsAny(query, <String>[
      'security audit',
      'security warning',
      'audit warning',
    ])) {
      recognized.add(
        const _PlannedModule(
          moduleId: 'SECURITY_AUDIT_OWNER_READ',
          readKind: AgentVoiceSuperAdminSourceReadKind.status,
        ),
      );
    }

    final List<_PlannedModule> unique = _dedupe(recognized);

    if (unique.isEmpty) {
      return _unsupported(
        query: query,
        code: 'QUERY_INTENT_NOT_CONNECTED',
        now: now,
      );
    }

    return _planned(
      intent: unique.length == 1
          ? unique.first.moduleId
          : 'MULTI_MODULE_STATUS',
      query: query,
      now: now,
      outputPreference: request.outputPreference,
      sources: unique,
    );
  }

  AgentVoiceSuperAdminQueryPlan _planned({
    required String intent,
    required String query,
    required DateTime now,
    required AgentVoiceSuperAdminOutputPreference outputPreference,
    required List<_PlannedModule> sources,
  }) {
    final AgentVoiceSuperAdminReportOrchestrationRequest reportRequest =
        AgentVoiceSuperAdminReportOrchestrationRequest(
          reportId: 'voice_super_admin_plan_${now.microsecondsSinceEpoch}',
          sourceRequests: sources
              .map(
                (_PlannedModule source) =>
                    AgentVoiceSuperAdminSourceAcquisitionRequest(
                      moduleId: source.moduleId,
                      readKind: source.readKind,
                      referenceId: source.referenceId,
                    ),
              )
              .toList(growable: false),
          outputPreference: outputPreference,
        );

    final AgentVoiceSuperAdminQueryPlan plan = AgentVoiceSuperAdminQueryPlan(
      status: AgentVoiceSuperAdminQueryPlanStatus.planned,
      code: 'EXPLICIT_VERIFIED_REPORT_REQUEST_PLANNED',
      intent: intent,
      normalizedQuery: query,
      createdAt: now,
      reportRequest: reportRequest,
    );

    plan.validate();
    return plan;
  }

  AgentVoiceSuperAdminQueryPlan _unsupported({
    required String query,
    required String code,
    required DateTime now,
  }) {
    final AgentVoiceSuperAdminQueryPlan plan = AgentVoiceSuperAdminQueryPlan(
      status: AgentVoiceSuperAdminQueryPlanStatus.unsupported,
      code: code,
      intent: 'UNSUPPORTED_READ_ONLY_QUERY',
      normalizedQuery: query,
      createdAt: now,
    );

    plan.validate();
    return plan;
  }

  List<_PlannedModule> _wholeEcosystemSources(Map<String, String> references) {
    return <_PlannedModule>[
      const _PlannedModule(
        moduleId: 'SYSTEM_HEALTH',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
      ),
      _PlannedModule(
        moduleId: 'NORMAL_RIDE',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
        referenceId: _reference(
          references,
          AgentVoiceSuperAdminQueryReferenceKey.rideId,
        ),
      ),
      _PlannedModule(
        moduleId: 'DRIVER',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
        referenceId: _reference(
          references,
          AgentVoiceSuperAdminQueryReferenceKey.driverId,
        ),
      ),
      _PlannedModule(
        moduleId: 'FOOD',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
        referenceId: _reference(
          references,
          AgentVoiceSuperAdminQueryReferenceKey.orderId,
        ),
      ),
      _PlannedModule(
        moduleId: 'RESTAURANT',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
        referenceId: _reference(
          references,
          AgentVoiceSuperAdminQueryReferenceKey.restaurantId,
        ),
      ),
      _PlannedModule(
        moduleId: 'HOTEL',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
        referenceId: _reference(
          references,
          AgentVoiceSuperAdminQueryReferenceKey.hotelBookingId,
        ),
      ),
      _PlannedModule(
        moduleId: 'TOUR',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
        referenceId: _reference(
          references,
          AgentVoiceSuperAdminQueryReferenceKey.tourBookingId,
        ),
      ),
      _PlannedModule(
        moduleId: 'CARGO',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
        referenceId: _reference(
          references,
          AgentVoiceSuperAdminQueryReferenceKey.cargoBookingId,
        ),
      ),
      _PlannedModule(
        moduleId: 'PARCEL',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
        referenceId: _reference(
          references,
          AgentVoiceSuperAdminQueryReferenceKey.parcelBookingId,
        ),
      ),
      _PlannedModule(
        moduleId: 'STUDENT_RIDE',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
        referenceId: _reference(
          references,
          AgentVoiceSuperAdminQueryReferenceKey.studentId,
        ),
      ),
      const _PlannedModule(
        moduleId: 'FINANCE_OWNER_READ',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
      ),
      const _PlannedModule(
        moduleId: 'APPLICATIONS_APPROVALS_READ',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
      ),
      const _PlannedModule(
        moduleId: 'COMPLAINTS_SUPPORT_READ',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
      ),
      const _PlannedModule(
        moduleId: 'SAFETY_SOS_OWNER_READ',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
      ),
      const _PlannedModule(
        moduleId: 'AI_HEALTH_OWNER_READ',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
      ),
      const _PlannedModule(
        moduleId: 'AI_USAGE_COST_OWNER_READ',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
      ),
      const _PlannedModule(
        moduleId: 'SECURITY_AUDIT_OWNER_READ',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
      ),
      const _PlannedModule(
        moduleId: 'OWNER_PERIODIC_SUMMARY',
        readKind: AgentVoiceSuperAdminSourceReadKind.status,
      ),
    ];
  }

  bool _isWholeEcosystemIntent(String query) {
    return _containsAny(query, <String>[
      'whole ecosystem',
      'whole app',
      'all modules',
      'overall status',
      'poore swat ride',
      'poora swat ride',
      'swat ride ka haal',
      'aaj ka haal',
      'overall swat ride',
    ]);
  }

  bool _looksConsequential(String query) {
    return _containsAny(query, <String>[
      'suspend',
      'ban',
      'refund',
      'change price',
      'change pricing',
      'set commission',
      'change commission',
      'transfer',
      'pay ',
      'send payment',
      'approve application',
      'reject application',
      'disable service',
      'enable service',
      'delete',
      'deploy',
      'mark safe',
      'close incident',
    ]);
  }

  bool _wantsDetails(String query) =>
      query.contains('detail') ||
      query.contains('full info') ||
      query.contains('full information');

  bool _containsAny(String query, List<String> needles) =>
      needles.any(query.contains);

  String _reference(Map<String, String> values, String key) =>
      values[key]?.trim() ?? '';

  List<_PlannedModule> _dedupe(List<_PlannedModule> input) {
    final Set<String> seen = <String>{};
    final List<_PlannedModule> output = <_PlannedModule>[];

    for (final _PlannedModule item in input) {
      if (seen.add(item.moduleId)) {
        output.add(item);
      }
    }

    return output;
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\-\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool get deterministicOnly => true;
  bool get parsesIdentityFromVoice => false;
  bool get parsesReferenceIdsFromVoice => false;
  bool get hiddenBroadQueryAllowed => false;
  bool get executesConnector => false;
  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get writesBusinessData => false;
  bool get mutatesSafety => false;
  bool get callsProvider => false;
  bool get usesSpeechToTextProvider => false;
  bool get usesTextToSpeechProvider => false;
  bool get deploys => false;
}

class _PlannedModule {
  const _PlannedModule({
    required this.moduleId,
    required this.readKind,
    this.referenceId = '',
  });

  final String moduleId;
  final String readKind;
  final String referenceId;
}
