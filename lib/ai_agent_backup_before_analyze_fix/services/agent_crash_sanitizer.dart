// =========================================================
// AI AGENT — CRASH SANITIZER
// =========================================================
//
// Removes obvious secrets and limits stored crash text.
// Privacy Router later adds stronger centralized rules.

class AgentCrashSanitizer {
  const AgentCrashSanitizer();

  String sanitizeText(
    String input, {
    int maxLength = 4000,
  }) {
    String output = input;

    final List<RegExp> patterns = <RegExp>[
      RegExp(r'(?i)bearer\s+[A-Za-z0-9\-\._~\+/]+=*'),
      RegExp(r'(?i)(api[_-]?key|token|secret|password)\s*[:=]\s*\S+'),
      RegExp(r'(?i)authorization\s*[:=]\s*\S+'),
    ];

    for (final RegExp pattern in patterns) {
      output = output.replaceAll(pattern, '[REDACTED]');
    }

    if (output.length > maxLength) {
      output = '${output.substring(0, maxLength)}...[TRUNCATED]';
    }

    return output;
  }
}
