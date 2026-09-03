import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_email_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_email_draft.dart';
import 'package:swat_ride/ai_agent/services/agent_email_draft_binding_service.dart';

void main() {
  const AgentEmailDraftBindingService service = AgentEmailDraftBindingService();

  AgentEmailDraft draft({
    String body = 'Your verified booking update is ready.',
  }) {
    return AgentEmailDraft(
      draftId: 'draft_sha256_migration',
      purpose: AgentEmailPurpose.supportReply,
      senderIdentityId: 'primary_official_sender',
      to: const <AgentEmailAddress>[
        AgentEmailAddress(address: 'customer@example.com'),
      ],
      subject: 'Booking update',
      bodyText: body,
      attachments: const <AgentEmailAttachmentRef>[],
      status: AgentEmailDraftStatus.approvalRequired,
      createdAt: DateTime.utc(2026, 8, 17, 1),
    );
  }

  dynamic canonicalize(dynamic value) {
    if (value == null || value is String || value is bool || value is num) {
      return value;
    }

    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }

    if (value is List) {
      return value.map<dynamic>(canonicalize).toList(growable: false);
    }

    if (value is Map) {
      final List<String> keys =
          value.keys
              .map((dynamic key) => key.toString())
              .toList(growable: false)
            ..sort();

      final Map<String, dynamic> sorted = <String, dynamic>{};

      for (final String key in keys) {
        sorted[key] = canonicalize(value[key]);
      }

      return sorted;
    }

    throw StateError(
      'Unsupported migration-test canonical value: ${value.runtimeType}.',
    );
  }

  String independentExpectedFingerprint(AgentEmailDraft value) {
    final String canonicalJson = jsonEncode(canonicalize(value.toMap()));

    return base64Url
        .encode(sha256.convert(utf8.encode(canonicalJson)).bytes)
        .replaceAll('=', '');
  }

  test('binding algorithm is canonical SHA-256 base64url V2', () {
    expect(
      AgentEmailDraftBindingService.algorithm,
      'CANONICAL_JSON_SHA256_BASE64URL_V2',
    );
  });

  test('binding fingerprint equals independent SHA-256 canonical digest', () {
    final AgentEmailDraft value = draft();

    final AgentEmailDraftBinding binding = service.bind(value);

    expect(binding.fingerprint, independentExpectedFingerprint(value));

    expect(binding.fingerprint.length, 43);

    expect(
      RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(binding.fingerprint),
      isTrue,
    );
  });

  test('legacy reversible Base64 algorithm is rejected', () {
    final AgentEmailDraftBinding legacy = AgentEmailDraftBinding(
      algorithm: 'CANONICAL_JSON_BASE64URL_V1',
      fingerprint: 'legacy-reversible-fingerprint',
      draftId: 'draft_sha256_migration',
    );

    expect(legacy.validate, throwsA(isA<AgentEmailDraftBindingException>()));
  });

  test('same canonical draft is deterministic and mutation changes digest', () {
    final AgentEmailDraft original = draft();

    final AgentEmailDraft changed = draft(body: 'Changed body.');

    final AgentEmailDraftBinding first = service.bind(original);

    final AgentEmailDraftBinding second = service.bind(original);

    final AgentEmailDraftBinding changedBinding = service.bind(changed);

    expect(first.fingerprint, second.fingerprint);

    expect(changedBinding.fingerprint, isNot(first.fingerprint));
  });

  test('SHA-256 migration grants zero provider/runtime authority', () {
    expect(service.providerExecutionAllowed, isFalse);
    expect(service.smtpExecutionAllowed, isFalse);
    expect(service.firestoreReadAllowed, isFalse);
    expect(service.firestoreWriteAllowed, isFalse);
    expect(service.runtimeActionAllowed, isFalse);
    expect(service.approvalConsumptionAllowed, isFalse);
  });
}
