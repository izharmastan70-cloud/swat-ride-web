// =========================================================
// AI AGENT — CALL PRIVACY SERVICE
// =========================================================

class AgentCallPrivacyService {
  const AgentCallPrivacyService();

  String maskPhone(String phone) {
    final String clean = phone.replaceAll(RegExp(r'\s+'), '');
    if (clean.length <= 4) return '****';
    return '${clean.substring(0, 2)}******${clean.substring(clean.length - 2)}';
  }

  bool containsForbiddenSecret(String text) {
    final String lower = text.toLowerCase();
    return <String>[
      'password',
      'otp code',
      'api key',
      'secret key',
      'bank pin',
      'card cvv',
    ].any(lower.contains);
  }
}
