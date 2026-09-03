import '../constants/agent_knowledge_library_contract_constants.dart';

class AgentKnowledgeItem {
  AgentKnowledgeItem({
    required this.itemId,
    required this.sourceId,
    required this.title,
    required this.module,
    required this.topic,
    required this.language,
    required this.status,
    required this.revision,
    required this.sourceVersion,
    required this.contentReferenceId,
    required Set<String> scopes,
    required this.effectiveAt,
    this.expiresAt,
    this.supersedesItemId = '',
  }) : scopes = Set<String>.unmodifiable(scopes);

  final String itemId;
  final String sourceId;
  final String title;
  final String module;
  final String topic;
  final String language;
  final String status;
  final int revision;
  final String sourceVersion;
  final String contentReferenceId;
  final Set<String> scopes;
  final DateTime effectiveAt;
  final DateTime? expiresAt;
  final String supersedesItemId;

  bool get metadataReferencesContentOnly => true;
  bool get containsRawSecret => false;
  bool get containsAuthToken => false;
  bool get containsPassword => false;
  bool get containsPaymentCard => false;
  bool get containsCvv => false;
  bool get containsPin => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get indexesContentHere => false;
  bool get retrievesContentHere => false;
  bool get invokesProvider => false;
  bool get persistsItem => false;

  bool isExpiredAt(DateTime now) =>
      expiresAt != null && !expiresAt!.isAfter(now);

  bool isEffectiveAt(DateTime now) => !effectiveAt.isAfter(now);

  bool get hasPublicPrivilegedScopeConflict =>
      scopes.contains(AgentKnowledgeScope.public) &&
      scopes.any(AgentKnowledgeScope.privileged.contains);

  void validateStructure() {
    if (!_validId(itemId) ||
        !_validId(sourceId) ||
        !_validId(sourceVersion) ||
        !_validId(contentReferenceId)) {
      throw const FormatException('Invalid knowledge item identifiers.');
    }

    if (supersedesItemId.isNotEmpty && !_validId(supersedesItemId)) {
      throw const FormatException('Invalid superseded item ID.');
    }

    if (title.trim().isEmpty ||
        title.length > AgentKnowledgeContractLimits.titleMax) {
      throw const FormatException('Invalid knowledge item title.');
    }

    if (module.trim().isEmpty ||
        module.length > AgentKnowledgeContractLimits.moduleMax ||
        topic.trim().isEmpty ||
        topic.length > AgentKnowledgeContractLimits.topicMax) {
      throw const FormatException('Invalid knowledge item module/topic.');
    }

    if (!AgentKnowledgeLanguage.values.contains(language)) {
      throw const FormatException('Unsupported knowledge language.');
    }

    if (!AgentKnowledgeItemStatus.values.contains(status)) {
      throw const FormatException('Unsupported knowledge item status.');
    }

    if (revision <= 0 || revision > AgentKnowledgeContractLimits.versionMax) {
      throw const FormatException('Invalid knowledge item revision.');
    }

    if (scopes.isEmpty ||
        scopes.length > AgentKnowledgeContractLimits.maxScopes ||
        scopes.any(
          (String scope) => !AgentKnowledgeScope.values.contains(scope),
        )) {
      throw const FormatException('Invalid knowledge item scopes.');
    }
  }

  bool _validId(String value) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= AgentKnowledgeContractLimits.idMax &&
        RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
  }
}
