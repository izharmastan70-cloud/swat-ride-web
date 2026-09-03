import '../constants/agent_module_connector_constants.dart';
import '../models/agent_module_connector_descriptor.dart';
import 'agent_module_connector_registry.dart';

// =========================================================
// AI AGENT — MODULE CONNECTOR PREFLIGHT
// =========================================================
//
// Pure safety check before any future module connector is used.

class AgentModuleConnectorPreflight {
  const AgentModuleConnectorPreflight();

  AgentModuleConnectorPreflightResult evaluate({
    required String module,
    required bool writeRequested,
  }) {
    final AgentModuleConnectorDescriptor? descriptor =
        AgentModuleConnectorRegistry.get(module);

    if (descriptor == null) {
      return AgentModuleConnectorPreflightResult.deny(
        'Unknown module connector.',
      );
    }

    if (!descriptor.enabled ||
        descriptor.status == AgentModuleConnectorStatus.disabled) {
      return AgentModuleConnectorPreflightResult.deny(
        'Module connector is disabled.',
      );
    }

    if (descriptor.status == AgentModuleConnectorStatus.notConnected) {
      return AgentModuleConnectorPreflightResult.deny(
        'Module connector is not connected yet.',
      );
    }

    if (writeRequested &&
        descriptor.status != AgentModuleConnectorStatus.writeReady) {
      return AgentModuleConnectorPreflightResult.deny(
        'Module connector is not write-ready.',
      );
    }

    if (!writeRequested &&
        descriptor.status != AgentModuleConnectorStatus.readOnlyReady &&
        descriptor.status != AgentModuleConnectorStatus.writeReady &&
        descriptor.status != AgentModuleConnectorStatus.monitorReady) {
      return AgentModuleConnectorPreflightResult.deny(
        'Module connector is not read/monitor-ready.',
      );
    }

    return const AgentModuleConnectorPreflightResult(
      allowed: true,
      reason: 'Module connector preflight passed.',
    );
  }
}

class AgentModuleConnectorPreflightResult {
  final bool allowed;
  final String reason;

  const AgentModuleConnectorPreflightResult({
    required this.allowed,
    required this.reason,
  });

  factory AgentModuleConnectorPreflightResult.deny(String reason) {
    return AgentModuleConnectorPreflightResult(
      allowed: false,
      reason: reason,
    );
  }
}
