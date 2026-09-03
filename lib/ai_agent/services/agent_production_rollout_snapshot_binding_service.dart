import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../constants/agent_production_rollout_snapshot_constants.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_production_rollout_snapshot.dart';
import '../models/agent_role.dart';

class AgentProductionRolloutSnapshotBindingService {
  const AgentProductionRolloutSnapshotBindingService();

  static const String algorithm = 'SHA256_CANONICAL_JSON_V1';

  AgentProductionRolloutSnapshot bind({
    required AgentMasterSettings settings,
    required List<AgentRole> roles,
    required DateTime capturedAtUtc,
    required String phase65SafetyEvidenceSha256,
    required String phase62VersionEvidenceSha256,
  }) {
    final Map<String, dynamic> master = _masterControlProjection(settings);

    final List<Map<String, dynamic>> roleProjections =
        roles.map(_roleProjection).toList(growable: false)..sort(
          (Map<String, dynamic> first, Map<String, dynamic> second) =>
              first['roleId'].toString().compareTo(second['roleId'].toString()),
        );

    final Map<String, dynamic> canonicalState = <String, dynamic>{
      'source': AgentProductionRolloutSnapshotSource.liveFirestore,
      'capturedAtUtc': capturedAtUtc.toUtc().toIso8601String(),
      'phase65SafetyEvidenceSha256': phase65SafetyEvidenceSha256
          .trim()
          .toLowerCase(),
      'phase62VersionEvidenceSha256': phase62VersionEvidenceSha256
          .trim()
          .toLowerCase(),
      'masterSettings': master,
      'roles': roleProjections,
    };

    final String fingerprint = sha256
        .convert(utf8.encode(jsonEncode(_canonicalize(canonicalState))))
        .toString();

    return AgentProductionRolloutSnapshot(
      source: AgentProductionRolloutSnapshotSource.liveFirestore,
      capturedAtUtc: capturedAtUtc.toUtc(),
      snapshotFingerprintSha256: fingerprint,
      phase65SafetyEvidenceSha256: phase65SafetyEvidenceSha256
          .trim()
          .toLowerCase(),
      phase62VersionEvidenceSha256: phase62VersionEvidenceSha256
          .trim()
          .toLowerCase(),
      masterSettingsProjection: master,
      roleControlProjections: roleProjections,
    );
  }

  Map<String, dynamic> _masterControlProjection(AgentMasterSettings settings) {
    final Map<String, dynamic> projection = Map<String, dynamic>.from(
      settings.toMap(),
    );

    // These are audit/lifecycle timestamps, not rollout authority controls.
    // Keeping them in the fingerprint would make the same operational state
    // hash differently whenever safeDefaults() is reconstructed.
    const Set<String> volatileNonAuthorityKeys = <String>{
      'createdAt',
      'updatedAt',
      'emergencyActivatedAt',
    };

    for (final String key in volatileNonAuthorityKeys) {
      projection.remove(key);
    }

    return _canonicalMap(projection);
  }

  Map<String, dynamic> _roleProjection(AgentRole role) {
    final List<String> allowed = List<String>.from(role.allowedActions)..sort();
    final List<String> approval = List<String>.from(
      role.approvalRequiredActions,
    )..sort();
    final List<String> forbidden = List<String>.from(role.forbiddenActions)
      ..sort();

    return <String, dynamic>{
      'roleId': role.roleId.trim(),
      'module': role.module.trim(),
      'enabled': role.enabled,
      'mode': role.mode,
      'allowedActions': allowed,
      'approvalRequiredActions': approval,
      'forbiddenActions': forbidden,
      'aiClass': role.aiClass,
      'privacyLevel': role.privacyLevel,
      'isFailClosed': role.isFailClosed,
    };
  }

  Map<String, dynamic> _canonicalMap(Map<String, dynamic> value) {
    return Map<String, dynamic>.from(
      _canonicalize(value) as Map<String, dynamic>,
    );
  }

  dynamic _canonicalize(dynamic value) {
    if (value == null || value is String || value is bool || value is num) {
      return value;
    }

    if (value is Timestamp) {
      return value.toDate().toUtc().toIso8601String();
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

    return value.toString();
  }

  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get callsProvider => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get activatesRollout => false;
}
