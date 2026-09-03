import '../constants/agent_action_ids.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_owner_whatsapp_foundation.dart';
import '../models/agent_owner_whatsapp_verified_report.dart';
import '../models/agent_role.dart';
import 'agent_owner_whatsapp_authorization_router.dart';
import 'agent_owner_whatsapp_verified_report_source.dart';

class AgentOwnerWhatsAppVerifiedReportBroker {
  final AgentOwnerWhatsAppAuthorizationRouter authorizationRouter;
  final AgentOwnerWhatsAppVerifiedReportAssembler assembler;

  const AgentOwnerWhatsAppVerifiedReportBroker({
    required this.authorizationRouter,
    required this.assembler,
  });

  Future<AgentOwnerWhatsAppVerifiedReport> buildVerifiedReport({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentOwnerWhatsAppControlSettings channelSettings,
    required AgentOwnerWhatsAppSessionBinding session,
    required AgentOwnerWhatsAppAuthorizationRequest authorizationRequest,
    required AgentOwnerWhatsAppVerifiedReportRequest reportRequest,
    required DateTime now,
  }) async {
    reportRequest.validate();

    if (role.roleId != AgentOwnerWhatsAppFoundation.roleId ||
        role.module != 'owner_whatsapp') {
      return _denied(
        reportRequest,
        now,
        'Only the isolated Owner WhatsApp role may request Owner reports.',
      );
    }

    if (authorizationRequest.actionId !=
        AgentActionId.readOwnerWhatsAppVerifiedReport) {
      return _denied(
        reportRequest,
        now,
        'Owner report broker accepts only the verified report read action.',
      );
    }

    if (authorizationRequest.controlArea !=
        AgentOwnerWhatsAppControlArea.report) {
      return _denied(
        reportRequest,
        now,
        'Owner report broker requires the report control area.',
      );
    }

    if (authorizationRequest.commandPolicy.commandClass !=
        AgentOwnerWhatsAppCommandClass.readReport) {
      return _denied(
        reportRequest,
        now,
        'Owner report broker requires a read-report command policy.',
      );
    }

    if (authorizationRequest.actorId.trim() != reportRequest.actorId) {
      return _denied(
        reportRequest,
        now,
        'Owner report actor does not match the authorized session actor.',
      );
    }

    final AgentOwnerWhatsAppAuthorizationResult authorization =
        await authorizationRouter.evaluate(
          settings: settings,
          role: role,
          channelSettings: channelSettings,
          session: session,
          request: authorizationRequest,
          now: now,
        );

    if (authorization.isDenied) {
      return _denied(reportRequest, now, authorization.reason);
    }

    if (authorization.decision.needsApproval) {
      return _denied(
        reportRequest,
        now,
        'Pure verified Owner report read unexpectedly requires approval; fail closed.',
      );
    }

    return assembler.build(request: reportRequest, now: now);
  }

  AgentOwnerWhatsAppVerifiedReport _denied(
    AgentOwnerWhatsAppVerifiedReportRequest request,
    DateTime now,
    String reason,
  ) {
    final List<AgentOwnerWhatsAppVerifiedReportSectionResult> sections = request
        .requestedSectionIds
        .map(
          (String sectionId) =>
              AgentOwnerWhatsAppVerifiedReportSectionResult.unavailable(
                sectionId: sectionId,
                sourceId: 'denied.owner_whatsapp_authorization',
                warning: reason,
                generatedAt: now.toUtc(),
              ),
        )
        .toList(growable: false);

    return AgentOwnerWhatsAppVerifiedReport(
      reportId: request.reportId,
      status: AgentOwnerWhatsAppVerifiedReportStatus.denied,
      sections: sections,
      warnings: <String>[reason],
      generatedAt: now.toUtc(),
    );
  }
}
