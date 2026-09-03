import 'dart:convert';

import '../constants/agent_owner_attention_constants.dart';
import '../constants/agent_owner_attention_source_signal_constants.dart';
import '../models/agent_email_admin_attention_event.dart';
import '../models/agent_owner_attention_event.dart';
import '../models/agent_owner_attention_source_signal.dart';
import 'agent_owner_attention_source_adapter.dart';

class AgentOwnerAttentionEmailAdapter {
  const AgentOwnerAttentionEmailAdapter({
    this.sourceAdapter = const AgentOwnerAttentionSourceAdapter(),
  });

  final AgentOwnerAttentionSourceAdapter sourceAdapter;

  AgentOwnerAttentionEvent adapt(AgentEmailAdminAttentionEvent email) {
    email.validate();

    if (!email.phase64OwnerAttentionCompatible ||
        !email.requiresHumanReview ||
        email.mayAutoSend ||
        email.bodyIncluded ||
        email.sensitiveValueIncluded ||
        email.status != 'PENDING_REVIEW') {
      throw const FormatException(
        'Email Admin Attention is not safe for Phase 64 ingestion.',
      );
    }

    final sourceHash = _sha256Hex(
      utf8.encode(
        '${email.attentionId}|${email.draftId}|${email.createdAt.toUtc().toIso8601String()}',
      ),
    );

    return sourceAdapter.adapt(
      AgentOwnerAttentionSourceSignal(
        sourceType: AgentOwnerAttentionSourceType.emailAttention,
        sourceKind: AgentOwnerAttentionSourceKind.emailUnusualReview,
        sourceEventId: email.attentionId,
        sourceReferenceSha256: sourceHash,
        safeTitle: email.subjectSafe,
        safeSummary: email.safeSummary,
        reasonCodes: List<String>.unmodifiable(email.reasonCodes),
        redactionVerified: true,
        minimumNecessaryVerified: true,
        occurredAtUtc: email.createdAt.toUtc(),
      ),
    );
  }

  String _sha256Hex(List<int> bytes) {
    final h = <int>[
      0x6a09e667,
      0xbb67ae85,
      0x3c6ef372,
      0xa54ff53a,
      0x510e527f,
      0x9b05688c,
      0x1f83d9ab,
      0x5be0cd19,
    ];

    final k = <int>[
      0x428a2f98,
      0x71374491,
      0xb5c0fbcf,
      0xe9b5dba5,
      0x3956c25b,
      0x59f111f1,
      0x923f82a4,
      0xab1c5ed5,
      0xd807aa98,
      0x12835b01,
      0x243185be,
      0x550c7dc3,
      0x72be5d74,
      0x80deb1fe,
      0x9bdc06a7,
      0xc19bf174,
      0xe49b69c1,
      0xefbe4786,
      0x0fc19dc6,
      0x240ca1cc,
      0x2de92c6f,
      0x4a7484aa,
      0x5cb0a9dc,
      0x76f988da,
      0x983e5152,
      0xa831c66d,
      0xb00327c8,
      0xbf597fc7,
      0xc6e00bf3,
      0xd5a79147,
      0x06ca6351,
      0x14292967,
      0x27b70a85,
      0x2e1b2138,
      0x4d2c6dfc,
      0x53380d13,
      0x650a7354,
      0x766a0abb,
      0x81c2c92e,
      0x92722c85,
      0xa2bfe8a1,
      0xa81a664b,
      0xc24b8b70,
      0xc76c51a3,
      0xd192e819,
      0xd6990624,
      0xf40e3585,
      0x106aa070,
      0x19a4c116,
      0x1e376c08,
      0x2748774c,
      0x34b0bcb5,
      0x391c0cb3,
      0x4ed8aa4a,
      0x5b9cca4f,
      0x682e6ff3,
      0x748f82ee,
      0x78a5636f,
      0x84c87814,
      0x8cc70208,
      0x90befffa,
      0xa4506ceb,
      0xbef9a3f7,
      0xc67178f2,
    ];

    final data = List<int>.from(bytes);
    final bitLength = data.length * 8;

    data.add(0x80);

    while ((data.length % 64) != 56) {
      data.add(0);
    }

    for (var i = 7; i >= 0; i--) {
      data.add((bitLength >> (8 * i)) & 0xff);
    }

    int rotr(int x, int n) =>
        ((x >> n) | ((x << (32 - n)) & 0xffffffff)) & 0xffffffff;

    for (var offset = 0; offset < data.length; offset += 64) {
      final w = List<int>.filled(64, 0);

      for (var i = 0; i < 16; i++) {
        final j = offset + (i * 4);
        w[i] =
            ((data[j] << 24) |
                (data[j + 1] << 16) |
                (data[j + 2] << 8) |
                data[j + 3]) &
            0xffffffff;
      }

      for (var i = 16; i < 64; i++) {
        final s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);

        final s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);

        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
      }

      var a = h[0];
      var b = h[1];
      var c = h[2];
      var d = h[3];
      var e = h[4];
      var f = h[5];
      var g = h[6];
      var hh = h[7];

      for (var i = 0; i < 64; i++) {
        final s1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
        final ch = (e & f) ^ ((~e) & g);
        final temp1 = (hh + s1 + ch + k[i] + w[i]) & 0xffffffff;

        final s0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0 + maj) & 0xffffffff;

        hh = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xffffffff;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xffffffff;
      }

      h[0] = (h[0] + a) & 0xffffffff;
      h[1] = (h[1] + b) & 0xffffffff;
      h[2] = (h[2] + c) & 0xffffffff;
      h[3] = (h[3] + d) & 0xffffffff;
      h[4] = (h[4] + e) & 0xffffffff;
      h[5] = (h[5] + f) & 0xffffffff;
      h[6] = (h[6] + g) & 0xffffffff;
      h[7] = (h[7] + hh) & 0xffffffff;
    }

    return h.map((x) => x.toRadixString(16).padLeft(8, '0')).join();
  }

  bool get preservesSourceModel => true;
  bool get bodyCopied => false;
  bool get sensitiveValueCopied => false;
  bool get sendsEmail => false;
  bool get writesInbox => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;
}
