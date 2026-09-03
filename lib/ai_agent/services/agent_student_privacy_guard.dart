// =========================================================
// AI AGENT — STUDENT PRIVACY GUARD
// =========================================================
//
// Student Ride data receives stricter handling because it can involve minors.
// This is an additional application guard, not a replacement for backend
// authorization/security rules.

class AgentStudentPrivacyGuard {
  const AgentStudentPrivacyGuard();

  bool containsForbiddenSecret(String text) {
    final String lower = text.toLowerCase();

    return <String>[
      'pickup pin',
      'handover pin',
      'qr secret',
      'password',
      'otp code',
      'api key',
      'bank pin',
      'card cvv',
    ].any(lower.contains);
  }

  String safeAlias(String value) {
    final String clean = value.trim();
    if (clean.isEmpty) return 'Student';
    return clean.length <= 2 ? '${clean[0]}*' : '${clean[0]}***';
  }
}
