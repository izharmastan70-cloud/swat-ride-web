// =========================================================
// AI AGENT — READ-ONLY OUTPUT SANITIZER
// =========================================================
//
// Phase 7 baseline redaction before data may be handed to an AI provider.
// A later Privacy Router will add context-aware classification/redaction.

class AgentReadOnlySanitizer {
  const AgentReadOnlySanitizer();

  Map<String, dynamic> sanitizeMap(Map<String, dynamic> input) {
    final Map<String, dynamic> output = <String, dynamic>{};

    for (final MapEntry<String, dynamic> entry in input.entries) {
      final String key = entry.key.trim();
      final String normalized = key.toLowerCase();

      if (_isSecretKey(normalized)) {
        output[key] = '[REDACTED]';
      } else {
        output[key] = _sanitizeValue(entry.value);
      }
    }

    return output;
  }

  dynamic _sanitizeValue(dynamic value) {
    if (value is Map) {
      return sanitizeMap(
        value.map(
          (dynamic key, dynamic item) =>
              MapEntry<String, dynamic>(key.toString(), item),
        ),
      );
    }

    if (value is Iterable) {
      return value
          .map<dynamic>((dynamic item) => _sanitizeValue(item))
          .toList(growable: false);
    }

    return value;
  }

  bool _isSecretKey(String key) {
    const List<String> blockedFragments = <String>[
      'password',
      'passwd',
      'secret',
      'token',
      'apikey',
      'api_key',
      'privatekey',
      'private_key',
      'authorization',
      'credential',
      'gatewaykey',
      'gateway_key',
      'banklogin',
      'bank_login',
      'serviceaccount',
      'service_account',
    ];

    return blockedFragments.any(key.contains);
  }
}
