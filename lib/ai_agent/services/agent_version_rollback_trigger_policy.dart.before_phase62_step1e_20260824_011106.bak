import '../constants/agent_version_monitoring_constants.dart';
import '../models/agent_version_record.dart';
import '../models/agent_version_rollback_trigger.dart';
import '../models/agent_version_rollout_health_decision.dart';

class AgentVersionRollbackTriggerPolicy {
  const AgentVersionRollbackTriggerPolicy();

  AgentVersionRollbackTrigger evaluate({
    required AgentVersionRecord version,
    required AgentVersionRolloutHealthDecision health,
  }) {
    try {
      version.validate();
      health.validate();
    } catch (_) {
      return AgentVersionRollbackTrigger(
        status: AgentVersionRollbackTriggerStatus.blockedInvalidInput,
        currentVersionId: version.versionId,
        rollbackTargetVersionId: null,
        rolloutId: health.rolloutId,
        reasonCode: 'invalid_rollback_trigger_input',
        ownerAlertRequired: true,
      );
    }

    if (!health.rollbackRequestRequired) {
      return AgentVersionRollbackTrigger(
        status: AgentVersionRollbackTriggerStatus.notRequired,
        currentVersionId: version.versionId,
        rollbackTargetVersionId: null,
        rolloutId: health.rolloutId,
        reasonCode: 'rollback_not_required',
        ownerAlertRequired: health.ownerAlertRequired,
      );
    }

    final String? previous = version.previousVersionId;

    if (previous == null || previous.trim().isEmpty) {
      return AgentVersionRollbackTrigger(
        status: AgentVersionRollbackTriggerStatus.blockedNoKnownGoodVersion,
        currentVersionId: version.versionId,
        rollbackTargetVersionId: null,
        rolloutId: health.rolloutId,
        reasonCode: 'known_good_previous_version_missing',
        ownerAlertRequired: true,
      );
    }

    return AgentVersionRollbackTrigger(
      status: AgentVersionRollbackTriggerStatus.required,
      currentVersionId: version.versionId,
      rollbackTargetVersionId: previous,
      rolloutId: health.rolloutId,
      reasonCode: health.reasonCode,
      ownerAlertRequired: true,
    );
  }

  bool get triggerOnly => true;
  bool get exactBackupRestorePerformed => false;
  bool get rollbackExecutionPerformed => false;
  bool get automaticRollbackPerformed => false;
  bool get persistsTrigger => false;
  bool get mutatesLifecycle => false;
  bool get routesTraffic => false;
  bool get deploysVersion => false;
  bool get activatesProduction => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get sendsOwnerAlert => false;
  bool get writesBusinessData => false;
}
