import '../constants/agent_crash_constants.dart';
import '../models/agent_crash_assessment.dart';
import '../models/agent_crash_event.dart';

// =========================================================
// AI AGENT — CRASH CLASSIFIER
// =========================================================
//
// Deterministic technical classification first.
// Paid AI is NOT called here.

class AgentCrashClassifier {
  const AgentCrashClassifier();

  AgentCrashAssessment assess(AgentCrashEvent event) {
    final String text =
        '${event.errorType} ${event.message} ${event.stackSummary}'
            .toLowerCase();

    final String category = _category(text);
    final String severity = _severity(text, event.occurrenceCount);

    final bool likelyCodeIssue = <String>[
      AgentCrashCategory.flutter,
      AgentCrashCategory.dart,
      AgentCrashCategory.firebase,
      AgentCrashCategory.build,
    ].contains(category);

    final bool shouldHandoff =
        likelyCodeIssue &&
        (severity == AgentCrashSeverity.high ||
            severity == AgentCrashSeverity.critical ||
            event.occurrenceCount >= 3);

    return AgentCrashAssessment(
      severity: severity,
      category: category,
      likelyCodeIssue: likelyCodeIssue,
      shouldHandoffToCodeAgent: shouldHandoff,
      shouldNotifyOwner:
          severity == AgentCrashSeverity.critical ||
              event.occurrenceCount >= 5,
      summary: '$category technical issue detected.',
      reason: shouldHandoff
          ? 'Technical issue meets Code Agent handoff threshold.'
          : 'Monitor first; no paid Code Agent handoff yet.',
    );
  }

  String _category(String text) {
    if (_contains(text, <String>[
      'gradle',
      'assembledebug',
      'build failed',
      'pubspec',
    ])) {
      return AgentCrashCategory.build;
    }

    if (_contains(text, <String>[
      'firebase',
      'firestore',
      'firebaseauth',
      'cloud_firestore',
    ])) {
      return AgentCrashCategory.firebase;
    }

    if (_contains(text, <String>[
      'storage',
      'firebase_storage',
    ])) {
      return AgentCrashCategory.storage;
    }

    if (_contains(text, <String>[
      'payment',
      'gateway',
      'jazzcash',
      'easypaisa',
    ])) {
      return AgentCrashCategory.payment;
    }

    if (_contains(text, <String>[
      'socket',
      'timeout',
      'network',
      'connection',
    ])) {
      return AgentCrashCategory.network;
    }

    if (_contains(text, <String>[
      'flutter',
      'widget',
      'renderflex',
      'setstate',
    ])) {
      return AgentCrashCategory.flutter;
    }

    if (_contains(text, <String>[
      'null check operator',
      'nosuchmethod',
      'typeerror',
      'rangeerror',
      'dart',
    ])) {
      return AgentCrashCategory.dart;
    }

    return AgentCrashCategory.unknown;
  }

  String _severity(String text, int count) {
    if (_contains(text, <String>[
          'fatal',
          'crash',
          'build failed',
          'security',
        ]) ||
        count >= 5) {
      return AgentCrashSeverity.critical;
    }

    if (count >= 3 ||
        _contains(text, <String>[
          'exception',
          'failed',
          'permission denied',
        ])) {
      return AgentCrashSeverity.high;
    }

    return AgentCrashSeverity.warning;
  }

  bool _contains(String text, List<String> terms) {
    return terms.any(text.contains);
  }
}
