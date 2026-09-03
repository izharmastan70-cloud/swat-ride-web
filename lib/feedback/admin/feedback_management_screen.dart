import 'package:flutter/material.dart';

import '../models/feedback_model.dart';
import '../services/feedback_admin_service.dart';

class FeedbackManagementScreen extends StatefulWidget {
  final String adminId;
  final FeedbackAdminService? adminService;
  final FeedbackServiceType? initialServiceType;
  final bool lockServiceType;
  final bool reviewsOnly;
  final bool lowRatingOnly;
  final int lowRatingMaximum;
  final bool reportsOnly;
  final FeedbackServiceType? reportsServiceType;

  const FeedbackManagementScreen({
    super.key,
    required this.adminId,
    this.adminService,
    this.initialServiceType,
    this.lockServiceType = false,
    this.reviewsOnly = false,
    this.lowRatingOnly = false,
    this.lowRatingMaximum = 2,
    this.reportsOnly = false,
    this.reportsServiceType,
  });

  @override
  State<FeedbackManagementScreen> createState() =>
      _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen>
    with SingleTickerProviderStateMixin {
  late final FeedbackAdminService _service;
  late final TabController _tabs;
  final TextEditingController _targetController = TextEditingController();

  FeedbackServiceType? _serviceType;
  FeedbackStatus? _status;
  int? _rating;
  String _targetId = '';

  @override
  void initState() {
    super.initState();
    _serviceType = widget.initialServiceType;
    _service = widget.adminService ?? FeedbackAdminService();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lowRatingOnly) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F5F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Low Rating Food Reviews',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                '2-star and below review queue',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        body: _lowRatingReviewsTab(),
      );
    }

    if (widget.reportsOnly) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F5F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Reported Food Reviews',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                'Food-only open report moderation',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        body: _reportsTab(),
      );
    }

    if (widget.reviewsOnly) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F5F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Food Review Management',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                'Food-only human-controlled moderation',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        body: _reviewsTab(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Management',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            Text(
              'Human-controlled moderation',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Reviews', icon: Icon(Icons.rate_review_rounded)),
            Tab(text: 'Open reports', icon: Icon(Icons.flag_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_reviewsTab(), _reportsTab()],
      ),
    );
  }

  Widget _lowRatingReviewsTab() {
    return StreamBuilder<List<FeedbackModel>>(
      stream: _service.watchLowRatingReviews(
        maximumRating: widget.lowRatingMaximum,
        serviceType: widget.initialServiceType,
        limit: 100,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _MessageView(
            icon: Icons.error_outline_rounded,
            title: 'Low-rating reviews could not be loaded',
            message: snapshot.error.toString(),
            color: const Color(0xFFB91C1C),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data!;

        if (reviews.isEmpty) {
          return const _MessageView(
            icon: Icons.verified_rounded,
            title: 'Low-rating queue is clear',
            message: 'No Food reviews are currently rated 2 stars or below.',
            color: Color(0xFF15803D),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: reviews.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _ReviewCard(
            review: reviews[index],
            onModerate: () => _moderateReview(reviews[index]),
            onNotes: () => _openNotes(reviews[index]),
          ),
        );
      },
    );
  }

  Widget _reviewsTab() {
    return Column(
      children: [
        _filters(),
        Expanded(
          child: StreamBuilder<List<FeedbackModel>>(
            stream: _service.watchReviews(
              serviceType: _serviceType,
              status: _status,
              rating: _rating,
              targetId: _targetId,
              limit: 100,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _MessageView(
                  icon: Icons.error_outline_rounded,
                  title: 'Reviews could not be loaded',
                  message: snapshot.error.toString(),
                  color: const Color(0xFFB91C1C),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final reviews = snapshot.data!;
              if (reviews.isEmpty) {
                return const _MessageView(
                  icon: Icons.search_off_rounded,
                  title: 'No matching reviews',
                  message: 'Change or reset the current filters.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
                itemCount: reviews.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _ReviewCard(
                  review: reviews[index],
                  onModerate: () => _moderateReview(reviews[index]),
                  onNotes: () => _openNotes(reviews[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filters() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(14),
      decoration: _decoration(),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _DropFilter<FeedbackServiceType?>(
            value: _serviceType,
            items: [
              const DropdownMenuItem(value: null, child: Text('All services')),
              ...FeedbackServiceType.values.map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item.displayName),
                ),
              ),
            ],
            onChanged: (value) {
              if (widget.lockServiceType) return;
              setState(() => _serviceType = value);
            },
          ),
          _DropFilter<FeedbackStatus?>(
            value: _status,
            items: [
              const DropdownMenuItem(value: null, child: Text('All statuses')),
              ...FeedbackStatus.values.map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(_statusText(item)),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _status = value),
          ),
          _DropFilter<int?>(
            value: _rating,
            items: [
              const DropdownMenuItem(value: null, child: Text('All ratings')),
              ...List.generate(5, (index) => 5 - index).map(
                (item) =>
                    DropdownMenuItem(value: item, child: Text('$item star')),
              ),
            ],
            onChanged: (value) => setState(() => _rating = value),
          ),
          SizedBox(
            width: 220,
            child: TextField(
              controller: _targetController,
              textInputAction: TextInputAction.search,
              decoration: _input('Target ID', Icons.search_rounded),
              onSubmitted: (value) => setState(() => _targetId = value.trim()),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () =>
                setState(() => _targetId = _targetController.text.trim()),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Apply'),
          ),
          TextButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _reportsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.watchOpenReports(
        entityType: widget.reportsServiceType == null ? null : 'review',
        serviceType: widget.reportsServiceType,
        limit: 100,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _MessageView(
            icon: Icons.error_outline_rounded,
            title: 'Reports could not be loaded',
            message: snapshot.error.toString(),
            color: const Color(0xFFB91C1C),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data!;
        if (reports.isEmpty) {
          return const _MessageView(
            icon: Icons.verified_rounded,
            title: 'Moderation queue is clear',
            message: 'There are no open review or reply reports.',
            color: Color(0xFF15803D),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: reports.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _ReportCard(
            report: reports[index],
            onResolve: () => _resolveReport(reports[index], dismiss: false),
            onDismiss: () => _resolveReport(reports[index], dismiss: true),
          ),
        );
      },
    );
  }

  void _resetFilters() {
    _targetController.clear();
    setState(() {
      _serviceType = widget.initialServiceType;
      _status = null;
      _rating = null;
      _targetId = '';
    });
  }

  Future<void> _moderateReview(FeedbackModel review) async {
    FeedbackStatus nextStatus = review.status == FeedbackStatus.hidden
        ? FeedbackStatus.published
        : FeedbackStatus.hidden;
    final reasonController = TextEditingController();
    final result = await showDialog<_ModerationResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Moderate review'),
          content: SizedBox(
            width: 470,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<FeedbackStatus>(
                  initialValue: nextStatus,
                  decoration: _input('New status', Icons.gavel_rounded),
                  items: const [
                    DropdownMenuItem(
                      value: FeedbackStatus.published,
                      child: Text('Publish / Unhide'),
                    ),
                    DropdownMenuItem(
                      value: FeedbackStatus.hidden,
                      child: Text('Hide from public'),
                    ),
                    DropdownMenuItem(
                      value: FeedbackStatus.flagged,
                      child: Text('Flag for investigation'),
                    ),
                    DropdownMenuItem(
                      value: FeedbackStatus.removed,
                      child: Text('Remove permanently'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => nextStatus = value);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: reasonController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: _input(
                    'Required moderation reason',
                    Icons.edit_note_rounded,
                  ),
                ),
                if (nextStatus == FeedbackStatus.removed)
                  const _WarningBox(
                    text:
                        'Removal is recorded with admin identity and audit reason.',
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) return;
                Navigator.pop(
                  context,
                  _ModerationResult(status: nextStatus, reason: reason),
                );
              },
              style: nextStatus == FeedbackStatus.removed
                  ? FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB91C1C),
                    )
                  : null,
              child: const Text('Confirm action'),
            ),
          ],
        ),
      ),
    );
    reasonController.dispose();
    if (result == null || !mounted) return;
    await _runAction(
      () => _service.moderateReview(
        feedbackId: review.id,
        nextStatus: result.status,
        adminId: widget.adminId,
        reason: result.reason,
      ),
      'Review moderation saved.',
    );
  }

  Future<void> _resolveReport(
    Map<String, dynamic> report, {
    required bool dismiss,
  }) async {
    final controller = TextEditingController();
    final resolution = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dismiss ? 'Dismiss report' : 'Resolve report'),
        content: SizedBox(
          width: 450,
          child: TextField(
            controller: controller,
            maxLines: 4,
            maxLength: 500,
            decoration: _input(
              'Required resolution details',
              Icons.fact_check_rounded,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: Text(dismiss ? 'Dismiss' : 'Resolve'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (resolution == null || !mounted) return;
    await _runAction(
      () => _service.resolveReport(
        reportId: _text(report['id']),
        adminId: widget.adminId,
        resolution: resolution,
        dismiss: dismiss,
      ),
      dismiss ? 'Report dismissed.' : 'Report resolved.',
    );
  }

  Future<void> _openNotes(FeedbackModel review) async {
    final noteController = TextEditingController();
    bool privateNote = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) => SizedBox(
            height: MediaQuery.sizeOf(context).height * .65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Admin notes',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  'Review ID: ${review.id}',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _service.watchAdminNotes(
                      entityType: 'review',
                      entityId: review.id,
                    ),
                    builder: (context, snapshot) {
                      final notes = snapshot.data ?? const [];
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (notes.isEmpty) {
                        return const Center(child: Text('No admin notes yet.'));
                      }
                      return ListView.separated(
                        itemCount: notes.length,
                        separatorBuilder: (_, _) => const Divider(),
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              _bool(note['private'])
                                  ? Icons.lock_rounded
                                  : Icons.groups_rounded,
                            ),
                            title: Text(_text(note['note'])),
                            subtitle: Text('Admin: ${_text(note['adminId'])}'),
                          );
                        },
                      );
                    },
                  ),
                ),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  maxLength: 1000,
                  decoration: _input('Add admin note', Icons.note_add_rounded),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Private admin note'),
                  value: privateNote,
                  onChanged: (value) =>
                      setSheetState(() => privateNote = value),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final note = noteController.text.trim();
                      if (note.isEmpty) return;
                      try {
                        await _service.addAdminNote(
                          entityType: 'review',
                          entityId: review.id,
                          adminId: widget.adminId,
                          note: note,
                          privateNote: privateNote,
                        );
                        noteController.clear();
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save note'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    noteController.dispose();
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    _showBlockingProgress();
    try {
      await action();
      if (!mounted) return;
      Navigator.pop(context);
      _message(successMessage);
    } catch (error) {
      if (!mounted) return;
      Navigator.pop(context);
      _message(error.toString(), error: true);
    }
  }

  void _showBlockingProgress() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _message(String value, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        backgroundColor: error ? const Color(0xFFB91C1C) : null,
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final FeedbackModel review;
  final VoidCallback onModerate;
  final VoidCallback onNotes;

  const _ReviewCard({
    required this.review,
    required this.onModerate,
    required this.onNotes,
  });

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(review.rating);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                child: Text(
                  '${review.rating}ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã¢â‚¬Â¹Ãƒâ€¦Ã¢â‚¬Å“ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.targetName.trim().isEmpty
                          ? review.targetType.displayName
                          : review.targetName,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${review.serviceType.displayName} ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ ${review.publicReviewerName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: review.status),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(review.comment, style: const TextStyle(height: 1.4)),
          ],
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: review.tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (review.isVerified)
                const _InfoPill(
                  text: 'Verified service',
                  icon: Icons.verified_rounded,
                  color: Color(0xFF15803D),
                ),
              if (review.isFlagged)
                _InfoPill(
                  text: '${review.reportCount} report(s)',
                  icon: Icons.flag_rounded,
                  color: const Color(0xFFB91C1C),
                ),
              _InfoPill(
                text: review.visibility.name,
                icon: review.visibility == FeedbackVisibility.private
                    ? Icons.lock_rounded
                    : Icons.public_rounded,
                color: const Color(0xFF4B5563),
              ),
            ],
          ),
          const Divider(height: 26),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNotes,
                  icon: const Icon(Icons.admin_panel_settings_rounded),
                  label: const Text('Admin notes'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onModerate,
                  icon: const Icon(Icons.gavel_rounded),
                  label: const Text('Moderate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onResolve;
  final VoidCallback onDismiss;

  const _ReportCard({
    required this.report,
    required this.onResolve,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: _decoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFFEE2E2),
              foregroundColor: Color(0xFFB91C1C),
              child: Icon(Icons.flag_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _text(report['category'], fallback: 'Reported content'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${_text(report['entityType'], fallback: 'item')} ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ ${_text(report['entityId'])}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const _OpenBadge(),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _text(report['reason'], fallback: 'No reason provided.'),
          style: const TextStyle(height: 1.4),
        ),
        const SizedBox(height: 8),
        Text(
          'Reporter: ${_text(report['reporterId'], fallback: 'Unknown')}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        const Divider(height: 26),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onDismiss,
                child: const Text('Dismiss'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: onResolve,
                child: const Text('Resolve'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _DropFilter<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _DropFilter({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 170,
    child: DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: _input('', Icons.filter_alt_rounded),
      items: items,
      onChanged: onChanged,
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final FeedbackStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: _statusColor(status).withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      _statusText(status),
      style: TextStyle(
        color: _statusColor(status),
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _OpenBadge extends StatelessWidget {
  const _OpenBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEDD5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'OPEN',
      style: TextStyle(
        color: Color(0xFFC2410C),
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _InfoPill extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _InfoPill({
    required this.text,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _WarningBox extends StatelessWidget {
  final String text;
  const _WarningBox({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFEE2E2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_rounded, color: Color(0xFFB91C1C)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: Color(0xFF991B1B))),
        ),
      ],
    ),
  );
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.color = const Color(0xFF6B7280),
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    ),
  );
}

class _ModerationResult {
  final FeedbackStatus status;
  final String reason;
  const _ModerationResult({required this.status, required this.reason});
}

InputDecoration _input(String label, IconData icon) => InputDecoration(
  labelText: label.isEmpty ? null : label,
  prefixIcon: Icon(icon),
  filled: true,
  fillColor: const Color(0xFFF5F6F7),
  isDense: true,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(13),
    borderSide: BorderSide.none,
  ),
);

BoxDecoration _decoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: const Color(0xFFE5E7EB)),
);

String _statusText(FeedbackStatus status) {
  switch (status) {
    case FeedbackStatus.published:
      return 'Published';
    case FeedbackStatus.pendingModeration:
      return 'Pending';
    case FeedbackStatus.hidden:
      return 'Hidden';
    case FeedbackStatus.removed:
      return 'Removed';
    case FeedbackStatus.flagged:
      return 'Flagged';
  }
}

Color _statusColor(FeedbackStatus status) {
  switch (status) {
    case FeedbackStatus.published:
      return const Color(0xFF15803D);
    case FeedbackStatus.pendingModeration:
      return const Color(0xFFB45309);
    case FeedbackStatus.hidden:
      return const Color(0xFF4B5563);
    case FeedbackStatus.removed:
      return const Color(0xFFB91C1C);
    case FeedbackStatus.flagged:
      return const Color(0xFF7C3AED);
  }
}

Color _ratingColor(int rating) {
  if (rating <= 2) return const Color(0xFFDC2626);
  if (rating == 3) return const Color(0xFFEA580C);
  return const Color(0xFF15803D);
}

String _text(Object? value, {String fallback = ''}) {
  final result = value?.toString().trim() ?? '';
  return result.isEmpty ? fallback : result;
}

bool _bool(Object? value) => value is bool && value;
