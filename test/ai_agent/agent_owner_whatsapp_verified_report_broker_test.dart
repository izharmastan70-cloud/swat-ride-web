import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_owner_whatsapp_verified_report.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_whatsapp_verified_report_source.dart';

class _VerifiedSource implements AgentOwnerWhatsAppVerifiedReportSource {
  _VerifiedSource({
    required this.sourceId,
    required this.supportedSectionIds,
    required this.payload,
  });

  @override
  final String sourceId;

  @override
  final Set<String> supportedSectionIds;

  final Map<String, dynamic> payload;

  @override
  Future<AgentOwnerWhatsAppVerifiedReportSectionResult> fetchVerifiedSection({
    required String sectionId,
    required AgentOwnerWhatsAppVerifiedReportRequest request,
  }) async {
    return AgentOwnerWhatsAppVerifiedReportSectionResult.verified(
      sectionId: sectionId,
      sourceId: sourceId,
      data: payload,
      generatedAt: DateTime.utc(2026, 8, 18),
    );
  }
}

class _UnavailableSource implements AgentOwnerWhatsAppVerifiedReportSource {
  const _UnavailableSource();

  @override
  String get sourceId => 'source.hotel.unavailable';

  @override
  Set<String> get supportedSectionIds => const <String>{
    AgentOwnerWhatsAppReportSectionId.hotel,
  };

  @override
  Future<AgentOwnerWhatsAppVerifiedReportSectionResult> fetchVerifiedSection({
    required String sectionId,
    required AgentOwnerWhatsAppVerifiedReportRequest request,
  }) async {
    return AgentOwnerWhatsAppVerifiedReportSectionResult.unavailable(
      sectionId: sectionId,
      sourceId: sourceId,
      warning: 'Hotel aggregate source is not connected.',
      generatedAt: DateTime.utc(2026, 8, 18),
    );
  }
}

AgentOwnerWhatsAppVerifiedReportRequest _request(Set<String> sections) {
  return AgentOwnerWhatsAppVerifiedReportRequest(
    reportId: 'owner_report_1',
    actorId: 'owner_1',
    fromInclusive: DateTime.utc(2026, 8, 17),
    toExclusive: DateTime.utc(2026, 8, 18),
    requestedSectionIds: sections,
  );
}

void main() {
  group('Phase 46 verified Owner report assembly', () {
    test('accepts structured backend-verified section', () async {
      final assembler = AgentOwnerWhatsAppVerifiedReportAssembler(
        sources: <AgentOwnerWhatsAppVerifiedReportSource>[
          _VerifiedSource(
            sourceId: 'source.ride.verified',
            supportedSectionIds: const <String>{
              AgentOwnerWhatsAppReportSectionId.ride,
            },
            payload: const <String, dynamic>{
              'completedRideCount': 12,
              'cancelledRideCount': 2,
            },
          ),
        ],
      );

      final report = await assembler.build(
        request: _request(const <String>{
          AgentOwnerWhatsAppReportSectionId.ride,
        }),
        now: DateTime.utc(2026, 8, 18),
      );

      expect(report.status, AgentOwnerWhatsAppVerifiedReportStatus.ready);
      expect(report.verifiedSectionCount, 1);
      expect(report.unavailableSectionCount, 0);
      expect(report.containsGuessedBusinessMetrics, isFalse);
    });

    test(
      'missing source becomes unavailable instead of guessed zero',
      () async {
        final assembler = AgentOwnerWhatsAppVerifiedReportAssembler(
          sources: const <AgentOwnerWhatsAppVerifiedReportSource>[],
        );

        final report = await assembler.build(
          request: _request(const <String>{
            AgentOwnerWhatsAppReportSectionId.revenue,
          }),
          now: DateTime.utc(2026, 8, 18),
        );

        expect(
          report.status,
          AgentOwnerWhatsAppVerifiedReportStatus.unavailable,
        );
        expect(report.verifiedSectionCount, 0);
        expect(report.sections.single.data, isEmpty);
        expect(report.sections.single.warning, contains('No verified'));
      },
    );

    test('explicit unavailable source remains unavailable', () async {
      final assembler = AgentOwnerWhatsAppVerifiedReportAssembler(
        sources: const <AgentOwnerWhatsAppVerifiedReportSource>[
          _UnavailableSource(),
        ],
      );

      final report = await assembler.build(
        request: _request(const <String>{
          AgentOwnerWhatsAppReportSectionId.hotel,
        }),
        now: DateTime.utc(2026, 8, 18),
      );

      expect(report.status, AgentOwnerWhatsAppVerifiedReportStatus.unavailable);
      expect(report.sections.single.available, isFalse);
      expect(report.sections.single.data, isEmpty);
    });

    test('mixed verified/unavailable sections produce PARTIAL', () async {
      final assembler = AgentOwnerWhatsAppVerifiedReportAssembler(
        sources: <AgentOwnerWhatsAppVerifiedReportSource>[
          _VerifiedSource(
            sourceId: 'source.food.verified',
            supportedSectionIds: const <String>{
              AgentOwnerWhatsAppReportSectionId.food,
            },
            payload: const <String, dynamic>{'orderCount': 5},
          ),
          const _UnavailableSource(),
        ],
      );

      final report = await assembler.build(
        request: _request(const <String>{
          AgentOwnerWhatsAppReportSectionId.food,
          AgentOwnerWhatsAppReportSectionId.hotel,
        }),
        now: DateTime.utc(2026, 8, 18),
      );

      expect(report.status, AgentOwnerWhatsAppVerifiedReportStatus.partial);
      expect(report.verifiedSectionCount, 1);
      expect(report.unavailableSectionCount, 1);
    });

    test(
      'secret-like source payload is rejected and marked unavailable',
      () async {
        final assembler = AgentOwnerWhatsAppVerifiedReportAssembler(
          sources: <AgentOwnerWhatsAppVerifiedReportSource>[
            _VerifiedSource(
              sourceId: 'source.security.bad',
              supportedSectionIds: const <String>{
                AgentOwnerWhatsAppReportSectionId.security,
              },
              payload: const <String, dynamic>{'apiToken': 'must-not-surface'},
            ),
          ],
        );

        final report = await assembler.build(
          request: _request(const <String>{
            AgentOwnerWhatsAppReportSectionId.security,
          }),
          now: DateTime.utc(2026, 8, 18),
        );

        expect(
          report.status,
          AgentOwnerWhatsAppVerifiedReportStatus.unavailable,
        );
        expect(report.sections.single.data, isEmpty);
        expect(
          report.sections.single.warning,
          contains('No value was guessed'),
        );
      },
    );

    test('duplicate section sources fail closed', () {
      expect(
        () => AgentOwnerWhatsAppVerifiedReportAssembler(
          sources: <AgentOwnerWhatsAppVerifiedReportSource>[
            _VerifiedSource(
              sourceId: 'source.ride.1',
              supportedSectionIds: const <String>{
                AgentOwnerWhatsAppReportSectionId.ride,
              },
              payload: const <String, dynamic>{'count': 1},
            ),
            _VerifiedSource(
              sourceId: 'source.ride.2',
              supportedSectionIds: const <String>{
                AgentOwnerWhatsAppReportSectionId.ride,
              },
              payload: const <String, dynamic>{'count': 2},
            ),
          ],
        ),
        throwsA(isA<AgentOwnerWhatsAppVerifiedReportException>()),
      );
    });

    test(
      'report object never grants execution/send/provider/deploy authority',
      () async {
        final assembler = AgentOwnerWhatsAppVerifiedReportAssembler(
          sources: const <AgentOwnerWhatsAppVerifiedReportSource>[],
        );

        final report = await assembler.build(
          request: _request(const <String>{
            AgentOwnerWhatsAppReportSectionId.approvals,
          }),
          now: DateTime.utc(2026, 8, 18),
        );

        expect(report.mayExecuteBusinessOrAdminWrite, isFalse);
        expect(report.maySendWhatsApp, isFalse);
        expect(report.mayCallProvider, isFalse);
        expect(report.mayDeploy, isFalse);
      },
    );
  });
}
