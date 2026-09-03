import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_owner_whatsapp_verified_report.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_whatsapp_verified_report_composition.dart';

void main() {
  group('Phase 46 Step 8D verified report production composition', () {
    test('exactly four audited sections are production-connected', () {
      expect(
        AgentOwnerWhatsAppVerifiedReportComposition.connectedSectionIds,
        const <String>{
          AgentOwnerWhatsAppReportSectionId.approvals,
          AgentOwnerWhatsAppReportSectionId.agentStatus,
          AgentOwnerWhatsAppReportSectionId.security,
          AgentOwnerWhatsAppReportSectionId.crashes,
        },
      );
    });

    test('business aggregate sections remain intentionally unavailable', () {
      for (final String sectionId in <String>[
        AgentOwnerWhatsAppReportSectionId.ride,
        AgentOwnerWhatsAppReportSectionId.driver,
        AgentOwnerWhatsAppReportSectionId.food,
        AgentOwnerWhatsAppReportSectionId.hotel,
        AgentOwnerWhatsAppReportSectionId.tour,
        AgentOwnerWhatsAppReportSectionId.cargo,
        AgentOwnerWhatsAppReportSectionId.student,
        AgentOwnerWhatsAppReportSectionId.revenue,
        AgentOwnerWhatsAppReportSectionId.complaints,
        AgentOwnerWhatsAppReportSectionId.refundsDisputes,
        AgentOwnerWhatsAppReportSectionId.tasks,
        AgentOwnerWhatsAppReportSectionId.agentActivity,
        AgentOwnerWhatsAppReportSectionId.developmentStatus,
        AgentOwnerWhatsAppReportSectionId.recommendations,
      ]) {
        expect(
          AgentOwnerWhatsAppVerifiedReportComposition.isSectionIntentionallyUnavailable(
            sectionId,
          ),
          isTrue,
          reason: sectionId,
        );
      }
    });

    test('connected and unavailable section sets never overlap', () {
      final Set<String> overlap = AgentOwnerWhatsAppVerifiedReportComposition
          .connectedSectionIds
          .intersection(
            AgentOwnerWhatsAppVerifiedReportComposition
                .intentionallyUnavailableSectionIds,
          );

      expect(overlap, isEmpty);
    });

    test('all known report sections are classified exactly once', () {
      final Set<String> classified = <String>{
        ...AgentOwnerWhatsAppVerifiedReportComposition.connectedSectionIds,
        ...AgentOwnerWhatsAppVerifiedReportComposition
            .intentionallyUnavailableSectionIds,
      };

      expect(classified, AgentOwnerWhatsAppReportSectionId.values);
    });

    test('unknown section is neither connected nor intentionally available', () {
      expect(
        AgentOwnerWhatsAppVerifiedReportComposition.isSectionConnected(
          'unknown_section',
        ),
        isFalse,
      );

      expect(
        AgentOwnerWhatsAppVerifiedReportComposition.isSectionIntentionallyUnavailable(
          'unknown_section',
        ),
        isFalse,
      );
    });
  });
}
