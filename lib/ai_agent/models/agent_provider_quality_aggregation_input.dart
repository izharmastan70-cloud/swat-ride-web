import '../constants/agent_provider_quality_signal_constants.dart';
import 'agent_provider_quality_signal.dart';

class AgentProviderQualityAggregationInput {
  AgentProviderQualityAggregationInput({
    required List<AgentProviderQualitySignal> signals,
  }) : signals = List<AgentProviderQualitySignal>.unmodifiable(signals);

  final List<AgentProviderQualitySignal> signals;

  String get providerId => signals.first.providerId;
  String get modelReference => signals.first.modelReference;
  String get providerTier => signals.first.providerTier;
  String get taskType => signals.first.taskType;

  Set<String> get coveredFamilies =>
      signals.map((AgentProviderQualitySignal value) => value.family).toSet();

  bool get hasDuplicateFamilies => coveredFamilies.length != signals.length;

  bool get criticalFamiliesPresent {
    const Set<String> critical = <String>{
      AgentProviderQualitySignalFamily.reliability,
      AgentProviderQualitySignalFamily.taskFit,
      AgentProviderQualitySignalFamily.outputQuality,
      AgentProviderQualitySignalFamily.safety,
    };

    return coveredFamilies.containsAll(critical);
  }

  bool get containsRawPrompt => false;
  bool get containsRawConversation => false;
  bool get containsRawProviderResponse => false;
  bool get invokesProvider => false;
  bool get mutatesRouting => false;
  bool get persistsInput => false;

  void validateStructure() {
    if (signals.isEmpty ||
        signals.length > AgentProviderQualitySignalFamily.values.length ||
        hasDuplicateFamilies) {
      throw const FormatException(
        'Invalid provider quality aggregation input.',
      );
    }

    for (final AgentProviderQualitySignal signal in signals) {
      signal.validateStructure();

      if (signal.providerId != providerId ||
          signal.modelReference != modelReference ||
          signal.providerTier != providerTier ||
          signal.taskType != taskType) {
        throw const FormatException(
          'Quality signals must share provider/model/tier/task binding.',
        );
      }
    }
  }
}
