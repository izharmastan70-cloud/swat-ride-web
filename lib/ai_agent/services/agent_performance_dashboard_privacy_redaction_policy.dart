import '../constants/agent_performance_dashboard_privacy_constants.dart';
import '../models/agent_performance_dashboard_agent_summary.dart';

class AgentPerformanceDashboardPrivacyRedactionPolicy {
  const AgentPerformanceDashboardPrivacyRedactionPolicy();

  static final RegExp _opaquePattern = RegExp(r'^[A-Za-z0-9_.:-]+$');
  static final RegExp _emailPattern = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    caseSensitive: false,
  );
  static final RegExp _phoneLikePattern = RegExp(r'^[+()\-\s0-9]+$');
  static final RegExp _jwtLikePattern = RegExp(
    r'^[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}$',
  );
  static final RegExp _secretLikePattern = RegExp(
    r'(?:^|[:._-])(?:sk-[A-Za-z0-9_-]{12,}|AIza[0-9A-Za-z_-]{16,}|bearer[:._-]?[A-Za-z0-9._=-]{12,})',
    caseSensitive: false,
  );

  bool isSafeOpaqueIdentifier(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty ||
        trimmed.length >
            AgentPerformanceDashboardPrivacyLimits.opaqueIdMaxLength ||
        trimmed != value ||
        !_opaquePattern.hasMatch(trimmed)) {
      return false;
    }

    if (_emailPattern.hasMatch(trimmed) ||
        trimmed.toLowerCase().startsWith('http:') ||
        trimmed.toLowerCase().startsWith('https:') ||
        trimmed.toLowerCase().startsWith('www.') ||
        _jwtLikePattern.hasMatch(trimmed) ||
        _secretLikePattern.hasMatch(trimmed)) {
      return false;
    }

    final String digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');

    if (_phoneLikePattern.hasMatch(trimmed) &&
        digitsOnly.length >= 10 &&
        digitsOnly.length <= 15) {
      return false;
    }

    return true;
  }

  bool isSafeSummaryIdentifierEnvelope(
    AgentPerformanceDashboardAgentSummary summary,
  ) {
    return isSafeOpaqueIdentifier(summary.agentId) &&
        isSafeOpaqueIdentifier(summary.cohortKey) &&
        isSafeOpaqueIdentifier(summary.windowId) &&
        isSafeOpaqueIdentifier(summary.scoreContractVersion);
  }

  String safeQueryIdOrRedacted(String queryId) {
    if (isSafeOpaqueIdentifier(queryId)) {
      return queryId;
    }
    return 'redacted:query';
  }

  bool get wholeSummaryRedactionOnUnsafeIdentifier => true;
  bool get rawPromptForbidden => true;
  bool get rawConversationForbidden => true;
  bool get displayNameForbidden => true;
  bool get emailForbidden => true;
  bool get phoneForbidden => true;
  bool get urlForbidden => true;
  bool get secretLikeValueForbidden => true;
  bool get tokenLikeValueForbidden => true;
  bool get exceptionTextForbidden => true;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get executesBusinessAction => false;
  bool get persistenceImplementedHere => false;
}
