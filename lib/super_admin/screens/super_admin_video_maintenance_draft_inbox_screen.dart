import 'package:flutter/material.dart';

import '../../help/models/help_video_maintenance_draft_record.dart';
import '../services/super_admin_video_maintenance_draft_service.dart';

class SuperAdminVideoMaintenanceDraftInboxScreen extends StatefulWidget {
  const SuperAdminVideoMaintenanceDraftInboxScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<SuperAdminVideoMaintenanceDraftInboxScreen> createState() =>
      _SuperAdminVideoMaintenanceDraftInboxScreenState();
}

class _SuperAdminVideoMaintenanceDraftInboxScreenState
    extends State<SuperAdminVideoMaintenanceDraftInboxScreen> {
  final _service = SuperAdminVideoMaintenanceDraftService();

  Future<bool> _confirm(String title, String message, String button) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(button),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _approve(HelpVideoMaintenanceDraftRecord draft) async {
    final ok = await _confirm(
      'Approve maintenance draft?',
      'This approves only the draft package. '
          'It DOES NOT publish a production tutorial.',
      'Approve draft',
    );

    if (!ok || !mounted) {
      return;
    }

    try {
      await _service.approveDraft(
        draftId: draft.id,
        reviewerId: widget.adminId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Draft approved. Production publishing remains blocked.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Approval failed: $error')));
    }
  }

  Future<void> _reject(HelpVideoMaintenanceDraftRecord draft) async {
    final ok = await _confirm(
      'Reject maintenance draft?',
      'Existing approved tutorial remains unchanged.',
      'Reject draft',
    );

    if (!ok || !mounted) {
      return;
    }

    try {
      await _service.rejectDraft(
        draftId: draft.id,
        reviewerId: widget.adminId,
        reason: 'Rejected from Video Maintenance Approval Inbox.',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance draft rejected.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rejection failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Maintenance Approval Inbox')),
      body: StreamBuilder<List<HelpVideoMaintenanceDraftRecord>>(
        stream: _service.watchDrafts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load drafts: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final drafts = snapshot.data!;

          if (drafts.isEmpty) {
            return const Center(child: Text('No video maintenance drafts.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: drafts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final draft = drafts[index];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        draft.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text('${draft.module} / ${draft.feature}'),
                      Text(
                        'App ${draft.targetAppVersion} | '
                        'Video ${draft.baseVideoVersion} -> '
                        '${draft.proposedVideoVersion}',
                      ),
                      Text('Status: ${draft.reviewStatus}'),
                      const SizedBox(height: 8),
                      Text(draft.changeSummary),
                      if (draft.needsExtraReview) ...<Widget>[
                        const SizedBox(height: 8),
                        const Text(
                          'EXTRA HUMAN REVIEW REQUIRED',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(draft.extraReviewReasons.join(', ')),
                      ],
                      const SizedBox(height: 8),
                      const Text(
                        'Approval here never auto-publishes '
                        'a production tutorial.',
                      ),
                      if (draft.isPending) ...<Widget>[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: <Widget>[
                            FilledButton(
                              onPressed: () => _approve(draft),
                              child: const Text('APPROVE DRAFT'),
                            ),
                            OutlinedButton(
                              onPressed: () => _reject(draft),
                              child: const Text('REJECT'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
