import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../constants/agent_production_rollout_arming_token_constants.dart';
import '../constants/agent_production_rollout_runtime_guard_constants.dart';
import '../models/agent_production_rollout_arming_token_models.dart';

class AgentProductionRolloutArmingTokenService {
  AgentProductionRolloutArmingTokenService({Random? secureRandom})
    : _secureRandom = secureRandom ?? Random.secure();

  final Random _secureRandom;

  AgentProductionRolloutArmingCredential createSecureCredential({
    required AgentProductionRolloutTrustedLivePreflight preflight,
    required int guardRevision,
    required DateTime issuedAtUtc,
    DateTime? expiresAtUtc,
  }) {
    preflight.validate();

    final List<int> bytes = List<int>.generate(
      AgentProductionRolloutArmingTokenLimits.secureRandomBytes,
      (_) => _secureRandom.nextInt(256),
      growable: false,
    );

    final String rawToken = base64UrlEncode(bytes).replaceAll('=', '');

    return bindRawToken(
      rawToken: rawToken,
      preflight: preflight,
      guardRevision: guardRevision,
      issuedAtUtc: issuedAtUtc,
      expiresAtUtc: expiresAtUtc,
    );
  }

  AgentProductionRolloutArmingCredential bindRawToken({
    required String rawToken,
    required AgentProductionRolloutTrustedLivePreflight preflight,
    required int guardRevision,
    required DateTime issuedAtUtc,
    DateTime? expiresAtUtc,
  }) {
    preflight.validate();

    final DateTime issued = issuedAtUtc.toUtc();
    final DateTime expires =
        expiresAtUtc?.toUtc() ??
        issued.add(AgentProductionRolloutArmingTokenLimits.maxValidity);

    return AgentProductionRolloutArmingCredential(
      rawToken: rawToken.trim(),
      tokenIdSha256: hashRawToken(rawToken),
      actorReferenceSha256: preflight.actorReferenceSha256.toLowerCase(),
      ownerApprovalId: preflight.ownerApprovalId,
      planFingerprintSha256: preflight.planFingerprintSha256.toLowerCase(),
      controlStateFingerprintSha256: preflight.controlStateFingerprintSha256
          .toLowerCase(),
      guardRevision: guardRevision,
      guardVersion: AgentProductionRolloutRuntimeGuardVersion.monitorOnlyV1,
      roleCount: preflight.roleCount,
      issuedAtUtc: issued,
      expiresAtUtc: expires,
    );
  }

  String hashRawToken(String rawToken) {
    return sha256.convert(utf8.encode(rawToken.trim())).toString();
  }

  bool matches({required String rawToken, required String tokenIdSha256}) {
    return hashRawToken(rawToken) == tokenIdSha256.trim().toLowerCase();
  }

  bool get persistsRawToken => false;
  bool get logsRawToken => false;
  bool get usesSecureRandom => true;
}
