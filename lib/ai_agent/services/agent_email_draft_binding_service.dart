import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/agent_email_draft.dart';

class AgentEmailDraftBindingService {
  const AgentEmailDraftBindingService();

  static const String algorithm = 'CANONICAL_JSON_SHA256_BASE64URL_V2';

  bool get providerExecutionAllowed => false;
  bool get smtpExecutionAllowed => false;
  bool get firestoreReadAllowed => false;
  bool get firestoreWriteAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get mailboxReadAllowed => false;
  bool get mailboxWriteAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;

  AgentEmailDraftBinding bind(AgentEmailDraft draft) {
    draft.validate();

    final String canonicalJson = _canonicalJson(draft.toMap());
    final String fingerprint = base64Url
        .encode(sha256.convert(utf8.encode(canonicalJson)).bytes)
        .replaceAll('=', '');

    final AgentEmailDraftBinding binding = AgentEmailDraftBinding(
      algorithm: algorithm,
      fingerprint: fingerprint,
      draftId: draft.draftId.trim(),
    );

    binding.validate();
    return binding;
  }

  bool matches({
    required AgentEmailDraft draft,
    required AgentEmailDraftBinding binding,
  }) {
    binding.validate();
    final AgentEmailDraftBinding current = bind(draft);

    return current.algorithm == binding.algorithm &&
        current.draftId == binding.draftId &&
        current.fingerprint == binding.fingerprint;
  }

  String _canonicalJson(Map<String, dynamic> value) {
    return jsonEncode(_canonicalize(value));
  }

  dynamic _canonicalize(dynamic value) {
    if (value == null || value is String || value is bool || value is num) {
      return value;
    }

    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }

    if (value is List) {
      return value.map<dynamic>(_canonicalize).toList(growable: false);
    }

    if (value is Map) {
      final List<String> keys =
          value.keys
              .map((dynamic key) => key.toString())
              .toList(growable: false)
            ..sort();

      final Map<String, dynamic> sorted = <String, dynamic>{};

      for (final String key in keys) {
        sorted[key] = _canonicalize(value[key]);
      }

      return sorted;
    }

    throw AgentEmailDraftBindingException(
      'Unsupported value type in canonical email draft binding: ${value.runtimeType}.',
    );
  }
}

class AgentEmailDraftBinding {
  const AgentEmailDraftBinding({
    required this.algorithm,
    required this.fingerprint,
    required this.draftId,
  });

  final String algorithm;
  final String fingerprint;
  final String draftId;

  bool get exactDraftMatchRequired => true;
  bool get maySend => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayCallProvider => false;
  bool get mayOpenNetworkConnection => false;
  bool get mayReadMailbox => false;
  bool get mayWriteMailbox => false;
  bool get mayDeploy => false;

  void validate() {
    if (algorithm != AgentEmailDraftBindingService.algorithm) {
      throw const AgentEmailDraftBindingException(
        'Unsupported email draft binding algorithm.',
      );
    }

    if (fingerprint.trim().isEmpty || draftId.trim().isEmpty) {
      throw const AgentEmailDraftBindingException(
        'Email draft binding fingerprint/draftId cannot be empty.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    validate();

    return <String, dynamic>{
      'algorithm': algorithm,
      'fingerprint': fingerprint,
      'draftId': draftId.trim(),
      'exactDraftMatchRequired': true,
    };
  }
}

class AgentEmailDraftBindingException implements Exception {
  const AgentEmailDraftBindingException(this.message);

  final String message;

  @override
  String toString() => 'AgentEmailDraftBindingException: $message';
}
