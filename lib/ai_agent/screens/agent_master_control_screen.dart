import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'agent_production_rollout_monitor_activation_screen.dart';
import 'agent_roles_screen.dart';

import 'admin_intelligence_report_screen.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_protected_retention_execution_settings.dart';
import '../models/agent_website_deployment_activation_settings.dart';
import '../services/agent_emergency_stop_service.dart';
import '../services/agent_master_settings_service.dart';
import '../services/agent_protected_retention_execution_management_service.dart';
import '../services/agent_protected_retention_execution_settings_service.dart';
import '../services/agent_website_deployment_activation_settings_service.dart';

// =========================================================
// AI AGENT ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â MASTER CONTROL SCREEN
// =========================================================
//
// Standalone Phase 5 screen.
// Not wired into main.dart.
// Existing SWAT RIDE modules are not connected.

class AgentMasterControlScreen extends StatefulWidget {
  final String currentAdminId;

  const AgentMasterControlScreen({super.key, required this.currentAdminId});

  @override
  State<AgentMasterControlScreen> createState() =>
      _AgentMasterControlScreenState();
}

class _AgentMasterControlScreenState extends State<AgentMasterControlScreen> {
  final AgentMasterSettingsService _settingsService =
      AgentMasterSettingsService();

  final AgentEmergencyStopService _emergencyService =
      AgentEmergencyStopService();

  final AgentProtectedRetentionExecutionSettingsService
  _protectedRetentionSettingsService =
      AgentProtectedRetentionExecutionSettingsService(
        firestore: FirebaseFirestore.instance,
      );

  late final AgentProtectedRetentionExecutionManagementService
  _protectedRetentionManagementService =
      AgentProtectedRetentionExecutionManagementService(
        settingsService: _protectedRetentionSettingsService,
      );

  final AgentWebsiteDeploymentActivationSettingsService
  _websiteDeploymentService = AgentWebsiteDeploymentActivationSettingsService();

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<String?> _askDeploymentReason({required String title}) async {
    final TextEditingController controller = TextEditingController();

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Owner/Admin reason required',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final String reason = controller.text.trim();

                if (reason.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(reason);
              },
              child: const Text('CONFIRM'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  Future<bool> _confirmLiveActivation() async {
    final bool? approved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Approve Live Deployment Authority?'),
          content: const Text(
            'This records Owner/Admin live activation approval intent. '
            'It does not itself execute Git push or Vercel deployment.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('APPROVE'),
            ),
          ],
        );
      },
    );

    return approved ?? false;
  }

  Future<void> _setWebsiteDeploymentEnabled(bool enabled) async {
    final String? reason = await _askDeploymentReason(
      title: enabled
          ? 'Enable Website Deployment Control'
          : 'Disable Website Deployment Control',
    );

    if (reason == null || reason.isEmpty) {
      return;
    }

    await _run(
      () => _websiteDeploymentService.setDeploymentEnabled(
        enabled: enabled,
        actorId: widget.currentAdminId,
        reason: reason,
      ),
    );
  }

  Future<void> _setGitProviderEnabled(bool enabled) async {
    final String? reason = await _askDeploymentReason(
      title: enabled
          ? 'Enable Git-connected Provider'
          : 'Disable Git-connected Provider',
    );

    if (reason == null || reason.isEmpty) {
      return;
    }

    await _run(
      () => _websiteDeploymentService.setGitConnectedProviderEnabled(
        enabled: enabled,
        actorId: widget.currentAdminId,
        reason: reason,
      ),
    );
  }

  Future<void> _setLiveActivationApproved(bool approved) async {
    if (approved) {
      final bool confirmed = await _confirmLiveActivation();

      if (!confirmed) {
        return;
      }
    }

    final String? reason = await _askDeploymentReason(
      title: approved
          ? 'Live Activation Approval Reason'
          : 'Revoke Live Activation Approval',
    );

    if (reason == null || reason.isEmpty) {
      return;
    }

    await _run(
      () => _websiteDeploymentService.setLiveActivationApproved(
        approved: approved,
        actorId: widget.currentAdminId,
        reason: reason,
      ),
    );
  }

  Future<void> _setWebsiteEmergencyBlocked(bool blocked) async {
    final String? reason = await _askDeploymentReason(
      title: blocked
          ? 'Emergency Block Website Deployment'
          : 'Release Website Deployment Emergency Block',
    );

    if (reason == null || reason.isEmpty) {
      return;
    }

    await _run(
      () => _websiteDeploymentService.setEmergencyBlocked(
        blocked: blocked,
        actorId: widget.currentAdminId,
        reason: reason,
      ),
    );
  }

  Future<String?> _askProtectedRetentionReason({required String title}) async {
    final TextEditingController controller = TextEditingController();

    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason',
              hintText: 'Minimum 10 characters required',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                final String reason = controller.text.trim();

                if (reason.length < 10) {
                  return;
                }

                Navigator.of(dialogContext).pop(reason);
              },
              child: const Text('CONFIRM'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _setProtectedRetentionMaster(bool enabled) async {
    final String? reason = await _askProtectedRetentionReason(
      title: enabled
          ? 'Enable Protected Retention Execution'
          : 'Disable Protected Retention Execution',
    );

    if (reason == null) {
      return;
    }

    await _run(() async {
      await _protectedRetentionManagementService.setMasterExecution(
        ownerId: widget.currentAdminId,
        enabled: enabled,
        reason: reason,
      );

      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _setProtectedDeletionPolicy(bool enabled) async {
    final String? reason = await _askProtectedRetentionReason(
      title: enabled
          ? 'Enable Protected Deletion Policy Gate'
          : 'Disable Protected Deletion Policy Gate',
    );

    if (reason == null) {
      return;
    }

    await _run(() async {
      await _protectedRetentionManagementService.setProtectedDeletion(
        ownerId: widget.currentAdminId,
        enabled: enabled,
        reason: reason,
      );

      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _setProtectedRetentionEmergency(bool active) async {
    final String? reason = await _askProtectedRetentionReason(
      title: active
          ? 'Activate Protected Retention Emergency Stop'
          : 'Release Protected Retention Emergency Stop',
    );

    if (reason == null) {
      return;
    }

    await _run(() async {
      await _protectedRetentionManagementService.setEmergencyStop(
        ownerId: widget.currentAdminId,
        active: active,
        reason: reason,
      );

      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _emergencyDisableProtectedRetention() async {
    final String? reason = await _askProtectedRetentionReason(
      title: 'Emergency Disable All Protected Retention Execution',
    );

    if (reason == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Emergency Disable All?'),
          content: const Text(
            'This activates the protected-retention Emergency Stop and '
            'turns Master Execution and Protected Deletion policy OFF. '
            'It does not delete any protected record.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('EMERGENCY DISABLE'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _run(() async {
      await _protectedRetentionManagementService.emergencyDisableAll(
        ownerId: widget.currentAdminId,
        reason: reason,
      );

      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<bool> _confirmMasterControlChange({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _setPaidReasoningEnabled(bool enabled) async {
    final bool confirmed = await _confirmMasterControlChange(
      title: enabled ? 'Enable Paid Reasoning?' : 'Disable Paid Reasoning?',
      message: enabled
          ? 'Generic Paid Reasoning is a last-escalation paid lane. Positive per-task, daily and monthly Rs limits must already be configured. This does not enable Paid Code AI.'
          : 'This stops new generic Paid Reasoning use. Free/Local AI and Paid Code AI controls remain separate.',
      confirmLabel: enabled ? 'ENABLE' : 'DISABLE',
    );

    if (!confirmed) return;

    await _run(
      () => _settingsService.setPaidReasoningEnabled(
        enabled: enabled,
        actorId: widget.currentAdminId,
      ),
    );
  }

  Future<void> _setAskBeforePaid(bool enabled) async {
    final bool confirmed = await _confirmMasterControlChange(
      title: enabled ? 'Enable Ask Before Paid?' : 'Disable Ask Before Paid?',
      message: enabled
          ? 'Owner approval will be required before generic Paid Reasoning is used.'
          : 'Generic Paid Reasoning may proceed without this extra paid-provider prompt when all other Permission, Approval, Runtime Gate and budget rules allow it. Existing high-risk approval authority is not disabled.',
      confirmLabel: enabled ? 'ENABLE' : 'DISABLE',
    );

    if (!confirmed) return;

    await _run(
      () => _settingsService.setAskBeforePaid(
        enabled: enabled,
        actorId: widget.currentAdminId,
      ),
    );
  }

  Future<void> _setAuditLoggingEnabled(bool enabled) async {
    final bool confirmed = await _confirmMasterControlChange(
      title: enabled
          ? 'Enable Audit Logging Preference?'
          : 'Disable Optional Audit Logging Preference?',
      message: enabled
          ? 'Optional/verbose audit logging preference will be enabled.'
          : 'Only the optional/verbose preference is disabled. Protected security, approval, task, provider and other mandatory audit evidence remains enforced.',
      confirmLabel: enabled ? 'ENABLE' : 'DISABLE',
    );

    if (!confirmed) return;

    await _run(
      () => _settingsService.setAuditLoggingEnabled(
        enabled: enabled,
        actorId: widget.currentAdminId,
      ),
    );
  }

  Future<void> _editPaidReasoningLimits(AgentMasterSettings settings) async {
    final TextEditingController perTaskController = TextEditingController(
      text: settings.paidReasoningPerTaskLimitRs.toString(),
    );
    final TextEditingController dailyController = TextEditingController(
      text: settings.paidReasoningDailyLimitRs.toString(),
    );
    final TextEditingController monthlyController = TextEditingController(
      text: settings.paidReasoningMonthlyLimitRs.toString(),
    );

    final Map<String, String>? values = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Paid Reasoning Rs Limits'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: perTaskController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Per-task limit (Rs)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dailyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Daily limit (Rs)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: monthlyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monthly limit (Rs)',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Rs 0 keeps the corresponding limit unconfigured while Paid Reasoning is OFF. All three limits must be positive before Paid Reasoning can be enabled.',
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(<String, String>{
                'perTask': perTaskController.text.trim(),
                'daily': dailyController.text.trim(),
                'monthly': monthlyController.text.trim(),
              }),
              child: const Text('SAVE LIMITS'),
            ),
          ],
        );
      },
    );

    perTaskController.dispose();
    dailyController.dispose();
    monthlyController.dispose();

    if (!mounted || values == null) return;

    final int? perTask = int.tryParse(values['perTask'] ?? '');
    final int? daily = int.tryParse(values['daily'] ?? '');
    final int? monthly = int.tryParse(values['monthly'] ?? '');

    if (perTask == null ||
        daily == null ||
        monthly == null ||
        perTask < 0 ||
        daily < 0 ||
        monthly < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter valid non-negative whole-number Rs limits.'),
        ),
      );
      return;
    }

    final bool confirmed = await _confirmMasterControlChange(
      title: 'Save Paid Reasoning Limits?',
      message:
          'Per-task: Rs $perTask\nDaily: Rs $daily\nMonthly: Rs $monthly\n\nThese limits apply only to generic Paid Reasoning and never change the Paid Code AI budget.',
      confirmLabel: 'SAVE',
    );

    if (!confirmed) return;

    await _run(
      () => _settingsService.setPaidReasoningLimits(
        perTaskLimitRs: perTask,
        dailyLimitRs: daily,
        monthlyLimitRs: monthly,
        actorId: widget.currentAdminId,
      ),
    );
  }

  Future<void> _activateEmergency() async {
    await _run(
      () => _emergencyService.activate(
        actorId: widget.currentAdminId,
        reason: 'Manual Emergency Stop from AI Master Control.',
      ),
    );
  }

  Future<void> _releaseEmergency() async {
    await _run(
      () => _emergencyService.release(
        actorId: widget.currentAdminId,
        reason: 'Owner/Admin manually released Emergency Stop.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('AI Master Control'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Agent Roles',
            icon: const Icon(Icons.manage_accounts_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const AgentRolesScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Production Rollout',
            icon: const Icon(Icons.rocket_launch_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) =>
                      AgentProductionRolloutMonitorActivationScreen(
                        currentAdminId: widget.currentAdminId,
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<AgentMasterSettings>(
        stream: _settingsService.watchSettings(),
        builder: (BuildContext context, AsyncSnapshot<AgentMasterSettings> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Settings error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final AgentMasterSettings settings =
              snapshot.data ?? AgentMasterSettings.safeDefaults();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _SwitchCard(
                title: 'AI MASTER',
                subtitle: 'Global AI control plane switch.',
                value: settings.masterEnabled,
                onChanged: (bool value) => _run(
                  () => _settingsService.setMasterEnabled(
                    enabled: value,
                    actorId: widget.currentAdminId,
                  ),
                ),
              ),
              _SwitchCard(
                title: 'FREE AI',
                subtitle: 'Routine business/ops AI provider class.',
                value: settings.freeAiEnabled,
                onChanged: (bool value) => _run(
                  () => _settingsService.setFreeAiEnabled(
                    enabled: value,
                    actorId: widget.currentAdminId,
                  ),
                ),
              ),
              _SwitchCard(
                title: 'LOCAL AI',
                subtitle: 'Future private/local AI provider class.',
                value: settings.localAiEnabled,
                onChanged: (bool value) => _run(
                  () => _settingsService.setLocalAiEnabled(
                    enabled: value,
                    actorId: widget.currentAdminId,
                  ),
                ),
              ),
              _SwitchCard(
                title: 'PAID CODE AI',
                subtitle: 'Technical/code debugging only.',
                value: settings.paidCodeAiEnabled,
                onChanged: (bool value) => _run(
                  () => _settingsService.setPaidCodeAiEnabled(
                    enabled: value,
                    actorId: widget.currentAdminId,
                  ),
                ),
              ),
              _SwitchCard(
                title: 'EMAIL AGENT',
                subtitle:
                    'Draft/review Email Agent switch. Turning this ON does not enable live provider transport.',
                value: settings.emailAgentEnabled,
                onChanged: (bool value) => _run(
                  () => _settingsService.setEmailAgentEnabled(
                    enabled: value,
                    actorId: widget.currentAdminId,
                  ),
                ),
              ),
              _SwitchCard(
                title: 'CALL AGENT',
                subtitle: 'Conversation/call automation master switch.',
                value: settings.callAgentEnabled,
                onChanged: (bool value) => _run(
                  () => _settingsService.setCallAgentEnabled(
                    enabled: value,
                    actorId: widget.currentAdminId,
                  ),
                ),
              ),
              _SwitchCard(
                title: 'APPROVAL ENGINE',
                subtitle: 'Required for ASK_FIRST/high-risk actions.',
                value: settings.approvalEngineEnabled,
                onChanged: (bool value) => _run(
                  () => _settingsService.setApprovalEngineEnabled(
                    enabled: value,
                    actorId: widget.currentAdminId,
                  ),
                ),
              ),
              _SwitchCard(
                title: 'PAID REASONING',
                subtitle:
                    'Generic paid reasoning only. Last escalation after Free/Local. Separate from Paid Code AI.',
                value: settings.paidReasoningEnabled,
                onChanged: _setPaidReasoningEnabled,
              ),
              _SwitchCard(
                title: 'ASK BEFORE PAID',
                subtitle:
                    'Ask owner before generic Paid Reasoning provider use. Other approval/security gates remain authoritative.',
                value: settings.askBeforePaid,
                onChanged: _setAskBeforePaid,
              ),
              _SwitchCard(
                title: 'AUDIT LOGGING PREFERENCE',
                subtitle:
                    'Optional/verbose audit preference. Protected security/approval/task/provider audit remains mandatory.',
                value: settings.auditLoggingEnabled,
                onChanged: _setAuditLoggingEnabled,
              ),
              Card(
                color: const Color(0xFF1A1A1A),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Paid Reasoning Rs Limits',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Per task: Rs ${settings.paidReasoningPerTaskLimitRs}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Daily: Rs ${settings.paidReasoningDailyLimitRs}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Monthly: Rs ${settings.paidReasoningMonthlyLimitRs}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        settings.paidReasoningBudgetConfigured
                            ? 'Paid Reasoning limits configured'
                            : 'Paid Reasoning limits not fully configured',
                        style: TextStyle(
                          color: settings.paidReasoningBudgetConfigured
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _editPaidReasoningLimits(settings),
                        icon: const Icon(Icons.edit),
                        label: const Text('EDIT PAID REASONING LIMITS'),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Paid Code AI budget is separate and is not changed by these limits.',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: const Color(0xFF1A1A1A),
                child: ListTile(
                  leading: const Icon(
                    Icons.analytics_outlined,
                    color: Color(0xFFFFD60A),
                  ),
                  title: const Text(
                    'Admin Intelligence Report',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Read-only verified findings surface. '
                    'No automatic admin action.',
                    style: TextStyle(color: Colors.white54),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) =>
                            const AdminIntelligenceReportScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: const Color(0xFF1A1A1A),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Paid Code AI Budget',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rs ${settings.paidCodeBudgetUsedRs} / '
                        'Rs ${settings.monthlyPaidCodeBudgetRs}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        settings.paidBudgetAvailable
                            ? 'Budget available'
                            : 'Budget unavailable/exhausted',
                        style: TextStyle(
                          color: settings.paidBudgetAvailable
                              ? Colors.greenAccent
                              : Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<AgentWebsiteDeploymentActivationSettings>(
                stream: _websiteDeploymentService.watchSettings(),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<AgentWebsiteDeploymentActivationSettings>
                      deploymentSnapshot,
                    ) {
                      if (deploymentSnapshot.hasError) {
                        return Card(
                          color: const Color(0xFF3A1111),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              'Website deployment settings error: '
                              '${deploymentSnapshot.error}',
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        );
                      }

                      final AgentWebsiteDeploymentActivationSettings
                      deployment =
                          deploymentSnapshot.data ??
                          AgentWebsiteDeploymentActivationSettings.safeDefaults();

                      return Card(
                        color: const Color(0xFF1A1A1A),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'WEBSITE DEPLOYMENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Owner-controlled deployment policy. '
                                'These controls do not directly execute '
                                'Git push or Vercel deployment.',
                                style: TextStyle(color: Colors.white60),
                              ),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Deployment Master',
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: const Text(
                                  'Master policy gate for website deployment.',
                                  style: TextStyle(color: Colors.white54),
                                ),
                                value: deployment.deploymentEnabled,
                                onChanged: _setWebsiteDeploymentEnabled,
                                activeThumbColor: const Color(0xFFFFD60A),
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Git-connected Provider',
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: const Text(
                                  'Requires Deployment Master ON.',
                                  style: TextStyle(color: Colors.white54),
                                ),
                                value: deployment.gitConnectedProviderEnabled,
                                onChanged: deployment.deploymentEnabled
                                    ? _setGitProviderEnabled
                                    : null,
                                activeThumbColor: const Color(0xFFFFD60A),
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Live Activation Approval',
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: const Text(
                                  'Owner/Admin approval intent only. '
                                  'No direct deployment execution here.',
                                  style: TextStyle(color: Colors.white54),
                                ),
                                value: deployment.ownerLiveActivationApproved,
                                onChanged:
                                    deployment.deploymentEnabled &&
                                        deployment
                                            .gitConnectedProviderEnabled &&
                                        !deployment.emergencyBlocked
                                    ? _setLiveActivationApproved
                                    : deployment.ownerLiveActivationApproved
                                    ? _setLiveActivationApproved
                                    : null,
                                activeThumbColor: const Color(0xFFFFD60A),
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Emergency Deployment Block',
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: const Text(
                                  'Immediately revokes live activation '
                                  'approval while blocked.',
                                  style: TextStyle(color: Colors.white54),
                                ),
                                value: deployment.emergencyBlocked,
                                onChanged: _setWebsiteEmergencyBlocked,
                                activeThumbColor: const Color(0xFFFFD60A),
                              ),
                              const Divider(),
                              Text(
                                deployment.deploymentSubsystemReady
                                    ? 'Deployment policy subsystem: READY'
                                    : 'Deployment policy subsystem: NOT READY',
                                style: TextStyle(
                                  color: deployment.deploymentSubsystemReady
                                      ? Colors.greenAccent
                                      : Colors.orangeAccent,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reason: ${deployment.reason}',
                                style: const TextStyle(color: Colors.white60),
                              ),
                              if (deployment.updatedBy.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 4),
                                Text(
                                  'Updated by: ${deployment.updatedBy}',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
              ),
              const SizedBox(height: 12),
              FutureBuilder<AgentProtectedRetentionExecutionSettings>(
                future: _protectedRetentionManagementService.getCurrentSettings(
                  ownerId: widget.currentAdminId,
                ),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<AgentProtectedRetentionExecutionSettings>
                      protectedSnapshot,
                    ) {
                      if (protectedSnapshot.hasError) {
                        return Card(
                          color: const Color(0xFF3A1111),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              'Protected retention settings error: '
                              '${protectedSnapshot.error}',
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        );
                      }

                      if (protectedSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !protectedSnapshot.hasData) {
                        return const Card(
                          color: Color(0xFF1A1A1A),
                          child: Padding(
                            padding: EdgeInsets.all(18),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      final AgentProtectedRetentionExecutionSettings protected =
                          protectedSnapshot.data ??
                          AgentProtectedRetentionExecutionSettings.safeDefaults(
                            ownerId: widget.currentAdminId,
                          );

                      return Card(
                        color: protected.emergencyStopActive
                            ? const Color(0xFF3A1111)
                            : const Color(0xFF1A1A1A),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'PROTECTED RETENTION EXECUTION',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Owner/Super Admin policy controls only. '
                                'These controls do not directly delete protected data.',
                                style: TextStyle(color: Colors.white60),
                              ),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Master Execution',
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: const Text(
                                  'Master policy gate for protected-retention execution.',
                                  style: TextStyle(color: Colors.white54),
                                ),
                                value: protected.masterExecutionEnabled,
                                onChanged: protected.emergencyStopActive
                                    ? null
                                    : _setProtectedRetentionMaster,
                                activeThumbColor: const Color(0xFFFFD60A),
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Protected Deletion Policy',
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: const Text(
                                  'Policy gate only. No record-delete action exists here.',
                                  style: TextStyle(color: Colors.white54),
                                ),
                                value: protected.protectedDeletionEnabled,
                                onChanged:
                                    protected.masterExecutionEnabled &&
                                        !protected.emergencyStopActive
                                    ? _setProtectedDeletionPolicy
                                    : protected.protectedDeletionEnabled
                                    ? _setProtectedDeletionPolicy
                                    : null,
                                activeThumbColor: const Color(0xFFFFD60A),
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Protected Retention Emergency Stop',
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: const Text(
                                  'Blocks protected-retention execution while active.',
                                  style: TextStyle(color: Colors.white54),
                                ),
                                value: protected.emergencyStopActive,
                                onChanged: _setProtectedRetentionEmergency,
                                activeThumbColor: const Color(0xFFFFD60A),
                              ),
                              const Divider(),
                              const Text(
                                'MANDATORY SAFETY GUARDS ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â LOCKED',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _LockedSafetyGuard(
                                label: 'Approval required',
                                enabled: protected.requireApproval,
                              ),
                              _LockedSafetyGuard(
                                label: 'Consumed approval required',
                                enabled: protected.requireConsumedApproval,
                              ),
                              _LockedSafetyGuard(
                                label: 'Explicit final confirmation required',
                                enabled:
                                    protected.requireExplicitFinalConfirmation,
                              ),
                              _LockedSafetyGuard(
                                label: 'Audit trail required',
                                enabled: protected.requireAuditTrail,
                              ),
                              _LockedSafetyGuard(
                                label: 'Super Admin required',
                                enabled: protected.requireSuperAdmin,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _emergencyDisableProtectedRetention,
                                  icon: const Icon(Icons.emergency),
                                  label: const Text('EMERGENCY DISABLE ALL'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                protected.failClosed
                                    ? 'Execution policy state: BLOCKED'
                                    : 'Execution policy gates: OPEN',
                                style: TextStyle(
                                  color: protected.failClosed
                                      ? Colors.orangeAccent
                                      : Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reason: ${protected.reason}',
                                style: const TextStyle(color: Colors.white60),
                              ),
                              if (protected.updatedBy.isNotEmpty) ...<Widget>[
                                const SizedBox(height: 4),
                                Text(
                                  'Updated by: ${protected.updatedBy}',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ],
                              const SizedBox(height: 8),
                              const Text(
                                'Actual protected-record deletion: NOT AVAILABLE '
                                'from this screen.',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
              ),
              const SizedBox(height: 12),
              Card(
                color: settings.emergencyReadOnly
                    ? const Color(0xFF3A1111)
                    : const Color(0xFF1A1A1A),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        settings.emergencyReadOnly
                            ? 'EMERGENCY READ-ONLY ACTIVE'
                            : 'Emergency Stop is not active',
                        style: TextStyle(
                          color: settings.emergencyReadOnly
                              ? Colors.redAccent
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (settings.emergencyReason.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          settings.emergencyReason,
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (!settings.emergencyReadOnly)
                        ElevatedButton.icon(
                          onPressed: _activateEmergency,
                          icon: const Icon(Icons.emergency),
                          label: const Text('ACTIVATE EMERGENCY STOP'),
                        )
                      else
                        OutlinedButton(
                          onPressed: _releaseEmergency,
                          child: const Text('RELEASE EMERGENCY STOP'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LockedSafetyGuard extends StatelessWidget {
  final String label;
  final bool enabled;

  const _LockedSafetyGuard({required this.label, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        enabled ? Icons.lock : Icons.warning_amber_rounded,
        color: enabled ? Colors.greenAccent : Colors.redAccent,
      ),
      title: Text(label, style: const TextStyle(color: Colors.white70)),
      trailing: Text(
        enabled ? 'LOCKED ON' : 'INVALID',
        style: TextStyle(
          color: enabled ? Colors.greenAccent : Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A1A),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFFFFD60A),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      ),
    );
  }
}
