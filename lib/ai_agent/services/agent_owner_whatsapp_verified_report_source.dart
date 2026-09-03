import '../models/agent_owner_whatsapp_verified_report.dart';

abstract class AgentOwnerWhatsAppVerifiedReportSource {
  String get sourceId;
  Set<String> get supportedSectionIds;

  Future<AgentOwnerWhatsAppVerifiedReportSectionResult> fetchVerifiedSection({
    required String sectionId,
    required AgentOwnerWhatsAppVerifiedReportRequest request,
  });
}

/// Pure report assembly boundary.
///
/// Sources must return structured verified data. A missing, failed, malformed
/// or privacy-unsafe source is represented as UNAVAILABLE; it is never replaced
/// with guessed zeroes, invented counts, or AI-generated business facts.
class AgentOwnerWhatsAppVerifiedReportAssembler {
  AgentOwnerWhatsAppVerifiedReportAssembler({
    required Iterable<AgentOwnerWhatsAppVerifiedReportSource> sources,
  }) : _sources = List<AgentOwnerWhatsAppVerifiedReportSource>.unmodifiable(
         sources,
       ) {
    _validateUniqueSources();
  }

  final List<AgentOwnerWhatsAppVerifiedReportSource> _sources;

  static const Set<String> forbiddenPayloadKeyFragments = <String>{
    'password',
    'passcode',
    'otp',
    'token',
    'secret',
    'apikey',
    'api_key',
    'authorization',
    'cookie',
    'cvv',
    'cvc',
    'cardnumber',
    'card_number',
    'privatekey',
    'private_key',
  };

  Future<AgentOwnerWhatsAppVerifiedReport> build({
    required AgentOwnerWhatsAppVerifiedReportRequest request,
    required DateTime now,
  }) async {
    request.validate();

    final List<AgentOwnerWhatsAppVerifiedReportSectionResult> sections =
        <AgentOwnerWhatsAppVerifiedReportSectionResult>[];
    final List<String> warnings = <String>[];

    for (final String sectionId in request.requestedSectionIds) {
      final AgentOwnerWhatsAppVerifiedReportSource? source = _sourceFor(
        sectionId,
      );

      if (source == null) {
        final result = AgentOwnerWhatsAppVerifiedReportSectionResult.unavailable(
          sectionId: sectionId,
          sourceId: 'unavailable.no_verified_source',
          warning:
              'No verified structured source is connected for this Owner report section.',
          generatedAt: now.toUtc(),
        );
        sections.add(result);
        warnings.add('$sectionId: ${result.warning}');
        continue;
      }

      try {
        final AgentOwnerWhatsAppVerifiedReportSectionResult result =
            await source.fetchVerifiedSection(
              sectionId: sectionId,
              request: request,
            );

        result.validate();

        if (result.sectionId != sectionId ||
            result.sourceId != source.sourceId) {
          throw const AgentOwnerWhatsAppVerifiedReportException(
            'Verified report source returned mismatched source/section identity.',
          );
        }

        if (result.available) {
          _rejectSecretLikePayload(result.data);
        }

        sections.add(result);

        if (!result.available) {
          warnings.add('$sectionId: ${result.warning}');
        }
      } catch (_) {
        final result = AgentOwnerWhatsAppVerifiedReportSectionResult.unavailable(
          sectionId: sectionId,
          sourceId: source.sourceId,
          warning:
              'Verified source could not safely provide this section. No value was guessed.',
          generatedAt: now.toUtc(),
        );
        sections.add(result);
        warnings.add('$sectionId: ${result.warning}');
      }
    }

    final int availableCount = sections
        .where((section) => section.available)
        .length;

    final String status;
    if (availableCount == sections.length) {
      status = AgentOwnerWhatsAppVerifiedReportStatus.ready;
    } else if (availableCount == 0) {
      status = AgentOwnerWhatsAppVerifiedReportStatus.unavailable;
    } else {
      status = AgentOwnerWhatsAppVerifiedReportStatus.partial;
    }

    return AgentOwnerWhatsAppVerifiedReport(
      reportId: request.reportId,
      status: status,
      sections: sections,
      warnings: warnings,
      generatedAt: now.toUtc(),
    );
  }

  AgentOwnerWhatsAppVerifiedReportSource? _sourceFor(String sectionId) {
    for (final AgentOwnerWhatsAppVerifiedReportSource source in _sources) {
      if (source.supportedSectionIds.contains(sectionId)) {
        return source;
      }
    }
    return null;
  }

  void _validateUniqueSources() {
    final Set<String> sourceIds = <String>{};
    final Set<String> sectionIds = <String>{};

    for (final AgentOwnerWhatsAppVerifiedReportSource source in _sources) {
      final String cleanSourceId = source.sourceId.trim();

      if (cleanSourceId.isEmpty || !sourceIds.add(cleanSourceId)) {
        throw const AgentOwnerWhatsAppVerifiedReportException(
          'Verified Owner report source IDs must be non-empty and unique.',
        );
      }

      for (final String sectionId in source.supportedSectionIds) {
        if (!AgentOwnerWhatsAppReportSectionId.values.contains(sectionId)) {
          throw AgentOwnerWhatsAppVerifiedReportException(
            'Verified Owner report source declares unknown section: $sectionId',
          );
        }

        if (!sectionIds.add(sectionId)) {
          throw AgentOwnerWhatsAppVerifiedReportException(
            'Multiple verified sources claim the same Owner report section: $sectionId',
          );
        }
      }
    }
  }

  static void _rejectSecretLikePayload(Map<String, dynamic> payload) {
    for (final MapEntry<String, dynamic> entry in payload.entries) {
      final String normalized = entry.key.trim().toLowerCase();

      for (final String fragment in forbiddenPayloadKeyFragments) {
        if (normalized.contains(fragment)) {
          throw AgentOwnerWhatsAppVerifiedReportException(
            'Secret/payment credential-like report key is forbidden: ${entry.key}',
          );
        }
      }

      final dynamic value = entry.value;

      if (value is Map) {
        final Map<String, dynamic> nested = <String, dynamic>{};
        for (final dynamic key in value.keys) {
          if (key is! String) {
            throw const AgentOwnerWhatsAppVerifiedReportException(
              'Verified Owner report map keys must be strings.',
            );
          }
          nested[key] = value[key];
        }
        _rejectSecretLikePayload(nested);
      } else if (value is Iterable) {
        for (final dynamic item in value) {
          if (item is Map) {
            final Map<String, dynamic> nested = <String, dynamic>{};
            for (final dynamic key in item.keys) {
              if (key is! String) {
                throw const AgentOwnerWhatsAppVerifiedReportException(
                  'Verified Owner report list map keys must be strings.',
                );
              }
              nested[key] = item[key];
            }
            _rejectSecretLikePayload(nested);
          }
        }
      }
    }
  }
}
