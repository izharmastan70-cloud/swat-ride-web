import '../constants/agent_module_connector_constants.dart';

// =========================================================
// AI AGENT — MODULE CONNECTOR DESCRIPTOR
// =========================================================
//
// Describes a future SWAT RIDE module bridge.
// Phase 13 does not connect any real business collection/service.

class AgentModuleConnectorDescriptor {
  final String connectorId;
  final String module;
  final String status;
  final bool enabled;
  final bool readOnlyFirst;
  final bool requiresRealModuleAudit;
  final List<String> plannedReadActionIds;
  final List<String> plannedWriteActionIds;
  final String notes;

  const AgentModuleConnectorDescriptor({
    required this.connectorId,
    required this.module,
    required this.status,
    required this.enabled,
    required this.readOnlyFirst,
    required this.requiresRealModuleAudit,
    required this.plannedReadActionIds,
    required this.plannedWriteActionIds,
    required this.notes,
  });

  bool get connected =>
      status != AgentModuleConnectorStatus.notConnected &&
      status != AgentModuleConnectorStatus.disabled;

  void validate() {
    if (connectorId.trim().isEmpty) {
      throw const AgentModuleConnectorValidationException(
        'connectorId cannot be empty.',
      );
    }

    if (!AgentModuleId.isValid(module)) {
      throw AgentModuleConnectorValidationException(
        'Unknown module "$module".',
      );
    }

    if (!AgentModuleConnectorStatus.isValid(status)) {
      throw AgentModuleConnectorValidationException(
        'Unknown connector status "$status".',
      );
    }
  }
}

class AgentModuleConnectorValidationException implements Exception {
  final String message;

  const AgentModuleConnectorValidationException(this.message);

  @override
  String toString() =>
      'AgentModuleConnectorValidationException: $message';
}
