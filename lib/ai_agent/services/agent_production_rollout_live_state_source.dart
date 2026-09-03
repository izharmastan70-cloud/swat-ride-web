import '../models/agent_production_rollout_snapshot.dart';
import 'agent_master_settings_service.dart';
import 'agent_production_rollout_snapshot_binding_service.dart';
import 'agent_role_service.dart';

class AgentProductionRolloutLiveStateSource {
  factory AgentProductionRolloutLiveStateSource({
    AgentMasterSettingsService? settingsService,
    AgentRoleService? roleService,
    AgentProductionRolloutSnapshotBindingService? bindingService,
  }) {
    return AgentProductionRolloutLiveStateSource._(
      settingsService,
      roleService,
      bindingService ?? const AgentProductionRolloutSnapshotBindingService(),
    );
  }

  AgentProductionRolloutLiveStateSource._(
    this._settingsService,
    this._roleService,
    this._bindingService,
  );

  final AgentMasterSettingsService? _settingsService;
  final AgentRoleService? _roleService;
  final AgentProductionRolloutSnapshotBindingService _bindingService;

  Future<AgentProductionRolloutSnapshot> readLiveSnapshot({
    required DateTime capturedAtUtc,
    required String phase65SafetyEvidenceSha256,
    required String phase62VersionEvidenceSha256,
  }) async {
    final AgentMasterSettingsService settingsService =
        _settingsService ?? AgentMasterSettingsService();
    final AgentRoleService roleService = _roleService ?? AgentRoleService();

    final settings = await settingsService.getSettings();
    final roles = await roleService.getAllRoles();

    return _bindingService.bind(
      settings: settings,
      roles: roles,
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65SafetyEvidenceSha256,
      phase62VersionEvidenceSha256: phase62VersionEvidenceSha256,
    );
  }

  bool get readOnly => true;
  bool get writesMasterSettings => false;
  bool get writesRoles => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get changesAgentMode => false;
  bool get activatesRollout => false;
  bool get callsProvider => false;
  bool get writesBusinessData => false;
}
