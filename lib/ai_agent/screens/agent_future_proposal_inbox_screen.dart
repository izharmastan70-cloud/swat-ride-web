import 'package:flutter/material.dart';

import '../constants/agent_future_proposal_constants.dart';
import '../models/agent_future_proposal.dart';
import '../services/agent_approval_service.dart';
import '../services/agent_future_proposal_repository.dart';
import '../services/agent_future_proposal_review_service.dart';
import '../services/agent_future_quality_workflow_coordinator.dart';

/// Super Admin Phase 41 Future Proposal Inbox.
///
/// UI never writes Firestore directly. All persistence, approval and edit
/// transitions route through the dedicated services.
class AgentFutureProposalInboxScreen extends StatefulWidget {
  const AgentFutureProposalInboxScreen({
    super.key,
    required this.currentAdminId,
  });

  final String currentAdminId;

  @override
  State<AgentFutureProposalInboxScreen> createState() =>
      _AgentFutureProposalInboxScreenState();
}

class _AgentFutureProposalInboxScreenState
    extends State<AgentFutureProposalInboxScreen> {
  final AgentFutureProposalRepository _repository =
      AgentFutureProposalRepository();

  final AgentFutureProposalReviewService _reviewService =
      AgentFutureProposalReviewService();

  final AgentApprovalService _approvalService = AgentApprovalService();

  final AgentFutureQualityWorkflowCoordinator _qualityWorkflow =
      AgentFutureQualityWorkflowCoordinator();
  final Set<String> _busyProposalIds = <String>{};

  String get _adminId => widget.currentAdminId.trim();

  bool _isBusy(String proposalId) => _busyProposalIds.contains(proposalId);

  void _setBusy(String proposalId, bool value) {
    if (!mounted) return;

    setState(() {
      if (value) {
        _busyProposalIds.add(proposalId);
      } else {
        _busyProposalIds.remove(proposalId);
      }
    });
  }

  void _message(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade800 : null,
      ),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<AgentFutureProposal> _ensureApprovalRequest(
    AgentFutureProposal proposal,
  ) async {
    if (proposal.superAdminApprovalId.trim().isNotEmpty) {
      return proposal;
    }

    final AgentFutureProposal submitted = await _reviewService
        .submitForSuperAdminApproval(
          proposal: proposal,
          reviewerId: _adminId,
          reviewNote: 'Future Proposal Inbox review by Super Admin.',
        );

    await _repository.saveTransition(
      proposal: submitted,
      expectedPreviousUpdatedAt: proposal.updatedAt,
    );

    return submitted;
  }

  Future<void> _approve(AgentFutureProposal proposal) async {
    if (_adminId.isEmpty) {
      _message('Current Super Admin identity is missing.', error: true);
      return;
    }

    if (proposal.status != AgentFutureProposalStatus.awaitingReview) {
      _message('Only AWAITING_REVIEW proposals can be approved.', error: true);
      return;
    }

    final bool confirmed = await _confirm(
      title: 'Approve Future Proposal?',
      message:
          'This approves only this exact proposal scope. '
          'It does NOT execute Code Agent, modify source code, '
          'or deploy anything.',
      actionLabel: 'APPROVE',
    );

    if (!confirmed) return;

    _setBusy(proposal.proposalId, true);

    try {
      final AgentFutureProposal submitted = await _ensureApprovalRequest(
        proposal,
      );

      await _approvalService.approve(
        approvalId: submitted.superAdminApprovalId,
        decidedBy: _adminId,
        note: 'Approved from Future Proposal Inbox.',
      );

      final AgentFutureProposal approved = await _reviewService
          .syncSuperAdminDecision(proposal: submitted);

      await _repository.saveTransition(
        proposal: approved,
        expectedPreviousUpdatedAt: submitted.updatedAt,
      );

      _message('Proposal approved. Code Agent has NOT been invoked.');
    } catch (error) {
      _message('Approval failed: $error', error: true);
    } finally {
      _setBusy(proposal.proposalId, false);
    }
  }

  Future<void> _reject(AgentFutureProposal proposal) async {
    if (_adminId.isEmpty) {
      _message('Current Super Admin identity is missing.', error: true);
      return;
    }

    if (proposal.status != AgentFutureProposalStatus.awaitingReview) {
      _message('Only AWAITING_REVIEW proposals can be rejected.', error: true);
      return;
    }

    final String? note = await _promptText(
      title: 'Reject Future Proposal',
      label: 'Reason',
      initialValue: proposal.reviewNote,
      requiredValue: true,
    );

    if (note == null) return;

    _setBusy(proposal.proposalId, true);

    try {
      final AgentFutureProposal submitted = await _ensureApprovalRequest(
        proposal,
      );

      await _approvalService.reject(
        approvalId: submitted.superAdminApprovalId,
        decidedBy: _adminId,
        note: note,
      );

      final AgentFutureProposal rejected = await _reviewService
          .syncSuperAdminDecision(proposal: submitted);

      await _repository.saveTransition(
        proposal: rejected,
        expectedPreviousUpdatedAt: submitted.updatedAt,
      );

      _message('Proposal rejected.');
    } catch (error) {
      _message('Reject failed: $error', error: true);
    } finally {
      _setBusy(proposal.proposalId, false);
    }
  }

  Future<void> _edit(AgentFutureProposal proposal) async {
    if (_adminId.isEmpty) {
      _message('Current Super Admin identity is missing.', error: true);
      return;
    }

    if (proposal.status != AgentFutureProposalStatus.awaitingReview &&
        proposal.status != AgentFutureProposalStatus.needsEdit) {
      _message('Only review/edit-state proposals can be edited.', error: true);
      return;
    }

    final _FutureProposalEditDraft? draft = await _showEditDialog(proposal);

    if (draft == null) return;

    _setBusy(proposal.proposalId, true);

    try {
      AgentFutureProposal editState = proposal;

      if (proposal.status != AgentFutureProposalStatus.needsEdit) {
        editState = await _reviewService.requestEdit(
          proposal: proposal,
          reviewerId: _adminId,
          reviewNote:
              'Super Admin requested proposal edit from Future Proposal Inbox.',
        );

        await _repository.saveTransition(
          proposal: editState,
          expectedPreviousUpdatedAt: proposal.updatedAt,
        );
      }

      final AgentFutureProposal revised = _reviewService.applyEdit(
        proposal: editState,
        editorId: _adminId,
        problem: draft.problem,
        affectedModule: draft.affectedModule,
        proposedSolution: draft.proposedSolution,
        expectedBenefit: draft.expectedBenefit,
        risk: draft.risk,
        developmentComplexity: draft.developmentComplexity,
        affectedFiles: draft.affectedFiles,
        affectedModules: draft.affectedModules,
        aiConfidence: draft.aiConfidence,
        reviewNote:
            'Edited by Super Admin. Fresh exact-scope approval required.',
      );

      await _repository.saveTransition(
        proposal: revised,
        expectedPreviousUpdatedAt: editState.updatedAt,
      );

      _message(
        'Proposal edited. Previous pending approval was invalidated; '
        'fresh approval is required.',
      );
    } catch (error) {
      _message('Edit failed: $error', error: true);
    } finally {
      _setBusy(proposal.proposalId, false);
    }
  }

  Future<void> _sync(AgentFutureProposal proposal) async {
    if (proposal.superAdminApprovalId.trim().isEmpty) {
      _message('No central approval is bound to this proposal.');
      return;
    }

    _setBusy(proposal.proposalId, true);

    try {
      final AgentFutureProposal synced = await _reviewService
          .syncSuperAdminDecision(proposal: proposal);

      if (synced.status == proposal.status &&
          synced.superAdminApprovalId == proposal.superAdminApprovalId &&
          synced.reviewNote == proposal.reviewNote &&
          synced.approvedBy == proposal.approvedBy) {
        _message('Proposal approval state is already current.');
        return;
      }

      await _repository.saveTransition(
        proposal: synced,
        expectedPreviousUpdatedAt: proposal.updatedAt,
      );

      _message('Proposal approval state synchronized.');
    } catch (error) {
      _message('Sync failed: $error', error: true);
    } finally {
      _setBusy(proposal.proposalId, false);
    }
  }

  Future<void> _ownerKeep(AgentFutureProposal proposal) async {
    if (_adminId.isEmpty) {
      _message('Current Owner/Super Admin identity is missing.', error: true);
      return;
    }

    if (proposal.status != AgentFutureProposalStatus.ownerDecisionPending) {
      _message(
        'KEEP is available only after strict QA + Security pass.',
        error: true,
      );
      return;
    }

    final String? note = await _promptText(
      title: 'KEEP Future Change',
      label: 'Owner decision note',
      initialValue: '',
      requiredValue: true,
    );

    if (note == null) return;

    final bool confirmed = await _confirm(
      title: 'Confirm KEEP?',
      message:
          'KEEP finalizes this quality lifecycle only. '
          'It does not grant deployment authority or expand Code Agent scope.',
      actionLabel: 'KEEP',
    );

    if (!confirmed) return;

    _setBusy(proposal.proposalId, true);

    try {
      await _qualityWorkflow.ownerKeep(
        proposalId: proposal.proposalId,
        ownerId: _adminId,
        note: note,
      );

      _message('Owner KEEP recorded.');
    } catch (error) {
      _message('KEEP failed: $error', error: true);
    } finally {
      _setBusy(proposal.proposalId, false);
    }
  }

  Future<void> _ownerRollback(AgentFutureProposal proposal) async {
    if (_adminId.isEmpty) {
      _message('Current Owner/Super Admin identity is missing.', error: true);
      return;
    }

    final bool eligible =
        proposal.status == AgentFutureProposalStatus.qaFailed ||
        proposal.status == AgentFutureProposalStatus.securityRejected ||
        proposal.status == AgentFutureProposalStatus.ownerDecisionPending;

    if (!eligible) {
      _message('ROLLBACK is unavailable from ${proposal.status}.', error: true);
      return;
    }

    final String? note = await _promptText(
      title: 'ROLLBACK Future Change',
      label: 'Owner rollback reason',
      initialValue: '',
      requiredValue: true,
    );

    if (note == null) return;

    final bool confirmed = await _confirm(
      title: 'Request ROLLBACK?',
      message:
          'This records ROLLBACK_REQUESTED first. '
          'Actual restore requires the exact Code Agent backup, '
          'and ROLLED_BACK is saved only after restore succeeds.',
      actionLabel: 'ROLLBACK',
    );

    if (!confirmed) return;

    _setBusy(proposal.proposalId, true);

    try {
      await _qualityWorkflow.ownerRollbackRequest(
        proposalId: proposal.proposalId,
        ownerId: _adminId,
        note: note,
      );

      _message(
        'ROLLBACK requested. Exact Code Agent backup restore is required '
        'before ROLLED_BACK can be recorded.',
      );
    } catch (error) {
      _message('ROLLBACK request failed: $error', error: true);
    } finally {
      _setBusy(proposal.proposalId, false);
    }
  }

  Future<String?> _promptText({
    required String title,
    required String label,
    required String initialValue,
    required bool requiredValue,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: initialValue,
    );

    try {
      return await showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 2,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () {
                final String value = controller.text.trim();

                if (requiredValue && value.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<_FutureProposalEditDraft?> _showEditDialog(
    AgentFutureProposal proposal,
  ) async {
    final TextEditingController problem = TextEditingController(
      text: proposal.problem,
    );

    final TextEditingController module = TextEditingController(
      text: proposal.affectedModule,
    );

    final TextEditingController solution = TextEditingController(
      text: proposal.proposedSolution,
    );

    final TextEditingController benefit = TextEditingController(
      text: proposal.expectedBenefit,
    );

    final TextEditingController files = TextEditingController(
      text: proposal.affectedFiles.join('\n'),
    );

    final TextEditingController modules = TextEditingController(
      text: proposal.affectedModules.join('\n'),
    );

    final TextEditingController confidence = TextEditingController(
      text: proposal.aiConfidence.toStringAsFixed(2),
    );

    String risk = proposal.risk;
    String complexity = proposal.developmentComplexity;

    try {
      return await showDialog<_FutureProposalEditDraft>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return AlertDialog(
                title: const Text('Edit Future Proposal'),
                content: SizedBox(
                  width: 640,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _field(problem, 'Problem', maxLines: 3),
                        _field(module, 'Affected module'),
                        _field(solution, 'Proposed solution', maxLines: 4),
                        _field(benefit, 'Expected benefit', maxLines: 4),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: risk,
                          decoration: const InputDecoration(
                            labelText: 'Risk',
                            border: OutlineInputBorder(),
                          ),
                          items: AgentFutureProposalRisk.values
                              .map(
                                (String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (String? value) {
                            if (value == null) return;
                            setDialogState(() => risk = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: complexity,
                          decoration: const InputDecoration(
                            labelText: 'Development complexity',
                            border: OutlineInputBorder(),
                          ),
                          items: AgentFutureProposalComplexity.values
                              .map(
                                (String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (String? value) {
                            if (value == null) return;
                            setDialogState(() => complexity = value);
                          },
                        ),
                        _field(
                          files,
                          'Affected files (one per line)',
                          maxLines: 5,
                        ),
                        _field(
                          modules,
                          'Affected modules (one per line)',
                          maxLines: 5,
                        ),
                        _field(confidence, 'AI confidence (0.0 - 1.0)'),
                        const SizedBox(height: 8),
                        const Text(
                          'Evidence references and affected counts are '
                          'evidence-derived and cannot be edited here.',
                        ),
                      ],
                    ),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('CANCEL'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final double? confidenceValue = double.tryParse(
                        confidence.text.trim(),
                      );

                      final List<String> fileValues = _lines(files.text);

                      final List<String> moduleValues = _lines(modules.text);

                      if (problem.text.trim().isEmpty ||
                          module.text.trim().isEmpty ||
                          solution.text.trim().isEmpty ||
                          benefit.text.trim().isEmpty ||
                          moduleValues.isEmpty ||
                          confidenceValue == null ||
                          confidenceValue < 0 ||
                          confidenceValue > 1) {
                        return;
                      }

                      Navigator.of(dialogContext).pop(
                        _FutureProposalEditDraft(
                          problem: problem.text.trim(),
                          affectedModule: module.text.trim(),
                          proposedSolution: solution.text.trim(),
                          expectedBenefit: benefit.text.trim(),
                          risk: risk,
                          developmentComplexity: complexity,
                          affectedFiles: fileValues,
                          affectedModules: moduleValues,
                          aiConfidence: confidenceValue,
                        ),
                      );
                    },
                    child: const Text('SAVE EDIT'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      problem.dispose();
      module.dispose();
      solution.dispose();
      benefit.dispose();
      files.dispose();
      modules.dispose();
      confidence.dispose();
    }
  }

  static Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  static List<String> _lines(String value) {
    return value
        .split(RegExp(r'[\r\n,]+'))
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Future Proposal Inbox')),
      body: StreamBuilder<List<AgentFutureProposal>>(
        stream: _repository.watchRecent(limit: 100),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<AgentFutureProposal>> snapshot,
            ) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error loading Future proposals: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final List<AgentFutureProposal> proposals = snapshot.data!;

              if (proposals.isEmpty) {
                return const Center(
                  child: Text(
                    'No Future proposals yet.\n'
                    'Future Agent creates recommendation-only proposals.',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: proposals.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  return _proposalCard(proposals[index]);
                },
              );
            },
      ),
    );
  }

  Widget _proposalCard(AgentFutureProposal proposal) {
    final bool busy = _isBusy(proposal.proposalId);

    final bool reviewable =
        proposal.status == AgentFutureProposalStatus.awaitingReview;

    final bool editable =
        proposal.status == AgentFutureProposalStatus.awaitingReview ||
        proposal.status == AgentFutureProposalStatus.needsEdit;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    proposal.problem,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Chip(label: Text(proposal.status)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Module: ${proposal.affectedModule}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Risk: ${proposal.risk}  Ã¢â‚¬Â¢  '
              'Complexity: ${proposal.developmentComplexity}  Ã¢â‚¬Â¢  '
              'Confidence: '
              '${(proposal.aiConfidence * 100).toStringAsFixed(0)}%',
            ),
            const SizedBox(height: 4),
            Text(
              'Affected users: ${proposal.affectedUserCount}  Ã¢â‚¬Â¢  '
              'Events: ${proposal.affectedEventCount}',
            ),
            const Divider(height: 24),
            const Text(
              'Proposed solution',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(proposal.proposedSolution),
            const SizedBox(height: 10),
            const Text(
              'Expected benefit',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(proposal.expectedBenefit),
            const SizedBox(height: 10),
            Text(
              'Evidence refs: ${proposal.evidenceRefs.length}  Ã¢â‚¬Â¢  '
              'Files: ${proposal.affectedFiles.length}  Ã¢â‚¬Â¢  '
              'Modules: ${proposal.affectedModules.length}',
            ),
            if (proposal.reviewNote.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text('Review note: ${proposal.reviewNote}'),
            ],
            if (proposal.superAdminApprovalId.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'Approval: ${proposal.superAdminApprovalId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (proposal.approvedBy.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'Approved by: ${proposal.approvedBy}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            if (busy)
              const LinearProgressIndicator()
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (reviewable)
                    FilledButton.icon(
                      onPressed: () => _approve(proposal),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('APPROVE'),
                    ),
                  if (reviewable)
                    OutlinedButton.icon(
                      onPressed: () => _reject(proposal),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('REJECT'),
                    ),
                  if (editable)
                    OutlinedButton.icon(
                      onPressed: () => _edit(proposal),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('EDIT'),
                    ),
                  if (proposal.superAdminApprovalId.trim().isNotEmpty &&
                      reviewable)
                    TextButton.icon(
                      onPressed: () => _sync(proposal),
                      icon: const Icon(Icons.sync),
                      label: const Text('SYNC APPROVAL'),
                    ),
                  if (proposal.status ==
                      AgentFutureProposalStatus.ownerDecisionPending)
                    FilledButton.icon(
                      onPressed: () => _ownerKeep(proposal),
                      icon: const Icon(Icons.done_all_rounded),
                      label: const Text('KEEP'),
                    ),
                  if (proposal.status == AgentFutureProposalStatus.qaFailed ||
                      proposal.status ==
                          AgentFutureProposalStatus.securityRejected ||
                      proposal.status ==
                          AgentFutureProposalStatus.ownerDecisionPending)
                    OutlinedButton.icon(
                      onPressed: () => _ownerRollback(proposal),
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('ROLLBACK'),
                    ),
                  if (proposal.status ==
                      AgentFutureProposalStatus.rollbackRequested)
                    const Chip(label: Text('ROLLBACK REQUESTED')),
                ],
              ),
            const SizedBox(height: 12),
            const Text(
              'Approval only authorizes this proposal scope. '
              'Code Agent execution remains a separate Phase 41-F gate.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class _FutureProposalEditDraft {
  const _FutureProposalEditDraft({
    required this.problem,
    required this.affectedModule,
    required this.proposedSolution,
    required this.expectedBenefit,
    required this.risk,
    required this.developmentComplexity,
    required this.affectedFiles,
    required this.affectedModules,
    required this.aiConfidence,
  });

  final String problem;
  final String affectedModule;
  final String proposedSolution;
  final String expectedBenefit;
  final String risk;
  final String developmentComplexity;
  final List<String> affectedFiles;
  final List<String> affectedModules;
  final double aiConfidence;
}
