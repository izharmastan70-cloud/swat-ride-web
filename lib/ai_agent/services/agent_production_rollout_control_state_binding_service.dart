import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/agent_production_rollout_snapshot.dart';

class AgentProductionRolloutControlStateBindingService {
  const AgentProductionRolloutControlStateBindingService();

  static const String algorithm = 'SHA256_CONTROL_STATE_V1';

  String bind(AgentProductionRolloutSnapshot snapshot) {
    snapshot.validate();

    final Map<String, dynamic> state = <String, dynamic>{
      'masterSettings': snapshot.masterSettingsProjection,
      'roles': snapshot.roleControlProjections,
    };

    return sha256
        .convert(utf8.encode(jsonEncode(_canonicalize(state))))
        .toString();
  }

  dynamic _canonicalize(dynamic value) {
    if (value == null || value is String || value is bool || value is num) {
      return value;
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

    return value.toString();
  }

  bool get excludesCaptureTimestamp => true;
  bool get excludesEnvelopeEvidenceReferences => true;
  bool get bindsMasterControlState => true;
  bool get bindsRoleAuthorityState => true;

  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get activatesRollout => false;
}
