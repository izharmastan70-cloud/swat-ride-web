import 'package:flutter/material.dart';

import '../../help/models/help_video_tutorial_model.dart';
import '../services/super_admin_video_tutorial_service.dart';

import 'super_admin_video_maintenance_draft_inbox_screen.dart';

import 'super_admin_video_analytics_screen.dart';

import 'super_admin_video_training_access_screen.dart';

import 'super_admin_video_navigation_screen.dart';

class SuperAdminVideoTutorialManagementScreen extends StatefulWidget {
  const SuperAdminVideoTutorialManagementScreen({
    super.key,
    required this.adminId,
  });

  final String adminId;

  @override
  State<SuperAdminVideoTutorialManagementScreen> createState() =>
      _SuperAdminVideoTutorialManagementScreenState();
}

class _SuperAdminVideoTutorialManagementScreenState
    extends State<SuperAdminVideoTutorialManagementScreen> {
  final SuperAdminVideoTutorialService _service =
      SuperAdminVideoTutorialService();

  List<String> _splitValues(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  String _joinValues(List<String> values) {
    return values.join(', ');
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _statusChip(String label) {
    return Chip(label: Text(label), visualDensity: VisualDensity.compact);
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openEditor({HelpVideoTutorialModel? tutorial}) async {
    final titleController = TextEditingController(text: tutorial?.title ?? '');

    final descriptionController = TextEditingController(
      text: tutorial?.description ?? '',
    );

    final urlController = TextEditingController(text: tutorial?.videoUrl ?? '');

    final categoryController = TextEditingController(
      text: tutorial?.category ?? 'general',
    );

    final orderController = TextEditingController(
      text: (tutorial?.displayOrder ?? 0).toString(),
    );

    final moduleController = TextEditingController(
      text: tutorial?.module ?? 'general',
    );

    final featureController = TextEditingController(
      text: tutorial?.feature ?? '',
    );

    final languageController = TextEditingController(
      text: tutorial?.language ?? 'und',
    );

    final audienceController = TextEditingController(
      text: tutorial?.audience ?? 'customer',
    );

    final durationController = TextEditingController(
      text: (tutorial?.duration ?? 0).toString(),
    );

    final appVersionController = TextEditingController(
      text: tutorial?.appVersion ?? '',
    );

    final videoVersionController = TextEditingController(
      text: tutorial?.videoVersion ?? '1',
    );

    final keywordsController = TextEditingController(
      text: _joinValues(tutorial?.keywords ?? const <String>[]),
    );

    final intentsController = TextEditingController(
      text: _joinValues(tutorial?.intents ?? const <String>[]),
    );

    final publishedStatusController = TextEditingController(
      text: tutorial?.publishedStatus ?? 'draft',
    );

    final storageReferenceController = TextEditingController(
      text: tutorial?.storageReference ?? '',
    );

    final reviewedByController = TextEditingController(
      text: tutorial?.reviewedBy ?? '',
    );

    final maintenanceSourceController = TextEditingController(
      text: tutorial?.maintenanceSource ?? 'manual',
    );

    final changeSummaryController = TextEditingController(
      text: tutorial?.changeSummary ?? '',
    );

    final supersedesVideoIdController = TextEditingController(
      text: tutorial?.supersedesVideoId ?? '',
    );

    final updateTaskIdController = TextEditingController(
      text: tutorial?.updateTaskId ?? '',
    );

    bool isEnabled = tutorial?.isEnabled ?? false;
    bool outdated = tutorial?.outdated ?? false;
    bool requiresApproval = tutorial?.requiresApproval ?? false;

    try {
      final bool? saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: Text(
                  tutorial == null
                      ? 'Add Video Tutorial'
                      : 'Edit Video Tutorial',
                ),
                content: SizedBox(
                  width: 620,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Text(
                          'Basic Tutorial Details',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),

                        _textField(controller: titleController, label: 'Title'),
                        const SizedBox(height: 12),

                        _textField(
                          controller: descriptionController,
                          label: 'Description',
                          minLines: 2,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: urlController,
                          label: 'HTTPS video URL',
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: categoryController,
                          label: 'Category',
                          hint: 'Ride, Food, Hotel, Safety...',
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: orderController,
                          label: 'Display order',
                          keyboardType: TextInputType.number,
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),

                        const Text(
                          'Advanced Tutorial Metadata',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),

                        const Text(
                          'Used by Help search, Support Agent, '
                          'app-version checks and future automatic '
                          'tutorial maintenance.',
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: moduleController,
                          label: 'Module',
                          hint: 'ride, food, hotel, safety...',
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: featureController,
                          label: 'Feature',
                          hint: 'booking, payment, SOS...',
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: languageController,
                          label: 'Language',
                          hint: 'ur, en, roman_ur, ps...',
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: audienceController,
                          label: 'Audience',
                          hint:
                              'customer, driver, food_rider, partner, admin...',
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: durationController,
                          label: 'Duration (seconds)',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: appVersionController,
                          label: 'App version',
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: videoVersionController,
                          label: 'Video version',
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: keywordsController,
                          label: 'Keywords',
                          hint: 'Comma separated',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: intentsController,
                          label: 'Support intents',
                          hint: 'Comma separated',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: publishedStatusController,
                          label: 'Publication status',
                          hint: 'draft / published / archived',
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: storageReferenceController,
                          label: 'Storage/CDN reference',
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: reviewedByController,
                          label: 'Reviewed by',
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),

                        const Text(
                          'Automatic Tutorial Maintenance',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),

                        const Text(
                          'AI/change detection may prepare an update '
                          'draft, but cannot publish it without '
                          'Owner/Super Admin approval.',
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: maintenanceSourceController,
                          label: 'Maintenance source',
                          hint:
                              'manual / admin_update / agent_change_detection',
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: changeSummaryController,
                          label: 'App/feature change summary',
                          minLines: 2,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: supersedesVideoIdController,
                          label: 'Supersedes video ID',
                        ),
                        const SizedBox(height: 12),

                        _textField(
                          controller: updateTaskIdController,
                          label: 'Update task ID',
                        ),
                        const SizedBox(height: 8),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Requires Owner/Super Admin approval',
                          ),
                          subtitle: const Text(
                            'Required for AI/change-detected drafts.',
                          ),
                          value: requiresApproval,
                          onChanged: (value) {
                            setDialogState(() {
                              requiresApproval = value;

                              if (value) {
                                isEnabled = false;
                              }
                            });
                          },
                        ),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Outdated'),
                          subtitle: const Text(
                            'Outdated videos cannot be publicly recommended.',
                          ),
                          value: outdated,
                          onChanged: (value) {
                            setDialogState(() {
                              outdated = value;

                              if (value) {
                                isEnabled = false;
                              }
                            });
                          },
                        ),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Enabled in public customer library',
                          ),
                          subtitle: const Text(
                            'Only approved, published, current '
                            'customer tutorials can be enabled.',
                          ),
                          value: isEnabled,
                          onChanged: (value) {
                            setDialogState(() {
                              isEnabled = value;
                            });
                          },
                        ),

                        if (tutorial != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(
                                  dialogContext,
                                ).colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Current approval status: '
                              '${tutorial.approvalStatus}\n'
                              'Approved by: '
                              '${tutorial.approvedBy.isEmpty ? "ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â" : tutorial.approvedBy}',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final int? displayOrder = int.tryParse(
                        orderController.text.trim(),
                      );

                      final int? duration = int.tryParse(
                        durationController.text.trim(),
                      );

                      if (displayOrder == null || displayOrder < 0) {
                        _showMessage('Display order must be 0 or greater.');
                        return;
                      }

                      if (duration == null || duration < 0) {
                        _showMessage('Duration must be 0 or greater.');
                        return;
                      }

                      final String publicationStatus = publishedStatusController
                          .text
                          .trim()
                          .toLowerCase();

                      const Set<String> allowedPublicationStates = <String>{
                        'draft',
                        'published',
                        'archived',
                      };

                      if (!allowedPublicationStates.contains(
                        publicationStatus,
                      )) {
                        _showMessage(
                          'Publication status must be '
                          'draft, published, or archived.',
                        );
                        return;
                      }

                      final String maintenanceSource =
                          maintenanceSourceController.text.trim().toLowerCase();

                      if (maintenanceSource == 'agent_change_detection' &&
                          !requiresApproval) {
                        _showMessage(
                          'AI/change-detected tutorial '
                          'must require approval.',
                        );
                        return;
                      }

                      final String audience = audienceController.text
                          .trim()
                          .toLowerCase();

                      final String effectiveStatus =
                          requiresApproval || outdated
                          ? 'draft'
                          : publicationStatus;

                      final bool effectiveEnabled =
                          isEnabled &&
                          !requiresApproval &&
                          !outdated &&
                          audience == 'customer' &&
                          effectiveStatus == 'published';

                      try {
                        if (tutorial == null) {
                          await _service.createTutorial(
                            title: titleController.text,
                            description: descriptionController.text,
                            videoUrl: urlController.text,
                            category: categoryController.text,
                            displayOrder: displayOrder,
                            isEnabled: effectiveEnabled,
                            adminId: widget.adminId,
                            module: moduleController.text,
                            feature: featureController.text,
                            language: languageController.text,
                            audience: audienceController.text,
                            duration: duration,
                            appVersion: appVersionController.text,
                            videoVersion: videoVersionController.text,
                            keywords: _splitValues(keywordsController.text),
                            intents: _splitValues(intentsController.text),
                            publishedStatus: effectiveStatus,
                            storageReference: storageReferenceController.text,
                            reviewedBy: reviewedByController.text,
                            outdated: outdated,
                            maintenanceSource: maintenanceSource,
                            changeSummary: changeSummaryController.text,
                            requiresApproval: requiresApproval,
                            supersedesVideoId: supersedesVideoIdController.text,
                            updateTaskId: updateTaskIdController.text,
                          );
                        } else {
                          await _service.updateTutorial(
                            tutorialId: tutorial.id,
                            title: titleController.text,
                            description: descriptionController.text,
                            videoUrl: urlController.text,
                            category: categoryController.text,
                            displayOrder: displayOrder,
                            isEnabled: effectiveEnabled,
                            adminId: widget.adminId,
                          );

                          await _service.updateAdvancedMetadata(
                            tutorialId: tutorial.id,
                            module: moduleController.text,
                            feature: featureController.text,
                            language: languageController.text,
                            audience: audienceController.text,
                            duration: duration,
                            appVersion: appVersionController.text,
                            videoVersion: videoVersionController.text,
                            keywords: _splitValues(keywordsController.text),
                            intents: _splitValues(intentsController.text),
                            publishedStatus: effectiveStatus,
                            storageReference: storageReferenceController.text,
                            reviewedBy: reviewedByController.text,
                            outdated: outdated,
                            maintenanceSource: maintenanceSource,
                            changeSummary: changeSummaryController.text,
                            requiresApproval: requiresApproval,
                            supersedesVideoId: supersedesVideoIdController.text,
                            updateTaskId: updateTaskIdController.text,
                            adminId: widget.adminId,
                            changeDetectedAt: tutorial.changeDetectedAt,
                          );
                        }

                        if (!dialogContext.mounted) {
                          return;
                        }

                        Navigator.of(dialogContext).pop(true);
                      } catch (error) {
                        if (!mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not save tutorial: $error'),
                          ),
                        );
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (saved == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tutorial metadata saved.')),
        );
      }
    } finally {
      titleController.dispose();
      descriptionController.dispose();
      urlController.dispose();
      categoryController.dispose();
      orderController.dispose();
      moduleController.dispose();
      featureController.dispose();
      languageController.dispose();
      audienceController.dispose();
      durationController.dispose();
      appVersionController.dispose();
      videoVersionController.dispose();
      keywordsController.dispose();
      intentsController.dispose();
      publishedStatusController.dispose();
      storageReferenceController.dispose();
      reviewedByController.dispose();
      maintenanceSourceController.dispose();
      changeSummaryController.dispose();
      supersedesVideoIdController.dispose();
      updateTaskIdController.dispose();
    }
  }

  Future<void> _setEnabled(HelpVideoTutorialModel tutorial, bool value) async {
    try {
      await _service.setEnabled(
        tutorialId: tutorial.id,
        isEnabled: value,
        adminId: widget.adminId,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update tutorial: $error')),
      );
    }
  }

  Future<bool> _confirmTutorialAction({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _approveTutorialAction(HelpVideoTutorialModel tutorial) async {
    final bool confirmed = await _confirmTutorialAction(
      title: 'Approve tutorial?',
      message:
          'This approves the reviewed tutorial. '
          'A customer-audience tutorial may become visible '
          'in the public Help Library. Private role training '
          'will remain blocked from the customer library.',
      confirmLabel: 'Approve',
    );

    if (!confirmed || !mounted) {
      return;
    }

    try {
      await _service.approveTutorial(
        tutorialId: tutorial.id,
        adminId: widget.adminId,
      );

      if (!mounted) {
        return;
      }

      _showMessage('Tutorial approved by Super Admin.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Could not approve tutorial: $error');
    }
  }

  Future<void> _rejectTutorialAction(HelpVideoTutorialModel tutorial) async {
    final bool confirmed = await _confirmTutorialAction(
      title: 'Reject tutorial?',
      message:
          'The tutorial will be returned to draft state '
          'and kept disabled. It will not be recommended '
          'to customers.',
      confirmLabel: 'Reject',
    );

    if (!confirmed || !mounted) {
      return;
    }

    try {
      await _service.rejectTutorial(
        tutorialId: tutorial.id,
        adminId: widget.adminId,
      );

      if (!mounted) {
        return;
      }

      _showMessage('Tutorial rejected and disabled.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Could not reject tutorial: $error');
    }
  }

  Future<void> _setOutdatedAction(
    HelpVideoTutorialModel tutorial,
    bool outdated,
  ) async {
    final bool confirmed = await _confirmTutorialAction(
      title: outdated ? 'Mark tutorial outdated?' : 'Mark tutorial current?',
      message: outdated
          ? 'The tutorial will immediately be disabled '
                'from customer recommendations until an '
                'updated version is reviewed.'
          : 'This only removes the outdated flag. '
                'It does not automatically publish or enable '
                'the tutorial.',
      confirmLabel: outdated ? 'Mark outdated' : 'Mark current',
    );

    if (!confirmed || !mounted) {
      return;
    }

    try {
      await _service.markOutdated(
        tutorialId: tutorial.id,
        outdated: outdated,
        adminId: widget.adminId,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        outdated
            ? 'Tutorial marked outdated and disabled.'
            : 'Tutorial marked current. Publication still requires normal safety rules.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Could not update outdated status: $error');
    }
  }

  Future<void> _archiveTutorialAction(HelpVideoTutorialModel tutorial) async {
    final bool confirmed = await _confirmTutorialAction(
      title: 'Archive tutorial?',
      message:
          'The tutorial will be archived and disabled. '
          'The record will remain available for version '
          'history and rollback-safe reference.',
      confirmLabel: 'Archive',
    );

    if (!confirmed || !mounted) {
      return;
    }

    try {
      await _service.archiveTutorial(
        tutorialId: tutorial.id,
        adminId: widget.adminId,
      );

      if (!mounted) {
        return;
      }

      _showMessage('Tutorial archived. No hard delete was performed.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Could not archive tutorial: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            tooltip: 'Tutorial Chapters & Deep Links',
            icon: const Icon(Icons.route_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      SuperAdminVideoNavigationScreen(adminId: widget.adminId),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Private Training Access',
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => SuperAdminVideoTrainingAccessScreen(
                    adminId: widget.adminId,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Video Guide Analytics',
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => SuperAdminVideoAnalyticsScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Video Maintenance Approval Inbox',
            icon: const Icon(Icons.fact_check_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      SuperAdminVideoMaintenanceDraftInboxScreen(
                        adminId: widget.adminId,
                      ),
                ),
              );
            },
          ),
        ],
        title: const Text('Video Tutorials'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add tutorial'),
      ),
      body: StreamBuilder<List<HelpVideoTutorialModel>>(
        stream: _service.watchTutorials(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Tutorial management is unavailable.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<HelpVideoTutorialModel> tutorials = snapshot.data!;

          if (tutorials.isEmpty) {
            return const Center(
              child: Text(
                'No tutorials yet. '
                'Use Add tutorial to create one.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: tutorials.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final HelpVideoTutorialModel tutorial = tutorials[index];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              tutorial.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Switch(
                            value: tutorial.isEnabled,
                            onChanged: (value) {
                              _setEnabled(tutorial, value);
                            },
                          ),
                        ],
                      ),

                      if (tutorial.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(tutorial.description),
                      ],

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          _statusChip('Module: ${tutorial.module}'),
                          _statusChip('Audience: ${tutorial.audience}'),
                          _statusChip('Language: ${tutorial.language}'),
                          _statusChip('Publish: ${tutorial.publishedStatus}'),
                          _statusChip('Approval: ${tutorial.approvalStatus}'),
                          _statusChip('Video v${tutorial.videoVersion}'),
                          if (tutorial.outdated) _statusChip('OUTDATED'),
                          if (tutorial.requiresApproval)
                            _statusChip('REVIEW REQUIRED'),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Category: ${tutorial.category}  ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢  '
                        'Order: ${tutorial.displayOrder}  ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢  '
                        'Duration: ${tutorial.duration}s',
                      ),

                      if (tutorial.appVersion.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('App version: ${tutorial.appVersion}'),
                      ],

                      if (tutorial.changeSummary.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Change: ${tutorial.changeSummary}'),
                      ],

                      const SizedBox(height: 6),

                      Text(
                        tutorial.videoUrl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Review actions',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        children: <Widget>[
                          if (tutorial.requiresApproval &&
                              tutorial.approvalStatus.trim().toLowerCase() !=
                                  'approved')
                            FilledButton.icon(
                              onPressed: () async {
                                await _approveTutorialAction(tutorial);
                              },
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                              ),
                              label: const Text('Approve'),
                            ),

                          if (tutorial.requiresApproval &&
                              tutorial.approvalStatus.trim().toLowerCase() !=
                                  'rejected')
                            OutlinedButton.icon(
                              onPressed: () async {
                                await _rejectTutorialAction(tutorial);
                              },
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Reject'),
                            ),

                          OutlinedButton.icon(
                            onPressed: () async {
                              await _setOutdatedAction(
                                tutorial,
                                !tutorial.outdated,
                              );
                            },
                            icon: Icon(
                              tutorial.outdated
                                  ? Icons.update_rounded
                                  : Icons.warning_amber_rounded,
                            ),
                            label: Text(
                              tutorial.outdated
                                  ? 'Mark current'
                                  : 'Mark outdated',
                            ),
                          ),

                          if (tutorial.publishedStatus.trim().toLowerCase() !=
                              'archived')
                            OutlinedButton.icon(
                              onPressed: () async {
                                await _archiveTutorialAction(tutorial);
                              },
                              icon: const Icon(Icons.archive_outlined),
                              label: const Text('Archive'),
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _openEditor(tutorial: tutorial);
                          },
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit metadata'),
                        ),
                      ),
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
