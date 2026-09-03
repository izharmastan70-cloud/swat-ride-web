import '../models/agent_owner_whatsapp_verified_report.dart';
import 'agent_owner_whatsapp_authorization_router.dart';
import 'agent_owner_whatsapp_verified_builtin_sources.dart';
import 'agent_owner_whatsapp_verified_report_broker.dart';
import 'agent_owner_whatsapp_verified_report_source.dart';

/// Phase 46 Owner WhatsApp verified-report production composition.
///
/// This class only wires already-audited read-only sources into the existing
/// authorization broker. It does not create a new authority path and does not
/// query business collections directly.
///
/// Connected in Step 8D:
/// - current pending approvals
/// - current AI Agent status
/// - current security audit summary
/// - current open crash snapshot
///
/// Every other Owner report section remains explicitly unsupported until a
/// real structured source is separately audited and attached.
class AgentOwnerWhatsAppVerifiedReportComposition {
  AgentOwnerWhatsAppVerifiedReportComposition._();

  static Set<String> get connectedSectionIds =>
      AgentOwnerWhatsAppVerifiedBuiltInSources.connectedSectionIds;

  static Set<String> get intentionallyUnavailableSectionIds =>
      Set<String>.unmodifiable(
        AgentOwnerWhatsAppReportSectionId.values.difference(
          connectedSectionIds,
        ),
      );

  static List<AgentOwnerWhatsAppVerifiedReportSource> productionSources() {
    return AgentOwnerWhatsAppVerifiedBuiltInSources.production();
  }

  static AgentOwnerWhatsAppVerifiedReportAssembler productionAssembler() {
    return AgentOwnerWhatsAppVerifiedReportAssembler(
      sources: productionSources(),
    );
  }

  static AgentOwnerWhatsAppVerifiedReportBroker productionBroker({
    required AgentOwnerWhatsAppAuthorizationRouter authorizationRouter,
  }) {
    return AgentOwnerWhatsAppVerifiedReportBroker(
      authorizationRouter: authorizationRouter,
      assembler: productionAssembler(),
    );
  }

  static bool isSectionConnected(String sectionId) =>
      connectedSectionIds.contains(sectionId);

  static bool isSectionIntentionallyUnavailable(String sectionId) =>
      intentionallyUnavailableSectionIds.contains(sectionId);
}
