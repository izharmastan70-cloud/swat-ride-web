import '../constants/agent_knowledge_library_contract_constants.dart';

class AgentKnowledgeSourceReference {
  const AgentKnowledgeSourceReference({
    required this.sourceId,
    required this.sourceType,
    required this.sourceReferenceId,
    required this.sourceVersion,
    required this.authorityClass,
    required this.verified,
    required this.approved,
    required this.active,
    required this.fresh,
    required this.lastVerifiedAt,
    this.expiresAt,
  });

  final String sourceId;
  final String sourceType;
  final String sourceReferenceId;
  final String sourceVersion;
  final String authorityClass;
  final bool verified;
  final bool approved;
  final bool active;
  final bool fresh;
  final DateTime lastVerifiedAt;
  final DateTime? expiresAt;

  bool get sourceIsInformationNotAuthority => true;
  bool get approvalMetadataDoesNotExecuteApproval => true;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get invokesProvider => false;
  bool get persistsSource => false;

  bool isExpiredAt(DateTime now) =>
      expiresAt != null && !expiresAt!.isAfter(now);

  void validateStructure() {
    if (!_validId(sourceId) ||
        !_validId(sourceReferenceId) ||
        !_validId(sourceVersion)) {
      throw const FormatException('Invalid knowledge source identifiers.');
    }

    if (!AgentKnowledgeSourceType.values.contains(sourceType)) {
      throw const FormatException('Unsupported knowledge source type.');
    }

    if (!AgentKnowledgeAuthorityClass.values.contains(authorityClass)) {
      throw const FormatException('Unsupported knowledge authority class.');
    }
  }

  bool _validId(String value) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= AgentKnowledgeContractLimits.idMax &&
        RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
  }
}
