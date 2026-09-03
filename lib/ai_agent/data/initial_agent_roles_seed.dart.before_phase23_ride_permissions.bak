import '../constants/agent_action_ids.dart';
import '../constants/agent_enums.dart';
import '../models/agent_role.dart';
import '../services/agent_role_service.dart';

// =========================================================
// INITIAL AGENT ROLES — SEED DATA
// =========================================================
//
// Development/bootstrap helper only.
// Phase 2 Permission Engine will be DEFAULT-DENY.

List<AgentRole> buildInitialAgentRoles() {
  final DateTime now = DateTime.now();

  AgentRole role({
    required String roleId,
    required String name,
    required String description,
    required String module,
    required String mode,
    String aiClass = AiClass.freeAi,
    String privacyLevel = PrivacyLevel.internal,
    bool enabled = true,
    List<String> allowedActions = const <String>[],
    List<String> approvalRequiredActions = const <String>[],
    List<String> forbiddenActions = const <String>[],
  }) {
    return AgentRole(
      roleId: roleId,
      name: name,
      description: description,
      module: module,
      enabled: enabled,
      mode: mode,
      allowedActions: allowedActions,
      approvalRequiredActions: approvalRequiredActions,
      forbiddenActions: forbiddenActions,
      aiClass: aiClass,
      privacyLevel: privacyLevel,
      createdAt: now,
    );
  }

  return <AgentRole>[
    role(
      roleId: 'ride_agent',
      name: 'Ride Agent',
      description: 'Monitors ride status, cancellations and driver delays.',
      module: 'ride',
      mode: AgentMode.monitorOnly,
    ),
    role(
      roleId: 'driver_agent',
      name: 'Driver Agent',
      description: 'Monitors driver applications, activity and earnings.',
      module: 'driver',
      mode: AgentMode.monitorOnly,
    ),
    role(
      roleId: 'food_agent',
      name: 'Food Agent',
      description: 'Monitors food orders and delivery status.',
      module: 'food',
      mode: AgentMode.monitorOnly,
    ),
    role(
      roleId: 'restaurant_agent',
      name: 'Restaurant Agent',
      description: 'Monitors restaurant availability and performance.',
      module: 'food',
      mode: AgentMode.monitorOnly,
    ),
    role(
      roleId: 'hotel_agent',
      name: 'Hotel Agent',
      description: 'Monitors hotel bookings and occupancy.',
      module: 'hotel',
      mode: AgentMode.monitorOnly,
    ),
    role(
      roleId: 'tour_agent',
      name: 'Tour Agent',
      description: 'Monitors tour bookings and availability.',
      module: 'tour',
      mode: AgentMode.monitorOnly,
    ),
    role(
      roleId: 'rewards_agent',
      name: 'Rewards Agent',
      description: 'Monitors points, coupons and cashback usage.',
      module: 'rewards',
      mode: AgentMode.monitorOnly,
    ),
    role(
      roleId: 'feedback_agent',
      name: 'Feedback Agent',
      description: 'Classifies, summarizes and drafts feedback/review replies.',
      module: 'feedback',
      mode: AgentMode.suggestOnly,
      allowedActions: const <String>[
        AgentActionId.readFeedback,
        AgentActionId.classifyFeedback,
        AgentActionId.draftFeedbackReply,
      ],
      approvalRequiredActions: const <String>[
        AgentActionId.sendFeedbackReply,
      ],
    ),
    role(
      roleId: 'support_agent',
      name: 'Support Agent',
      description: 'Drafts routine support/FAQ responses; escalates sensitive issues.',
      module: 'support',
      mode: AgentMode.suggestOnly,
      allowedActions: const <String>[
        AgentActionId.readSupportCase,
        AgentActionId.draftSupportReply,
      ],
      approvalRequiredActions: const <String>[
        AgentActionId.sendSupportReply,
      ],
    ),
    role(
      roleId: 'reports_agent',
      name: 'Reports Agent',
      description: 'Builds read-only owner/system reports from connected data.',
      module: 'reports',
      mode: AgentMode.monitorOnly,
      allowedActions: const <String>[
        AgentActionId.readSystemHealth,
        AgentActionId.readDailySummary,
      ],
    ),
    role(
      roleId: 'safety_agent',
      name: 'Safety Agent',
      description: 'Monitors SOS/emergency alerts. Alert + assist only.',
      module: 'safety',
      mode: AgentMode.monitorOnly,
      privacyLevel: PrivacyLevel.private,
    ),
    role(
      roleId: 'call_agent',
      name: 'Call Agent',
      description: 'Handles inbound call conversations for booking/support.',
      module: 'call',
      mode: AgentMode.monitorOnly,
      privacyLevel: PrivacyLevel.private,
    ),
    role(
      roleId: AgentRole.crashAgentRoleId,
      name: 'Crash Agent',
      description: 'Monitors crashes/errors and prepares Code Agent handoff. '
          'Never calls paid AI directly.',
      module: 'crash',
      mode: AgentMode.monitorOnly,
      aiClass: AiClass.freeAi,
      privacyLevel: PrivacyLevel.private,
      allowedActions: const <String>[
        AgentActionId.readCrashLog,
        AgentActionId.classifyCrash,
      ],
      approvalRequiredActions: const <String>[
        AgentActionId.handoffCrashToCodeAgent,
      ],
    ),
    role(
      roleId: AgentRole.codeAgentRoleId,
      name: 'Code Agent',
      description: 'Diagnoses and prepares fixes for code/technical issues.',
      module: 'code',
      mode: AgentMode.askFirst,
      aiClass: AiClass.paidCodeAi,
      privacyLevel: PrivacyLevel.private,
      allowedActions: const <String>[
        AgentActionId.readCode,
        AgentActionId.analyzeCodeError,
        AgentActionId.prepareCodeFix,
        AgentActionId.modifyCode,
        AgentActionId.deployCode,
      ],
      approvalRequiredActions: const <String>[
        AgentActionId.analyzeCodeError,
        AgentActionId.prepareCodeFix,
        AgentActionId.modifyCode,
        AgentActionId.deployCode,
      ],
    ),
    role(
      roleId: 'finance_agent',
      name: 'Finance Agent',
      description: 'Monitors/reconciles finances and drafts money actions; '
          'never executes money on its own.',
      module: 'finance',
      mode: AgentMode.monitorOnly,
      privacyLevel: PrivacyLevel.private,
      allowedActions: const <String>[
        AgentActionId.readFinanceSummary,
        AgentActionId.prepareSettlement,
        AgentActionId.executeRefund,
        AgentActionId.approveWithdrawal,
      ],
      approvalRequiredActions: const <String>[
        AgentActionId.prepareSettlement,
        AgentActionId.executeRefund,
        AgentActionId.approveWithdrawal,
      ],
    ),
    role(
      roleId: 'cargo_agent',
      name: 'Cargo Agent',
      description: 'Cargo foundation is prepared but remains OFF until the '
          'real Cargo module is complete and audited.',
      module: 'cargo',
      mode: AgentMode.off,
      enabled: false,
      allowedActions: const <String>[
        AgentActionId.readCargoBooking,
        AgentActionId.readCargoStatus,
        AgentActionId.cancelCargoBooking,
      ],
      approvalRequiredActions: const <String>[
        AgentActionId.cancelCargoBooking,
      ],
    ),
    role(
      roleId: 'student_agent',
      name: 'Student Agent',
      description: 'Reserved for Student Ride. Stays OFF until the module '
          'and its safety testing are complete.',
      module: 'student',
      mode: AgentMode.off,
      enabled: false,
      privacyLevel: PrivacyLevel.private,
    ),
  ];
}

Future<void> seedInitialAgentRoles(AgentRoleService service) async {
  for (final AgentRole role in buildInitialAgentRoles()) {
    await service.createRoleIfNotExists(role);
  }
}
