import '../constants/agent_privacy_export_delivery_constants.dart';
import '../constants/agent_privacy_retention_classification_constants.dart';

class AgentPrivacyExportRecord {
  AgentPrivacyExportRecord({
    required this.dataKind,
    required this.fields,
    required this.redactedProjectionVerified,
    required this.restrictedCriticalExcluded,
    required this.protectedEvidenceExcluded,
  }) {
    validate();
  }

  final String dataKind;
  final Map<String, Object?> fields;

  final bool redactedProjectionVerified;
  final bool restrictedCriticalExcluded;
  final bool protectedEvidenceExcluded;

  bool get containsRawCallRecording => false;
  bool get containsSecrets => false;
  bool get containsTokens => false;
  bool get containsPaymentCredentials => false;

  void validate() {
    if (!AgentPrivacyDataKind.values.contains(dataKind) ||
        fields.isEmpty ||
        fields.length >
            AgentPrivacyExportDeliveryLimits.maximumFieldCountPerRecord ||
        !redactedProjectionVerified ||
        !restrictedCriticalExcluded ||
        !protectedEvidenceExcluded) {
      throw const FormatException('Invalid sanitized privacy export record.');
    }

    final blockedKey = RegExp(
      r'(password|passwd|secret|api.?key|auth.?token|approval.?token|permission.?token|card.?number|cvv|cvc|payment.?credential|raw.?recording|audio.?bytes)',
      caseSensitive: false,
    );

    for (final entry in fields.entries) {
      final key = entry.key.trim();

      if (key.isEmpty ||
          key.length > AgentPrivacyExportDeliveryLimits.maximumFieldKeyLength ||
          blockedKey.hasMatch(key)) {
        throw const FormatException(
          'Unsafe field name in privacy export record.',
        );
      }

      _validateValue(entry.value);
    }
  }

  void _validateValue(Object? value) {
    if (value == null || value is num || value is bool) {
      return;
    }

    if (value is String) {
      if (value.length >
          AgentPrivacyExportDeliveryLimits.maximumTextValueLength) {
        throw const FormatException('Privacy export text value is too large.');
      }
      return;
    }

    if (value is List<Object?>) {
      if (value.length > 1000) {
        throw const FormatException('Privacy export list value is too large.');
      }

      for (final item in value) {
        _validateValue(item);
      }
      return;
    }

    if (value is Map<String, Object?>) {
      if (value.length > 1000) {
        throw const FormatException('Privacy export map value is too large.');
      }

      for (final entry in value.entries) {
        if (entry.key.trim().isEmpty) {
          throw const FormatException(
            'Privacy export nested key cannot be empty.',
          );
        }
        _validateValue(entry.value);
      }
      return;
    }

    throw const FormatException('Unsupported privacy export value type.');
  }

  Map<String, Object?> toSafeMap() {
    return <String, Object?>{
      'dataKind': dataKind,
      'fields': fields,
      'redactedProjectionVerified': true,
      'restrictedCriticalExcluded': true,
      'protectedEvidenceExcluded': true,
    };
  }
}
