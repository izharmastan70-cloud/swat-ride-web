import '../constants/help_video_education_adversarial_constants.dart';

class HelpVideoEducationPrivacySafeTelemetryEvent {
  HelpVideoEducationPrivacySafeTelemetryEvent({
    required this.tutorialId,
    required this.eventType,
    required this.module,
    required this.feature,
    required this.language,
    required this.appVersion,
    required this.videoVersion,
    required this.reasonCode,
    required this.occurredAt,
  });

  final String tutorialId;
  final String eventType;
  final String module;
  final String feature;
  final String language;
  final String appVersion;
  final String videoVersion;
  final String reasonCode;
  final DateTime occurredAt;

  bool get metadataOnly => true;
  bool get containsRawMessage => false;
  bool get containsPhone => false;
  bool get containsEmail => false;
  bool get containsAuthToken => false;
  bool get containsPaymentSecret => false;
  bool get containsPreciseLocation => false;
  bool get containsVideoUrl => false;
  bool get grantsAuthority => false;
  bool get writesBusinessData => false;
  bool get persistsTelemetry => false;

  void validateStructure() {
    if (!_safeId(tutorialId, 180)) {
      throw const HelpVideoEducationTelemetryException(
        'Telemetry tutorial ID is invalid.',
      );
    }

    if (!HelpVideoEducationTelemetryEventType.values.contains(eventType)) {
      throw const HelpVideoEducationTelemetryException(
        'Telemetry event type is invalid.',
      );
    }

    if (!_safeOptional(module, 100) ||
        !_safeOptional(feature, 120) ||
        !_safeOptional(language, 20) ||
        !_safeOptional(appVersion, 40) ||
        !_safeOptional(videoVersion, 40) ||
        !_safeOptional(reasonCode, 100)) {
      throw const HelpVideoEducationTelemetryException(
        'Telemetry metadata is invalid.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'tutorialId': tutorialId,
      'eventType': eventType,
      'module': module,
      'feature': feature,
      'language': language,
      'appVersion': appVersion,
      'videoVersion': videoVersion,
      'reasonCode': reasonCode,
      'occurredAt': occurredAt.toUtc().toIso8601String(),
      'metadataOnly': true,
      'containsRawMessage': false,
      'containsPhone': false,
      'containsEmail': false,
      'containsAuthToken': false,
      'containsPaymentSecret': false,
      'containsPreciseLocation': false,
      'containsVideoUrl': false,
      'grantsAuthority': false,
      'writesBusinessData': false,
      'persistsTelemetry': false,
    });
  }

  bool _safeId(String value, int maxLength) {
    final String trimmed = value.trim();
    return trimmed.isNotEmpty &&
        trimmed.length <= maxLength &&
        !RegExp(r'[\u0000-\u001F]').hasMatch(trimmed);
  }

  bool _safeOptional(String value, int maxLength) {
    final String trimmed = value.trim();
    return trimmed.length <= maxLength &&
        !RegExp(r'[\u0000-\u001F]').hasMatch(trimmed);
  }
}

class HelpVideoEducationTelemetryException implements Exception {
  const HelpVideoEducationTelemetryException(this.message);

  final String message;

  @override
  String toString() => 'HelpVideoEducationTelemetryException: $message';
}
