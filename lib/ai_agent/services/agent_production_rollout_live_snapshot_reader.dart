import '../models/agent_production_rollout_snapshot.dart';
import 'agent_production_rollout_live_state_source.dart';

abstract class AgentProductionRolloutLiveSnapshotReader {
  Future<AgentProductionRolloutSnapshot> read({
    required DateTime capturedAtUtc,
    required String phase65SafetyEvidenceSha256,
    required String phase62VersionEvidenceSha256,
  });
}

class AgentProductionRolloutLiveSnapshotReaderAdapter
    implements AgentProductionRolloutLiveSnapshotReader {
  AgentProductionRolloutLiveSnapshotReaderAdapter({
    AgentProductionRolloutLiveStateSource? source,
  }) : _source = source ?? AgentProductionRolloutLiveStateSource();

  final AgentProductionRolloutLiveStateSource _source;

  @override
  Future<AgentProductionRolloutSnapshot> read({
    required DateTime capturedAtUtc,
    required String phase65SafetyEvidenceSha256,
    required String phase62VersionEvidenceSha256,
  }) {
    return _source.readLiveSnapshot(
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65SafetyEvidenceSha256,
      phase62VersionEvidenceSha256: phase62VersionEvidenceSha256,
    );
  }

  bool get adapterOnly => true;
  bool get writesFirestore => false;
  bool get changesMasterSettings => false;
  bool get changesAgentMode => false;
  bool get activatesRollout => false;
}
