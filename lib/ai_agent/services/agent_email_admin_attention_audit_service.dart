import '../constants/agent_audit_constants.dart';
import '../models/agent_email_admin_attention_event.dart';
import '../models/agent_email_draft.dart';
import '../models/agent_email_draft_policy_decision.dart';
import 'agent_audit_service.dart';

class AgentEmailAdminAttentionAuditService {
  AgentEmailAdminAttentionAuditService({this._auditService});

  final AgentAuditService? _auditService;

  AgentAuditService get auditService => _auditService ?? AgentAuditService();

  bool get maySendEmail => false;
  bool get mayApproveEmail => false;
  bool get mayRejectEmail => false;
  bool get mayConsumeApproval => false;
  bool get mayCallProvider => false;
  bool get mayStoreRawBodyInAttentionMetadata => false;
  bool get mayStoreSensitiveCredentialValue => false;

  AgentEmailAdminAttentionEvent buildEvent({
    required String attentionId,
    required String sourceAddress,
    required AgentEmailDraft draft,
    required AgentEmailDraftPolicyDecision policyDecision,
    DateTime? createdAt,
  }) {
    draft.validate();
    policyDecision.validate();

    if (!policyDecision.requiresHumanReview) {
      throw const AgentEmailAdminAttentionException(
        'Normal Email Draft does not require Admin Attention.',
      );
    }

    final AgentEmailAdminAttentionEvent event = AgentEmailAdminAttentionEvent(
      attentionId: attentionId.trim(),
      draftId: draft.draftId.trim(),
      sourceAddressMasked: _maskEmail(sourceAddress),
      subjectSafe: _redactSensitiveText(draft.subject),
      safeSummary:
          'Unusual Email requires Super Admin review. Message body is intentionally hidden from attention metadata.',
      reasonCodes: List<String>.unmodifiable(policyDecision.reasonCodes),
      createdAt: createdAt ?? DateTime.now(),
    );

    event.validate();
    return event;
  }

  Future<void> recordEvent(AgentEmailAdminAttentionEvent event) async {
    event.validate();

    await auditService.recordSystemEvent(
      reason:
          'Unusual Email requires Super Admin review before any consequential action.',
      module: 'email',
      actionId: 'email.admin_attention',
      result: 'REVIEW_REQUIRED',
      severity: AgentAuditSeverity.warning,
      metadata: event.toSafeMetadata(),
    );
  }

  Future<AgentEmailAdminAttentionEvent?> recordIfRequired({
    required String attentionId,
    required String sourceAddress,
    required AgentEmailDraft draft,
    required AgentEmailDraftPolicyDecision policyDecision,
    DateTime? createdAt,
  }) async {
    if (!policyDecision.requiresHumanReview) {
      return null;
    }

    final AgentEmailAdminAttentionEvent event = buildEvent(
      attentionId: attentionId,
      sourceAddress: sourceAddress,
      draft: draft,
      policyDecision: policyDecision,
      createdAt: createdAt,
    );

    await recordEvent(event);
    return event;
  }

  String _maskEmail(String value) {
    final String normalized = value.trim().toLowerCase();
    final int at = normalized.indexOf('@');

    if (at <= 0 || at == normalized.length - 1) {
      return '[REDACTED_EMAIL]';
    }

    final String local = normalized.substring(0, at);
    final String domain = normalized.substring(at + 1);

    final String prefix = local.length <= 2
        ? local.substring(0, 1)
        : local.substring(0, 2);

    return '$prefix***@$domain';
  }

  String _redactSensitiveText(String value) {
    String output = value.trim();

    final List<RegExp> patterns = <RegExp>[
      RegExp(r'\bpassword\s*(?:[:=]|\bis\b)\s*\S+', caseSensitive: false),
      RegExp(r'\botp\s*(?:[:=]|\bis\b)\s*\d{4,8}\b', caseSensitive: false),
      RegExp(r'\b(api[_\s-]?key)\s*[:=]\s*\S+', caseSensitive: false),
      RegExp(r'\b(access[_\s-]?token)\s*[:=]\s*\S+', caseSensitive: false),
      RegExp(r'\bsecret\s*[:=]\s*\S+', caseSensitive: false),
      RegExp(r'\b(cvv|cvc)\s*[:=]\s*\d{3,4}\b', caseSensitive: false),
      RegExp(
        r'\b(card\s*number)\s*[:=]\s*(?:\d[\s-]*){12,19}\b',
        caseSensitive: false,
      ),
    ];

    for (final RegExp pattern in patterns) {
      output = output.replaceAll(pattern, '[REDACTED]');
    }

    if (output.isEmpty) {
      return '[NO_SUBJECT]';
    }

    const int maxLength = 160;
    if (output.length > maxLength) {
      return '${output.substring(0, maxLength)}...';
    }

    return output;
  }
}
